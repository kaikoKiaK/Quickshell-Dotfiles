pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Io

PanelWindow {
    id: root
    required property ShellScreen targetScreen
    required property int barHeight
    required property var audioWidget
    property int currentSinkIndex: 0

    screen: targetScreen
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: barHeight + 250
    color: "transparent"
    exclusiveZone: 0
    visible: root.audioWidget.showMediaPopup && root.audioWidget.mediaTitle !== ""

    Rectangle {
        id: mediaPopout
        width: {
            var base = 300;
            var pCount = root.audioWidget.mediaPlayers.length;
            if (pCount > 0)
                base += pCount * 48 + 4 + 125;
            return base + 20;
        }
        height: root.audioWidget.mediaPlayersMeta.length > 1 ? 250 : 220
        y: 0
        anchors.left: parent.left
        anchors.leftMargin: root.audioWidget.x / 8
        radius: 8
        color: "#101010"
        border.color: "#2a2a2a"
        border.width: 1

        opacity: root.audioWidget.showMediaPopup ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            onHoveredChanged: root.audioWidget.popupHovered = hovered
        }

        Process {
            id: setPlayerVolProc
            property string targetPlayer: ""
            property real targetVolume: 0
            property bool isBrave: targetPlayer.indexOf("brave") === 0

            command: isBrave ? ["sh", "-c", "idx=$(pactl list sink-inputs | awk '/^Sink Input #/{gsub(\"#\",\"\",$3); idx=$3} /application\\.name = \"Brave\"/{print idx; exit}'); [ -n \"$idx\" ] && pactl set-sink-input-volume \"$idx\" " + Math.round(targetVolume * 100) + "%"] : ["playerctl", "--player=" + targetPlayer, "volume", String(targetVolume)]
        }
        Process {
            id: switchAudioSink
            property string targetSink: ""
            command: ["sh", "-c", "TARGET=\"" + targetSink + "\" && pactl set-default-sink \"$TARGET\" && pactl list short sink-inputs | awk '{print $1}' | xargs -I {} pactl move-sink-input {} \"$TARGET\""]
        }
        Item {
            id: sinkToggleBtn
            width: 24
            height: 24
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 6
            z: 1

            Text {
                anchors.centerIn: parent
                text: root.currentSinkIndex === 0 ? "󰋋" : "󰍹"
                color: sinkToggleHover.hovered ? "#eeeeee" : "#666666"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }

            HoverHandler {
                id: sinkToggleHover
            }

            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: {
                    var sinks = ["alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1", "alsa_output.usb-HP__Inc_HyperX_Virtual_Surround_Sound_00000000-00.analog-stereo"];
                    root.currentSinkIndex = root.currentSinkIndex === 0 ? 1 : 0;
                    switchAudioSink.targetSink = sinks[root.currentSinkIndex];
                    switchAudioSink.running = false;
                    Qt.callLater(() => switchAudioSink.running = true);
                }
            }
        }
        Row {
            anchors.fill: parent
            anchors.margins: 16
            anchors.rightMargin: 16 + 20
            spacing: 12

            Column {
                id: leftContent
                width: parent.width - (slidersArea.visible ? slidersArea.width + parent.spacing : 0)
                spacing: 36

                Column {
                    spacing: 10
                    width: parent.width

                    Row {
                        id: playerSwitcher
                        visible: root.audioWidget.mediaPlayersMeta.length > 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        Repeater {
                            model: root.audioWidget.mediaPlayersMeta

                            delegate: Rectangle {
                                id: tab
                                required property int index
                                required property var modelData
                                width: label.implicitWidth + 14
                                height: 20
                                radius: 5
                                color: tab.index === root.audioWidget.selectedPlayerIndex ? "#8caaee" : "#2a2a2a"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Text {
                                    id: label
                                    anchors.centerIn: parent
                                    text: tab.modelData.name.split(".")[0].toUpperCase()
                                    color: tab.index === root.audioWidget.selectedPlayerIndex ? "#101010" : "#888888"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }

                                TapHandler {
                                    cursorShape: Qt.PointingHandCursor
                                    onTapped: {
                                        if (tab.index === root.audioWidget.selectedPlayerIndex)
                                            return;
                                        switchAnim.direction = tab.index > root.audioWidget.selectedPlayerIndex ? 1 : -1;
                                        switchAnim.targetIndex = tab.index;
                                        switchAnim.restart();
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: trackInfoClip
                        width: parent.width
                        height: titleArtistColumn.height
                        clip: true

                        Column {
                            id: titleArtistColumn
                            width: parent.width
                            spacing: 2

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.audioWidget.mediaTitle
                                color: "#eeeeee"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.audioWidget.mediaArtist
                                color: "#666666"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }
                }

                SequentialAnimation {
                    id: switchAnim
                    property int targetIndex: 0
                    property int direction: 1   // 1 = slide from right, -1 = slide from left

                    ParallelAnimation {
                        NumberAnimation {
                            target: titleArtistColumn
                            property: "x"
                            to: -switchAnim.direction * trackInfoClip.width
                            duration: 110
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: titleArtistColumn
                            property: "opacity"
                            to: 0
                            duration: 110
                        }
                    }
                    ScriptAction {
                        script: {
                            root.audioWidget.selectPlayer(switchAnim.targetIndex);
                            titleArtistColumn.x = switchAnim.direction * trackInfoClip.width;
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: titleArtistColumn
                            property: "x"
                            to: 0
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: titleArtistColumn
                            property: "opacity"
                            to: 1
                            duration: 180
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 70

                    Item {
                        width: 32
                        height: 32
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            color: prevPopupHover.hovered ? "#eeeeee" : "#666666"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 35
                            scale: prevPopupHover.hovered ? 1.2 : 1.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutBack
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            HoverHandler {
                                id: prevPopupHover
                            }
                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: {
                                    root.audioWidget.mediaPrevious.running = false;
                                    Qt.callLater(() => root.audioWidget.mediaPrevious.running = true);
                                }
                            }
                        }
                    }

                    Item {
                        width: 32
                        height: 32
                        Text {
                            anchors.centerIn: parent
                            text: root.audioWidget.isPlaying ? "󰏤" : "󰐊"
                            color: playPopupHover.hovered ? "#8caaee" : "#eeeeee"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 45
                            scale: playPopupHover.hovered ? 1.2 : 1.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutBack
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            HoverHandler {
                                id: playPopupHover
                            }
                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: {
                                    root.audioWidget.mediaPlay.running = false;
                                    Qt.callLater(() => root.audioWidget.mediaPlay.running = true);
                                }
                            }
                        }
                    }

                    Item {
                        width: 32
                        height: 32
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            color: nextPopupHover.hovered ? "#eeeeee" : "#666666"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 35
                            scale: nextPopupHover.hovered ? 1.2 : 1.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutBack
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            HoverHandler {
                                id: nextPopupHover
                            }
                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: {
                                    root.audioWidget.mediaNext.running = false;
                                    Qt.callLater(() => root.audioWidget.mediaNext.running = true);
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Item {
                        width: parent.width
                        height: 24

                        Rectangle {
                            id: seekBarContainer
                            width: parent.width
                            height: seekBarHover.hovered ? 16 : 6
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 2
                            color: "#2a2a2a"

                            Behavior on height {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                width: root.audioWidget.mediaDuration > 0 ? parent.width * (root.audioWidget.mediaPosition / root.audioWidget.mediaDuration) : 0
                                height: parent.height
                                radius: parent.radius
                                color: "#8caaee"
                                Behavior on width {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        HoverHandler {
                            id: seekBarHover
                        }

                        TapHandler {
                            cursorShape: Qt.PointingHandCursor
                            onTapped: function (event) {
                                var pos = event.position.x / parent.width;
                                root.audioWidget.mediaSeek(pos);
                            }
                        }
                    }

                    Row {
                        width: parent.width

                        Text {
                            id: posLabel
                            text: root.audioWidget.formatTime(root.audioWidget.mediaPosition)
                            color: "#666666"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        Item {
                            width: parent.width - posLabel.implicitWidth - durLabel.implicitWidth
                            height: 1
                        }

                        Text {
                            id: durLabel
                            text: root.audioWidget.formatTime(root.audioWidget.mediaDuration)
                            color: "#666666"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }
                }
            }

            Item {
                id: slidersArea
                width: root.audioWidget.mediaPlayers.length * 44
                visible: root.audioWidget.mediaPlayers.length > 0
                height: parent.height

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: 4

                    Repeater {
                        model: root.audioWidget.mediaPlayers

                        delegate: Item {
                            id: delegate
                            width: 40
                            height: parent.height

                            required property int index
                            required property var modelData

                            property real displayVolume: {
                                let vols = root.audioWidget.mediaPlayerVolumes;
                                return index < vols.length ? vols[index] : 0;
                            }
                            property real dragVolume: -1

                            Rectangle {
                                id: track
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 24
                                width: trackHover.hovered ? 10 : 6
                                height: parent.height - 56
                                radius: width / 2
                                color: "#2a2a2a"

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    id: fill
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    height: parent.height * Math.min((delegate.dragVolume >= 0 ? delegate.dragVolume : delegate.displayVolume) / 100, 1)
                                    radius: parent.radius
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: delegate.modelData.indexOf("brave") === 0 ? "#ff5301" : delegate.modelData.indexOf("spotify") === 0 ? "#34bb63" : "#8caaee"
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: delegate.modelData.indexOf("brave") === 0 ? "#ff2301" : delegate.modelData.indexOf("spotify") === 0 ? "#32834e" : "#8caaee"
                                        }
                                    }
                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            HoverHandler {
                                id: trackHover
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 4
                                text: Math.round(delegate.dragVolume >= 0 ? delegate.dragVolume : delegate.displayVolume) + "%"
                                color: "#888888"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: delegate.modelData.split(".")[0].toUpperCase()
                                color: "#666666"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: function (mouse) {
                                    updateVol(mouse.y);
                                }
                                onReleased: delegate.dragVolume = -1
                                onPositionChanged: function (mouse) {
                                    if (pressed)
                                        updateVol(mouse.y);
                                }
                                function updateVol(my) {
                                    let trackTop = track.y;
                                    let trackH = track.height;
                                    let vol = 1 - ((my - trackTop) / trackH);
                                    vol = Math.max(0, Math.min(100, Math.round(vol * 100)));
                                    delegate.dragVolume = vol;

                                    setPlayerVolProc.targetPlayer = delegate.modelData;
                                    setPlayerVolProc.targetVolume = vol / 100;
                                    setPlayerVolProc.running = false;
                                    Qt.callLater(() => setPlayerVolProc.running = true);

                                    // Optimistically update so displayVolume already matches
                                    // when dragVolume clears on release — avoids the bounce.
                                    let vols = root.audioWidget.mediaPlayerVolumes.slice();
                                    vols[delegate.index] = vol;
                                    root.audioWidget.mediaPlayerVolumes = vols;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
