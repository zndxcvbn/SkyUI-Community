// @abstract
class ItemcardDataExtender implements skyui.components.list.IListProcessor
{
  /* PRIVATE VARIABLES */

    private var _itemInfo: Object;
    private var _requestItemInfo: Function;


  /* INITIALIZATION */
    
    public function ItemcardDataExtender()
    {
        this._requestItemInfo = function(a_target: Object, a_index: Number)
        {
            var oldIndex = this._selectedIndex;
            this._selectedIndex = a_index;
            gfx.io.GameDelegate.call("RequestItemCardInfo", [], a_target, "updateItemInfo");
            this._selectedIndex = oldIndex;
        };
    }
    
    
  /* PUBLIC FUNCTIONS */
    
    public function updateItemInfo(a_updateObj: Object)
    {
        this._itemInfo = a_updateObj;
    }
    
    // @override IListProcessor
    public function processList(a_list: BasicList)
    {
        var entryList = a_list.entryList;
        var entryLen = entryList.length;

        // The game's only signal for "entry changed" is clearing
        // skyui_itemDataProcessed on the changed entry. We scan once to find
        // those (irreducible cost). The scan also publishes the dirty entries
        // on the list, so downstream processors (icon/property extenders) don't
        // each re-scan the full entryList -- they consume this small set.
        var dirty = [];

        // Reverse iteration: AVM1's pre-decrement + compare-to-zero is one op
        // cheaper than forward i++ with bounds-compare. Steady-state hot path
        // (all entries already processed) just reads the flag and continues,
        // so per-iter overhead is the dominant cost.
        //
        // Order safety: dirty handling is per-entry (each iter writes only on
        // its own `e`), and the inner `_requestItemInfo` -> `processEntry`
        // pair is synchronous (game-side `updateItemInfo` lands inline before
        // the next iter). Downstream consumers of `dirty` (PropertyDataExtender,
        // FilteredEnumeration via markDataDirty) are order-agnostic.
        for (var i = entryLen; --i >= 0; ) {
            var e = entryList[i];

            // Truthy check instead of == true: in steady state this hot path
            // runs ~775 times per call doing nothing else, so saving one
            // compare per iter pays back. The flag is only ever written as
            // boolean true (here); game-side clear sets undefined/false --
            // both falsy.
            if (e.skyui_itemDataProcessed)
                continue;

            // Mark as seen so the next InvalidateData doesn't re-add this entry
            // to dirty just because nothing ever set the flag (filterFlag==0
            // entries would otherwise leak in every call).
            e.skyui_itemDataProcessed = true;
            e.skyui_iconProcessed = false;
            e.skyui_propsProcessed = false;
            // Mark for re-render so the next UpdateList won't skip this clip
            // via the same-entry-no-change fast path.
            e.skyui_renderDirty = true;
            dirty.push(e);

            // Skip own (expensive, SKSE round-trip) processing for entries that
            // belong to no visible category -- matches the original behavior.
            // Downstream processors still see them via the dirty list, just as
            // they were seen by their full scans before.
            if (e.filterFlag == 0)
                continue;

            this.fixSKSEExtendedObject(e);

            // Hack to retrieve itemcard info
            this._requestItemInfo.apply(a_list, [this, i]);
            this.processEntry(e, this._itemInfo);
        }

        a_list.skyui_dirtyEntries = dirty;
    }


  /* PRIVATE FUNCTIONS */
    
    // @abstract
    private function processEntry(a_entryObject: Object, a_itemInfo: Object) {}

    private function fixSKSEExtendedObject(a_extendedObject: Object)
    {
        if (a_extendedObject.formType == undefined)
            return;

        switch(a_extendedObject.formType) {
            case skyui.defines.Form.TYPE_SPELL:
            case skyui.defines.Form.TYPE_SCROLLITEM:
            case skyui.defines.Form.TYPE_INGREDIENT:
            case skyui.defines.Form.TYPE_POTION:
            case skyui.defines.Form.TYPE_EFFECTSETTING:

                // school is sent as subType
                if (a_extendedObject.school == undefined && a_extendedObject.subType != undefined) {
                    a_extendedObject.school = a_extendedObject.subType;
                    delete(a_extendedObject.subType);
                }

                // resistance is sent as magicType
                if (a_extendedObject.resistance == undefined && a_extendedObject.magicType != undefined) {
                    a_extendedObject.resistance = a_extendedObject.magicType;
                    delete(a_extendedObject.magicType);
                }

                // primaryValue is sent as actorValue
                /* // Ignore
                if (a_extendedObject.primaryValue == undefined && a_extendedObject.actorValue != undefined) {
                    a_extendedObject.primaryValue = a_extendedObject.actorValue;
                    delete(a_extendedObject.actorValue);
                }
                */
                break;

            case skyui.defines.Form.TYPE_WEAPON:
                // weaponType is sent as subType
                if (a_extendedObject.weaponType == undefined && a_extendedObject.subType != undefined) {
                    a_extendedObject.weaponType = a_extendedObject.subType;
                    delete(a_extendedObject.subType);
                }
                break;

            case skyui.defines.Form.TYPE_BOOK:
                // (SKSE < 1.6.6) flags and bookType (and some padding) are sent as one UInt32 bookType
                if (a_extendedObject.flags == undefined && a_extendedObject.bookType != undefined) {
                    var oldBookType: Number = a_extendedObject.bookType;
                    a_extendedObject.bookType	= (oldBookType & 0xFF00) >>> 8;
                    a_extendedObject.flags		= (oldBookType & 0x00FF);
                }
                break;

            default:
                break;
        }

    }
}
