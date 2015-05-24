module maud.vm.vmi;

//Tamaño de una localidad de memoria
alias loc_t = ubyte;

interface VMInterface
{
	MemInterface memory();
	void setMemory(MemInterface f);
	size_t getStackIdx() const;
	size_t getStackSize() const;
	size_t getNetSize();
	void executeStep();
	void executeStep(bool stringout, bool dryrun);
	uint getRegister(size_t reg);
	void setRegister(size_t reg,uint x);
	uint getPC();
	void setPC(uint x);
	void restart();
	bool isHalted();
	size_t getWordSize();

	static VMInterface create();
}

interface MemInterface{
	loc_t* getAddress(size_t n = 0, short wordsize = 1);
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