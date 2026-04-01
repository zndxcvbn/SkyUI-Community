class GiftMenu extends ItemMenu
{
   var _categoryListIconArt;
   var _platform;
   var BottomBar_mc;
   var inventoryLists;
   static var SKYUI_RELEASE_IDX = 2018;
   static var SKYUI_VERSION_MAJOR = 5;
   static var SKYUI_VERSION_MINOR = 2;
   static var SKYUI_VERSION_STRING = GiftMenu.SKYUI_VERSION_MAJOR + "." + GiftMenu.SKYUI_VERSION_MINOR + " SE";
   var _bGivingGifts = true;

   static var EXIT:   Object = {Label: "$Exit",   PCArt: "Tab",   XBoxArt: "360_B",  PS3Art: "PS3_B"};
   static var SEARCH: Object = {Label: "$Search", PCArt: "Space", XBoxArt: "",       PS3Art: ""};
   static var GIVE:   Object = {Label: "$Give",   PCArt: "E",     XBoxArt: "360_A",  PS3Art: "PS3_A"};
   static var TAKE:   Object = {Label: "$Take",   PCArt: "E",     XBoxArt: "360_A",  PS3Art: "PS3_A"};
   static var SORT:   Object = {Label: "$Sort",   PCArt: "",      XBoxArt: "360_RS", PS3Art: "PS3_RS"};
   static var ORDER:  Object = {Label: "$Order",  PCArt: "",      XBoxArt: "360_LS", PS3Art: "PS3_LS"};

   function GiftMenu()
   {
      super();
      this._categoryListIconArt = ["inv_all","inv_weapons","inv_armor","inv_potions","inv_scrolls","inv_food","inv_ingredients","inv_books","inv_keys","inv_misc"];
   }
   function InitExtensions()
   {
      super.InitExtensions();
      gfx.io.GameDelegate.addCallBack("SetMenuInfo",this,"SetMenuInfo");
      var _loc3_ = this.inventoryLists.categoryList;
      _loc3_.iconArt = this._categoryListIconArt;
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
   function ShowItemsList()
   {
   }
   function SetMenuInfo(a_bGivingGifts, a_bUseFavorPoints)
   {
      this._bGivingGifts = a_bGivingGifts;
      if(!a_bUseFavorPoints)
      {
         this.BottomBar_mc.HidePlayerInfo();
      }
   }
   function UpdatePlayerInfo(a_favorPoints)
   {
      this.BottomBar_mc.SetGiftInfo(a_favorPoints);
   }
   function onShowItemsList(event)
   {
      var _loc2_ = this.inventoryLists.categoryList;
      _loc2_.selectedIndex = 0;
      _loc2_.entryList[0].text = "$ALL";
      _loc2_.InvalidateData();
      this.inventoryLists.showItemsList();
      this.UpdateBottomBar(false);
   }
   function onHideItemsList(event)
   {
      super.onHideItemsList(event);
      this.BottomBar_mc.UpdatePerItemInfo({type:skyui.defines.Inventory.ICT_NONE});
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
   function onItemCardSubMenuAction(event)
   {
      super.onItemCardSubMenuAction(event);
      if(event.menu == "quantity")
      {
         gfx.io.GameDelegate.call("QuantitySliderOpen",[event.opening]);
      }
   }
   function UpdateBottomBar(a_bSelected)
   {
      this.BottomBar_mc.HideButtons();

      if(a_bSelected)
      {
         var actionBtn = !this._bGivingGifts ? GiftMenu.TAKE : GiftMenu.GIVE;
         this.BottomBar_mc.CreateButton(0, actionBtn);
      }
      else
      {
         this.BottomBar_mc.CreateButton(0, GiftMenu.EXIT);
         this.BottomBar_mc.CreateButton(1, GiftMenu.SEARCH);

         if (this._platform != 0)
         {
            this.BottomBar_mc.CreateButton(2, GiftMenu.SORT);
            this.BottomBar_mc.CreateButton(3, GiftMenu.ORDER);
         }
      }

      this.BottomBar_mc.PositionButtons();
   }
}
