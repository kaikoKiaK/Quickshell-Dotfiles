import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: iconText.implicitWidth + 26
    implicitHeight: parent.height

    property bool popupHovered: false
    property bool _showPopup: false
    readonly property bool showMonitors: _showPopup || popupHovered

    Rectangle {
        anchors.fill: parent
        color: "#101010"
        topRightRadius: 0
        bottomRightRadius: 0
        topLeftRadius: 5
        bottomLeftRadius: 5

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            topRightRadius: 0
            bottomRightRadius: 0
            topLeftRadius: 5
            bottomLeftRadius: 5
            border.color: "#eeeeee"
            border.width: 1
            opacity: hoverHandler.hovered ? 0.35 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            topRightRadius: 0
            bottomRightRadius: 0
            topLeftRadius: 5
            bottomLeftRadius: 5
            opacity: hoverHandler.hovered ? 0.06 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            id: iconText
            anchors.centerIn: parent
            text: ""
            color: "#eeeeee"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18

            scale: hoverHandler.hovered ? 1.15 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutBack
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered) {
                    hidetimer.stop();
                    root._showPopup = true;
                } else {
                    hidetimer.restart();
                }
            }
        }

        Timer {
            id: hidetimer
            interval: 300
            onTriggered: root._showPopup = false
        }
    }
}
