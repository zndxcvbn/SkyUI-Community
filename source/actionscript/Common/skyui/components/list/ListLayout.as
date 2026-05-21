/*
 *  Encapsulates the list layout configuration.
 */
class skyui.components.list.ListLayout
{
  /* CONSTANTS */

    private static var MAX_TEXTFIELD_INDEX = 10;

    private static var LEFT = 0;
    private static var RIGHT = 1;
    private static var TOP = 2;
    private static var BOTTOM = 3;

    public static var COL_TYPE_ITEM_ICON = 0;
    public static var COL_TYPE_EQUIP_ICON = 1;
    public static var COL_TYPE_TEXT = 2;
    public static var COL_TYPE_NAME = 3;


  /* PRIVATE VARIABLES */

    private var _activeViewIndex: Number = -1;

    private var _layoutData: Object;
    private var _viewData: Object;
    private var _columnData: Object;
    private var _defaultsData: Object;

    private var _lastViewIndex: Number = -1;

    // Active sort as an ordered chain of {columnIndex, columnState, reverse,
    // columnId}. [0] is the primary key; later entries are secondary keys added
    // via Shift+click. columnId is the column's stable identifier, so the chain
    // survives view (category) changes even though columnIndex does not. The
    // chain always holds at least one entry.
    private var _sortChain: Array;

    private var _stateData: Object;

    private var _defaultEntryTextFormat: TextFormat;
    private var _defaultLabelTextFormat: TextFormat;

    // List of views in this layout (updated only when the config changes)
    private var _viewList: Array;

    // List of columns for the current view (updated when the view changes
    private var _columnList: Array;

    private var _lastFilterFlag: Number = -1;

    private var _categoryToViewIndex: Object;
    private var _columnIndexById: Object;
    private var _layoutIndexByColumnList: Array;


  /* PROPERTIES */

    public function get currentView()
    {
        return this._viewList[this._activeViewIndex];
    }

    // Primary (first) sort column. Kept for the single-sort callers and the header.
    public function get activeColumnIndex()
    {
        return this._sortChain[0].columnIndex;
    }

    public function get activeColumnState()
    {
        return this._sortChain[0].columnState;
    }

    public function get forceReverse()
    {
        return this._sortChain[0].reverse;
    }

    public function get sortChain()
    {
        return this._sortChain;
    }

    public function get columnCount()
    {
        return this._columnLayoutData.length;
    }

    private var _columnLayoutData: Array;

    public function get columnLayoutData()
    {
        return this._columnLayoutData;
    }

    private var _hiddenStageNames: Array;

    public function get hiddenStageNames()
    {
        return this._hiddenStageNames;
    }

    private var _entryWidth: Number;

    public function get entryWidth()
    {
        return this._entryWidth;
    }

    public function set entryWidth(a_width: Number)
    {
        this._entryWidth = a_width;
    }

    private var _entryHeight: Number;

    public function get entryHeight()
    {
        return this._entryHeight;
    }

    private var _layoutUpdateCount: Number = 1;

    public function get layoutUpdateCount()
    {
        return this._layoutUpdateCount;
    }

    private var _columnDescriptors: Array;

    public function get columnDescriptors()
    {
        return this._columnDescriptors;
    }

    private var _sortOptions: Array;

    public function get sortOptions()
    {
        return this._sortOptions;
    }

    private var _sortAttributes: Array;

    public function get sortAttributes()
    {
        return this._sortAttributes;
    }

    private var _columnMargin: Number;

    public function get columnMargin()
    {
        return this._columnMargin;
    }

    public function set columnMargin(a_margin: Number)
    {
        this._columnMargin = a_margin;
    }



  /* INITIALIZATION */

