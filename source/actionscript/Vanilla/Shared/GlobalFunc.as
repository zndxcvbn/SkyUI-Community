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
}
