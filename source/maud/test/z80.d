module maud.test.z80;
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
		//LD SP, 201H
		zero[0] = 0x31;
		zero[1] = 0x01;
		zero[2] = 0x02;
		//LD HL, 1211H
		zero[3] = 0x21;
		zero[4] = 0x11;
		zero[5] = 0x12;
		//LD BC, FFAAH
		zero[6] = 0x01;
		zero[7] = 0xAA;
		zero[8] = 0xFF;

		vm.execStep();
		pass = pass && (vm.register2(RE.SP2) == 0x201);

		vm.execStep();
		pass = pass && (vm.register2(RE.HL2) == 0x1211);

		vm.execStep();
		pass = pass && (vm.register2(RE.BC2) == 0xFFAA);

		return pass;
	}

	bool DJNZ_D(){
		vm.restart();
		pass = true;

		zero[0] = 0x10;
		zero[1] = 0x05;

		zero[2] = 0x10;
		zero[3] = 0x05;

		zero[9] = 0x10;
		zero[10] = cast(ubyte)-0xB;

		vm.setRegister(RE.B,1);
		vm.execStep();

		pass = pass && (vm.register2(RE.PC2) == 0x2);

		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x9);

		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x0);

		return pass;
	}

	bool JR_D(){
		vm.restart();
		pass = true;
		
		zero[0] = 0x18;
		zero[1] = 0x01;

		zero[3] = 0x18;
		zero[4] = cast(ubyte)(-3);

		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x3);
		
		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x2);

		return pass;
	}

	bool EX_AF_AF(){
		vm.restart();
		pass = true;
		
		zero[0] = 0x08;
		zero[1] = 0x08;
		
		vm.setRegister(RE.A,0xBA);
		vm.setRegister(RE.F,0xCA);

		vm.execStep();
		pass = pass && (vm.register(RE.AP) == 0xBA);
		pass = pass && (vm.register(RE.FP) == 0xCA);

		vm.execStep();
		pass = pass && (vm.register(RE.A) == 0xBA);
		pass = pass && (vm.register(RE.A) == 0xBA);

		return pass;
	}

	mixin(TestElem!(LD_RR_NN,DJNZ_D,JR_D,EX_AF_AF));

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
			"if("~id~"()){"
				"writeln(\"PASSED\");"
				"passed++;"
			"}else{"
				"writeln(\"FAILED\");"
				"passed++;"
				"}"~
			TestElem!(T[1..$]);
	}
}
