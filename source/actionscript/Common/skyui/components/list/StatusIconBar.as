class skyui.components.list.StatusIconBar extends MovieClip
{
    public var background: MovieClip;
    public var poisonIcon: MovieClip;
    public var enchIcon: MovieClip;
    public var favoriteIcon: MovieClip;
    public var bestIcon: MovieClip;
    public var stolenIcon: MovieClip;
    public var readIcon: MovieClip;

    private var _icons: Array;

    function StatusIconBar()
    {
        super();
    }

    public function onLoad()
    {
        this._icons = [
            this.bestIcon,
            this.favoriteIcon,
            this.poisonIcon,
            this.stolenIcon,
            this.enchIcon,
            this.readIcon
        ];
        this.background.JustifyContent(this._icons, "flex-start", 5);
    }

    private function setIconState(a_icon: MovieClip, a_show: Boolean, a_size: Number)
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

    public function updateStatuses(a_entryObject: Object, a_showStolen: Boolean, a_iconSize: Number)
    {
        this.setIconState(this.bestIcon,     (a_entryObject.bestInClass == true), a_iconSize);
        this.setIconState(this.favoriteIcon, (a_entryObject.favorite == true), a_iconSize);
        this.setIconState(this.poisonIcon,   (a_entryObject.isPoisoned == true), a_iconSize);
        this.setIconState(this.stolenIcon,   (a_showStolen && (a_entryObject.isStolen == true || a_entryObject.isStealing == true)), a_iconSize);
        this.setIconState(this.enchIcon,     (a_entryObject.isEnchanted == true), a_iconSize);
        this.setIconState(this.readIcon,     (a_entryObject.isRead == true), a_iconSize);
        this.background.JustifyContent(this._icons, "flex-start", 5);
    }
}