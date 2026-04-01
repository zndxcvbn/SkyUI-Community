class BarterMenu extends ItemMenu
{
   var _categoryListIconArt;
   var _platform;
   var _tabBarIconArt;
   var BottomBar_mc;
   var inventoryLists;
   var itemCard;
   static var SKYUI_RELEASE_IDX = 2018;
   static var SKYUI_VERSION_MAJOR = 5;
   static var SKYUI_VERSION_MINOR = 2;
   static var SKYUI_VERSION_STRING = BarterMenu.SKYUI_VERSION_MAJOR + "." + BarterMenu.SKYUI_VERSION_MINOR + " SE";
   var fBuyMult = 1;
   var fSellMult = 1;
   var iConfirmAmount = 0;
   var iPlayerGold = 0;
   var iVendorGold = 0;
   var bEnableTabs = true;

   static var EXIT:   Object = {Label: "$Exit",       PCArt: "Tab",   XBoxArt: "360_B",    PS3Art: "PS3_B"};
   static var SEARCH: Object = {Label: "$Search",     PCArt: "Space", XBoxArt: "",         PS3Art: ""};
   static var SWITCH: Object = {Label: "$Switch Tab", PCArt: "L-Alt", XBoxArt: "360_LB",   PS3Art: "PS3_L1"};
   static var BUY:    Object = {Label: "$Buy",        PCArt: "E",     XBoxArt: "360_A",    PS3Art: "PS3_A"};
   static var SELL:   Object = {Label: "$Sell",       PCArt: "E",     XBoxArt: "360_A",    PS3Art: "PS3_A"};
   static var SORT:   Object = {Label: "$Sort",       PCArt: "",      XBoxArt: "360_RS",   PS3Art: "PS3_RS"};
   static var ORDER:  Object = {Label: "$Order",      PCArt: "",      XBoxArt: "360_LS",   PS3Art: "PS3_LS"};
   static var ACCEPT: Object = {Label: "$Select",     PCArt: "Enter", XBoxArt: "360_A",    PS3Art: "PS3_A"};
   static var CANCEL: Object = {Label: "$Cancel",     PCArt: "Tab",   XBoxArt: "360_B",    PS3Art: "PS3_B"};

   function BarterMenu()
   {
      super();
      this._categoryListIconArt = ["inv_all","inv_weapons","inv_armor","inv_potions","inv_scrolls","inv_food","inv_ingredients","inv_books","inv_keys","inv_misc"];
      this._tabBarIconArt = ["buy","sell"];
   }
   function InitExtensions()
   {
      super.InitExtensions();
      gfx.io.GameDelegate.addCallBack("SetBarterMultipliers",this,"SetBarterMultipliers");
      this.itemCard.addEventListener("messageConfirm",this,"onTransactionConfirm");
      this.itemCard.addEventListener("sliderChange",this,"onQuantitySliderChange");
      this.inventoryLists.tabBarIconArt = this._tabBarIconArt;
      var _loc3_ = this.inventoryLists.categoryList;
      _loc3_.iconArt = this._categoryListIconArt;
   }
   function setConfig(a_config)
   {
      super.setConfig(a_config);
      var _loc3_ = this.inventoryLists.itemList;
      _loc3_.addDataProcessor(new BarterDataSetter(this.fBuyMult,this.fSellMult));
      _loc3_.addDataProcessor(new InventoryIconSetter(a_config.Appearance));
      _loc3_.addDataProcessor(new skyui.props.PropertyDataExtender(a_config.Appearance,a_config.Properties,"itemProperties","itemIcons","itemCompoundProperties"));
      var _loc5_ = skyui.components.list.ListLayoutManager.createLayout(a_config.ListLayout,"ItemListLayout");
      _loc3_.layout = _loc5_;
      if(this.inventoryLists.categoryList.selectedEntry)
      {
         _loc5_.changeFilterFlag(this.inventoryLists.categoryList.selectedEntry.flag);
      }

      BarterMenu.SEARCH.PCArt = this._searchKey;
      BarterMenu.SWITCH.PCArt = this._switchTabKey;
      BarterMenu.SWITCH.XBoxArt = this._switchTabKey;
      BarterMenu.SWITCH.PS3Art = this._switchTabKey;

      this.UpdateBottomBar(false);
   }
   function onExitButtonPress()
   {
      gfx.io.GameDelegate.call("CloseMenu",[]);
   }
   function SetBarterMultipliers(afBuyMult, afSellMult)
   {
      this.fBuyMult = afBuyMult;
      this.fSellMult = afSellMult;
   }
   function ShowRawDealWarning(strWarning)
   {
      this.itemCard.ShowConfirmMessage(strWarning);
   }
   function UpdateItemCardInfo(aUpdateObj)
   {
      if(this.IsViewingVendorItems())
      {
         aUpdateObj.value *= this.fBuyMult;
         aUpdateObj.value = Math.max(aUpdateObj.value,1);
      }
      else
      {
         aUpdateObj.value *= this.fSellMult;
      }
      aUpdateObj.value = Math.floor(aUpdateObj.value + 0.5);
      this.itemCard.itemInfo = aUpdateObj;
      this.BottomBar_mc.SetBarterPerItemInfo(aUpdateObj,this.PlayerInfoObj);
   }
   function UpdatePlayerInfo(aiPlayerGold, aiVendorGold, astrVendorName, aUpdateObj)
   {
      this.iVendorGold = aiVendorGold;
      this.iPlayerGold = aiPlayerGold;
      this.BottomBar_mc.SetBarterInfo(aiPlayerGold,aiVendorGold,undefined,astrVendorName);
      this.PlayerInfoObj = aUpdateObj;
   }
   function onShowItemsList(event)
   {
      this.inventoryLists.showItemsList();
      this.UpdateBottomBar(false);
   }
   function onItemHighlightChange(event)
   {
      if(event.index != -1)
      {
         this.UpdateBottomBar(true);
      }
      super.onItemHighlightChange(event);
   }
   function onHideItemsList(event)
   {
      super.onHideItemsList(event);
      this.BottomBar_mc.SetBarterPerItemInfo({type:skyui.defines.Inventory.ICT_NONE});
      this.UpdateBottomBar(false);
   }
   function onQuantitySliderChange(event)
   {
      var _loc2_ = this.itemCard.itemInfo.value * event.value;
      if(this.IsViewingVendorItems())
      {
         _loc2_ *= -1;
      }
      this.BottomBar_mc.SetBarterInfo(this.iPlayerGold,this.iVendorGold,_loc2_);
   }
   function onQuantityMenuSelect(event)
   {
      var _loc2_ = event.amount * this.itemCard.itemInfo.value;
      if(_loc2_ > this.iVendorGold && !this.IsViewingVendorItems())
      {
         this.iConfirmAmount = event.amount;
         gfx.io.GameDelegate.call("GetRawDealWarningString",[_loc2_],this,"ShowRawDealWarning");
      }
      else
      {
         this.doTransaction(event.amount);
      }
   }
   function onItemCardSubMenuAction(event)
   {
      super.onItemCardSubMenuAction(event);
      gfx.io.GameDelegate.call("QuantitySliderOpen",[event.opening]);
      if(event.menu == "quantity")
      {
         if(event.opening)
         {
            this.onQuantitySliderChange({value:this.itemCard.itemInfo.count});
         }
         else
         {
            this.BottomBar_mc.SetBarterInfo(this.iPlayerGold,this.iVendorGold);
         }
      }
   }
   function onTransactionConfirm()
   {
      this.doTransaction(this.iConfirmAmount);
      this.iConfirmAmount = 0;
   }
   function doTransaction(aiAmount)
   {
      gfx.io.GameDelegate.call("ItemSelect",[aiAmount,this.itemCard.itemInfo.value,this.IsViewingVendorItems()]);
   }
   function IsViewingVendorItems()
   {
      return this.inventoryLists.categoryList.activeSegment == 0;
   }
   function UpdateBottomBar(a_bSelected)
   {
      this.BottomBar_mc.HideButtons();

      if(a_bSelected)
      {
         var actionBtn = this.IsViewingVendorItems() ? BarterMenu.BUY : BarterMenu.SELL;
         this.BottomBar_mc.CreateButton(0, actionBtn);
      }
      else
      {
         this.BottomBar_mc.CreateButton(0, BarterMenu.EXIT);
         this.BottomBar_mc.CreateButton(1, BarterMenu.SWITCH);
         this.BottomBar_mc.CreateButton(2, BarterMenu.SEARCH);

         if (this._platform != 0)
         {
            this.BottomBar_mc.CreateButton(3, BarterMenu.SORT);
            this.BottomBar_mc.CreateButton(4, BarterMenu.ORDER);
         }
      }

      this.BottomBar_mc.PositionButtons();
   }
}
