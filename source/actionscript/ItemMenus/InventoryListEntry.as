class InventoryListEntry extends skyui.components.list.TabularListEntry
{
  /* CONSTANTS */

    private static var STATES = ["None", "Equipped", "LeftEquip", "RightEquip", "LeftAndRightEquip"];


  /* PRIVATE VARIABLES */

    private var _iconLabel: String;
    private var _iconColor: Number;

    // Cached state-icon size. Depends only on layout (entryHeight), so
    // setSpecificEntryLayout (which runs on layout change) computes it once;
    // updateSpecificEntryState reuses it on every per-entry refresh.
    private var _stateIconSize: Number;


  /* STAGE ELEMENTS */

    public var itemIcon: MovieClip;
    public var equipIcon: MovieClip;

    public var stateIcons: MovieClip;


  /* CONSTRUCTOR */

    function InventoryListEntry()
    {
        super();
    }


  /* INITIALIZATION */
   
    // @override TabularListEntry
    public function initialize(a_index: Number, a_state: ListState)
    {
        super.initialize();

        var iconLoader = new MovieClipLoader();
        iconLoader.addListener(this);
        iconLoader.loadClip(a_state.iconSource, this.itemIcon);

        this.itemIcon._visible = false;
        this.equipIcon._visible = false;        

        for (var i = 0; this["textField" + i] != undefined; i++)
            this["textField" + i]._visible = false;
    }
   
   
  /* PUBLIC FUNCTIONS */

    // @override TabularListEntry
    public function setSpecificEntryLayout(a_entryObject: Object, a_state: ListState)
    {
        var entryH = skyui.components.list.TabularList(a_state.list).layout.entryHeight;
        this._stateIconSize = entryH * 0.5;

        this.stateIcons.background._height = entryH;
        this.stateIcons._y = (entryH - this._stateIconSize) / 2;
    }

    // @override TabularListEntry
    // Status icons (equipped, stolen, read, etc.) depend on the bound entry,
    // not on layout. Refresh them on every setEntry so scroll/rebind picks
    // up the new entry's state instead of leaving the previous entry's icons
    // stuck on the clip.
    public function updateSpecificEntryState(a_entryObject: Object, a_state: ListState)
    {
        skyui.components.list.StateIcons.updateStatuses(this.stateIcons, a_entryObject, a_state.showStolenIcon, this._stateIconSize);
    }

    // @override TabularListEntry
    public function formatEquipIcon(a_entryField: Object, a_entryObject: Object, a_state: ListState)
    {
        if (a_entryObject != undefined && a_entryObject.equipState != undefined) {
            a_entryField.gotoAndStop(InventoryListEntry.STATES[a_entryObject.equipState]);
        } else {
            a_entryField.gotoAndStop("None");
        }
    }

    // @override TabularListEntry
    public function formatItemIcon(a_entryField: Object, a_entryObject: Object, a_state: ListState)
    {
        this._iconLabel = a_entryObject["iconLabel"] != undefined ? a_entryObject["iconLabel"] : "default_misc";
        this._iconColor = a_entryObject["iconColor"];

        // Could return here if _iconLoaded is false
        a_entryField.gotoAndStop(this._iconLabel);
        this.changeIconColor(MovieClip(a_entryField), this._iconColor);
    }

    // @override TabularListEntry
    public function formatName(a_entryField: Object, a_entryObject: Object, a_state: ListState)
    {
        var nameText: String = a_entryObject.displayName != undefined ? a_entryObject.displayName : " ";

        a_entryField.autoSize = "left";
        a_entryField.SetText(nameText);
        this.formatColor(a_entryField, a_entryObject, a_state);
        
        this.stateIcons._x = a_entryField._x + a_entryField.textWidth + 10;
    }

    // @override TabularEntry
    public function formatText(a_entryField: Object, a_entryObject: Object, a_state: ListState)
    {
        this.formatColor(a_entryField, a_entryObject, a_state);
        a_entryField.autoSize = a_entryField.getTextFormat().align;
    }


  /* PRIVATE FUNCTIONS */

    // @implements MovieClipLoader
    private function onLoadInit(a_icon: MovieClip)
    {
        a_icon.gotoAndStop(this._iconLabel);
        this.changeIconColor(a_icon, this._iconColor);
    }

    private function formatColor(a_entryField: Object, a_entryObject: Object, a_state: ListState)
    {
        // Negative Effect
        if (a_entryObject.negativeEffect == true)
            a_entryField.textColor = a_entryObject.enabled == false ? a_state.negativeDisabledColor : a_state.negativeEnabledColor;
            
        // Stolen
        else if (a_entryObject.infoIsStolen == true || a_entryObject.isStealing == true)
            a_entryField.textColor = a_entryObject.enabled == false ? a_state.stolenDisabledColor : a_state.stolenEnabledColor;
            
        // Default
        else
            a_entryField.textColor = a_entryObject.enabled == false ? a_state.defaultDisabledColor : a_state.defaultEnabledColor;
    }

    private function changeIconColor(a_icon: MovieClip, a_rgb: Number)
    {
        var ct = new flash.geom.ColorTransform();
        ct.rgb = (a_rgb == undefined) ? 0xFFFFFF : a_rgb;
        
        var tf = new flash.geom.Transform(a_icon);
        tf.colorTransform = ct;
    }
}
