pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root
    required property ShellScreen targetScreen
    required property int barHeight
    required property var clockWidget

    screen: targetScreen
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: barHeight + 300
    color: "transparent"
    exclusiveZone: 0

    // Weather state
    property string weatherTemp: "--°C"
    property string weatherWind: "-- km/h"
    property string weatherHumidity: "--%"
    property int weatherCode: -1
    property bool weatherLoading: true

    function weatherIcon(code) {
        if (code === 0)
            return "󰖙";
        if (code === 1 || code === 2)
            return "󰖕";
        if (code === 3)
            return "󰖐";
        if (code >= 45 && code <= 48)
            return "󰖑";
        if (code >= 51 && code <= 67)
            return "󰖗";
        if (code >= 71 && code <= 77)
            return "󰼶";
        if (code >= 80 && code <= 82)
            return "󰖘";
        if (code >= 85 && code <= 86)
            return "󰼶";
        if (code >= 95 && code <= 99)
            return "󰖓";
        return "󰖑";
    }

    function weatherDesc(code) {
        if (code === 0)
            return "Clear sky";
        if (code === 1)
            return "Mostly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code >= 45 && code <= 48)
            return "Foggy";
        if (code >= 51 && code <= 55)
            return "Drizzle";
        if (code >= 61 && code <= 67)
            return "Rainy";
        if (code >= 71 && code <= 77)
            return "Snowy";
        if (code >= 80 && code <= 82)
            return "Rain showers";
        if (code >= 85 && code <= 86)
            return "Snow showers";
        if (code >= 95 && code <= 99)
            return "Thunderstorm";
        return "Unknown";
    }

    Process {
        id: weatherReader
        command: ["curl", "-s", "https://api.open-meteo.com/v1/forecast?latitude=42.5987&longitude=-5.5671&current=temperature_2m,weathercode,windspeed_10m,relativehumidity_2m&timezone=Europe/Madrid"]

        property string buffer: ""

        stdout: SplitParser {
            onRead: function (line) {
                weatherReader.buffer += line;
            }
        }

        onRunningChanged: {
            if (!running) {
                try {
                    const data = JSON.parse(weatherReader.buffer);
                    const current = data.current;
                    root.weatherTemp = Math.round(current.temperature_2m) + "°C";
                    root.weatherCode = current.weathercode;
                    root.weatherWind = Math.round(current.windspeed_10m) + " km/h";
                    root.weatherHumidity = current.relativehumidity_2m + "%";
                    root.weatherLoading = false;
                } catch (e) {
                    console.log("weather parse error:", e);
                }
                weatherReader.buffer = "";
            }
        }
    }

    onVisibleChanged: if (visible)
        weatherReader.running = true

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: weatherReader.running = true
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: calendarPopout
            width: 390
            height: 230
            y: 0
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 8
            color: "#101010"
            border.color: "#2a2a2a"
            border.width: 1

            HoverHandler {
                onHoveredChanged: root.clockWidget.popupHovered = hovered
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
                anchors.margins: 12
                spacing: 8

                // Month + year header
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDateTime(new Date(), "MMMM yyyy")
                    color: "#eeeeee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Row {
                    width: parent.width
                    spacing: 12

                    // ── Left: calendar ───────────────────────────────────
                    Column {
                        spacing: 6

                        Grid {
                            columns: 7
                            spacing: 2

                            Repeater {
                                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                delegate: Text {
                                    required property string modelData
                                    width: 34
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData
                                    color: "#666666"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        Grid {
                            id: dayGrid
                            columns: 7
                            spacing: 3

                            property var now: new Date()
                            property int today: now.getDate()
                            property int currentMonth: now.getMonth() + 1
                            property int currentYear: now.getFullYear()
                            property int daysInMonth: new Date(currentYear, currentMonth, 0).getDate()
                            property int firstWeekday: (new Date(currentYear, currentMonth - 1, 1).getDay() + 6) % 7
                            property int totalCells: firstWeekday + daysInMonth

                            Repeater {
                                model: dayGrid.totalCells
                                delegate: Rectangle {
                                    required property int index
                                    width: 34
                                    height: 28
                                    radius: 4

                                    property int dayNum: index - dayGrid.firstWeekday + 1
                                    property bool isDay: index >= dayGrid.firstWeekday
                                    property bool isToday: isDay && dayNum === dayGrid.today

                                    color: isToday ? "#eeeeee" : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.isDay ? parent.dayNum : ""
                                        color: parent.isToday ? "#101010" : "#eeeeee"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                                    }
                                }
                            }
                        }
                    }

                    // ── Vertical divider ─────────────────────────────────
                    Rectangle {
                        width: 1
                        height: parent.height
                        color: "#2a2a2a"
                    }

                    // ── Right: weather ───────────────────────────────────
                    Column {
                        spacing: 10
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            visible: root.weatherLoading
                            text: "Loading\nweather..."
                            color: "#444444"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Column {
                            visible: !root.weatherLoading
                            spacing: 8

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.weatherIcon(root.weatherCode)
                                color: "#e8ae0e"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 32
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.weatherTemp
                                color: "#eeeeee"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 22
                                font.weight: Font.Bold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.weatherDesc(root.weatherCode)
                                color: "#666666"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            Rectangle {
                                width: 80
                                height: 1
                                color: "#2a2a2a"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 6
                                Text {
                                    text: "󰖝"
                                    color: "#8caaee"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.weatherWind
                                    color: "#aaaaaa"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 6
                                Text {
                                    text: ""
                                    color: "#8caaee"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.weatherHumidity
                                    color: "#aaaaaa"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
