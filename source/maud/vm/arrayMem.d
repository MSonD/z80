module maud.vm.arrayMem;
import maud.vm.vmi;
import maud.vm.error;
class ArrayMem : MemInterface
{
	private size_t[] arr;
	loc_t* acc;
	this (size_t size){
		//Redondear hacia arriba
		auto rmd = size%size_t.sizeof;
		arr.length = (size-rmd)/size_t.sizeof + (rmd == 0?0:1);
		acc = cast(loc_t *)arr.ptr;
	}
	loc_t* getAddress(size_t place,short wordsize = 1){
		auto dir  = place * loc_t.sizeof/wordsize;
		version(SAFE){
			if(dir >= size)
				throw new VMMemoryException(place);
		}
		return acc+(dir);
	}

	size_t size(){
		return arr.length*(size_t.sizeof/loc_t.sizeof);
	}

	version(_){
	uint query(size_t loc){
		return *(cast(uint*)(acc + loc));
	}
	ulong queryl(size_t loc){
		return *(cast(ulong*)(acc + loc));
	}
	ushort querys(size_t loc){
		return *(cast(ushort*)(acc + loc));
	}
	ubyte queryb(size_t loc){
		return *(cast(ubyte*)(acc + loc));
	}
	}

	//Size in bytes
	static MemInterface create(size_t size){
		return new ArrayMem(size);
	}
}

unittest{
	import std.stdio;
	writeln("=> ArrayMem");
	auto mem = arrayMem.create(33);
	assert(mem.size()%size_t.sizeof == 0);
	(cast(ubyte*) mem.getAddress(0)) [34] = 255;
}