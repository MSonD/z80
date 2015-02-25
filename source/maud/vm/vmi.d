module maud.vm.vmi;

//Tamaño de una localidad de memoria
alias loc_t = ubyte;

interface VMInterface
{
	MemInterface getMemoryRange();
	void setMemoryRange(MemInterface f);
	size_t getStackAddress();
	size_t getStackSize();
	void execute();
	void executeStep();
	ulong getRegisterStatus(size_t reg);
	void setRegisterStatus(size_t reg,ulong x);
	size_t getWordSize();

	static VMInterface create();
}

interface MemInterface{
	loc_t* getAddress(size_t n, short wordsize = 1);
	size_t size();
	static MemInterface create(size_t size);
	/+
	uint query(size_t loc);
	ulong queryl(size_t loc);
	ushort querys(size_t loc);
	ubyte queryb(size_t loc);
	+/
	//Size in bytes
}

interface CoreDumpInterface{
	void push(loc_t* size, size_t tam);
	void setWordSize(size_t len);
	size_t getWordSize();

	static CoreDumpInterface create();
}