class BarterMenu extends ItemMenu
{
   var _cancelControls;
   var _categoryListIconArt;
   var _platform;
   var _searchControls;
   var _sortColumnControls;
   var _sortOrderControls;
   var _switchControls;
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

   var ExitBtn:   Object;
   var SearchBtn: Object;
   var SwitchBtn: Object;
   var BuyBtn:    Object;
   var SellBtn:   Object;
   var SortBtn:   Object;
   var OrderBtn:  Object;
   var AcceptBtn: Object;
   var CancelBtn: Object;

   function BarterMenu()
   {
      super();
      this._categoryListIconArt = ["inv_all","inv_weapons","inv_armor","inv_potions","inv_scrolls","inv_food","inv_ingredients","inv_books","inv_keys","inv_misc"];
      this._tabBarIconArt = ["buy","sell"];
      this.InitBottomBarBtns();
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
         var actionBtn = this.IsViewingVendorItems() ? this.BuyBtn : this.SellBtn;
         this.BottomBar_mc.CreateButton(0, actionBtn);
      }
      else
      {
         this.BottomBar_mc.CreateButton(0, this.ExitBtn);
         this.BottomBar_mc.CreateButton(1, this.SwitchBtn);
         this.BottomBar_mc.CreateButton(2, this.SearchBtn);

         if (this._platform != 0)
         {
            this.BottomBar_mc.CreateButton(3, this.SortBtn);
            this.BottomBar_mc.CreateButton(4, this.OrderBtn);
         }
      }

      this.BottomBar_mc.PositionButtons();
   }
   function InitBottomBarBtns()
   {
      this.ExitBtn   = {text: "$Exit",       PCArt: "Tab",   XBoxArt: "360_B",    PS3Art: "PS3_B"};
      this.SearchBtn = {text: "$Search",     PCArt: "Space", XBoxArt: "",         PS3Art: ""};
      this.SwitchBtn = {text: "$Switch Tab", PCArt: "L-Alt", XBoxArt: "360_LB",   PS3Art: "PS3_L1"};
      
      this.BuyBtn    = {text: "$Buy",        PCArt: "E",     XBoxArt: "360_A",    PS3Art: "PS3_A"};
      this.SellBtn   = {text: "$Sell",       PCArt: "E",     XBoxArt: "360_A",    PS3Art: "PS3_A"};
      
      this.SortBtn   = {text: "$Sort",       PCArt: "",      XBoxArt: "360_RS",   PS3Art: "PS3_RS"};
      this.OrderBtn  = {text: "$Order",      PCArt: "",      XBoxArt: "360_LS",   PS3Art: "PS3_LS"};
      
      this.AcceptBtn = {text: "$Select",     PCArt: "Enter", XBoxArt: "360_A",    PS3Art: "PS3_A"};
      this.CancelBtn = {text: "$Cancel",     PCArt: "Tab",   XBoxArt: "360_B",    PS3Art: "PS3_B"};
   }
}
