class skyui.util.GlobalFunctions
{
    private static var _arrayExtended: Boolean = false;
    
    private function GlobalFunctions() {}
    
    static function extract(a_str: String, a_startChar: String, a_endChar: String)
    {
        var startIndex: Number = a_str.indexOf(a_startChar) + 1;
        var endIndex: Number = a_str.lastIndexOf(a_endChar);
        return a_str.slice(startIndex, endIndex);
    }
    
    static function clean(a_str: String)
    {
        var commentIndex: Number = a_str.indexOf(";");
        if (commentIndex > 0) {
            a_str = a_str.slice(0, commentIndex);
        }

        var start: Number = 0;
        var len: Number = a_str.length;
        
        while (start < len && (a_str.charAt(start) == " " || a_str.charAt(start) == "\t")) {
            start++;
        }
        
        var end: Number = len - 1;
        while (end >= start && (a_str.charAt(end) == " " || a_str.charAt(end) == "\t")) {
            end--;
        }

        return a_str.slice(start, end + 1);
    }
    
    static function unescape(a_str: String)
    {
        return a_str.split("\\n").join("\n").split("\\t").join("\t");
    }
    
    static function addArrayFunctions()
    {
        if (skyui.util.GlobalFunctions._arrayExtended) return;
        
        skyui.util.GlobalFunctions._arrayExtended = true;

        Array.prototype.indexOf = function(searchElement: Object, fromIndex: Number)
        {
            // 1. Let obj be ToObject(this)
            // 2. Let len be LengthOfArrayLike(obj)
            var len: Number = this.length;

            // 3. If len = 0, return -1
            if (len === 0 || len === undefined) return -1;

            // 4. Let n be ToInteger(fromIndex)
            // 5. If fromIndex is undefined, n is 0
            var n: Number = Number(fromIndex);
            if (isNaN(n)) {
                n = 0;
            }

            // 6. If n = +Infinity, return -1
            if (n === Number.POSITIVE_INFINITY) return -1;
            // 7. If n = -Infinity, set n to 0
            if (n === Number.NEGATIVE_INFINITY) n = 0;

            // 8. If n >= len, return -1
            if (n >= len) return -1;

            var k: Number;

            // 8.a & 9.a-b Calculation of start index k
            if (n >= 0) {
                k = n;
            } else {
                k = len + n;
                if (k < 0) k = 0;
            }

            // 10. Repeat, while k < len
            while (k < len) {
                if (this.hasOwnProperty(String(k)) && this[k] === searchElement) {
                    return k;
                }
                k++;
            }

            // 11. Return -1
            return -1;
        };

        Array.prototype.equals = function(a_other: Array)
        {
            if (a_other == undefined || this.length != a_other.length) return false;
            
            for (var i: Number = 0; i < a_other.length; i++) {
                if (a_other[i] !== this[i]) return false;
            }
            return true;
        };

        Array.prototype.contains = function(searchElement: Object, fromIndex: Number)
        {
            // 1. Let obj be ToObject(this)
            // 2. Let len be LengthOfArrayLike(obj)
            var len: Number = this.length;

            // 3. If len = 0, return false
            if (len === 0 || len === undefined) return false;

            // 4. Let n be ToInteger(fromIndex)
            // 5. If fromIndex is undefined, n is 0
            var n: Number = Number(fromIndex);
            if (isNaN(n)) {
                n = 0;
            }

            // 6. If n = +Infinity, return false
            if (n === Number.POSITIVE_INFINITY) return false;
            // 7. If n = -Infinity, set n to 0
            if (n === Number.NEGATIVE_INFINITY) n = 0;

            // 8. If n >= len, return false
            if (n >= len) return false;

            var k: Number;

            // 8.a & 9.a-b Calculation of start index k
            if (n >= 0) {
                k = n;
            } else {
                k = len + n;
                if (k < 0) k = 0;
            }

            // 10. Repeat, while k < len
            while (k < len) {
                var elementK = this[k];

                if (searchElement === elementK) {
                    return true;
                } else if (searchElement !== searchElement && elementK !== elementK) {
                    return true;
                }

                k++;
            }

            // 11. Return false
            return false;
        };

        _global.ASSetPropFlags(Array.prototype, ["indexOf", "equals", "contains"], 1, 0);
    }
    
