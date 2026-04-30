class Shared.ListFilterer
{
  /* PUBLIC VARIABLES */

    public var EntryMatchesFunc;
    public var dispatchEvent;
    public var iItemFilter;


  /* PRIVATE VARIABLES */

    private var _filterArray;


  /* INITIALIZATION */

    function ListFilterer()
    {
        this.iItemFilter = 4294967295;
        this.EntryMatchesFunc = this.EntryMatchesFilter;

        gfx.events.EventDispatcher.initialize(this);
    }


  /* PROPERTIES */

    public function get itemFilter() { return this.iItemFilter; }
    public function set itemFilter(aiNewFilter)
    {
        var changed = this.iItemFilter != aiNewFilter;

        this.iItemFilter = aiNewFilter;

        if (changed)
            this.dispatchEvent({type: "filterChange"});
    }

    public function get filterArray() { return this._filterArray; }
    public function set filterArray(aNewArray) { this._filterArray = aNewArray; }


  /* PUBLIC FUNCTIONS */

    public function SetPartitionedFilterMode(abPartition)
    {
        this.EntryMatchesFunc = abPartition
            ? this.EntryMatchesPartitionedFilter
            : this.EntryMatchesFilter;
    }

    public function EntryMatchesFilter(aEntry)
    {
        if (aEntry == undefined) return false;

        return (aEntry.filterFlag == undefined) ||
                ((aEntry.filterFlag & this.iItemFilter) != 0);
    }

    public function EntryMatchesPartitionedFilter(aEntry)
    {
        if (aEntry == undefined) return false;

        if (this.iItemFilter == 4294967295) return true;

        var flag = aEntry.filterFlag;

        var part0 =  flag        & 0xFF;
        var part1 = (flag >> 8)  & 0xFF;
        var part2 = (flag >> 16) & 0xFF;
        var part3 = (flag >> 24) & 0xFF;

        return (
            part0 == this.iItemFilter ||
            part1 == this.iItemFilter ||
            part2 == this.iItemFilter ||
            part3 == this.iItemFilter
        );
    }

    public function GetPrevFilterMatch(aiStartIndex) { return this._findMatch(aiStartIndex, -1); }
    public function GetNextFilterMatch(aiStartIndex) { return this._findMatch(aiStartIndex, 1); }

    public function ClampIndex(aiStartIndex)
    {
        if (aiStartIndex == undefined) return aiStartIndex;

        var index = aiStartIndex;

        if (!this.EntryMatchesFunc(this._filterArray[index]))
        {
            var nextIndex = this.GetNextFilterMatch(index);
            var prevIndex = this.GetPrevFilterMatch(index);

            if (nextIndex != undefined)
                index = nextIndex;
            else if (prevIndex != undefined)
                index = prevIndex;
            else
                return -1;

            if (nextIndex != undefined &&
                prevIndex != undefined &&
                prevIndex != nextIndex &&
                index == nextIndex &&
                this._filterArray[prevIndex].text == this._filterArray[aiStartIndex].text
            )
                index = prevIndex;
        }

        return index;
    }


  /* PRIVATE FUNCTIONS */

    private function _findMatch(startIndex, step)
    {
        if (startIndex == undefined) return undefined;

        var index = startIndex + step;

        while (index >= 0 && index < this._filterArray.length)
        {
            if (this.EntryMatchesFunc(this._filterArray[index])) return index;

            index += step;
        }

        return undefined;
    }
}
