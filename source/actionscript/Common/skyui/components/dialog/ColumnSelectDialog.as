/*
 *  Dropdown checkbox dialog. Runs in one of two modes, chosen by the init
 *  object passed to DialogManager.open():
 *
 *   - Column mode (init has "layout"): toggles which columns are shown.
 *   - Value mode  (init has "valueFilter" + "valueEntries"): toggles which
 *     values of a single column are shown, driving a ColumnValueFilter.
 */
class skyui.components.dialog.ColumnSelectDialog extends skyui.components.dialog.BasicDialog
{
  /* STAGE ELEMENTS */

    public var list: ButtonList;


  /* PROPERTIES */

    // Column mode
    public var layout: ListLayout;

    // Value mode (set via the init object)
    public var valueFilter: skyui.filter.ColumnValueFilter;
    public var valueEntries: Array;


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

        if (this.valueFilter != undefined) {
            // Value mode: grow the list rightwards so it drops down under the column.
            this.list.align = "LEFT";
            this.setValueListData();
        } else {
            this.layout.addEventListener("layoutChange", this, "onLayoutChange");
            this.setColumnListData();
        }
    }

    public function onDialogOpening()
    {
        gfx.io.GameDelegate.call("PlaySound",["UIMenuBladeOpenSD"]);
        gfx.managers.FocusHandler.instance.setFocus(this.list, 0);
    }

    public function onDialogClosing()
    {
        gfx.io.GameDelegate.call("PlaySound",["UIMenuBladeCloseSD"]);

        if (this.layout != undefined)
            this.layout.removeEventListener("layoutChange", this, "onLayoutChange");
    }

    public function onColumnToggle(event: Object)
    {
        var entry = event.entry;

        // Value mode: entry.value holds the "hidden" state for this value.
        if (this.valueFilter != undefined) {
            if (entry.id == "__clear__") {
                this.valueFilter.resetActiveColumn();
                this.valueFilter.dispatchEvent({type: "filterChange"});
                skyui.util.DialogManager.close();
                return;
            }

            entry.value = !entry.value;
            entry.state = entry.value ? "off" : "on";
            this.valueFilter.setValueHidden(entry.id, entry.value);
            this.list.InvalidateData();
            return;
        }

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

        var columnDescriptors = this.layout.getViewColumnDescriptors();

        for (var i = 0; i < columnDescriptors.length; i++) {
            var col = columnDescriptors[i];

            if (col.type == skyui.components.list.ListLayout.COL_TYPE_TEXT)
                this.list.entryList.push({enabled: true, text: col.longName, value: col.hidden, state: (col.hidden ? "off" : "on"), id: col.identifier});
        }

        this.list.InvalidateData();
    }

    private function setValueListData()
    {
        this.list.clearList();

        for (var i = 0; i < this.valueEntries.length; i++) {
            var v = this.valueEntries[i];
            this.list.entryList.push({enabled: true, text: v.text, value: v.hidden, state: (v.hidden ? "off" : "on"), id: v.key});
        }
        
        // Clear button
        this.list.entryList.push({
            enabled: true, 
            text: "Clear", 
            id: "__clear__", 
            state: "hide",
            textColor: 0xFF5050,
            indicatorColor: 0x990000
        });

        this.list.InvalidateData();
    }
}
