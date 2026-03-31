class Components.CrossPlatformButtons extends gfx.controls.Button
{
   var ButtonArt;
   var ButtonArtSecondary;
   var ButtonArtSecondary_mc;
   var ButtonArt_mc;
   var CurrentPlatform;
   var OnTextFieldChanged;
   var PCButton;
   var PS3Button;
   var PS3Swapped;
   var XBoxButton;
   var _height;
   var _parent;
   var attachMovie;
   var border;
   var getNextHighestDepth;
   var textField;
   var XBoxButtonSecondary = null;
   var PS3ButtonSecondary = null;
   var PCButtonSecondary = null;
   function CrossPlatformButtons()
   {
      super();
      this.textField.onChanged = Shared.Proxy.create(this,this.Reposition);
      gfx.io.GameDelegate.call("myLog",["CrossPlatformButtons::CrossPlatformButtons"]);
   }
   function onLoad()
   {
      super.onLoad();
      if(this._parent.onButtonLoad != undefined)
      {
         this._parent.onButtonLoad(this);
      }
      gfx.io.GameDelegate.call("myLog",["CrossPlatformButtons::onLoad"]);
   }
   function SetPlatform(aiPlatform, aSwapPS3)
   {
      gfx.io.GameDelegate.call("myLog",["CrossPlatformButtons::SetPlatform"]);
      if(aiPlatform != undefined)
      {
         this.CurrentPlatform = aiPlatform;
      }
      if(aSwapPS3 != undefined)
      {
         this.PS3Swapped = aSwapPS3;
      }
      this.RefreshArt();
   }
   /* @override Use ButtonArt.swf instead embedded DefineSprite btns in each .swf */
   function RefreshArt()
   {
      if(undefined != this.ButtonArt)
      {
         this.ButtonArt.removeMovieClip();
      }
      if(undefined != this.ButtonArtSecondary)
      {
         this.ButtonArtSecondary.removeMovieClip();
      }
      if(undefined != this.ButtonArt_mc)
      {
         this.ButtonArt_mc.removeMovieClip();
      }
      if(undefined != this.ButtonArtSecondary_mc)
      {
         this.ButtonArtSecondary_mc.removeMovieClip();
      }
      
      var _loc2_;
      var _loc3_;
      var _loc5_;
      var _loc4_;
      
      var attachIcon = function(targetObj, instanceName, targetValue, fallbackValue) {
         var newClip = targetObj.attachMovie("ButtonArt", instanceName, targetObj.getNextHighestDepth());
         if (newClip != undefined) {
            newClip.gotoAndStop(targetValue);
            if (fallbackValue != undefined && newClip._currentframe == 1 && targetValue != 1 && targetValue != "Keyboard") {
               newClip.gotoAndStop(fallbackValue);
            }
         } else {
            newClip = targetObj.attachMovie(targetValue, instanceName, targetObj.getNextHighestDepth());
            if (newClip == undefined && fallbackValue != undefined) {
               newClip = targetObj.attachMovie(fallbackValue, instanceName, targetObj.getNextHighestDepth());
            }
         }
         return newClip;
      };

      switch(this.CurrentPlatform)
      {
         case Shared.ButtonChange.PLATFORM_PC:
            if(this.PCButton != "None" && this.PCButton != undefined)
            {
               this.ButtonArt_mc = attachIcon(this, "ButtonArt", this.PCButton);
            }
            if(this.PCButtonSecondary != null && this.PCButtonSecondary != undefined)
            {
               this.ButtonArtSecondary_mc = attachIcon(this, "ButtonArtSecondary", this.PCButtonSecondary);
            }
            break;
            
         case Shared.ButtonChange.PLATFORM_PC_GAMEPAD:
         case Shared.ButtonChange.PLATFORM_360:
         case Shared.ButtonChange.PLATFORM_SCARLETT:
            if(this.XBoxButton != "None" && this.XBoxButton != undefined)
            {
               this.ButtonArt_mc = attachIcon(this, "ButtonArt", this.XBoxButton);
            }
            if(this.XBoxButtonSecondary != null && this.XBoxButtonSecondary != undefined)
            {
               this.ButtonArtSecondary_mc = attachIcon(this, "ButtonArtSecondary", this.XBoxButtonSecondary);
            }
            break;
            
         case Shared.ButtonChange.PLATFORM_PS3:
         case Shared.ButtonChange.PLATFORM_PROSPERO:
         default:
            _loc2_ = this.PS3Button;
            _loc3_ = this.PS3ButtonSecondary;
            gfx.io.GameDelegate.call("myLog",[String(_loc2_)]);
            
            if(this.PS3Swapped)
            {
               if(_loc2_ == "PS3_A") _loc2_ = "PS3_B";
               else if(_loc2_ == "PS3_B") _loc2_ = "PS3_A";
               
               if(_loc3_ == "PS3_A") _loc3_ = "PS3_B";
               else if(_loc3_ == "PS3_B") _loc3_ = "PS3_A";
            }
            
            _loc5_ = _loc2_;
            _loc4_ = _loc3_;
            
            if(this.CurrentPlatform == Shared.ButtonChange.PLATFORM_PROSPERO)
            {
               var convertToPS5 = function(buttonName)
               {
                  if(buttonName != undefined && buttonName.indexOf("PS3_") == 0)
                  {
                     return "PS5_" + buttonName.substr(4);
                  }
                  return buttonName;
               };
               
               _loc2_ = convertToPS5(_loc2_);
               _loc3_ = convertToPS5(_loc3_);
            }
            
            gfx.io.GameDelegate.call("myLog",[String(_loc2_)]);
            
            if(_loc2_ != "None" && _loc2_ != undefined)
            {
               this.ButtonArt_mc = attachIcon(this, "ButtonArt", _loc2_, _loc5_);
            }
            
            if(_loc3_ != null && _loc3_ != undefined)
            {
               this.ButtonArtSecondary_mc = attachIcon(this, "ButtonArtSecondary", _loc3_, _loc4_);
            }
            break;
      }
      
      if(this.ButtonArt_mc != undefined)
      {
         this.ButtonArt_mc._x -= this.ButtonArt_mc._width;
         this.ButtonArt_mc._y = (this._height - this.ButtonArt_mc._height) / 2;
      }
      
      if(this.ButtonArtSecondary_mc != undefined)
      {
         this.ButtonArtSecondary_mc._y = this.ButtonArt_mc._y;
      }
      
      this.Reposition();
      if(this.border != undefined) this.border._visible = false;
   }
   function GetArt()
   {
      var _loc2_ = null;
      if(this.PCArtSecondary != undefined)
      {
         _loc2_ = {PCArt:this.PCButton,XBoxArt:this.XBoxButton,PS3Art:this.PS3Button,PCArtSecondary:this.PCButtonSecondary,XBoxArtSecondary:this.XBoxButtonSecondary,PS3ArtSecondary:this.PS3ButtonSecondary};
      }
      else
      {
         _loc2_ = {PCArt:this.PCButton,XBoxArt:this.XBoxButton,PS3Art:this.PS3Button};
      }
      return _loc2_;
   }
   function SetArt(aPlatformArt)
   {
      this.PCArt = aPlatformArt.PCArt;
      this.XBoxArt = aPlatformArt.XBoxArt;
      this.PS3Art = aPlatformArt.PS3Art;
      if(aPlatformArt.PCArtSecondary != undefined)
      {
         this.PCArtSecondary = aPlatformArt.PCArtSecondary;
         this.XBoxArtSecondary = aPlatformArt.XBoxArtSecondary;
         this.PS3ArtSecondary = aPlatformArt.PS3ArtSecondary;
      }
      this.RefreshArt();
   }
   function get XBoxArt()
   {
      return null;
   }
   function set XBoxArt(aValue)
   {
      if(aValue != "")
      {
         this.XBoxButton = aValue;
      }
   }
   function get XBoxArtSecondary()
   {
      return null;
   }
   function set XBoxArtSecondary(aValue)
   {
      if(aValue != "")
      {
         this.XBoxButtonSecondary = aValue;
      }
   }
   function get PS3Art()
   {
      return null;
   }
   function set PS3Art(aValue)
   {
      if(aValue != "")
      {
         this.PS3Button = aValue;
      }
   }
   function get PS3ArtSecondary()
   {
      return null;
   }
   function set PS3ArtSecondary(aValue)
   {
      if(aValue != "")
      {
         this.PS3ButtonSecondary = aValue;
      }
   }
   function get PCArt()
   {
      return null;
   }
   function set PCArt(aValue)
   {
      if(aValue != "")
      {
         this.PCButton = aValue;
      }
   }
   function get PCArtSecondary()
   {
      return null;
   }
   function set PCArtSecondary(aValue)
   {
      if(aValue != "")
      {
         this.PCButtonSecondary = aValue;
      }
   }
   function Reposition()
   {
      this.ButtonArtSecondary_mc._x = this.textField._width;
      if(this.OnTextFieldChanged != undefined)
      {
         this.OnTextFieldChanged.call();
      }
   }
}
