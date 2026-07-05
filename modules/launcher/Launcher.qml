pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
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

    // ── Focus & reset when shown ──────────────────────────────────────────
    onLauncherVisibleChanged: {
        if (launcherVisible) {
            searchField.text = "";
            root.selectedIndex = 0;
            searchField.forceActiveFocus();
        }
    }

    function launchSelected() {
        if (root.filteredApps.length === 0)
            return;
        root.filteredApps[root.selectedIndex].execute();
        root.close();
    }

    function close() {
        searchField.text = "";
        root.selectedIndex = 0;
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
                        text: "Search applications..."
                        color: "#444444"
                        font: searchField.font
                        visible: searchField.text === ""
                    }

                    onTextChanged: root.selectedIndex = 0

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            if (root.selectedIndex < root.filteredApps.length - 1)
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

            // ── App list ─────────────────────────────────────────────────
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
                    model: root.filteredApps
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
                        visible: root.filteredApps.length === 0
                        text: "No results"
                        color: "#444444"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }

                    delegate: AppEntry {
                        required property var modelData
                        required property int index

                        appName: modelData.name
                        appIcon: modelData.icon
                        appExec: ""
                        isSelected: index === root.selectedIndex
                        itemIndex: index
                        width: listView.width

                        onActivated: root.launchSelected()
                        onHoverChanged: idx => root.selectedIndex = idx
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
