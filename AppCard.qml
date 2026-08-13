import QtQuick
import QtQuick.Window
import Quickshell
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
  readonly property string webAppIconName: {
    var match = String(appData.class || "").toLowerCase()
      .match(/^(?:chrome|chromium)-(.+?)__/)
    if (!match) return ""
    var parts = match[1].split(".")
    if (parts[0] === "web") parts.shift()
    return parts.length > 1 ? parts[parts.length - 2] : parts[0]
  }
  readonly property string iconName: webAppIconName
    || (desktopEntry && desktopEntry.icon ? String(desktopEntry.icon) : "")
  readonly property string iconSource: iconName
    ? Quickshell.iconPath(iconName, true)
    : ""
  readonly property string displayName: desktopEntry && desktopEntry.name
    ? String(desktopEntry.name)
    : String(appData.title || appData.class || "Application")

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

  Image {
    id: appIcon

    visible: status === Image.Ready
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Style.spacing.lg
    width: Math.min(Style.space(88), parent.width - Style.spacing.xl * 2)
    height: width
    source: root.iconSource
    sourceSize: Qt.size(
      Math.ceil(width * Screen.devicePixelRatio),
      Math.ceil(height * Screen.devicePixelRatio))
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    cache: true
    smooth: true
    mipmap: true
  }

  Text {
    visible: appIcon.status !== Image.Ready
    anchors.centerIn: appIcon
    text: root.displayName.slice(0, 1).toUpperCase()
    color: Color.popups.text
    font.family: Style.font.menuFamily
    font.pixelSize: Style.font.displayLarge
    font.weight: Font.Medium
  }

  Text {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.margins: Style.spacing.md
    height: Style.space(28)
    text: root.displayName
    color: Color.popups.text
    font.family: Style.font.menuFamily
    font.pixelSize: Style.font.bodySmall
    font.weight: Font.Medium
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
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
