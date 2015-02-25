module maud.vm.util;

//Carácteres por defecto hasta base 64
immutable string default_map = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz/\\";

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
void naryToStrMap(T, W, size_t radix)(T number, W[] buff, immutable(W)[] map = default_map, size_t max = 0) if (isInteger!T){
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
