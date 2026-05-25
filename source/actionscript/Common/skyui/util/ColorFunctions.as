class skyui.util.ColorFunctions
{
    /* CONSTANTS */

    private static var RAD_TO_DEG: Number = 180 / Math.PI;
    private static var DEG_TO_RAD: Number = Math.PI / 180;

    /* HEX */

    public static function hexToRgb(hex: Number)
    {
        hex = skyui.util.ColorFunctions.validHex(hex);

        return [
            (hex >> 16) & 0xFF,
            (hex >> 8) & 0xFF,
            hex & 0xFF
        ];
    }

    public static function hexToHsv(hex: Number)
    {
        return skyui.util.ColorFunctions.rgbToHsv(skyui.util.ColorFunctions.hexToRgb(hex));
    }

    public static function hexToHsl(hex: Number)
    {
        return skyui.util.ColorFunctions.rgbToHsl(skyui.util.ColorFunctions.hexToRgb(hex));
    }

    public static function hexToStr(hex: Number, prefix: Boolean)
    {
        hex = skyui.util.ColorFunctions.validHex(hex);

        var str: String = hex.toString(16).toUpperCase();

        while (str.length < 6)
            str = "0" + str;

        return (prefix ? "0x" : "") + str;
    }

    public static function validHex(hex: Number)
    {
        return skyui.util.ColorFunctions.clampValue(hex, 0x000000, 0xFFFFFF);
    }


    /* RGB */

    public static function rgbToHex(rgb: Array)
    {
        return (
            (skyui.util.ColorFunctions.clampValue(rgb[0], 0, 255) << 16) |
            (skyui.util.ColorFunctions.clampValue(rgb[1], 0, 255) << 8) |
            skyui.util.ColorFunctions.clampValue(rgb[2], 0, 255)
        );
    }

    public static function rgbToHsv(rgb: Array)
    {
        // in:  [R,G,B] => [0..255]
        // out: [H,S,V] => H[0..360], S/V[0..100]

        var r: Number = skyui.util.ColorFunctions.clampValue(rgb[0], 0, 255) / 255;
        var g: Number = skyui.util.ColorFunctions.clampValue(rgb[1], 0, 255) / 255;
        var b: Number = skyui.util.ColorFunctions.clampValue(rgb[2], 0, 255) / 255;

        var max: Number = Math.max(r, Math.max(g, b));
        var min: Number = Math.min(r, Math.min(g, b));
        var delta: Number = max - min;

        var h: Number = skyui.util.ColorFunctions.calcHue(r, g, b, max, delta);
        var s: Number = (max == 0) ? 0 : delta / max;
        var v: Number = max;

        return [
            Math.round(h),
            Math.round(s * 100),
            Math.round(v * 100)
        ];
    }

    public static function rgbToHsb(rgb: Array)
    {
        return skyui.util.ColorFunctions.rgbToHsv(rgb);
    }

    public static function rgbToHsl(rgb: Array)
    {
        // in:  [R,G,B] => [0..255]
        // out: [H,S,L] => H[0..360], S/L[0..100]

        var r: Number = skyui.util.ColorFunctions.clampValue(rgb[0], 0, 255) / 255;
        var g: Number = skyui.util.ColorFunctions.clampValue(rgb[1], 0, 255) / 255;
        var b: Number = skyui.util.ColorFunctions.clampValue(rgb[2], 0, 255) / 255;

        var max: Number = Math.max(r, Math.max(g, b));
        var min: Number = Math.min(r, Math.min(g, b));
        var delta: Number = max - min;

        var l: Number = (max + min) * 0.5;
        var h: Number = skyui.util.ColorFunctions.calcHue(r, g, b, max, delta);

        var s: Number = 0;

        if (delta != 0)
        {
            s = delta / (1 - Math.abs(2 * l - 1));
        }

        return [
            Math.round(h),
            Math.round(s * 100),
            Math.round(l * 100)
        ];
    }


    /* HSV */

    public static function hsvToRgb(hsv: Array)
    {
        // in:  [H,S,V]
        // out: [R,G,B]

        var h: Number = skyui.util.ColorFunctions.normalizeHue(hsv[0]);
        var s: Number = skyui.util.ColorFunctions.clampValue(hsv[1], 0, 100) / 100;
        var v: Number = skyui.util.ColorFunctions.clampValue(hsv[2], 0, 100) / 100;

        var c: Number = v * s;
        var x: Number = c * (1 - Math.abs((h / 60) % 2 - 1));
        var m: Number = v - c;

        var rgb: Array = skyui.util.ColorFunctions.hueToRgb(c, x, h);

        return [
            Math.round((rgb[0] + m) * 255),
            Math.round((rgb[1] + m) * 255),
            Math.round((rgb[2] + m) * 255)
        ];
    }

    public static function hsvToHex(hsv: Array)
    {
        return skyui.util.ColorFunctions.rgbToHex(skyui.util.ColorFunctions.hsvToRgb(hsv));
    }


    /* HSB */

    public static function hsbToRgb(hsb: Array)
    {
        return skyui.util.ColorFunctions.hsvToRgb(hsb);
    }

    public static function hsbToHex(hsb: Array)
    {
        return skyui.util.ColorFunctions.hsvToHex(hsb);
    }


    /* HSL */

    public static function hslToRgb(hsl: Array)
    {
        // in:  [H,S,L]
        // out: [R,G,B]

        var h: Number = skyui.util.ColorFunctions.normalizeHue(hsl[0]);
        var s: Number = skyui.util.ColorFunctions.clampValue(hsl[1], 0, 100) / 100;
        var l: Number = skyui.util.ColorFunctions.clampValue(hsl[2], 0, 100) / 100;

        var c: Number = (1 - Math.abs(2 * l - 1)) * s;
        var x: Number = c * (1 - Math.abs((h / 60) % 2 - 1));
        var m: Number = l - c * 0.5;

        var rgb: Array = skyui.util.ColorFunctions.hueToRgb(c, x, h);

        return [
            Math.round((rgb[0] + m) * 255),
            Math.round((rgb[1] + m) * 255),
            Math.round((rgb[2] + m) * 255)
        ];
    }

    public static function hslToHex(hsl: Array)
    {
        return skyui.util.ColorFunctions.rgbToHex(skyui.util.ColorFunctions.hslToRgb(hsl));
    }


    /* PRIVATE */

    private static function calcHue(r: Number, g: Number, b: Number, max: Number, delta: Number)
    {
        var h: Number = 0;

        if (delta == 0)
        {
            return 0;
        }

        if (max == r)
        {
            h = ((g - b) / delta) % 6;
        }
        else if (max == g)
        {
            h = ((b - r) / delta) + 2;
        }
        else
        {
            h = ((r - g) / delta) + 4;
        }

        h *= 60;

        if (h < 0)
            h += 360;

        return h;
    }

    private static function hueToRgb(c: Number, x: Number, h: Number)
    {
        if (h < 60)       return [c, x, 0];
        else if (h < 120) return [x, c, 0];
        else if (h < 180) return [0, c, x];
        else if (h < 240) return [0, x, c];
        else if (h < 300) return [x, 0, c];

        return [c, 0, x];
    }

    private static function normalizeHue(value: Number)
    {
        value = value % 360;

        if (value < 0)
            value += 360;

        return value;
    }

    private static function clampValue(value: Number, min: Number, max: Number)
    {
        return Math.min(max, Math.max(min, value));
    }
}
