// @abstract
class skyui.components.list.TabularListEntry extends skyui.components.list.BasicListEntry
{
  /* CONSTANTS */
	
	private static var ANIM_FADE_STEP: Number = 10;
	private static var ANIM_MAX_JUMP_Y: Number = 600;
	private static var ANIM_Y_DECAY: Number = 0.6;
	private static var ANIM_Y_EPSILON: Number = 0.5;

  /* PRIVATE VARIABLES */

    private var _layoutUpdateCount: Number = -1;


  /* STAGE ELEMENTS */

    public var selectIndicator: MovieClip;


  /* INITIALIZATION */

    function TabularListEntry()
    {
        super();
    }


  /* PUBLIC FUNCTIONS */

    // @override BasicListEntry
    public function setEntry(a_entryObject: Object, a_state: ListState)
    {
        var layout: ListLayout = skyui.components.list.TabularList(a_state.list).layout;
            
        // Show select area if this is the current entry
        var isSelected: Boolean = (a_entryObject == a_state.list.selectedEntry);
        
        this.updateSelectionAnimation(isSelected, a_state.list);
        
        var curLayoutUpdateCount = layout.layoutUpdateCount;

        // Has the view update sequence number changed? Then Update the columns positions etc.
        if (this._layoutUpdateCount != curLayoutUpdateCount) {
            this._layoutUpdateCount = curLayoutUpdateCount;

            this.setEntryLayout(a_entryObject, a_state);
            this.setSpecificEntryLayout(a_entryObject, a_state);
        }

        // Entry-dependent state (e.g. status icons) must refresh on every
        // setEntry, not just on layout change -- the bound entry can change
        // (scroll, rebind) without the layout count moving. Subclasses
        // override updateSpecificEntryState to do the per-entry work that
        // used to live (incorrectly) inside the layout-gated branch above.
        this.updateSpecificEntryState(a_entryObject, a_state);
        
        // Format the actual entry contents. Do this with every update.
        // Per-column string ops (charAt/slice/stageName compare) are now
        // precomputed on columnLayoutData -- see ListLayout.updateLayout.
        for (var i = 0; i < layout.columnCount; i++) {
            var columnLayoutData: ColumnLayoutData = layout.columnLayoutData[i];
            var e = this.getColumnField(columnLayoutData.stageName);

            // Substitute @variables by entryObject properties
            var entryValue: String = columnLayoutData.entryValue;
            if (entryValue != undefined) {
                if (columnLayoutData.useReference) {
                    var subVal = a_entryObject[columnLayoutData.referenceAttr] != undefined
                        ? a_entryObject[columnLayoutData.referenceAttr]
                        : "-";
                    if (columnLayoutData.isFirstTextColumn)
                        subVal = this.__rf_cleanDisplayText(subVal);
                    e.SetText(subVal);
                } else {
                    if (columnLayoutData.isFirstTextColumn)
                        entryValue = this.__rf_cleanDisplayText(entryValue);
                    e.SetText(entryValue);
                }
            }

            // Process based on column type
            switch (columnLayoutData.type) {
                case skyui.components.list.ListLayout.COL_TYPE_EQUIP_ICON :
                    this.formatEquipIcon(e, a_entryObject, a_state);
                    break;

                case skyui.components.list.ListLayout.COL_TYPE_ITEM_ICON :
                    this.formatItemIcon(e, a_entryObject, a_state);
                    break;

                case skyui.components.list.ListLayout.COL_TYPE_NAME :
                    this.formatName(e, a_entryObject, a_state);
                    break;

                case skyui.components.list.ListLayout.COL_TYPE_TEXT :
                default :
                    this.formatText(e, a_entryObject, a_state);
            }

            // Process color overrides after regular formatting
            if (columnLayoutData.colorAttribute != undefined) {
                var color = a_entryObject[columnLayoutData.colorAttribute];
                if (color != undefined)
                    e.textColor = color;
            }
        }

        // We just rendered this entry. Clear the dirty flag so the next
        // UpdateList can skip a redundant setEntry on this clip if nothing
        // changed -- see ScrollingList display loop for the skip path.
        a_entryObject.skyui_renderDirty = false;
    }

    public function updateSelectionAnimation(isSelected: Boolean, a_list: ScrollingList)
    {
        if (isSelected) {
            this.selectIndicator._visible = true;
            
            if (a_list.bDisableAnim || a_list.enableAnimation === false) {
                this.resetSelectionAnim(true);
                a_list.lastSelectionAnimY = this._y;
                return;
            }

            if (a_list.lastSelectionAnimY == undefined || a_list.lastSelectionAnimY == -1) {
                this.selectIndicator._y = 0;
                this.selectIndicator._alpha = 0;
                a_list.lastSelectionAnimY = this._y;

                this.onEnterFrame = function() {
                    this.selectIndicator._alpha += skyui.components.list.TabularListEntry.ANIM_FADE_STEP; 
                    if (this.selectIndicator._alpha >= 100) {
                        this.selectIndicator._alpha = 100;
                        delete this.onEnterFrame;
                    }
                };
                return;
            }

            var prevY: Number = a_list.lastSelectionAnimY;
            var diffY: Number = prevY - this._y;
            if (diffY == 0) {
                this.resetSelectionAnim(true);
                return;
            }
            a_list.lastSelectionAnimY = this._y;
            
            if (Math.abs(diffY) < skyui.components.list.TabularListEntry.ANIM_MAX_JUMP_Y) {
                this.selectIndicator._y = diffY;
                this.selectIndicator._alpha = 100;

                this.onEnterFrame = function() {
                    this.selectIndicator._y *= skyui.components.list.TabularListEntry.ANIM_Y_DECAY; 
                    if (Math.abs(this.selectIndicator._y) < skyui.components.list.TabularListEntry.ANIM_Y_EPSILON) {
                        this.selectIndicator._y = 0;
                        delete this.onEnterFrame;
                    }
                };
            } else {
                this.resetSelectionAnim(true);
            }
        } else {
            this.resetSelectionAnim(false);
        }
    }

