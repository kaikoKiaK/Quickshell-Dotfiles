import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root
    implicitWidth: row.implicitWidth + 16
    implicitHeight: parent.height

    // Pass the screen from shell.qml so we filter workspaces per monitor
    required property ShellScreen screen

    Rectangle {
        anchors.fill: parent
        color: "#101010"
        radius: 5

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: Hyprland.workspaces.values.filter(ws => {
                    return ws.monitor?.name === root.screen.name;
                })

                delegate: Rectangle {
                    id: wsBtn
                    required property var modelData

                    readonly property bool isActive: Hyprland.focusedWorkspace?.id === modelData.id

                    width: 28
                    height: 28
                    radius: 4
                    color: "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wsBtn.isActive ? "" : ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: wsBtn.isActive ? 17 : 14
                        color: wsBtn.isActive ? "#eeeeee" : "#666666"

                        scale: wsBtn.isActive ? 1.1 : hoverHandler.hovered ? 1.05 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    TapHandler {
                        onTapped: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsBtn.modelData.id + " })")
                    }

                    HoverHandler {
                        id: hoverHandler
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }
}
