class Shared.CenteredList extends MovieClip
{
  /* PUBLIC VARIABLES */

    public var BottomHalf;
    public var EntriesA;
    public var SelectedEntry;
    public var TopHalf;

    public var bMultilineList;
    public var bRepositionEntries;
    public var bToFitList;

    public var dispatchEvent;

    public var fCenterY;
    public var iMaxEntriesBottomHalf;
    public var iMaxEntriesTopHalf;
    public var iSelectedIndex;


  /* PROPERTIES */
    
    public function get selectedTextString() { return this.EntriesA[this.iSelectedIndex].text;}

    public function get selectedIndex() { return this.iSelectedIndex; }
    public function set selectedIndex(aiNewIndex) { this.iSelectedIndex = aiNewIndex; }

    public function get selectedEntry() { return this.EntriesA[this.iSelectedIndex]; }

    public function get entryList() { return this.EntriesA; }
    public function set entryList(anewArray) { this.EntriesA = anewArray; }


  /* INITIALIZATION */

    function CenteredList()
    {
        super();

        this.TopHalf = this.TopHalf;
        this.SelectedEntry = this.SelectedEntry;
        this.BottomHalf = this.BottomHalf;
        this.EntriesA = new Array();

        gfx.events.EventDispatcher.initialize(this);
        Mouse.addListener(this);

        this.iSelectedIndex = 0;
        this.fCenterY = this.SelectedEntry._y + this.SelectedEntry._height / 2;

        this.bRepositionEntries = true;

        this.iMaxEntriesTopHalf = this._countEntries(this.TopHalf);
        this.iMaxEntriesBottomHalf = this._countEntries(this.BottomHalf);
    }


  /* PUBLIC FUNCTIONS */

    public function ClearList()
    {
        this.EntriesA.splice(0, this.EntriesA.length);
    }

    public function handleInput(details, pathToFocus)
    {
        if (!Shared.GlobalFunc.IsKeyPressed(details)) return false;

        if (details.navEquivalent == gfx.ui.NavigationCode.UP)
        {
            this.moveListDown();
            return true;
        }

        if (details.navEquivalent == gfx.ui.NavigationCode.DOWN)
        {
            this.moveListUp();
            return true;
        }

        if (details.navEquivalent == gfx.ui.NavigationCode.ENTER && this.iSelectedIndex != -1)
        {
            this.dispatchEvent({
                type: "itemPress",
                index: this.iSelectedIndex,
                entry: this.EntriesA[this.iSelectedIndex]
            });
            return true;
        }

        return false;
    }

    public function onMouseWheel(delta)
    {
        if (!this.hitTest(_root._xmouse, _root._ymouse, true)) return;

        if (delta < 0) this.moveListUp();
        else if (delta > 0) this.moveListDown();
    }

    public function onPress(aiMouseIndex, aiKeyboardOrMouse)
    {
        if (this.SelectedEntry.hitTest(_root._xmouse, _root._ymouse, true))
        {
            this.dispatchEvent({
                type: "itemPress",
                index: this.iSelectedIndex,
                entry: this.EntriesA[this.iSelectedIndex],
                keyboardOrMouse: aiKeyboardOrMouse
            });
        }
    }

    public function onPressAux(aiMouseIndex, aiKeyboardOrMouse, aiButtonIndex)
    {
        if (this.SelectedEntry.hitTest(_root._xmouse, _root._ymouse, true) && aiButtonIndex == 1)
        {
            this.dispatchEvent({
                type: "itemPressAux",
                index: this.iSelectedIndex,
                entry: this.EntriesA[this.iSelectedIndex],
                keyboardOrMouse: aiKeyboardOrMouse
            });
        }
    }

    public function moveListUp()
    {
        if (this.iSelectedIndex < this.EntriesA.length - 1)
        {
            this.iSelectedIndex++;
            this.UpdateList();
            this.dispatchEvent({type: "listMovedUp"});
        }
    }

    public function moveListDown()
    {
        if (this.iSelectedIndex > 0)
        {
            this.iSelectedIndex--;
            this.UpdateList();
            this.dispatchEvent({type: "listMovedDown"});
        }
    }

