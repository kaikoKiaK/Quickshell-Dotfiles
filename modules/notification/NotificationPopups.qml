import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 10
        right: 10
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notifications"
    color: "transparent"

    implicitWidth: 360
    implicitHeight: col.implicitHeight
    visible: !NotificationService.dnd && NotificationService.popups.values.length > 0

    mask: Region {
        item: col
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 8

        Repeater {
            model: NotificationService.popups
            NotificationCard {
                Layout.fillWidth: true
            }
        }
    }
}
