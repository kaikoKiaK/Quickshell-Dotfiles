pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Rectangle {
    id: root

    required property string appName
    required property string appIcon
    required property string appExec
    required property bool isSelected
    required property int itemIndex

    signal activated
    signal hoverChanged(int idx)

    implicitHeight: 44
    width: parent ? parent.width : 0
    radius: 6
    color: root.isSelected ? "#1e1e2e" : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 80
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "#eeeeee"
        opacity: root.isSelected ? 0.07 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 80
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "#8caaee"
        border.width: 1
        opacity: root.isSelected ? 0.6 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 80
            }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // App icon — tries the theme icon, falls back to a generic glyph
        Item {
            id: iconContainer
            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: iconImage
                anchors.fill: parent
                source: root.appIcon !== "" ? Quickshell.iconPath(root.appIcon, true) : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: status === Image.Ready
            }

            // Fallback glyph when no icon resolves
            Text {
                anchors.centerIn: parent
                text: ""
                color: root.isSelected ? "#8caaee" : "#555555"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                visible: iconImage.status !== Image.Ready
                Behavior on color {
                    ColorAnimation {
                        duration: 80
                    }
                }
            }
        }

        Text {
            text: root.appName
            color: root.isSelected ? "#eeeeee" : "#aaaaaa"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.weight: root.isSelected ? Font.Medium : Font.Normal
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: parent.width - iconContainer.width - parent.spacing
            Behavior on color {
                ColorAnimation {
                    duration: 80
                }
            }
        }
    }

    HoverHandler {
        onHoveredChanged: if (hovered)
            root.hoverChanged(root.itemIndex)
    }

    TapHandler {
        cursorShape: Qt.PointingHandCursor
        onTapped: root.activated()
    }
}
