﻿module maud.vm.z80;
import maud.vm.vmi;
import std.functional;
version (SAFE) import maud.vm.error;

struct OpData{
	string mnem;
	size_t oplen;
	size_t ndirs;
	size_t runtime;
}

//Registros
enum RE{
	A = 0,
	AF = 0,
	F,

	B,
	BC = B,
	C,

	D,
	DE = D,
	E,

	H,
	HL = H,
	L,

	IX,
	IXh,

	IY,
	IYh,

	SP,
	SPh,

	PC,
	PCh,

	AP,
	AFP,
	FP,

	BP,
	BCP = BP,
	CP,

	DP,
	DEP = DP,
	EP,

	HP,
	HLP = HP,
	LP,

	AF2 = AF/2,
	BC2 = BC/2,
	DE2 = DE/2,
	HL2 = HL/2,
	PC2 = PC/2,
	SP2 = SP/2,
	AFP2 = AFP/2, 
	BCP2 = BCP/2,
	DEP2 = DEP/2,
	HLP2 = HLP/2,
	_ERROR = LP+1
	
}
enum FLAG_MASK : ubyte{
	C = 0b1,
	N = 0b10,
	PV = 0b100,
	H = 0b10000,
	Z = 0b1000000,
	S = 0b10000000
}
enum OP_MASK : ubyte{
	z = 0b111,
	y = 0b111000,
	q = 0b1000,
	p = 0b110000,
	x = 0b11000000
}
//Modos de direccionamiento
enum DIR{
	K,
	CONST = K,
	A,
	ADDRESS = A,
	P,
	POINTER = P,
	R,
	REGISTER = R,
	I,
	REG_IND = I
}

/**
 * Simulador Zilog Z80
 * **/
class Z80VM //: VMInterface
{
	enum wsize = 1;
	enum extra_register_space = 32;
	enum minimal_memory = 1024*16 + extra_register_space; //16K
	enum stacksize = 4096;

	size_t stack_idx = 0;
	size_t reg_idx = 0;
	size_t pro_mem_idx = 0;
	
	MemInterface mem;
	ubyte* m;
	ubyte* reg;
	ushort* reg2;
	ushort PCs;
	
	void delegate(string item) tokens;
	
	size_t time_i;
	
	this(MemInterface mp)
	{ 
		mem = mp;
		assert(mem.size >= minimal_memory, "Se necesita mayor memoria");
		
		m = mem.getAddress(0);
		stack_idx = mem.size - stacksize;
		reg_idx = stack_idx - extra_register_space;
		pro_mem_idx = reg_idx;

		reg = mem.getAddress(reg_idx);
		reg2 = cast(ushort*) mem.getAddress(reg_idx);
		
		PCs = 0;

		reg2[RE.PC2] = 0;
		reg2[RE.SP] = cast(ushort) stack_idx;
	}

	ubyte fetch(uint idx){
		version (SAFE)
			if (PCs >= pro_mem_idx)
				throw new VMProtectionException(PCs);
		return m[idx];

	}

	ubyte register(RE regs){
		return reg[regs];
	}
	ushort register2(RE regs){
		return reg2[regs];
	}

	void setRegister(RE x,ubyte regs){
		reg[x] = regs;
	}
	void setRegister2(RE x,ushort regs){
		reg2[x] = regs;
	}

	void restart(){
		reg[0..RE._ERROR-1] = 0;
		PCs = 0;
	}

