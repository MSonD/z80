module maud.vm.z80;
import maud.vm.vmi;
import maud.vm.util;
import std.functional;
import std.conv;
version (SAFE) import maud.vm.error;
public import maud.vm.constants;

/**
 * Simulador Zilog Z80
 * **/
class Z80VM : VMInterface
{
	enum wsize = 1;
	enum extra_register_space = 32;
	enum minimal_memory = 1024*16 + extra_register_space; //16K

	private{
		size_t stacksize = 0;
		size_t stack_idx = 0;
		size_t reg_idx = 0;
		size_t pro_mem_idx = 0;
		
		MemInterface mem;
		ubyte* m;
		ubyte* reg;
		ushort* reg2;
		ushort PCs;
		bool halted = false;
		bool interrupts_enabled = true;

		HSWAP HL_state = HSWAP.NO;
		ushort HL_swap;
		
		void delegate(string item) pipe_out;
		
		size_t time_i;
	}
	this(MemInterface mp)
	{ 

		assert(mp.size >= minimal_memory, "Se necesita mayor memoria");

		setMemory(mp);
		
		PCs = 0;

		reg2[RE.PC2] = 0;
		reg2[RE.SP2] = cast(ushort) stack_idx;
	}

	void setMemory(MemInterface memory){
		mem = memory;
		m = mem.getAddress(0);
		stack_idx = mem.size - extra_register_space - 1;
		reg_idx = mem.size - extra_register_space;
		pro_mem_idx = reg_idx;
		
		reg = mem.getAddress(reg_idx);
		reg2 = cast(ushort*) mem.getAddress(reg_idx);
	}
	bool isHalted(){
		return halted;
	}
	size_t getNetSize(){
		return reg_idx;
	}

	ubyte fetch(size_t idx){
		version (SAFE)
			if (idx >= pro_mem_idx)
				throw new VMProtectionException(idx);
		return m[idx];

	}

	ushort fetch2(size_t idx){
		version (SAFE)
			if (idx + 1 >= pro_mem_idx)
				throw new VMProtectionException(idx);
		return m[idx] + (m[idx+1] << 8);
		
	}

	void store(size_t idx,ubyte wha){
		version (SAFE)
			if (idx >= pro_mem_idx)
				throw new VMProtectionException(idx);
		m[idx] = wha;
		
	}
	void store2(size_t idx,ushort wha){

		version (SAFE)
			if (idx + 1 >= pro_mem_idx)
				throw new VMProtectionException(idx);
		m[idx] = wha & 0xFF;
		m[idx+1] = (wha >> 8);
		
	}

	uint getRegister(size_t regs){
		if(regs < RE2.AF)
			return reg[regs];
		else
			return reg2[regs-RE2.AF];
	}

	size_t getStackIdx() const{
		return stack_idx;
	}

	size_t getStackSize() const{
		return stacksize;
	}

	size_t getWordSize(){return 1;}

	uint getRegister2(RE regs){
		return reg2[regs];
	}

	void setRegister(size_t x,uint data){
		if(x < RE2.AF)
			reg[x] = cast(ubyte)data;
		else
			reg2[x-RE2.AF] = cast(ushort)data;
	}
	void setRegister2(RE x,ushort regs){
		reg2[x] = regs;
	}

	void restart(){
		swapHL(HSWAP.NO);
		stacksize = 0;
		time_i = 0;
		halted = false;
		reg[0..RE._ERROR-1] = 0;
		reg2[RE.SP2] = cast(ushort) getStackIdx;
		PCs = 0;
	}

	void setPC(uint dir){
		halted = false;
		mem.getAddress(dir);
		PCs = cast(ushort)dir;
		reg2[RE.PC2] = cast(ushort)dir;
	}

	uint getPC(){
		return PCs;
	}

