class skyui.components.list.FilteredEnumeration extends skyui.components.list.BasicEnumeration
{
  /* PRIVATE VARIABLES */

    private var _filteredData: Array;
    private var _filterChain: Array;

    // Skip-applyFilters bookkeeping. Filters dispatch filterChange on their
    // criteria changes -- we listen and set _filtersDirty. _dataDirty is set
    // by the caller (ScrollingList.InvalidateData when it sees a non-empty
    // dirty-entries list). _lastEntryDataLength catches add/remove of entries.
    // invalidate() short-circuits when none of the three signal a change.
    private var _filtersDirty: Boolean = true;
    private var _dataDirty: Boolean = true;
    private var _lastEntryDataLength: Number = -1;

    // Bumped each time applyFilters actually runs. UpdateList compares against
    // its last snapshot to decide whether re-rendering is needed.
    public var _version: Number = 0;


  /* INITIALIZATION */

    public function FilteredEnumeration(a_data: Array)
    {
        super(a_data);

        this._filterChain = [];
        this._filteredData = [];
    }


  /* PUBLIC FUNCTIONS */

    public function addFilter(a_filter: IFilter)
    {
        this._filterChain.push(a_filter);

        // Each filter is an EventDispatcher; hooking filterChange here lets
        // applyFilters skip re-running when criteria haven't moved.
        if (a_filter.addEventListener != undefined)
            a_filter.addEventListener("filterChange", this, "_rfOnFilterChange");
    }

    // Called via EventDispatcher mixin (public so the dispatcher can find it).
    public function _rfOnFilterChange()
    {
        this._filtersDirty = true;
    }

    // Signal from the caller (typically ScrollingList.InvalidateData) that
    // entry data may have changed in ways that affect filtering or sort --
    // e.g. ItemcardDataExtender's dirty-entry list was non-empty. Cleared by
    // the next applyFilters.
    public function markDataDirty()
    {
        this._dataDirty = true;
    }

    // @override skyui.BasicEnumeration
    public function size()
    {
        return this._filteredData.length;
    }

    // @override skyui.BasicEnumeration
    public function at(a_index: Number)
    {
        return this._filteredData[a_index];
    }

    // @override skyui.IEntryEnumeration
    public function lookupEntryIndex(a_enumIndex: Number)
    {
        return this._filteredData[a_enumIndex].itemIndex;
    }

    // @override skyui.IEntryEnumeration
    public function lookupEnumIndex(a_entryIndex: Number)
    {
        return this._entryData[a_entryIndex].filteredIndex;
    }

    // The underlying entryData has been modified externally, so regenerate the
    // enumeration. Self-skips when nothing relevant changed since the last
    // apply (cached _filteredData is still correct) -- callers can invoke this
    // unconditionally without paying the rebuild cost on redundant calls.
    //
    // Returns true if applyFilters actually ran, false if the call was a
    // skip. ScrollingList.InvalidateData uses this to skip the downstream
    // work (selection bounds, UpdateList) -- those depend on filtered output
    // which is unchanged when invalidate skipped.
    public function invalidate()
    {
        if (!this._filtersDirty
            && !this._dataDirty
            && this._entryData.length == this._lastEntryDataLength)
            return false;

        this.applyFilters();
        this._filtersDirty = false;
        this._dataDirty = false;
        this._lastEntryDataLength = this._entryData.length;
        return true;
    }


  /* PRIVATE FUNCTIONS */

    private function applyFilters()
    {
        // Native shallow copy. Roughly half the cost of the per-element AVM1
        // loop we used to do here. Entries that survive the filter chain get
        // their filteredIndex re-set in the reindex pass below; entries the
        // filters exclude have their filteredIndex cleared by the filter
        // itself (see ItemTypeFilter / NameFilter / ColumnValueFilter).
        var filtered = this._entryData.slice();
        this._filteredData = filtered;

        // Apply filters
        var chain = this._filterChain;
        var chainLen = chain.length;
        for (var i = 0; i < chainLen; i++)
            chain[i].applyFilter(filtered);

        // Reindex: writes filteredIndex on every surviving entry.
        var outLen = filtered.length;
        for (var k = 0; k < outLen; k++)
            filtered[k].filteredIndex = k;

        this._version++;
    }
}