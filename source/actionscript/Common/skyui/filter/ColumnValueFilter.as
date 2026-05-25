/*
 *  Hides item entries whose value for a single column attribute has been
 *  unchecked in the column-value dialog (opened with a middle click on a
 *  column header). Only one column is filtered at a time.
 */
class skyui.filter.ColumnValueFilter implements skyui.filter.IFilter
{
  /* PRIVATE VARIABLES */

    // Item attribute currently being filtered (e.g. the column's @-property).
    private var _attribute: String;

    // Set of value keys that are hidden: key -> true.
    private var _hidden: Object;
    private var _hiddenCount: Number;


  /* INITIALIZATION */

    public function ColumnValueFilter()
    {
        gfx.events.EventDispatcher.initialize(this);

        this._hidden = {};
        this._hiddenCount = 0;
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
        return this._attribute;
    }

    // Switches the column being filtered. Changing the attribute drops the
    // hidden set so values from the previous column stop filtering.
    public function setColumn(a_attribute: String)
    {
        if (this._attribute == a_attribute)
            return;

        this._attribute = a_attribute;

        var bHadHidden: Boolean = this._hiddenCount > 0;

        this._hidden = {};
        this._hiddenCount = 0;

        if (bHadHidden)
            this.dispatchEvent({type: "filterChange"});
    }

    public function isValueHidden(a_key: String)
    {
        return this._hidden[a_key] == true;
    }

    public function setValueHidden(a_key: String, a_bHidden: Boolean)
    {
        if (a_bHidden == this.isValueHidden(a_key))
            return;

        if (a_bHidden) {
            this._hidden[a_key] = true;
            this._hiddenCount++;
        } else {
            delete this._hidden[a_key];
            this._hiddenCount--;
        }

        this.dispatchEvent({type: "filterChange"});
    }

    // Silent reset (no filterChange event); the caller must refresh the list.
    public function reset()
    {
        this._hidden = {};
        this._hiddenCount = 0;
    }

    // @override skyui.filter.IFilter
    public function applyFilter(a_filteredList: Array)
    {
        if (this._hiddenCount == 0 || this._attribute == undefined)
            return;

        // Write-index pattern instead of splice -- O(N) instead of O(N^2)
        // when many values are hidden. Clears filteredIndex on excluded
        // entries; ownership moved here from FilteredEnumeration's copy loop.
        var attr = this._attribute;
        var hidden = this._hidden;
        var writeIndex = 0;
        var len = a_filteredList.length;

        for (var i = 0; i < len; i++) {
            var e = a_filteredList[i];
            var value = e[attr];
            var key: String = (value == undefined) ? "" : String(value);

            if (hidden[key] != true)
                a_filteredList[writeIndex++] = e;
            else
                e.filteredIndex = undefined;
        }

        a_filteredList.length = writeIndex;
    }
}
