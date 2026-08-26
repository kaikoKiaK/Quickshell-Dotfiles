import Quickshell
import QtQuick
import Quickshell.Io
import "."

PanelWindow {
    id: root
    required property ShellScreen targetScreen
    required property int barHeight
    required property var monitorsWidget

    screen: targetScreen
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: barHeight + monitorsPopout.height + monitorsPopout.border.width * 2
    color: "transparent"
    exclusiveZone: 0
    visible: root.monitorsWidget.showMonitors

    property var monitors: []
    property int selectedMonitor: -1
    property int brightness: 100
    property int temperature: 6500
    property int volume: 100
    property string activeInput: ""
    property string currentBus: root.selectedMonitor >= 0 && root.selectedMonitor < root.monitors.length ? root.monitors[root.selectedMonitor].bus : "0"

    ColorUtils {
        id: colors
    }

    property bool popoutHovered: false
    property bool comboOpen: false

    function refreshPopupHover() {
        root.monitorsWidget.popupHovered = root.popoutHovered || root.comboOpen;
    }

    readonly property int activeInputIndex: (function () {
            if (root.selectedMonitor < 0 || root.selectedMonitor >= root.monitors.length)
                return -1;
            let inputs = root.monitors[root.selectedMonitor].inputs;
            for (let i = 0; i < inputs.length; i++)
                if (inputs[i].hex === root.activeInput)
                    return i;
            return -1;
        })()

    onSelectedMonitorChanged: if (selectedMonitor >= 0) {
        brightnessReader.running = true;
        inputReader.running = true;
        volumeReader.running = true;
    }

    Timer {
        id: initTimer
        interval: 2000
        running: true
        onTriggered: monitorReader.running = true
    }

    Timer {
        id: brightnessTimer
        interval: 3000
        repeat: true
        running: root.visible
        onTriggered: if (root.selectedMonitor >= 0) {
            brightnessReader.running = true;
            inputReader.running = true;
            volumeReader.running = true;
        }
    }

    Process {
        id: monitorReader
        command: ["sh", "/home/kaiko/.config/quickshell/default/modules/bar/popouts/scripts/get-monitors.sh"]

        property var _monitors: []

        stdout: SplitParser {
            onRead: function (line) {
                let lineStr = line.trim();
                if (lineStr === "")
                    return;
                let parts = lineStr.split("|");
                if (parts[0] === "input") {
                    if (parts.length >= 4) {
                        for (let i = 0; i < monitorReader._monitors.length; i++) {
                            if (monitorReader._monitors[i].bus === parts[1]) {
                                monitorReader._monitors[i].inputs.push({
                                    hex: parts[2],
                                    name: parts[3]
                                });
                                break;
                            }
                        }
                    }
                } else if (parts.length >= 2 && parts[0] !== "") {
                    monitorReader._monitors.push({
                        bus: parts[0],
                        name: parts[1],
                        inputs: []
                    });
                }
            }
        }

        onRunningChanged: {
            if (running) {
                _monitors = [];
            } else {
                root.monitors = _monitors;
                if (root.selectedMonitor < 0 || root.selectedMonitor >= _monitors.length)
                    root.selectedMonitor = _monitors.length > 0 ? 0 : -1;
            }
        }
    }

    Process {
        id: brightnessReader
        command: ["sh", "-c", "ddcutil --bus=" + root.currentBus + " getvcp 10 | awk -F'=' '/current value/ {print $2}' | awk '{print $1}' | tr -d ','"]

        stdout: SplitParser {
            onRead: function (line) {
                var b = parseInt(line.trim());
                if (!isNaN(b))
                    root.brightness = Math.max(0, Math.min(100, b));
            }
        }
    }

    Process {
        id: gammaSetter
        property int value: 100
        command: ["sh", "-c", "ddcutil --bus=" + root.currentBus + " setvcp 10 " + value]
    }

    Process {
        id: volumeReader
        command: ["sh", "-c", "ddcutil --bus=" + root.currentBus + " getvcp 0x62 | awk -F'=' '/current value/ {print $2}' | awk '{print $1}' | tr -d ','"]

        stdout: SplitParser {
            onRead: function (line) {
                var v = parseInt(line.trim());
                if (!isNaN(v))
                    root.volume = Math.max(0, Math.min(100, v));
            }
        }
    }

    Process {
        id: volumeSetter
        property int value: 100
        command: ["sh", "-c", "ddcutil --bus=" + root.currentBus + " setvcp 0x62 " + value]
    }

    Process {
        id: tempSetter
        property int value: 6500
        command: ["sh", "-c", "hyprctl hyprsunset temperature " + value]
    }

    Process {
        id: inputReader
        command: ["sh", "-c", "ddcutil --bus=" + root.currentBus + " getvcp 60 2>/dev/null | grep -oP 'sl=0x\\K[0-9a-fA-F]+'"]

        stdout: SplitParser {
            onRead: function (line) {
                let hex = line.trim().toLowerCase();
                if (hex !== "")
                    root.activeInput = hex;
            }
        }
    }

    Process {
        id: inputSetter
        property string value: "0x0f"
        command: ["sh", "-c", "ddcutil --bus=" + root.currentBus + " setvcp 60 " + value]
    }

    Rectangle {
        id: monitorsPopout
        width: 500
        height: 284
        y: 0
        anchors.left: parent.left
        anchors.leftMargin: 10
        radius: 8
        color: "#101010"
        border.color: "#2a2a2a"
        border.width: 1

        HoverHandler {
            onHoveredChanged: {
                root.popoutHovered = hovered;
                root.refreshPopupHover();
            }
        }

        opacity: root.visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: "Monitors"
                color: "#eeeeee"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            Row {
                spacing: 12

                Column {
                    width: 220
                    spacing: 6

                    Text {
                        text: "Monitor"
                        color: "#888888"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    MonitorCombo {
                        id: monitorsCombo
                        model: root.monitors
                        currentIndex: root.selectedMonitor
                        placeholder: "No monitors"
                        display: function (modelData) {
                            return (modelData.name.split(":")[1] || modelData.name);
                        }
                        onActivated: {
                            root.selectedMonitor = currentIndex;
                            root.popoutHovered = true;
                            root.refreshPopupHover();
                        }
                        onPopupOpened: {
                            root.comboOpen = true;
                            root.refreshPopupHover();
                        }
                        onPopupClosed: {
                            root.comboOpen = false;
                            root.refreshPopupHover();
                        }
                    }

                    Text {
                        visible: root.monitors.length === 0
                        text: "No DDC monitors detected"
                        color: "#666666"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                }

                Column {
                    width: 220
                    spacing: 6

                    Text {
                        visible: root.selectedMonitor >= 0 && root.selectedMonitor < root.monitors.length && root.monitors[root.selectedMonitor].inputs.length > 0
                        text: "Input Source"
                        color: "#888888"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    MonitorCombo {
                        id: inputsCombo
                        model: root.selectedMonitor >= 0 && root.selectedMonitor < root.monitors.length ? root.monitors[root.selectedMonitor].inputs : []
                        currentIndex: root.activeInputIndex
                        placeholder: "Select input"
                        onActivated: {
                            let inputs = root.selectedMonitor >= 0 && root.selectedMonitor < root.monitors.length ? root.monitors[root.selectedMonitor].inputs : [];
                            if (currentIndex >= 0 && currentIndex < inputs.length) {
                                let inp = inputs[currentIndex];
                                root.activeInput = inp.hex;
                                inputSetter.value = "0x" + inp.hex;
                                inputSetter.running = false;
                                Qt.callLater(() => inputSetter.running = true);
                            }
                            root.popoutHovered = true;
                            root.refreshPopupHover();
                        }
                        onPopupOpened: {
                            root.comboOpen = true;
                            root.refreshPopupHover();
                        }
                        onPopupClosed: {
                            root.comboOpen = false;
                            root.refreshPopupHover();
                        }
                    }
                }
            }

            SliderBar {
                id: gammaSlider
                title: "Gamma"
                from: 0
                to: 100
                suffix: "%"
                value: root.brightness
                fillColor: colors.gammaColor(gammaSlider.effectiveValue)
                labelColor: "#eeeeee"
                onCommitted: function (v) {
                    root.brightness = v;
                    gammaSetter.value = v;
                    gammaSetter.running = false;
                    Qt.callLater(() => gammaSetter.running = true);
                }
            }

            SliderBar {
                id: temperatureSlider
                title: "Temperature"
                from: 2500
                to: 6500
                suffix: "K"
                value: root.temperature
                fillColor: colors.tempColor(temperatureSlider.effectiveValue)
                onCommitted: function (v) {
                    root.temperature = v;
                    tempSetter.value = v;
                    tempSetter.running = false;
                    Qt.callLater(() => tempSetter.running = true);
                }
            }

            SliderBar {
                id: volumeSlider
                title: "Volume"
                from: 0
                to: 100
                suffix: "%"
                value: root.volume
                fillColor: "#a6da95"
                labelColor: "#eeeeee"
                onCommitted: function (v) {
                    root.volume = v;
                    volumeSetter.value = v;
                    volumeSetter.running = false;
                    Qt.callLater(() => volumeSetter.running = true);
                }
            }
        }
    }
}
