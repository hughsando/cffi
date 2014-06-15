package cffi;

#if !macro 
	@:autoBuild(cffi.Caller.buildFields()) 
#end
@:remove
interface ICaller { }
