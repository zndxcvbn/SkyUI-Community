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

    // viewIndex, columnIndex, stateIndex
    private var _prefData: Object;

    private var _stateData: Object;

    private var _defaultEntryTextFormat: TextFormat;
    private var _defaultLabelTextFormat: TextFormat;

    // List of views in this layout (updated only when the config changes)
    private var _viewList: Array;

    // List of columns for the current view (updated when the view changes
    private var _columnList: Array;

    private var _lastFilterFlag: Number = -1;

    private var _forceReverse: Boolean = false;

    private var _categoryToViewIndex: Object;
    private var _columnIndexById: Object;
    private var _layoutIndexByColumnList: Array;


  /* PROPERTIES */

    public function get currentView()
    {
        return this._viewList[this._activeViewIndex];
    }

    private var _activeColumnIndex: Number = -1;

    public function get activeColumnIndex()
    {
        return this._activeColumnIndex;
    }

    public function get columnCount()
    {
        return this._columnLayoutData.length;
    }

    private var _activeColumnState: Number = 1;

    public function get activeColumnState()
    {
        return this._activeColumnState;
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
        
        this._prefData = {column: null, stateIndex: 1};
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
        
        if (activeIndex == undefined) {
            activeIndex = this._viewList.length - 1;
        }

        if (activeIndex == -1 || this._lastViewIndex == activeIndex)
            return;

        this._lastViewIndex = activeIndex;
        this._activeViewIndex = activeIndex;

        this.updateColumnList();

        if (!this.restorePrefState()) {
            var primaryColName = this.currentView.primaryColumn;
            var visibleIdx = this._columnIndexById[primaryColName];
            this._activeColumnIndex = (visibleIdx != undefined) ? visibleIdx : 0;
            this._activeColumnState = 1;
        }

        this.updateLayout();
    }

    public function selectColumn(a_index: Number, a_bShift: Boolean)
    {
        var col = this._columnList[a_index];
        
        // Invalid column
        if (col == null || col.passive)
            return;

        if (this._activeColumnIndex == a_index) {
            if (a_bShift) {
                this._forceReverse = !this._forceReverse;
            } else {
                this._forceReverse = false;
                if (this._activeColumnState < col.states)
                    this._activeColumnState++;
                else
                    this._activeColumnState = 1;
            }
        } else {
            this._activeColumnIndex = a_index;
            this._activeColumnState = 1;
            this._forceReverse = (a_bShift == true);
        }
        
        // Save as preferred state
        this._prefData.column = col;
        this._prefData.stateIndex = this._activeColumnState;
            
        this.updateLayout();
    }

    public function selectColumnPrev(a_index: Number, a_bShift: Boolean)
    {
        var col = this._columnList[a_index];
        
        // Invalid column
        if (col == null || col.passive)
            return;

        if (this._activeColumnIndex == a_index) {
            if (a_bShift) {
                this._forceReverse = !this._forceReverse;
            } else {
                this._forceReverse = false;
                if (this._activeColumnState > 1)
                    this._activeColumnState--;
                else
                    this._activeColumnState = col.states;
            }
        } else {
            this._activeColumnIndex = a_index;
            this._activeColumnState = col.states;
            this._forceReverse = (a_bShift == true);
        }
        // Save as preferred state
        this._prefData.column = col;
        this._prefData.stateIndex = this._activeColumnState;
            
        this.updateLayout();
    }

    public function restoreColumnState(a_activeIndex: Number, a_activeState: Number)
    {
        var col = this._columnList[a_activeIndex];
        
        // Invalid column
        if (col == null || col.passive)
            return;

        if (a_activeState < 1 || a_activeState > col.states)
            return;
        
        this._activeColumnIndex = a_activeIndex;
        this._activeColumnState = a_activeState;
        
        // Save as preferred state
        this._prefData.column = col;
        this._prefData.stateIndex = this._activeColumnState;

        this.updateLayout();
    }

    public function clearSorting()
    {
        this._forceReverse = false;
        this._activeColumnIndex = this.currentView.columns.indexOf(this.currentView.primaryColumn);
        if (this._activeColumnIndex == -1)
            this._activeColumnIndex = 0;
            
        this._activeColumnState = 1;
        this._prefData.column = this._columnList[this._activeColumnIndex];
        this._prefData.stateIndex = 1;
        this.updateLayout();
    }


  /* PRIVATE FUNCTIONS */

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

        var colCount = this._columnList.length;
        var maxHeight = 0;
        var textFieldIndex = 0;
        var bEnableItemIcon = false;
        var bEnableEquipIcon = false;
        
        var weightedFlags = 0;
        
        // FIRST PASS: Collecting basic data
        for (var i = 0; i < colCount; i++) {
            var col = this._columnList[i];
            
            var cData = this._columnLayoutData[i];
            if (cData == undefined) {
                cData = new skyui.components.list.ColumnLayoutData();
                this._columnLayoutData[i] = cData;
            }

            var isActive = (i == this._activeColumnIndex);
            var stateData = isActive ? col.statesData[this._activeColumnState] : col.statesData[1];
            
            if (isActive) this.updateSortParams(stateData, col.type);
            
            cData.type = col.type;
            cData.labelValue = stateData.label.text;
            cData.entryValue = stateData.entry.text;
            cData.colorAttribute = stateData.colorAttribute;
            
            // Sort arrow
            if (isActive && col.type == skyui.components.list.ListLayout.COL_TYPE_NAME && this._forceReverse)
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
                    
                    var stateData = (i == this._activeColumnIndex) ? col.statesData[this._activeColumnState] : col.statesData[1];
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
    
    private function updateSortParams(stateData: Object, colType: Number)
    {
        if (!stateData._cachedSortAttributes) {
            this._sortOptions = null;
            this._sortAttributes = null;
            return;
        }
        
        this._sortAttributes = stateData._cachedSortAttributes;

        if (colType == skyui.components.list.ListLayout.COL_TYPE_NAME && this._forceReverse) {
            this._sortOptions = stateData._cachedSortOptionsRev;
        } else {
            this._sortOptions = stateData._cachedSortOptions;
        }
    }

    private function restorePrefState()
    {
        // No preference to restore yet
        if (!this._prefData.column)
            return false;

        var listIndex = this._columnIndexById[this._prefData.column.identifier];

        if (listIndex == undefined)
            return false;

        this._activeColumnIndex = listIndex;
        this._activeColumnState = this._prefData.stateIndex;

        return true;
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