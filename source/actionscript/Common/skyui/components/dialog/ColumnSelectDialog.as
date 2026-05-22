class skyui.components.dialog.ColumnSelectDialog extends skyui.components.dialog.BasicDialog
{	
  /* STAGE ELEMENTS */
  
	public var list: ButtonList;
	
	
  /* PROPERTIES */
	
	public var layout: ListLayout;
	
	
  /* CONSTRUCTORS */
  
	public function ColumnSelectDialog()
	{
		super();
	}
	
	
  /* PUBLIC FUNCTIONS */
	
	// Constructor is too early to do anything with the embedded list if the Movie is created with attachMovie.
	public function onLoad()
	{
		this.list.listEnumeration = new skyui.components.list.BasicEnumeration(this.list.entryList);
		
		this.list.addEventListener("itemPress", this, "onColumnToggle");
		this.layout.addEventListener("layoutChange", this, "onLayoutChange");
		
		this.setColumnListData();
	}
	
	public function onDialogOpening()
	{
		gfx.io.GameDelegate.call("PlaySound", ["UIMenuBladeOpenSD"]);
		gfx.managers.FocusHandler.instance.setFocus(this.list, 0);
	}
	
	public function onDialogClosing()
	{
		gfx.io.GameDelegate.call("PlaySound",["UIMenuBladeCloseSD"]);
		this.layout.removeEventListener("layoutChange", this, "onLayoutChange");
	}
	
	public function onColumnToggle(event: Object)
	{
		var entry = event.entry;
		skyui.util.ConfigManager.setOverride("ListLayout", "columns." + entry.id + ".hidden", !entry.value, entry.value ? "false" : "true");
	}
	
	public function onLayoutChange(event: Object)
	{
		this.setColumnListData();
	}
	
	// @GFx
	public function handleInput(details: InputDetails, pathToFocus: Array)
	{	
		if (Shared.GlobalFunc.IsKeyPressed(details)) {
			if (details.navEquivalent == gfx.ui.NavigationCode.TAB || details.navEquivalent == gfx.ui.NavigationCode.ESCAPE ||
					details.navEquivalent == gfx.ui.NavigationCode.LEFT || details.navEquivalent == gfx.ui.NavigationCode.RIGHT) {
				skyui.util.DialogManager.close();
				return true;
			}
		}
			
		var nextClip = pathToFocus.shift();
		return nextClip.handleInput(details, pathToFocus);
	}
	
	public function onMouseDown()
	{
		for (var e = Mouse.getTopMostEntity(); e != undefined; e = e._parent)
			if (e == this)
				return;
		skyui.util.DialogManager.close();
	}
	
	
  /* PRIVATE FUNCTIONS */
	
	private function setColumnListData()
	{
		this.list.clearList();
		
		var columnDescriptors = this.layout.columnDescriptors;
		
		for (var i = 0; i < columnDescriptors.length; i++) {
			var col = columnDescriptors[i];
			
			if (col.type == skyui.components.list.ListLayout.COL_TYPE_TEXT)
				this.list.entryList.push({enabled: true, text: col.longName, value: col.hidden, state: (col.hidden ? "off" : "on"), id: col.identifier});
		}
		
		this.list.InvalidateData();
	}
}
