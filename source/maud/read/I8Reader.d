module maud.read.I8Reader;
import maud.vm.vmi;
import std.range;
import std.conv;
class I8Reader
{
	public static void read(R)(MemInterface x, R input)
		if  (isInputRange!R && is(ElementType!R == char[])){
		uint datalen;
		foreach(line; input){

			if(line.length == 0) continue;
			if(line.length < 11)
				throw new FormatException("longitud incorrecta");
			if(line[0] != ':')
				throw new FormatException("':' faltante");
			if((datalen = to!uint(line[1..3],16)) != (line.length - 11)/2)
				throw new FormatException("longitud incorrecta");
			switch(line[7..9]){
				case "00":
					ubyte* c = x.getAddress(to!uint(line[3..7],16));
					for(uint i = 0;i < datalen;i++){
						*c = to!ubyte(line[(9+i*2)..(9+i*2 +2)],16); //magic and stuff
						c++;
					}
					break;
				case "01":
					goto I8Reader_read_end;
				default:
					throw new FormatException("formato no soportado");
			}

		}
	I8Reader_read_end:
	}
}

class FormatException : Exception{
	this(string msg = ""){
		super("Error de formato "~msg);
	}
}
