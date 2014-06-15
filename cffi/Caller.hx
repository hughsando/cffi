package cffi;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
using haxe.macro.ExprTools;
#end


class Caller
{
   public static macro function buildFields( ) : Array<Field>
   {
       var fields = Context.getBuildFields();
       for(i in 0...fields.length)
       {
          try {
             fields[i] = transform(fields[i]);
          }
          catch( e:Dynamic )
          {
             var cls = "Unknown";
             var from = Context.getLocalClass();
             if (from!=null)
                cls = from.toString();

             Context.error( "Error in cffi for field " + fields[i].name + " in " + cls + " :" + e,
                haxe.macro.Context.currentPos() );
          }
       }
       return fields;
   }

   public static function metaString(e:Expr) : String
   {
      return e.getValue();
   }

   public static function codeToComplexType(code:String) : ComplexType
   {
      if (!Context.defined("cpp"))
         switch(code)
         {
            case "f" : code = "d";
            case "v" : code = "D";
            case "o" : code = "D";
            default:
         }
      switch(code)
      {
         case "b" : return TPath( { pack:[], name:"Bool" } );
         case "i" : return TPath( { pack:[], name:"Int" } );
         case "d" : return TPath( { pack:[], name:"Float" } );
         case "s" : return TPath( { pack:[], name:"String" } );
         case "o" : return TPath( { pack:["cpp"], name:"Object" } );
         case "D" : return TPath( { pack:[], name:"Dynamic" } );
         case "f" : return TPath( { pack:["cpp"], name:"Float32" } );
         case "v" : return TPath( { pack:["cpp"], name:"Void" } );
         case "c" :
             if (Context.defined("cpp"))
                return TPath( { pack:["cpp"], name:"RawConstPtr",
                      params: [TPType( TPath( { pack:["cpp"], name:"Char" } ) )  ] } );
             throw "const char * type only supported on cpp target";
         default:
             throw "Unknown signature type :'" + code + "' valid types: b,i,d,s,f,o,v,c";

      }
      return null;
      
   }

   public static function createCffiVar(inPrim:String, inDll:String, inSig:String)
   {
      var e:Expr = null;
      var type:ComplexType = null;

      var args = new Array<ComplexType>();
      var parts = inSig.split("");
      if (parts.length==0)
          throw "no return type specified";
      var ret = codeToComplexType(parts.pop());
      for(p in parts)
         args.push( codeToComplexType(p) );

      return FVar( TPath( { pack:["cffi"], name:"Callable", params:[TPType(TFunction(args,ret))]}), e );
   }

   public static function transform(field:Field):Field
   {
      switch(field.kind)
      {
         case FVar(t,e):
            var cffi:String = null;
            var dll:String = null;
            var prim:String = field.name;

            var from = Context.getLocalClass();
            if (from!=null)
            {
               var parts = from.toString().split(".");
               if (parts.length>1)
                  dll = parts[0];
            }

            if (field.meta!=null)
               for(meta in field.meta)
                  if (meta.name=="cffi" && meta.params!=null)
                  {
                     if (meta.params.length>0)
                        cffi = metaString(meta.params[0]);
                     if (meta.params.length>1)
                        dll = metaString(meta.params[1]);
                     if (meta.params.length>2)
                        prim = metaString(meta.params[2]);
                     break;
                 }
            if (cffi!=null)
               field.kind = createCffiVar(prim, dll, cffi);
         default:
      }

      return field;
   }
}
