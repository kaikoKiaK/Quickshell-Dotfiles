pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property Notification current: null
    property int holds: 0   // > 0 while a clock card is hovered
    readonly property alias popups: server.trackedNotifications

    function arm() {
        const n = root.current;
        if (n && root.holds === 0 && n.urgency !== NotificationUrgency.Critical)
            revertTimer.restart();
        else
            revertTimer.stop();
    }
    onCurrentChanged: arm()
    onHoldsChanged: arm()

    Timer {
        id: revertTimer
        interval: 5000
        onTriggered: {
            if (root.current)
                root.current.expire();   // drops it from trackedNotifications
            root.current = null;
        }
    }

    Connections {
        target: root.current
        function onClosed() {
            root.current = null;
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            if (root.dnd)
                return;
            if (root.current && root.current !== n)
                root.current.expire();
            root.current = n;
        }
    }
}
