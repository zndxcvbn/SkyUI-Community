class skyui.components.list.TabularList extends skyui.components.list.ScrollingList
{
  /* PRIVATE VARIABLES */

    private var _previousColumnKey: Number = -1;
    private var _nextColumnKey: Number = -1;
    private var _sortOrderKey: Number = -1;
    private var _itemCountMode: Number = 0;

    // Cached header item count. UpdateList runs on every scroll, but the count
    // only changes when the filtered set, the sort attribute, or the count mode
    // changes -- so we recompute lazily, gated by _itemCountDirty.
    private var _cachedItemCount: Number = -1;
    private var _itemCountDirty: Boolean = true;

  /* STAGE ELEMENTS */

    public var header: SortedListHeader;


  /* PROPERTIES */ 

    private var _layout: ListLayout;

    public function get layout()
    {
        return this._layout;
    }

    public function set layout(a_layout: ListLayout)
    {
        if (this._layout)
            this._layout.removeEventListener("layoutChange", this, "onLayoutChange");
        this._layout = a_layout;
        this._layout.addEventListener("layoutChange", this, "onLayoutChange");
        
        if (this.header)
            this.header.layout = a_layout;
    }


  /* INITIALIZATION */

    public function TabularList()
    {
        super();
        
        skyui.util.ConfigManager.registerLoadCallback(this, "onConfigLoad");
    }


  /* PUBLIC FUNCTIONS */

    // @GFx
    public function handleInput(details: InputDetails, pathToFocus: Array)
    {		
        if (super.handleInput(details, pathToFocus))
            return true;

        if (!this.disableInput && this._platform != 0) {
            if (Shared.GlobalFunc.IsKeyPressed(details)) {
                if (details.skseKeycode == this._previousColumnKey) {
                    this._layout.selectColumn(this._layout.activeColumnIndex - 1);
                    return true;
                } else if (details.skseKeycode == this._nextColumnKey) {
                    this._layout.selectColumn(this._layout.activeColumnIndex + 1);
                    return true;
                } else if (details.skseKeycode == this._sortOrderKey) {
                    this._layout.selectColumn(this._layout.activeColumnIndex);
                    return true;
                }
            }
        }
        return false;
    }

    // @override ScrollingList
    public function InvalidateData()
    {
        // Filtered set / processed entries may change -- count is now stale.
        this._itemCountDirty = true;
        super.InvalidateData();
    }

    // @override ScrollingList
    public function UpdateList()
    {
        super.UpdateList();

        if (this.header == undefined || this.listEnumeration == undefined)
            return;

        if (this._itemCountMode <= 0 || this._layout == undefined || this._layout.columnLayoutData == undefined) {
            this.header.updateItemCount(-1);
            return;
        }

        if (this._itemCountDirty) {
            this._cachedItemCount = this.computeItemCount();
            this._itemCountDirty = false;
        }

        this.header.updateItemCount(this._cachedItemCount);
    }

    // Walks the filtered enumeration once; the result is cached. See
    // _itemCountDirty for what invalidates the cache.
    private function computeItemCount()
    {
        var totalRows = this.listEnumeration.size();
        var totalItemsCount = 0;

        var activeColIdx = this._layout.activeColumnIndex;
        var isActiveColName = (this._layout.columnLayoutData[activeColIdx].type == skyui.components.list.ListLayout.COL_TYPE_NAME);

        var primaryAttr: String;
        if (this._layout && this._layout.sortAttributes && this._layout.sortAttributes.length > 0) {
            primaryAttr = this._layout.sortAttributes[0];
        }

        for (var i = 0; i < totalRows; i++) {
            var entry = this.listEnumeration.at(i);
            if (entry != undefined) {
                var amountToAdd = (this._itemCountMode == 2 && entry.count != undefined && entry.count > 0) ? entry.count : 1;

                if (isActiveColName) {
                    if (primaryAttr == undefined || primaryAttr == "text" || entry[primaryAttr]) {
                        totalItemsCount += amountToAdd;
                    }
                } else {
                    totalItemsCount += amountToAdd;
                }
            }
        }

        return totalItemsCount;
    }

  /* PRIVATE FUNCTIONS */

    private function onConfigLoad(event: Object)
    {
        var config = event.config;
        
        if (config.ScrollingList.selection.animation != undefined)
            this.enableAnimation = config.ScrollingList.selection.animation;

        if (config.ScrollingList.pagination.enabled != undefined)
            this.paginationEnabled = config.ScrollingList.pagination.enabled;

        if (config.ScrollingList.pagination.align != undefined)
            this.setPagerAlign(config.ScrollingList.pagination.align);
        
        if (config.ItemList.itemCount.mode != undefined) {
            var mode = Number(config.ItemList.itemCount.mode);
            
            if (mode > 2) {
                mode = 2;
            } else if (mode < 0 || isNaN(mode)) {
                mode = 0;
            }
            
            this._itemCountMode = mode;
        } else {
            this._itemCountMode = 0;
        }

        this._itemCountDirty = true;

        this.applyScrollConfig(config.ScrollingList);

        if (this._platform != 0) {
            this._previousColumnKey = config["Input"].controls.gamepad.prevColumn;
            this._nextColumnKey = config["Input"].controls.gamepad.nextColumn;
            this._sortOrderKey = config["Input"].controls.gamepad.sortOrder;
        }
    }

    private function onLayoutChange(event: Object)
    {
        this.entryHeight = this._layout.entryHeight;

        this.header._x = this.leftBorder;

        this.recalcMaxListIndex();

        // sortAttributes / active column may have changed -- itemCount depends
        // on both, so the cached value is stale.
        this._itemCountDirty = true;

        // Column layout may have changed (e.g. column count differs between
        // categories). Bump the version so UpdateList's skip path forces a
        // re-render on currently-visible clips -- otherwise stale text fields
        // from the old layout linger until the user scrolls or hovers.
        this._layoutVersion++;
        // Token bump for UpdateList's fast-path skip.
        this._updateToken++;

        if (this._layout.sortAttributes && this._layout.sortOptions)
            this.dispatchEvent({type:"sortChange", attributes: this._layout.sortAttributes, options:  this._layout.sortOptions});

        this.requestUpdate();
    }
}