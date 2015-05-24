module maud.defines;
public import log = std.experimental.logger;
version(SAFE){
	pragma(msg,"Compiling with limit checking");
}

//More than actual checks, a reminder 
static assert(cast(ubyte)(-3) == cast(ubyte)(~3 + 1), "Platform error, negation is not two's complement");
static assert(cast(ubyte)(0xAB0A) == 0x0A, "Platform error, not little endian or unexpected casting behavior");

alias uint pword;