    public function ListLayout(a_layoutData: Object, a_viewData: Object, a_columnData: Object, a_defaultsData: Object)
    {
        Shared.GlobalFunc.AddArrayExtensions();
        Shared.GlobalFunc.AddTextFormatExtensions();

        gfx.events.EventDispatcher.initialize(this);

        this._columnIndexById = {};
        this._layoutIndexByColumnList = [];

        this._sortChain = [ {columnIndex: -1, columnState: 1, reverse: false, columnId: null} ];
        this._viewList = [];
        this._columnList = [];
        this._columnLayoutData = [];
        this._hiddenStageNames = [];
        this._columnDescriptors = [];

        this._layoutData = a_layoutData;
        this._viewData = a_viewData;
        this._columnData = a_columnData;
        this._defaultsData = a_defaultsData;

        if (this._entryWidth == undefined)
            this._entryWidth = this._defaultsData.entryWidth;

        if (this._columnMargin == undefined)
            this._columnMargin = this._defaultsData.columnMargin;

        this.updateViewList();
        this.updateColumnList();

        // Initial textformats
        this._defaultEntryTextFormat = new TextFormat();
        this._defaultLabelTextFormat = new TextFormat();

        // Copy default textformat values from config
        for (var prop in this._defaultsData.entry.textFormat)
            if (this._defaultEntryTextFormat.hasOwnProperty(prop))
                this._defaultEntryTextFormat[prop] = this._defaultsData.entry.textFormat[prop];

        for (var prop in this._defaultsData.label.textFormat)
            if (this._defaultLabelTextFormat.hasOwnProperty(prop))
                this._defaultLabelTextFormat[prop] = this._defaultsData.label.textFormat[prop];
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

    public function refresh()
    {
        this.updateViewList();
        this._lastViewIndex = -1;
        this.changeFilterFlag(this._lastFilterFlag);
    }

    public function changeFilterFlag(a_flag: Number)
    {
        this._lastFilterFlag = a_flag;

        var activeIndex: Number = this._categoryToViewIndex[a_flag];

        if (activeIndex == undefined)
            activeIndex = this._viewList.length - 1;

        if (activeIndex == -1 || this._lastViewIndex == activeIndex)
            return;

        this._lastViewIndex = activeIndex;
        this._activeViewIndex = activeIndex;

        this.updateColumnList();
        this.resolveSortChain();
        this.updateLayout();
    }

    // Cycles the column at a_index forward (next state / ascending).
    public function selectColumn(a_index: Number, a_bShift: Boolean)
    {
        this.cycleColumn(a_index, a_bShift, 1);
    }

    // Cycles the column at a_index backward (previous state / descending).
    public function selectColumnPrev(a_index: Number, a_bShift: Boolean)
    {
        this.cycleColumn(a_index, a_bShift, -1);
    }

    // Restores a saved sort chain (array of {columnIndex, columnState, reverse}).
    // Entries that no longer map to a valid column are dropped.
    public function restoreSortChain(a_chain: Array)
    {
        if (a_chain == undefined)
            return;

        var chain = [];

        for (var i = 0; i < a_chain.length; i++) {
            var src = a_chain[i];
            var col = this._columnList[src.columnIndex];

            if (col == null || col.passive)
                continue;

            if (src.columnState < 1 || src.columnState > col.states)
                continue;

            chain.push(this.makeSortEntry(src.columnIndex, src.columnState, (src.reverse == true)));
        }

        if (chain.length == 0)
            return;

        this._sortChain = chain;
        this.updateLayout();
    }

    // Single-column restore; kept for callers that only deal with one column.
    public function restoreColumnState(a_activeIndex: Number, a_activeState: Number, a_reverse: Boolean)
    {
        this.restoreSortChain([ {columnIndex: a_activeIndex, columnState: a_activeState, reverse: (a_reverse == true)} ]);
    }

    public function clearSorting()
    {
        var primaryIndex = this._columnIndexById[this.currentView.primaryColumn];
        this._sortChain = [ this.makeSortEntry((primaryIndex != undefined) ? primaryIndex : 0, 1, false) ];
        this.updateLayout();
    }


  /* PRIVATE FUNCTIONS */

    // Handles a header click. a_direction is +1 (selectColumn) or -1
    // (selectColumnPrev) and controls which way multi-state columns cycle.
    private function cycleColumn(a_index: Number, a_bShift: Boolean, a_direction: Number)
    {
        var col = this._columnList[a_index];

        // Invalid column
        if (col == null || col.passive)
            return;

        if (a_bShift)
            this.shiftColumn(a_index);
        else
            this.replaceSort(a_index, col, a_direction);

        this.updateLayout();
    }

    // Shift+click: flips the direction of a column already in the chain, or
    // appends it as a new (ascending) secondary sort key.
    private function shiftColumn(a_index: Number)
    {
        var pos = this.sortChainPos(a_index);

        if (pos != -1)
            this._sortChain[pos].reverse = !this._sortChain[pos].reverse;
        else
            this._sortChain.push(this.makeSortEntry(a_index, 1, false));
    }

    // Plain click: cycles a column that is already part of the sort in place
    // (so multi-state columns can be stepped without losing the chain); a click
    // on an unsorted column resets to a single-column sort.
    private function replaceSort(a_index: Number, col: Object, a_direction: Number)
    {
        var pos = this.sortChainPos(a_index);

        if (pos == -1) {
            this._sortChain = [ this.makeSortEntry(a_index, (a_direction > 0) ? 1 : col.states, false) ];
            return;
        }

        var entry = this._sortChain[pos];

        if (col.states > 1) {
            var state = entry.columnState + a_direction;
            if (state < 1)
                state = col.states;
            else if (state > col.states)
                state = 1;
            entry.columnState = state;
        } else {
            entry.reverse = !entry.reverse;
        }
    }

    private function makeSortEntry(a_index: Number, a_state: Number, a_reverse: Boolean)
    {
        var col = this._columnList[a_index];
        return {columnIndex: a_index, columnState: a_state, reverse: a_reverse, columnId: (col != null) ? col.identifier : null};
    }

    // Position of the column within the sort chain, or -1 if it is not sorted.
    private function sortChainPos(a_index: Number)
    {
        for (var i = 0; i < this._sortChain.length; i++)
            if (this._sortChain[i].columnIndex == a_index)
                return i;

        return -1;
    }

    // Re-resolves the sort chain after a view change. Columns are remembered by
    // stable id; entries absent from the new view are dropped, and if nothing
    // remains the view's primary column becomes the sole sort.
    private function resolveSortChain()
    {
        var resolved = [];

        for (var i = 0; i < this._sortChain.length; i++) {
            var entry = this._sortChain[i];
            var idx = (entry.columnId != null) ? this._columnIndexById[entry.columnId] : undefined;

            if (idx != undefined) {
                entry.columnIndex = idx;
                resolved.push(entry);
            }
        }

        if (resolved.length == 0) {
            var primaryIndex = this._columnIndexById[this.currentView.primaryColumn];
            resolved.push(this.makeSortEntry((primaryIndex != undefined) ? primaryIndex : 0, 1, false));
        }

        this._sortChain = resolved;
    }

    // Builds the multi-key sort attribute/option arrays from the whole chain.
    // Each column's attribute list conventionally ends with "text" (a generic
    // item-name tiebreaker). In a multi-column sort that tiebreaker must run
    // only once, after every column's real key -- otherwise the first column's
    // trailing "text" leaves no ties for the later columns to break.
    private function rebuildSortParams()
    {
        var attributes = [];
        var options = [];
        var hasTextTail = false;
        var textTailOption = 0;

        for (var i = 0; i < this._sortChain.length; i++) {
            var entry = this._sortChain[i];
            var col = this._columnList[entry.columnIndex];

            if (col == null)
                continue;

            var stateData = col.statesData[entry.columnState];

            if (stateData == undefined || !stateData._cachedSortAttributes)
                continue;

            var entryAttributes = stateData._cachedSortAttributes;
            var entryOptions = entry.reverse ? stateData._cachedSortOptionsRev : stateData._cachedSortOptions;

            if (entryOptions == null)
                continue;

            var count = entryAttributes.length;

            // Peel a trailing "text" tiebreaker, but only when the column has a
            // real key of its own (more than one attribute).
            if (count > 1 && entryAttributes[count - 1] == "text") {
                hasTextTail = true;
                textTailOption = entryOptions[count - 1];
                count--;
            }

            for (var j = 0; j < count; j++) {
                attributes.push(entryAttributes[j]);
                options.push(entryOptions[j]);
            }
        }

        if (hasTextTail) {
            attributes.push("text");
            options.push(textTailOption);
        }

        if (attributes.length > 0) {
            this._sortAttributes = attributes;
            this._sortOptions = options;
        } else {
            this._sortAttributes = null;
            this._sortOptions = null;
        }
    }

    private function preprocessColumn(col: Object)
    {
        col._isProcessed = true;

        col.statesData = [];

        var numStates = col.states != undefined ? col.states : 1;

        for (var s = 1; s <= numStates; s++) {
            var stateData = col["state" + s];
            if (!stateData) continue;

            if (col.entry != undefined && col.entry.textFormat != undefined) {
                var entryTF = new TextFormat();
                this._mergeTextFormats(entryTF, this._defaultEntryTextFormat);
                this._mergeTextFormats(entryTF, col.entry.textFormat);
                stateData._cachedEntryTF = entryTF;
            } else {
                stateData._cachedEntryTF = this._defaultEntryTextFormat;
            }

            if (col.label != undefined && col.label.textFormat != undefined) {
                var labelTF = this._defaultLabelTextFormat.clone();
                this._mergeTextFormats(labelTF, col.label.textFormat);
                stateData._cachedLabelTF = labelTF;
            } else {
                stateData._cachedLabelTF = this._defaultLabelTextFormat;
            }

            var sortAttributes = stateData.sortAttributes;
            if (!sortAttributes && stateData.entry.text.charAt(0) == "@") {
                sortAttributes = [ stateData.entry.text.slice(1) ];
            }

            if (sortAttributes) {
                stateData._cachedSortAttributes = (sortAttributes.length !== undefined && typeof sortAttributes !== "string") ? sortAttributes : [sortAttributes];
            } else {
                stateData._cachedSortAttributes = null;
            }

            var sortOptions = stateData.sortOptions;
            if (sortOptions) {
                var baseOpts = (sortOptions.length !== undefined && typeof sortOptions !== "string") ? sortOptions.concat() : [sortOptions];
                stateData._cachedSortOptions = baseOpts;

                var revOpts =[];
                for (var i = 0; i < baseOpts.length; i++) {
                    revOpts[i] = baseOpts[i] ^ 2; // DESCENDING = 2
                }
                stateData._cachedSortOptionsRev = revOpts;
            } else {
                stateData._cachedSortOptions = null;
                stateData._cachedSortOptionsRev = null;
            }

            stateData._cachedArrowDown = stateData.label.arrowDown ? true : false;

            col.statesData[s] = stateData;
        }

        col._borderLeft = col.border != undefined ? col.border[skyui.components.list.ListLayout.LEFT] : 0;
        col._borderRight = col.border != undefined ? col.border[skyui.components.list.ListLayout.RIGHT] : 0;
        col._borderTop = col.border != undefined ? col.border[skyui.components.list.ListLayout.TOP] : 0;
        col._borderBottom = col.border != undefined ? col.border[skyui.components.list.ListLayout.BOTTOM] : 0;
        col._hasBorder = col.border != undefined;
    }

    private function _mergeTextFormats(target: TextFormat, source: Object)
    {
        for (var prop in source) {
            if (prop != "hasOwnProperty" && prop != "clone") {
                target[prop] = source[prop];
            }
        }
    }

    private function updateLayout()
    {
        this._layoutUpdateCount++;

        this.rebuildSortParams();

        var colCount = this._columnList.length;
        var maxHeight = 0;
        var textFieldIndex = 0;
        var bEnableItemIcon = false;
        var bEnableEquipIcon = false;

        var weightedFlags = 0;

        // Map columnIndex -> sort chain entry, for sort arrows and per-column state.
        var sortByIndex = {};
        for (var s = 0; s < this._sortChain.length; s++)
            sortByIndex[this._sortChain[s].columnIndex] = this._sortChain[s];

        // FIRST PASS: Collecting basic data
        for (var i = 0; i < colCount; i++) {
            var col = this._columnList[i];

            var cData = this._columnLayoutData[i];
            if (cData == undefined) {
                cData = new skyui.components.list.ColumnLayoutData();
                this._columnLayoutData[i] = cData;
            }

            var sortEntry = sortByIndex[i];
            var sorted = (sortEntry != undefined);
            var stateData = sorted ? col.statesData[sortEntry.columnState] : col.statesData[1];

            cData.type = col.type;
            cData.sorted = sorted;
            cData.labelValue = stateData.label.text;
            cData.entryValue = stateData.entry.text;
            cData.colorAttribute = stateData.colorAttribute;

            // Sort arrow
            if (sorted && sortEntry.reverse)
                cData.labelArrowDown = !stateData._cachedArrowDown;
            else
                cData.labelArrowDown = stateData._cachedArrowDown;
        }

        // WIDTH CALCULATION
        var weightedWidth = this._entryWidth - 12;
        var weightSum = 0;

        for (var i = 0; i < colCount; i++) {
            var col = this._columnList[i];
            var cData = this._columnLayoutData[i];

            // Calc total weighted width and set weighted flags
            if (col.weight != undefined) {
                weightSum += col.weight;
                weightedFlags = (weightedFlags | 1) << 1;
            } else {
                weightedFlags = (weightedFlags | 0) << 1;
            }

            if (col.indent != undefined)
                weightedWidth -= col.indent;

            // Height including borders for maxHeight
            var curHeight = 0;

            switch (col.type) {
                // ITEM ICON + EQUIP ICON
                case skyui.components.list.ListLayout.COL_TYPE_ITEM_ICON:
                case skyui.components.list.ListLayout.COL_TYPE_EQUIP_ICON:
                    if (col.type == skyui.components.list.ListLayout.COL_TYPE_ITEM_ICON) {
                        cData.stageName = "itemIcon";
                        bEnableItemIcon = true;
                    } else {
                        cData.stageName = "equipIcon";
                        bEnableEquipIcon = true;
                    }
                    cData.width = cData.height = col.icon.size;
                    weightedWidth -= col.icon.size;
                    curHeight += col.icon.size;
                    break;

                default:
                    cData.stageName = "textField" + textFieldIndex++;
                    if (col.width != undefined) {
                        cData.width = col.width < 1 ? (col.width * this._entryWidth) : col.width;
                        weightedWidth -= cData.width;
                    } else {
                        cData.width = 0;
                    }

                    cData.height = col.height != undefined ? (col.height < 1 ? (col.height * this._entryWidth) : col.height) : 0;

                    var sortEntry = sortByIndex[i];
                    var stateData = (sortEntry != undefined) ? col.statesData[sortEntry.columnState] : col.statesData[1];
                    cData.textFormat = stateData._cachedEntryTF;
                    cData.labelTextFormat = stateData._cachedLabelTF;
            }

            if (col._hasBorder) {
                weightedWidth -= (col._borderLeft + col._borderRight);
                curHeight += (col._borderTop + col._borderBottom);
                cData.y = col._borderTop;
            } else {
                cData.y = 0;
            }

            if (curHeight > maxHeight) maxHeight = curHeight;
        }

        // WEIGHT DISTRIBUTION
        if (weightSum > 0 && weightedWidth > 0 && weightedFlags != 0) {
            var tempFlags = weightedFlags;
            for (var i = colCount - 1; i >= 0; i--) {
                var col = this._columnList[i];
                var cData = this._columnLayoutData[i];

                if ((tempFlags >>>= 1) & 1) {
                    var share = (col.weight / weightSum) * weightedWidth;
                    if (col._hasBorder)
                        cData.width += share - col._borderLeft - col._borderRight;
                    else
                        cData.width += share;
                }
            }
        }

        // CALCULATION OF X POSITIONS
        var xPos = 0;
        var visibleColumnCount = colCount;
        for (var i = 0; i < colCount; i++) {
            var col = this._columnList[i];
            var cData = this._columnLayoutData[i];

            if (col.indent != undefined)
                xPos += col.indent;

            var offset = 0;
            if (cData.type == skyui.components.list.ListLayout.COL_TYPE_TEXT) {
                var multiplier = (visibleColumnCount - 1) - i;
                offset = this.columnMargin * multiplier;
            }

            cData.labelX = xPos - offset;

            if (col._hasBorder) {
                cData.labelWidth = cData.width + col._borderLeft + col._borderRight;
                cData.x = xPos - offset;
                xPos += col._borderLeft;
                cData.x = xPos - offset;
                xPos += col._borderRight + cData.width;
            } else {
                cData.labelWidth = cData.width;
                cData.x = xPos - offset;
                xPos += cData.width;
            }
        }

        this._columnLayoutData.length = colCount;

        var hIdx = 0;
        for (var i = textFieldIndex; i < skyui.components.list.ListLayout.MAX_TEXTFIELD_INDEX; i++)
            this._hiddenStageNames[hIdx++] = "textField" + i;

        if (!bEnableItemIcon) this._hiddenStageNames[hIdx++] = "itemIcon";
        if (!bEnableEquipIcon) this._hiddenStageNames[hIdx++] = "equipIcon";
        this._hiddenStageNames.length = hIdx;

        this._entryHeight = maxHeight;

        // sortChange might not always trigger an update, so we have to make sure the list is updated,
        // even if that means we update it twice.
        this.dispatchEvent({type: "layoutChange"});
    }

    private function updateViewList()
    {
        var viewList = this._viewList;
        var viewData = this._viewData;
        var viewNames = this._layoutData.views;

        viewList.length = 0;

        this._categoryToViewIndex = {};

        var len = viewNames.length;
        var c = 0;

        for (var i = 0; i < len; i++) {
            var view = viewData[viewNames[i]];

            if (view == undefined)
                continue;

            viewList[c] = view;

            var cats = view.category;
            if (!(cats instanceof Array))
                cats = [cats];

            for (var j = 0; j < cats.length; j++) {
                var cat = cats[j];

                if (this._categoryToViewIndex[cat] == undefined)
                    this._categoryToViewIndex[cat] = c;
            }

            c++;
        }
    }

    private function updateColumnList()
    {
        var columnNames = this.currentView.columns;
        var columnData = this._columnData;

        var columnList = this._columnList;
        var columnDescriptors = this._columnDescriptors;

        columnList.length = 0;
        columnDescriptors.length = 0;

        var indexMap = this._columnIndexById = {};
        var layoutIndexMap = this._layoutIndexByColumnList;
        layoutIndexMap.length = 0;

        var len = columnNames.length;
        var c = 0;

        for (var i = 0; i < len; i++)
        {
            var name = columnNames[i];
            var col = columnData[name];

            if (col.hidden)
                continue;

            col.identifier = name;

            if (!col._isProcessed)
                this.preprocessColumn(col);

            columnList[c] = col;

            columnDescriptors[c] = {
                identifier: name,
                longName: col.name,
                type: col.type
            };

            indexMap[name] = c;
            layoutIndexMap[i] = c;

            c++;
        }
    }
}
