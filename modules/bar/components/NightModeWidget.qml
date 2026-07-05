import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: iconText.implicitWidth + 26
    implicitHeight: parent.height

    property bool isNightMode: false

    // Read initial state on startup
    Component.onCompleted: stateReader.running = true

    Process {
        id: stateReader
        command: ["sh", "-c", "ddcutil --bus=3 getvcp 10 | awk -F'=' '/current value/ {print $2}' | awk '{print $1}' | tr -d ','"]
        stdout: SplitParser {
            onRead: function (line) {
                var brightness = parseInt(line.trim());
                root.isNightMode = brightness === 0;
            }
        }
    }

    Process {
        id: nightModeOn
        command: ["sh", "-c", "ddcutil --bus=9 setvcp 10 0 & ddcutil --bus=11 setvcp 10 0 & hyprctl hyprsunset temperature 2500; hyprctl hyprsunset gamma 80"]
        onRunningChanged: if (!running)
            root.isNightMode = true
    }

    Process {
        id: nightModeOff
        command: ["sh", "-c", "ddcutil --bus=9 setvcp 10 100 & ddcutil --bus=11 setvcp 10 100 & hyprctl hyprsunset temperature 6500; hyprctl hyprsunset gamma 100"]
        onRunningChanged: if (!running)
            root.isNightMode = false
    }

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
            border.color: root.isNightMode ? "#e8ae0e" : "#eeeeee"
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
            color: root.isNightMode ? "#e8ae0e" : "#ffffff"
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
            text: root.isNightMode ? "" : "󰌵"
            color: root.isNightMode ? "#e8ae0e" : "#eeeeee"
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

        TapHandler {
            cursorShape: Qt.PointingHandCursor
            onTapped: {
                if (root.isNightMode) {
                    nightModeOff.running = false;
                    Qt.callLater(() => nightModeOff.running = true);
                } else {
                    nightModeOn.running = false;
                    Qt.callLater(() => nightModeOn.running = true);
                }
            }
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }
    }
}
