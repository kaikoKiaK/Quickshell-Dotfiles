pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../lockscreen"

Item {
    id: root
    implicitWidth: row.implicitWidth + 16
    implicitHeight: parent.height

    readonly property var buttons: [
        {
            icon: "",
            label: "lock",
            action: () => LockState.lock()
        },
        {
            icon: "󰒲",
            label: "suspend",
            cmd: ["systemctl", "suspend"]
        },
        {
            icon: "",
            label: "reboot",
            cmd: ["reboot"]
        },
        {
            icon: "⏻",
            label: "poweroff",
            cmd: ["poweroff"]
        },
    ]

    Rectangle {
        anchors.fill: parent
        color: "#101010"
        radius: 5

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: root.buttons

                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property int iconSize: {
                        switch (btn.modelData.label) {
                        case "lock":
                            return 16;
                        case "suspend":
                            return 18;
                        default:
                            return 16;
                        }
                    }

                    width: 32
                    height: root.height - 10
                    radius: 4
                    color: "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    readonly property color iconColor: {
                        switch (btn.modelData.label) {
                        case "lock":
                            return "#e8ae0e";
                        case "suspend":
                            return "#ffffff";
                        case "reboot":
                            return "#2ffbb8";
                        case "poweroff":
                            return "#e78284";
                        default:
                            return "#eeeeee";
                        }
                    }

                    readonly property color iconHoverColor: {
                        switch (btn.modelData.label) {
                        case "lock":
                            return "#c7950c";
                        case "suspend":
                            return "#8caaee";
                        case "reboot":
                            return "#08a875";
                        case "poweroff":
                            return "#ff5555";
                        default:
                            return "#eeeeee";
                        }
                    }

                    readonly property real iconRotation: {
                        if (!hoverHandler.hovered)
                            return 0;
                        switch (btn.modelData.label) {
                        case "reboot":
                            return 180;
                        case "poweroff":
                            return 15;
                        default:
                            return 0;
                        }
                    }

                    Text {
                        id: iconText
                        anchors.centerIn: parent
                        text: btn.modelData.icon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: btn.iconSize
                        color: hoverHandler.hovered ? btn.iconHoverColor : btn.iconColor

                        scale: tapHandler.pressed ? 0.85 : hoverHandler.hovered ? 1.2 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                        }

                        rotation: btn.iconRotation
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    Process {
                        id: proc
                        command: btn.modelData.cmd ?? []
                    }

                    TapHandler {
                        id: tapHandler
                        onTapped: {
                            if (btn.modelData.action)
                                btn.modelData.action();
                            else
                                proc.running = true;
                        }
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
