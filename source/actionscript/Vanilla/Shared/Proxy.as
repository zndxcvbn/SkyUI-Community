class Shared.Proxy
{
   function Proxy() {}
    
   public static function create(oTarget: Object, fFunction: Function)
   {
      var aParameters: Array = arguments.slice(2);

      return function()
      {
         fFunction.apply(oTarget, arguments.concat(aParameters));
      };
   }
}
