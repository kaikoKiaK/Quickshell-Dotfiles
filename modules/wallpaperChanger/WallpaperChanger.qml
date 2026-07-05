pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root
    required property ShellScreen targetScreen

    screen: targetScreen
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: -1
    color: "#000000"  // black fallback instead of transparent
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "wallpaper"

    property string currentWallpaper: WallpaperManager.currentWallpaper

    // Layer A
    Image {
        id: imageA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        opacity: 1
    }

    // Layer B — crossfades in on top
    Image {
        id: imageB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        opacity: 0

        onStatusChanged: {
            if (status === Image.Ready) {
                crossfade.start();
            }
        }

        NumberAnimation {
            id: crossfade
            target: imageB
            property: "opacity"
            to: 1
            duration: 800
            easing.type: Easing.OutCubic
            onFinished: {
                imageA.source = imageB.source;
                imageA.opacity = 1;
                imageB.opacity = 0;
            }
        }
    }

    onCurrentWallpaperChanged: {
        imageB.source = currentWallpaper;
    }

    Component.onCompleted: {
        imageA.source = currentWallpaper;
    }
}
