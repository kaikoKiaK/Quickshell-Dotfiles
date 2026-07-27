pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "logic.js" as Logic

Item {
    id: root
    property string modelName: "gemma4:e2b"
    property string ollamaUrl: "http://127.0.0.1:11434/api/chat"
    property bool waitingForResponse: false
    property var availableModels: []
    signal escapePressed

    Component.onCompleted: fetchModels()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.escapePressed();
            event.accepted = true;
        }
    }

    ListModel {
        id: chatModel
    }

    function fetchModels() {
        Logic.fetchModels(root);
    }
    function clearChat() {
        Logic.clearChat(chatModel);
    }
    function focusInput() {
        Logic.focusInput(inputField);
    }
    function parseSegments(msgText) {
        return Logic.parseSegments(msgText);
    }
    function buildHistory() {
        return Logic.buildHistory(chatModel);
    }
    function sendMessage(userText) {
        Logic.sendMessage(userText, root, chatModel, inputField);
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            ComboBox {
                id: modelSelector
                Layout.preferredWidth: 200
                Layout.preferredHeight: 28
                model: root.availableModels
                currentIndex: availableModels.indexOf(root.modelName)
                onActivated: root.modelName = availableModels[currentIndex]

                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15

                contentItem: Text {
                    text: modelSelector.displayText
                    color: "#eeeeee"
                    font: modelSelector.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    color: "#1e1f20"
                    radius: 7
                    border.color: "#3a3a3a"
                    border.width: 1
                }

                popup: Popup {
                    y: modelSelector.height + 4
                    width: modelSelector.width
                    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
                    padding: 4

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: modelSelector.popup.visible ? modelSelector.delegateModel : null

                        ScrollIndicator.vertical: ScrollIndicator {}
                    }

                    background: Rectangle {
                        color: "#1e1f20"
                        radius: 7
                        border.color: "#3a3a3a"
                        border.width: 1
                    }
                }

                delegate: ItemDelegate {
                    id: delegateItem
                    required property var modelData
                    required property int index

                    width: modelSelector.width
                    contentItem: Text {
                        text: delegateItem.modelData
                        color: "#eeeeee"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                    highlighted: modelSelector.highlightedIndex === delegateItem.index
                    background: Rectangle {
                        color: delegateItem.highlighted ? "#2a2a2a" : "transparent"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RoundButton {
                id: clearButton
                implicitWidth: 32
                implicitHeight: 32
                onClicked: root.clearChat()

                HoverHandler {
                    id: hoverHandler
                }

                contentItem: Item {
                    anchors.fill: parent

                    Item {
                        id: iconWrapper
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        scale: hoverHandler.hovered ? 1.1 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                        }

                        Image {
                            id: clearIconSource
                            anchors.fill: parent
                            source: "../bar/sources/svgs/clearBrush.svg"
                            sourceSize.width: 16
                            sourceSize.height: 16
                            fillMode: Image.PreserveAspectFit
                            visible: false
                            cache: false
                        }

                        MultiEffect {
                            anchors.fill: clearIconSource
                            source: clearIconSource
                            colorization: 1.0
                            colorizationColor: "#eeeeee"
                        }
                    }
                }
                background: Rectangle {
                    radius: width / 2
                    color: clearButton.hovered ? "#2a2a2a" : "transparent"
                    border.color: "#3a3a3a"
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                }
            }
        }

        ListView {
            id: chatView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: chatModel
            spacing: 6
            clip: true

            delegate: Item {
                required property string msgRole
                required property string msgText
                required property bool msgDone
                width: chatView.width
                height: bubble.height + 8

                Rectangle {
                    id: bubble
                    width: Math.min(bubbleContent.implicitWidth + 16, chatView.width * 0.9)
                    height: bubbleContent.implicitHeight + 16
                    anchors.right: msgRole === "user" ? parent.right : undefined
                    anchors.left: msgRole === "user" ? undefined : parent.left
                    radius: 10
                    color: msgRole === "user" ? "#8caaee" : "#1c1c1c"

                    Loader {
                        id: bubbleContent
                        anchors.fill: parent
                        anchors.margins: 8
                        sourceComponent: !msgDone && msgText === "" ? thinkingComponent : msgDone ? formattedComponent : plainComponent
                    }

                    Component {
                        id: thinkingComponent
                        Item {
                            implicitWidth: 30
                            implicitHeight: 20

                            readonly property real dotSize: 6
                            readonly property real baseY: implicitHeight / 2 - dotSize / 2

                            property real offset0: 0
                            property real offset1: 0
                            property real offset2: 0

                            Rectangle {
                                x: 2
                                y: baseY + offset0
                                width: dotSize
                                height: dotSize
                                radius: dotSize / 2
                                color: "#eeeeee"
                            }
                            Rectangle {
                                x: 12
                                y: baseY + offset1
                                width: dotSize
                                height: dotSize
                                radius: dotSize / 2
                                color: "#eeeeee"
                            }
                            Rectangle {
                                x: 22
                                y: baseY + offset2
                                width: dotSize
                                height: dotSize
                                radius: dotSize / 2
                                color: "#eeeeee"
                            }

                            SequentialAnimation on offset0 {
                                loops: Animation.Infinite
                                PropertyAnimation {
                                    to: -6
                                    duration: 300
                                    easing.type: Easing.OutQuad
                                }
                                PropertyAnimation {
                                    to: 0
                                    duration: 300
                                    easing.type: Easing.InQuad
                                }
                                PauseAnimation {
                                    duration: 400
                                }
                            }

                            SequentialAnimation on offset1 {
                                loops: Animation.Infinite
                                PauseAnimation {
                                    duration: 200
                                }
                                PropertyAnimation {
                                    to: -6
                                    duration: 300
                                    easing.type: Easing.OutQuad
                                }
                                PropertyAnimation {
                                    to: 0
                                    duration: 300
                                    easing.type: Easing.InQuad
                                }
                                PauseAnimation {
                                    duration: 200
                                }
                            }

                            SequentialAnimation on offset2 {
                                loops: Animation.Infinite
                                PauseAnimation {
                                    duration: 400
                                }
                                PropertyAnimation {
                                    to: -6
                                    duration: 300
                                    easing.type: Easing.OutQuad
                                }
                                PropertyAnimation {
                                    to: 0
                                    duration: 300
                                    easing.type: Easing.InQuad
                                }
                            }
                        }
                    }

                    Component {
                        id: plainComponent
                        Text {
                            width: Math.min(implicitWidth, chatView.width * 0.75)
                            text: msgText
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: msgRole === "user" ? "#101010" : "#eeeeee"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                        }
                    }

                    Component {
                        id: formattedComponent
                        Column {
                            id: contentColumn
                            spacing: 6

                            Repeater {
                                model: root.parseSegments(msgText)

                                delegate: Loader {
                                    required property var modelData
                                    sourceComponent: modelData.type === "code" ? codeBlockComponent : textComponent

                                    property var segmentData: modelData

                                    Component {
                                        id: textComponent
                                        Text {
                                            width: Math.min(implicitWidth, chatView.width * 0.75)
                                            text: segmentData.content
                                            textFormat: Text.MarkdownText
                                            wrapMode: Text.Wrap
                                            color: msgRole === "user" ? "#101010" : "#eeeeee"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 15
                                        }
                                    }

                                    Component {
                                        id: codeBlockComponent
                                        Rectangle {
                                            width: codeText.implicitWidth + 20
                                            height: codeText.implicitHeight + 20
                                            radius: 6
                                            color: "#0d0d0d"
                                            border.color: "#333333"
                                            border.width: 1

                                            Text {
                                                id: codeText
                                                anchors.margins: 10
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                width: Math.min(implicitWidth, chatView.width * 0.75) - 20
                                                text: segmentData.content
                                                wrapMode: Text.Wrap
                                                color: "#a6e3a1"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 13
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            TextField {
                id: inputField
                Layout.fillWidth: true
                placeholderText: "Ask anything..."
                color: "#eeeeee"
                placeholderTextColor: "#888888"
                padding: 10
                font.family: "JetBrainsMono Nerd Font"
                background: Rectangle {
                    color: "#1e1f20"
                    radius: 7
                }
                onAccepted: {
                    root.sendMessage(text);
                    text = "";
                }
            }

            RoundButton {
                text: ""
                implicitWidth: 40
                implicitHeight: 40
                font.pixelSize: 18
                enabled: !root.waitingForResponse
                rightPadding: 8
                onClicked: {
                    root.sendMessage(inputField.text);
                    inputField.text = "";
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
