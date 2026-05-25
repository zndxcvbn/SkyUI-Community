class skyui.filter.NameFilter implements skyui.filter.IFilter
{
    var dispatchEvent;
    var nameAttribute = "text";
    var _filterText = "";
    var _normalizedFilter = "";
    var _filterLength = 0;
    var _debounceID;

    static var DEBOUNCE_DELAY = 300;

    static var _latinMap: Array;
    static var _cyrMap: Object;

    static var _charStrCache: Array;

    function NameFilter() {
        gfx.events.EventDispatcher.initialize(this);
        skyui.filter.NameFilter.initCharMap();
    }

    function get filterText() { return this._filterText; }

    function set filterText(a_filterText: String)
    {
        if (a_filterText == undefined) a_filterText = "";
        if (a_filterText == this._filterText) return;

        this._filterText = a_filterText;
        this._normalizedFilter = skyui.filter.NameFilter.normalizeString(a_filterText);
        this._filterLength = this._normalizedFilter.length;

        if (this._debounceID != undefined) {
            clearInterval(this._debounceID);
            delete this._debounceID;
        }

        if (a_filterText == "") {
            this.dispatchEvent({ type: "filterChange" });
            return;
        }

        this._debounceID = setInterval(this, "_onDebounceTimer", skyui.filter.NameFilter.DEBOUNCE_DELAY);
    }

    function _onDebounceTimer() {
        clearInterval(this._debounceID);
        delete this._debounceID;
        this.dispatchEvent({ type: "filterChange" });
    }

    static function prenormalizeList(a_list: Array, a_nameAttr: String) {
        var attr: String = a_nameAttr || "text";

        var len: Number = a_list.length;
        for (var i: Number = 0; i < len; i++) {
            var e: Object = a_list[i];
            var raw: String = e[attr];

            e._normalizedName = (raw != undefined)
                ? skyui.filter.NameFilter.normalizeString(raw)
                : "";
            e._normalizedSource = raw;
        }
    }

    function applyFilter(a_filteredList: Array) {
        if (this._filterLength == 0) return;

        var nf: String = this._normalizedFilter;
        var fl: Number = this._filterLength;

        var attr: String = this.nameAttribute;
        if (attr == undefined) attr = "text";

        var writeIndex: Number = 0;
        var len: Number = a_filteredList.length;

        // Single-branch loop: matched entries go to writeIndex, excluded ones
        // get filteredIndex cleared inline. Clear ownership moved here from
        // FilteredEnumeration's copy loop.
        for (var i: Number = 0; i < len; i++) {
            var e: Object = a_filteredList[i];
            var raw: String = e[attr];
            var matches: Boolean = false;

            if (raw != undefined) {
                if (e._normalizedSource !== raw) {
                    e._normalizedSource = raw;
                    e._normalizedName = skyui.filter.NameFilter.normalizeString(raw);
                }

                var name: String = e._normalizedName;
                if (name != undefined && name.length >= fl && name.indexOf(nf) != -1)
                    matches = true;
            }

            if (matches)
                a_filteredList[writeIndex++] = e;
            else
                e.filteredIndex = undefined;
        }

        a_filteredList.length = writeIndex;
    }

    static function normalizeString(a_str: String) {
        if (!a_str) return "";

        var latinMap: Array = skyui.filter.NameFilter._latinMap;
        var cyrMap: Object = skyui.filter.NameFilter._cyrMap;
        var cache: Array = skyui.filter.NameFilter._charStrCache;

        var lower: String = a_str.toLowerCase();
        var slen: Number = lower.length;


        if (slen <= 16) {
            var result: String = "";
            for (var i: Number = 0; i < slen; i++) {
                var code: Number = lower.charCodeAt(i);
                var mapped;

                if (code < 384) {
                    mapped = latinMap[code];
                } else if (code >= 1025 && code <= 1169) {
                    mapped = cyrMap[code];
                }

                if (mapped === -1) continue;

                if (mapped != undefined) {
                    result += cache[mapped];
                } else {
                    var cs: String = cache[code];
                    if (cs == undefined) {
                        cs = String.fromCharCode(code);
                        cache[code] = cs;
                    }
                    result += cs;
                }
            }
            return result;

        } else {
            var parts: Array = [];
            var pi: Number = 0;
            for (var j: Number = 0; j < slen; j++) {
                var code2: Number = lower.charCodeAt(j);
                var mapped2;

                if (code2 < 384) {
                    mapped2 = latinMap[code2];
                } else if (code2 >= 1025 && code2 <= 1169) {
                    mapped2 = cyrMap[code2];
                }

                if (mapped2 === -1) continue;

                if (mapped2 != undefined) {
                    parts[pi++] = cache[mapped2];
                } else {
                    var cs2: String = cache[code2];
                    if (cs2 == undefined) {
                        cs2 = String.fromCharCode(code2);
                        cache[code2] = cs2;
                    }
                    parts[pi++] = cs2;
                }
            }
            return parts.join("");
        }
    }

    static function initCharMap() {
        if (skyui.filter.NameFilter._latinMap != undefined) return;

        var cache: Array = new Array(8192);
        skyui.filter.NameFilter._charStrCache = cache;

        function fillCharCache(start: Number, end: Number) {
            for (var i: Number = start; i <= end; i++) {
                cache[i] = String.fromCharCode(i);
            }
        }
        function fillRange(arr: Array, start: Number, end: Number, value: Number) {
            for (var i: Number = start; i <= end; i++) {
                arr[i] = value;
            }
        }
        function mapCodes(arr: Array, codes: Array, target: Number) {
            for (var i: Number = 0; i < codes.length; i++) {
                arr[codes[i]] = target;
            }
        }
        function mapObjectCodes(obj: Object, codes: Array, target: Number) {
            for (var i: Number = 0; i < codes.length; i++) {
                obj[codes[i]] = target;
            }
        }

        // Basic ASCII cache
        fillCharCache(32, 126);

        // ══════════════ Ignore symbols ══════════════
        var lm: Array = new Array(384);
        skyui.filter.NameFilter._latinMap = lm;

        fillRange(lm, 161, 191, -1);
        lm[215] = -1;
        lm[247] = -1;

        // ══════════════ Latin (ASCII 97-122) ══════════════
        // 'a' (97) - ÀÁÂÃÄÅÆ àáâãäåæ Ąą Ăă Ââ
        mapCodes(lm, [192,193,194,195,196,197,198, 224,225,226,227,228,229,230, 260,261, 258,259], 97);
        // 'c' (99) - Çç Ćć Čč
        mapCodes(lm, [199,231, 262,263, 268,269], 99);
        // 'd' (100) - Ðð Ďď
        mapCodes(lm, [208,240, 270,271], 100);
        // 'e' (101) - ÈÉÊË èéêë Ęę Ěě
        mapCodes(lm, [200,201,202,203, 232,233,234,235, 280,281, 282,283], 101);
        // 'g' (103) - Ğğ
        mapCodes(lm, [286,287], 103);
        // 'i' (105) - ÌÍÎÏ ìíîï İı Īī
        mapCodes(lm, [204,205,206,207, 236,237,238,239, 304,305, 302,303], 105);
        // 'l' (108) - Łł Ĺĺ Ľľ
        mapCodes(lm, [321,322, 313,314, 317,318], 108);
        // 'n' (110) - Ññ Ńń Ňň
        mapCodes(lm, [209,241, 323,324, 327,328], 110);
        // 'o' (111) - ÒÓÔÕÖØ òóôõöø Őő
        mapCodes(lm, [210,211,212,213,214,216, 242,243,244,245,246,248, 336,337], 111);
        // 'r' (114) - Řř Ŕŕ
        mapCodes(lm, [344,345, 340,341], 114);
        // 's' (115) - ß Śś Šš Şş
        mapCodes(lm, [223, 346,347, 352,353, 350,351], 115);
        // 't' (116) - Þþ Ťť Ţţ
        mapCodes(lm, [222,254, 356,357, 354,355], 116);
        // 'u' (117) - ÙÚÛÜ ùúûü Ůů Űű Ūū
        mapCodes(lm, [217,218,219,220, 249,250,251,252, 366,367, 368,369, 362,363], 117);
        // 'y' (121) - Ýýÿ
        mapCodes(lm, [221,253,255], 121);
        // 'z' (122) - Źź Żż Žž
        mapCodes(lm, [377,378, 379,380, 381,382], 122);

        // cache ASCII a-z
        fillCharCache(97, 122);

        // ══════════════ Cyrillic ══════════════
        var cm: Object = {};
        skyui.filter.NameFilter._cyrMap = cm;

        // 'г' (1075) - Ґґ
        mapObjectCodes(cm, [1168, 1169], 1075);
        // 'е' (1077) - Ёё Єє
        mapObjectCodes(cm, [1025, 1105, 1028, 1108], 1077);
        // 'и' (1080) - Іі Її
        mapObjectCodes(cm, [1030, 1110, 1031, 1111], 1080);
        // 'й' (1081) - Јј
        mapObjectCodes(cm, [1032, 1112], 1081);
        // 'с' (1089) - Ѕѕ
        mapObjectCodes(cm, [1029, 1109], 1089);
        // 'у' (1091) - Ўў
        mapObjectCodes(cm, [1038, 1118], 1091);

        // cache Cyrillic а-я
        fillCharCache(1072, 1103);
    }


    function isMatch(a_entry: Object) {
        var name: String = a_entry._normalizedName;
        if (name == undefined) return false;
        var fl: Number = this._filterLength;
        if (fl == 0) return true;
        if (name.length < fl) return false;
        return name.indexOf(this._normalizedFilter) != -1;
    }
}