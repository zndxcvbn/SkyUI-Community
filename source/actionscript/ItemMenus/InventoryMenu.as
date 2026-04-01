class InventoryMenu extends ItemMenu
{
   var ToggleMenuFade;
   var _categoryListIconArt;
   var _platform;
   var _quantityMinCount;
   var bFadedIn;
   var BottomBar_mc;
   var checkBook;
   var confirmSelectedEntry;
   var inventoryLists;
   var itemCard;
   var saveIndices;
   var shouldProcessItemsListInput;
   static var SKYUI_RELEASE_IDX = 2018;
   static var SKYUI_VERSION_MAJOR = 5;
   static var SKYUI_VERSION_MINOR = 2;
   static var SKYUI_VERSION_STRING = InventoryMenu.SKYUI_VERSION_MAJOR + "." + InventoryMenu.SKYUI_VERSION_MINOR + " SE";
   var _bMenuClosing = false;
   var _bSwitchMenus = false;
   var bPCControlsReady = true;
   
   static var EXIT:     Object = {Label: "$Exit",   PCArt: "Tab",   XBoxArt: "360_B",    PS3Art: "PS3_B"};
   static var SEARCH:   Object = {Label: "$Search", PCArt: "Space", XBoxArt: "",         PS3Art: ""};
   static var SWITCH:   Object = {Label: "$Magic",  PCArt: "L-Alt", XBoxArt: "360_Back", PS3Art: "PS3_Select"};
   static var DROP:     Object = {Label: "$Drop",   PCArt: "R",     XBoxArt: "360_X",    PS3Art: "PS3_X"};
   static var FAVORITE: Object = {Label: "$Favorite", PCArt: "F",   XBoxArt: "360_Y",    PS3Art: "PS3_Y"};
   static var CHARGE:   Object = {Label: "$Charge", PCArt: "T",     XBoxArt: "360_RB",   PS3Art: "PS3_RB"};
   static var SORT:     Object = {Label: "$Sort",   PCArt: "",      XBoxArt: "360_RS",   PS3Art: "PS3_RS"};
   static var ORDER:    Object = {Label: "$Order",  PCArt: "",      XBoxArt: "360_LS",   PS3Art: "PS3_LS"};
   static var ACCEPT:   Object = {Label: "$Select", PCArt: "Enter", XBoxArt: "360_A",    PS3Art: "PS3_A"};
   static var CANCEL:   Object = {Label: "$Cancel", PCArt: "Tab",   XBoxArt: "360_B",    PS3Art: "PS3_B"};
   
   function InventoryMenu()
   {
      super();
      this._categoryListIconArt = ["cat_favorites","inv_all","inv_weapons","inv_armor","inv_potions","inv_scrolls","inv_food","inv_ingredients","inv_books","inv_keys","inv_misc"];
      gfx.io.GameDelegate.addCallBack("AttemptEquip",this,"AttemptEquip");
      gfx.io.GameDelegate.addCallBack("DropItem",this,"DropItem");
      gfx.io.GameDelegate.addCallBack("AttemptChargeItem",this,"AttemptChargeItem");
      gfx.io.GameDelegate.addCallBack("ItemRotating",this,"ItemRotating");
   }
   function InitExtensions()
   {
      super.InitExtensions();
      Shared.GlobalFunc.AddReverseFunctions();
      this.inventoryLists.zoomButtonHolder.gotoAndStop(1);
      var _loc3_ = this.inventoryLists.categoryList;
      _loc3_.iconArt = this._categoryListIconArt;
      this.itemCard.addEventListener("itemPress",this,"onItemCardListPress");
   }
   function setConfig(a_config)
   {
      super.setConfig(a_config);
      var _loc3_ = this.inventoryLists.itemList;
      _loc3_.addDataProcessor(new InventoryDataSetter());
      _loc3_.addDataProcessor(new InventoryIconSetter(a_config.Appearance));
      _loc3_.addDataProcessor(new skyui.props.PropertyDataExtender(a_config.Appearance,a_config.Properties,"itemProperties","itemIcons","itemCompoundProperties"));
      var _loc5_ = skyui.components.list.ListLayoutManager.createLayout(a_config.ListLayout,"ItemListLayout");
      _loc3_.layout = _loc5_;
      if(this.inventoryLists.categoryList.selectedEntry)
      {
         _loc5_.changeFilterFlag(this.inventoryLists.categoryList.selectedEntry.flag);
      }
   }
   function handleInput(details, pathToFocus)
   {
      if(!this.bFadedIn)
      {
         return true;
      }
      var _loc3_ = pathToFocus.shift();
      if(_loc3_.handleInput(details,pathToFocus))
      {
         return true;
      }
      if(Shared.GlobalFunc.IsKeyPressed(details))
      {
         if(details.navEquivalent == gfx.ui.NavigationCode.TAB || details.navEquivalent == gfx.ui.NavigationCode.SHIFT_TAB)
         {
            this.startMenuFade();
            gfx.io.GameDelegate.call("CloseTweenMenu",[]);
         }
         else if(!this.inventoryLists.itemList.disableInput)
         {
            if(details.skseKeycode == this._switchTabKey || details.control == "Quick Magic")
            {
               this.openMagicMenu(true);
            }
         }
      }
      return true;
   }
   function AttemptEquip(a_slot, a_bCheckOverList)
   {
      var _loc2_ = a_bCheckOverList == undefined ? true : a_bCheckOverList;
      if(this.shouldProcessItemsListInput(_loc2_) && this.confirmSelectedEntry())
      {
         gfx.io.GameDelegate.call("ItemSelect",[a_slot]);
         this.checkBook(this.inventoryLists.itemList.selectedEntry);
      }
   }
   function DropItem()
   {
      if(this.shouldProcessItemsListInput(false) && this.inventoryLists.itemList.selectedEntry != undefined)
      {
         if(this._quantityMinCount < 1 || this.inventoryLists.itemList.selectedEntry.count < this._quantityMinCount)
         {
            this.onQuantityMenuSelect({amount:1});
         }
         else
         {
            this.itemCard.ShowQuantityMenu(this.inventoryLists.itemList.selectedEntry.count);
         }
      }
   }
   function AttemptChargeItem()
   {
      if(this.inventoryLists.itemList.selectedIndex == -1)
      {
         return undefined;
      }
      if(this.shouldProcessItemsListInput(false) && this.itemCard.itemInfo.charge != undefined && this.itemCard.itemInfo.charge < 100)
      {
         gfx.io.GameDelegate.call("ShowSoulGemList",[]);
      }
   }
   function SetPlatform(a_platform, a_bPS3Switch)
   {
      this.inventoryLists.zoomButtonHolder.gotoAndStop(1);
      this.inventoryLists.zoomButtonHolder.ZoomButton._visible = a_platform != 0;
      this.inventoryLists.zoomButtonHolder.ZoomButton.SetPlatform(a_platform,a_bPS3Switch);
      super.SetPlatform(a_platform,a_bPS3Switch);
   }
   function ItemRotating()
   {
      this.inventoryLists.zoomButtonHolder.PlayForward(this.inventoryLists.zoomButtonHolder._currentframe);
   }
   function onExitMenuRectClick()
   {
      this.startMenuFade();
      gfx.io.GameDelegate.call("ShowTweenMenu",[]);
   }
   function onFadeCompletion()
   {
      if(!this._bMenuClosing)
      {
         return undefined;
      }
      gfx.io.GameDelegate.call("CloseMenu",[]);
      if(this._bSwitchMenus)
      {
         gfx.io.GameDelegate.call("CloseTweenMenu",[]);
         skse.OpenMenu("MagicMenu");
      }
   }
   function onShowItemsList(event)
   {
      super.onShowItemsList(event);
      if(event.index != -1)
      {
         this.UpdateBottomBar(true);
      }
      this.UpdateBottomBar(false);
   }
   function onItemHighlightChange(event)
   {
      super.onItemHighlightChange(event);
      if(event.index != -1)
      {
         this.UpdateBottomBar(true);
      }
   }
   function onHideItemsList(event)
   {
      super.onHideItemsList(event);
      this.BottomBar_mc.UpdatePerItemInfo({type:skyui.defines.Inventory.ICT_NONE});
      this.UpdateBottomBar(false);
   }
   function onItemSelect(event)
   {
      if(event.entry.enabled && event.keyboardOrMouse != 0)
      {
         gfx.io.GameDelegate.call("ItemSelect",[]);
         this.checkBook(event.entry);
      }
   }
   function onQuantityMenuSelect(event)
   {
      gfx.io.GameDelegate.call("ItemDrop",[event.amount]);
      gfx.io.GameDelegate.call("RequestItemCardInfo",[],this,"UpdateItemCardInfo");
   }
   function onMouseRotationFastClick(aiMouseButton)
   {
      gfx.io.GameDelegate.call("CheckForMouseEquip",[aiMouseButton],this,"AttemptEquip");
   }
   function onItemCardListPress(event)
   {
      gfx.io.GameDelegate.call("ItemCardListCallback",[event.index]);
   }
   function onItemCardSubMenuAction(event)
   {
      super.onItemCardSubMenuAction(event);
      gfx.io.GameDelegate.call("QuantitySliderOpen",[event.opening]);
      if(event.menu == "list")
      {
         if(event.opening == true)
         {
            this.BottomBar_mc.HideButtons();

            this.BottomBar_mc.CreateButton(0, this.AcceptBtn);
            this.BottomBar_mc.CreateButton(1, this.CancelBtn);

            this.BottomBar_mc.PositionButtons();
         }
         else
         {
            gfx.io.GameDelegate.call("RequestItemCardInfo",[],this,"UpdateItemCardInfo");
            this.UpdateBottomBar(true);
         }
      }
   }
   function openMagicMenu(a_bFade)
   {
      if(a_bFade)
      {
         this._bSwitchMenus = true;
         this.startMenuFade();
      }
      else
      {
         this.saveIndices();
         gfx.io.GameDelegate.call("CloseMenu",[]);
         gfx.io.GameDelegate.call("CloseTweenMenu",[]);
         skse.OpenMenu("MagicMenu");
      }
   }
   function startMenuFade()
   {
      this.inventoryLists.hidePanel();
      this.ToggleMenuFade();
      this.saveIndices();
      this._bMenuClosing = true;
   }
   function UpdateBottomBar(a_bSelected)
   {
      this.BottomBar_mc.HideButtons();

      if (a_bSelected) 
      {
         var itemInfo = this.itemCard.itemInfo;
         var selectedEntry = this.inventoryLists.itemList.selectedEntry;

         var isFavorited = (selectedEntry.filterFlag & this.inventoryLists.categoryList.entryList[0].flag) != 0;
         this.FavBtn.text = isFavorited ? "$Unfavorite" : "$Favorite";

         this.BottomBar_mc.CreateButton(0, this.getEquipButtonData(itemInfo.type, false));
         this.BottomBar_mc.CreateButton(1, InventoryMenu.DROP);
         this.BottomBar_mc.CreateButton(2, InventoryMenu.FAVORITE);

         if (itemInfo.charge != undefined && itemInfo.charge < 100)
            this.BottomBar_mc.CreateButton(3, InventoryMenu.CHARGE);
      } 
      else 
      {
         this.BottomBar_mc.CreateButton(0, InventoryMenu.EXIT);
         this.BottomBar_mc.CreateButton(1, InventoryMenu.SWITCH);
         this.BottomBar_mc.CreateButton(2, InventoryMenu.SEARCH);

         if (this._platform != 0)
         {
            this.BottomBar_mc.CreateButton(3, InventoryMenu.SORT);
            this.BottomBar_mc.CreateButton(4, InventoryMenu.ORDER);
         }
      }

      this.BottomBar_mc.PositionButtons();
   }
}
