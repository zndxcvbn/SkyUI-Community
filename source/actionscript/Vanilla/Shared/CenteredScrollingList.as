class Shared.CenteredScrollingList extends Shared.BSScrollingList
{
  /* PUBLIC VARIABLES */

    var EntriesA;
    var GetClipByIndex;
    var SetEntryText;

    var _filterer;
    var bDisableInput;
    var bMouseDrivenNav;
    var bPointerHighlight;
    var bRecenterSelection;

    var border;
    var dispatchEvent;
    var doSetSelectedIndex;

    var fListHeight;
    var iDividerIndex;
    var iListItemsShown;
    var iMaxItemsShown;
    var iMaxScrollPosition;
    var iMaxTextLength;
    var iNumTopHalfEntries;
    var iNumUnfilteredItems;
    var iPlatform;
    var iScrollPosition;
    var iSelectedIndex;


  /* CONSTANTS */

    static var PLATFORM_PC = 0;


  /* PROPERTIES */

    public function get filterer() { return this._filterer; }

    public function set maxTextLength(aLength)
    {
        if (aLength > 3) this.iMaxTextLength = aLength;
    }

    public function get numUnfilteredItems() { return this.iNumUnfilteredItems; }
    public function get numTopHalfEntries() { return this.iNumTopHalfEntries; }
    public function set numTopHalfEntries(aiNum) { this.iNumTopHalfEntries = aiNum; }

    public function get centeredEntry()
    {
        var clip = this.GetClipByIndex(this.iNumTopHalfEntries);
        return (clip && clip.itemIndex != undefined) ? this.EntriesA[clip.itemIndex] : null;
    }


  /* INITIALIZATION */

    public function CenteredScrollingList()
    {
        super();

        this._filterer = new Shared.ListFilterer();
        this._filterer.addEventListener("filterChange", this, "onFilterChange");

        this.bRecenterSelection = false;
        this.bPointerHighlight = false;

        this.iMaxTextLength = 256;
        this.iDividerIndex = -1;
        this.iNumUnfilteredItems = 0;
    }


  /* PUBLIC FUNCTIONS */

    public function IsDivider(aEntry) { return aEntry.divider == true || aEntry.flag == 0; }

    public function RestoreScrollPosition(aiNewPosition, abRecenterSelection)
    {
        this.iScrollPosition = Math.max(0, Math.min(aiNewPosition, this.iMaxScrollPosition));
        this.bRecenterSelection = abRecenterSelection;
    }

    public function InvalidateData()
    {
        this.bPointerHighlight = false;

        this.filterer.filterArray = this.EntriesA;

        this.fListHeight = this.border._height;

        this.CalculateMaxScrollPosition();

        this.iScrollPosition = Math.min(this.iScrollPosition, this.iMaxScrollPosition);

        this.UpdateList();
    }

    public function UpdateList()
    {
        var baseY = this.GetClipByIndex(0)._y;
        var currentY = 0;

        var entryIdx = this.filterer.ClampIndex(0);
        var shouldRecenter = this._shouldRecenter();

        this._findLastDivider();

        this.iListItemsShown = 0;
        this.iNumUnfilteredItems = 0;

        if (shouldRecenter)
            this.iSelectedIndex = -1;

        var skipCount = Math.max(0, this.iScrollPosition - this.iNumTopHalfEntries);
        entryIdx = this._advanceFilterIndex(entryIdx, skipCount);

        var firstVisibleSlot = Math.max(0, this.iNumTopHalfEntries - this.iScrollPosition);

        for (var clipIdx = 0; clipIdx < this.iMaxItemsShown; clipIdx++)
        {
            var clip = this.GetClipByIndex(clipIdx);

            var isVisible = (clipIdx >= firstVisibleSlot) &&
                            (entryIdx != undefined) &&
                            (entryIdx < this.EntriesA.length);

            if (isVisible && currentY <= this.fListHeight)
            {
                this._renderEntry(clip, clipIdx, entryIdx, shouldRecenter);

                entryIdx = this.filterer.GetNextFilterMatch(entryIdx);

                this.iNumUnfilteredItems++;
                this.iListItemsShown++;
            }
            else
            {
                this._hideClip(clip);
            }

            clip._y = baseY + currentY;
            currentY += clip._height;
        }

        this._handleMouseSelection(shouldRecenter);

        this.bRecenterSelection = false;
    }

    public function SetEntry(aEntryClip, aEntryObject)
    {
        if (!aEntryClip) return;

        if (aEntryClip.textField != undefined)
            aEntryClip.textField.textColor = 0xFFFFFF;

        var isDivider = this.IsDivider(aEntryObject);
        aEntryClip.gotoAndStop(isDivider ? "Divider" : "Normal");

        this._applyAlpha(aEntryClip, aEntryObject);

        this.SetEntryText(aEntryClip, aEntryObject);
    }

    public function _moveSelection(direction, eventType)
    {
        this.bPointerHighlight = true;
        this.bMouseDrivenNav = false;

        var oldScroll = this.iScrollPosition;
        var newScroll = this.iScrollPosition + direction;

        this.iScrollPosition = Math.max(0, Math.min(this.iMaxScrollPosition, newScroll));

        if (oldScroll != this.iScrollPosition)
        {
            this.UpdateList();

            this.dispatchEvent({
                type: eventType,
                index: this.iSelectedIndex,
                scrollChanged: true
            });
        }
    }

    public function moveSelectionUp() { this._moveSelection(-1, "listMovedUp"); }
    public function moveSelectionDown() { this._moveSelection(1, "listMovedDown"); }

    //==================================================
    // Mouse
    //==================================================
    public function onMouseMove()
    {
        this._handleMouseInteraction();
    }

    public function onMouseDown()
    {
        if (this.bDisableInput) return;
        this._handleMouseInteraction();
    }

    public function onMouseWheel(delta)
    {
        if (this.bDisableInput) return;
        if (!this.hitTest(_root._xmouse, _root._ymouse, true)) return;

        this.bPointerHighlight = true;
        this.bMouseDrivenNav = true;

        var oldScroll = this.iScrollPosition;
        var oldSelectedIndex = this.iSelectedIndex;

        var direction = (delta > 0) ? -1 : 1;

        this.iScrollPosition = Math.max(0, Math.min(this.iMaxScrollPosition, this.iScrollPosition + direction));

        if (oldScroll != this.iScrollPosition)
        {
            this.UpdateList();

            if (this.iSelectedIndex != oldSelectedIndex && this.iSelectedIndex != -1)
            {
                this.dispatchEvent({
                type: "selectionChange",
                index: this.iSelectedIndex,
                keyboardOrMouse: 0
                });
            }
        }
    }

    public function GetItemUnderMouse()
    {
        for (var i = 0; i < this.iMaxItemsShown; i++)
        {
            var clip = this.GetClipByIndex(i);

            if (clip && clip._visible && clip.itemIndex != undefined && clip.hitTest(_root._xmouse, _root._ymouse, true))
                return clip;
        }
        return null;
    }

    //==================================================
    // Filter / scroll
    //==================================================
    public function CalculateMaxScrollPosition()
    {
        var count = 0;
        var idx = this.filterer.ClampIndex(0);

        while (idx != undefined)
        {
            count++;
            idx = this.filterer.GetNextFilterMatch(idx);
        }

        this.iMaxScrollPosition = Math.max(0, count - 1);
    }

    public function onFilterChange()
    {
        this.iSelectedIndex = this.filterer.ClampIndex(this.iSelectedIndex);

        this.CalculateMaxScrollPosition();
        this.UpdateList();
    }

    public function doSetSelectedIndex(aiNewIndex, aiKeyboardOrMouse)
    {
        if (this.bPointerHighlight && aiKeyboardOrMouse == 0) return;

        if (!this.bDisableSelection && aiNewIndex != this.iSelectedIndex)
        {
            this.iSelectedIndex = aiNewIndex;

            for (var i = 0; i < this.iMaxItemsShown; i++)
            {
                var clip = this.GetClipByIndex(i);
                if (clip && clip.itemIndex != undefined)
                this.SetEntry(clip, this.EntriesA[clip.itemIndex]);
            }

            this.dispatchEvent({
                type: "selectionChange",
                index: this.iSelectedIndex,
                keyboardOrMouse: aiKeyboardOrMouse
            });
        }
    }

    //==================================================
    // Press
    //==================================================
    public function onItemPress(aiKeyboardOrMouse)
    {
        if (aiKeyboardOrMouse != undefined)
        {
            super.onItemPress(aiKeyboardOrMouse);
            return;
        }

        var centerClip = this.GetClipByIndex(this.iNumTopHalfEntries);
        var centerIndex = centerClip ? centerClip.itemIndex : undefined;

        if (!this.bDisableInput && !this.bDisableSelection && centerIndex != undefined)
        {
            if (!this.bPointerHighlight || this.iSelectedIndex != centerIndex)
            {
                this.bPointerHighlight = true;
                this.bMouseDrivenNav = false;
                this.iSelectedIndex = centerIndex;

                this.UpdateList();
            }

            this.dispatchEvent({
                type: "itemPress",
                index: this.iSelectedIndex,
                entry: this.EntriesA[this.iSelectedIndex],
                keyboardOrMouse: aiKeyboardOrMouse
            });
        }
        else if (!this.bDisableInput)
        {
            this.dispatchEvent({type: "listPress"});
        }
    }

    /* @extension */
    public function setInteractive(abInteractive:Boolean)
    {
        this.bDisableInput = !abInteractive;
        this.disableSelection = !abInteractive;
    }


  /* PRIVATE FUNCTIONS */

    private function _shouldRecenter()
    {
        return (this.bRecenterSelection ||
                this.iPlatform != Shared.CenteredScrollingList.PLATFORM_PC ||
                this.bPointerHighlight) && !this.bNoSelectionMode;
    }
    
    private function _findLastDivider()
    {
        this.iDividerIndex = -1;

        for (var i = 0; i < this.EntriesA.length; i++)
        {
            if (this.IsDivider(this.EntriesA[i]))
                this.iDividerIndex = i;
        }
    }

    private function _advanceFilterIndex(startIndex, steps)
    {
        var idx = startIndex;

        for (var i = 0; i < steps && idx != undefined; i++)
            idx = this.filterer.GetNextFilterMatch(idx);

        return idx;
    }
    
    private function _renderEntry(clip, clipIdx, entryIdx, shouldRecenter)
    {
        var entry = this.EntriesA[entryIdx];

        clip.itemIndex = this.IsDivider(entry) ? undefined : entryIdx;
        clip.clipIndex = clipIdx;
        clip._visible = true;

        if (clipIdx == this.iNumTopHalfEntries && shouldRecenter)
            this.iSelectedIndex = entryIdx;

        this.SetEntry(clip, entry);
    }

    private function _hideClip(clip)
    {
        clip._visible = false;
        clip.itemIndex = undefined;
        clip.clipIndex = undefined;
    }

    private function _handleMouseSelection(shouldRecenter)
    {
        if (this.bMouseDrivenNav && !shouldRecenter && !this.bNoSelectionMode)
        {
            var hovered = this.GetItemUnderMouse();

            if (hovered != null)
                this.doSetSelectedIndex(hovered.itemIndex, 0);
        }
    }
    
    private function _applyAlpha(aEntryClip, aEntryObject)
    {
        var isSelected = (aEntryObject == this.EntriesA[this.iSelectedIndex]);

        if (this.bIsInactive)
            isSelected = false;

        if (this.iPlatform == Shared.CenteredScrollingList.PLATFORM_PC)
        {
            aEntryClip._alpha = isSelected ? 100 : 60;
            return;
        }

        var dist = Math.abs(aEntryClip.clipIndex - this.iNumTopHalfEntries);

        if (this.bIsInactive)
            aEntryClip._alpha = 60;
        else
            aEntryClip._alpha = (dist == 0) ? 100 : Math.max(20, 60 - dist * 10);
    }
    
    private function _handleMouseInteraction()
    {
        this.bMouseDrivenNav = true;
        this.bPointerHighlight = false;

        var item = this.GetItemUnderMouse();
        if (item)
            this.doSetSelectedIndex(item.itemIndex, 0);
    }
}
