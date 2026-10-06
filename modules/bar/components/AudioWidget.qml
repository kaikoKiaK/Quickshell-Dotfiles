import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: mainRow.implicitWidth + 26
    implicitHeight: parent.height

    property int volume: 0
    property bool muted: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaStatus: "Stopped"
    property bool isPlaying: mediaStatus !== "Paused" && mediaTitle !== ""
    property alias mediaPlay: mediaPlay
    property alias mediaNext: mediaNext
    property alias mediaPrevious: mediaPrevious
    property bool popupHovered: false
    property bool _showPopup: false
    readonly property bool showMediaPopup: _showPopup || popupHovered
    property real mediaPosition: 0
    property real mediaDuration: 0
    property var mediaPlayers: []
    property var mediaPlayerVolumes: []
    property var mediaPlayersMeta: []
    property int selectedPlayerIndex: 0
    readonly property string currentPlayerName: (selectedPlayerIndex >= 0 && selectedPlayerIndex < mediaPlayersMeta.length) ? mediaPlayersMeta[selectedPlayerIndex].name : ""

    // Expose seek and formatTime
    function formatTime(secs) {
        var s = Math.floor(secs);
        var m = Math.floor(s / 60);
        s = s % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    function mediaSeek(fraction) {
        var targetPos = fraction * root.mediaDuration;
        root.mediaPosition = targetPos;  // update instantly
        mediaSeekProc.fraction = fraction;
        mediaSeekProc.running = false;
        Qt.callLater(() => mediaSeekProc.running = true);
    }

    function selectPlayer(idx) {
        if (idx < 0 || idx >= mediaPlayersMeta.length)
            return;
        selectedPlayerIndex = idx;
        var p = mediaPlayersMeta[idx];
        mediaTitle = p.title;
        mediaArtist = p.artist;
        mediaStatus = p.status;
        mediaPosition = p.position;
        mediaDuration = p.duration;
    }

    Timer {
        id: hidetimer
        interval: 300
        onTriggered: root._showPopup = false
    }

    // Volume polling
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            volumeReader.running = true;
            muteReader.running = true;
            mediaMetaReader.running = true;
            playerInfoReader.running = true;
        }
    }

    Process {
        id: volumeReader
        command: ["sh", "-c", "LANG=C pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1 && LANG=C pactl get-sink-mute @DEFAULT_SINK@"]
        stdout: SplitParser {
            onRead: function (line) {
                if (line.startsWith("Mute:"))
                    root.muted = line.includes("yes");
                else if (line.match(/^\d+$/))
                    root.volume = parseInt(line);
            }
        }
    }

    Process {
        id: muteReader
        command: ["sh", "-c", "LANG=C pactl get-sink-mute @DEFAULT_SINK@"]
        stdout: SplitParser {
            onRead: function (line) {
                root.muted = line.includes("yes");
            }
        }
    }

    Process {
        id: mediaMetaReader
        command: ["sh", "/home/kaiko/.config/quickshell/default/modules/bar/popouts/scripts/get-players-metadata.sh"]

        property var _players: []

        stdout: SplitParser {
            onRead: function (line) {
                let parts = line.split("~|~");
                if (parts.length < 6)
                    return;
                mediaMetaReader._players.push({
                    name: parts[0],
                    status: parts[1],
                    title: parts[2],
                    artist: parts[3],
                    position: parseFloat(parts[4]) / 1000000,
                    duration: parseFloat(parts[5]) / 1000000
                });
            }
        }

        onRunningChanged: {
            if (running) {
                _players = [];
            } else {
                root.mediaPlayersMeta = _players;
                if (root.selectedPlayerIndex < 0 || root.selectedPlayerIndex >= _players.length)
                    root.selectedPlayerIndex = _players.length > 0 ? 0 : -1;

                let cur = root.selectedPlayerIndex >= 0 ? _players[root.selectedPlayerIndex] : null;
                root.mediaTitle = cur ? cur.title : "";
                root.mediaArtist = cur ? cur.artist : "";
                root.mediaStatus = cur ? cur.status : "Stopped";
                root.mediaPosition = cur ? cur.position : 0;
                root.mediaDuration = cur ? cur.duration : 0;
            }
        }
    }
    Process {
        id: playerInfoReader
        command: ["sh", "/home/kaiko/.config/quickshell/default/modules/bar/popouts/scripts/get-player-volumes.sh"]

        property var _players: []
        property var _volumes: []

        stdout: SplitParser {
            onRead: function (line) {
                let lineStr = line.trim();
                if (lineStr === "")
                    return;
                let colonIdx = lineStr.lastIndexOf(":");
                if (colonIdx > 0) {
                    let name = lineStr.substring(0, colonIdx);
                    let volStr = lineStr.substring(colonIdx + 1);
                    if (name !== "") {
                        playerInfoReader._players.push(name);
                        let vol = parseFloat(volStr);
                        playerInfoReader._volumes.push(isNaN(vol) ? 0 : Math.round(vol * 100));
                    }
                }
            }
        }

        onRunningChanged: {
            if (running) {
                _players = [];
                _volumes = [];
            } else {
                root.mediaPlayers = _players;
                root.mediaPlayerVolumes = _volumes;
            }
        }
    }
    Process {
        id: volUp
        command: ["sh", "-c", "pactl set-sink-volume @DEFAULT_SINK@ +1% && LANG=C pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1"]
        stdout: SplitParser {
            onRead: function (line) {
                if (line.match(/^\d+$/))
                    root.volume = parseInt(line);
            }
        }
    }

    Process {
        id: volDown
        command: ["sh", "-c", "pactl set-sink-volume @DEFAULT_SINK@ -1% && LANG=C pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1"]
        stdout: SplitParser {
            onRead: function (line) {
                if (line.match(/^\d+$/))
                    root.volume = parseInt(line);
            }
        }
    }

    Process {
        id: volMute
        command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
        onRunningChanged: if (!running)
            volumeReader.running = true
    }

    Process {
        id: mediaSeekProc
        property real fraction: 0
        command: ["sh", "-c", "playerctl --player=\"" + root.currentPlayerName + "\" position " + (fraction * root.mediaDuration)]
    }

    Process {
        id: mediaPlay
        command: ["playerctl", "--player=" + root.currentPlayerName, "play-pause"]
        onRunningChanged: if (!running)
            mediaMetaReader.running = true
    }
    Process {
        id: mediaNext
        command: ["playerctl", "--player=" + root.currentPlayerName, "next"]
        onRunningChanged: if (!running)
            mediaMetaReader.running = true
    }
    Process {
        id: mediaPrevious
        command: ["playerctl", "--player=" + root.currentPlayerName, "previous"]
        onRunningChanged: if (!running)
            mediaMetaReader.running = true
    }

    Rectangle {
        anchors.fill: parent
        color: "#101010"

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered) {
                    hidetimer.stop();
                    root._showPopup = true;
                } else {
                    hidetimer.restart();
                }
            }
        }
        // Border glow
        Rectangle {
            anchors.fill: parent
            color: "transparent"
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

        // Volume bar at the bottom
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: 2
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            height: 3
            radius: 2
            color: "#2a2a2a"

            Rectangle {
                width: parent.width * Math.min(root.volume / 100, 1)
                height: parent.height
                radius: parent.radius
                color: root.muted ? "#666666" : root.volume > 100 ? "#ff5555" : root.volume > 66 ? "#8caaee" : "#55ff99"
                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
        }

        Row {
            id: mainRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -2
            spacing: 8

            // Volume section
            Row {
                id: label
                spacing: 4

                Text {
                    text: root.muted ? "󰝟" : root.volume === 0 ? "󰸈" : root.volume < 50 ? "󰖀" : "󰕾"
                    color: root.muted ? "#666666" : "#8caaee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                Text {
                    text: root.volume + "%"
                    color: root.muted ? "#666666" : "#eeeeee"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }
        }

        // Scroll to change volume
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onWheel: function (event) {
                if (event.angleDelta.y > 0) {
                    volUp.running = false;
                    Qt.callLater(() => volUp.running = true);
                } else {
                    volDown.running = false;
                    Qt.callLater(() => volDown.running = true);
                }
            }
        }

        // Click to mute
        TapHandler {
            cursorShape: Qt.PointingHandCursor
            onTapped: {
                volMute.running = false;
                Qt.callLater(() => volMute.running = true);
            }
        }
    }
}
