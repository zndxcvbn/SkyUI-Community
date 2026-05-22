class skyui.components.list.ScrollingList extends skyui.components.list.BasicList
{
  /* CONSTANTS & CONFIGURATION */

    public var keyRepeatDelay: Number = 300;
    public var keyRepeatInterval: Number = 25;

    // Height reserved at the bottom of the list for the page navigator.
    private static var PAGER_RESERVE: Number = 30;


  /* PRIVATE VARIABLES */ 

    // This serves as the actual size of the list as its incremented during updating
    private var _listIndex: Number = 0;

    private var _curClipIndex: Number = -1;

    // The maximum allowed size. Actual size might be smaller if the list is not filled completely.
    private var _maxListIndex: Number;

    // Timers for fast key repetition
    private var _keyRepeatTimeout: Number;
    private var _keyRepeatInterval: Number;
    private var _heldNavDirection: Number = -1;

    // Flag that allows list Entry to disable their animation
    public var bDisableAnim: Boolean = false;
    public var lastSelectionAnimY: Number = -1;
    public var enableAnimation: Boolean = false;

    // Pagination: clickable page numbers below the list instead of a scrollbar.
    private var _paginationEnabled: Boolean = false;
    private var _pager: skyui.components.list.ListPager;
    private var _pagerAlign: Number = 0; // ListPager.ALIGN_LEFT


  /* STAGE ELEMENTS */

    public var scrollbar: MovieClip;

    public var scrollUpButton: MovieClip;
    public var scrollDownButton: MovieClip;


  /* PROPERTIES */

    public var entryHeight: Number = 28;

    public var scrollDelta: Number = 1;

    public var isPressOnMove: Boolean = false;

    private var _scrollPosition: Number = 0;

    public function get scrollPosition()
    {
        return this._scrollPosition;
    }

    public function set scrollPosition(a_newPosition: Number)
    {
        // In pagination mode the position snaps to whole pages.
        if (this._paginationEnabled && this._maxListIndex > 0)
            a_newPosition = Math.floor(a_newPosition / this._maxListIndex) * this._maxListIndex;

        if (a_newPosition == this._scrollPosition || a_newPosition < 0 || a_newPosition > this._maxScrollPosition)
            return;

        if (this.scrollbar != undefined && !this._paginationEnabled) {
            this.scrollbar.position = a_newPosition;
        } else {
            this.bDisableAnim = true;
            this.updateScrollPosition(a_newPosition);
            this.bDisableAnim = false;
        }
    }

    private var _maxScrollPosition: Number = 0;

    public function get maxScrollPosition()
    {
        return this._maxScrollPosition;
    }

    private var _listHeight: Number;

    public function get listHeight()
    {
        return this._listHeight;
    }

    public function set listHeight(a_height: Number)
    {
        this._listHeight = this.background._height = a_height;
        this.recalcMaxListIndex();

        if (this.scrollbar != undefined)
            this.scrollbar.height = this._listHeight;

        if (this._pager != undefined)
            this.positionPager();
    }


  /* INITIALIZATION */

    public function ScrollingList()
    {
        super();
        
        this._listHeight = this.background._height - this.topBorder - this.bottomBorder;

        this.recalcMaxListIndex();
    }
    
    public function applyScrollConfig(a_config: Object)
    {
        if (a_config == undefined) return;

        if (a_config.keyRepeatDelay != undefined)
            this.keyRepeatDelay = Math.max(0, Number(a_config.keyRepeatDelay));
            
        if (a_config.keyRepeatInterval != undefined)
            this.keyRepeatInterval = Math.max(1, Number(a_config.keyRepeatInterval));
    }


  /* PUBLIC FUNCTIONS */

    // @override MovieClip
    public function onLoad()
    {
        if (this.scrollbar != undefined) {
            this.scrollbar.position = 0;
            this.scrollbar.addEventListener("scroll", this, "onScroll");
            this.scrollbar._y = this.background._y + this.topBorder;
            this.scrollbar.height = this._listHeight;
        }
    }

    // @override BasicList
    public function setPlatform(a_platform: Number, a_bPS3Switch: Boolean)
    {
        super.setPlatform(a_platform,a_bPS3Switch);
    }

    public function onUnload()
    {
        this.stopKeyRepeat();
    }

    // @GFx
    public function handleInput(details: InputDetails, pathToFocus: Array)
    {
        if (this.disableInput)
            return false;

        // That makes no sense, does it?
        var entry = this.getClipByIndex(this.selectedIndex);
        var bHandled = entry != undefined && entry.handleInput != undefined && entry.handleInput(details, pathToFocus.slice(1));
        if (bHandled)
            return true;

        var nav = details.navEquivalent;
        var isNavKey = (nav == gfx.ui.NavigationCode.UP || nav == gfx.ui.NavigationCode.DOWN || 
                        nav == gfx.ui.NavigationCode.PAGE_UP || nav == gfx.ui.NavigationCode.PAGE_DOWN);

        if (isNavKey) {
            if (details.value == "keyDown") {
                this.executeNavDirection(nav);
                this.startKeyRepeat(nav);
                return true;
            }
            if (details.value == "keyUp") {
                if (this._heldNavDirection == nav) 
                    this.stopKeyRepeat();
                return true;
            }
            if (details.value == "keyHold") {
                return true; 
            }
        }

        if (Shared.GlobalFunc.IsKeyPressed(details)) {
            if (!this.disableSelection && details.navEquivalent == gfx.ui.NavigationCode.ENTER) {
                // TODO: See gfx.managers.InputDelegate.inputToNav(); stop it from converting numberpad -> navEquivalent
                // Fix for numberpad 0 being handled as ENTER
                if (details.code == 96 && this._platform == skyui.components.list.BasicList.PLATFORM_PC)
                    return false;

                this.onItemPress();
                return true;
            }
        }
        return false;
    }

    // @override BasicList
    public function UpdateList()
    {
        if (this._bSuspended) {
            this._bRequestUpdate = true;
            return;
        }
        
        // Prepare clips
        this.setClipCount(this._maxListIndex);
        
        var xStart = this.background._x + this.leftBorder;
        var yStart = this.background._y + this.topBorder;
        var h = 0;

        // Clear clipIndex for everything before the selected list portion
        for (var i = 0; i < this.getListEnumSize() && i < this._scrollPosition ; i++)
            this.getListEnumEntry(i).clipIndex = undefined;

        this._listIndex = 0;
        
        // Display the selected list portion of the list
        for (var i = this._scrollPosition; i < this.getListEnumSize() && this._listIndex < this._maxListIndex; i++) {
            var entryClip = this.getClipByIndex(this._listIndex);
            var entryItem = this.getListEnumEntry(i);

            entryClip.itemIndex = entryItem.itemIndex;
            entryItem.clipIndex = this._listIndex;
            
            entryClip.setEntry(entryItem, this.listState);

            entryClip._x = xStart;
            entryClip._y = yStart + h;
            entryClip._visible = true;

            h = h + this.entryHeight;

            ++this._listIndex;
        }
        
        // Clear clipIndex for everything after the selected list portion
        for (var i = this._scrollPosition + this._listIndex; i < this.getListEnumSize(); i++)
            this.getListEnumEntry(i).clipIndex = undefined;
            
        // Select entry under the cursor for mouse-driven navigation
        if (this.isMouseDrivenNav) {
            for (var j = 0; j < this._listIndex; j++) {
                var clip = this.getClipByIndex(j);
                if (clip != undefined && clip._visible && clip.itemIndex != undefined && clip.hitTest(_root._xmouse, _root._ymouse, true)) {
                    this.doSetSelectedIndex(clip.itemIndex, skyui.components.list.BasicList.SELECT_MOUSE);
                    break;
                }
            }
        }
                    
        if (this.scrollUpButton != undefined)
            this.scrollUpButton._visible = !this._paginationEnabled && this._scrollPosition > 0;
        if (this.scrollDownButton != undefined)
            this.scrollDownButton._visible = !this._paginationEnabled && this._scrollPosition < this._maxScrollPosition;

        if (this._paginationEnabled) {
            this.ensurePager();
            this._pager.update(this.pageCount, this.currentPage);
        }
    }

    // @override BasicList
    public function InvalidateData()
    {
        if (this._bSuspended) {
            this._bRequestInvalidate = true;
            return;
        }
        
        for (var i = 0; i < this._entryList.length; i++) {
            this._entryList[i].itemIndex = i;
            this._entryList[i].clipIndex = undefined;
        }
            
        for (var i = 0; i < this._dataProcessors.length; i++)
            this._dataProcessors[i].processList(this);
        
        this.listEnumeration.invalidate();

        if (this._selectedIndex >= this.listEnumeration.size())
            this._selectedIndex = this.listEnumeration.size() - 1;
            
        if (this.listEnumeration.lookupEnumIndex(this._selectedIndex) == null)
            this._selectedIndex = -1;
        
        this.calculateMaxScrollPosition();		
        
        this.bDisableAnim = true;
        this.UpdateList();
        
        // Restore selection
        if (this._curClipIndex != undefined && this._curClipIndex != -1 && this._listIndex > 0) {
            if (this._curClipIndex >= this._listIndex)
                this._curClipIndex = this._listIndex - 1;
            
            var entryClip = this.getClipByIndex(this._curClipIndex);
            this.doSetSelectedIndex(entryClip.itemIndex, skyui.components.list.BasicList.SELECT_MOUSE);
        }
        
        this.bDisableAnim = false;
        
        if (this.onInvalidate)
            this.onInvalidate();
    }

    public function moveSelectionUp(a_bScrollPage: Boolean)
    {
        if (!this.disableSelection && !a_bScrollPage) {
            if (this._selectedIndex == -1) {
                this.selectDefaultIndex(false);
            } else if (this.getSelectedListEnumIndex() >= this.scrollDelta) {
                this.doSetSelectedIndex(this.getListEnumRelativeIndex(-this.scrollDelta), skyui.components.list.BasicList.SELECT_KEYBOARD);
                this.isMouseDrivenNav = false;
                if (this.isPressOnMove) this.onItemPress();
            } else if (this.getListEnumSize() > 0) {
                this.doSetSelectedIndex(this.getListEnumEntry(this.getListEnumSize() - 1).itemIndex, skyui.components.list.BasicList.SELECT_KEYBOARD);
                this.isMouseDrivenNav = false;
            }
        } else if (a_bScrollPage) {
            var t = this.scrollPosition - this._listIndex;
            this.scrollPosition = t > 0 ? t : 0;
            this.doSetSelectedIndex(-1, skyui.components.list.BasicList.SELECT_MOUSE);
        } else {
            this.scrollPosition = this.scrollPosition - this.scrollDelta;
        }
    }

    public function moveSelectionDown(a_bScrollPage: Boolean)
    {
        if (!this.disableSelection && !a_bScrollPage) {
            if (this._selectedIndex == -1) {
                this.selectDefaultIndex(true);
            } else if (this.getSelectedListEnumIndex() < this.getListEnumSize() - this.scrollDelta) {
                this.doSetSelectedIndex(this.getListEnumRelativeIndex(this.scrollDelta), skyui.components.list.BasicList.SELECT_KEYBOARD);
                this.isMouseDrivenNav = false;
                if (this.isPressOnMove) this.onItemPress();
            } else if (this.getListEnumSize() > 0) {
                this.doSetSelectedIndex(this.getListEnumEntry(0).itemIndex, skyui.components.list.BasicList.SELECT_KEYBOARD);
                this.isMouseDrivenNav = false;
            }
        } else if (a_bScrollPage) {
            var t = this.scrollPosition + this._listIndex;
            this.scrollPosition = t < this._maxScrollPosition ? t : this._maxScrollPosition;
            this.doSetSelectedIndex(-1, skyui.components.list.BasicList.SELECT_MOUSE);
        } else {
            this.scrollPosition = this.scrollPosition + this.scrollDelta;
        }
    }

    public function selectDefaultIndex(a_bTop: Boolean)
    {
        if (this._listIndex <= 0)
            return;
            
        if (a_bTop) {
            var firstClip = this.getClipByIndex(0);
            if (firstClip.itemIndex != undefined)
                this.doSetSelectedIndex(firstClip.itemIndex, skyui.components.list.BasicList.SELECT_KEYBOARD);
        } else {
            var lastClip = this.getClipByIndex(this._listIndex - 1);
            if (lastClip.itemIndex != undefined)
                this.doSetSelectedIndex(lastClip.itemIndex, skyui.components.list.BasicList.SELECT_KEYBOARD);
        }
    }


  /* PAGINATION */

    public function get paginationEnabled()
    {
        return this._paginationEnabled;
    }

    public function set paginationEnabled(a_enabled: Boolean)
    {
        this._paginationEnabled = a_enabled;

        if (a_enabled)
            this.ensurePager();

        if (this._pager != undefined)
            this._pager.setVisible(a_enabled);

        // Row count depends on the mode (pagination reserves a strip for the pager).
        this.recalcMaxListIndex();
        this.updateScrollbar();
        this.requestUpdate();
    }

    // Number of rows on a page (the visible window).
    public function get pageSize()
    {
        return this._maxListIndex;
    }

    public function get pageCount()
    {
        if (this._maxListIndex <= 0 || this.listEnumeration == undefined)
            return 1;

        var n = Math.ceil(this.getListEnumSize() / this._maxListIndex);
        return (n < 1) ? 1 : n;
    }

    // Zero-based index of the page currently shown.
    public function get currentPage()
    {
        if (this._maxListIndex <= 0)
            return 0;

        return Math.floor(this._scrollPosition / this._maxListIndex);
    }

    public function goToPage(a_page: Number)
    {
        this.scrollPosition = a_page * this._maxListIndex;
    }

    // (Re)computes the visible row count. In pagination mode a strip at the
    // bottom of the list is reserved for the page navigator.
    private function recalcMaxListIndex()
    {
        var h = this._listHeight;

        if (this._paginationEnabled)
            h -= skyui.components.list.ScrollingList.PAGER_RESERVE;

        this._maxListIndex = Math.floor((h / this.entryHeight) + 0.05);
    }

    // Sets the page-number alignment ("left", "center" or "right").
    public function setPagerAlign(a_align: String)
    {
        if (a_align == "center")
            this._pagerAlign = skyui.components.list.ListPager.ALIGN_CENTER;
        else if (a_align == "right")
            this._pagerAlign = skyui.components.list.ListPager.ALIGN_RIGHT;
        else
            this._pagerAlign = skyui.components.list.ListPager.ALIGN_LEFT;

        if (this._pager != undefined)
            this._pager.setAlign(this._pagerAlign);
    }

    // Creates the page navigator on first use.
    private function ensurePager()
    {
        if (this._pager != undefined)
            return;

        var holder = this.createEmptyMovieClip("pagerHolder", this.getNextHighestDepth());
        this._pager = new skyui.components.list.ListPager(holder, this);
        this._pager.setAlign(this._pagerAlign);
        this.positionPager();
    }

    private function positionPager()
    {
        if (this._pager == undefined)
            return;

        var px = this.background._x + this.leftBorder;
        var bottomY = this.background._y + this.topBorder + this._listHeight;
        var w = this.background._width - this.leftBorder - this.rightBorder;
        this._pager.setArea(px, bottomY, w);
    }


  /* PRIVATE FUNCTIONS */

    private function executeNavDirection(navCode: Number)
    {
        if (navCode == gfx.ui.NavigationCode.UP || navCode == gfx.ui.NavigationCode.PAGE_UP) {
            this.moveSelectionUp(navCode == gfx.ui.NavigationCode.PAGE_UP);
        } else if (navCode == gfx.ui.NavigationCode.DOWN || navCode == gfx.ui.NavigationCode.PAGE_DOWN) {
            this.moveSelectionDown(navCode == gfx.ui.NavigationCode.PAGE_DOWN);
        }
    }

    private function startKeyRepeat(navCode: Number)
    {
        this.stopKeyRepeat();  
        this._heldNavDirection = navCode;
        this._keyRepeatTimeout = setInterval(this, "onKeyRepeatStart", this.keyRepeatDelay);
    }

    private function onKeyRepeatStart()
    {
        clearInterval(this._keyRepeatTimeout);
        delete this._keyRepeatTimeout;
        this._keyRepeatInterval = setInterval(this, "onKeyRepeatTick", this.keyRepeatInterval);
    }

    private function onKeyRepeatTick()
    {
        if (this._heldNavDirection == -1) {
            this.stopKeyRepeat();
            return;
        }
        this.executeNavDirection(this._heldNavDirection);
    }

    private function stopKeyRepeat()
    {
        clearInterval(this._keyRepeatTimeout);
        delete this._keyRepeatTimeout;
        clearInterval(this._keyRepeatInterval);
        delete this._keyRepeatInterval;
        this._heldNavDirection = -1;
    }

    // @GFx
    private function onMouseWheel(a_delta: Number)
    {
        if (this.disableInput)
            return;
        
        if (this.hitTest(_root._xmouse, _root._ymouse, true)) 
        {
            this.isMouseDrivenNav = true;
            if (a_delta < 0)      this.scrollPosition += this.scrollDelta;
            else if (a_delta > 0) this.scrollPosition -= this.scrollDelta;
        }
    }

    private function onScroll(event: Object)
    {
        this.bDisableAnim = true;
        try {
            this.updateScrollPosition(Math.floor(event.position + 0.5));
        } finally {
            this.bDisableAnim = false;
        }
    }

    // @override BasicList
    private function doSetSelectedIndex(a_newIndex: Number, a_keyboardOrMouse: Number)
    {
        if (this._selectedIndex == -1 && a_newIndex != -1) {
            this.lastSelectionAnimY = -1;
        }
        
        if (this.disableSelection || a_newIndex == this._selectedIndex)
            return;
            
        // Selection is not contained in current entry enumeration, ignore
        if (a_newIndex != -1 && this.getListEnumIndex(a_newIndex) == undefined)
            return;
            
        var oldEntry = this.selectedEntry;
        
        this._selectedIndex = a_newIndex;

        // Old entry was mapped to a clip? Then clear with setEntry now that selectedIndex has been updated
        if (oldEntry.clipIndex != undefined) {
            var clip = this.getClipByIndex(oldEntry.clipIndex);
            clip.setEntry(oldEntry, this.listState);
        }
            
            
        // Select valid entry
        if (this._selectedIndex != -1) {

            var enumIndex = this.getSelectedListEnumIndex();

            if (this._paginationEnabled && this._maxListIndex > 0) {
                // Jump to the page that holds the selected entry.
                var pagePos = Math.floor(enumIndex / this._maxListIndex) * this._maxListIndex;
                if (pagePos != this._scrollPosition) {
                    this.scrollPosition = pagePos;
                } else {
                    var pclip = this.getClipByIndex(this.selectedEntry.clipIndex);
                    pclip.setEntry(this.selectedEntry, this.listState);
                }

            // New entry before visible portion, move scroll window up
            } else if (enumIndex < this._scrollPosition) {
                this.scrollPosition = enumIndex;

            // New entry below visible portion, move scroll window down
            } else if (enumIndex >= this._scrollPosition + this._listIndex) {
                this.scrollPosition = Math.min(enumIndex - this._listIndex + this.scrollDelta, this._maxScrollPosition);

            // No need to change the scroll window, just select new entry
            } else {
                var clip = this.getClipByIndex(this.selectedEntry.clipIndex);
                clip.setEntry(this.selectedEntry, this.listState);
            }

            this._curClipIndex = this.selectedEntry.clipIndex;
            
        // Unselect
        } else {
            this._curClipIndex = -1;
        }

        this.dispatchEvent({type:"selectionChange", index:this._selectedIndex, keyboardOrMouse:a_keyboardOrMouse});
    }

    private function calculateMaxScrollPosition()
    {
        if (this._paginationEnabled && this._maxListIndex > 0) {
            this._maxScrollPosition = (this.pageCount - 1) * this._maxListIndex;
        } else {
            var t = this.getListEnumSize() - this._maxListIndex;
            this._maxScrollPosition = (t > 0) ? t : 0;
        }

        this.updateScrollbar();

        if (this._scrollPosition > this._maxScrollPosition)
            this.scrollPosition = this._maxScrollPosition;
    }

    private function updateScrollPosition(a_position: Number)
    {
        this._scrollPosition = a_position;
        this.UpdateList();
    }

    private function updateScrollbar()
    {
        if (this.scrollbar != undefined) {
            this.scrollbar._visible = !this._paginationEnabled && this._maxScrollPosition > 0;
            if (!this._paginationEnabled)
                this.scrollbar.setScrollProperties(this._maxListIndex, 0, this._maxScrollPosition);
        }
    }

    // @override BasicList
    private function getClipByIndex(a_index: Number)
    {
        if (a_index < 0 || a_index >= this._maxListIndex)
            return undefined;

        return this._entryClipManager.getClip(a_index);
    }
}
