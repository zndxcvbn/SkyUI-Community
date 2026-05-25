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

    // Bookkeeping for the trailing-cleanup pass in UpdateList: clips with
    // index in [_listIndex, _prevListIndex) were visible last call but aren't
    // this call, so they need to be hidden. EntryClipManager no longer does a
    // universal reset every UpdateList, so this is the per-frame trim.
    private var _prevListIndex: Number = 0;

    // Bumped by subclasses (TabularList.onLayoutChange) when the visual
    // structure changes -- e.g. column count differs between categories. The
    // display loop's skip check compares per-clip vs current; mismatch forces
    // re-render so a clip can update its layout (column widths, hidden cols).
    public var _layoutVersion: Number = 0;

    // Snapshot of state at the end of the last UpdateList. If nothing tracked
    // here has moved, UpdateList can skip its whole body (everything visible
    // would render identically).
    private var _lastUpdateEnumVersion: Number = -1;
    private var _lastUpdateScrollPos: Number = -1;
    private var _lastUpdateSelIdx: Number = -2;  // -1 is a valid "no selection"
    private var _lastUpdateLayoutVer: Number = -1;

    // Single-token fast path for UpdateList early-return. Bumped at each
    // state-change site (scroll, selection, layout, filter/data invalidation).
    // Fast-path compare = 1 read + 1 compare (vs 10+4 of the 4-field snapshot).
    // The 4-field snapshot above is kept as a slow-path fallback -- if any
    // bump site is missed, the snapshot still catches state changes correctly,
    // we just lose the fast skip for that one call.
    public var _updateToken: Number = 0;
    private var _lastUpdateToken: Number = -1;

    // Last seen _entryList.length -- one of two signals that the game may have
    // reshuffled entry positions and we need to re-anchor itemIndex. -1 forces
    // the first call to run idxReset (cold path).
    private var _lastEntryCount: Number = -1;

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

        // Fast path: single-token compare. State-change sites bump
        // _updateToken; if it hasn't moved, nothing tracked changed and the
        // rendered output would be identical to last call.
        if (this._updateToken == this._lastUpdateToken)
            return;

        // Slow-path fallback: the 4-field snapshot. If a bump site was missed
        // OR a write churned the token without actually changing state, this
        // check still skips correctly. enumVer is undefined on BasicEnumeration;
        // the != check still works (sameState false on first call, runs
        // UpdateList, then snapshots).
        var enumVer = this.listEnumeration._version;
        if (enumVer == this._lastUpdateEnumVersion
            && this._scrollPosition == this._lastUpdateScrollPos
            && this._selectedIndex == this._lastUpdateSelIdx
            && this._layoutVersion == this._lastUpdateLayoutVer) {
            // State really is unchanged; sync token so the fast path catches
            // the next call.
            this._lastUpdateToken = this._updateToken;
            return;
        }

        // Prepare clips
        this.setClipCount(this._maxListIndex);

        var xStart = this.background._x + this.leftBorder;
        var yStart = this.background._y + this.topBorder;
        var h = 0;

        // Pre-clear the clipIndex of entries that the existing clips currently
        // point at, so when the visible window shifts the off-screen entries
        // drop their stale clipIndex. Walking the ~maxListIndex clips is O(M)
        // instead of walking the whole enumeration twice (O(N)) -- a big win
        // on large lists. The display loop below re-sets clipIndex for entries
        // that remain visible, so this is safe even when windows overlap.
        for (var j = 0; j < this._maxListIndex; j++) {
            var prevClip = this._entryClipManager.getClip(j);
            if (prevClip != undefined && prevClip._entry != undefined) {
                var prevEntry = prevClip._entry;
                if (prevEntry.clipIndex == j)
                    prevEntry.clipIndex = undefined;
            }
        }

        this._listIndex = 0;

        // Locals for the hot loop -- AVM1 method dispatch is expensive, so
        // pulling these out of per-iteration getter/wrapper calls is a real
        // savings over 26 iterations.
        var selEntry = this.selectedEntry;
        var enumeration = this.listEnumeration;
        var enumSize = enumeration.size();
        var clipPool = this._entryClipManager;
        var maxIdx = this._maxListIndex;
        var layoutVer = this._layoutVersion;

        // Display the selected list portion of the list. Skip setEntry on
        // clips where (a) the bound entry hasn't changed, (b) the entry isn't
        // marked render-dirty by the data setter, and (c) its selection state
        // is unchanged. setEntry is the bulk of UpdateList's cost; on
        // equip/drop only 1-2 entries change so 24+ clips skip the heavy
        // re-render.
        for (var i = this._scrollPosition; i < enumSize && this._listIndex < maxIdx; i++) {
            var entryClip = clipPool.getClip(this._listIndex);
            var entryItem = enumeration.at(i);
            var isSelected = (entryItem == selEntry);

            // Compare by reference, not by itemIndex. itemIndex is just the
            // entry's position in _entryList -- after a drop, remaining entries
            // shift down and their itemIndex values move with them, so an old
            // itemIndex can collide with a *different* entry's new itemIndex
            // (false-positive skip). Object identity is stable.
            var sameEntry = (entryClip._entry == entryItem);
            var canSkip = sameEntry
                          && entryItem.skyui_renderDirty != true
                          && entryClip._wasSelected == isSelected
                          && entryClip._layoutVersion == layoutVer;

            // itemIndex is updated unconditionally: a drop shifts every
            // remaining entry's itemIndex (idxReset rebases to 0..N-1) even
            // when the clip stays bound to the same entry, so mouse hit-test
            // and selection-restore (both consume clip.itemIndex) must see
            // the current value.
            entryClip.itemIndex = entryItem.itemIndex;

            if (!canSkip) {
                entryClip._entry = entryItem;
                entryClip.setEntry(entryItem, this.listState);
                entryClip._wasSelected = isSelected;
                entryClip._layoutVersion = layoutVer;
            }

            entryItem.clipIndex = this._listIndex;
            entryClip._x = xStart;
            entryClip._y = yStart + h;
            entryClip._visible = true;

            h = h + this.entryHeight;

            ++this._listIndex;
        }

        // Hide clips that were visible last call but aren't this call. Replaces
        // the per-frame universal reset that used to live in EntryClipManager
        // -- it would also wipe clip.itemIndex on every UpdateList, defeating
        // the skip check above. Leaving itemIndex intact on hidden clips is
        // fine: if the same entry comes back to the same slot the skip check
        // matches, otherwise it sees a different itemIndex and re-renders.
        for (var k = this._listIndex; k < this._prevListIndex; k++) {
            var trailClip = this._entryClipManager.getClip(k);
            if (trailClip != undefined)
                trailClip._visible = false;
        }
        this._prevListIndex = this._listIndex;

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

        // Snapshot the state we just rendered against; next call's self-skip
        // compares against these.
        this._lastUpdateEnumVersion = enumVer;
        this._lastUpdateScrollPos = this._scrollPosition;
        this._lastUpdateSelIdx = this._selectedIndex;
        this._lastUpdateLayoutVer = this._layoutVersion;
        this._lastUpdateToken = this._updateToken;
    }

    // @override BasicList
    public function InvalidateData()
    {
        if (this._bSuspended) {
            this._bRequestInvalidate = true;
            return;
        }

        // Run processors first. They walk _entryList by loop position and
        // check their own dirty flags -- none of them read itemIndex -- so
        // it's safe to defer idxReset until after we know whether the array
        // actually changed.
        var procs = this._dataProcessors;
        var procLen = procs.length;
        for (var p = 0; p < procLen; p++)
            procs[p].processList(this);

        var list = this._entryList;
        var entryCount = list.length;

        // Decide whether the game may have shuffled entry positions. Two
        // signals -- either one means itemIndex on existing entries can be
        // stale and must be re-anchored:
        //   1. A processor published a non-empty dirty-entries list
        //      (ItemcardDataExtender clears skyui_itemDataProcessed on every
        //      entry the game touched).
        //   2. _entryList.length changed (add/remove).
        // When both are quiet the array is byte-identical to last call;
        // skipping the 775-entry scan saves ~half the steady-state cost.
        var dirty = this.skyui_dirtyEntries;
        var hasDirty = (dirty != undefined && dirty.length > 0);
        var lengthChanged = (entryCount != this._lastEntryCount);
        this._lastEntryCount = entryCount;

        if (hasDirty || lengthChanged) {
            // Read-then-write: most entries' itemIndex already matches their
            // position even when *some* entries moved. Skipping the write
            // when unchanged still trims a few hundred setMember ops.
            //
            // Reverse iteration: AVM1 pre-decrement + compare-to-zero is one
            // op cheaper than the forward i++ + bounds-compare per iter.
            // idxReset is order-agnostic (each iter only writes the entry's
            // own itemIndex), so the reverse is safe.
            for (var i = entryCount; --i >= 0; ) {
                var ent = list[i];
                if (ent.itemIndex != i)
                    ent.itemIndex = i;
            }
        }

        // Cache the enumeration reference -- it's hit four times below.
        var enumeration = this.listEnumeration;

        // Signal data dirtiness to the enumeration when we know entries
        // changed. invalidate() itself short-circuits if nothing's actually
        // dirty, so calling it unconditionally is safe and cheap.
        if (hasDirty && enumeration.markDataDirty != undefined)
            enumeration.markDataDirty();

        // applyFilters returns true/false (or undefined for enumerations that
        // don't implement the skip protocol -- BasicEnumeration). Skipping
        // downstream work is only safe when the enumeration explicitly told
        // us the filtered output is unchanged; otherwise (undefined) we run
        // everything as before.
        var applied = enumeration.invalidate();

        if (applied != false) {
            // Enum (filter+sort) output changed -- bump token so UpdateList's
            // fast path knows to re-render.
            this._updateToken++;

            var enumSize = enumeration.size();
            if (this._selectedIndex >= enumSize)
                this._selectedIndex = enumSize - 1;

            if (enumeration.lookupEnumIndex(this._selectedIndex) == null)
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
        }

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
        this._updateToken++;

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
        this._updateToken++;
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
