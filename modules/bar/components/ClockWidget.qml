import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../../notification/"

Item {
    id: root

    readonly property real baseHeight: parent.height - 10
    readonly property real cardWidth: 360

    property bool popupHovered: false
    property bool _showPopup: false

    readonly property Notification notif: NotificationService.current
    readonly property bool morphed: notif !== null && !NotificationService.dnd

    // keep showing the last notification while we fade/shrink back
    property Notification lastNotif: null
    onNotifChanged: if (notif)
        lastNotif = notif
    readonly property Notification shown: notif ? notif : lastNotif

    readonly property bool showCalendar: !morphed && (_showPopup || popupHovered)

    implicitWidth: morphed ? cardWidth : label.implicitWidth + 26
    implicitHeight: morphed ? details.implicitHeight + 30 : baseHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    readonly property color accent: {
        if (!shown)
            return "#5b9bd5";
        if (shown.urgency === NotificationUrgency.Critical)
            return "#e05555";
        if (shown.urgency === NotificationUrgency.Low)
            return "#888888";
        return "#5b9bd5";
    }

    // pause the 5s countdown while the card is hovered (counter, so multi-monitor is safe)
    property bool _holding: false
    function updateHold() {
        const want = morphed && hoverHandler.hovered;
        if (want === _holding)
            return;
        _holding = want;
        NotificationService.holds += want ? 1 : -1;
    }
    onMorphedChanged: updateHold()
    Component.onDestruction: {
        if (_holding)
            NotificationService.holds -= 1;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    property string timeText: Qt.formatDateTime(clock.date, "dd - hh:mm")

    Rectangle {
        anchors.fill: parent
        color: "#101010"
        radius: root.morphed ? 10 : 5
        clip: true
        Behavior on radius {
            NumberAnimation {
                duration: 280
            }
        }

        // border: white on hover, accent while morphed
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: root.morphed ? (hoverHandler.hovered ? root.accent : "#2a2a2a") : "#eeeeee"
            border.width: 1
            opacity: root.morphed ? 1 : (hoverHandler.hovered ? 0.35 : 0)
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
            opacity: !root.morphed && hoverHandler.hovered ? 0.06 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        // click anywhere on the card to dismiss (buttons sit above this)
        MouseArea {
            anchors.fill: parent
            enabled: root.morphed
            onClicked: {
                if (NotificationService.current)
                    NotificationService.current.dismiss();
                NotificationService.current = null;
            }
        }

        // ---- clock face (pinned to the top strip so it doesn't drift while resizing) ----
        Text {
            id: label
            x: (parent.width - width) / 2
            y: (root.baseHeight - height) / 2
            text: root.timeText
            color: "#eeeeee"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            font.weight: Font.Bold
            opacity: root.morphed ? 0 : 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        // ---- card face ----
        Rectangle {
            width: parent.width / 3
            height: 3
            radius: 2
            color: root.accent
            opacity: root.morphed ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
            anchors {
                top: parent.top
                topMargin: 7
                horizontalCenter: parent.horizontalCenter
            }
        }

        NotificationContent {
            id: details
            notif: root.shown
            x: 12
            y: 18
            width: root.cardWidth - 24   // fixed, so text never re-wraps mid-animation
            opacity: root.morphed ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                root.updateHold();
                if (root.morphed)
                    return;
                if (hovered) {
                    hidetimer.stop();
                    root._showPopup = true;
                } else {
                    hidetimer.restart();
                }
            }
        }

        Timer {
            id: hidetimer
            interval: 300
            onTriggered: root._showPopup = false
        }
    }
}
