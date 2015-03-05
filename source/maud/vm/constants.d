module maud.vm.constants;

version(LittleEndian)
enum RE{
	F = 0,
	AF = 0,
	A,
	
	C,
	BC = C,
	B,
	
	E,
	DE = E,
	D,
	
	L,
	HL = L,
	H,
	
	IX,
	IXl,
	
	IY,
	IYl,
	
	SP,
	SPl,
	
	PC,
	PCl,
	
	FP,
	AFP = FP,
	AP,
	
	CP,
	BCP = CP,
	BP,
	
	EP,
	DEP = EP,
	DP,
	
	LP,
	HLP = LP,
	HP,
	_ERROR,
	AF2 = AF/2,
	BC2 = BC/2,
	DE2 = DE/2,
	HL2 = HL/2,
	PC2 = PC/2,
	SP2 = SP/2,
	AFP2 = AFP/2, 
	BCP2 = BCP/2,
	DEP2 = DEP/2,
	HLP2 = HLP/2
	
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