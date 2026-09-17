pragma Singleton

import Quickshell

Singleton {
    id: root
    property bool locked: false

    function lock() {
        root.locked = true;
    }

    function unlock() {
        root.locked = false;
    }
}