	MemInterface memory(){
		return mem;
	}
	void executeStep(){
		executeStep(false,false);
	}
	void executeStep(bool dumpTokens = false, bool dryrun = false){
		while(!executeStepMain(dumpTokens, dryrun)){}
		swapHL(HSWAP.NO);
	}
	bool executeStepMain(bool tokens, bool dry){
		ubyte opcode = fetch(PCs);
		
		ubyte z_code, y_code, x_code, p_code, q_code;
		ubyte tmp, a1, a2;
		ushort tmp2;
		string s_string;

		if(halted){//NOP
			time_i += 4;
			return true;
		}

		x_code = (opcode & OP_MASK.x) >> 6;
		y_code = (opcode & OP_MASK.y) >> 3;
		z_code = (opcode & OP_MASK.z);
		p_code = (opcode & OP_MASK.p) >> 4;
		q_code = (opcode & OP_MASK.q) >> 3;

		switch(x_code){
			case 0:
				switch(z_code){
					case 0:
						switch(y_code){
							case 0: //NOP
								mixin(DRY("\"NOP\""));
								time_i+=4;
								skip;
								break;
							case 1: //EX AF AF'
								mixin(DRY("\"EX AF AF'\""));
								tmp2 = reg2[RE.AF2];
								reg2[RE.AF2] = reg2[RE.AFP2];
								reg2[RE.AFP2] = tmp2;
								time_i+=4;
								//if(tokens) tokens("EX AF, AF'");
								skip;
								break;
							case 2://DJNZ d
								tmp = fetch(PCs + 1); //#PCs
								if(tokens)
									s_string = "DJNZ" ~ to!string(tmp,16);
								mixin(DRY);
								skip(2);
								if(--reg[RE.B] == 0){
									time_i+=8;
								}
								else{
									reg2[RE.PC2] += cast (byte)(tmp);
									time_i+=13;
								}
								break;
							case 3://JR d
								skip(2);
								reg2[RE.PC2] += cast (byte)(fetch(PCs + 1));
								time_i+=8;
								break;
							default://JR cc, d
								skip(2);
								if(cc_t(y_code-4)){
									reg2[RE.PC2] +=  cast (byte)(fetch(PCs + 1));
									time_i+=12;
								}else time_i+=7;
						}//Y
						break;
					case 1://Z
						switch(q_code){
							case 0: //LD rr, nn
								skip(3);
								m[rp_t(p_code) +1] = fetch(PCs + 2);  //TODO: Check endianess
								m[rp_t(p_code)] = fetch(PCs + 1);
								time_i+=10;
								break;
							case 1://ADD HL, rr 
								skip;
								tmp2 = reg2[RE.HL2];
								tmp2 += *cast (short*)(m+rp_t(p_code));
								reg2[RE.HL2] = tmp2 & 0xFFFF;
								reg[RE.F] &= ~FLAG_MASK.N;
								if(tmp2 >> 16 == 0){
									reg[RE.F] &= ~FLAG_MASK.C;
									/*No zero flag (?) */
								}else{
									reg[RE.F] |= FLAG_MASK.C;
								}
								time_i+=11;
								//TODO: Half carry
								break;
							default:
						}
						break;
					case 2://Z
						if(q_code == 0){
							switch(p_code){
								case 0://LD (BC), A
									skip;
									store(reg2[RE.BC2],reg[RE.A]);
									time_i+=7;
									break;
								case 1://LD (DE), A
									skip;
									store(reg2[RE.DE2],reg[RE.A]);
									time_i+=7;
									break;
								case 2://LD (nn), HL
									skip(3);
									store2(fetch2(PCs+1),reg2[RE.HL2]);
									time_i += 16;
									break;
								case 3://LD (nn), A
									skip(3);
									store(fetch2(PCs+1),reg[RE.A]);
									time_i +=13;
									break;
								default:
							}
						}else{
							switch(p_code){
								case 0://LD A, (BC)
									skip;
									reg[RE.A] = fetch(reg2[RE.BC2]);
									time_i+=7;
									break;
								case 1://LD A, (DE)
									skip;
									reg[RE.A] = fetch(reg2[RE.DE2]);
									time_i+=7;
									break;
								case 2://LD HL, (nn)
									skip(3);
									reg2[RE.HL2] = fetch2(fetch2(PCs+1));
									time_i +=16;
									break;
								case 3://LD A, (nn)
									skip(3);
									reg[RE.A] = fetch(fetch2(PCs+1));
									time_i += 13;
									break;
								default:
							}
						}
						break;
					case 3://Z
						skip;
						time_i += 6;
						if(q_code == 0) //INC rr
							(*cast(ushort*)(m+rp_t(p_code) )) ++;
						else			//DEC rr
							(*cast(ushort*)(m+rp_t(p_code) )) --;
						break;
					case 4://INC r FIXME: HFLAG
						skip;
						time_i += 4;
						//What? The spec says it.
						setFlag(FLAG_MASK.PV,  m[r_t(y_code, 0,false)] == 0x7f);
						setFlag(FLAG_MASK.H,  (m[r_t(y_code, 0,false)]&0b1111) == 0b1111);
						setFlag(FLAG_MASK.N, false);
						tmp = ++ m[r_t(y_code, 7)];
						setFlag(FLAG_MASK.S, (tmp & SIGN_BIT) > 0);
						setFlag(FLAG_MASK.Z, tmp == 0);
						break;
					case 5://DEC r
						skip;
						time_i += 4;
						setFlag(FLAG_MASK.PV,  m[r_t(y_code, 0,false)] == 0x80);
						setFlag(FLAG_MASK.H,  (m[r_t(y_code, 0,false)]&0b1111) == 0b0000);
						setFlag(FLAG_MASK.N, true);
						tmp = --m[r_t(y_code, 7)];
						setFlag(FLAG_MASK.S, (tmp & SIGN_BIT) > 0);
						setFlag(FLAG_MASK.Z, tmp == 0);
						break; 
					case 6: //LD r, n
						skip(2);
						time_i += 7;
						m[r_t(y_code, 3)] = fetch(PCs + 1);
						break;
					case 7:
						switch(y_code){
							case 0://RLCA
								skip;
								time_i += 4;
								tmp = (reg[RE.A] & SIGN_BIT )>> 7;
								(reg[RE.A] <<= 1) += tmp;
								setFlag(FLAG_MASK.C, tmp > 0);
								reg[RE.F] &= ~(FLAG_MASK.N | FLAG_MASK.H);
								break;
							case 1://RRCA
								skip;
								time_i += 4;
								tmp = reg[RE.A] & 1;
								(reg[RE.A] >>= 1) += (tmp<<7);
								setFlag(FLAG_MASK.C, tmp == 1);
								reg[RE.F] &= ~(FLAG_MASK.N | FLAG_MASK.H);
								break;
							case 2://RLA
								skip;
								time_i += 4;
								tmp = (reg[RE.A] & SIGN_BIT )>> 7;
								(reg[RE.A] <<= 1) += reg[RE.F]&FLAG_MASK.C;
								setFlag(FLAG_MASK.C, tmp > 0);
								reg[RE.F] &= ~(FLAG_MASK.N | FLAG_MASK.H);
								break;
							case 3:	//RRA
								skip;
								tmp = reg[RE.A] & 1;
								time_i += 4;
								(reg[RE.A] >>= 1) += (reg[RE.F]<<7);
								setFlag(FLAG_MASK.C, tmp == 1);
								reg[RE.F] &= ~(FLAG_MASK.N | FLAG_MASK.H);
								break;
							case 4://DAA TODO
								time_i += 4;
								tmp = reg[RE.A];

								if((tmp&0xf) > 9 || getFlag(FLAG_MASK.H)){
									if(getFlag(FLAG_MASK.N))
										tmp = reg[RE.A]-=6;
									else
										tmp = reg[RE.A]+=6;
								}
								
								if((tmp&0xf0) > (9<<4) || getFlag(FLAG_MASK.C)){
									if(getFlag(FLAG_MASK.N))
										tmp = reg[RE.A]-=0x60;
									else
										tmp = reg[RE.A]+=0x60;
								}

								skip;
								break;
							case 5://CPL
								skip;
								time_i += 4;
								reg[RE.A] = ~reg[RE.A]; 
								reg[RE.F] |= (FLAG_MASK.N | FLAG_MASK.H);
								break;
							case 6://SCF
								skip;
								time_i += 4;
								reg[RE.F] &= ~(FLAG_MASK.N | FLAG_MASK.H);
								setFlag(FLAG_MASK.C, true);
								break;
							case 7://CCF
								skip;
								time_i += 4;
								setFlag(FLAG_MASK.N,false);
								setFlag(FLAG_MASK.H, reg[RE.F]&FLAG_MASK.C);
								setFlag(FLAG_MASK.C, !(reg[RE.F]&FLAG_MASK.C));
								break;
							default:
						}//Y
						break;
					default:
				}//Z
				break;
				
			case 1://X //LD R, R
				//HALT
				if(opcode == 0x76){
					time_i += 4;
					halted = true;
					return true;
				}
				skip;
				time_i += 4;

				if(HL_state != HSWAP.NO){//UGLY HACK
					if(y_code == 6){
						if(z_code == 5){//LD (IX+d), L
							m[r_t(y_code,3)] = HL_swap&0xFF;
							break;
						}
						if(z_code == 4){//LD (IX+d), H
							m[r_t(y_code,3)] = (HL_swap&0xFF00)>>8;
							break;
						}
					}
					if (z_code == 6){
						if(y_code == 5){//LD L, (IX+d)
							HL_swap = (HL_swap&0xFF00) | m[r_t(z_code,3)];
							break;
						}
						if(y_code == 4){//LD H, (IX,+d)
							HL_swap = (HL_swap&0xFF) | (m[r_t(z_code,3)]<<8);
							break;
						}
					}
				}

				m[r_t(y_code,3)] = m[r_t(z_code,3)];
				break;
			case 2: //X ALU[y] [z]
				skip;
				time_i += 4;
				ALU(y_code,reg[RE.A],
					m[r_t(z_code,3)],
					reg[RE.A]);
				break;
			case 3:	
				switch(z_code){
					case 0://RET cc
						if(cc_t(y_code)){
							reg2[RE.PC2] = pop();
							time_i += 11;
						}else{ 
							time_i += 5;
							skip;
						}
						break;
					case 1:
						if(q_code == 0){//POP rr
							skip;
							time_i += 10;
							*cast(ushort*) (m+rp2_t(p_code)) = pop();
							break;
						}else{
							switch(p_code){
								case 0://RET
									reg2[RE.PC2] = pop();
									time_i += 10;
									break;
								case 1://EXX
									skip;
									time_i += 4;
									tmp2 = reg2[RE.BC2];
									reg2[RE.BC2] = reg2[RE.BCP2];
									reg2[RE.BCP2] = tmp2;
									tmp2 = reg2[RE.DE2];
									reg2[RE.DE2] = reg2[RE.DEP2];
									reg2[RE.DEP2] = tmp2;
									tmp2 = reg2[RE.HL2];
									reg2[RE.HL2] = reg2[RE.HLP2];
									reg2[RE.HLP2] = tmp2;
									break;
								case 2://JP (HL)
									skip;
									time_i+=4;
									reg2[RE.PC2] = reg2[RE.HL2];
									break;
								case 3: //LD SP, HL
									skip;
									time_i += 6;
									reg2[RE.SP2] = reg2[RE.HL2];
									break;
								default:
							}//P
							break;
						}//Q
					case 2://JP cc, nn
						skip(3);
						time_i += 10;
						if(cc_t(y_code))
							reg2[RE.PC2] = fetch2(PCs + 1);
						break;
					case 3:
						switch(y_code){
							case 0://JP nn
								skip(3);
								time_i += 10;
								reg2[RE.PC2] = fetch2(PCs + 1);
								break;
							case 1://CB
								skip;
								PCs++;
								executeStepCB(tokens,dry);
								break;
							case 2://OUT (n), A
								time_i += 11;
								skip(2);
								//NOT IMPLEMENTED
								break;
							case 3://IN A, (n)
								time_i += 11;
								skip(2);
								//NOT IMPLEMENTED
								break;
							case 4: //EX (SP), HL
								time_i += 19;
								skip;
								tmp2 = reg2[RE.HL2];
								reg2[RE.HL2] = fetch2(reg2[RE.SP2]);
								store2(reg2[RE.SP2], tmp);
								break;
							case 5: //EX DE, HL
								time_i += 4;
								skip;
								swapHL(HSWAP.NO);
								tmp2 = reg2[RE.HL2];
								reg2[RE.HL2] = reg2[RE.DE2];
								reg2[RE.DE2] = tmp;
								break;
							case 6://DI
								time_i += 4;
								skip;
								interrupts_enabled = false;
								break;
							case 7://EI
								time_i += 4;
								skip;
								interrupts_enabled = true;
								break;
							default:
						}
						break;
					case 4: //CALL cc, nn
						if(cc_t(y_code)){
							tmp2 = fetch2(PCs + 1);
							push(cast(ushort)(PCs + 3));
							reg2[RE.PC2] = tmp2;
							time_i += 17;
						}else{
							time_i += 10;
							skip(3);
						}	
						break;
					case 5://Z
						if(q_code == 0){ //PUSH rr
							time_i += 11;
							skip;
							push(*cast(ushort*)(m+rp2_t(p_code)));
						}else{
							switch(p_code){
								case 0://CALL nn
									tmp2 = fetch2(PCs + 1);
									push(cast(ushort)(PCs + 3));
									reg2[RE.PC2] = tmp2;
									time_i += 17;
									break;
									//TODO: IMPLEMENT IX; IY ROT
								case 1://DD
									skip;
									PCs = reg2[RE.PC2];
									swapHL(HSWAP.IX);
									return false;
								case 2://ED
									skip();
									PCs++;
									swapHL(HSWAP.NO);
									executeStepED(tokens, dry);
									break;
								case 3://FD
									skip;
									PCs = reg2[RE.PC2];
									swapHL(HSWAP.IY);
									return false;
								default:
									skip;
							}
						}
						break;
					case 6://Z ALU[y] n
						skip(2);
						time_i += 7;
						ALU(y_code,reg[RE.A],fetch(PCs +1), reg[RE.A]);
						break;
					case 7://RST n
						time_i += 11;
						push(reg2[RE.PC2]);
						reg2[RE.PC2] = y_code*8;
						break;
					default:
				}//Z
				break;
			default:
		}
		PCs = reg2[RE.PC2];
		return true;
	}

