module maud.defines;

version(SAFE){
	pragma(msg,"Compilando con comprobacion de limites");
}

alias uint pword;

struct Token{
	enum : uint{
		_NULL,
		_INST_MIN,
		MOV,
		PUSH,
		_INST_MAX,
		NUMBER,
	}
	uint type;
	pword payload;
}
