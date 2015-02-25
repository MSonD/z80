module maud.vm.stdDump;
import maud.vm.vmi;
import maud.vm.util;

import std.stdio;  
//Hexdecimal
class StdDump : CoreDumpInterface
{
	size_t wsize = 1;
	uint newline = 16;
	void setWordSize(size_t len){
		wsize = len;
	}
	size_t getWordSize(){
		return wsize;
	}
	void push(loc_t* ptr, size_t tam){
		char[2] buff;
		if(ptr is null)
			return;
		for(size_t k = 0;k < tam;){
			for(size_t i = 0;i<wsize && k < tam;i++,k++){
				binToStr!(16,ubyte)(ptr[k],buff);
				writef(buff);
			}
			write(" ");
			if(k % (wsize*newline) == 0){
				write("\n");

			}
		}
	}
	this(){}
}

unittest{
	writeln("=> StdDump");
	size_t[] data = [ 0xFF, 0x00, 0xDD, 0xAA, 0x12];
	StdDump dumper = new StdDump();
	dumper.setWordSize(1);
	dumper.setWordSize(4);
	dumper.push(cast(ubyte*)data.ptr,5*4);
}