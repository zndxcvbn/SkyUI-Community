class skyui.components.SearchWidget extends MovieClip
{
  /* CONSTANTS */

    private static var S_FILTER = "$FILTER";
    
    
  /* PRIVATE VARIABLES */

    private var _previousFocus: Object;
    private var _currentInput: String;
    private var _lastInput: String;
    private var _bActive: Boolean;
    private var _bRestoreFocus: Boolean = false;
    private var _bEnableAutoupdate: Boolean;
    private var _updateDelay: Number;
    
    private var _updateTimerId: Number;
    
    
  /* STAGE ELEMENTS */

    public var textField: TextField;
    public var icon: MovieClip;
    
  /* PROPERTIES */
    
    public var isDisabled: Boolean = false;
    
    
  /* INITIALIZATION */
    
    public function SearchWidget()
    {
        super();
        gfx.events.EventDispatcher.initialize(this);
        
        this.textField.onKillFocus = function(a_newFocus: Object)
        {
            this._parent.endInput();
        };
        
        this.textField.SetText(skyui.components.SearchWidget.S_FILTER);

        skyui.util.ConfigManager.registerLoadCallback(this, "onConfigLoad");
    }
    
    
  /* PUBLIC FUNCTIONS */

    // @mixin by gfx.events.EventDispatcher
    public var dispatchEvent: Function;
    public var dispatchQueue: Function;
    public var hasEventListener: Function;
    public var addEventListener: Function;
    public var removeEventListener: Function;
    public var removeAllEventListeners: Function;
    public var cleanUpEvents: Function;
    
    public function onConfigLoad(event)
    {
        var config = event.config;
        this._bEnableAutoupdate = config["SearchBox"].autoupdate.enable;
        this._updateDelay = config["SearchBox"].autoupdate.delay;
    }
    
    public function onPress(a_mouseIndex, a_keyboardOrMouse)
    {
        this.startInput();
    }

    public function startInput()
    {
        if (this._bActive || this.isDisabled)
            return;
        
        this._previousFocus = gfx.managers.FocusHandler.instance.getFocus(0);

        this._currentInput = this._lastInput = undefined;
        
        this.textField.SetText("");
        this.textField.type = "input";
        this.textField.noTranslate = true;
        this.textField.selectable = true;
        
        Selection.setFocus(this.textField);
        Selection.setSelection(0,0);
        
        this._bActive = true;
        skse.AllowTextInput(true);
        
        this.dispatchEvent({type: "inputStart"});
        
        if (this._bEnableAutoupdate) {
            this.onEnterFrame = function()
            {
                this.refreshInput();
                
                if (this._currentInput != this._lastInput) {
                    this._lastInput = this._currentInput;
                    
                    if (this._updateTimerId != undefined) {
                        clearInterval(this._updateTimerId);
                    }
                    this._updateTimerId = setInterval(this, "updateInput", this._updateDelay);
                }
            };
        }
    }

    public function endInput()
    {
        if (!this._bActive)
            return;

        delete this.onEnterFrame;
        
        this.textField.type = "dynamic";
        this.textField.noTranslate = false;
        this.textField.selectable = false;
        this.textField.maxChars = null;
        
        var bPrevEnabled = this._previousFocus.focusEnabled;
        this._previousFocus.focusEnabled = true;
        Selection.setFocus(this._previousFocus,0);
        this._previousFocus.focusEnabled = bPrevEnabled;

        this._bActive = false;
        skse.AllowTextInput(false);

        this.refreshInput();

        if (this._currentInput != undefined) {
            this.dispatchEvent({type: "inputEnd", data: this._currentInput});
        } else {
            this.textField.SetText(skyui.components.SearchWidget.S_FILTER);
            this.dispatchEvent({type: "inputEnd", data: ""});
        }
    }

    // @GFx
    public function handleInput(details: InputDetails, pathToFocus: Array)
    {
        if (Shared.GlobalFunc.IsKeyPressed(details)) {
            
            if (details.navEquivalent == gfx.ui.NavigationCode.ENTER) {
                this.endInput();
                
            } else if (details.navEquivalent == gfx.ui.NavigationCode.TAB || details.navEquivalent == gfx.ui.NavigationCode.ESCAPE) {
                this.clearText();
                this.endInput();
            }

            var nextClip = pathToFocus.shift();
            if (nextClip.handleInput(details, pathToFocus))
                return true;
        }
        
        return false;
    }
    
    
  /* PRIVATE FUNCTIONS */
    
    private function clearText()
    {
        this.textField.SetText("");
    }
    
    private function refreshInput()
    {
        var t =  Shared.GlobalFunc.StringTrim(this.textField.text);
        
        if (t != undefined && t != "" && t != skyui.components.SearchWidget.S_FILTER) {
            this._currentInput = t;
        } else {
           this._currentInput = undefined;
        }
    }
    
    private function updateInput()
    {
        if (this._updateTimerId != undefined) {
            clearInterval(this._updateTimerId);
            this._updateTimerId = undefined;
            
            if (this._currentInput != undefined) {
                this.dispatchEvent({type: "inputChange", data: this._currentInput});
            } else {
                this.dispatchEvent({type: "inputChange", data: ""});
            }
        }
    }
}
