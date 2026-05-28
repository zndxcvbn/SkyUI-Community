class skyui.components.list.SortedListHeader extends MovieClip
{
  /* PRIVATE VARIABLES */

    private var _columns: Array;
    private var _itemCount: Number = -1;
    private var _countColumn: MovieClip;

    // Pool of sort-direction icons, one per column in the sort chain.
    // [0] is the sortIcon authored in the SWF; the rest are clones of it.
    private var _sortIcons: Array;


  /* STAGE ELEMENTS */

    public var sortIcon: MovieClip;
    public var iconColumnIndicator: MovieClip;


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
    }


  /* INITIALIZATION */

    public function SortedListHeader()
    {
        super();

        this._columns = new Array();
        this._sortIcons = new Array();
    }


  /* PUBLIC FUNCTIONS */

    public function columnPress(a_columnIndex: Number, a_bShift: Boolean)
    {
        this._layout.selectColumn(a_columnIndex, a_bShift);
    }

    public function columnRightPress(a_columnIndex: Number, a_bShift: Boolean)
    {
        this._layout.selectColumnPrev(a_columnIndex, a_bShift);
    }

    public function columnCtrlPress(a_columnIndex: Number)
    {
        this._layout.clearSorting();
    }

    // Middle click: relayed to the owning list so the menu can open the
    // column-value filter dialog. The header itself is not list-specific.
    public function columnMiddlePress(a_columnIndex: Number)
    {
        this._parent.dispatchEvent({type: "columnValueRequest", columnIndex: a_columnIndex});
    }

    public function updateItemCount(a_count: Number)
    {
        this._itemCount = a_count;

        if (a_count < 0) {
            if (this._countColumn != undefined)
                this._countColumn._visible = false;
            if (this._layout != undefined)
                this.positionButtons();
            return;
        }

        this.positionButtons();
    }


  /* PRIVATE FUNCTIONS */

    private function getValueFilter()
    {
        var list = this._parent;
        if (list == undefined) return undefined;

        var enumeration = list.listEnumeration;
        if (enumeration == undefined) return undefined;

        var chain = enumeration._filterChain;
        if (chain == undefined) return undefined;

        for (var i = 0; i < chain.length; i++) {
            if (chain[i] instanceof skyui.filter.ColumnValueFilter) {
                return chain[i];
            }
        }
        return undefined;
    }

    private function drawFilterIndicator(mc: MovieClip, r: Number, color: Number)
    {
        mc.clear();
        mc.beginFill(color, 100);
        
        var a = r * 0.414213562;
        var b = r * 0.707106781;
        mc.moveTo(r, 0);
        mc.curveTo(r, -a, b, -b);
        mc.curveTo(a, -r, 0, -r);
        mc.curveTo(-a, -r, -b, -b);
        mc.curveTo(-r, -a, -r, 0);
        mc.curveTo(-r, a, -b, b);
        mc.curveTo(-a, r, 0, r);
        mc.curveTo(a, r, b, b);
        mc.curveTo(r, a, r, 0);
        mc.endFill();
    }

    // Hides all columns (but doesn't delete them since they can be re-used later).
    private function clearColumns()
    {
        for (var i = 0; i < this._columns.length; i++)
            this._columns[i]._visible = false;
    }

    private function addColumn(a_index: Number)
    {
        if (a_index < 0)
            return undefined;

        var columnButton = this["Column" + a_index];

        if (columnButton != undefined) {
            this._columns[a_index] = columnButton;
            this._columns[a_index]._visible = true;
            return columnButton;
        }

        // Create on-demand
        columnButton = this.attachMovie("HeaderColumn", "Column" + a_index, this.getNextHighestDepth());

        columnButton.columnIndex = a_index;

        columnButton.onPress = function(a_mouseIndex, a_keyboardOrMouse, a_buttonIndex)
        {
            if (this.columnIndex != undefined) {
                if (Key.isDown(Key.CONTROL))
                    this._parent.columnCtrlPress(this.columnIndex);
                else
                    this._parent.columnPress(this.columnIndex, Key.isDown(Key.SHIFT));
            }
        };

        columnButton.onPressAux = function(a_mouseIndex, a_keyboardOrMouse, a_buttonIndex)
        {
            if (this.columnIndex == undefined)
                return;

            if (a_buttonIndex == 1)
                this._parent.columnRightPress(this.columnIndex, Key.isDown(Key.SHIFT));
            else if (a_buttonIndex == 2)
                this._parent.columnMiddlePress(this.columnIndex);
        };

        this._columns[a_index] = columnButton;
        return columnButton;
    }

    // Returns a pooled sort-direction icon. Index 0 is the sortIcon authored in
    // the SWF; higher indices are clones of it, created on demand.
    private function getSortIcon(a_index: Number)
    {
        if (this._sortIcons[a_index] != undefined)
            return this._sortIcons[a_index];

        var icon = (a_index == 0)
            ? this.sortIcon
            : this.sortIcon.duplicateMovieClip("sortIcon" + a_index, this.getNextHighestDepth());

        this._sortIcons[a_index] = icon;
        return icon;
    }

    private function onLayoutChange(event)
    {
        this.clearColumns();

        for (var i = 0; i < this._layout.columnCount; i++) {
            var columnLayoutData = this._layout.columnLayoutData[i];
            var btn = this.addColumn(i);

            btn.label._x = 0;

            btn._x = columnLayoutData.labelX;

            btn.label._width = columnLayoutData.labelWidth;
            btn.label.setTextFormat(columnLayoutData.labelTextFormat);

            btn.label.SetText(columnLayoutData.labelValue);
        }

        this.positionButtons();
    }

    // Places the buttonAreas around textfields and the sort indicators.
    private function positionButtons()
    {
        var sortIconIndex = 0;
        var valueFilter = this.getValueFilter();

        for (var i = 0; i < this._columns.length; i++) {
            var e = this._columns[i];
            var cData = this._layout.columnLayoutData[i];

            e.label._y = -e.label._height;

            e.buttonArea._x = e.label.getLineMetrics(0).x - 4;
            e.buttonArea._width = e.label.getLineMetrics(0).width + 8;
            e.buttonArea._y = e.label._y - 2;
            e.buttonArea._height = e.label._height + 2;

            var iconAnchorX = e._x + e.buttonArea._x + e.buttonArea._width;

            if (cData.type == skyui.components.list.ListLayout.COL_TYPE_ITEM_ICON) {
                this.iconColumnIndicator._x = iconAnchorX;
                this.iconColumnIndicator._y = -e._height + ((e._height - this.iconColumnIndicator._height) / 2);
                this.iconColumnIndicator._visible = !cData.sorted;
            }

            // Sort-direction icon, one per column participating in the sort.
            var icon = null;
            if (cData.sorted) {
                icon = this.getSortIcon(sortIconIndex++);
                icon.gotoAndStop(cData.labelArrowDown ? "desc" : "asc");
                icon._visible = true;
                icon._x = iconAnchorX;
                icon._y = -e._height + ((e._height - icon._height) / 2) - 1;
            }

            // --- Filter Indicator ---
            var attr = this._layout.getColumnAttribute(i);
            var isFiltered = (valueFilter != undefined && attr != null && valueFilter.isColumnFiltered(attr));

            var indicator = e.filterIndicator;
            if (isFiltered) {
                if (indicator == undefined) {
                    indicator = e.createEmptyMovieClip("filterIndicator", e.getNextHighestDepth());
                    this.drawFilterIndicator(indicator, 2, 0xFF9900);
                }
                indicator._visible = true;
                
                var indicatorX = e.buttonArea._x + e.buttonArea._width + 4;
                if (cData.sorted) {
                    indicatorX += 10;
                }
                indicator._x = indicatorX;
                indicator._y = e.label._y + (e.label._height / 2) - 1;
            } else {
                if (indicator != undefined) {
                    indicator._visible = false;
                }
            }

            if (cData.type == skyui.components.list.ListLayout.COL_TYPE_NAME && this._itemCount >= 0) {

                if (this._countColumn == undefined) {
                    this._countColumn = this.attachMovie("HeaderColumn", "CountColumn", this.getNextHighestDepth());
                    this._countColumn.buttonArea._visible = false;
                    this._countColumn.label.autoSize = "left";
                }

                var fmt: TextFormat = cData.labelTextFormat;
                this._countColumn.label.setTextFormat(fmt);
                this._countColumn.label.SetText("(" + this._itemCount + ")");

                var countAnchorX = iconAnchorX;
                if (isFiltered) {
                    countAnchorX += 12;
                }

                if (icon != null)
                    this._countColumn._x = icon._x + icon._width + 4;
                else
                    this._countColumn._x = countAnchorX + 4;

                this._countColumn._y = e._y;
                this._countColumn.label._y = e.label._y;
                this._countColumn._visible = true;

                e.buttonArea._width = (this._countColumn._x + this._countColumn.label._width) - (e._x + e.buttonArea._x);
            }
        }

        // Hide sort icons left over from a previously longer chain.
        for (var k = sortIconIndex; k < this._sortIcons.length; k++)
            this._sortIcons[k]._visible = false;
    }
}
