pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "./components"

PanelWindow {
    id: bar
    required property ShellScreen targetScreen

    screen: targetScreen
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 45
    color: "transparent"
    exclusiveZone: implicitHeight

    property alias audioWidget: audioWidget
    property alias clockWidget: clockWidget
    property alias monitorsWidget: monitorsWidget

    Item {
        anchors.fill: parent

        WorkspacesWidget {
            id: workspacesWidget
            anchors.left: parent.left
            anchors.leftMargin: 19
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 10
            screen: bar.targetScreen
        }

        MonitorsWidget {
            id: monitorsWidget
            anchors.left: workspacesWidget.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 10
        }

        AudioWidget {
            id: audioWidget
            anchors.left: monitorsWidget.right
            anchors.leftMargin: -1
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 10
        }

        AIChatToggle {
            id: aiChatToggle
            targetScreen: bar.targetScreen
            anchors.left: audioWidget.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 10
        }

        NetworkWidget {
            id: networkWidget
            anchors.left: aiChatToggle.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 10
        }

        ClockWidget {
            id: clockWidget
            anchors.centerIn: parent
            height: parent.height - 10
        }

        CpuMemoryWidget {
            id: cpuMemoryWidget
            anchors.right: powerControlsWidget.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 10
        }

        PowerControlsWidget {
            id: powerControlsWidget
            anchors.right: parent.right
            anchors.rightMargin: 19
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 10
        }
    }
}
