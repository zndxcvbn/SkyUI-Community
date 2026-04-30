class DialogueCenteredList extends Shared.CenteredScrollingList
{
  /* PUBLIC VARIABLES */ 

    public var fCenterY: Number;    


  /* INITIALIZATION */ 

    public function DialogueCenteredList()
    {
        super();
        
        var centerClip = this.GetClipByIndex(this.iNumTopHalfEntries);
        this.fCenterY = centerClip._y + (centerClip._height / 2);
    }


  /* PUBLIC FUNCTIONS */ 

    // @override CenteredScrollingList
    public function SetEntryText(aEntryClip: MovieClip, aEntryObject: Object)
    {
        super.SetEntryText(aEntryClip, aEntryObject);
        
        if (aEntryClip.textField != undefined) {
            var isNew = aEntryObject.topicIsNew == undefined || aEntryObject.topicIsNew;
            aEntryClip.textField.textColor = isNew ? 0xFFFFFF : 0x606060;
        }
    }

    // @override CenteredScrollingList
    function UpdateList()
    {
        
        if (this.bPointerHighlight)
            this.iSelectedIndex = this.iScrollPosition;

        var currentY: Number = 0;
        
        var dataIdx: Number = Math.max(0, this.iScrollPosition - this.iNumTopHalfEntries);
        
        this.iListItemsShown = 0;
        
        for (var i: Number = 0; i < this.iNumTopHalfEntries; i++) {
            var entryClip = this.GetClipByIndex(i);
            
            if ((this.iScrollPosition - this.iNumTopHalfEntries + i) >= 0) {
                this.SetEntry(entryClip, this.EntriesA[dataIdx]);
                entryClip._visible = true;
                entryClip.itemIndex = dataIdx;
                this.EntriesA[dataIdx].clipIndex = i;
                dataIdx++;
            } else {
                this.SetEntry(entryClip, {text: " "});
                entryClip._visible = false;
                entryClip.itemIndex = undefined;
            }
            
            entryClip._y = currentY;
            currentY += entryClip._height;
            this.iListItemsShown++;
        }
        
        if (this.bPointerHighlight)
            this.iSelectedIndex = dataIdx;
        
        while (dataIdx < this.EntriesA.length && this.iListItemsShown < this.iMaxItemsShown && currentY <= this.fListHeight) {
            var entryClip = this.GetClipByIndex(this.iListItemsShown);
            
            this.SetEntry(entryClip, this.EntriesA[dataIdx]);
            this.EntriesA[dataIdx].clipIndex = this.iListItemsShown;
            entryClip.itemIndex = dataIdx;
            entryClip._y = currentY;
            entryClip._visible = true;
            
            currentY += entryClip._height;
            
            if (currentY <= this.fListHeight && this.iListItemsShown < this.iMaxItemsShown)
                this.iListItemsShown++;
                
            dataIdx++;
        }

        for (var j: Number = this.iListItemsShown; j < this.iMaxItemsShown; j++) {
            var unusedClip = this.GetClipByIndex(j);
            unusedClip._visible = false;
            unusedClip.itemIndex = undefined;
        }

        if (!this.bPointerHighlight && !this.bRecenterSelection) {
            for (var k: Number = 0; k < this.iMaxItemsShown; k++) {
                var clip = this.GetClipByIndex(k);
                if (clip && clip._visible && clip.itemIndex != undefined) {
                    if (clip.hitTest(_root._xmouse, _root._ymouse, true) && clip.itemIndex != this.iSelectedIndex) {
                        this.doSetSelectedIndex(clip.itemIndex, 0);
                        break;
                    }
                }
            }
        }
        
        this.bRecenterSelection = false;
        
        this.RepositionEntries();

        var INDICATOR_LIMIT: Number = 3;
        this._parent.ScrollIndicators.Up._visible = (this.scrollPosition > this.iNumTopHalfEntries);
        
        var isDownVisible = (this.EntriesA.length - this.scrollPosition - 1 > INDICATOR_LIMIT) || (currentY > this.fListHeight);
        this._parent.ScrollIndicators.Down._visible = isDownVisible;
    }

    // @override CenteredScrollingList
    public function onMouseWheel(delta: Number)
    {
        if (!this.bDisableInput) {
            this.bPointerHighlight = true;

            if (delta < 0) {
                var nextClip = this.GetClipByIndex(this.iNumTopHalfEntries + 1);
                if (nextClip._visible) this.scrollPosition += 1;
            } else if (delta > 0) {
                var prevClip = this.GetClipByIndex(this.iNumTopHalfEntries - 1);
                if (prevClip._visible) this.scrollPosition -= 1;
            }

            this.iSelectedIndex = this.iScrollPosition;
            this.UpdateList();
        }
    }

    public function RepositionEntries()
    {
        var centerClip = this.GetClipByIndex(this.iNumTopHalfEntries);
        var currentVisualCenter = centerClip._y + (centerClip._height / 2);
        var offset: Number = this.fCenterY - currentVisualCenter;

        for (var i: Number = 0; i < this.iMaxItemsShown; i++) {
            var clip = this.GetClipByIndex(i);
            clip._y += offset;
        }
    }
    
    public function SetSelectedTopic(aiTopicIndex: Number)
    {
        this.bPointerHighlight = true;
        this.iSelectedIndex = 0;
        this.iScrollPosition = 0;
        
        for (var i: Number = 0; i < this.EntriesA.length; i++) {
            if (this.EntriesA[i].topicIndex == aiTopicIndex) {
                this.iScrollPosition = i;
                this.iSelectedIndex = i;
                break;
            }
        }
        this.UpdateList();
    }
}
