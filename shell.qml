pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "modules/bar/"
import "modules/bar/popouts/Calendar"
import "modules/bar/popouts/Media"
import "modules/bar/popouts/Monitors"
import "modules/launcher/"
import "modules/wallpaperChanger"

ShellRoot {
    id: shellRoot

    property bool launcherOpen: false

    IpcHandler {
        target: "toggleLauncher"
        function launch() {
            shellRoot.launcherOpen = !shellRoot.launcherOpen;
        }
    }

    IpcHandler {
        target: "randomWallpaper"
        function handle() {
            WallpaperManager.random();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Item {
            id: screenRoot
            required property ShellScreen modelData

            WallpaperChanger {
                targetScreen: screenRoot.modelData
            }

            Bar {
                id: bar
                targetScreen: screenRoot.modelData
            }

            CalendarPopout {
                targetScreen: screenRoot.modelData
                barHeight: bar.implicitHeight
                clockWidget: bar.clockWidget
                visible: bar.clockWidget.showCalendar
            }

            MediaPopout {
                targetScreen: screenRoot.modelData
                barHeight: bar.implicitHeight
                audioWidget: bar.audioWidget
            }

            MonitorsPopout {
                targetScreen: screenRoot.modelData
                barHeight: bar.implicitHeight
                monitorsWidget: bar.monitorsWidget
            }

            Launcher {
                id: launcher
                targetScreen: screenRoot.modelData

                // 1. Keep it reading declaratively from the root state
                launcherVisible: shellRoot.launcherOpen && (screenRoot.modelData.name === Hyprland.focusedMonitor.name)

                // 2. Catch the close event from Launcher.qml and pass it up
                onCloseRequested: {
                    shellRoot.launcherOpen = false;
                }
            }
        }
    }
}
