package cffi;

#if cpp

typedef Callable<T> = cpp.Function<T>;

#else

abstract Callable<T>(T)
{
   public var call(get,never):T;

   inline public function new(inValue:T) this = inValue;

   inline function get_call():T return this;
}

#end
