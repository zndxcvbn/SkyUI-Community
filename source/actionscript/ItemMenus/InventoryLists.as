class InventoryLists extends MovieClip
{   
  /* CONSTANTS */
    
    static var HIDE_PANEL = 0;
    static var SHOW_PANEL = 1;
    static var TRANSITIONING_TO_HIDE_PANEL = 2;
    static var TRANSITIONING_TO_SHOW_PANEL = 3;
    
    
  /* STAGE ELEMENTS */

    public var panelContainer: MovieClip;
    public var zoomButtonHolder: MovieClip;


  /* PRIVATE VARIABLES */

    private var _typeFilter: ItemTypeFilter;
    private var _nameFilter: NameFilter;
    private var _sortFilter: SortFilter;
    private var _columnValueFilter: ColumnValueFilter;
    
    private var _platform: Number;
    
    private var _currCategoryIndex: Number;
    private var _savedSelectionIndex: Number = -1;
    
    private var _searchKey: Number = -1;
    private var _switchTabKey: Number = -1;
    private var _sortOrderKey: Number = -1;
    private var _sortOrderKeyHeld: Boolean = false;
    
    private var _bTabbed = false;
    private var _leftTabText: String;
    private var _rightTabText: String;

    private var _columnSelectDialog: MovieClip;
    private var _columnSelectDialogX: Number;
    private var _columnSelectInterval: Number;
    

  /* PROPERTIES */

    public var itemList: TabularList;

    public var categoryList: CategoryList;
    
    public var tabBar: TabBar;
    
    public var searchWidget: SearchWidget;
    
    public var categoryLabel: MovieClip;
    
    public var columnSelectButton: Button;
    
    private var _currentState: Number;
    
    public function get currentState()
    {
        return this._currentState;
    }

    public function set currentState(a_newState: Number)
    {
        if (a_newState == InventoryLists.SHOW_PANEL)
            gfx.managers.FocusHandler.instance.setFocus(this.itemList, 0);

        this._currentState = a_newState;
    }
    
    private var _tabBarIconArt: Array;
    
    public function set tabBarIconArt(a_iconArt: Array)
    {
        this._tabBarIconArt = a_iconArt;
        
        if (this.tabBar)
            this.tabBar.setIcons(this._tabBarIconArt[0], this._tabBarIconArt[1]);
    }
    
    public function get tabBarIconArt()
    {
        return this._tabBarIconArt;
    }


  /* INITIALIZATION */

    public function InventoryLists()
    {
        super();

        Shared.GlobalFunc.AddArrayExtensions();
        Shared.GlobalFunc.SetExtendedLayoutFunctions();

        gfx.events.EventDispatcher.initialize(this);

        this.gotoAndStop("NoPanels");

        gfx.io.GameDelegate.addCallBack("SetCategoriesList", this, "SetCategoriesList");
        gfx.io.GameDelegate.addCallBack("InvalidateListData", this, "InvalidateListData");

        this._typeFilter = new skyui.filter.ItemTypeFilter();
        this._nameFilter = new skyui.filter.NameFilter();
        this._sortFilter = new skyui.filter.SortFilter();
        this._columnValueFilter = new skyui.filter.ColumnValueFilter();
        
        this.categoryList = this.panelContainer.categoryList;
        this.categoryLabel = this.panelContainer.categoryLabel;
        this.itemList = this.panelContainer.itemList;
        this.searchWidget = this.panelContainer.searchWidget;
        this.columnSelectButton = this.panelContainer.columnSelectButton;

        skyui.util.ConfigManager.registerLoadCallback(this, "onConfigLoad");
        skyui.util.ConfigManager.registerUpdateCallback(this, "onConfigUpdate");
    }
    
    
  /* PUBLIC FUNCTIONS */

    // @mixin by gfx.events.gfx.events.EventDispatcher
    public var dispatchEvent: Function;
    public var dispatchQueue: Function;
    public var hasEventListener: Function;
    public var addEventListener: Function;
    public var removeEventListener: Function;
    public var removeAllEventListeners: Function;
    public var cleanUpEvents: Function;
    
    // @mixin by Shared.Shared.GlobalFunc
    public var Lock: Function;
    
    public function InitExtensions()
    {
        Shared.GlobalFunc.SetLockFunction();

        this.categoryList.listEnumeration = new skyui.components.list.BasicEnumeration(this.categoryList.entryList);

        var listEnumeration = new skyui.components.list.FilteredEnumeration(this.itemList.entryList);
        listEnumeration.addFilter(this._typeFilter);
        listEnumeration.addFilter(this._nameFilter);
        listEnumeration.addFilter(this._columnValueFilter);
        listEnumeration.addFilter(this._sortFilter);
        this.itemList.listEnumeration = listEnumeration;
        // data processors are initialized by the top-level menu since they differ in each case
        
        this.itemList.listState.maxTextLength = 80;

        this._typeFilter.addEventListener("filterChange", this, "onFilterChange");
        this._nameFilter.addEventListener("filterChange", this, "onFilterChange");
        this._sortFilter.addEventListener("filterChange", this, "onFilterChange");
        this._columnValueFilter.addEventListener("filterChange", this, "onFilterChange");

        this.categoryList.addEventListener("itemPress", this, "onCategoriesItemPress");
        this.categoryList.addEventListener("itemPressAux", this, "onCategoriesItemPress");
        this.categoryList.addEventListener("selectionChange", this, "onCategoriesListSelectionChange");

        this.itemList.disableInput = false;

        this.itemList.addEventListener("selectionChange", this, "onItemsListSelectionChange");
        this.itemList.addEventListener("sortChange", this, "onSortChange");
        this.itemList.addEventListener("columnValueRequest", this, "onColumnValueRequest");

        this.searchWidget.addEventListener("inputStart", this, "onSearchInputStart");
        this.searchWidget.addEventListener("inputEnd", this, "onSearchInputEnd");
        this.searchWidget.addEventListener("inputChange", this, "onSearchInputChange");
        
        this.columnSelectButton.addEventListener("press", this, "onColumnSelectButtonPress");
        
        // Delay updates until config is ready
        this.categoryList.suspended = true;
        this.itemList.suspended = true;
        this.panelContainer.ListBackground.Lock("TB", true, true);
    }

    public function showPanel(a_bPlayBladeSound: Boolean)
    {
        // Release itemlist for updating
        this.categoryList.suspended = false;
        this.itemList.suspended = false;
        
        this._currentState = InventoryLists.TRANSITIONING_TO_SHOW_PANEL;
        this.gotoAndPlay("PanelShow");

        this.dispatchEvent({type:"categoryChange", index: this.categoryList.selectedIndex});

        if (a_bPlayBladeSound != false)
            gfx.io.GameDelegate.call("PlaySound",["UIMenuBladeOpenSD"]);
    }

    public function hidePanel()
    {
        this._currentState = InventoryLists.TRANSITIONING_TO_HIDE_PANEL;
        this.gotoAndPlay("PanelHide");
        gfx.io.GameDelegate.call("PlaySound",["UIMenuBladeCloseSD"]);
    }
    
    public function enableTabBar()
    {
        this._bTabbed = true;
        this.panelContainer.gotoAndPlay("tabbed");
        this.itemList.listHeight = 480;
    }

    public function setPlatform(a_platform: Number, a_bPS3Switch: Boolean)
    {
        this._platform = a_platform;

        this.categoryList.setPlatform(a_platform,a_bPS3Switch);
        this.itemList.setPlatform(a_platform,a_bPS3Switch);
    }

    // @GFx
    public function handleInput(details: InputDetails, pathToFocus: Array)
    {
        if (this._currentState != InventoryLists.SHOW_PANEL)
            return false;

        if (this._platform != 0) {
            if (details.skseKeycode == this._sortOrderKey) {
                if (details.value == "keyDown") {
                    this._sortOrderKeyHeld = true;

                    if (this._columnSelectDialog)
                        skyui.util.DialogManager.close();
                    else
                        this._columnSelectInterval = setInterval(this, "onColumnSelectButtonPress", 1000, {type: "timeout"});

                    return true;
                } else if (details.value == "keyUp") {
                    this._sortOrderKeyHeld = false;

                    if (this._columnSelectInterval == undefined)
                        // keyPress handled: Key was released after the interval expired, don't process any further
                        return true;

                    // keyPress not handled: Clear intervals and change value to keyDown to be processed later
                    clearInterval(this._columnSelectInterval);
                    delete(this._columnSelectInterval);
                    // Continue processing the event as a normal keyDown event
                    details.value = "keyDown";
                } else if (this._sortOrderKeyHeld && details.value == "keyHold") {
                    // Fix for opening journal menu while key is depressed
                    // For some reason this is the only time we receive a keyHold event
                    this._sortOrderKeyHeld = false;

                    if (this._columnSelectDialog)
                        skyui.util.DialogManager.close();

                    return true;
                }
            }

            if (this._sortOrderKeyHeld) // Disable extra input while interval is active
                return true;
        }
        
        var kc = details.code;
        var isCtrl = details.ctrlKey || Key.isDown(Key.CONTROL);

        if (isCtrl && (kc == 87 || kc == 38 || kc == 83 || kc == 40)) {
            if (details.value == "keyDown" || details.value == "keyHold") {
                var dir = (kc == 83 || kc == 40) ? 1 : -1;
                this.selectEquippedItem(dir);
                return true;
            }
            if (details.value == "keyUp") return true;
        }

        if (Shared.GlobalFunc.IsKeyPressed(details)) {
            // Search hotkey (default space)
            if (details.skseKeycode == this._searchKey) {
                this.searchWidget.startInput();
                return true;
            }
            
            // Toggle tab (default ALT)
            if (this.tabBar != undefined && details.skseKeycode == this._switchTabKey) {
                this.tabBar.tabToggle();
                return true;
            }
        }
        
        if (this.categoryList.handleInput(details, pathToFocus))
            return true;
        
        var nextClip = pathToFocus.shift();
        return nextClip.handleInput(details, pathToFocus);
    }

    public function getContentBounds()
    {
        var lb = this.panelContainer.ListBackground;
        return [lb._x, lb._y, lb._width, lb._height];
    }
    
    public function showItemsList()
    {
        this._currCategoryIndex = this.categoryList.selectedIndex;

        // Column values differ per category, so drop any active value filter.
        // The category change below re-invalidates the list anyway.
        this._columnValueFilter.reset();
        
        this.categoryLabel.textField.SetText(this.categoryList.selectedEntry.text);

        // Start with no selection
        this.itemList.selectedIndex = -1;
        this.itemList.scrollPosition = 0;

        if (this.categoryList.selectedEntry != undefined) {
            // Set filter type
            this._typeFilter.changeFilterFlag(this.categoryList.selectedEntry.flag);
            
            // Not set yet before the config is loaded
            this.itemList.layout.changeFilterFlag(this.categoryList.selectedEntry.flag);
        }
        
        this.itemList.requestUpdate();
        
        this.dispatchEvent({type: "itemHighlightChange", index: this.itemList.selectedIndex});

        this.itemList.disableInput = false;
    }

    // Called to initially set the category list.
    // @API
    public function SetCategoriesList()
    {
        var textOffset = 0;
        var flagOffset = 1;
        var bDontHideOffset = 2;
        var len = 3;
        var index = 0;

        this.categoryList.clearList();

        for (var i = 0; i < arguments.length; i = i + len) {
            var entry = {text: arguments[i + textOffset], flag: arguments[i + flagOffset], bDontHide: arguments[i + bDontHideOffset], savedItemIndex: 0, filterFlag: arguments[i + bDontHideOffset] == true ? (1) : (0)};
            this.categoryList.entryList.push(entry);

            if (entry.flag == 0)
                this.categoryList.dividerIndex = index;

            index++;
        }

        // Initialize tabbar labels and replace text of segment heads (name -> ALL)
        if (this._bTabbed) {
            // Restore 0 as default index for tabbed lists
            this.categoryList.selectedIndex = 0;
            this._leftTabText = this.categoryList.entryList[0].text;
            this._rightTabText = this.categoryList.entryList[this.categoryList.dividerIndex + 1].text;
            this.categoryList.entryList[0].text = this.categoryList.entryList[this.categoryList.dividerIndex + 1].text = "$ALL";
        }

        this.categoryList.InvalidateData();
    }

    // Called whenever the underlying entryList data is updated (using an item, equipping etc.)
    // @API
    public function InvalidateListData()
    {
        var flag = this.categoryList.selectedEntry.flag;

        for (var i = 0; i < this.categoryList.entryList.length; i++)
            this.categoryList.entryList[i].filterFlag = this.categoryList.entryList[i].bDontHide ? 1 : 0;

        this.itemList.InvalidateData();

        // Mark non-empty categories (bDontHide=false ones start at filterFlag 0).
        // A category is non-empty iff some item's flag bitmask intersects it.
        // Since (a & f) | (b & f) | ... == (a | b | ...) & f, OR-ing every item
        // flag once collapses the old O(items * categories) double loop into
        // O(items + categories).
        var itemEntryList = this.itemList.entryList;
        var categoryEntryList = this.categoryList.entryList;

        var allItemFlags = 0;
        for (var i = 0; i < itemEntryList.length; i++)
            allItemFlags |= itemEntryList[i].filterFlag;

        for (var j = 0; j < categoryEntryList.length; j++) {
            if (categoryEntryList[j].filterFlag == 0 && (allItemFlags & categoryEntryList[j].flag))
                categoryEntryList[j].filterFlag = 1;
        }

        this.categoryList.UpdateList();

        if (flag != this.categoryList.selectedEntry.flag) {
            // Triggers an update if filter flag changed
            this._typeFilter.itemFilter = this.categoryList.selectedEntry.flag;
            this.dispatchEvent({type:"categoryChange", index: this.categoryList.selectedIndex});
        }
        
        // This is called when an ItemCard list closes(ex. ShowSoulGemList) to refresh ItemCard data    
        if (this.itemList.selectedIndex == -1)
            this.dispatchEvent({type:"showItemsList", index: -1});
        else
            this.dispatchEvent({type:"itemHighlightChange", index: this.itemList.selectedIndex});
    }
    
    
  /* PRIVATE FUNCTIONS */

    private function onConfigLoad(event: Object)
    {
        var config = event.config;
        this._searchKey = config["Input"].controls.pc.search;
        
        if (this._platform == 0)
            this._switchTabKey = config["Input"].controls.pc.switchTab;
        else {
            this._switchTabKey = config["Input"].controls.gamepad.switchTab;
            this._sortOrderKey = config["Input"].controls.gamepad.sortOrder;
        }
    }

    private function onFilterChange()
    {
        this.itemList.requestInvalidate();
    }
    
    private function onTabBarLoad()
    {
        this.tabBar = this.panelContainer.tabBar;
        this.tabBar.setIcons(this._tabBarIconArt[0], this._tabBarIconArt[1]);
        this.tabBar.addEventListener("tabPress", this, "onTabPress");
        
        if (this.categoryList.dividerIndex != -1)
            this.tabBar.setLabelText(this._leftTabText, this._rightTabText);

        this.tabBar.Lock("B");
        this.tabBar._y = this._parent.bottomBar._y - this.tabBar._height - Stage.safeRect.y - Stage.visibleRect.y + 17;
    }
    
    private function onColumnSelectButtonPress(event: Object)
    {
        if (event.type == "timeout") {
            clearInterval(this._columnSelectInterval);
            delete(this._columnSelectInterval);
        }

        if (this._columnSelectDialog) {
            skyui.util.DialogManager.close();
            return;
        }
        
        this._savedSelectionIndex = this.itemList.selectedIndex;
        this.itemList.selectedIndex = -1;
        
        this.categoryList.disableSelection = this.categoryList.disableInput = true;
        this.itemList.disableSelection = this.itemList.disableInput = true;
        this.searchWidget.isDisabled = true;
            
        this._columnSelectDialog = skyui.util.DialogManager.open(this.panelContainer, "ColumnSelectDialog", {_x: this._columnSelectDialogX != undefined ? this._columnSelectDialogX : 554, _y: 35, layout: this.itemList.layout});
        this._columnSelectDialog.addEventListener("dialogClosed", this, "onColumnSelectDialogClosed");
    }
    
    private function onColumnSelectDialogClosed(event: Object)
    {
        this.categoryList.disableSelection = this.categoryList.disableInput = false;
        this.itemList.disableSelection = this.itemList.disableInput = false;
        this.searchWidget.isDisabled = false;
        
        this.itemList.selectedIndex = this._savedSelectionIndex;
    }

    // Middle click on a column header: open a checkbox dropdown listing the
    // distinct values of that column and let the player show/hide each value.
    private function onColumnValueRequest(event: Object)
    {
        // Only one dialog open at a time.
        if (this._columnSelectDialog)
            return;

        var columnIndex = event.columnIndex;
        var attribute = this.itemList.layout.getColumnAttribute(columnIndex);

        // Icon columns and the like have no backing value to filter by.
        if (attribute == undefined || attribute == null)
            return;

        this._columnValueFilter.setColumn(attribute);

        var valueEntries = this.collectColumnValues(attribute);
        if (valueEntries.length == 0)
            return;

        this._savedSelectionIndex = this.itemList.selectedIndex;
        this.itemList.selectedIndex = -1;

        this.categoryList.disableSelection = this.categoryList.disableInput = true;
        this.itemList.disableSelection = this.itemList.disableInput = true;
        this.searchWidget.isDisabled = true;

        var dialogX = this.itemList._x + this.itemList.header._x + this.itemList.layout.columnLayoutData[columnIndex].labelX + 9;

        this._columnSelectDialog = skyui.util.DialogManager.open(this.panelContainer, "ColumnSelectDialog",
            {_x: dialogX, _y: 120, valueFilter: this._columnValueFilter, valueEntries: valueEntries});
        this._columnSelectDialog.addEventListener("dialogClosed", this, "onColumnSelectDialogClosed");
    }

    // Distinct values of a_attribute among items in the current category, as
    // dialog entries {text, key, hidden} sorted by value. The display text
    // carries the per-value item count, e.g. "Dragon (16)".
    private function collectColumnValues(a_attribute: String)
    {
        var catFlag = this._typeFilter.itemFilter;
        var counts = {};
        var keys = [];
        var entryList = this.itemList.entryList;

        for (var i = 0; i < entryList.length; i++) {
            var entry = entryList[i];

            if (!this._typeFilter.isMatch(entry, catFlag))
                continue;

            var value = entry[a_attribute];
            var key = (value == undefined) ? "" : String(value);

            if (counts[key] == undefined) {
                counts[key] = 0;
                keys.push(key);
            }

            counts[key]++;
        }

        var valueEntries = [];

        for (var k = 0; k < keys.length; k++) {
            var ck = keys[k];
            var label = (ck == "" ? "-" : ck) + " (" + counts[ck] + ")";
            valueEntries.push({text: label, key: ck, hidden: this._columnValueFilter.isValueHidden(ck)});
        }

        valueEntries.sortOn("key", Array.CASEINSENSITIVE);

        return valueEntries;
    }
    
    private function onConfigUpdate(event: Object)
    {
        this.itemList.layout.refresh();
    }

    private function onCategoriesItemPress()
    {
        this.showItemsList();
    }
    
    private function onTabPress(event: Object)
    {
        if (this.categoryList.disableSelection || this.categoryList.disableInput || this.itemList.disableSelection || this.itemList.disableInput)
            return;
        
        if (event.index == skyui.components.TabBar.LEFT_TAB) {
            this.tabBar.activeTab = skyui.components.TabBar.LEFT_TAB;
            this.categoryList.activeSegment = CategoryList.LEFT_SEGMENT;
        } else if (event.index == skyui.components.TabBar.RIGHT_TAB) {
            this.tabBar.activeTab = skyui.components.TabBar.RIGHT_TAB;
            this.categoryList.activeSegment = CategoryList.RIGHT_SEGMENT;
        }
        
        gfx.io.GameDelegate.call("PlaySound",["UIMenuBladeOpenSD"]);
        this.showItemsList();
    }

    private function onCategoriesListSelectionChange(event: Object)
    {
        this.dispatchEvent({type:"categoryChange", index:event.index});
        
        if (event.index != -1)
            gfx.io.GameDelegate.call("PlaySound",["UIMenuFocus"]);
    }

    private function onItemsListSelectionChange(event: Object)
    {
        this.dispatchEvent({type:"itemHighlightChange", index:event.index});

        if (event.index != -1)
            gfx.io.GameDelegate.call("PlaySound",["UIMenuFocus"]);
    }

    private function onSortChange(event: Object)
    {
        this._sortFilter.setSortBy(event.attributes, event.options);
    }

    private function onSearchInputStart(event: Object)
    {
        this.categoryList.disableSelection = this.categoryList.disableInput = true;
        this.itemList.disableSelection = this.itemList.disableInput = true;
        this._nameFilter.filterText = "";
    }

    private function onSearchInputChange(event: Object)
    {
        this._nameFilter.filterText = event.data;
    }

    private function onSearchInputEnd(event: Object)
    {
        this.categoryList.disableSelection = this.categoryList.disableInput = false;
        this.itemList.disableSelection = this.itemList.disableInput = false;
        this._nameFilter.filterText = event.data;
    }

    function selectEquippedItem(a_direction: Number)
    {
        var list = this.itemList;
        var enumSize = list.getListEnumSize();
        if (enumSize <= 0) return;

        var currentEnumIdx = list.getSelectedListEnumIndex();
        if (currentEnumIdx == undefined || currentEnumIdx == -1) {
            currentEnumIdx = (a_direction > 0) ? -1 : 0;
        }

        for (var i = 1; i <= enumSize; i++) {
            var nextEnumIdx = (currentEnumIdx + (i * a_direction)) % enumSize;
            if (nextEnumIdx < 0) nextEnumIdx += enumSize;
            
            var entry = list.getListEnumEntry(nextEnumIdx);

            if (entry != undefined && entry.equipState != undefined && entry.equipState > 0) {
                list.doSetSelectedIndex(entry.itemIndex, 1); 
                gfx.io.GameDelegate.call("PlaySound", ["UIMenuFocus"]);
                return;
            }
        }
    }

    function applyDynamicWidth(a_newWidth: Number)
    {
        var defaultWidth = 530;
        var delta = a_newWidth - defaultWidth;

        this.panelContainer.ListBackground._width += delta;
        this.itemList.header.seperator._width += delta;
        this.categoryList.background._width += delta;

        var tab = this.panelContainer.tabBar;
        var halfDelta = delta / 2;

        tab.image._width += delta;
        tab.rightIcon._x += delta;
        tab.rightLabel._x += delta;
        tab.leftButton._width += halfDelta;
        tab.rightButton._x += halfDelta;
        tab.rightButton._width += halfDelta;

        this.itemList.scrollbar._x += delta;
        this.searchWidget._x += delta;
        this.columnSelectButton._x += delta;
        this._columnSelectDialogX = 554 + delta;
    }
}
