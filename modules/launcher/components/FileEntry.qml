pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Rectangle {
    id: root

    required property string fileName
    required property string fileDir
    required property string fileIcon
    required property string fallbackGlyph
    required property bool isSelected
    required property int itemIndex

    signal activated
    signal hoverChanged(int idx)

    implicitHeight: 46
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

        // File icon — tries the theme's mimetype icon (e.g. image-x-generic,
        // application-pdf), falls back to a Nerd Font glyph by category
        Item {
            id: iconContainer
            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: iconImage
                anchors.fill: parent
                source: root.fileIcon !== "" ? Quickshell.iconPath(root.fileIcon, true) : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: root.fallbackGlyph
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

        Column {
            width: parent.width - iconContainer.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: root.fileName
                color: root.isSelected ? "#eeeeee" : "#aaaaaa"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.weight: root.isSelected ? Font.Medium : Font.Normal
                elide: Text.ElideRight
                width: parent.width
                Behavior on color {
                    ColorAnimation {
                        duration: 80
                    }
                }
            }

            Text {
                text: root.fileDir
                color: "#666666"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                elide: Text.ElideMiddle
                width: parent.width
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
