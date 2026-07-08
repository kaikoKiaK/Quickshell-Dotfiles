pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects
import "../../ai"

Item {
    id: root
    required property ShellScreen targetScreen
    property bool popoutOpen: false

    implicitWidth: iconWrapper.implicitWidth + 34
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        color: "#101010"

        Rectangle {
            anchors.fill: parent
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
            color: "#ffffff"
            opacity: hoverHandler.hovered ? 0.06 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        HoverHandler {
            id: hoverHandler
        }

        Item {
            id: iconWrapper
            width: 20
            height: 20
            anchors.centerIn: parent
            scale: hoverHandler.hovered ? 1.15 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutBack
                }
            }

            Image {
                id: iconSource
                anchors.fill: parent
                source: root.popoutOpen ? "../sources/svgs/robotFilled.svg" : "../sources/svgs/robotHollow.svg"
                sourceSize.width: iconWrapper.width
                sourceSize.height: iconWrapper.height
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            MultiEffect {
                anchors.fill: iconSource
                source: iconSource
                colorization: 1.0
                colorizationColor: "#eeeeee"

                Behavior on colorizationColor {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.popoutOpen = !root.popoutOpen
        }

        Loader {
            id: popoutLoader
            active: true
            sourceComponent: popoutComponent
        }
    }

    Component {
        id: popoutComponent

        PanelWindow {
            id: chatPanel
            screen: root.targetScreen
            visible: root.popoutOpen

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            onVisibleChanged: {
                if (visible) {
                    Qt.callLater(chatWindowInstance.focusInput);
                }
            }

            anchors {
                top: true
                left: true
            }

            implicitWidth: 560
            implicitHeight: 1030

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                topLeftRadius: 0
                bottomLeftRadius: 0
                topRightRadius: 8
                bottomRightRadius: 8
                color: "#101010"
                border.color: "#2a2a2a"
                border.width: 1

                ChatWindow {
                    id: chatWindowInstance
                    anchors.fill: parent
                    anchors.margins: 16
                    onEscapePressed: root.popoutOpen = false
                }
            }
        }
    }
}