	bool executeStepCB(bool tokens, bool dry){
		ubyte opcode;
		if(HL_state == HSWAP.NO)
			opcode = fetch(PCs);
		else{
			opcode = fetch(PCs + 1);
			PCs--;
		}
		ubyte z_code, y_code, x_code;
		string s_string;
		
		if(halted){//NOP
			time_i += 4;
			return true;
		}
		
		x_code = (opcode & OP_MASK.x) >> 6;
		y_code = (opcode & OP_MASK.y) >> 3;
		z_code = (opcode & OP_MASK.z);
		switch(x_code){
			case 0://ROT[y] r
				skip;
				ROT(y_code, m[r_t(z_code,7)]);
				break;
			case 1://BIT y, r[z]
				skip;
				ushort idx  = m[r_t(z_code,7)];
				setFlag(FLAG_MASK.Z,(idx & (1<<y_code) )== 0);
				setFlag(FLAG_MASK.N, false);
				setFlag(FLAG_MASK.H, true);
				break;
			case 2://RES
				skip;
				m[r_t(z_code,7)] &= ~(1<<y_code);
				break;
			case 3://SET
				skip;
				m[r_t(z_code,7)] |= (1<<y_code);
				break;
			default:
		}
		return true;
	}

	bool executeStepED(bool tokens, bool dry){
		ubyte opcode = fetch(PCs);
		
		ubyte z_code, y_code, x_code, q_code, p_code;
		string s_string;
		
		if(halted){//NOP
			time_i += 4;
			return true;
		}
		
		x_code = (opcode & OP_MASK.x) >> 6;
		y_code = (opcode & OP_MASK.y) >> 3;
		q_code = (opcode & OP_MASK.q) >> 3;
		p_code = (opcode & OP_MASK.p) >> 4;
		z_code = (opcode & OP_MASK.z);
		switch(x_code){
			case 0://NOPx2
				skip;
				time_i += 8;
				break;
			case 1:
				switch(z_code){
					case 0://IN / OUT NOT IMPLEMENTED
					case 1:
						skip(2);
						time_i+=12;
						break;
					case 2:
						skip;
						uint tmp3 = reg2[RE.HL2];
						short tmp2 =*cast(ushort*)(m + rp_t(p_code));
						if(q_code == 0){ //SBC HL rr
							//TODO: PV, H flags
							tmp3 -= tmp2;
							reg2[RE.HL2] = cast(ushort) (tmp3&0xFFFF);
							setFlag(FLAG_MASK.C, tmp2 > reg2[RE.HL2]);
							setFlag(FLAG_MASK.S, (tmp3&0x800) > 0);
							setFlag(FLAG_MASK.N, true);
							setFlag(FLAG_MASK.Z, !tmp3);
						}else{//ADC HL rr
							tmp3 += tmp2;
							reg2[RE.HL2] = cast(ushort) (tmp3&0xFFFF);
							setFlag(FLAG_MASK.C, (tmp3 >> 16) > 0);
							setFlag(FLAG_MASK.S, (tmp3&0x800) > 0);
							setFlag(FLAG_MASK.N, !tmp3);
						}
						break;
					case 3:
						skip(3);
						time_i += 20;
						//LD (nn), rr
						if(q_code){
							store2(fetch2(fetch2(PCs+1)), *cast(ushort*)(m + rp_t(p_code)) );
						//LD rr, (nn)
						}else{
							*cast(ushort*)(m + rp_t(p_code)) = cast(ushort) fetch2(fetch2(PCs+1));
						}
						break;
					case 4://NEG
						skip;
						time_i += 8;
						setFlag(FLAG_MASK.PV, reg[RE.A] == 0x80);
						setFlag(FLAG_MASK.C, reg[RE.A] != 0);
						reg[RE.A] = cast(ubyte)(-reg[RE.A]);
						setFlag(FLAG_MASK.N, true);
						setFlag(FLAG_MASK.Z, reg[RE.A] == 0);
						break;
					case 5:
						//RETN //RETI NOT IMPLEMENTED
						skip;
						time_i += 14;
						break;
					case 6:
						//IM NOT IPLEMENTED
						skip;
						time_i += 8;
						break;
					case 7:
						switch(y_code){
							case 4://RRD
								skip;
								time_i += 8;
								ubyte tmp = fetch(reg2[RE.HL2]);
								ubyte tmp2 = tmp&0x0F;
								tmp >>= 4;
								tmp |= (reg[RE.A]&0x0F) << 4;
								reg[RE.A] = (reg[RE.A]&0xF0) | tmp2;
								store(reg[RE.HL],tmp);
								setFlag(FLAG_MASK.S,(reg[RE.A]&SIGN_BIT) >0);
								setFlag(FLAG_MASK.Z,reg[RE.A] == 0);
								setFlag(FLAG_MASK.H,false);
								setFlag(FLAG_MASK.PV, isEvenParity(reg[RE.A]));
								setFlag(FLAG_MASK.N,false);
								break;
							//RLD
							case 5:
								skip;
								time_i += 8;
								ubyte tmp = fetch(reg2[RE.HL2]);
								ubyte tmp2 = tmp&0xF0;
								tmp <<= 4;
								tmp |= (reg[RE.A]&0x0F);
								reg[RE.A] = (reg[RE.A]&0xF0) | (tmp2>>4);
								store(reg[RE.HL],tmp);
								setFlag(FLAG_MASK.S,(reg[RE.A]&SIGN_BIT) > 0);
								setFlag(FLAG_MASK.Z,reg[RE.A] == 0);
								setFlag(FLAG_MASK.H,false);
								setFlag(FLAG_MASK.PV, isEvenParity(reg[RE.A]));
								setFlag(FLAG_MASK.N,false);
								break;
							default:
								skip;
								time_i += 8;
								break;
						}
						break;
					default:

				}
				break;
			case 2://xxI[R]
				BLI(y_code,z_code);
				break;
			case 3://NOPx2
				skip;
				time_i += 8;
				break;
			default:
		}
		return true;
	}

