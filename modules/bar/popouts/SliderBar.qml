import QtQuick

Item {
    id: slider
    required property string title
    required property int from
    required property int to
    property string suffix: ""
    property int value: from
    property real dragValue: -1
    property string fillColor: "#8caaee"
    property string labelColor: fillColor
    signal committed(int v)

    readonly property int effectiveValue: dragValue >= 0 ? Math.round(dragValue) : value

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.rightMargin: 8
    implicitHeight: 46

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 20
        height: 8
        radius: 4
        color: "#2a2a2a"

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * (slider.effectiveValue - slider.from) / (slider.to - slider.from)
            radius: parent.radius
            color: slider.fillColor
            opacity: slider.dragValue >= 0 ? 1 : 0.6

            Behavior on width {
                enabled: slider.dragValue < 0
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                }
            }
        }
    }

    Rectangle {
        id: thumb
        width: 18
        height: 18
        radius: width / 2
        color: slider.dragValue >= 0 ? "#ffffff" : "#dddddd"
        border.color: "#101010"
        border.width: 1
        y: track.y + (track.height - height) / 2
        x: track.x + (slider.effectiveValue - slider.from) / (slider.to - slider.from) * track.width - width / 2
        scale: slider.dragValue >= 0 ? 1.2 : 1.0

        Behavior on x {
            enabled: slider.dragValue < 0
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutBack
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }
    }

    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        text: slider.title
        color: "#888888"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
    }

    Text {
        id: valueText
        anchors.top: parent.top
        x: Math.max(0, Math.min(parent.width - width, thumb.x + thumb.width / 2 - width / 2))
        text: slider.effectiveValue + slider.suffix
        color: slider.labelColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.weight: Font.Bold
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: function (mouse) {
            updateVal(mouse.x);
        }
        onPositionChanged: function (mouse) {
            if (pressed)
                updateVal(mouse.x);
        }
        onReleased: slider.dragValue = -1

        function updateVal(mx) {
            let ratio = Math.max(0, Math.min(1, (mx - track.x) / track.width));
            let v = Math.round(slider.from + ratio * (slider.to - slider.from));
            slider.dragValue = v;
            slider.committed(v);
        }
    }
}
