/*
 *  Hides item entries whose value for a single column attribute has been
 *  unchecked in the column-value dialog (opened with a middle click on a
 *  column header). Supports multi-column filtering simultaneously.
 */
class skyui.filter.ColumnValueFilter implements skyui.filter.IFilter
{
  /* PRIVATE VARIABLES */

    private var _activeAttribute: String;

    // Map filter: attribute -> { isNumeric: Boolean, hidden: Object, count: Number, _cachedRanges: Array }
    private var _filters: Object;

    // Temporarily ignore a specific column's filter during manual filtering
    private var _ignoreAttribute: String;


  /* INITIALIZATION */

    public function ColumnValueFilter()
    {
        gfx.events.EventDispatcher.initialize(this);

        this._filters = {};
    }


  /* PUBLIC FUNCTIONS */

    // @mixin by gfx.events.EventDispatcher
    public var dispatchEvent: Function;
    public var dispatchQueue: Function;
    public var hasEventListener: Function;
    public var addEventListener: Function;
    public var removeEventListener: Function;
    public var removeAllEventListeners: Function;
    public var cleanUpEvents: Function;

    public function get attribute()
    {
        return this._activeAttribute;
    }

    public function get ignoreAttribute()
    {
        return this._ignoreAttribute;
    }

    public function set ignoreAttribute(a_attr: String)
    {
        this._ignoreAttribute = a_attr;
    }
    
    public function setColumn(a_attribute: String, a_isNumeric: Boolean)
    {
        this._activeAttribute = a_attribute;

        if (this._filters[a_attribute] == undefined) {
            this._filters[a_attribute] = {
                isNumeric: (a_isNumeric == true),
                hidden: {},
                count: 0
            };
        } else {
            this._filters[a_attribute].isNumeric = (a_isNumeric == true);
        }
    }

    public function isColumnFiltered(a_attribute: String)
    {
        var filter = this._filters[a_attribute];
        return filter != undefined && filter.count > 0;
    }

    public function isValueHidden(a_key: String)
    {
        var filter = this._filters[this._activeAttribute];
        if (filter == undefined) return false;
        return filter.hidden[a_key] == true;
    }
    
    public function setValueHidden(a_key: String, a_bHidden: Boolean)
    {
        var attr = this._activeAttribute;
        if (attr == undefined) return;

        var filter = this._filters[attr];
        if (filter == undefined) return;

        var isCurrentlyHidden = (filter.hidden[a_key] == true);
        if (a_bHidden == isCurrentlyHidden)
            return;

        if (a_bHidden) {
            filter.hidden[a_key] = true;
            filter.count++;
        } else {
            delete filter.hidden[a_key];
            filter.count--;
        }
        
        delete filter._cachedRanges;

        this.dispatchEvent({type: "filterChange"});
    }
    
    public function reset()
    {
        this._filters = {};
        this._activeAttribute = undefined;
    }
    
    public function resetActiveColumn()
    {
        var attr = this._activeAttribute;
        if (attr == undefined) return;

        var filter = this._filters[attr];
        if (filter != undefined) {
            filter.hidden = {};
            filter.count = 0;
            delete filter._cachedRanges;
        }
    }

    // @override skyui.filter.IFilter
    public function applyFilter(a_filteredList: Array)
    {
        var activeFilters = [];
        for (var attr in this._filters) {
            if (attr == this._ignoreAttribute) {
                continue;
            }

            var filter = this._filters[attr];
            if (filter != undefined && filter.count > 0) {
                activeFilters.push({ attribute: attr, config: filter });
            }
        }

        var activeFiltersLen = activeFilters.length;
        if (activeFiltersLen == 0)
            return;

        var writeIndex = 0;
        var len = a_filteredList.length;

        for (var i = 0; i < len; i++) {
            var e = a_filteredList[i];
            var keepItem = true;

            for (var f = 0; f < activeFiltersLen; f++) {
                var filterObj = activeFilters[f];
                var attr = filterObj.attribute;
                var config = filterObj.config;
                var value = e[attr];

                if (config.isNumeric) {
                    if (config._cachedRanges == undefined) {
                        config._cachedRanges = [];
                        for (var key in config.hidden) {
                            if (config.hidden[key] == true && key != "") {
                                var parts = key.split("_");
                                var isClosed = (parts[2] == "c");
                                config._cachedRanges.push({ min: Number(parts[0]), max: Number(parts[1]), closed: isClosed });
                            }
                        }
                    }

                    if (value == undefined || isNaN(value)) {
                        if (config.hidden[""] == true) {
                            keepItem = false;
                            break;
                        }
                        continue;
                    }

                    var isHidden = false;
                    var ranges = config._cachedRanges;
                    var rangesLen = ranges.length;
                    for (var r = 0; r < rangesLen; r++) {
                        var range = ranges[r];
                        
                        var match = range.closed 
                            ? (value >= range.min && value <= range.max)
                            : (value >= range.min && value < range.max);
                            
                        if (match) {
                            isHidden = true;
                            break;
                        }
                    }

                    if (isHidden) {
                        keepItem = false;
                        break;
                    }

                } else {
                    var key: String = (value == undefined) ? "" : String(value);
                    if (config.hidden[key] == true) {
                        keepItem = false;
                        break;
                    }
                }
            }

            if (keepItem) {
                a_filteredList[writeIndex++] = e;
            } else {
                e.filteredIndex = undefined;
            }
        }

        a_filteredList.length = writeIndex;
    }
}
