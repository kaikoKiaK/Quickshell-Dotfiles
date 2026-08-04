function fetchModels(root) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", "http://127.0.0.1:11434/api/tags");
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
            try {
                const response = JSON.parse(xhr.responseText);
                const names = response.models.map(m => m.name);
                root.availableModels = names;
                if (names.indexOf(root.modelName) === -1 && names.length > 0) {
                    root.modelName = names[0];
                }
            } catch (e) {
                console.log("Failed to parse model list:", e);
            }
        }
    };
    xhr.send();
}

function clearChat(chatModel) {
    chatModel.clear();
}

function focusInput(inputField) {
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

function buildHistory(chatModel) {
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

function sendMessage(userText, root, chatModel, inputField) {
    if (userText.trim().length === 0 || root.waitingForResponse)
        return;
    chatModel.append({
        msgRole: "user",
        msgText: userText,
        msgDone: true
    });
    const historyForRequest = buildHistory(chatModel);
    chatModel.append({
        msgRole: "assistant",
        msgText: "",
        msgDone: false
    });
    const assistantIndex = chatModel.count - 1;
    root.waitingForResponse = true;

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
                    }
                }
            }
        }

        if (xhr.readyState === XMLHttpRequest.DONE) {
            root.waitingForResponse = false;
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