	void BLI(ubyte indexA, ubyte indexB){
		switch(indexA){
			case 4:
				switch(indexB){
					case 0:
						skip;
						blockWritePass!"++"();
						time_i += 16;
						break;
					case 1:
						skip;
						blockWritePass!"++"();
						time_i += 16;
						break;
					default://NOT IMPLEMENTED
						time_i += 16;
						skip;
				}
				break;
			case 5:
				switch(indexB){
					case 0:
						skip;
						blockWritePass!"--"();
						time_i += 16;
						break;
					case 1:
						skip;
						blockReadPass!"--"();
						time_i += 16;
						break;
					default://NOT IMPLEMENTED
						time_i += 16;
						skip;
				}
				break;
			case 6:
				switch(indexB){
					case 0:
						blockWriteLoop!"++"();
						break;
					case 1:
						blockReadLoop!"++"();
						time_i += 16;
						break;
					default://NOT IMPLEMENTED
						time_i += 16;
						skip;
				}
				break;
			case 7:
				switch(indexB){
					case 0:
						blockWriteLoop!"--"();
						time_i += 16;
						break;
					case 1:
						blockReadLoop!"--"();
						time_i += 16;
						break;
					default://NOT IMPLEMENTED
						time_i += 16;
						skip;
				}
				break;
			default://Outi etc.
				//NOT IMPLEMENTED
				time_i += 16;
				skip;
		}
	}

