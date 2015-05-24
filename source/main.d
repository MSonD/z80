module main;
import std.stdio;
import std.getopt;
import maud.vm.z80;
import maud.vm.arrayMem;
import maud.glue.maudInterface;
import maud.ui.app;
import maud.test.z80;
import dlangui;
mixin APP_ENTRY_POINT;

/// entry point for dlangui based application
extern (C) int UIAppMain(string[] args) {

	// create window
	bool doTests;
	//Does not works on windows
	version(Windows){}else{
		getopt(args, "test", &doTests);
	}
	if(doTests) {pmain; return 0;}

	auto c = new ApplicationContext(new Z80VM( new ArrayMem(64*1024 + 32)));

	auto app = new MainApp(c);

	return Platform.instance.enterMessageLoop();
}



void pmain()
{
	//auto mem = arrayMem.create(64*1024);
	//I8Reader.read(mem,stdin.byLine);
	//StdDump dumper = new StdDump();
	//dumper.setWordSize(2);
	//dumper.push(mem.getAddress(0),0xFF);

	writeln("Executing test cases...");
	writeln("[passed, failed]: ",testVM());
}