	void jumpTo(ushort dir){
		mem.getAddress(dir);
		PCs = dir;
		reg2[RE.PC2] = dir;
	}

	
	void execStep(){
		ubyte opcode = fetch(PCs);
		import std.stdio;
		
		ubyte z_code, y_code, x_code, p_code, q_code;
		ubyte tmp, a1, a2;
		ushort tmp2, as;
		
		x_code = (opcode & OP_MASK.x) >> 6;
		y_code = (opcode & OP_MASK.y) >> 3;
		z_code = (opcode & OP_MASK.z);
		p_code = (opcode & OP_MASK.p) >> 4;
		q_code = (opcode & OP_MASK.q) >> 3;
		reg2[RE.PC2]++;

		//writeln("OP:",opcode," x:",x_code," z:",z_code," y:",y_code);
				
		switch(x_code){
			case 0:
				switch(z_code){
					case 0:
						switch(y_code){
							case 0: //NOP
								//if(tokens) tokens("NOP");
								time_i+=4;
								break;
							case 1: //EX AF AF'
								tmp2 = reg2[RE.AF2];
								reg2[RE.AF2] = reg2[RE.AFP2];
								reg2[RE.AFP2] = tmp2;
								time_i+=4;
								//if(tokens) tokens("EX AF, AF'");
								break;
							case 2://DJNZ d
								tmp = fetch(PCs + 1); //#PCs
								if(--reg[RE.B] == 0){
									reg2[RE.PC2]++;
									time_i+=8;
								}
								else{
									reg2[RE.PC2] += cast (byte)(tmp + 1);
									time_i+=13;
								}
								break;
							case 3://JR d
								reg2[RE.PC2] += cast (byte)(fetch(reg2[RE.PC2]) + 1);
								time_i+=8;
								break;
							default://JR cc, d
								if(cc_t(cast(ubyte)(y_code-4))){
									reg2[RE.PC2] += cast (byte)(fetch(reg2[RE.PC2]) + 1);
									time_i+=12;
								}else time_i+=7;
						}
						break;
					case 1:
						switch(q_code){
							case 0: //LD rr, nn
								m[rp_t(p_code) +1] = fetch(PCs + 2);  //#Orden correcto?
								m[rp_t(p_code)] = fetch(PCs + 1);
								reg2[RE.PC2]+=2;
								time_i+=10;
								break;
							case 1:
								break;
							default:
						}
						break;
					default:
				}
				break;
				
			case 1:
			case 2:
			case 3:
			default:
		}
		PCs = reg2[RE.PC2];
	}
	
	//private{
	size_t r_t(ubyte opcode){
		immutable ubyte map[] = [RE.B,RE.C,RE.D,RE.E,RE.H,RE.L,RE._ERROR,RE.A];
		version (SAFE)
			if(opcode >= map.length)
				throw new VMInternalException("Opcode-r fuera de rango");
		if(opcode == 6){
			auto ptr = reg2[RE.HL2];
			version (SAFE)
				if(ptr >= stack_idx)
					throw new VMProtectionException(ptr,PCs);
			return reg2[RE.HL2];
		}else{
			auto ptr = reg_idx + map[opcode];
			version (SAFE)
				if(ptr >= stack_idx)
					throw new VMInternalException();
			return ptr;
		}
	}
	size_t rp_t(ubyte opcode){
		immutable ubyte map[] = [RE.BC,RE.DE,RE.HL,RE.SP];
		version (SAFE)
			if(opcode >= map.length)
				throw new VMInternalException("Opcode-r fuera de rango");
		auto ptr = reg_idx + map[opcode];
		version (SAFE)
			if(ptr >= stack_idx)
				throw new VMInternalException();
		return ptr;
	}
	size_t rp2_t(ubyte opcode){
		immutable ubyte map[] = [RE.BC,RE.DE,RE.HL,RE.A];
		version (SAFE)
			if(opcode >= map.length)
				throw new VMInternalException("Opcode-r fuera de rango");
		auto ptr = reg_idx + map[opcode];
		version (SAFE)
			if(ptr >= stack_idx)
				throw new VMInternalException();
		return ptr;
	}

	ubyte cc_t(ubyte opcode){
		immutable ubyte map[] = [FLAG_MASK.Z,FLAG_MASK.C,FLAG_MASK.PV,FLAG_MASK.S];
		ubyte res = reg[RE.F] & map[opcode>>1];
		if(opcode & 1) return res;
		return !res;
	}
	
	//}
}

private{

}