	void ROT(uint y_code, ref ubyte outval){
		ubyte tmp;
		switch(y_code){
			case 0://RLC
				tmp = outval&0x80;
				setFlag(FLAG_MASK.C, tmp > 0);
				outval <<= 1;
				outval |= tmp>>7;
				break;
			case 1://RRC
				tmp = outval&1;
				setFlag(FLAG_MASK.C, tmp >0);
				outval >>= 1;
				outval |= tmp<<7;
				break;
			case 2://RL
				tmp = outval&0x80;
				outval <<= 1;
				outval |= reg[RE.F]&FLAG_MASK.C;
				setFlag(FLAG_MASK.C, tmp > 0);
				break;
			case 3://RR
				tmp = outval&1;
				outval =  outval>>1 | reg[RE.F]&FLAG_MASK.C<<7;
				setFlag(FLAG_MASK.C, tmp > 0);
				break;
			case 4://SLA
				tmp = outval&0x80;
				setFlag(FLAG_MASK.C, tmp > 0);
				outval <<=1;
				break;
			case 5://SRA
				tmp = outval&0x80;
				setFlag(FLAG_MASK.C, (outval&1) > 0);
				outval >>=1;
				outval &= tmp;
				break;
			case 6://SLL
				tmp = outval&1;
				setFlag(FLAG_MASK.C, (outval&0x80) > 0);
				outval <<=1;
				outval &= tmp;
				break;
			case 7://SRL
				tmp = outval&1;
				setFlag(FLAG_MASK.C, tmp > 0);
				outval >>=1;
				break;
			default:
		}
		setFlag(FLAG_MASK.PV,isEvenParity(outval));
		setFlag(FLAG_MASK.Z, outval == 0);
		reg[RE.F] &= ~(FLAG_MASK.N | FLAG_MASK.H);
	}

