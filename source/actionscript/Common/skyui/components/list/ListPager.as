/*
 *  Runtime-built page navigator shown below a ScrollingList when pagination
 *  mode is on (instead of the scrollbar). Renders clickable page numbers with
 *  ellipses for skipped ranges, e.g. "1 2 3 ... 12".
 *
 *  This is a plain controller class: it owns a container MovieClip and fills
 *  it with per-page clips at runtime, so no SWF symbol is required.
 */
class skyui.components.list.ListPager
{
  /* CONSTANTS */

    public static var ALIGN_LEFT: Number = 0;
    public static var ALIGN_CENTER: Number = 1;
    public static var ALIGN_RIGHT: Number = 2;

    // Pages shown on each side of the current one before collapsing to "...".
    private static var WINDOW: Number = 2;

    // Horizontal gap between entries, in pixels.
    private static var SPACING: Number = 6;

    // Padding added to a digit to form its (square) hit box.
    private static var PADDING: Number = 4;

    // Gap between the pager and the bottom edge of the list.
    private static var BOTTOM_PADDING: Number = 4;

    // buildPageList marker for an ellipsis slot.
    private static var ELLIPSIS: Number = -1;


  /* PRIVATE VARIABLES */

    private var _container: MovieClip;
    private var _list: skyui.components.list.ScrollingList;

    private var _format: TextFormat;
    private var _activeFormat: TextFormat;

    // Per-page clips currently on screen, so they can be cleared on rebuild.
    private var _clips: Array;
    private var _itemHeight: Number;

    // Placement: alignment mode + the area (left x, bottom y, width) to lay out in.
    private var _align: Number;
    private var _areaX: Number;
    private var _areaBottom: Number;
    private var _areaWidth: Number;

    // Last rendered state, to skip needless rebuilds.
    private var _pageCount: Number;
    private var _currentPage: Number;


  /* INITIALIZATION */

    public function ListPager(a_container: MovieClip, a_list: skyui.components.list.ScrollingList)
    {
        this._container = a_container;
        this._list = a_list;
        this._clips = [];
        this._itemHeight = 0;
        this._align = skyui.components.list.ListPager.ALIGN_LEFT;
        this._areaX = 0;
        this._areaBottom = 0;
        this._areaWidth = 0;
        this._pageCount = -1;
        this._currentPage = -1;

        this._format = new TextFormat();
        this._format.font = "$EverywhereMediumFont";
        this._format.size = 16;
        this._format.color = 0x888888;

        this._activeFormat = new TextFormat();
        this._activeFormat.font = "$EverywhereMediumFont";
        this._activeFormat.size = 16;
        this._activeFormat.bold = true;
        this._activeFormat.color = 0xFFFFFF;
    }


  /* PUBLIC FUNCTIONS */

    public function setVisible(a_visible: Boolean)
    {
        this._container._visible = a_visible;
    }

    // a_bottom is the y of the list's bottom edge; the pager sits just above it.
    public function setArea(a_x: Number, a_bottom: Number, a_width: Number)
    {
        this._areaX = a_x;
        this._areaBottom = a_bottom;
        this._areaWidth = a_width;
        this.reflow();
    }

    public function setAlign(a_align: Number)
    {
        this._align = a_align;
        this.reflow();
    }

    public function update(a_pageCount: Number, a_currentPage: Number)
    {
        if (a_pageCount == this._pageCount && a_currentPage == this._currentPage)
            return;

        this._pageCount = a_pageCount;
        this._currentPage = a_currentPage;

        this.rebuild();
    }


  /* PRIVATE FUNCTIONS */

    private function rebuild()
    {
        for (var i = 0; i < this._clips.length; i++)
            this._clips[i].removeMovieClip();

        this._clips = [];
        this._itemHeight = 0;

        // A single page (or none) needs no navigator.
        if (this._pageCount > 1) {
            var items = this.buildPageList();

            for (var j = 0; j < items.length; j++)
                this._clips.push(this.createItem(items[j], j));
        }

        this.reflow();
    }

