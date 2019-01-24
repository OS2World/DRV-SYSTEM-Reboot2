	title    REBOOTDR.ASM -- Installable device driver for OS/2 reboot
	.286

; REBOOTDR.ASM
; By Mitch Stuart and Paul Chen
;
; Reference:  TEMPLATE.ASM, Page 377, in Ray Duncan's "Advanced
;             OS/2 Programming," Microsoft Press, 1989.
;
; To assemble and link:
;
;     masm rebootdr.asm;
;     link rebootdr,rebootdr.sys,,os2,rebootdr
;
; Apparently some versions of the linker will call the resulting file
; "REBOOTDR.DLL" even though we specifed ".SYS" on the command line.
; In this case, just rename REBOOTDR.DLL to REBOOTDR.SYS and it will
; work fine.
;
; To install, add the line "DEVICE=REBOOTDR.SYS" to the CONFIG.SYS file.
; To reboot, type REBOOT2.  REBOOT2.EXE is a program file that simply
; attempts to open the device "REBOOTZZ", thus causing the machine to
; reboot.
;
; Description:
;
;	This device driver gets installed at boot time.  It sets up a
; dummy character device driver called "REBOOTZZ".  Then, when an 
; application opens the device "REBOOTZZ", this driver gets control.
; It calls one of the DevHlp functions to get the system reboot
; vector, and then jumps to that address, causing the system to reboot.
;
maxcmd		equ		26

stdin		equ		0
stdout		equ		1
stderr		equ		2

cr		equ		0dh
lf		equ		0ah

GetDosVar	equ		24h
GetRebootVector	equ		5

		extrn		DosWrite:far

DGROUP		group		_DATA

_DATA		segment word public 'DATA'

; ***** Device driver header

header		dd		-1
		dw		8880h
		dw		Strat		; our "stragegy" entry point
		dw		0
		db		'REBOOTZZ'	
		db		8 dup (0)

; ***** Device driver variables

devhlp		dd		?		; DevHlp entry point
wlen		dw		?		; DosWrite length

; ***** Dispatch table 

dispch		dw		Init		; 0   Init driver
		dw		ReturnOK	; 1   Media check
		dw		ReturnOK	; 2   Build BPB
		dw		Error		; 3   not used
		dw		ReturnOK	; 4   Read
		dw		ReturnOK	; 5   Nondestructive read
		dw		ReturnOK	; 6   Return input status
		dw		ReturnOK	; 7   Flush input buffers
		dw		ReturnOK	; 8   Write
		dw		ReturnOK	; 9   Write with verify
		dw		ReturnOK	; 10  Return output status
		dw		ReturnOK	; 11  Flush output buffers
		dw		Error		; 12  not used
		dw		DevOpen		; 13  Open
		dw		ReturnOK	; 14  Close
		dw		ReturnOK	; 15  Removable media
		dw		ReturnOK	; 16  Generic IOCTL
		dw		ReturnOK	; 17  Reset media
		dw		ReturnOK	; 18  Get logical drive
		dw		ReturnOK	; 19  Set logical drive
		dw		ReturnOK	; 20  Deinstall
		dw		Error		; 21  not used
		dw		ReturnOK	; 22  Partitionable fixed disks
		dw		ReturnOK	; 23  Get fixed disk unit map
		dw		Error		; 24  not used
		dw		Error		; 25  not used
		dw		Error		; 26  not used

ident		db		cr,lf
		db		'OS/2 reboot driver loaded.  '
		db		'Type REBOOT2 to reboot system.'
		db		cr,lf
ident_len	equ		$ - ident

_DATA		ends


_TEXT		segment word public 'CODE'

		assume cs:_TEXT,ds:DGROUP,es:NOTHING

Strat		proc		far
		mov		di,es:[bx+2]	; get command code
		and		di,0ffh
		cmp		di,maxcmd	; supported command?
		jle		Strat1		; yes
		call		Error		; unsupported command
		jmp		Strat2

Strat1:		add		di,di		; branch to command handler
		call		word ptr [di+dispch]

Strat2:		mov		es:[bx+3],ax	; return status code
		ret
Strat		endp


DevOpen		proc		near

		; Get the address of the reboot vector
		mov		dl,GetDosVar
		mov		al,GetRebootVector
		call		devhlp

                ; AX:BX now contains the reboot vector
                ; We want it to be in ES:BX for a far jump
                mov             es, ax

		; Jump to vector and reboot
		jmp   dword ptr es:[bx]

                ; We should never get here, but return just in case ...
		mov		ax,0100h	; return "done" status
		ret
DevOpen		endp


Error		proc		near		; set error bit, done status
		mov		ax,8103h	; and unknown command code
		ret
Error		endp


ReturnOK	proc		near
		mov		ax,0100h	; return "done" status
		ret
ReturnOK	endp


Init		proc		near
		mov		ax,es:[bx+14]	; get DevHlp entry point
		mov		word ptr devhlp,ax
		mov		ax,es:[bx+16]	
		mov		word ptr devhlp+2,ax

		; set offsets to end of code and data segments
		mov		word ptr es:[bx+14],offset _TEXT:Init
		mov		word ptr es:[bx+16],offset DGROUP:ident

		; display sign-on message
		push		stdout
		push		ds
		push		offset DGROUP:ident
		push		ident_len
		push		ds
		push		offset DGROUP:wlen
		call		DosWrite

		mov		ax,0100h        ; return "done"
		ret
Init		endp

_TEXT		ends

		end



