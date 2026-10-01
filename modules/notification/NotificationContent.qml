pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

ColumnLayout {
    id: root
    property Notification notif: null
    spacing: 6

    readonly property string iconSource: {
        if (!notif)
            return "";
        if (notif.image !== "")
            return notif.image;
        if (notif.appIcon === "")
            return "";
        if (notif.appIcon.startsWith("/"))
            return "file://" + notif.appIcon;
        return Quickshell.iconPath(notif.appIcon, true);
    }
    // qmllint disable unresolved-type
    readonly property var actionList: notif ? notif.actions : []

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Image {
            visible: root.iconSource !== ""
            source: root.iconSource
            sourceSize: Qt.size(40, 40)
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.notif ? root.notif.appName : ""
                color: "#888888"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.notif ? root.notif.summary : ""
                color: "#eeeeee"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }

    Text {
        visible: text !== ""
        Layout.fillWidth: true
        text: root.notif ? root.notif.body : ""
        textFormat: Text.StyledText
        color: "#cccccc"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        wrapMode: Text.WordWrap
        maximumLineCount: 4
        elide: Text.ElideRight
    }

    RowLayout {
        visible: root.notif !== null && root.actionList.length > 0
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.actionList

            delegate: Rectangle {
                id: btn
                required property NotificationAction modelData

                implicitWidth: label.implicitWidth + 20
                implicitHeight: 26
                radius: 6
                color: btnMouse.containsMouse ? "#2a2a2a" : "#1a1a1a"
                border.width: 1
                border.color: "#333333"

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: btn.modelData.text
                    color: "#eeeeee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: btn.modelData.invoke()
                }
            }
        }
    }
}
