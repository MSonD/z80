module maud.glue.lua;
import maud.glue.maudInterface;
import luad.all;
import maud.vm.constants;
import std.conv;
import std.traits;
LuaState createLua(ApplicationContext c){
	LuaState l = new LuaState();
	l.openLibs;
	l["put"] = &c.put;
	l["seek"] = &c.seek;
	l["step"] = &c.VM.executeStep;
	l["get"] = &c.get;
	l["p"] = &c.p;
	l["clear"] = &c.clear;
	l["load"] = &c.load;
	l["set"] = &c.VM.setRegister;
	foreach(immutable member; EnumMembers!RE)
		l[to!string(member)] = member;
	foreach(immutable member; EnumMembers!RE2)
		l[to!string(member)] = member;

	return l;
}