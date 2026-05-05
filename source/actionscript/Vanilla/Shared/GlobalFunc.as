class Shared.GlobalFunc
{
    static var RegisteredTextFields = new Object();
    static var RegisteredMovieClips = new Object();

    function GlobalFunc() {}

  // MATH / UTILS

    static function Lerp(aTargetMin, aTargetMax, aSourceMin, aSourceMax, aSource, abClamp)
    {
        var value = aTargetMin + (aSource - aSourceMin) / (aSourceMax - aSourceMin) * (aTargetMax - aTargetMin);

        if (abClamp)
            value = Math.max(aTargetMin, Math.min(value, aTargetMax));

        return value;
    }

    static function RoundDecimal(aNumber, aPrecision)
    {
        var pow = Math.pow(10, aPrecision);
        return Math.round(aNumber * pow) / pow;
    }

    static function StringTrim(astrText)
    {
        var start = 0;
        var end = astrText.length - 1;

        while (start < astrText.length && Shared.GlobalFunc._isWhitespace(astrText.charAt(start))) start++;
        while (end >= 0 && Shared.GlobalFunc._isWhitespace(astrText.charAt(end))) end--;

        return astrText.substring(start, end + 1);
    }

    private static function _isWhitespace(ch)
    {
        return ch == " " || ch == "\n" || ch == "\r" || ch == "\t";
    }

    static function IsKeyPressed(aInputInfo, abProcessKeyHeldDown)
    {
        if (abProcessKeyHeldDown == undefined) abProcessKeyHeldDown = true;
        return aInputInfo.value == "keyDown" || (abProcessKeyHeldDown && aInputInfo.value == "keyHold");
    }

  // TEXTFIELD

    static function MaintainTextFormat()
    {
        if (TextField.prototype.enableShrinkToFit == undefined)
        {
            TextField.prototype.enableShrinkToFit = false;
            TextField.prototype.overflowMode = "none";
            TextField.prototype.maxHeightExpand = 0;
            TextField.prototype.minFontSize = 10;
        }

        TextField.prototype.SetText = function(aText, abHTMLText)
        {
            if (!aText) aText = " ";

            var fmt = this.getTextFormat();
            var letterSpacing = fmt.letterSpacing;
            var kerning = fmt.kerning;

            if (abHTMLText) {
                this.htmlText = aText;
                fmt = this.getTextFormat();
                fmt.letterSpacing = letterSpacing;
                fmt.kerning = kerning;
            } else {
                this.text = aText;
            }

            this.setTextFormat(fmt);

            if (this.enableShrinkToFit || this.overflowMode == "ellipsis")
                Shared.GlobalFunc.ApplyTextOverflow(this);
        };
    }


  // MOVIECLIP HELPERS

    static function SetLockFunction()
    {
        MovieClip.prototype.Lock = function(aPosition)
        {
            var min = {
                x: Stage.visibleRect.x + Stage.safeRect.x,
                y: Stage.visibleRect.y + Stage.safeRect.y
            };

            var max = {
                x: Stage.visibleRect.x + Stage.visibleRect.width - Stage.safeRect.x,
                y: Stage.visibleRect.y + Stage.visibleRect.height - Stage.safeRect.y
            };

            this._parent.globalToLocal(min);
            this._parent.globalToLocal(max);

            if (aPosition.indexOf("T") != -1) this._y = min.y;
            if (aPosition.indexOf("B") != -1) this._y = max.y;
            if (aPosition.indexOf("L") != -1) this._x = min.x;
            if (aPosition.indexOf("R") != -1) this._x = max.x;
        };
    }

    static function AddMovieExploreFunctions()
    {
        MovieClip.prototype.getMovieClips = function()
        {
            var result = new Array();
            for (var key in this) {
                if (this[key] instanceof MovieClip && this[key] != this) {
                    result.push(this[key]);
                }
            }
            return result;
        };

        MovieClip.prototype.showMovieClips = function()
        {
            for (var key in this) {
                if (this[key] instanceof MovieClip && this[key] != this) {
                    trace(this[key]);
                    this[key].showMovieClips();
                }
            }
        };
    }

    static function AddReverseFunctions()
    {
        MovieClip.prototype.PlayReverse = function()
        {
            if (this._currentframe <= 1) {
                this.gotoAndStop(1);
                return;
            }

            var self = this;
            this.onEnterFrame = function()
            {
                if (self._currentframe > 1)
                    self.gotoAndStop(self._currentframe - 1);
                else
                    delete self.onEnterFrame;
            };
        };

        MovieClip.prototype.PlayForward = function(aFrameLabel)
        {
            delete this.onEnterFrame;
            this.gotoAndPlay(aFrameLabel);
        };
        MovieClip.prototype.PlayForward = function(aFrame)
        {
            delete this.onEnterFrame;
            this.gotoAndPlay(aFrame);
        };
    }


  // REGISTRATION
  
    static function AddRegisterTextFields()
    {
        TextField.prototype.RegisterTextField = function(aStartingClip)
        {
            var key = this._name + aStartingClip._name;
            if (Shared.GlobalFunc.RegisteredTextFields[key] == undefined)
                Shared.GlobalFunc.RegisteredTextFields[key] = this;
        };
    }

    static function RegisterTextFields(aStartingClip)
    {
        for (var key in aStartingClip) {
            if (aStartingClip[key] instanceof TextField)
                aStartingClip[key].RegisterTextField(aStartingClip);
        }
    }

    static function RegisterAllTextFieldsInTimeline(aStartingClip)
    {
        for (var i = 1; aStartingClip._totalFrames && i <= aStartingClip._totalFrames; i++) {
            aStartingClip.gotoAndStop(i);
            Shared.GlobalFunc.RegisterTextFields(aStartingClip);
        }
    }

    static function AddRegisterMovieClips()
    {
        MovieClip.prototype.RegisterMovieClip = function(aStartingClip)
        {
            var key = this._name + aStartingClip._name;
            if (Shared.GlobalFunc.RegisteredMovieClips[key] == undefined)
                Shared.GlobalFunc.RegisteredMovieClips[key] = this;
        };
    }

    static function RegisterMovieClips(aStartingClip)
    {
        for (var key in aStartingClip) {
            if (aStartingClip[key] instanceof MovieClip)
                aStartingClip[key].RegisterMovieClip(aStartingClip);
        }
    }

    static function RecursiveRegisterMovieClips(aStartingClip, aRootClip)
    {
        for (var key in aStartingClip) {
            if (aStartingClip[key] instanceof MovieClip) {
                if (aStartingClip[key] != aStartingClip)
                    Shared.GlobalFunc.RecursiveRegisterMovieClips(aStartingClip[key], aRootClip);
                aStartingClip[key].RegisterMovieClip(aRootClip);
            }
        }
    }

    static function RegisterAllMovieClipsInTimeline(aStartingClip)
    {
        for (var i = 1; aStartingClip._totalFrames && i <= aStartingClip._totalFrames; i++) {
            aStartingClip.gotoAndStop(i);
            Shared.GlobalFunc.RegisterMovieClips(aStartingClip);
        }
    }

    static function GetTextField(aParentClip, aName)
    {
        var key = aName + aParentClip._name;
        var tf = Shared.GlobalFunc.RegisteredTextFields[key];

        if (tf != undefined) return tf;
        trace(aName + " is not registered a TextField name.");
    }

    static function GetMovieClip(aParentClip, aName)
    {
        var key = aName + aParentClip._name;
        var mc = Shared.GlobalFunc.RegisteredMovieClips[key];

        if (mc != undefined) return mc;
        trace(aName + " is not registered a MovieClip name.");
    }



    /* ─── SkyUI Extensions ─── */
    static function ApplyTextOverflow(tf:TextField) {
        if (tf.text == "" || tf.text == undefined) return;

        if (tf.origHeight == undefined) tf.origHeight = tf._height;
        tf._height = tf.origHeight;
        tf.textAutoSize = "none";
        tf.multiline = true;
        tf.wordWrap = true;

        if (tf.enableShrinkToFit) {
            var availableHeight:Number = tf.origHeight + tf.maxHeightExpand;
            tf._height = availableHeight;

            var fmt:TextFormat = tf.getTextFormat();
            var metrics:Object = fmt.getTextExtent(tf.text, tf._width);

            if (metrics.textFieldHeight > tf._height) {
                Shared.GlobalFunc._shrinkFontToFit(tf);
            }

            metrics = tf.getTextFormat().getTextExtent(tf.text, tf._width);
            var expansion:Number = Math.min(Math.max(metrics.textFieldHeight - tf.origHeight, 0), tf.maxHeightExpand);
            tf._height = tf.origHeight + expansion;
        }

        if (tf.overflowMode == "ellipsis" && tf.maxscroll > 1) {
            Shared.GlobalFunc._applyEllipsis(tf);
        }
    }

    private static function _shrinkFontToFit(tf:TextField) {
        if (tf.numLines == 0) return;
        var fmt:TextFormat = tf.getTextFormat();
        var minSize:Number = tf.minFontSize;
        var maxSize:Number = fmt.size;
        var bestSize:Number = minSize;

        while (minSize <= maxSize) {
            var mid:Number = Math.floor((minSize + maxSize) / 2);
            fmt.size = mid;
            tf.setTextFormat(fmt);

            // +4 (2 pixel gutter) = textFieldHeight
            if ((tf.textHeight + 4) < tf._height) {
                bestSize = mid;
                minSize = mid + 1;
            } else {
                maxSize = mid - 1;
            }
        }
        fmt.size = bestSize;
        tf.setTextFormat(fmt);
    }

    private static function _applyEllipsis(tf:TextField) {
        var original:String = tf.htmlText;
        var ellipsis:String = "...";
        var fmt:TextFormat = tf.getTextFormat();

        var left:Number = 0;
        var right:Number = original.length;
        var best:String = original;

        while (left <= right) {
            var mid:Number = Math.floor((left + right) / 2);
            var test:String = original.substr(0, mid) + ellipsis;

            tf.htmlText = test;
            tf.setTextFormat(fmt);

            if (tf.maxscroll == 1) {
                best = test;
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }

        tf.htmlText = best;
        tf.setTextFormat(fmt);
   }

    /**
     * Injects the Anchor method into the MovieClip prototype.
     * This allows any MovieClip to be aligned relative to another clip.
     */
    static function AddAnchorFunction() {
        if (MovieClip.prototype.Anchor != undefined) return;
        if (Shared.GlobalFunc._deferCounter == undefined) Shared.GlobalFunc._deferCounter = 0;

        /**
         * Aligns the current MovieClip relative to a source MovieClip.
         * 
         * @param source            The reference MovieClip to align against.
         * @param targetAnchorType  Point on THIS clip (TL, TC, TR, CL, C, CR, BL, BC, BR).
         * @param sourceAnchorType  Point on SOURCE clip. If undefined, targetAnchorType is used for source, and target is mirrored.
         * @param offsetX           Additional horizontal offset.
         * @param offsetY           Additional vertical offset.
         * @param waitNextFrame     If true, delays calculation by one frame (useful for newly created UI).
         * @return                  Returns 'this' for method chaining.
         */
        MovieClip.prototype.Anchor = function(source:MovieClip, targetAnchorType:String, sourceAnchorType:String, offsetX:Number, offsetY:Number, waitNextFrame:Boolean) {
            if (!source) return this;
            
            if (sourceAnchorType == undefined) {
                sourceAnchorType = targetAnchorType;
                targetAnchorType = undefined;
            }
            
            var sAnchor:Number = Shared.GlobalFunc._parseAnchorString(sourceAnchorType);
            var tAnchor:Number = (targetAnchorType != undefined) 
                ? Shared.GlobalFunc._parseAnchorString(targetAnchorType) 
                : Shared.GlobalFunc._parseOppositeAnchor(sAnchor);
            
            // Defer execution by one frame to allow Scaleform components (like DialogManager) 
            // to finalize their internal layout and calculate accurate dimensions.
            if (waitNextFrame === true) {
                var target = this;
                var helperName = "__anchorHelper_" + (++Shared.GlobalFunc._deferCounter);
                var helper = target.createEmptyMovieClip(helperName, target.getNextHighestDepth());
                
                helper.onEnterFrame = function() {
                    delete this.onEnterFrame;
                    this.removeMovieClip();
                    Shared.GlobalFunc.Anchor(target, source, tAnchor, sAnchor, offsetX, offsetY);
                };
            } else {
                Shared.GlobalFunc.Anchor(this, source, tAnchor, sAnchor, offsetX, offsetY);
            }
            
            return this;
        };
    }

    /**
     * Core static logic for calculating and applying coordinates.
     * 
     * @param target        The MovieClip to be moved.
     * @param source        The reference MovieClip.
     * @param targetAnchor  Numeric ID (1-9) of the anchor point on the target.
     * @param sourceAnchor  Numeric ID (1-9) of the anchor point on the source.
     * @param offsetX       Horizontal translation.
     * @param offsetY       Vertical translation.
     */
    public static function Anchor(target:MovieClip, source:MovieClip, targetAnchor:Number, sourceAnchor:Number, offsetX:Number, offsetY:Number) {
        if (!target || !source) return;
        
        var destPt = Shared.GlobalFunc._getAnchorPointGlobal(source, sourceAnchor);
        if (!destPt || isNaN(destPt.x) || isNaN(destPt.y)) return;
        
        destPt.x += (offsetX != undefined ? offsetX : 0);
        destPt.y += (offsetY != undefined ? offsetY : 0);
        
        var targetPt = Shared.GlobalFunc._getAnchorPointLocal(target, targetAnchor);
        target.localToGlobal(targetPt);
        if (!targetPt || isNaN(targetPt.x) || isNaN(targetPt.y)) return;
        
        var parent = target._parent;
        if (parent) {
            parent.globalToLocal(destPt);
            parent.globalToLocal(targetPt);
        }
        
        target._x += (destPt.x - targetPt.x);
        target._y += (destPt.y - targetPt.y);
    }

    /**
     * Converts a string anchor code to a numeric Numpad-style ID (1-9).
     * 
     * @param anchorType    String code (e.g., "TL", "TC", "BR").
     * @return              Numeric ID (1=TL, 2=TC, 3=TR, 4=CL, 5=C, 6=CR, 7=BL, 8=BC, 9=BR).
     */
    private static function _parseAnchorString(anchorType:String) {
        var map = {TL:1, T:2, TC:2, TR:3, L:4, CL:4, C:5, CR:6, R:6, BL:7, B:8, BC:8, BR:9};
        var key = (anchorType && typeof anchorType == "string") ? anchorType.toUpperCase() : "C";
        return map[key] || 5;
    }

    /**
     * Calculates the vertically mirrored anchor point.
     * 
     * @param anchor    Original anchor numeric ID.
     * @return          Opposite anchor ID (e.g., Top becomes Bottom).
     */
    private static function _parseOppositeAnchor(anchor:Number) {
        var flip = [5, 7, 8, 9, 4, 5, 6, 1, 2, 3];
        return flip[anchor] || 5;
    }

    /**
     * Retrieves global stage coordinates for a specific anchor point on a clip.
     * 
     * @param clip      The MovieClip to inspect.
     * @param anchor    Anchor point numeric ID.
     * @return          Object with global {x, y}.
     */
    private static function _getAnchorPointGlobal(clip:MovieClip, anchor:Number) {
        var pt = Shared.GlobalFunc._getAnchorPointLocal(clip, anchor);
        clip.localToGlobal(pt); 
        return pt;
    }

    /**
     * Calculates local coordinates of an anchor point relative to the clip's visual bounds.
     * 
     * @param clip      The MovieClip to inspect.
     * @param anchor    Anchor point numeric ID (1-9).
     * @return          Object with local {x, y}.
     */
    private static function _getAnchorPointLocal(clip:MovieClip, anchor:Number) {
        var b = clip.getBounds(clip);
        var xMin:Number = b.xMin != undefined ? b.xMin : 0;
        var xMax:Number = b.xMax != undefined ? b.xMax : 0;
        var yMin:Number = b.yMin != undefined ? b.yMin : 0;
        var yMax:Number = b.yMax != undefined ? b.yMax : 0;
        
        // Protection against crooked anchors (return to center)
        anchor = (anchor > 0 && anchor < 10) ? anchor : 5; 
        
        var col = (anchor - 1) % 3;             // 0: Left, 1: Center, 2: Right
        var row = Math.floor((anchor - 1) / 3); // 0: Up,   1: Middle, 2: Down
        
        var x = (col == 0) ? xMin : (col == 2 ? xMax : (xMin + xMax) / 2);
        var y = (row == 0) ? yMin : (row == 2 ? yMax : (yMin + yMax) / 2);
        
        return {x: x, y: y};
    }

    static function SetExtendedLayoutFunctions()
    {
        /**
         * Horizontally aligns and distributes a set of child MovieClips within the bounds of this MovieClip.
         * This method acts as a layout engine inspired by the CSS Flexbox 'justify-content' property.
         * 
         * Positioning is calculated based on the current width (`_width`) and horizontal position (`_x`) 
         * of the container MovieClip.
         * 
         * @param aChildren  {Array}  An array of MovieClips to be aligned. Only clips where `_visible == true` are included in calculations.
         * @param aMode      {String} The distribution algorithm to use:
         *                            - "flex-start":    Clips are packed toward the left edge.
         *                            - "flex-end":      Clips are packed toward the right edge.
         *                            - "center":        Clips are centered horizontally.
         *                            - "space-between": Clips are evenly distributed; first clip is at the left, last is at the right.
         *                            - "space-around":  Clips are evenly distributed with half-size spaces on the ends.
         *                            - "space-evenly":  Clips are distributed so that all gaps (including edges) are equal.
         * @param aGap       {Number} The fixed spacing (in pixels) to apply between items for "flex" modes, 
         *                            or the fallback gap value.
         * 
         * @example
         * myContainer.JustifyContent(iconsArray, "flex-start", 10);
         */
        MovieClip.prototype.JustifyContent = function(aChildren: Array, aMode: String, aGap: Number)
        {
            var items: Array = [];
            var totalItemsWidth: Number = 0;
            
            for (var i: Number = 0; i < aChildren.length; i++) {
                if (aChildren[i]._visible) {
                    items.push(aChildren[i]);
                    totalItemsWidth += aChildren[i]._width;
                }
            }

            var n: Number = items.length;
            if (n == 0) return;

            var freeSpace: Number = this._width - totalItemsWidth;
            var currentX: Number = this._x;
            
            if (aGap == undefined) aGap = 0;
            var gap: Number = aGap;

            switch (aMode) {
                case "flex-start":
                    gap = aGap;
                    break;
                case "flex-end":
                    gap = aGap;
                    currentX += freeSpace;
                    break;
                case "center":
                    gap = aGap;
                    currentX += freeSpace / 2;
                    break;
                case "space-between":
                    gap = (n > 1) ? freeSpace / (n - 1) : aGap;
                    break;
                case "space-around":
                    gap = freeSpace / n;
                    currentX += gap / 2;
                    break;
                case "space-evenly":
                    gap = freeSpace / (n + 1);
                    currentX += gap;
                    break;
            }

            for (var j: Number = 0; j < n; j++) {
                items[j]._x = currentX;
                currentX += items[j]._width + gap;
            }
        };
    }
}
