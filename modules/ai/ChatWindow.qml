pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
            msgText: userText
        });
        const historyForRequest = buildHistory(); // snapshot before placeholder
        chatModel.append({
            msgRole: "assistant",
            msgText: "…"
        });
        const assistantIndex = chatModel.count - 1;
        waitingForResponse = true;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", root.ollamaUrl);
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                waitingForResponse = false;
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        chatModel.set(assistantIndex, {
                            msgRole: "assistant",
                            msgText: response.message.content
                        });
                    } catch (e) {
                        chatModel.set(assistantIndex, {
                            msgRole: "assistant",
                            msgText: "Parse error: " + e
                        });
                    }
                } else {
                    chatModel.set(assistantIndex, {
                        msgRole: "assistant",
                        msgText: "Error reaching Ollama (status " + xhr.status + "). Is `ollama serve` running?"
                    });
                }
            }
        };

        xhr.send(JSON.stringify({
            model: root.modelName,
            messages: historyForRequest,
            stream: false,
            think: false
        }));
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

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
                width: chatView.width
                height: bubble.height + 8

                Rectangle {
                    id: bubble
                    width: Math.min(contentColumn.implicitWidth + 16, chatView.width * 0.9)
                    height: contentColumn.implicitHeight + 16
                    anchors.right: msgRole === "user" ? parent.right : undefined
                    anchors.left: msgRole === "user" ? undefined : parent.left
                    radius: 10
                    color: msgRole === "user" ? "#8caaee" : "#1c1c1c"

                    Column {
                        id: contentColumn
                        anchors.fill: parent
                        anchors.margins: 8
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
