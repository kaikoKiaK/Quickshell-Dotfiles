pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    property string modelName: "qwen3.5:9b"
    property string ollamaUrl: "http://127.0.0.1:11434/api/chat"
    property bool waitingForResponse: false
    signal escapePressed

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.escapePressed();
            event.accepted = true;
        }
    }

    ListModel {
        id: chatModel
    }

    function clearChat() {
        chatModel.clear();
    }

    function focusInput() {
        inputField.forceActiveFocus();
    }

    function parseSegments(msgText) {
        const segments = [];
        const codeBlockRegex = /```(\w*)\n([\s\S]*?)```/g;
        let lastIndex = 0;
        let match;

        while ((match = codeBlockRegex.exec(msgText)) !== null) {
            if (match.index > lastIndex) {
                segments.push({
                    type: "text",
                    content: msgText.slice(lastIndex, match.index)
                });
            }
            segments.push({
                type: "code",
                language: match[1],
                content: match[2].replace(/\n$/, "")
            });
            lastIndex = codeBlockRegex.lastIndex;
        }

        if (lastIndex < msgText.length) {
            segments.push({
                type: "text",
                content: msgText.slice(lastIndex)
            });
        }

        if (segments.length === 0) {
            segments.push({
                type: "text",
                content: msgText
            });
        }

        return segments;
    }

    function buildHistory() {
        let history = [];
        for (let i = 0; i < chatModel.count; i++) {
            let m = chatModel.get(i);
            history.push({
                role: m.msgRole,
                content: m.msgText
            });
        }
        return history;
    }

    function sendMessage(userText) {
        if (userText.trim().length === 0 || waitingForResponse)
            return;
        chatModel.append({
            msgRole: "user",
            msgText: userText,
            msgDone: true
        });
        const historyForRequest = buildHistory();
        chatModel.append({
            msgRole: "assistant",
            msgText: "",
            msgDone: false
        });
        const assistantIndex = chatModel.count - 1;
        waitingForResponse = true;

        let accumulatedText = "";
        let processedLength = 0;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", root.ollamaUrl);
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.LOADING || xhr.readyState === XMLHttpRequest.DONE) {
                const newText = xhr.responseText.substring(processedLength);
                processedLength = xhr.responseText.length;

                if (newText.length > 0) {
                    const lines = newText.split("\n");
                    for (let i = 0; i < lines.length; i++) {
                        const line = lines[i].trim();
                        if (line.length === 0)
                            continue;
                        try {
                            const chunk = JSON.parse(line);
                            if (chunk.message && chunk.message.content) {
                                accumulatedText += chunk.message.content;
                                chatModel.set(assistantIndex, {
                                    msgRole: "assistant",
                                    msgText: accumulatedText,
                                    msgDone: false
                                });
                            }
                        } catch (e) {
                            // incomplete line straddling a chunk boundary, ignore
                        }
                    }
                }
            }

            if (xhr.readyState === XMLHttpRequest.DONE) {
                waitingForResponse = false;
                if (xhr.status === 200) {
                    chatModel.set(assistantIndex, {
                        msgRole: "assistant",
                        msgText: accumulatedText,
                        msgDone: true
                    });
                } else if (accumulatedText.length === 0) {
                    chatModel.set(assistantIndex, {
                        msgRole: "assistant",
                        msgText: "Error reaching Ollama (status " + xhr.status + "). Is `ollama serve` running?",
                        msgDone: true
                    });
                }
            }
        };

        xhr.send(JSON.stringify({
            model: root.modelName,
            messages: historyForRequest,
            stream: true,
            think: false
        }));
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

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
                        sourceComponent: msgDone ? formattedComponent : plainComponent
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
                placeholderText: "Ask something..."
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
