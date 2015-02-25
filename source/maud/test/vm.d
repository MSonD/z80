module maud.test.vm;
import std.stdio;
import maud.vm.arrayMem;
import maud.vm.stdDump;
import maud.vm.z80;

int[2] testVM(){
	uint passed;
	uint nopassed;

	StdDump dumper = new StdDump();
	dumper.setWordSize(2);
	auto mem = arrayMem.create(64*1024);
	auto zero = mem.getAddress(0);
	auto vm = new Z80VM(mem);
	bool pass;

	bool LD_RR_NN(){
		vm.restart();
		pass = true;
		zero[0] = 0x31;
		zero[1] = 0x01;
		zero[2] = 0x02;

		vm.execStep();
		pass = pass && (vm.register2(RE.SP2) == 0x201);
		return pass;
	}
	bool DJNZ_D(){
		vm.restart();
		pass = true;
		vm.setRegister(RE.B,2);
		vm.execStep();
		pass = pass && (vm.register2(RE.SP2) == 0x201);
		return pass;
	}
	mixin(TestElem!(LD_RR_NN,LD_RR_NN,LD_RR_NN));

	return [passed, nopassed];
}

template Test(T...){

}

template TestElem(T...){
	static if(T.length == 0){
		enum TestElem = "";
	}else{
		enum id = __traits(identifier,T[0]);
		enum TestElem = "write(\""~id~"  \");"
			"writeln( "~id~"() ? \"PASSED\" : \"FAILED\"); "~
			TestElem!(T[0..$-1]);
	}
}