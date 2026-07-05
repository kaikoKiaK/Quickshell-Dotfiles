pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string wallpaperDir: "/home/kaiko/wallpapers"
    property var wallpapers: []
    property int currentIndex: 0
    property string currentWallpaper: wallpapers.length > 0 ? wallpapers[currentIndex] : ""

    // Load wallpaper list on startup
    Component.onCompleted: loadWallpapers()

    Process {
        id: findWallpapers
        command: ["sh", "-c", "find " + root.wallpaperDir + " -type f \\( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \\) | sort"]
        stdout: SplitParser {
            onRead: function (line) {
                if (line.trim() !== "")
                    root.wallpapers.push("file://" + line.trim());
            }
        }
        onRunningChanged: {
            if (!running) {
                root.wallpapers = root.wallpapers.slice();
                root.currentIndex = 0;
            }
        }
    }

    function loadWallpapers() {
        root.wallpapers = [];
        findWallpapers.running = false;
        Qt.callLater(() => findWallpapers.running = true);
    }

    function next() {
        if (wallpapers.length === 0)
            return;
        currentIndex = (currentIndex + 1) % wallpapers.length;
    }

    function previous() {
        if (wallpapers.length === 0)
            return;
        currentIndex = (currentIndex - 1 + wallpapers.length) % wallpapers.length;
    }

    function random() {
        if (wallpapers.length === 0)
            return;
        currentIndex = Math.floor(Math.random() * wallpapers.length);
    }

    // Auto-rotate every 30 minutes
    Timer {
        interval: 1800000
        running: root.wallpapers.length > 0
        repeat: true
        onTriggered: root.random()
    }
}
