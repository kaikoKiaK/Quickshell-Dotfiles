import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: label.implicitWidth + 26
    implicitHeight: parent.height

    // CPU
    property real cpuPercent: 0
    property real cpuTemp: 0
    property real prevIdle: 0
    property real prevTotal: 0

    // Memory
    property real memUsed: 0
    property real memTotal: 0
    property real memPercent: memTotal > 0 ? (memUsed / memTotal) * 100 : 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuReader.running = true;
            memReader.running = true;
            tempReader.running = true;
        }
    }

    Process {
        id: cpuReader
        command: ["cat", "/proc/stat"]
        stdout: SplitParser {
            onRead: function (line) {
                if (!line.startsWith("cpu "))
                    return;
                var parts = line.trim().split(/\s+/);
                var user = parseFloat(parts[1]);
                var nice = parseFloat(parts[2]);
                var system = parseFloat(parts[3]);
                var idle = parseFloat(parts[4]);
                var iowait = parseFloat(parts[5]);
                var irq = parseFloat(parts[6]);
                var softirq = parseFloat(parts[7]);
                var steal = parseFloat(parts[8]) || 0;
                var totalIdle = idle + iowait;
                var totalBusy = user + nice + system + irq + softirq + steal;
                var total = totalIdle + totalBusy;
                var diffTotal = total - root.prevTotal;
                var diffIdle = totalIdle - root.prevIdle;
                if (diffTotal > 0)
                    root.cpuPercent = ((diffTotal - diffIdle) / diffTotal) * 100;
                root.prevTotal = total;
                root.prevIdle = totalIdle;
            }
        }
    }

    Process {
        id: memReader
        command: ["cat", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: function (line) {
                if (line.startsWith("MemTotal:"))
                    root.memTotal = parseFloat(line.split(/\s+/)[1]) / 1024 / 1024;
                else if (line.startsWith("MemAvailable:"))
                    root.memUsed = root.memTotal - parseFloat(line.split(/\s+/)[1]) / 1024 / 1024;
            }
        }
    }

    Process {
        id: tempReader
        command: ["cat", "/sys/class/thermal/thermal_zone4/temp"]
        stdout: SplitParser {
            onRead: function (line) {
                root.cpuTemp = parseFloat(line) / 1000;
            }
        }
    }

    Process {
        id: btopLauncher
        command: ["kitty", "-T", "btop", "-o", "window_margin_width=0", "-o", "window_padding_width=0", "btop"]
    }

    Rectangle {
        anchors.fill: parent
        color: "#101010"
        radius: 5

        // Border glow
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: root.cpuPercent > 80 || root.memPercent > 80 ? "#ff5555" : "#eeeeee"
            border.width: 1
            opacity: hoverHandler.hovered ? 0.35 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Inner highlight
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.cpuPercent > 80 || root.memPercent > 80 ? "#ff5555" : "#ffffff"
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
            spacing: 10

            // CPU
            Row {
                spacing: 4
                Text {
                    text: "󰍛 "
                    color: root.cpuPercent > 80 ? "#ff5555" : root.cpuPercent > 50 ? "#ffaa55" : "#55ff99"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                }
                Text {
                    text: root.cpuTemp.toFixed(0) + "°C"
                    color: "#eeeeee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.cpuPercent.toFixed(0) + "%"
                    color: "#eeeeee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    width: 35
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Divider
            Text {
                text: "|"
                color: "#333333"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }

            // Memory
            Row {
                spacing: 4
                Text {
                    text: " "
                    color: root.memPercent > 80 ? "#ff5555" : root.memPercent > 50 ? "#ffaa55" : "#84bfed"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                }
                Text {
                    text: root.memUsed.toFixed(1) + " / " + root.memTotal.toFixed(1) + " GB"
                    color: "#eeeeee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }
        }

        TapHandler {
            onTapped: btopLauncher.running = true
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }
    }
}
