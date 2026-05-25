class skyui.components.list.EntryClipManager
{ 
  /* PRIVATE VARIABLES */

    private var _clipPool: Array;
    
    private var _list: BasicList;
    
    private var _entryRenderer: String;
    
    private var _nextIndex: Number = 0;
    
    
  /* PROPERTIES */
    
    private var _clipCount: Number = -1;
    
    public function get clipCount()
    {
        return this._clipCount;
    }
    
    // Grows the pool if needed. Per-frame visibility / itemIndex management
    // is now handled by the caller (ScrollingList.UpdateList) so the pool's
    // state is stable across UpdateList calls -- which is what lets the
    // display loop's same-entry skip check (B) actually fire.
    //
    // The only universal reset happens when the addressable count *shrinks*
    // (e.g. pagination toggle, listHeight change), because clips beyond the
    // new range must not stay visible with stale data.
    public function set clipCount(a_clipCount: Number)
    {
        var oldCount = this._clipCount;
        this._clipCount = a_clipCount;

        var d = a_clipCount - this._clipPool.length;
        if (d > 0)
            this.growPool(d);

        if (oldCount > a_clipCount) {
            for (var i = a_clipCount; i < this._clipPool.length; i++) {
                this._clipPool[i]._visible = false;
                this._clipPool[i].itemIndex = undefined;
            }
        }
    }
    
    
  /* INITIALIZATION */

    public function EntryClipManager(a_list: BasicList)
    {
        this._list = a_list;
        this._clipPool = [];
    }


  /* PUBLIC FUNCTIONS */
    
    public function getClip(a_index: Number)
    {
        if (a_index >= this._clipCount)
            return undefined;

        return this._clipPool[a_index];
    }
    
    
  /* PRIVATE FUNCTIONS */
    
    private function growPool(a_size: Number)
    {
        var entryRenderer = this._list.entryRenderer;

        for (var i = 0; i < a_size; i++) {
            var entryClip = this._list.attachMovie(entryRenderer, entryRenderer + this._nextIndex, this._list.getNextHighestDepth());
            entryClip.initialize(this._nextIndex, this._list.listState);

            // Fresh clips default to _visible = true sitting at (0, 0). If the
            // first UpdateList renders fewer entries than _maxListIndex (e.g.
            // small category), the unbound clips would otherwise stack their
            // initial-frame content on top of the first row. The trailing
            // cleanup in UpdateList can't catch them on the first frame
            // because _prevListIndex is still 0. Hide them here; the display
            // loop will turn _visible back on for each clip it binds.
            entryClip._visible = false;
            entryClip.itemIndex = undefined;

            this._clipPool[this._nextIndex] = entryClip;
            this._nextIndex++;
        }
    }
}