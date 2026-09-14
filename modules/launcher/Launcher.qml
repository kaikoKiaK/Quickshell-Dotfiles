pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "./components"

PanelWindow {
    id: root

    // ── Public API ──────────────────────────────────────────────────────────
    required property ShellScreen targetScreen
    property bool launcherVisible: false
    signal closeRequested

    // ── Window setup ────────────────────────────────────────────────────────
    screen: targetScreen
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: 0
    color: "transparent"
    visible: root.launcherVisible
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ── Filtered app list ─────────────────────────────────────────────────
    property int selectedIndex: 0

    property var filteredApps: {
        var apps = DesktopEntries.applications.values.filter(function (e) {
            return !e.noDisplay;
        });
        var query = searchField.text.toLowerCase().trim();
        if (query !== "") {
            apps = apps.filter(function (e) {
                return e.name.toLowerCase().includes(query) || (e.genericName && e.genericName.toLowerCase().includes(query));
            });
        }
        apps.sort(function (a, b) {
            return a.name.localeCompare(b.name);
        });
        return apps;
    }

    // ── File search results (populated asynchronously by fileSearchProcess) ─
    property var fileResults: []

    // ── Combined results shown in the list (apps first, then matching files)
    property var combinedResults: {
        var apps = root.filteredApps.map(function (e) {
            return {
                kind: "app",
                name: e.name,
                icon: e.icon,
                appData: e
            };
        });
        var query = searchField.text.trim();
        if (query.length >= 2)
            return apps.concat(root.fileResults);
        return apps;
    }

    // Maps a file extension to a freedesktop mimetype icon name (resolved
    // through the current icon theme via Quickshell.iconPath) and a Nerd
    // Font glyph to use if the theme doesn't have that icon.
    readonly property var fileIconMap: ({
            // documents
            pdf: {
                icon: "application-pdf",
                glyph: ""
            },
            doc: {
                icon: "x-office-document",
                glyph: ""
            },
            docx: {
                icon: "x-office-document",
                glyph: ""
            },
            odt: {
                icon: "x-office-document",
                glyph: ""
            },
            xls: {
                icon: "x-office-spreadsheet",
                glyph: ""
            },
            xlsx: {
                icon: "x-office-spreadsheet",
                glyph: ""
            },
            ods: {
                icon: "x-office-spreadsheet",
                glyph: ""
            },
            csv: {
                icon: "x-office-spreadsheet",
                glyph: ""
            },
            ppt: {
                icon: "x-office-presentation",
                glyph: ""
            },
            pptx: {
                icon: "x-office-presentation",
                glyph: ""
            },
            odp: {
                icon: "x-office-presentation",
                glyph: ""
            },
            txt: {
                icon: "text-x-generic",
                glyph: ""
            },
            md: {
                icon: "text-x-generic",
                glyph: ""
            },
            log: {
                icon: "text-x-generic",
                glyph: ""
            },
            // images
            png: {
                icon: "image-x-generic",
                glyph: ""
            },
            jpg: {
                icon: "image-x-generic",
                glyph: ""
            },
            jpeg: {
                icon: "image-x-generic",
                glyph: ""
            },
            gif: {
                icon: "image-x-generic",
                glyph: ""
            },
            webp: {
                icon: "image-x-generic",
                glyph: ""
            },
            svg: {
                icon: "image-x-generic",
                glyph: ""
            },
            bmp: {
                icon: "image-x-generic",
                glyph: ""
            },
            // audio
            mp3: {
                icon: "audio-x-generic",
                glyph: ""
            },
            flac: {
                icon: "audio-x-generic",
                glyph: ""
            },
            wav: {
                icon: "audio-x-generic",
                glyph: ""
            },
            ogg: {
                icon: "audio-x-generic",
                glyph: ""
            },
            // video
            mp4: {
                icon: "video-x-generic",
                glyph: ""
            },
            mkv: {
                icon: "video-x-generic",
                glyph: ""
            },
            webm: {
                icon: "video-x-generic",
                glyph: ""
            },
            avi: {
                icon: "video-x-generic",
                glyph: ""
            },
            mov: {
                icon: "video-x-generic",
                glyph: ""
            },
            // archives
            zip: {
                icon: "package-x-generic",
                glyph: ""
            },
            tar: {
                icon: "package-x-generic",
                glyph: ""
            },
            gz: {
                icon: "package-x-generic",
                glyph: ""
            },
            xz: {
                icon: "package-x-generic",
                glyph: ""
            },
            "7z": {
                icon: "package-x-generic",
                glyph: ""
            },
            rar: {
                icon: "package-x-generic",
                glyph: ""
            },
            // code
            js: {
                icon: "text-x-script",
                glyph: ""
            },
            ts: {
                icon: "text-x-script",
                glyph: ""
            },
            py: {
                icon: "text-x-script",
                glyph: ""
            },
            sh: {
                icon: "text-x-script",
                glyph: ""
            },
            qml: {
                icon: "text-x-script",
                glyph: ""
            },
            c: {
                icon: "text-x-csrc",
                glyph: ""
            },
            cpp: {
                icon: "text-x-c++src",
                glyph: ""
            },
            h: {
                icon: "text-x-chdr",
                glyph: ""
            },
            rs: {
                icon: "text-x-rust",
                glyph: ""
            },
            go: {
                icon: "text-x-go",
                glyph: ""
            },
            json: {
                icon: "application-json",
                glyph: ""
            },
            html: {
                icon: "text-html",
                glyph: ""
            },
            css: {
                icon: "text-css",
                glyph: ""
            }
        })

    function fileIconFor(name) {
        var dot = name.lastIndexOf(".");
        var ext = dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
        var entry = root.fileIconMap[ext];
        if (entry)
            return entry;
        return {
            icon: "text-x-generic",
            glyph: ""
        };
    }

    // ── File search process ─────────────────────────────────────────────────
    // Debounced so we don't spawn a search on every keystroke.
    Timer {
        id: fileSearchDebounce
        interval: 180
        repeat: false
        onTriggered: root.runFileSearch(searchField.text.trim())
    }

    Process {
        id: fileSearchProcess
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                var path = line.trim();
                if (path === "")
                    return;
                var parts = path.split("/");
                var name = parts[parts.length - 1];
                var dir = parts.slice(0, -1).join("/");
                var home = Quickshell.env("HOME");
                if (home && dir.indexOf(home) === 0)
                    dir = "~" + dir.slice(home.length);
                var iconInfo = root.fileIconFor(name);
                root.fileResults = root.fileResults.concat([
                    {
                        kind: "file",
                        name: name,
                        path: path,
                        dir: dir,
                        icon: iconInfo.icon,
                        glyph: iconInfo.glyph
                    }
                ]);
            }
        }
    }

    function runFileSearch(query) {
        if (query.length < 2) {
            root.fileResults = [];
            return;
        }
        root.fileResults = [];
        var home = Quickshell.env("HOME") || "";
        fileSearchProcess.exec({
            command: ["fd", "--type", "f", "--max-results", "30", "--", query, home]
        });
    }

    // ── Focus & reset when shown ──────────────────────────────────────────
    onLauncherVisibleChanged: {
        if (launcherVisible) {
            searchField.text = "";
            root.selectedIndex = 0;
            root.fileResults = [];
            searchField.forceActiveFocus();
        } else {
            fileSearchProcess.running = false;
        }
    }

    function launchSelected() {
        if (root.combinedResults.length === 0)
            return;
        var entry = root.combinedResults[root.selectedIndex];
        if (entry.kind === "app") {
            entry.appData.execute();
        } else if (entry.kind === "file") {
            Quickshell.execDetached(["xdg-open", entry.path]);
        }
        root.close();
    }

    function close() {
        searchField.text = "";
        root.selectedIndex = 0;
        root.fileResults = [];
        fileSearchProcess.running = false;
        root.closeRequested();
    }

    // ── Overlay backdrop ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.launcherVisible ? 0.55 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        TapHandler {
            onTapped: root.close()
        }
    }

    // ── Launcher panel ────────────────────────────────────────────────────
    Rectangle {
        id: panel
        width: 560
        height: column.implicitHeight + 24
        anchors.centerIn: parent

        radius: 12
        color: "#101010"
        border.color: "#2a2a2a"
        border.width: 1

        opacity: root.launcherVisible ? 1 : 0
        scale: root.launcherVisible ? 1 : 0.96
        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        // Subtle glow border
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: "#8caaee"
            border.width: 1
            opacity: 0.25
        }

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            // ── Search row ───────────────────────────────────────────────
            Row {
                id: searchRow
                width: parent.width
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: "#8caaee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                }

                TextInput {
                    id: searchField
                    width: parent.width - 28
                    height: 40
                    color: "#eeeeee"
                    selectionColor: "#8caaee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search applications and files..."
                        color: "#444444"
                        font: searchField.font
                        visible: searchField.text === ""
                    }

                    onTextChanged: {
                        root.selectedIndex = 0;
                        var query = searchField.text.trim();
                        if (query.length < 2) {
                            fileSearchDebounce.stop();
                            fileSearchProcess.running = false;
                            root.fileResults = [];
                        } else {
                            fileSearchDebounce.restart();
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            if (root.selectedIndex < root.combinedResults.length - 1)
                                root.selectedIndex++;
                            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (root.selectedIndex > 0)
                                root.selectedIndex--;
                            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launchSelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            root.close();
                            event.accepted = true;
                        }
                    }
                }
            }

            // ── Divider ──────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 1
                color: "#2a2a2a"
            }

            // ── Results list ────────────────────────────────────────────
            Item {
                width: parent.width
                height: listView.height
                implicitHeight: height

                ListView {
                    id: listView
                    anchors.left: parent.left
                    anchors.right: scrollBar.left
                    anchors.rightMargin: 4
                    height: Math.min(5 * 44 + 4 * 2 + 8 + 4, contentHeight + topMargin + bottomMargin)
                    clip: true
                    model: root.combinedResults
                    spacing: 2
                    topMargin: 8
                    bottomMargin: 4
                    boundsBehavior: Flickable.StopAtBounds

                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "y"
                            from: listView.y + 8
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }

                    remove: Transition {
                        NumberAnimation {
                            property: "opacity"
                            to: 0
                            duration: 80
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            property: "y"
                            to: listView.y + 8
                            duration: 80
                            easing.type: Easing.InCubic
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.combinedResults.length === 0
                        text: "No results"
                        color: "#444444"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }

                    delegate: Item {
                        id: delegateRoot
                        required property var modelData
                        required property int index
                        width: listView.width
                        height: modelData.kind === "app" ? 44 : 46

                        Loader {
                            anchors.fill: parent
                            sourceComponent: delegateRoot.modelData.kind === "app" ? appComponent : fileComponent
                        }

                        Component {
                            id: appComponent
                            AppEntry {
                                appName: delegateRoot.modelData.name
                                appIcon: delegateRoot.modelData.icon
                                appExec: ""
                                isSelected: delegateRoot.index === root.selectedIndex
                                itemIndex: delegateRoot.index
                                width: listView.width

                                onActivated: root.launchSelected()
                                onHoverChanged: idx => root.selectedIndex = idx
                            }
                        }

                        Component {
                            id: fileComponent
                            FileEntry {
                                fileName: delegateRoot.modelData.name
                                fileDir: delegateRoot.modelData.dir
                                fileIcon: delegateRoot.modelData.icon
                                fallbackGlyph: delegateRoot.modelData.glyph
                                isSelected: delegateRoot.index === root.selectedIndex
                                itemIndex: delegateRoot.index
                                width: listView.width

                                onActivated: root.launchSelected()
                                onHoverChanged: idx => root.selectedIndex = idx
                            }
                        }
                    }
                }

                ScrollBar {
                    id: scrollBar
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    policy: ScrollBar.AsNeeded
                    size: listView.visibleArea.heightRatio
                    position: listView.visibleArea.yPosition
                    onPositionChanged: {
                        if (pressed)
                            listView.contentY = position * listView.contentHeight;
                    }
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: "#555555"
                    }
                    background: Item {}
                }
            }
        }
    }
}
