module maud.vm.util;

mixin (generateHexMap8!"HEX_MAP");

//Carácteres por defecto hasta base 64
immutable string default_map = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz/\\";
immutable dstring ds_map = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz/\\";

template DefaultMap(T){
	static if(is(T == char))
		enum DefaultMap = default_map;
	else static if(is(T == dchar))
		enum DefaultMap = ds_map;
}
//Es el tipo un tipo entero
template isInteger(T){
	enum isInteger = is(T : long) | is(T : ulong);
}

unittest{
	static assert(isInteger!int);
	static assert(isInteger!ushort);
	static assert(isInteger!long);
	static assert(!isInteger!string);
}

//Devuelve el tipo sin signo correspondiente
template toUnsigned(T) if (isInteger!T){
	static if(is(T : byte))
		alias toUnsigned = ubyte;
	else static if(is(T : short))
		alias toUnsigned = ushort;
	else static if(is(T : int))
		alias toUnsigned = uint;
	else static if(is(T : long))
		alias toUnsigned = ulong;
	else static assert(0, "Invalid Type");
}

//Devuelve el logaritmo base dos superior mas proximo
T log2 (T) (T num) if (isInteger!T){
	T btr = 1;
	T k = 0;
	for(; btr < num; btr = btr<<1)
		k++;
	return k;
}

//Es el numero una potencia de dos
bool is2power (T) (T num) if (isInteger!T){
	T btr = 1;
	for(;btr < num; btr = btr<<1){}
	return btr-num == 0;
}

//Genera una serie de unos en representacion binaria (2^n - 1)
T gen1s(T)(size_t digits){
	T num = 1;
	for(size_t i = 1;i < digits;i++)
		num |= num<<1;
	return num;
}

/**
 * Genera una cadena representando el valor de un número en base n. Donde n es una potencia de 2
 * **/
void naryToStrMap(T, W, size_t radix)(T number, W[] buff, immutable(W)[] map = DefaultMap!W, size_t max = 0) if (isInteger!T){
	static if( is2power(radix) ){
		toUnsigned!T num = number;
		enum bsize = log2(radix);
		enum mask = gen1s!T(bsize);
		enum tsize = (T.sizeof*8)/bsize;
		size_t size;
		if(max == 0)
			size = tsize;
		else size = max;
		size_t i;
		for(i = 0;i < size ;i++){
			auto item = map[ (num & (mask<<(i*bsize)))>>(i*bsize) ];
			buff[size-i-1] = item; 
		}
		if( i < buff.length) buff[i] = '\0';
	}else{
		static assert(0, "Not implemented, not needed now ");
	}
}
/*
void naryToStrMapDyn(T, W)(T number, W[] buff, size_t digits, immutable(W)[] map = default_map) if (isInteger!T){
		toUnsigned!T num = number;
		auto bsize = digits;
		auto mask = gen1s!T(bsize);
		auto size = (T.sizeof*8)/bsize;
		size_t i;
		for(i = 0;i < size ;i++){
			auto item = map[ (num & (mask<<(i*bsize)))>>(i*bsize) ];
			buff[size-i-1] = item; 
		}
		if( i < buff.length) buff[i] = '\0';
}*/



void binToStr(size_t radix, T)(T number,char[] buff, size_t max = 0) if (isInteger!T){
	naryToStrMap!(T,char,radix)(number,buff,default_map, max);
}

string binToStr(T)(T number, size_t max = 0) if (isInteger!T){
	auto buff = new char[max > 0? max : T.sizeof*2];
	binToStr!(16,T)(number,buff,max);
	return buff;
}

dstring binToStrd(T)(T number, size_t max = 0) if (isInteger!T){
	auto buff = new dchar[max > 0? max : T.sizeof*2];
	naryToStrMap!(T,dchar,16)(number,buff,ds_map, max);
	return buff;
}


template generateHexMap8(string name){
	enum generateHexMap8 = "immutable dstring[] "~name~" = ["~
		generateHexMap8_loop!0~"];";
}

template generateHexMap8_loop(uint nb){
	static if(nb == 255)
		enum generateHexMap8_loop = "\"FF\"";
	else{
		enum generateHexMap8_loop = "\""d ~ ds_map[nb/16] ~ ds_map[nb%16]~ "\","d~ generateHexMap8_loop!(nb+1);
	}
}


bool isEvenParity(ubyte x){
	x ^= x>>4;
	x ^= x>>2;
	x ^= x>>1;
	return (x&1) == 0;
}