    static function mapUnicodeChar(a_charCode: Number)
    {
        if (a_charCode == 8470) return 185; // №

        if (a_charCode >= 1025 && a_charCode <= 1169) {
            switch (a_charCode) {
                case 1025: return 168; // Ё
                case 1028: return 170; // Є
                case 1029: return 189; // Ѕ
                case 1030: return 178; // І
                case 1031: return 175; // Ї
                case 1032: return 163; // Ј
                case 1038: return 161; // Ў
                case 1105: return 184; // ё
                case 1108: return 186; // є
                case 1109: return 190; // ѕ
                case 1110: return 179; // і
                case 1111: return 191; // ї
                case 1112: return 188; // ј
                case 1118: return 162; // ў
                case 1168: return 165; // Ґ
                case 1169: return 164; // ґ
                default:
                    if (a_charCode >= 1039 && a_charCode <= 1103) {
                        return a_charCode - 848;
                    }
            }
        }
        return a_charCode;
    }
    
    static function formatString(a_str: String)
    {
        if (arguments.length < 2) return a_str;

        var result: String = "";
        var lastPos: Number = 0;
        var argIndex: Number = 1;

        while (argIndex < arguments.length) {
            var openBrace: Number = a_str.indexOf("{", lastPos);
            var closeBrace: Number = a_str.indexOf("}", lastPos);

            if (openBrace == -1 || closeBrace == -1) break;

            result += a_str.slice(lastPos, openBrace);
            
            var precision: Number = Number(a_str.slice(openBrace + 1, closeBrace));
            var multiplier: Number = Math.pow(10, precision);
            var value: String = (Math.round(arguments[argIndex] * multiplier) / multiplier).toString();
            
            if (precision > 0) {
                if (value.indexOf(".") == -1) value += ".";
                var parts: Array = value.split(".");
                var currentDecimals: Number = parts[1].length;
                while (currentDecimals++ < precision) {
                    value += "0";
                }
            }

            result += value;
            lastPos = closeBrace + 1;
            argIndex++;
        }

        result += a_str.slice(lastPos);
        return result;
    }
    
    static function formatNumber(a_number: Number, a_decimal: Number)
    {
        var str: String = a_number.toString().toLowerCase();
        var parts: Array = str.split("e", 2);
        var multiplier: Number = Math.pow(10, a_decimal);
        
        var baseValue: String = String(Math.round(parseFloat(parts[0]) * multiplier) / multiplier);

        if (a_decimal > 0) {
            var dotIndex: Number = baseValue.indexOf(".");
            if (dotIndex == -1) {
                dotIndex = baseValue.length;
                baseValue += ".";
            }
            var currentPrecision: Number = baseValue.length - (dotIndex + 1);
            for (var i: Number = 0; currentPrecision + i < a_decimal; i++) {
                baseValue += "0";
            }
        }

        if (parts[1] != undefined) {
            baseValue += "E" + parts[1];
        }
        
        return baseValue;
    }
    
    static function getMappedKey(a_control: String, a_context: Number, a_bGamepad: Boolean)
    {
        if (_global.skse == undefined) return -1;

        if (a_bGamepad === true) {
            return skse.GetMappedKey(a_control, skyui.defines.Input.DEVICE_GAMEPAD, a_context);
        }

        var keyCode: Number = skse.GetMappedKey(a_control, skyui.defines.Input.DEVICE_KEYBOARD, a_context);
        if (keyCode == -1) {
            keyCode = skse.GetMappedKey(a_control, skyui.defines.Input.DEVICE_MOUSE, a_context);
        }
        return keyCode;
    }
    
    static function hookFunction(a_scope: Object, a_memberFn: String, a_hookScope: Object, a_hookFn: String)
    {
        var originalFn: Function = a_scope[a_memberFn];
        if (originalFn == null) return false;

        a_scope[a_memberFn] = function() {
            originalFn.apply(a_scope, arguments);
            a_hookScope[a_hookFn].apply(a_hookScope, arguments);
        };
        return true;
    }
    
    static function getDistance(a: Object, b: Object)
    {
        var dx: Number = b._x - a._x;
        var dy: Number = b._y - a._y;
        return Math.sqrt(dx * dx + dy * dy);
    }
    
    static function getAngle(a: Object, b: Object)
    {
        var dx: Number = b._x - a._x;
        var dy: Number = b._y - a._y;
        return Math.atan2(dy, dx) * 57.29577951308232; // (180 / Math.PI)
    }
}