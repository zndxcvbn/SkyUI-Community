class CategoryList extends skyui.components.list.BasicList
{
   var selectedEntry;
   var _activeSegment;
   var _bFastSwitch;
   var _bRequestInvalidate;
   var _bRequestUpdate;
   var _bSuspended;
   var _contentWidth;
   var _entryClipManager;
   var _entryList;
   var _segmentLength;
   var _segmentOffset;
   var _selectedIndex;
   var _selectorPos;
   var _targetSelectorPos;
   var _totalWidth;
   var background;
   var disableInput;
   var disableSelection;
   var dispatchEvent;
   var dividerIndex;
   var doSetSelectedIndex;
   var getClipByIndex;
   var iconSize;
   var isMouseDrivenNav;
   var listEnumeration;
   var listState;
   var onInvalidate;
   var selectorCenter;
   var selectorLeft;
   var selectorRight;
   var setClipCount;
   static var LEFT_SEGMENT = 0;
   static var RIGHT_SEGMENT = 1;
   function CategoryList()
   {
      super();
      this._selectorPos = 0;
      this._targetSelectorPos = 0;
      this._bFastSwitch = false;
      this._activeSegment = CategoryList.LEFT_SEGMENT;
      this.dividerIndex = -1;
      this._segmentOffset = 0;
      this._segmentLength = 0;
      if(this.iconSize == undefined)
      {
         this.iconSize = 32;
      }
      Shared.GlobalFunc.SetExtendedLayoutFunctions();
   }
   function set activeSegment(a_segment)
   {
      if(a_segment == this._activeSegment)
      {
         return;
      }
      this._activeSegment = a_segment;
      this.calculateSegmentParams();
      if(a_segment == CategoryList.LEFT_SEGMENT && this._selectedIndex > this.dividerIndex)
      {
         this.doSetSelectedIndex(this._selectedIndex - this.dividerIndex - 1,skyui.components.list.BasicList.SELECT_MOUSE);
      }
      else if(a_segment == CategoryList.RIGHT_SEGMENT && this._selectedIndex < this.dividerIndex)
      {
         this.doSetSelectedIndex(this._selectedIndex + this.dividerIndex + 1,skyui.components.list.BasicList.SELECT_MOUSE);
      }
      this.UpdateList();
   }
   function get activeSegment()
   {
      return this._activeSegment;
   }
   function clearList()
   {
      this.dividerIndex = -1;
      this._entryList.splice(0);
   }
   function InvalidateData()
   {
      if(this._bSuspended)
      {
         this._bRequestInvalidate = true;
         return undefined;
      }
      this.listEnumeration.invalidate();
      this.calculateSegmentParams();
      if(this._selectedIndex >= this.listEnumeration.size())
      {
         this._selectedIndex = this.listEnumeration.size() - 1;
      }
      this.UpdateList();
      if(this.onInvalidate)
      {
         this.onInvalidate();
      }
   }
   function UpdateList()
   {
      if(this._bSuspended) {
         this._bRequestUpdate = true;
         return;
      }
      
      this.setClipCount(this._segmentLength);
      
      var visibleClips: Array = [];
      
      for(var i: Number = 0; i < this._segmentLength; i++) {
         var clip = this.getClipByIndex(i);
         var entryData = this.listEnumeration.at(i + this._segmentOffset);
         
         clip.setEntry(entryData, this.listState);
         clip.background._width = clip.background._height = this.iconSize;
         entryData.clipIndex = i;
         clip.itemIndex = i + this._segmentOffset;
         clip._visible = true;
         
         visibleClips.push(clip);
      }
      
      this.background.JustifyContent(visibleClips, "space-evenly");

      this.updateSelector();

      if (this._selectedIndex != -1) {
         this._selectorPos = this._targetSelectorPos;
         this.drawSelector(this._selectorPos);
      }
   }
   function moveSelectionLeft()
   {
      if(this.disableSelection)
      {
         return undefined;
      }
      var _loc2_ = this._selectedIndex;
      var _loc3_ = this._selectedIndex;
      do
      {
         if(_loc2_ > this._segmentOffset)
         {
            _loc2_ = _loc2_ - 1;
         }
         else
         {
            this._bFastSwitch = true;
            _loc2_ = this._segmentOffset + this._segmentLength - 1;
         }
      }
      while(_loc2_ != _loc3_ && this.listEnumeration.at(_loc2_).filterFlag == 0 && !this.listEnumeration.at(_loc2_).bDontHide);
      
      this.onItemPress(_loc2_,0);
   }
   function moveSelectionRight()
   {
      if(this.disableSelection)
      {
         return undefined;
      }
      var _loc2_ = this._selectedIndex;
      var _loc3_ = this._selectedIndex;
      do
      {
         if(_loc2_ < this._segmentOffset + this._segmentLength - 1)
         {
            _loc2_ = _loc2_ + 1;
         }
         else
         {
            this._bFastSwitch = true;
            _loc2_ = this._segmentOffset;
         }
      }
      while(_loc2_ != _loc3_ && this.listEnumeration.at(_loc2_).filterFlag == 0 && !this.listEnumeration.at(_loc2_).bDontHide);
      
      this.onItemPress(_loc2_,0);
   }
   function handleInput(details, pathToFocus)
   {
      if(this.disableInput)
      {
         return false;
      }
      if(Shared.GlobalFunc.IsKeyPressed(details))
      {
         if(details.navEquivalent == gfx.ui.NavigationCode.LEFT)
         {
            this.moveSelectionLeft();
            return true;
         }
         if(details.navEquivalent == gfx.ui.NavigationCode.RIGHT)
         {
            this.moveSelectionRight();
            return true;
         }
      }
      return false;
   }
   function onEnterFrame()
   {
      super.onEnterFrame();

      if (this._selectedIndex == -1) return;

      if (this._bFastSwitch) {
         this._selectorPos = this._targetSelectorPos;
         this._bFastSwitch = false;
      } else {
         var diff = this._targetSelectorPos - this._selectorPos;
         if (Math.abs(diff) < 0.5) {
            this._selectorPos = this._targetSelectorPos;
         } else {
            this._selectorPos += diff * 0.2;
         }
      }

      this.drawSelector(this._selectorPos);
   }
   function onItemPress(a_index, a_keyboardOrMouse)
   {
      if(this.disableInput || this.disableSelection || a_index == -1)
      {
         return undefined;
      }
      this.doSetSelectedIndex(a_index,a_keyboardOrMouse);
      this.updateSelector();
      this.dispatchEvent({type:"itemPress",index:this._selectedIndex,entry:this.selectedEntry,keyboardOrMouse:a_keyboardOrMouse});
   }
   function onItemPressAux(a_index, a_keyboardOrMouse, a_buttonIndex)
   {
      if(this.disableInput || this.disableSelection || a_index == -1 || a_buttonIndex != 1)
      {
         return undefined;
      }
      this.doSetSelectedIndex(a_index,a_keyboardOrMouse);
      this.updateSelector();
      this.dispatchEvent({type:"itemPressAux",index:this._selectedIndex,entry:this.selectedEntry,keyboardOrMouse:a_keyboardOrMouse});
   }
   function onItemRollOver(a_index)
   {
      if(this.disableInput || this.disableSelection)
      {
         return undefined;
      }
      this.isMouseDrivenNav = true;
      if(a_index == this._selectedIndex)
      {
         return undefined;
      }
      var _loc2_ = this.getClipByIndex(a_index);
      _loc2_._alpha = 75;
   }
   function onItemRollOut(a_index)
   {
      if(this.disableInput || this.disableSelection)
      {
         return undefined;
      }
      this.isMouseDrivenNav = true;
      if(a_index == this._selectedIndex)
      {
         return undefined;
      }
      var _loc2_ = this.getClipByIndex(a_index);
      _loc2_._alpha = 50;
   }
   function calculateSegmentParams()
   {
      if(this.dividerIndex != undefined && this.dividerIndex != -1)
      {
         if(this._activeSegment == CategoryList.LEFT_SEGMENT)
         {
            this._segmentOffset = 0;
            this._segmentLength = this.dividerIndex;
         }
         else
         {
            this._segmentOffset = this.dividerIndex + 1;
            this._segmentLength = this.listEnumeration.size() - this._segmentOffset;
         }
      }
      else
      {
         this._segmentOffset = 0;
         this._segmentLength = this.listEnumeration.size();
      }
   }
   function updateSelector()
   {
      if (this.selectorCenter == undefined) return;

      if (this._selectedIndex == -1) {
         this.selectorCenter._visible = this.selectorLeft._visible = this.selectorRight._visible = false;
         return;
      }
      
      var targetClip = this.getClipByIndex(this._selectedIndex - this._segmentOffset);
      if (targetClip == undefined) return;
      
      this._targetSelectorPos = targetClip._x + (targetClip.background._width - this.selectorCenter._width) / 2;
      
      var targetY = targetClip._y + targetClip.background._height;
      this.selectorCenter._y = this.selectorLeft._y = this.selectorRight._y = targetY;

      this.selectorCenter._visible = this.selectorLeft._visible = this.selectorRight._visible = true;
   }
   
   private function drawSelector(a_x: Number)
   {
      if (this.selectorCenter == undefined) return;

      var bgX: Number = this.background._x;
      var bgMaxX: Number = bgX + this.background._width;
      
      this.selectorCenter._x = a_x;
      
      if (this.selectorLeft != undefined) {
         this.selectorLeft._x = bgX;
         this.selectorLeft._width = Math.max(0, a_x - bgX);
      }
      
      if (this.selectorRight != undefined) {
         var rightStart: Number = a_x + this.selectorCenter._width;
         this.selectorRight._x = rightStart;
         this.selectorRight._width = Math.max(0, bgMaxX - rightStart);
      }
   }
}