    public function UpdateList()
    {
        this.iSelectedIndex = Math.min(Math.max(this.iSelectedIndex, 0), this.EntriesA.length - 1);

        var topArray = (this.iSelectedIndex > 0)
            ? this.EntriesA.slice(0, this.iSelectedIndex)
            : undefined;

        var bottomArray = (this.iSelectedIndex < this.EntriesA.length - 1)
            ? this.EntriesA.slice(this.iSelectedIndex + 1)
            : undefined;

        this.UpdateTopHalf(topArray);
        this.SetEntry(this.SelectedEntry, this.EntriesA[this.iSelectedIndex]);
        this.UpdateBottomHalf(bottomArray);

        this.RepositionEntries();
    }

    public function UpdateTopHalf(aEntryArray)
    {
        var offset = this.iMaxEntriesTopHalf - (aEntryArray ? aEntryArray.length : 0);

        for (var i = this.iMaxEntriesTopHalf - 1; i >= 0; i--)
        {
            var entryIndex = i - offset;

            if (aEntryArray && entryIndex >= 0 && entryIndex < aEntryArray.length)
                this.SetEntry(this._getEntry(this.TopHalf, i), aEntryArray[entryIndex]);
            else
                this.SetEntry(this._getEntry(this.TopHalf, i));
        }
    }

    public function UpdateBottomHalf(aEntryArray)
    {
        for (var i = 0; i < this.iMaxEntriesBottomHalf; i++)
        {
            if (aEntryArray && i < aEntryArray.length)
                this.SetEntry(this._getEntry(this.BottomHalf, i), aEntryArray[i]);
            else
                this.SetEntry(this._getEntry(this.BottomHalf, i));
        }
    }

    public function SetEntry(aEntryClip, aEntryObject)
    {
        this._applyTextSettings(aEntryClip);
        this._setEntryText(aEntryClip, aEntryObject);
    }
    
    public function SetupMultilineList()
    {
        this.bMultilineList = true;

        this._applyToAllEntries(this.TopHalf, this.iMaxEntriesTopHalf, function(entry) {
            entry.textField.verticalAutoSize = "top";
        });

        this._applyToAllEntries(this.BottomHalf, this.iMaxEntriesBottomHalf, function(entry) {
            entry.textField.verticalAutoSize = "top";
        });

        if (this.SelectedEntry)
            this.SelectedEntry.textField.verticalAutoSize = "top";
    }

    public function SetupToFitList()
    {
        this.bToFitList = true;

        this._applyToAllEntries(this.TopHalf, this.iMaxEntriesTopHalf, function(entry) {
            entry.textField.textAutoSize = "shrink";
        });

        this._applyToAllEntries(this.BottomHalf, this.iMaxEntriesBottomHalf, function(entry) {
            entry.textField.textAutoSize = "shrink";
        });

        if (this.SelectedEntry)
            this.SelectedEntry.textField.textAutoSize = "shrink";
    }

    public function RepositionEntries()
    {
        if (!this.bRepositionEntries) return;

        this._layoutContainer(this.TopHalf, this.iMaxEntriesTopHalf);
        this._layoutContainer(this.BottomHalf, this.iMaxEntriesBottomHalf);

        this.SelectedEntry._y = this.fCenterY - this.SelectedEntry._height / 2;

        this.TopHalf._y = this.SelectedEntry._y - this.TopHalf._height;
        this.BottomHalf._y = this.SelectedEntry._y + this.SelectedEntry._height;
    }


  /* PRIVATE FUNCTIONS */
    
    private function _countEntries(container)
    {
        var count = 0;
        
        while (container["Entry" + count] != undefined)
            count++;

        return count;
    }

    private function _getEntry(container, index)
    {
        return container["Entry" + index];
    }

    private function _applyTextSettings(aEntryClip)
    {
        if (this.bMultilineList)
            aEntryClip.textField.verticalAutoSize = "top";

        if (this.bToFitList)
            aEntryClip.textField.textAutoSize = "shrink";
    }

    private function _setEntryText(aEntryClip, aEntryObject)
    {
        if (aEntryObject != undefined && aEntryObject.text != undefined)
        {
            if (aEntryObject.count > 1)
                aEntryClip.textField.SetText(aEntryObject.text + " (" + aEntryObject.count + ")");
            else
                aEntryClip.textField.SetText(aEntryObject.text); 
        }
        else
        {
            aEntryClip.textField.SetText(" ");
        }
    }

    private function _applyToAllEntries(container, maxCount, fn)
    {
        for (var i = 0; i < maxCount; i++)
            fn(container["Entry" + i]);
    }

    private function _layoutContainer(container, maxCount)
    {
        var y = 0;

        for (var i = 0; i < maxCount; i++)
        {
            var entry = container["Entry" + i];
            entry._y = y;
            y += entry._height;
        }
    }
}
