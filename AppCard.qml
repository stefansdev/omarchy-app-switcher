import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  required property var appData
  property var toplevel: null
  property bool selected: false

  readonly property var waylandToplevel: toplevel ? toplevel.wayland : null
  readonly property string appId: waylandToplevel
    ? String(waylandToplevel.appId || appData.class || "")
    : String(appData.class || "")
  readonly property var desktopEntry: appId
    ? (DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId))
    : null
  readonly property string iconSource: desktopEntry && desktopEntry.icon
    ? Quickshell.iconPath(desktopEntry.icon, true)
    : ""

  signal activated()

  radius: Math.max(0, Style.cornerRadius - Style.spacing.md)
  color: selected
    ? Style.selectedFillFor(Color.popups.text, Color.accent)
    : Util.alpha(Color.popups.text, cardHover.hovered ? 0.08 : 0.045)
  borderSpec: selected
    ? Border.withWidth(
        Border.controlSpec("focus", Color.popups.text, Color.accent),
        Math.max(Style.space(2), Style.focusBorderWidth))
    : Border.flat(Util.alpha(Color.popups.border, 0.42), Math.max(1, Style.normalBorderWidth))
  clip: true

  Behavior on color {
    ColorAnimation { duration: 45 }
  }

  Item {
    id: previewArea

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.left: parent.left
    anchors.bottom: appDetails.top
    anchors.margins: Style.spacing.sm
    clip: true

    ScreencopyView {
      id: preview

      anchors.centerIn: parent
      captureSource: root.waylandToplevel
      live: false
      paintCursor: false
      width: {
        if (!hasContent || sourceSize.width <= 0 || sourceSize.height <= 0) return parent.width
        return Math.min(parent.width, parent.height * sourceSize.width / sourceSize.height)
      }
      height: {
        if (!hasContent || sourceSize.width <= 0 || sourceSize.height <= 0) return parent.height
        return Math.min(parent.height, parent.width * sourceSize.height / sourceSize.width)
      }
      visible: hasContent
    }

    Image {
      visible: !preview.hasContent && source !== ""
      anchors.centerIn: parent
      width: Math.min(parent.width, parent.height) * 0.38
      height: width
      source: root.iconSource
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      smooth: true
      opacity: 0.82
    }
  }

  Row {
    id: appDetails

    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.margins: Style.spacing.md
    height: Style.space(32)
    spacing: Style.spacing.sm

    Image {
      visible: source !== ""
      anchors.verticalCenter: parent.verticalCenter
      width: visible ? Style.font.icon : 0
      height: width
      source: root.iconSource
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      smooth: true
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - (root.iconSource ? Style.font.icon + parent.spacing : 0)
      text: String(root.appData.title || root.appData.class || "Application")
      color: Color.popups.text
      font.family: Style.font.menuFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter
    }
  }

  HoverHandler {
    id: cardHover
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: root.activated()
  }
}
