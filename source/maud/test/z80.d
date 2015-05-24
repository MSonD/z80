module maud.test.z80;
import maud.defines;
import maud.vm.arrayMem;
import maud.vm.stdDump;
import maud.vm.z80;

int[2] testVM(){
	uint passed;
	uint nopassed;

	StdDump dumper = new StdDump();
	dumper.setWordSize(4);

	auto mem = ArrayMem.create(64*1024);
	auto zero = mem.getAddress(0);
	auto vm = new Z80VM(mem);
	bool pass = true;

	void vali(lazy bool premise){
		pass = pass & premise;
	}

	bool littleBig(){
		vm.setRegister2(RE.HL2,0x0102);
		vali(vm.getRegister(RE.H) == 0x01);
		vali(vm.getRegister(RE.L) == 0x02);
		return pass;
	}

	bool LD_RR_NN(){
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

		vm.executeStep();
		vali (vm.getRegister2(RE.SP2) == 0x201);

		vm.executeStep();
		vali (vm.getRegister2(RE.HL2) == 0x1211);

		vm.executeStep();
		vali (vm.getRegister2(RE.BC2) == 0xFFAA);

		return pass;
	}

	bool DJNZ_D(){
		zero[0] = 0x10;
		zero[1] = 0x05;

		zero[2] = 0x10;
		zero[3] = 0x05;

		zero[9] = 0x10;
		zero[10] = cast(ubyte)-0xB;

		vm.setRegister(RE.B,1);
		vm.executeStep();

		vali (vm.getRegister2(RE.PC2) == 0x2);

		vm.executeStep();
		vali (vm.getRegister2(RE.PC2) == 0x9);

		vm.executeStep();
		vali (vm.getRegister2(RE.PC2) == 0x0);

		return pass;
	}

	bool JR_D(){
		//JR 1
		zero[0] = 0x18;
		zero[1] = 0x01;
		//JR -3
		zero[3] = 0x18;
		zero[4] = cast(ubyte)(-3);

		vm.executeStep();
		vali (vm.getRegister2(RE.PC2) == 0x3);
		
		vm.executeStep();
		vali (vm.getRegister2(RE.PC2) == 0x2);

		return pass;
	}

	
	bool JR_CC_D(){
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
		vm.executeStep();
		vali (vm.getRegister2(RE.PC2) == 0x2);
		vm.executeStep();
		vali (vm.getRegister2(RE.PC2) == 0x5);

		vm.executeStep();
		vali (vm.getRegister2(RE.PC2) == 0x7);

		vm.executeStep();
		vali (vm.getRegister2(RE.PC2) == 0x9);
		return pass;
	}

	bool EX_AF_AF(){
		//EX AF AF
		zero[0] = 0x08;
		zero[1] = 0x08;
		
		vm.setRegister(RE.A,0xBA);
		vm.setRegister(RE.F,0xCA);

		vm.executeStep();
		vali (vm.getRegister(RE.AP) == 0xBA);
		vali (vm.getRegister(RE.FP) == 0xCA);

		vm.executeStep();
		vali (vm.getRegister(RE.A) == 0xBA);
		vali (vm.getRegister(RE.A) == 0xBA);

		return pass;
	}

	bool ADD_HL_RR(){
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

		vm.executeStep();
		vali (vm.getRegister2(RE.HL2) == 0xCCDD);
		vali (!(vm.getRegister(RE.F) & FLAG_MASK.N));
		vali (!(vm.getRegister(RE.F) & FLAG_MASK.C));

		vm.executeStep();
		vali (vm.getRegister2(RE.HL2) == 0xCCDD - 0xF);

		vm.setRegister(RE.F,0);
		vm.executeStep();
		vali (vm.getRegister2(RE.HL2) == 0);
		return pass;
	}

	bool LD_mRR_A (){
		//LD (BC), A
		zero[0] = 0x02;
		vm.setRegister(RE.A,0x12);
		vm.setRegister2(RE.BC2,0x0001);
		vm.setRegister2(RE.BC2,0x0042);
		
		vm.executeStep();
		vm.executeStep();
		vali (zero[0x42] == 0x12);
		
		return pass;
	}

	bool LD_A_mRR (){
		//LD A, (BC)
		zero[0] = 0x0A;
		//LD A, (DE)
		zero[1] = 0x1A;
		zero[0xDED] = 0xBE;

		vm.setRegister2(RE.BC2,0x0001);
		vm.setRegister2(RE.DE2,0x0DED);

		vm.executeStep();
		vali (vm.getRegister(RE.A) == 0x1A);
		vm.executeStep();
		vali (vm.getRegister(RE.A) == 0xBE);

		return pass;
	}

	bool LD_HL_NN(){
		//LD HL, (2050H)
		zero[0] = 0x2A;
		zero[1] = 0x50;
		zero[2] = 0x20;

		zero[0x2050] = 0x19;
		zero[0x2051] = 0x86;

		vm.executeStep();
		vali(vm.getRegister(RE.H) == 0x86);
		vali(vm.getRegister(RE.L) == 0x19);

		return pass;
	}

	bool LD_A_NN(){
		//LD A, 0002H
		zero[0] = 0x3A;
		zero[1] = 0x03;
		zero[2] = 0x00;
		zero[3] = 0x06;

		vm.setRegister(RE.A,90);
		vm.executeStep();
		vali(vm.getRegister(RE.A) == 6);
		//
		return pass;
	}

	bool INC_RR(){
		//INC BC
		zero[0] =  0x03;
		//INC DE
		zero[1] = 0x13;
		//INC SP
		zero[2] = 0x33;

		vm.setRegister2(RE.BC2,0xFFFF);
		vm.setRegister2(RE.SP2,0xFDAF);
		vm.executeStep();
		vali(vm.getRegister2(RE.BC2) == 0);
		vm.executeStep();
		vali(vm.getRegister2(RE.DE2) == 1);
		vm.executeStep();
		vali(vm.getRegister2(RE.SP2) == 0xFDB0);
		return pass;
	}

	bool DEC_RR(){
		//DEC BC
		zero[0] = 0x0B;
		//DEC HL
		zero[1] = 0x2B;
		//DEC SP
		zero[2] = 0x3B;
		
		vm.setRegister2(RE.BC2,0x1);
		vm.setRegister2(RE.SP2,0xADAF);
		vm.executeStep();
		vali(vm.getRegister2(RE.BC2) == 0);
		vm.executeStep();
		vali(vm.getRegister2(RE.HL2) == 0xFFFF);
		vm.executeStep();
		vali(vm.getRegister2(RE.SP2) == 0xADAE);
		return pass;
	}

	bool INC_R(){
		//INC A
		zero[0] = 0x3C;
		//INC H
		zero[1] = 0x24;

		vm.setRegister(RE.A,0xFF);
		vm.setRegister(RE.H, 0x7F);
		vm.executeStep;
		vali(vm.getRegister(RE.A) == 0);
		vali(vm.getFlag(FLAG_MASK.Z));
		vm.executeStep;
		vali(vm.getRegister(RE.H) == 0x80);
		vali(vm.getFlag(FLAG_MASK.S));

		return pass;
	}

	bool DEC_R(){
		//DEC H
		zero[0] = 0x25;
		//DEC L
		zero[1] = 0x2D;
		
		vm.setRegister(RE.L,0x0);
		vm.setRegister(RE.H, 0x1);
		vm.executeStep;
		vali(vm.getRegister(RE.A) == 0);
		vali(vm.getFlag(FLAG_MASK.Z));
		vm.executeStep;
		vali(vm.getRegister(RE.L) == 0xFF);
		vali(vm.getFlag(FLAG_MASK.S));
		
		return pass;
	}

	bool RLCA(){
		zero[0] = 0x07;
		zero[1] = 0x07;
		vm.setRegister(RE.A,0b01000000);
		vm.executeStep;
		vali(vm.getRegister(RE.A) == 0x80);
		vali(!vm.getFlag(FLAG_MASK.C));
		vm.executeStep;
		vali(vm.getRegister(RE.A) == 1);
		vali(vm.getFlag(FLAG_MASK.C));

		return pass;
	}

	bool RRCA(){
		zero[0] = 0x0F;
		zero[1] = 0x0F;
		vm.setRegister(RE.A,0b10);
		vm.executeStep;
		vali(vm.getRegister(RE.A) == 0x1);
		vali(!vm.getFlag(FLAG_MASK.C));
		vm.executeStep;
		vali(vm.getRegister(RE.A) == 0x80);
		vali(vm.getFlag(FLAG_MASK.C));
		
		return pass;
	}

	bool HALT(){
		//NOP
		zero[0] = 0x00;
		//HALT
		zero[1] = 0x76;
		vm.executeStep();
		vm.executeStep();
		vm.executeStep();
		vali(vm.getPC() == 1);
		return pass;
	}

	bool LD_R_R(){
		zero[0] = 0x77; //LD (HL), A
		zero[1] = 0x5C; //LD E, H
		zero[2] = 0x4B; //LD C, E
		zero[3] = 0x41; //LD B, C
		zero[4] = 0x78; //LD A, B
		zero[5] = 0x7E; //LD A, (HL)

		vm.setRegister(RE2.HL, 0x1210);
		vm.setRegister(RE.A, 0x20);
		vm.executeStep();
		vali(zero[0x1210] == 0x20);
		vm.executeStep();
		vm.executeStep();
		vm.executeStep();
		vm.executeStep();
		vali(vm.getRegister(RE.B) == 0x12);
		vm.executeStep();
		vali(vm.getRegister(RE.A) == 0x20);
		return pass;
	}


	mixin(TestElem!(littleBig, LD_RR_NN, DJNZ_D,
			JR_D, JR_CC_D, EX_AF_AF, ADD_HL_RR,
			LD_mRR_A, LD_A_mRR, LD_HL_NN, LD_A_NN,
			INC_RR, DEC_RR, INC_R, DEC_R, RLCA, RRCA,
			HALT, LD_R_R
			));

	return [passed, nopassed];
}

private template TestElem(T...){
	static if(T.length == 0){
		enum TestElem = "";
	}else{
		enum id = __traits(identifier,T[0]);
		enum TestElem = 
			"if("~id~"()){"
				"log.info(\""~id~"  \" ~ \"PASSED\");"
				"passed++;"
				"}else{"
				"log.info(\""~id~"  \" ~ \"FAILED\");"
				"nopassed++;"
				"}"
				"vm.restart();pass = true;"~
				TestElem!(T[1..$]);
	}
}