    // Positions the container and lays the entries out with the chosen
    // horizontal alignment; the pager bottom rests BOTTOM_PADDING above the list.
    private function reflow()
    {
        var i = 0;
        var total = 0;

        for (i = 0; i < this._clips.length; i++)
            total += this._clips[i]._width;

        if (this._clips.length > 1)
            total += (this._clips.length - 1) * skyui.components.list.ListPager.SPACING;

        var offset = 0;
        if (this._align == skyui.components.list.ListPager.ALIGN_CENTER)
            offset = (this._areaWidth - total) / 2;
        else if (this._align == skyui.components.list.ListPager.ALIGN_RIGHT)
            offset = this._areaWidth - total;

        if (offset < 0)
            offset = 0;

        var x = offset;
        for (i = 0; i < this._clips.length; i++) {
            this._clips[i]._x = x;
            x += this._clips[i]._width + skyui.components.list.ListPager.SPACING;
        }

        this._container._x = this._areaX;
        this._container._y = this._areaBottom - this._itemHeight - skyui.components.list.ListPager.BOTTOM_PADDING;
    }

    // Page indices to render, with ELLIPSIS markers where ranges are skipped.
    private function buildPageList()
    {
        var pages = [];
        var lastShown = -1;

        for (var i = 0; i < this._pageCount; i++) {
            var bShow = (i == 0)
                || (i == this._pageCount - 1)
                || (i >= this._currentPage - skyui.components.list.ListPager.WINDOW && i <= this._currentPage + skyui.components.list.ListPager.WINDOW);

            if (!bShow)
                continue;

            if (i - lastShown > 1)
                pages.push(skyui.components.list.ListPager.ELLIPSIS);

            pages.push(i);
            lastShown = i;
        }

        return pages;
    }

    private function createItem(a_page: Number, a_depth: Number)
    {
        var clip = this._container.createEmptyMovieClip("item" + a_depth, a_depth);

        var bEllipsis: Boolean = (a_page == skyui.components.list.ListPager.ELLIPSIS);
        var bActive: Boolean = (a_page == this._currentPage);

        var label = clip.createTextField("label", 0, 0, 0, 20, 20);
        label.autoSize = "left";
        label.selectable = false;
        label.embedFonts = true;
        label.text = bEllipsis ? "..." : String(a_page + 1);
        label.setTextFormat(bActive ? this._activeFormat : this._format);

        var textW: Number = label._width;
        var textH: Number = label._height;

        // Square hit box: side = digit height + padding; when the text is wider
        // than tall (e.g. "12", "...") the box widens to the text instead.
        var boxH: Number = textH + skyui.components.list.ListPager.PADDING;
        var boxW: Number = ((textW > textH) ? textW : textH) + skyui.components.list.ListPager.PADDING;

        // Invisible fill so the whole box is the clickable area.
        clip.beginFill(0x000000, 0);
        clip.moveTo(0, 0);
        clip.lineTo(boxW, 0);
        clip.lineTo(boxW, boxH);
        clip.lineTo(0, boxH);
        clip.lineTo(0, 0);
        clip.endFill();

        label._x = (boxW - textW) / 2;
        label._y = (boxH - textH) / 2;

        this._itemHeight = boxH;

        // Ellipsis and the current page are not clickable.
        if (bEllipsis || bActive)
            return clip;

        clip.pagerList = this._list;
        clip.pageNumber = a_page;
        clip.normalFormat = this._format;

        clip.onRelease = function()
        {
            this.pagerList.goToPage(this.pageNumber);
        };

        clip.onRollOver = function()
        {
            this.label.textColor = 0xFFFFFF;
        };

        clip.onRollOut = function()
        {
            this.label.setTextFormat(this.normalFormat);
        };

        return clip;
    }
}
