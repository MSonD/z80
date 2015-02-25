module maud.vm.error;
import maud.vm.util;

private enum digit_size = 4;
class VMException : Exception
{
	this(string tail)
	{
		super(tail);
	}
}

class VMMemoryException : VMException{
	size_t _loc;
	size_t _inst_loc;
	this(){
		super("Memoria fuera de rango");
	}

	this(size_t loc){
		_loc = loc;
		super("Memoria "~binToStr(loc,digit_size)~" fuera de rango");
	}
	this (size_t loc, size_t inst_loc){
		_inst_loc = inst_loc;
		super("Memoria "~binToStr(loc,digit_size)~" invocada desde "~binToStr(inst_loc,digit_size)~" fuera de rango");
	}
}

class VMProtectionException : VMException{
	size_t _loc;
	size_t _inst_loc;
	this(){
		super("Escritura en memoria protegida");
	}
	
	this(size_t loc){
		_loc = loc;
		super("Escritura en "~binToStr(loc,digit_size)~" protegida");
	}
	this (size_t loc, size_t inst_loc){
		_inst_loc = inst_loc;
		super("Escritura en "~binToStr(loc,digit_size)~" invocada desde "~binToStr(inst_loc,digit_size)~" esta protegida");
	}
}


class VMInternalException : VMException{
	this(string msg = ""){
		if(msg != "")
			super("Error interno: "~msg);
		else
			super ("Error interno");
	}
}