    // Do any clip-specific tasks when the view was changed for this entry.
    // @abstract
    public function setSpecificEntryLayout(a_entryObject: Object, a_state: ListState) {}

    // Refresh entry-dependent state (status icons etc.) on every setEntry.
    // Called even when the layout count hasn't moved -- this is what handles
    // entry rebinds during scroll, equipped/read state changes, etc.
    // @abstract
    public function updateSpecificEntryState(a_entryObject: Object, a_state: ListState) {}

    // @abstract
    public function formatName(a_entryField: Object, a_entryObject: Object, a_state: ListState) {}

    // @abstract
    public function formatEquipIcon(a_entryField: Object, a_entryObject: Object, a_state: ListState) {}

    // @abstract
    public function formatItemIcon(a_entryField: Object, a_entryObject: Object, a_state: ListState) {}

    // @abstract
    public function formatText(a_entryField: Object, a_entryObject: Object, a_state: ListState) {}


  /* PRIVATE FUNCTIONS */

    private function setEntryLayout(a_entryObject: Object, a_state: ListState)
    {
        var layout: ListLayout = skyui.components.list.TabularList(a_state.list).layout;
            
        this.background._width = this.selectIndicator._width = layout.entryWidth;
        this.background._height = this.selectIndicator._height = layout.entryHeight;

        // Set up all visible elements in this entry
        for (var i = 0; i < layout.columnCount; i++) {
            var columnLayoutData: ColumnLayoutData = layout.columnLayoutData[i];
            var e = this.getColumnField(columnLayoutData.stageName);

            e._visible = true;

            e._x = columnLayoutData.x;
            e._y = columnLayoutData.y;

            if (columnLayoutData.width > 0)
                e._width = columnLayoutData.width;

            if (columnLayoutData.height > 0)
                e._height = columnLayoutData.height;

            if (e instanceof TextField)
                e.setTextFormat(columnLayoutData.textFormat);
        }

        // Hide unused icons.
        var hiddenStageNames = layout.hiddenStageNames;
        for (var j = 0; j < hiddenStageNames.length; j++)
            this[hiddenStageNames[j]]._visible = false;

        // Hide text fields past the current column count. They are created on
        // demand, so the layout cannot list them in hiddenStageNames; the
        // existing ones are contiguous, so the probe stops at the first gap.
        var k = layout.textColumnCount;
        while (this["textField" + k] != undefined) {
            this["textField" + k]._visible = false;
            k++;
        }
    }

    // Returns the stage element backing a column, creating the text field on
    // demand so the column count is not capped by the entry's timeline.
    private function getColumnField(a_stageName: String)
    {
        var field = this[a_stageName];

        if (field == undefined && a_stageName.substr(0, 9) == "textField")
            field = this.createColumnTextField(a_stageName);

        return field;
    }

    // Creates a column text field, copying the timeline textField0's styling
    // (font embedding, html mode, filters) so dynamic columns match the rest.
    private function createColumnTextField(a_stageName: String)
    {
        var tf: TextField = this.createTextField(a_stageName, this.getNextHighestDepth(), 0, 0, 100, 24);
        var tpl = this.textField0;

        if (tpl != undefined) {
            tf.embedFonts = tpl.embedFonts;
            tf.html = tpl.html;
            tf.selectable = tpl.selectable;
            tf.multiline = tpl.multiline;
            tf.wordWrap = tpl.wordWrap;
            tf.antiAliasType = tpl.antiAliasType;
            tf.gridFitType = tpl.gridFitType;
            tf.filters = tpl.filters;
        }

        return tf;
    }

    // HACK: specific workaround for tab-delimited translation text (e.g. BOOBIES Potions).
    // TODO: replace with a cleaner generic solution if SkyUI handles this case centrally later.
    private function __rf_cleanDisplayText(a_text)
    {
        if (a_text == undefined)
            return a_text;
            
        var firstTabIndex = a_text.indexOf("\t");
        
        if (firstTabIndex == -1)
            return a_text;
            
        var lastValidCharIndex = firstTabIndex;
        
        while (lastValidCharIndex > 0 && (a_text.charCodeAt(lastValidCharIndex - 1) == 32 || a_text.charCodeAt(lastValidCharIndex - 1) == 160))
        {
            lastValidCharIndex--;
        }
        
        return a_text.substring(0, lastValidCharIndex);
    }

    private function resetSelectionAnim(a_visible: Boolean)
	{
		delete this.onEnterFrame;
		this.selectIndicator._visible = a_visible;
		this.selectIndicator._y = 0;
		this.selectIndicator._alpha = 100;
	}
}