	void ALU(uint y_code, ubyte val1, ubyte val2, ref ubyte outval){
		uint res;
		switch(y_code){
			case 0: //ADD A, r
				res = val1 + val2;
				alu_plus_flags(val1, val2, res);
				break;
			case 1: //ADC A, r
				res = val1 + val2 + (reg[RE.F] & FLAG_MASK.C);
				alu_plus_flags(val1,val2, res);
				break;
			case 2://SUB A, r
				res = (val1 - val2);
				alu_minus_flags(val1, val2, res);
				break;
			case 3://SBC A, r
				res = (val1 - val2) - (reg[RE.F] & FLAG_MASK.C);
				alu_minus_flags(val1, val2, res);
				break;
			case 4: //AND A, r
				res = val1 & val2;
				setFlag(FLAG_MASK.PV, isEvenParity(cast(ubyte) res));
				setFlag(FLAG_MASK.C,false);
				setFlag(FLAG_MASK.N, false);
				//wat
				setFlag(FLAG_MASK.H, true);
				break;
			case 5://XOR A,r
				res = val1 ^ val2;
				setFlag(FLAG_MASK.PV, isEvenParity( cast(ubyte)res) );
				setFlag(FLAG_MASK.C,false);
				setFlag(FLAG_MASK.N, false);
				setFlag(FLAG_MASK.H, false);
				break;
			case 6://OR A,r
				res = val1 | val2;
				setFlag(FLAG_MASK.PV, isEvenParity(cast(ubyte)res));
				setFlag(FLAG_MASK.C,false);
				setFlag(FLAG_MASK.N, false);
				setFlag(FLAG_MASK.H, false);
				break;
			case 7://CP
				res = (val1 - val2);
				alu_minus_flags(val1, val2, res);
				return;
			default:
				//Used outside normal range.
		}//X
		outval = cast(ubyte) res;
	}
	void blockWriteLoop(string op)(){
		blockWritePass!op();
		reg[RE.F] &= ~(FLAG_MASK.H | FLAG_MASK.PV | FLAG_MASK.N);
		if(reg2[RE.BC2] == 0){
			skip;
			time_i += 16;
		}else{
			reg2[RE.PC2]--;
			time_i += 21;
		}
	}
	
