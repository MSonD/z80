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

	void vali(bool premise){
		pass = pass & premise;
	}

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

		//JR 1
		zero[0] = 0x18;
		zero[1] = 0x01;
		//JR -3
		zero[3] = 0x18;
		zero[4] = cast(ubyte)(-3);

		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x3);
		
		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x2);

		return pass;
	}


	bool JR_CC_D(){
		vm.restart();
		pass = true;
		
		//JR NZ, FF
		zero[0] = 0x20;
		zero[1] = 0xFF;
		//JR Z, +1
		zero[2] = 0x28;
		zero[3] = 0x01;
		//JR NC, +0 
		zero[5] = 0x30;
		zero[6] = 0;
		//JR C, FF
		zero[7] = 0x38;
		zero[8] = 0xFF;

		vm.setRegister(RE.F,FLAG_MASK.Z);
		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x2);
		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x5);

		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x7);

		vm.execStep();
		pass = pass && (vm.register2(RE.PC2) == 0x9);
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

	bool ADD_HL_RR(){
		vm.restart();
		pass = true;

		//ADD HL, BC
		zero[0] = 0x09;
		//ADD HL, DE
		zero[1] = 0x19;
		//ADD HL, SP
		zero[2] = 0x39;

		vm.setRegister2(RE.HL2,0xABCD);
		vm.setRegister2(RE.BC2,0x2110);
		vm.setRegister2(RE.DE2,cast(ushort)(~0xF + 1));
		vm.setRegister2(RE.SP2,cast (ushort)(0xF - 0xCCDD));

		vm.execStep();
		pass = pass && (vm.register2(RE.HL2) == 0xCCDD);
		pass = pass && !(vm.register(RE.F) & FLAG_MASK.N);
		pass = pass && !(vm.register(RE.F) & FLAG_MASK.C);

		vm.execStep();
		pass = pass && (vm.register2(RE.HL2) == 0xCCDD - 0xF);

		vm.execStep();
		pass = pass && (vm.register2(RE.HL2) == 0);
		return pass;
	}

	bool LD_mRR_A (){
		vm.restart();
		pass = true;
		
		//LD (BC), A
		zero[0] = 0x02;

		//LD (DE), A
		vm.setRegister(RE.A,0x12);
		vm.setRegister2(RE.BC2,0x0001);
		vm.setRegister2(RE.BC2,0x0042);
		
		vm.execStep();
		vm.execStep();
		vali (zero[0x42] == 0x12);
		
		return pass;
	}

	bool LD_A_mRR (){
		vm.restart();
		pass = true;

		//LD A, (BC)
		zero[0] = 0x0A;
		//LD A, (DE)
		zero[1] = 0x1A;
		zero[0xDED] = 0xBE;

		vm.setRegister2(RE.BC2,0x0001);
		vm.setRegister2(RE.DE2,0x0DED);

		vm.execStep();
		vali (vm.register(RE.A) == 0x1A);
		vm.execStep();
		vali (vm.register(RE.A) == 0xBE);

		return pass;
	}


	mixin(TestElem!(LD_RR_NN,DJNZ_D,JR_D,JR_CC_D,EX_AF_AF,ADD_HL_RR,LD_mRR_A,LD_A_mRR));

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
				"nopassed++;"
				"}"~
			TestElem!(T[1..$]);
	}
}
