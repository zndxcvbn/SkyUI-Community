class skyui.util.ConfigManager
{
  /* CONSTANTS */

    private static var CONFIG_PATH = "skyui/config.txt";
    private static var TIMEOUT = 3000;
    
    private static var LOAD_NONE = 0;
    private static var LOAD_FILE = 1;
    private static var LOAD_PAPYRUS = 2;
    
    
  /* PRIVATE VARIABLES */

    private static var _constantTable: Object = {
        
        ASCENDING: 0,
        DESCENDING: Array.DESCENDING,
        CASEINSENSITIVE: Array.CASEINSENSITIVE,
        NUMERIC: Array.NUMERIC
    };
    
    // Contains names of classes
    private static var _extConstantTableNames: Array = [];
    // Contains the actual classes.
    private static var _extConstantTables: Object = {};
    
    private static var _eventDummy: Object;
    
    // LOAD_NONE: waiting for file, LOAD_FILE: file parsed (waiting for Papyrus), LOAD_PAPYRUS: fully loaded
    private static var _loadPhase: Number = skyui.util.ConfigManager.LOAD_NONE;
    
    private static var _config: Object;
    
    private static var _timeoutID: Number;
    
    
  /* INITIALIATZION */

    private static var _initialized:Boolean = skyui.util.ConfigManager.initialize();

    private static function initialize()
    {
        skyui.util.GlobalFunctions.addArrayFunctions();
        
        skyui.util.ConfigManager._eventDummy = {};
        gfx.events.EventDispatcher.initialize(skyui.util.ConfigManager._eventDummy);
        
        var lv = new LoadVars();
        lv.onData = skyui.util.ConfigManager.parseData;
        lv.load(skyui.util.ConfigManager.CONFIG_PATH);
        
        return true;
    }
    
    
  /* PAPYRUS INTERFACE */

    // Key/value pairs "Section$k$e$y$" / "value"
    public static var out_overrides = {};
    public static var in_overrideKeys = [];
    
    public static function setExternalOverrideKeys()
    {
        skyui.util.ConfigManager.in_overrideKeys.splice(0);
        
        for (var i = 0; i < arguments.length; i++)
            skyui.util.ConfigManager.in_overrideKeys[i] = arguments[i];
    }
    
    public static function setExternalOverrideValues()
    {
        // Received overrides before file? This can't be right.
        if (skyui.util.ConfigManager._loadPhase == skyui.util.ConfigManager.LOAD_NONE)
            return;
        
        // Update happens in 2 phases.
        // First the keys are sent and stored, then the values are sent and immediately processed.
        for (var i = 0; i < arguments.length; i++) {
            var t = skyui.util.ConfigManager.in_overrideKeys[i];
            if (t && t != "")
                skyui.util.ConfigManager.parseExternalOverride(t, arguments[i]);
        }
        
        if (skyui.util.ConfigManager._loadPhase != skyui.util.ConfigManager.LOAD_PAPYRUS) {
            clearInterval(skyui.util.ConfigManager._timeoutID);
            delete skyui.util.ConfigManager._timeoutID;
            
            skyui.util.ConfigManager._loadPhase = skyui.util.ConfigManager.LOAD_PAPYRUS;
            skyui.util.ConfigManager._eventDummy.dispatchEvent({type: "configLoad", config: skyui.util.ConfigManager._config});			
        } else {
            // Timeout
            skyui.util.ConfigManager._eventDummy.dispatchEvent({type: "configUpdate", config: skyui.util.ConfigManager._config});
        }
    }
    
    
  /* PUBLIC FUNCTIONS */

    public static function registerLoadCallback(a_scope: Object, a_callBack: String)
    {
        skyui.util.ConfigManager._eventDummy.addEventListener("configLoad", a_scope, a_callBack);
    }
    
    public static function registerUpdateCallback(a_scope: Object, a_callBack: String)
    {
        skyui.util.ConfigManager._eventDummy.addEventListener("configUpdate", a_scope, a_callBack);
    }
    
    public static function setConstant(a_name: String, a_value)
    {
        var type = typeof(a_value);
        if (type != "number" && type != "boolean" && type != "string")
            return;
        
        skyui.util.ConfigManager._constantTable[a_name] = a_value;
    }
    
    
    public static function addConstantTable(a_name: String, a_class: Function)
    {
        skyui.util.ConfigManager._extConstantTableNames.push(a_name);
    }
    
    public static function getConstant(a_name: String)
    {
        if (skyui.util.ConfigManager._constantTable[a_name] != undefined)
            return skyui.util.ConfigManager._constantTable[a_name];
        
        var a: Array = a_name.split(".");

        if (a.length < 2)
            return undefined;

        var className: String = a[a.length - 2];
        var constName: String = a[a.length - 1];

        if (skyui.util.ConfigManager._extConstantTables[className][constName] != undefined)
            return skyui.util.ConfigManager._extConstantTables[className][constName];

        return undefined;
    }
    
    public static function setOverride(a_section: String, a_key: String, a_value, a_valueStr: String)
    {
        // Allow to add new sections
        if (skyui.util.ConfigManager._config[a_section] == undefined)
            skyui.util.ConfigManager._config[a_section] = {};

        var sectionObj = skyui.util.ConfigManager._config[a_section];
        var parts = a_key.split(".");

        // Capture the var container before the walk creates intermediate sections.
        var varContainer = skyui.util.ConfigManager.getVarContainer(sectionObj, parts);

        // Store value in config at section.a.b.c
        var loc = skyui.util.ConfigManager.resolveContainer(sectionObj, parts);
        loc[parts[parts.length - 1]] = a_value;

        // UI functions would try to look up keys.a.b.c, instead of keys["a.b.c"].
        // . -> $
        var ovrKey = a_section + "$" + parts.join("$");
        skyui.util.ConfigManager.out_overrides[ovrKey] = a_valueStr;
        skse.SendModEvent("SKICO_setConfigOverride", ovrKey);

        // If we changed the value of a var, update all recorded references.
        skyui.util.ConfigManager.updateVarReferences(varContainer, a_value);

        skyui.util.ConfigManager._eventDummy.dispatchEvent({type: "configUpdate", config: skyui.util.ConfigManager._config});
    }
    
    // (Unsafe) Provide static accessor to the config to retrieve trivial values
    /*
    public static function getValue(a_section: String, a_key: String)
    {
        if (skyui.util.ConfigManager._loadPhase < skyui.util.ConfigManager.LOAD_PAPYRUS)
            return null;
        
        var a = a_key.split(".");
        var loc = skyui.util.ConfigManager._config[a_section];
        for (var j = 0; j < a.length; j++) {
            if (loc[a[j]] == undefined)
                return null;
            loc = loc[a[j]];
        }
        
        return loc;
    }*/


  /* PRIVATE FUNCTIONS */

    // Returns the var container for a key path (section.vars.<name>), or null
    // if the path does not reference a config variable.
    private static function getVarContainer(a_sectionObj: Object, a_parts: Array)
    {
        if (a_parts[0] == "vars")
            return a_sectionObj.vars[a_parts[1]];

        return null;
    }

    // Walks the key path, creating missing intermediate sections, and returns
    // the container that holds the leaf key (a_parts[a_parts.length - 1]).
    private static function resolveContainer(a_sectionObj: Object, a_parts: Array)
    {
        var loc = a_sectionObj;
        for (var j = 0; j < a_parts.length - 1; j++) {
            if (loc[a_parts[j]] == undefined)
                loc[a_parts[j]] = {};
            loc = loc[a_parts[j]];
        }
        return loc;
    }

    // Re-applies a new value to every location that referenced this config var.
    private static function updateVarReferences(a_varContainer: Object, a_value)
    {
        if (!a_varContainer)
            return;

        for (var i = 0; i < a_varContainer._refLocs.length; i++) {
            var varLoc = a_varContainer._refLocs[i];
            var varKey = a_varContainer._refKeys[i];
            varLoc[varKey] = a_value;
        }
    }

    private static function parseExternalOverride(a_key: String, a_valueStr: String)
    {
        var index = a_key.indexOf("$");

        // raw key: section$k$e$y
        var section = skyui.util.GlobalFunctions.clean(a_key.slice(0, index));
        var key = skyui.util.GlobalFunctions.clean(a_key.slice(index + 1));
        var val = skyui.util.ConfigManager.parseValueString(skyui.util.GlobalFunctions.clean(a_valueStr), null);

        var sectionObj = skyui.util.ConfigManager._config[section];
        // External keys use $ as separator
        var parts = key.split("$");

        // Capture the var container before the walk creates intermediate sections.
        var varContainer = skyui.util.ConfigManager.getVarContainer(sectionObj, parts);

        var loc = skyui.util.ConfigManager.resolveContainer(sectionObj, parts);
        loc[parts[parts.length - 1]] = val;

        // If we changed the value of a var, update all recorded references.
        skyui.util.ConfigManager.updateVarReferences(varContainer, val);
    }

    private static function parseData(a_data: String)
    {
        skyui.util.ConfigManager._config = {};
        
        // Resolve constant tables
        for (var i = 0; i < skyui.util.ConfigManager._extConstantTableNames.length; i++) {
            var a = skyui.util.ConfigManager._extConstantTableNames[i].split(".");
            var className: String = a[a.length - 1];
            var tbl = _global[a[0]];
            for (var j = 1; j < a.length; j++)
                tbl = tbl[a[j]];
            skyui.util.ConfigManager._extConstantTables[className] = tbl;
        }
        
        var lines = a_data.split("\r\n");
        if (lines.length == 1)
            lines = a_data.split("\n");

        var section = undefined;

        for (var i = 0; i < lines.length; i++) {

            // Comment
            if (lines[i].charAt(0) == ";")
                continue;

            // Section start
            if (lines[i].charAt(0) == "[") {
                section = lines[i].slice(1, lines[i].lastIndexOf("]"));
                
                if (skyui.util.ConfigManager._config[section] == undefined)
                    skyui.util.ConfigManager._config[section] = {};
                    
                continue;
            }

            if (lines[i].length < 3 || section == undefined)
                continue;
            
            // Get raw key string
            var key = skyui.util.GlobalFunctions.clean(lines[i].slice(0, lines[i].indexOf("=")));
            if (key == undefined)
                continue;
                
            // Prepare key subsections
            var parts = key.split(".");
            var sectionObj = skyui.util.ConfigManager._config[section];
            var loc = skyui.util.ConfigManager.resolveContainer(sectionObj, parts);

            // Detect value type & extract
            var val = skyui.util.ConfigManager.parseValueString(skyui.util.GlobalFunctions.clean(lines[i].slice(lines[i].indexOf("=") + 1)), sectionObj, loc, parts[parts.length - 1]);

            if (val == undefined)
                continue;

            // Store val at config.section.a.b.c.d
            loc[parts[parts.length - 1]] = val;
        }
        
        skyui.util.ConfigManager._loadPhase = skyui.util.ConfigManager.LOAD_FILE;
        skyui.util.ConfigManager._timeoutID = setInterval(skyui.util.ConfigManager.onTimeout, skyui.util.ConfigManager.TIMEOUT);
        
//		_eventDummy.dispatchEvent({type: "configLoad", config: _config});
    }
    
    private static function onTimeout()
    {
        clearInterval(skyui.util.ConfigManager._timeoutID);
        delete skyui.util.ConfigManager._timeoutID;

        if (skyui.util.ConfigManager._loadPhase != skyui.util.ConfigManager.LOAD_PAPYRUS) {
            skyui.util.ConfigManager._loadPhase = skyui.util.ConfigManager.LOAD_PAPYRUS;
            skyui.util.ConfigManager._eventDummy.dispatchEvent({type: "configLoad", config: skyui.util.ConfigManager._config});
        }
    }
    
    // Resolution precedence (first match wins):
    //   number -> bool ("true"/"false", case-insensitive) -> "undefined"
    //   -> '...' explicit string -> @prop entry-property
    //   -> <k:v,...> assoc array -> <...> list -> {a|b|c} flags
    //   -> registered constant -> config var -> default string
    private static function parseValueString(a_str: String, a_root: Object, a_loc: Object, a_key: String)
    {
        if (a_str == undefined)
            return undefined;

        // Number?
        if (!isNaN(a_str))
            return Number(a_str);

        var lower: String = a_str.toLowerCase();
        if (lower == "true")
            return true;
        if (lower == "false")
            return false;
        if (lower == "undefined")
            return undefined;

        var firstChar: String = a_str.charAt(0);

        // Explicit String?
        if (firstChar == "'")
            return skyui.util.GlobalFunctions.extract(a_str, "'", "'");

        // Entry property - substituted later
        if (firstChar == "@")
            return a_str;

        // Associative array?
        if (firstChar == "<" && a_str.indexOf(":") != -1)
            return skyui.util.ConfigManager.parseAssoc(a_str, a_root);

        // List?
        if (firstChar == "<")
            return skyui.util.ConfigManager.parseList(a_str, a_root);

        // Flags?
        if (firstChar == "{")
            return skyui.util.ConfigManager.parseFlags(a_str, a_root, a_loc, a_key);

        // Constant?
        var constValue = skyui.util.ConfigManager.getConstant(a_str);
        if (constValue != undefined)
            return constValue;

        // Var?
        var varEntry: Object = a_root.vars[a_str];
        if (varEntry != undefined) {
            // A variable might be updated later via overrides, so each var stores
            // its references (object/key pairs) to allow re-evaluation.
            if (a_loc && a_key) {
                if (varEntry._refLocs == undefined) {
                    varEntry._refLocs = [];
                    varEntry._refKeys = [];
                }
                // Can be either object+string or array+index
                varEntry._refLocs.push(a_loc);
                varEntry._refKeys.push(a_key);
            }
            return varEntry.value;
        }

        // Default String
        return a_str;
    }

    //TODO: parseAssoc and parseList should properly check if [:,] is within a string
    private static function parseAssoc(a_str: String, a_root: Object)
    {
        var assocArray: Object = {};
        var pairs: Array = skyui.util.GlobalFunctions.extract(a_str, "<", ">").split(",");
        for (var i = 0; i < pairs.length; i++) {
            var keyValue: Array = pairs[i].split(":");
            // Ignore malformed pairs
            if (keyValue.length != 2)
                continue;
            var key = skyui.util.ConfigManager.parseValueString(skyui.util.GlobalFunctions.clean(keyValue[0]), a_root, null, null);
            var val = skyui.util.ConfigManager.parseValueString(skyui.util.GlobalFunctions.clean(keyValue[1]), a_root, assocArray, key);
            assocArray[key] = val;
        }
        return assocArray;
    }

    private static function parseList(a_str: String, a_root: Object)
    {
        if (a_str.charAt(1) == ">")
            return [];

        var values: Array = skyui.util.GlobalFunctions.extract(a_str, "<", ">").split(",");
        for (var i = 0; i < values.length; i++)
            values[i] = skyui.util.ConfigManager.parseValueString(skyui.util.GlobalFunctions.clean(values[i]), a_root, values, i);

        return values;
    }

    private static function parseFlags(a_str: String, a_root: Object, a_loc: Object, a_key: String)
    {
        var tokens: Array = skyui.util.GlobalFunctions.extract(a_str, "{", "}").split("|");
        var flags: Number = 0;
        for (var i = 0; i < tokens.length; i++) {
            var t = skyui.util.ConfigManager.parseValueString(skyui.util.GlobalFunctions.clean(tokens[i]), a_root, a_loc, a_key);
            if (isNaN(t))
                return undefined;

            flags = flags | t;
        }
        return flags;
    }
}
