class Shared.PlatformChangeUser extends MovieClip
{
  /* CONSTANTS */

   public static var PlatformChange;


  /* INITIALIZATION */

   public function PlatformChangeUser()
   {
      super();
      Shared.PlatformChangeUser.PlatformChange = new Shared.ButtonChange();
   }


  /* PUBLIC FUNCTIONS */

   public function RegisterPlatformChangeListener(aCrossPlatformButton)
   {
      Shared.PlatformChangeUser.PlatformChange.addEventListener("platformChange", aCrossPlatformButton, "SetPlatform");
      Shared.PlatformChangeUser.PlatformChange.addEventListener("SwapPS3Button", aCrossPlatformButton, "SetPS3Swap");
   }
}
