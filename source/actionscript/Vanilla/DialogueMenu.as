class DialogueMenu extends MovieClip
{
  /* PUBLIC VARIABLES */

    public var ExitButton: MovieClip;
    public var SpeakerName: TextField;
    public var SubtitleText: TextField;
    public var TopicList: MovieClip;
    public var TopicListHolder: MovieClip;

    public var bAllowProgress: Boolean;
    public var bFadedIn: Boolean;
    public var eMenuState: Number;
    
    private var iAllowProgressTimerID: Number;


  /* CONSTANTS */ 

    public static var SHOW_GREETING: Number = 0;
    public static var TOPIC_LIST_SHOWN: Number = 1;
    public static var TOPIC_CLICKED: Number = 2;
    public static var TRANSITIONING: Number = 3;
    public static var ALLOW_PROGRESS_DELAY: Number = 750;

    private static var iMouseDownExecutionCount: Number = 0;


  /* INITIALIZATION */ 

    public function DialogueMenu()
    {
        super();
        this.TopicList = this.TopicListHolder.List_mc;
        this.eMenuState = DialogueMenu.SHOW_GREETING;
        this.bFadedIn = true;
        this.bAllowProgress = false;
        
        Shared.ButtonMapping.Initialize("DialogueMenu");
    }

    public function InitExtensions()
    {
        Stage.scaleMode = "showAll";
        Mouse.addListener(this);

        gfx.io.GameDelegate.addCallBack("Cancel", this, "onCancelPress");
        gfx.io.GameDelegate.addCallBack("ShowDialogueText", this, "ShowDialogueText");
        gfx.io.GameDelegate.addCallBack("HideDialogueText", this, "HideDialogueText");
        gfx.io.GameDelegate.addCallBack("PopulateDialogueList", this, "PopulateDialogueLists");
        gfx.io.GameDelegate.addCallBack("ShowDialogueList", this, "DoShowDialogueList");
        gfx.io.GameDelegate.addCallBack("StartHideMenu", this, "StartHideMenu");
        gfx.io.GameDelegate.addCallBack("SetSpeakerName", this, "SetSpeakerName");
        gfx.io.GameDelegate.addCallBack("NotifyVoiceReady", this, "OnVoiceReady");
        gfx.io.GameDelegate.addCallBack("AdjustForPALSD", this, "AdjustForPALSD");
        
        this.TopicList.addEventListener("listMovedUp", this, "playListUpAnim");
        this.TopicList.addEventListener("listMovedDown", this, "playListDownAnim");
        this.TopicList.addEventListener("itemPress", this, "onItemSelect");

        Shared.GlobalFunc.SetLockFunction();
        
        this.ExitButton.Lock("BR");
        this.ExitButton._x -= 50;
        this.ExitButton._y -= 30;
        this.ExitButton.addEventListener("click", this, "onCancelPress");
        
        this.TopicListHolder._visible = false;
        
        var textCopy = this.TopicListHolder.TextCopy_mc;
        textCopy._visible = false;
        textCopy.textField.textColor = 0x606060;
        textCopy.textField.verticalAutoSize = "top";
        
        this.TopicListHolder.PanelCopy_mc._visible = false;

        gfx.managers.FocusHandler.instance.setFocus(this.TopicList, 0);

        this.SubtitleText.verticalAutoSize = "top";
        this.SubtitleText.SetText(" ");
        
        this.SpeakerName.verticalAutoSize = "top";
        this.SpeakerName.SetText(" ");
    }


  /* PUBLIC FUNCTIONS */ 

    public function AdjustForPALSD()
    {
        _root.DialogueMenu_mc._x -= 35;
    }

    public function SetPlatform(aiPlatform: Number, abPS3Switch: Boolean)
    {
        this.ExitButton.SetPlatform(aiPlatform, abPS3Switch);
        this.TopicList.SetPlatform(aiPlatform, abPS3Switch);
        Shared.ButtonMapping.CorrectLabel(this.ExitButton);
    }

    public function SetSpeakerName(strName: String)
    {
        this.SpeakerName.SetText(strName);
    }

    public function handleInput(details: Object, pathToFocus: Array)
    {
        if (this.bFadedIn && Shared.GlobalFunc.IsKeyPressed(details)) 
        {
            if (details.navEquivalent == gfx.ui.NavigationCode.TAB) 
            {
                this.onCancelPress();
            } 
            else if (details.navEquivalent != gfx.ui.NavigationCode.UP && 
                     details.navEquivalent != gfx.ui.NavigationCode.DOWN || 
                     this.eMenuState == DialogueMenu.TOPIC_LIST_SHOWN) 
            {
                pathToFocus[0].handleInput(details, pathToFocus.slice(1));
            }
        }
        return true;
    }

    public function get menuState() {  return this.eMenuState; }
    public function set menuState(aNewState: Number) { this.eMenuState = aNewState; }

    public function ShowDialogueText(astrText: String)
    {
        this.SubtitleText.SetText(astrText);
    }

    public function OnVoiceReady()
    {
        this.StartProgressTimer();
    }

    public function StartProgressTimer()
    {
        this.bAllowProgress = false;
        clearInterval(this.iAllowProgressTimerID);
        this.iAllowProgressTimerID = setInterval(this, "SetAllowProgress", DialogueMenu.ALLOW_PROGRESS_DELAY);
    }

    public function HideDialogueText()
    {
        this.SubtitleText.SetText(" ");
    }

    public function SetAllowProgress()
    {
        clearInterval(this.iAllowProgressTimerID);
        this.bAllowProgress = true;
    }

    public function PopulateDialogueLists()
    {
        this.TopicList.ClearList();

        var stride: Number = 3;
        var i: Number = 0;
        while (i < arguments.length - 1)
        {
            var entry = {
                text: arguments[i],
                topicIsNew: arguments[i + 1],
                topicIndex: arguments[i + 2]
            };
            this.TopicList.entryList.push(entry);
            i += stride;
        }

        var selectedTopicIndex = arguments[arguments.length - 1];
        if (selectedTopicIndex != -1)
            this.TopicList.SetSelectedTopic(selectedTopicIndex);
        
        this.TopicList.InvalidateData();
    }

    public function DoShowDialogueList(abNewList: Boolean, abHideExitButton: Boolean)
    {
        var canShow = (this.eMenuState == DialogueMenu.TOPIC_CLICKED) || 
                      (this.eMenuState == DialogueMenu.SHOW_GREETING && this.TopicList.entryList.length > 0);
        
        if (canShow) {
            var isTopicClicked = (this.eMenuState == DialogueMenu.TOPIC_CLICKED);
            this.ShowDialogueList(abNewList, abNewList && isTopicClicked);
        }
        
        this.ExitButton._visible = !abHideExitButton;
    }

    public function ShowDialogueList(abSlideAnim: Boolean, abCopyVisible: Boolean)
    {
        this.TopicListHolder._visible = true;
        this.TopicListHolder.gotoAndPlay(abSlideAnim ? "slideListIn" : "fadeListIn");
        this.eMenuState = DialogueMenu.TRANSITIONING;
        
        this.TopicListHolder.TextCopy_mc._visible = abCopyVisible;
        this.TopicListHolder.PanelCopy_mc._visible = abCopyVisible;
    }

    public function onItemSelect(event: Object)
    {
        if (this.bAllowProgress && event.keyboardOrMouse != 0)
        {
            if (this.eMenuState == DialogueMenu.TOPIC_LIST_SHOWN)
                this.onSelectionClick();
            else if (this.eMenuState == DialogueMenu.TOPIC_CLICKED || this.eMenuState == DialogueMenu.SHOW_GREETING)
                this.SkipText();
                
            this.bAllowProgress = false;
        }
    }

    public function SkipText()
    {
        if (this.bAllowProgress) {
            gfx.io.GameDelegate.call("SkipText", []);
            this.bAllowProgress = false;
        }
    }

    public function onMouseDown()
    {
        DialogueMenu.iMouseDownExecutionCount++;
        if (DialogueMenu.iMouseDownExecutionCount % 2 == 0) return;
        
        this.onItemSelect();
    }

    public function onCancelPress()
    {
        if (this.eMenuState == DialogueMenu.SHOW_GREETING)
            this.SkipText();
        else
            this.StartHideMenu();
    }

    public function StartHideMenu()
    {
        this.SubtitleText._visible = false;
        this.bFadedIn = false;
        this.SpeakerName.SetText(" ");
        this.ExitButton._visible = false;
        
        this._parent.gotoAndPlay("startFadeOut");
        gfx.io.GameDelegate.call("CloseMenu", []);
    }

    public function playListUpAnim(aEvent: Object)
    {
        if (aEvent.scrollChanged) aEvent.target._parent.gotoAndPlay("moveUp");
    }

    public function playListDownAnim(aEvent: Object)
    {
        if (aEvent.scrollChanged) aEvent.target._parent.gotoAndPlay("moveDown");
    }

    public function onSelectionClick()
    {
        if (this.eMenuState == DialogueMenu.TOPIC_LIST_SHOWN)
            this.eMenuState = DialogueMenu.TOPIC_CLICKED;

        if (this.TopicList.scrollPosition != this.TopicList.selectedIndex) {
            this.TopicList.RestoreScrollPosition(this.TopicList.selectedIndex, true);
            this.TopicList.UpdateList();
        }

        this.TopicListHolder.gotoAndPlay("topicClicked");
        
        var textCopy = this.TopicListHolder.TextCopy_mc;
        textCopy._visible = true;
        textCopy.textField.SetText(this.TopicList.selectedEntry.text);
        
        var verticalOffset: Number = textCopy._y - this.TopicList._y - this.TopicList.Entry4._y;
        textCopy.textField._y = 6.25 - verticalOffset;

        gfx.io.GameDelegate.call("TopicClicked", [this.TopicList.selectedEntry.topicIndex]);
    }

    public function onFadeOutCompletion()
    {
        gfx.io.GameDelegate.call("FadeDone", []);
    }
}
