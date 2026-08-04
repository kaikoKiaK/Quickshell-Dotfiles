import QtQuick

QtObject {
    function hexToRgb(hex) {
        var h = hex.replace("#", "");
        return [parseInt(h.substring(0, 2), 16), parseInt(h.substring(2, 4), 16), parseInt(h.substring(4, 6), 16)];
    }

    function lerpColor(a, b, t) {
        t = Math.max(0, Math.min(1, t));
        var ca = hexToRgb(a);
        var cb = hexToRgb(b);
        var r = Math.round(ca[0] + (cb[0] - ca[0]) * t);
        var g = Math.round(ca[1] + (cb[1] - ca[1]) * t);
        var b = Math.round(ca[2] + (cb[2] - ca[2]) * t);
        return "#" + ((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1);
    }

    function stopColor(stops, value) {
        if (value <= stops[0].v)
            return stops[0].c;
        for (let i = 0; i < stops.length - 1; i++) {
            if (value <= stops[i + 1].v) {
                let t = (value - stops[i].v) / (stops[i + 1].v - stops[i].v);
                return lerpColor(stops[i].c, stops[i + 1].c, t);
            }
        }
        return stops[stops.length - 1].c;
    }

    function gammaColor(p) {
        return stopColor([
            {
                v: 0,
                c: "#000000"
            },
            {
                v: 100,
                c: "#ffffff"
            }
        ], p);
    }

    function tempColor(k) {
        return stopColor([
            {
                v: 2500,
                c: "#ff5f2e"
            },
            {
                v: 3000,
                c: "#ff9a4d"
            },
            {
                v: 3500,
                c: "#ffc47f"
            },
            {
                v: 4200,
                c: "#ffdca8"
            },
            {
                v: 5000,
                c: "#fff2e0"
            },
            {
                v: 5500,
                c: "#ffffff"
            },
            {
                v: 6500,
                c: "#b4ccff"
            }
        ], k);
    }
}
