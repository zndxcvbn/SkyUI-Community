class Shared.BSScrollingList extends MovieClip
{
  /* PUBLIC VARIABLES */

    public var EntriesA;
    public var ListScrollbar;
    public var ScrollDown;
    public var ScrollUp;
    public var bDisableInput;
    public var bDisableSelection;
    public var bListAnimating;
    public var bMouseDrivenNav;
    public var border;
    public var dispatchEvent;
    public var fListHeight;
    public var iListItemsShown;
    public var iMaxItemsShown;
    public var iMaxScrollPosition;
    public var iPlatform;
    public var iScrollPosition;
    public var iScrollbarDrawTimerID;
    public var iSelectedIndex;
    public var iTextOption;
    public var itemIndex;
    public var onMousePress;
    public var scrollbar;

    public var bIsInactive = false;
    public var bNoSelectionMode = false;
    public var bAllowUpToTabs = false;


  /* CONSTANTS */

    private static var TEXT_OPTION_NONE = 0;
    private static var TEXT_OPTION_SHRINK_TO_FIT = 1;
    private static var TEXT_OPTION_MULTILINE = 2;


  /* PROPERTIES */

    public function get selectedIndex() { return this.iSelectedIndex; }
    public function set selectedIndex(aiNewIndex) { this.doSetSelectedIndex(aiNewIndex); }

    public function get length() { return this.EntriesA.length; }
    public function get selectedEntry() { return this.EntriesA[this.iSelectedIndex]; }

    public function get listAnimating() { return this.bListAnimating; }
    public function set listAnimating(abFlag) { this.bListAnimating = abFlag; }

    public function get entryList() { return this.EntriesA; }
    public function set entryList(anewArray) { this.EntriesA = anewArray; }

    public function get disableSelection() { return this.bDisableSelection; }
    public function set disableSelection(abFlag) { this.bDisableSelection = abFlag; }

    public function get disableInput() { return this.bDisableInput; }
    public function set disableInput(abFlag) { this.bDisableInput = abFlag; }

    public function get maxEntries() { return this.iMaxItemsShown; }

    public function get textOption() { return this.iTextOption; }
    public function set textOption(strNewOption)
    {
        switch (strNewOption)
        {
            case "Shrink To Fit":
                this.iTextOption = Shared.BSScrollingList.TEXT_OPTION_SHRINK_TO_FIT;
                break;
            case "Multi-Line":
                this.iTextOption = Shared.BSScrollingList.TEXT_OPTION_MULTILINE;
                break;
            default:
                this.iTextOption = Shared.BSScrollingList.TEXT_OPTION_NONE;
        }
    }

    public function get scrollPosition() { return this.iScrollPosition; }
    public function get maxScrollPosition() { return this.iMaxScrollPosition; }

    public function set scrollPosition(aiNewPosition)
    {
        if (aiNewPosition == this.iScrollPosition) return;
        if (aiNewPosition < 0 || aiNewPosition > this.iMaxScrollPosition) return;

        if (this.ListScrollbar != undefined)
            this.ListScrollbar.position = aiNewPosition;
        else
            this.updateScrollPosition(aiNewPosition);
    }


  /* INITIALIZATION */

    public function BSScrollingList()
    {
        super();

        this.EntriesA = new Array();
        this.bDisableSelection = false;
        this.bDisableInput = false;
        this.bMouseDrivenNav = false;

        gfx.events.EventDispatcher.initialize(this);
        Mouse.addListener(this);

        this.iSelectedIndex = -1;
        this.iScrollPosition = 0;
        this.iMaxScrollPosition = 0;
        this.iListItemsShown = 0;
        this.iPlatform = 1;
        this.fListHeight = this.border._height;

        this.ListScrollbar = this.scrollbar;
        this.iMaxItemsShown = 0;

        this._initEntryClips();
    }

    public function onLoad()
    {
        if (this.ListScrollbar != undefined)
        {
            this.ListScrollbar.position = 0;
            this.ListScrollbar.addEventListener("scroll", this, "onScroll");
        }
    }


  /* PUBLIC FUNCTIONS */

    public function ClearList()
    {
        this.EntriesA.splice(0, this.EntriesA.length);
    }

    public function GetClipByIndex(aiIndex)
    {
        return this["Entry" + aiIndex];
    }

    public function handleInput(details, pathToFocus)
    {
        if (this.bDisableInput) return false;

        var handled = false;
        var clip = this.GetClipByIndex(this.selectedIndex - this.scrollPosition);

        if (clip != undefined && clip.handleInput != undefined)
            handled = clip.handleInput(details, pathToFocus.slice(1));

        if (!handled && Shared.GlobalFunc.IsKeyPressed(details))
            handled = this._handleNavigation(details);

        return handled;
    }

    public function onMouseWheel(delta)
    {
        if (this.bDisableInput) return;

        if (this.hitTest(_root._xmouse, _root._ymouse, true))
        {
            this.doSetSelectedIndex(-1, 0);

            if (delta < 0) this.scrollPosition += 1;
            else if (delta > 0) this.scrollPosition -= 1;
        }
    }

    public function doSetSelectedIndex(aiNewIndex, aiKeyboardOrMouse)
    {
        if (this.bDisableSelection || aiNewIndex == this.iSelectedIndex) return;

        var prevIndex = this.iSelectedIndex;
        this.iSelectedIndex = aiNewIndex;

        if (prevIndex != -1)
            this.SetEntry(this.GetClipByIndex(this.EntriesA[prevIndex].clipIndex), this.EntriesA[prevIndex]);
        
        if (this.iSelectedIndex != -1)
            this._ensureSelectionVisible();

        this.dispatchEvent({
            type: "selectionChange",
            index: this.iSelectedIndex,
            keyboardOrMouse: aiKeyboardOrMouse
        });
    }

    function updateScrollPosition(aiPosition)
    {
        this.iScrollPosition = aiPosition;
        this.UpdateList();
    }

    function UpdateList()
    {
        var baseY = this.GetClipByIndex(0)._y;
        var offsetY = 0;
        var index = this.iScrollPosition;

        this._clearHiddenEntries();

        this.iListItemsShown = 0;

        while (index < this.EntriesA.length &&
                this.iListItemsShown < this.iMaxItemsShown &&
                offsetY <= this.fListHeight)
        {
            var clip = this.GetClipByIndex(this.iListItemsShown);
            var entry = this.EntriesA[index];

            this.SetEntry(clip, entry);

            entry.clipIndex = this.iListItemsShown;
            clip.itemIndex = index;
            clip._y = baseY + offsetY;
            clip._visible = true;

            offsetY += clip._height;

            if (offsetY <= this.fListHeight)
                this.iListItemsShown++;

            index++;
        }

        this._hideUnusedClips();
        this._updateScrollIndicators();
    }

    public function InvalidateData()
    {
        var oldMax = this.iMaxScrollPosition;

        this.fListHeight = this.border._height;
        this.CalculateMaxScrollPosition();

        if (this.ListScrollbar != undefined)
        {
            if (oldMax != this.iMaxScrollPosition)
            {
                this.ListScrollbar._visible = false;
                this.ListScrollbar.setScrollProperties(this.iMaxItemsShown, 0, this.iMaxScrollPosition);

                if (this.iScrollbarDrawTimerID != undefined)
                    clearInterval(this.iScrollbarDrawTimerID);

                this.iScrollbarDrawTimerID = setInterval(this, "SetScrollbarVisibility", 50);
            }
            else
            {
                this.SetScrollbarVisibility();
            }
        }

        if (this.iSelectedIndex >= this.EntriesA.length)
            this.iSelectedIndex = this.EntriesA.length - 1;

        if (this.iScrollPosition > this.iMaxScrollPosition)
            this.iScrollPosition = this.iMaxScrollPosition;

        this.UpdateList();
    }

    public function SetScrollbarVisibility()
    {
        clearInterval(this.iScrollbarDrawTimerID);
        this.iScrollbarDrawTimerID = undefined;

        this.ListScrollbar._visible = this.iMaxScrollPosition > 0;
    }

    public function CalculateMaxScrollPosition()
    {
        var height = 0;
        var index = this.EntriesA.length - 1;

        while (index >= 0 && height <= this.fListHeight)
        {
            height += this.GetEntryHeight(index);

            if (height <= this.fListHeight)
                index--;
        }

        this.iMaxScrollPosition = index + 1;
    }

    public function GetEntryHeight(aiEntryIndex)
    {
        var clip = this.GetClipByIndex(0);
        this.SetEntry(clip, this.EntriesA[aiEntryIndex]);
        return clip._height;
    }

    public function moveSelectionUp()
    {
        if (this.EntriesA.length == 1) return;

        if (!this.bDisableSelection && this.selectedIndex > 0)
            this.selectedIndex -= 1;
        else
            this.scrollPosition -= 1;
    }

    public function moveSelectionDown()
    {
        if (this.EntriesA.length == 1) return;

        if (!this.bDisableSelection && (this.selectedIndex < this.EntriesA.length - 1))
            this.selectedIndex += 1;
        else
            this.scrollPosition += 1;
    }

    public function onItemPress(aiKeyboardOrMouse)
    {
        if (!this.bDisableInput && !this.bDisableSelection && this.iSelectedIndex != -1)
        {
            this.dispatchEvent({
                type: "itemPress",
                index: this.iSelectedIndex,
                entry: this.EntriesA[this.iSelectedIndex],
                keyboardOrMouse: aiKeyboardOrMouse
            });
        }
        else
        {
            this.dispatchEvent({type: "listPress"});
        }
    }

    public function onItemPressAux(aiKeyboardOrMouse, aiButtonIndex)
    {
        if (!this.bDisableInput && !this.bDisableSelection &&
            this.iSelectedIndex != -1 && aiButtonIndex == 1)
        {
            this.dispatchEvent({
                type: "itemPressAux",
                index: this.iSelectedIndex,
                entry: this.EntriesA[this.iSelectedIndex],
                keyboardOrMouse: aiKeyboardOrMouse
            });
        }
    }

    public function SetEntry(aEntryClip, aEntryObject)
    {
        if (aEntryClip == undefined) return;

        aEntryClip.gotoAndStop(aEntryObject == this.selectedEntry ? "Selected" : "Normal");
        this.SetEntryText(aEntryClip, aEntryObject);
    }

    public function SetEntryText(aEntryClip, aEntryObject)
    {
        if (aEntryClip.textField == undefined) return;

        if (this.textOption == Shared.BSScrollingList.TEXT_OPTION_SHRINK_TO_FIT)
            aEntryClip.textField.textAutoSize = "shrink";
        else if (this.textOption == Shared.BSScrollingList.TEXT_OPTION_MULTILINE)
            aEntryClip.textField.verticalAutoSize = "top";

        aEntryClip.textField.SetText(aEntryObject.text != undefined ? aEntryObject.text : " ");

        if (aEntryObject.enabled != undefined)
            aEntryClip.textField.textColor = aEntryObject.enabled != false ? 0xFFFFFF : 0x606060;

        if (aEntryObject.disabled != undefined)
            aEntryClip.textField.textColor = aEntryObject.disabled != true ? 0xFFFFFF : 0x606060;
    }


    public function SetPlatform(aiPlatform, abPS3Switch)
    {
        this.iPlatform = aiPlatform;
        this.bMouseDrivenNav = this.iPlatform == 0;
    }

    public function onScroll(event)
    {
        this.updateScrollPosition(Math.floor(event.position + 0.5));
    }


  /* PRIVATE FUNCTIONS */

    private function _initEntryClips()
    {
        var clip = this.GetClipByIndex(this.iMaxItemsShown);

        while (clip != undefined)
        {
            clip.clipIndex = this.iMaxItemsShown;

            clip.onRollOver = function()
            {
                if (!this._parent.listAnimating && !this._parent.bDisableInput && this.itemIndex != undefined)
                {
                    this._parent.doSetSelectedIndex(this.itemIndex, 0);
                    this._parent.bMouseDrivenNav = true;
                }
            };

            clip.onPress = function(aiMouseIndex, aiKeyboardOrMouse)
            {
                if (this.itemIndex != undefined)
                {
                    this._parent.onItemPress(aiKeyboardOrMouse);

                    if (!this._parent.bDisableInput && this.onMousePress != undefined)
                        this.onMousePress();
                }
            };

            clip.onPressAux = function(aiMouseIndex, aiKeyboardOrMouse, aiButtonIndex)
            {
                if (this.itemIndex != undefined)
                    this._parent.onItemPressAux(aiKeyboardOrMouse, aiButtonIndex);
            };

            clip = this.GetClipByIndex(++this.iMaxItemsShown);
        }
    }

    private function _handleNavigation(details)
    {
        if (details.navEquivalent == gfx.ui.NavigationCode.UP)
        {
            if (this._isAtTop())
                return this.bAllowUpToTabs === true ? false : true;

            this.moveSelectionUp();
            return true;
        }

        if (details.navEquivalent == gfx.ui.NavigationCode.DOWN)
        {
            this.moveSelectionDown();
            return true;
        }

        if (!this.bDisableSelection && details.navEquivalent == gfx.ui.NavigationCode.ENTER)
        {
            this.onItemPress();
            return true;
        }

        return false;
    }

    private function _isAtTop()
    {
        if (this.iNumTopHalfEntries != undefined)
            return this.iScrollPosition <= 0;
        
        if (this.selectedIndex == -1)
            return this.iScrollPosition <= 0;

        return this.selectedIndex <= 0;
    }
    
    private function _ensureSelectionVisible()
    {
        if (this.iPlatform == 0)
        {
            this._updateSelectedEntryVisual();
            return;
        }

        if (this.iSelectedIndex < this.iScrollPosition)
        {
            this.scrollPosition = this.iSelectedIndex;
        }
        else if (this.iSelectedIndex >= this.iScrollPosition + this.iListItemsShown)
        {
            this.scrollPosition = Math.min(
                this.iSelectedIndex - this.iListItemsShown + 1,
                this.iMaxScrollPosition
            );
        }
        else
        {
            this._updateSelectedEntryVisual();
        }
    }

    private function _updateSelectedEntryVisual()
    {
        this.SetEntry(
            this.GetClipByIndex(this.EntriesA[this.iSelectedIndex].clipIndex),
            this.EntriesA[this.iSelectedIndex]
        );
    }

    private function _clearHiddenEntries()
    {
        for (var i = 0; i < this.iScrollPosition; i++)
            this.EntriesA[i].clipIndex = undefined;
    }

    private function _hideUnusedClips()
    {
        for (var i = this.iListItemsShown; i < this.iMaxItemsShown; i++)
            this.GetClipByIndex(i)._visible = false;
    }

    private function _updateScrollIndicators()
    {
        if (this.ScrollUp != undefined)
            this.ScrollUp._visible = this.scrollPosition > 0;

        if (this.ScrollDown != undefined)
            this.ScrollDown._visible = this.scrollPosition < this.iMaxScrollPosition;
    }
}