	void blockWritePass(string op)(){
		store(reg2[RE.DE2],fetch(reg2[RE.HL2]));
		mixin("reg2[RE.DE2]"~op~";");
		mixin("reg2[RE.HL2]"~op~";");
		setFlag(FLAG_MASK.PV,(--reg2[RE.BC2]) != 0);
	}
	
	void blockReadLoop(string op)(){
		blockReadPass!op();
		if(reg2[RE.BC2] == 0 || !reg[RE.F]&FLAG_MASK.PV){
			skip;
			time_i += 16;
		}else{
			reg2[RE.PC2]--;
			time_i += 21;
		}
	}
	
	void blockReadPass(string op)(){
		ubyte val = fetch(reg2[RE.HL2]);
		ubyte res = reg[RE.A];
		res -= val;
		alu_minus_flags(reg[RE.A], val, res);
		mixin("reg2[RE.HL2]"~op~";");
		setFlag(FLAG_MASK.PV,--reg2[RE.BC2] != 0);
	}

	void swapHL(HSWAP p){
		ushort* dst;
		ushort tmp;
		with(HSWAP)	switch(HL_state){
			case IX:
				reg2[RE.IX2] = reg2[RE.HL2];
				reg2[RE.HL2] = HL_swap;
				break;
			case IY:
				reg2[RE.IY2] = reg2[RE.HL2];
				reg2[RE.HL2] = HL_swap;
				break;
			default:
		}
		with(HSWAP) switch(p){
			case NO:
				HL_state = HSWAP.NO;
				return;
			case IX:
				HL_swap = reg2[RE.HL2];
				reg2[RE.HL2] = reg2[RE.IX2];
				HL_state = HSWAP.IX;
				break;
			case IY:
				HL_swap = reg2[RE.HL2];
				HL_state = HSWAP.IY;
				reg2[RE.HL2] = reg2[RE.IY2];
				break;
			default:
		}
	}

