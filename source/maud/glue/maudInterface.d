module maud.glue.maudInterface;
import maud.vm.vmi;
import maud.glue.lua;
import maud.vm.constants;
import maud.read.I8Reader;
import luad.state;
import std.stdio;
import std.utf;
import std.traits;

class ApplicationContext{
	this(VMInterface x){
		machine = x;	
		L = createLua(this);
	}
	@property VMInterface VM(){
		return machine;
	}

	@property VMInterface VM(VMInterface n){
		return machine = n;
	}

	void seek(uint loc){
		this.loc = loc % machine.getNetSize;
		//TODO: signal overflow
	}

	void put(ubyte p){
		*machine.memory.getAddress(loc) = p;
		loc = ++loc % machine.getNetSize;
	}
	void p(ubyte[] p...){
		foreach(data; p)
			put(data);
	}

	void clear(){
		auto data = machine.memory.getAddress;
		for(size_t i = 0;i < machine.getNetSize;i++)
			data[i] = 0;
		machine.restart();
	}

	ubyte get(size_t pos){
		return *machine.memory.getAddress(std.math.abs(pos % machine.getNetSize));
	}

	void command(dstring s){
		L.doString(s.toUTF8);
	}

	LuaState getLua(){
		return L;
	}

	void load(string fname){
		auto f = File(fname);
		I8Reader.read(VM.memory,f.byLine());
	}


private:
	VMInterface machine;
	uint loc;
	LuaState L;
}