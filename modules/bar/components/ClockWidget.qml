import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: label.implicitWidth + 26
    implicitHeight: parent.height

    // Expose hover state so shell.qml can drive the popup window
    readonly property bool showCalendar: hoverHandler.hovered

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    property string timeText: Qt.formatDateTime(clock.date, "dd - hh:mm")

    Rectangle {
        anchors.fill: parent
        color: "#101010"
        radius: 5

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
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
            opacity: hoverHandler.hovered ? 0.06 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.timeText
            color: "#eeeeee"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            font.weight: Font.Bold
        }

        HoverHandler {
            id: hoverHandler
        }
    }
}
