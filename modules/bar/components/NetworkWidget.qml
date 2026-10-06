import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: label.implicitWidth + 26
    implicitHeight: parent.height

    property real rxBytes: 0
    property real txBytes: 0
    property real rxSpeed: 0
    property real txSpeed: 0
    property string iface: "enp6s0" // change to your interface e.g. wlan0

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1024 * 1024)
            return (bytesPerSec / 1024 / 1024).toFixed(1) + " MB/s";
        else if (bytesPerSec >= 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        else
            return bytesPerSec.toFixed(0) + " B/s";
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: netReader.running = true
    }

    Process {
        id: netReader
        command: ["sh", "-c", "cat /sys/class/net/" + root.iface + "/statistics/rx_bytes && cat /sys/class/net/" + root.iface + "/statistics/tx_bytes"]
        stdout: SplitParser {
            property real newRx: 0
            onRead: function (line) {
                var val = parseFloat(line);
                if (newRx === 0) {
                    newRx = val;
                } else {
                    let newTx = val;
                    if (root.rxBytes > 0) {
                        root.rxSpeed = (newRx - root.rxBytes);
                        root.txSpeed = (newTx - root.txBytes);
                    }
                    root.rxBytes = newRx;
                    root.txBytes = newTx;
                    newRx = 0;
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#101010"
        topLeftRadius: 0
        topRightRadius: 5
        bottomLeftRadius: 0
        bottomRightRadius: 5

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            topLeftRadius: 0
            topRightRadius: 5
            bottomLeftRadius: 0
            bottomRightRadius: 5
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
            topLeftRadius: 0
            topRightRadius: 5
            bottomLeftRadius: 0
            bottomRightRadius: 5
            color: "#ffffff"
            opacity: hoverHandler.hovered ? 0.06 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
        Row {
            id: label
            anchors.centerIn: parent
            spacing: 8

            // Download
            Row {
                spacing: 4
                Text {
                    text: "󰇚"
                    color: "#55ff99"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
                Text {
                    text: root.formatSpeed(root.rxSpeed)
                    color: "#eeeeee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }

            // Divider
            Text {
                text: "|"
                color: "#333333"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }

            // Upload
            Row {
                spacing: 4
                Text {
                    text: "󰕒"
                    color: "#8caaee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
                Text {
                    text: root.formatSpeed(root.txSpeed)
                    color: "#eeeeee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }
        }

        HoverHandler {
            id: hoverHandler
        }
    }
}
