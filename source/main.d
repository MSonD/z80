module main;

import std.stdio;
import maud.vm.util;
import maud.test.vm;
extern (C) void doStuff(){
	static int[] data = [-1,-1,-1];
	data[0] = 0;
}

extern (C) void doStuff2(){
	static int[] data = [-1,-1,-1];
	data[0] = 0;
}

void main(string[] args)
{
	// Prints "Hello World" string in console
	testVM();
	stdin.readln();
}

