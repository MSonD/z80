module maud.vm.pvm;
import maud.vm.vmi;

//Operaciones
enum OP{
	NOP,
	MOV,
	JAE
}

//Registros
enum RE{
	_MIN = 0,
	AX = 0,
	AH = 0,
	AL = 1,
	CX = 2,
	CL = 2,
	CH = 3,
	DX = 4,
	DH = 4,
	DL = 5,
	BX = 6,
	BH = 6,
	BL = 7,
	SP,
	BP,
	EF,
	FLAGS = EF,
	EIP,
	PC = EIP,
	MAR,
	MBR,
	MAX
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

//16 bits
//Convenciones
/**
 * 0xFFFF
 *   ^^
 * Instruccion
 * 
 * 0xFFFF
 *     ^
 * Modo direccion operador src
 * 
 * OxFFFF
 *      ^
 * Modo direccion operador dst
 * **/
class PoorVM //: VMInterface
{
	enum wsize = 2;
	enum default_stack_idx = 4095; //2**12 - 1
	enum minimal_memory = 1024*64;

	MemInterface xmem;
	short[255] registers;

	//IR y deocdificacion
	short[8] operands;
	byte[8] dirmodes;
	size_t noperands;
	size_t ioperands;

	byte* _loc;
	size_t time_i;

	void delegate()[] operator;

	this(MemInterface mp)
	{ 
		xmem = mp;
		_loc = cast(byte*)xmem.getAddress(0);
		assert(xmem.size >= minimal_memory, "Se necesita mayor memoria");
		registers[RE.EIP] = 0;
		registers[RE.SP] = default_stack_idx;
		registers[RE.BP] = default_stack_idx;
	}

	void op_nop(){}
	void op_mov(){
	}
	void op_test(){
		mixin (
			wmr!(0,RE.AX)~
			wrr!(RE.AX,RE.BX)~
			wrm!(RE.AX,1)
			);
	}
}

private{
	template wrr (alias src,alias dst){
		enum wrr = "registers["~dst.stringof~"] = registers["~src.stringof~"];"
		"time_i++;\n";
	}
	template wcr (alias src,alias dst){
		enum wcr = "registers["~dst.stringof~"] = "~src.stringof~";"
			"time_i++;\n";
	}
	template wmr (alias src,alias dst){
		version(PRECISE){
			enum wm = "registers["~dst.stringof~"] = src;"
				"time_i++;\n";
		}else{
			enum wmr = "registers["~dst.stringof~"] = *(cast(short*) (_loc + ("~src.stringof~")) );"
				"time_i+=3;\n";
		}
	}
	template wrm (alias src,alias dst){
		version(PRECISE){
			enum wm = "registers["~dst.stringof~"] = src;"
				"time_i++;\n";
		}else{
			enum wrm = "*(cast(short*) (_loc + ("~dst.stringof~")) ) = registers["~src.stringof~"];"
				"time_i+=3;\n";
		}
	}
	template mem_r (){
			enum fls = "registers[RE.MBR] = ";
	}
}