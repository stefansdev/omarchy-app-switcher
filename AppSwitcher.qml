import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property var apps: []
  property int selectedIndex: -1
  property string pendingAddress: ""
  property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

  readonly property int visibleCardCount: Math.max(1, Math.min(5, apps.length))
  readonly property real cardGap: Style.spacing.md

  function normalizedAddress(value) {
    var address = String(value || "").trim().toLowerCase()
    if (!address.match(/^(0x)?[0-9a-f]+$/)) return ""
    return address.indexOf("0x") === 0 ? address : "0x" + address
  }

  function focusedScreen() {
    var monitor = Hyprland.focusedMonitor
    var screens = Quickshell.screens || []
    if (monitor) {
      for (var i = 0; i < screens.length; i++) {
        if (screens[i] && screens[i].name === monitor.name) return screens[i]
      }
    }
    return screens.length > 0 ? screens[0] : null
  }

  function toplevelFor(address) {
    var wanted = normalizedAddress(address)
    var workspaces = Hyprland.workspaces.values
    for (var i = 0; i < workspaces.length; i++) {
      var toplevels = workspaces[i].toplevels.values
      for (var j = 0; j < toplevels.length; j++) {
        if (normalizedAddress(toplevels[j].address) === wanted) return toplevels[j]
      }
    }
    return null
  }

  function parsePayload(payloadJson) {
    try {
      var payload = JSON.parse(String(payloadJson || "{}"))
      return {
        direction: Number(payload.direction || 1) < 0 ? -1 : 1,
        apps: Array.isArray(payload.apps) ? payload.apps : []
      }
    } catch (error) {
      console.warn("AppSwitcher: invalid payload", error)
      return { direction: 1, apps: [] }
    }
  }

  function advance(direction) {
    if (apps.length < 1) return
    selectedIndex = (selectedIndex + direction + apps.length) % apps.length
    appList.currentIndex = selectedIndex
    appList.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function open(payloadJson) {
    var payload = parsePayload(payloadJson)

    if (opened) {
      advance(payload.direction)
      return
    }

    apps = payload.apps
    if (apps.length < 1) return

    targetScreen = focusedScreen()
    selectedIndex = payload.direction < 0 ? apps.length - 1 : Math.min(1, apps.length - 1)
    opened = true
    appList.currentIndex = selectedIndex
    Qt.callLater(function() {
      keyCatcher.forceActiveFocus()
      appList.positionViewAtIndex(selectedIndex, ListView.Contain)
    })
  }

  function close() {
    opened = false
    apps = []
    selectedIndex = -1
  }

  function dismiss() {
    close()
    if (shell && typeof shell.hide === "function")
      shell.hide((manifest && manifest.id) || "stefans.app-switcher")
  }

  function activateSelected() {
    if (selectedIndex < 0 || selectedIndex >= apps.length) {
      dismiss()
      return
    }

    var address = normalizedAddress(apps[selectedIndex].address)
    if (!address) {
      dismiss()
      return
    }

    // Hyprland refuses window focus while our exclusive-keyboard overlay is
    // mapped, so close it first and focus once the layer is gone.
    pendingAddress = address
    dismiss()
    focusTimer.restart()
  }

  function focusPending() {
    var address = pendingAddress
    pendingAddress = ""
    if (!address) return

    // Focusing doesn't raise floating windows, so bring the newly active one to the top.
    if (Hyprland.usingLua) {
      Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + address + "\" })")
      Hyprland.dispatch("hl.dsp.window.bring_to_top()")
    } else {
      Hyprland.dispatch("focuswindow address:" + address)
      Hyprland.dispatch("alterzorder top")
    }
  }

  Timer {
    id: focusTimer
    interval: 30
    onTriggered: root.focusPending()
  }

  function commit(_) {
    if (!opened) return "closed"
    activateSelected()
    return "ok"
  }

  PanelWindow {
    id: panel

    screen: root.targetScreen
    visible: root.opened && root.targetScreen !== null
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "omarchy-app-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
      anchors.fill: parent
      color: Util.alpha(Color.background, 0.20)
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    FocusScope {
      id: keyCatcher

      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Tab) {
          root.advance((event.modifiers & Qt.ShiftModifier) ? -1 : 1)
          event.accepted = true
        } else if (event.key === Qt.Key_Backtab) {
          root.advance(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.activateSelected()
          event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
          root.dismiss()
          event.accepted = true
        }
      }

      Keys.onReleased: function(event) {
        if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
          root.activateSelected()
          event.accepted = true
        }
      }

      BorderSurface {
        id: switcherSurface

        readonly property real horizontalPadding: Style.spacing.panelPadding
        readonly property real verticalPadding: Style.spacing.lg
        readonly property real availableCardWidth: Math.max(
          Style.space(132),
          (panel.width * 0.84 - horizontalPadding * 2
            - root.cardGap * (root.visibleCardCount - 1)) / root.visibleCardCount)
        readonly property real cardWidth: Math.min(Style.space(168), availableCardWidth)
        readonly property real listWidth: Math.min(
          panel.width * 0.88 - horizontalPadding * 2,
          root.apps.length * cardWidth + Math.max(0, root.apps.length - 1) * root.cardGap)

        anchors.centerIn: parent
        width: listWidth + horizontalPadding * 2 + borderLeft + borderRight
        height: Style.space(164) + verticalPadding * 2 + borderTop + borderBottom
        radius: Style.cornerRadius
        color: Color.popups.background
        borderSpec: Border.none()
        opacity: root.opened ? 1 : 0

        Behavior on opacity {
          NumberAnimation { duration: 65; easing.type: Easing.OutCubic }
        }

        ListView {
          id: appList

          anchors.fill: parent
          anchors.margins: switcherSurface.horizontalPadding
          orientation: ListView.Horizontal
          spacing: root.cardGap
          clip: true
          model: root.apps
          boundsBehavior: Flickable.StopAtBounds
          highlightMoveDuration: 55
          highlightResizeDuration: 55

          delegate: AppCard {
            required property var modelData
            required property int index

            width: switcherSurface.cardWidth
            height: appList.height
            appData: modelData
            toplevel: root.toplevelFor(modelData.address)
            selected: index === root.selectedIndex
            onActivated: {
              root.selectedIndex = index
              root.activateSelected()
            }
          }
        }
      }
    }
  }
}
