module main;
import std.stdio;
import maud.vm.util;
import maud.test.z80;


void main(string[] args)
{
	writeln("Executing test cases...");
	writeln("[passed, failed]: ",testVM());
	stdin.readln();
}

