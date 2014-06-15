package cffi;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
#end

class Lib
{

   #if !macro
	/**
		Load and return a Dynamic primitive from a DLL library.
	**/
	public static function load( lib : String, prim : String, nargs : Int ) : Dynamic
   {
		#if neko
		return neko.Lib.load(lib,prim,nargs);
		#elseif cpp
		return cpp.Lib.load(lib,prim,nargs);
		#else
      throw "Not implemented for this platform";
      return null;
		#end
	}

   /**
		Tries to load, and always returns a valid function, but the function may throw
		if called.
	**/
	public static function loadLazy(lib,prim,nargs) : Dynamic
   {
		#if neko
		return neko.Lib.loadLazy(lib,prim,nargs);
		#elseif cpp
		return cpp.Lib.loadLazy(lib,prim,nargs);
		#else
      throw "Not implemented for this platform";
      return null;
		#end
   }
   #end

   public static function codeToType(code:String, forCpp:Bool) : String
   {
      switch(code)
      {
         case "b" : return "Bool";
         case "i" : return "Int";
         case "d" : return "Float";
         case "s" : return "String";
         case "f" : return forCpp ? "cpp.Float32" : "Float";
         case "o" : return forCpp ? "cpp.Object" : "Dynamic";
         case "v" : return forCpp ? "cpp.Void" : "Dynamic";
         case "c" :
             if (forCpp)
                return "cpp.RawConstPtr<cpp.Char>";
             throw "const char * type only supported on cpp target";
         default:
            throw "Unknown signature type :" + code + " valid types: b,i,d,s,f,o,v,c";
      }
   }


   public static macro function loadPrime(inModule:String, inName:String, inSig:String,inAllowFail:Bool = false)
   {
      var parts = inSig.split("");
      if (parts.length<1)
         throw "Invalid function signature " + inSig;
      var isCpp = Context.defined("cpp");
      var typeString = parts.length==1 ? codeToType("v",isCpp) : codeToType(parts.shift(),isCpp);
      for(p in parts)
         typeString += "->" + codeToType(p,isCpp);
      var expr = "";
      if (isCpp)
      {
         typeString = "cpp.Function<" + typeString + ">";
         expr = 'new $typeString(cpp.Lib._loadPrime("$inModule","$inName","$inSig",$inAllowFail))';
      }
      else
      {
         var len = parts.length;
         if (len>5)
            len = -1;
         expr = 'new sys.cffi.Callable(neko.Lib.load("$inModule","$inName",$len))';
         if (inAllowFail)
            expr = 'try { $expr; } catch(e:Dynamic) { null; }';
      }
      return Context.parse( expr, Context.currentPos() );
   }


}