	void push(ushort dir){
		stacksize++;
		reg2[RE.SP2]-=2;
		m[reg2[RE.SP2]] = dir & 0xFF;
		m[reg2[RE.SP2]+1] = (dir >> 8);
	}

	ushort pop (){
		stacksize--;
		ushort p = m[reg2[RE.SP2]] + (m[reg2[RE.SP2]+1] << 8);
		reg2[RE.SP2]+=2;
		return p;
	}
	//private{
	void skip(ushort k = 1){
		reg2[RE.PC2]+=k;
	}

	void alu_plus_flags(uint a, uint b, uint result){
		setFlag(FLAG_MASK.S, (result & SIGN_BIT) > 0);
		setFlag(FLAG_MASK.Z, (result&0xff) == 0);
		setFlag(FLAG_MASK.C, (result >> 8) > 0);
		setFlag(FLAG_MASK.PV, 
			( ((a & SIGN_BIT)^(b &SIGN_BIT)) == 0 ) && 
			((result & SIGN_BIT) != (a & SIGN_BIT))
			);
		setFlag(FLAG_MASK.N,false);
		setFlag(FLAG_MASK.H, (((a&0xf) + (result&0xf))&0x10) > 0);
	}

	void alu_minus_flags(uint a, uint b, uint result){
		setFlag(FLAG_MASK.S, (result & SIGN_BIT) > 0);
		setFlag(FLAG_MASK.Z, (result&0xff) == 0);
		setFlag(FLAG_MASK.C, b > a);//TODO: CHECK THIS
		setFlag(FLAG_MASK.PV, 
			( ((a & SIGN_BIT)^(b &SIGN_BIT)) > 0 ) && 
			((result & SIGN_BIT) != (a & SIGN_BIT))
			);
		setFlag(FLAG_MASK.N,true);
		setFlag(FLAG_MASK.H, (b&0xf) > (a&0xf) );
		//FIXME H flag
	}

	void setFlag(FLAG_MASK f, lazy bool cond){
		if(cond)
			reg[RE.F] |= f;
		else
			reg[RE.F] &= ~f;
	}

	bool getFlag(FLAG_MASK f){
		return (reg[RE.F] & f) > 0;
	}
	size_t r_t(ubyte opcode, size_t inc = 0, bool full = true){
		immutable ubyte[] map = [RE.B,RE.C,RE.D,RE.E,RE.H,RE.L,RE._ERROR,RE.A];
		version (SAFE)
			if(opcode >= map.length)
				throw new VMInternalException("Opcode-r fuera de rango");
		if(opcode == 6){
			time_i += inc;
			ushort ptr;
			ptr = reg2[RE.HL2];
			if(HL_state != HSWAP.NO){//UGLY HACK
				ptr += fetch(PCs + 1);
				if(full){
					skip;//:( can't even add time correctly
					PCs++;
				}
			}
			version (SAFE)
				if(ptr >= pro_mem_idx)
					throw new VMProtectionException(ptr,PCs);
			return ptr;
		}else{
			auto ptr = reg_idx + map[opcode];
			return ptr;
		}
	}
	size_t rp_t(ubyte opcode){
		immutable ubyte[] map = [RE.BC,RE.DE,RE.HL,RE.SP];
		version (SAFE)
			if(opcode >= map.length)
				throw new VMInternalException("Opcode-r fuera de rango");
		auto ptr = reg_idx + map[opcode];
		return ptr;
	}
	size_t rp2_t(ubyte opcode){
		immutable ubyte[] map = [RE.BC,RE.DE,RE.HL,RE.AF];
		version (SAFE)
			if(opcode >= map.length)
				throw new VMInternalException("Opcode-r fuera de rango");
		auto ptr = reg_idx + map[opcode];
		return ptr;
	}

	ubyte cc_t(size_t opcode){
		immutable ubyte[] map = [FLAG_MASK.Z,FLAG_MASK.C,FLAG_MASK.PV,FLAG_MASK.S];
		ubyte res = reg[RE.F] & map[opcode>>1];
		if(opcode & 1) return res;
		return !res;
	}
	
	//}
}

private enum HSWAP{
	NO,
	IX,
	IY
}

private pure string DRY(string code = "s_string"){
	return "if(tokens){pipe_out("~code~"); if(dry){ return true; }}";
}