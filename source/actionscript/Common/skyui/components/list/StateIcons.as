class skyui.components.list.StateIcons
{
    private static var _rules: Array = [
        { clipName: "bestIcon",     checkFunc: function(obj, showStolen) { return obj.bestInClass == true; } },
        { clipName: "favoriteIcon", checkFunc: function(obj, showStolen) { return obj.favorite == true; } },
        { clipName: "poisonIcon",   checkFunc: function(obj, showStolen) { return obj.isPoisoned == true; } },
        { clipName: "stolenIcon",   checkFunc: function(obj, showStolen) { return showStolen && (obj.isStolen == true || obj.isStealing == true); } },
        { clipName: "enchIcon",     checkFunc: function(obj, showStolen) { return obj.isEnchanted == true; } },
        { clipName: "readIcon",     checkFunc: function(obj, showStolen) { return obj.isRead == true; } }
    ];


  /* PUBLIC FUNCTIONS */

    public static function registerRule(a_clipName: String, a_checkFunc: Function, a_linkageId: String)
    {
        if (skyui.components.list.StateIcons._rules == undefined)
            skyui.components.list.StateIcons._rules = [];
            
        for (var i: Number = 0; i < skyui.components.list.StateIcons._rules.length; i++) {
            if (skyui.components.list.StateIcons._rules[i].clipName == a_clipName) {
                skyui.components.list.StateIcons._rules[i].checkFunc = a_checkFunc;
                if (a_linkageId != undefined)
                    skyui.components.list.StateIcons._rules[i].linkageId = a_linkageId;
                return;
            }
        }
        
        skyui.components.list.StateIcons._rules.push({
            clipName: a_clipName,
            checkFunc: a_checkFunc,
            linkageId: a_linkageId
        });
    }

    public static function updateStatuses(a_bar: MovieClip, a_entryObject: Object, a_showStolen: Boolean, a_iconSize: Number)
    {
        if (a_bar == undefined || a_entryObject == undefined)
            return;

        var activeIcons: Array = [];
        
        for (var i: Number = 0; i < skyui.components.list.StateIcons._rules.length; i++) {
            var rule: Object = skyui.components.list.StateIcons._rules[i];
            var clip: MovieClip = a_bar[rule.clipName];
            
            if (clip == undefined && rule.linkageId != undefined) {
                var depth: Number = a_bar.getNextHighestDepth();
                clip = a_bar.attachMovie(rule.linkageId, rule.clipName, depth);
            }

            if (clip != undefined) {
                activeIcons.push(clip);
                
                var isShow: Boolean = rule.checkFunc(a_entryObject, a_showStolen);
                skyui.components.list.StateIcons.setIconState(clip, isShow, a_iconSize);
            }
        }
        
        a_bar.background.JustifyContent(activeIcons, "flex-start", 5);
    }

    private static function setIconState(a_icon: MovieClip, a_show: Boolean, a_size: Number)
    {
        if (a_icon == undefined) return;

        if (a_show)
        {
            a_icon._visible = true;
            a_icon.gotoAndStop("show");

            if (a_size != undefined)
                a_icon._width = a_icon._height = a_size;
        }
        else
        {
            a_icon.gotoAndStop("hide");
            a_icon._visible = false;
        }
    }
}
