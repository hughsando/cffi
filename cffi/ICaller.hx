package cffi;

#if !macro 
	@:autoBuild(cffi.Caller.buildFields()) 
#end
interface ICaller { }
