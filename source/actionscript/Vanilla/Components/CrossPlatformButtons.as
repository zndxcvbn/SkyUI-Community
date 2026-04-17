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
   var iconClips = [];
   
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

   function attachIcon(targetObj, instanceName, targetValue, fallbackValue)
   {
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
   }
   /* @override Use ButtonArt.swf instead embedded DefineSprite btns in each .swf 
      Fallback: Vanilla behavior (attachMovie DefineSprite btns from its own .swf)
   */
   function RefreshArt()
   {
      this.removeAllIcons();
      
      var iconNames = this.getIconNamesForCurrentPlatform();
      
      if(iconNames == null || iconNames.length == 0)
      {
         return;
      }
      
      this.ButtonArt_mc = this.createEmptyMovieClip("ButtonArt_mc", this.getNextHighestDepth());
      this.ButtonArt = this.ButtonArt_mc;
      this.iconClips = [];
      
      var currentX = 0;
      
      for(var i = 0; i < iconNames.length; i++)
      {
         var iconName = iconNames[i];
         if(iconName == "None" || iconName == undefined)
         {
            continue;
         }
         
         if(iconName == "+")
         {
            var plusTF = this.ButtonArt_mc.createTextField("plus_" + i, this.ButtonArt_mc.getNextHighestDepth(), currentX, 0, 10, 10);
            plusTF.autoSize = "left";
            plusTF.selectable = false;
            
            var tfFormat;
            if(this.textField != undefined)
            {
               plusTF.embedFonts = this.textField.embedFonts;
               tfFormat = this.textField.getTextFormat();
               plusTF.setNewTextFormat(tfFormat);
            }
            else
            {
               tfFormat = new TextFormat();
               tfFormat.size = 20;
               tfFormat.color = 0xFFFFFF;
               plusTF.setNewTextFormat(tfFormat);
            }
            
            plusTF.text = "+";
            
            if(this.textField != undefined)
            {
               plusTF.setTextFormat(this.textField.getTextFormat());
            }
            
            plusTF._y = (this._height - plusTF._height) / 2;
            currentX += plusTF._width;
            
            this.iconClips.push(plusTF);
            continue;
         }
         
         var iconClip = this.attachIcon(this.ButtonArt_mc, "icon_" + i, iconName);
         if(iconClip != undefined)
         {
            iconClip._x = currentX;
            iconClip._y = (this._height - iconClip._height) / 2;
            currentX += iconClip._width;
            this.iconClips.push(iconClip);
         }
      }
      
      if(this.ButtonArt_mc != undefined)
      {
         this.ButtonArt_mc._x = -this.ButtonArt_mc._width;
         this.ButtonArt_mc._y = 0;
      }
      
      this.Reposition();
      if(this.border != undefined) this.border._visible = false;
   }
   
   function getIconNamesForCurrentPlatform()
   {
      var primaryString;
      var secondaryString = null;
      var fallbackPrimary = null;
      var fallbackSecondary = null;
      
      switch(this.CurrentPlatform)
      {
         case Shared.ButtonChange.PLATFORM_PC:
            primaryString = this.PCButton;
            secondaryString = this.PCButtonSecondary;
            break;
            
         case Shared.ButtonChange.PLATFORM_PC_GAMEPAD:
         case Shared.ButtonChange.PLATFORM_360:
         case Shared.ButtonChange.PLATFORM_SCARLETT:
            primaryString = this.XBoxButton;
            secondaryString = this.XBoxButtonSecondary;
            break;
            
         case Shared.ButtonChange.PLATFORM_PS3:
         case Shared.ButtonChange.PLATFORM_PROSPERO:
         default:
            primaryString = this.PS3Button;
            secondaryString = this.PS3ButtonSecondary;
            fallbackPrimary = primaryString;
            fallbackSecondary = secondaryString;
            
            gfx.io.GameDelegate.call("myLog",[String(primaryString)]);
            
            if(this.PS3Swapped)
            {
               primaryString = this.swapPS3Buttons(primaryString);
               secondaryString = this.swapPS3Buttons(secondaryString);
            }
            
            if(this.CurrentPlatform == Shared.ButtonChange.PLATFORM_PROSPERO)
            {
               primaryString = this.convertToPS5(primaryString);
               secondaryString = this.convertToPS5(secondaryString);
            }
            
            gfx.io.GameDelegate.call("myLog",[String(primaryString)]);
            break;
      }
      
      var allIcons =[];
      
      if(primaryString != "None" && primaryString != undefined)
      {
         var primaryIcons = this.parseIconString(primaryString);
         allIcons = allIcons.concat(primaryIcons);
      }
      
      if(secondaryString != null && secondaryString != "None" && secondaryString != undefined)
      {
         var secondaryIcons = this.parseIconString(secondaryString);
         allIcons = allIcons.concat(secondaryIcons);
      }
      
      return allIcons;
   }
   
   function parseIconString(iconString)
   {
      if(iconString == undefined || iconString == null || iconString == "None")
      {
         return[];
      }
      
      if(typeof(iconString) != "string")
      {
         return[String(iconString)];
      }
      
      return iconString.split("+").join("|+|").split("|");
   }
   
   function swapPS3Buttons(buttonName)
   {
      if(buttonName == undefined) return buttonName;
      
      if(typeof(buttonName) == "string" && (buttonName.indexOf("|") != -1 || buttonName.indexOf("+") != -1))
      {
         var tempStr = buttonName.split("+").join("|+|");
         var parts = tempStr.split("|");
         for(var i = 0; i < parts.length; i++)
         {
            if(parts[i] == "PS3_A") parts[i] = "PS3_B";
            else if(parts[i] == "PS3_B") parts[i] = "PS3_A";
         }
         return parts.join("|").split("|+|").join("+");
      }
      
      if(buttonName == "PS3_A") return "PS3_B";
      if(buttonName == "PS3_B") return "PS3_A";
      return buttonName;
   }
   
   function convertToPS5(buttonName)
   {
      if(buttonName == undefined) return buttonName;
      
      if(typeof(buttonName) == "string" && (buttonName.indexOf("|") != -1 || buttonName.indexOf("+") != -1))
      {
         var tempStr = buttonName.split("+").join("|+|");
         var parts = tempStr.split("|");
         for(var i = 0; i < parts.length; i++)
         {
            if(parts[i] != undefined && parts[i].indexOf("PS3_") == 0)
            {
               parts[i] = "PS5_" + parts[i].substr(4);
            }
         }
         return parts.join("|").split("|+|").join("+");
      }
      
      if(typeof(buttonName) == "string" && buttonName.indexOf("PS3_") == 0)
      {
         return "PS5_" + buttonName.substr(4);
      }
      return buttonName;
   }
   
   function removeAllIcons()
   {
      if(this.iconClips)
      {
         for(var i = 0; i < this.iconClips.length; i++)
         {
            if(this.iconClips[i] != undefined)
            {
               this.iconClips[i].removeMovieClip();
            }
         }
         this.iconClips = [];
      }
      
      if(this.ButtonArt_mc != undefined)
      {
         this.ButtonArt_mc.removeMovieClip();
         this.ButtonArt_mc = undefined;
      }
      
      if(this.ButtonArtSecondary_mc != undefined)
      {
         this.ButtonArtSecondary_mc.removeMovieClip();
         this.ButtonArtSecondary_mc = undefined;
      }
      
      this.ButtonArt = undefined;
      this.ButtonArtSecondary = undefined;
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
