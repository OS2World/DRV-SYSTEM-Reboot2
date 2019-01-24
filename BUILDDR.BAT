del rebootdr.exe
del rebootdr.sys
masm rebootdr.asm;
link rebootdr,rebootdr.sys,,os2,rebootdr
ren rebootdr.dll rebootdr.sys
