class skyui.components.dialog.BasicDialog extends MovieClip
{	
  /* CONSTANTS */

    public static var OPEN = 0;
    public static var CLOSED = 1;
    public static var OPENING = 2;
    public static var CLOSING = 3;
    
    
  /* PRIVATE VARIABLES */
    
    private var _dialogState: Number = -1;
    private var _fadeTween: Tween;
    
    
  /* INITIALIZATION */
    
    public function BasicDialog()
    {
        super();
        gfx.events.EventDispatcher.initialize(this);
        Mouse.addListener(this);
    }
    

  /* PUBLIC FUNCTIONS */

    // @mixin by EventDispatcher
    public var dispatchEvent: Function;
    public var dispatchQueue: Function;
    public var hasEventListener: Function;
    public var addEventListener: Function;
    public var removeEventListener: Function;
    public var removeAllEventListeners: Function;
    public var cleanUpEvents: Function;
    
    public function openDialog()
    {
        this.setDialogState(skyui.components.dialog.BasicDialog.OPENING);
        
        if (this._fadeTween) {
            this._fadeTween.stop();
            delete this._fadeTween;
        }
        
        this._fadeTween = new mx.transitions.Tween(this, "_alpha", mx.transitions.easing.None.easeNone, 0, 100, 0.25, true);
        this._fadeTween.FPS = 40;
        this._fadeTween.onMotionFinished = mx.utils.Delegate.create(this, this.fadedInFunc);
    }
    
    public function closeDialog()
    {
        this.setDialogState(skyui.components.dialog.BasicDialog.CLOSING);
        
        if (this._fadeTween) {
            this._fadeTween.stop();
            delete this._fadeTween;
        }
        
        this._fadeTween = new mx.transitions.Tween(this, "_alpha", mx.transitions.easing.None.easeNone, 100, 0, 0.25, true);
        this._fadeTween.FPS = 40;
        this._fadeTween.onMotionFinished = mx.utils.Delegate.create(this, this.fadedOutFunc);
    }
    
    public var onDialogOpening: Function;
    
    public var onDialogOpen: Function;
    
    public var onDialogClosing: Function;
    
    public var onDialogClosed: Function;
    
    
  /* PRIVATE FUNCTIONS */
    
    private function setDialogState(a_newState: Number)
    {
        if (this._dialogState == a_newState)
            return;
            
        this._dialogState = a_newState;
        
        if (a_newState == skyui.components.dialog.BasicDialog.OPENING) {
            if (this.onDialogOpening)
                this.onDialogOpening();
            this.dispatchEvent({type: "dialogOpening"});
            
        } else if (a_newState == skyui.components.dialog.BasicDialog.OPEN) {
            if (this.onDialogOpen)
                this.onDialogOpen();
            this.dispatchEvent({type: "dialogOpen"});

        } else if (a_newState == skyui.components.dialog.BasicDialog.CLOSING) {
            if (this.onDialogClosing)
                this.onDialogClosing();
            this.dispatchEvent({type: "dialogClosing"});

        } else if (a_newState == skyui.components.dialog.BasicDialog.CLOSED) {
            if (this.onDialogClosed)
                this.onDialogClosed();
            this.dispatchEvent({type: "dialogClosed"});
            
            this.removeAllEventListeners();
            this.removeMovieClip();
        }
    }
    
    private function fadedInFunc()
    {
        this.setDialogState(skyui.components.dialog.BasicDialog.OPEN);
    }
    
    private function fadedOutFunc()
    {
        this.setDialogState(skyui.components.dialog.BasicDialog.CLOSED);
    }
}