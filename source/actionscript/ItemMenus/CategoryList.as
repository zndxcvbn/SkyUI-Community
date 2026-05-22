class CategoryList extends skyui.components.list.BasicList
{
  /* CONSTANTS */
    
    public static var LEFT_SEGMENT: Number  = 0;
    public static var RIGHT_SEGMENT: Number = 1;
    
    // Icon transparency settings
    private static var ALPHA_NORMAL: Number = 50;
    private static var ALPHA_HOVER: Number  = 75;
    
    // Selector animation settings
    private static var ANIM_SPEED: Number   = 0.2;
    private static var ANIM_SNAP: Number    = 1.0;
    
    
  /* STAGE ELEMENTS */
    
    public var selectorCenter: MovieClip;
    public var selectorLeft: MovieClip;
    public var selectorRight: MovieClip;
    public var background: MovieClip;
    
    
  /* PRIVATE VARIABLES */
    
    private var _xOffset: Number;
    private var _contentWidth: Number;
    private var _totalWidth: Number;
    private var _selectorPos: Number;
    private var _targetSelectorPos: Number;
    private var _bFastSwitch: Boolean;
    private var _segmentOffset: Number;
    private var _segmentLength: Number;


  /* PROPERTIES */
    
    // Distance from border to start icon.
    public var iconIndent: Number;
    
    // Size of the icon.
    public var iconSize: Number;
    
    // Array that contains the icon label for category at position i.
    // The category list uses fixed lengths/icons, so this is assigned statically.
    public var iconArt: Array;
    
    // For segmented lists, this is in the index of the divider that seperates player and container/vendor inventory.
    public var dividerIndex: Number;
    
    // The active segment for divided lists (left or right).
    private var _activeSegment: Number;
    
    public function set activeSegment(a_segment: Number)
    {
        if (a_segment == this._activeSegment)
            return;
        
        this._activeSegment = a_segment;
        
        this.calculateSegmentParams();
        
        if (a_segment == CategoryList.LEFT_SEGMENT && this._selectedIndex > this.dividerIndex)
            this.doSetSelectedIndex(this._selectedIndex - this.dividerIndex - 1, skyui.components.list.BasicList.SELECT_MOUSE);
        else if (a_segment == CategoryList.RIGHT_SEGMENT && this._selectedIndex < this.dividerIndex)
            this.doSetSelectedIndex(this._selectedIndex + this.dividerIndex + 1, skyui.components.list.BasicList.SELECT_MOUSE);
        
        this.requestUpdate();
    }
    
    public function get activeSegment()
    {
        return this._activeSegment;
    }
    
    
  /* INITIALIZATION */
    
    public function CategoryList()
    {
        super();
        
        this._selectorPos = 0;
        this._targetSelectorPos = 0;
        this._bFastSwitch = false;

        this._activeSegment = CategoryList.LEFT_SEGMENT;
        this.dividerIndex = -1;
        this._segmentOffset = 0;
        this._segmentLength = 0;
        
        this.iconSize = 32;
    }
    
    
  /* PUBLIC FUNCTIONS */

    // Clears the list. For the category list, that's ok since the entryList isn't manipulated directly.
    // @override BasicList
    public function clearList()
    {
        this.dividerIndex = -1;
        this._entryList.splice(0);
    }
    
    // @override BasicList
    public function InvalidateData()
    {
        if (this._bSuspended) {
            this._bRequestInvalidate = true;
            return;
        }
        
        this.listEnumeration.invalidate();

        this.calculateSegmentParams();
        
        if (this._selectedIndex >= this.listEnumeration.size())
            this._selectedIndex = this.listEnumeration.size() - 1;

        this.UpdateList();
        
        if (this.onInvalidate)
            this.onInvalidate();
    }
    
    // @override BasicList
    public function UpdateList()
    {
        if (this._bSuspended) {
            this._bRequestUpdate = true;
            return;
        }
        
        this.setClipCount(this._segmentLength);
        
        this._contentWidth = this._segmentLength * this.iconSize;
        this._totalWidth = this.background._width;

        var clipsArray: Array = [];
        
        for (var i: Number = 0; i < this._segmentLength; i++) {
            var entryClip: MovieClip = this.getClipByIndex(i);
            var entryData: Object = this.listEnumeration.at(i + this._segmentOffset);

            entryData.clipIndex = i;
            entryClip.itemIndex = i + this._segmentOffset;
            entryClip.setEntry(entryData, this.listState);

            entryClip.background._width = this.iconSize;
            entryClip.background._height = this.iconSize;
            entryClip._visible = true;

            clipsArray.push(entryClip);
        }
        
        this.background.JustifyContent(clipsArray, "space-evenly");
        
        this.updateSelector();
    }
    
    // Moves the selection left to the next element. Wraps around.
    public function moveSelectionLeft()  { this.moveSelection(-1); }

    // Moves the selection right to the next element. Wraps around.
    public function moveSelectionRight() { this.moveSelection(1); }
    
    // @GFx
    public function handleInput(details: InputDetails, pathToFocus: Array)
    {
        if (this.disableInput)
            return false;
            
        if (!Shared.GlobalFunc.IsKeyPressed(details))
            return false;
        
        if (details.navEquivalent == gfx.ui.NavigationCode.LEFT) {
            this.moveSelectionLeft();
            return true;
        }
        
        if (details.navEquivalent == gfx.ui.NavigationCode.RIGHT) {
            this.moveSelectionRight();
            return true;
        }
        
        return false;
    }
    
    // @override BasicList
    public function onEnterFrame()
    {
        super.onEnterFrame();
        
        if (this._selectorPos == this._targetSelectorPos)
            return;
        
        var distance: Number = this._targetSelectorPos - this._selectorPos;
        
        if (Math.abs(distance) < CategoryList.ANIM_SNAP)
            this._selectorPos = this._targetSelectorPos;
        else
            this._selectorPos += distance * CategoryList.ANIM_SPEED;
        
        this.refreshSelector();
    }
    
    // @override BasicList
    public function onItemPress(a_index: Number, a_keyboardOrMouse: Number)
    {
        if (this.disableInput || this.disableSelection || a_index == -1)
            return;
            
        this.doSetSelectedIndex(a_index, a_keyboardOrMouse);
        this.updateSelector();
        this.dispatchEvent({type: "itemPress", index: this._selectedIndex, entry: this.selectedEntry, keyboardOrMouse: a_keyboardOrMouse});
    }
    
    // @override BasicList
    private function onItemPressAux(a_index: Number, a_keyboardOrMouse: Number, a_buttonIndex: Number)
    {
        if (this.disableInput || this.disableSelection || a_index == -1 || a_buttonIndex != 1)
            return;
        
        this.doSetSelectedIndex(a_index, a_keyboardOrMouse);
        this.updateSelector();
        this.dispatchEvent({type: "itemPressAux", index: this._selectedIndex, entry: this.selectedEntry, keyboardOrMouse: a_keyboardOrMouse});
    }
    
    // @override BasicList
    public function onItemRollOver(a_index: Number)
    {
        if (this.disableInput || this.disableSelection)
            return;
            
        this.isMouseDrivenNav = true;
        
        if (a_index == this._selectedIndex)
            return;
            
        var entryClip: MovieClip = this.getClipByIndex(a_index);
        entryClip._alpha = CategoryList.ALPHA_HOVER;
    }

    // @override BasicList
    public function onItemRollOut(a_index: Number)
    {
        if (this.disableInput || this.disableSelection)
            return;
            
        this.isMouseDrivenNav = true;
        
        if (a_index == this._selectedIndex)
            return;
            
        var entryClip: MovieClip = this.getClipByIndex(a_index);
        entryClip._alpha = CategoryList.ALPHA_NORMAL;
    }


  /* PRIVATE FUNCTIONS */
    
    private function calculateSegmentParams()
    {
        // Divided
        if (this.dividerIndex != undefined && this.dividerIndex != -1) {
            if (this._activeSegment == CategoryList.LEFT_SEGMENT) {
                this._segmentOffset = 0;
                this._segmentLength = this.dividerIndex;
            } else {
                this._segmentOffset = this.dividerIndex + 1;
                this._segmentLength = this.listEnumeration.size() - this._segmentOffset;
            }
        
        // Default for non-divided lists
        } else {
            this._segmentOffset = 0;
            this._segmentLength = this.listEnumeration.size();
        }
    }
    
    private function isDisabledCategory(index: Number)
    {
        var entry: Object = this.listEnumeration.at(index);
        return (entry.filterFlag == 0 && !entry.bDontHide);
    }
    
    private function moveSelection(direction: Number)
    {
        if (this.disableSelection) return;

        var curIndex: Number = this._selectedIndex;
        var startIndex: Number = this._selectedIndex;
        var minIndex: Number = this._segmentOffset;
        var maxIndex: Number = this._segmentOffset + this._segmentLength - 1;

        do {
            curIndex += direction;
            
            if (curIndex < minIndex) {
                this._bFastSwitch = true;
                curIndex = maxIndex;
            } else if (curIndex > maxIndex) {
                this._bFastSwitch = true;
                curIndex = minIndex;
            }
            
        } while (curIndex != startIndex && this.isDisabledCategory(curIndex));

        this.onItemPress(curIndex, 0);
    }
    
    private function applySelectorLayout(centerX: Number)
    {
        this.selectorCenter._x = centerX;

        if (this.selectorLeft != undefined) {
            this.selectorLeft._width = centerX;
        }

        if (this.selectorRight != undefined) {
            this.selectorRight._x = centerX + this.selectorCenter._width;
            this.selectorRight._width = this._totalWidth - this.selectorRight._x;
        }
    }
    
    private function updateSelector()
    {
        if (this.selectorCenter == undefined) {
            return;
        }
        
        if (this._selectedIndex == -1) {
            this.selectorCenter._visible = false;

            if (this.selectorLeft != undefined)
                this.selectorLeft._visible = false;
                
            if (this.selectorRight != undefined)
                this.selectorRight._visible = false;

            return;
        }

        var selectedClip: MovieClip = this._entryClipManager.getClip(this._selectedIndex - this._segmentOffset);

        this._targetSelectorPos = selectedClip._x + (selectedClip.background._width - this.selectorCenter._width) / 2;
        
        this.selectorCenter._visible = true;
        this.selectorCenter._y = selectedClip._y + selectedClip.background._height;
        
        if (this.selectorLeft != undefined) {
            this.selectorLeft._visible = true;
            this.selectorLeft._x = 0;
            this.selectorLeft._y = this.selectorCenter._y;
        }

        if (this.selectorRight != undefined) {
            this.selectorRight._visible = true;
            this.selectorRight._y = this.selectorCenter._y;
        }
        
        if (this._bFastSwitch) {
            this._selectorPos = this._targetSelectorPos;
            this._bFastSwitch = false;
            this.refreshSelector();
        } else if (this._selectorPos == this._targetSelectorPos) {
            this.refreshSelector();
        }
    }

    private function refreshSelector()
    {
        this.selectorCenter._visible = true;
        this.applySelectorLayout(this._selectorPos);
    }
}