;____________________________________________________________________________________________________________________________
; MD5hash : hashes a string using the md5 algorithm
;ŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻ
; input  :
;  ptBuffer: pointer to the string buffer (doesn't have to be zero-terminated, must be at least 64bytes)
;  dtBufferLength: number of bytes to hash
;  ptMD5Result: pointer to a MD5RESULT structure
; output :
;  ptMD5Result: contains the MD5 hash dwords in dtA, dtB, dtC, dtD
;  ptResult : NULL no ascii output required OR
;             pointer to a string buffer (at least 33 bytes) for md5 digest output (lower case)
;____________________________________________________________________________________________________________________________
; Source : roy|fleur
; Modified by Ziggy 15th August, 2005
;ŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻŻ

MD5hash			proto	:dword,:dword,:dword,:dword

; Usage  : invoke MD5hash, addr ptBuffer, dtBufferLength, addr ptMD5Result, addr ptResult
;
; or
;
;        : invoke MD5hash, addr ptBuffer, dtBufferLength, addr ptMD5Result, NULL


.data

szMD5Format		db	'%.8X%.8X%.8X%.8X',0

.data?
MD5RESULT		STRUCT
	dtA		dd	?
	dtB		dd	?
	dtC		dd	?
	dtD		dd	?
MD5RESULT		ENDS

.code

FF			MACRO	dta,dtb,dtc,dtd,x,s,t				; a = b + ((a + F(b,c,d) + x + t) << s )

			mov	eax,dtb
			mov	ebx,dtc
			mov	ecx,dtd

			; F(x,y,z) = (x and y) or ((not x) and z)
			and	ebx,eax
			not	eax
			and	eax,ecx
			or	eax,ebx

			add	eax,dta
			add	eax,x
			add	eax,t

			mov	cl,s
			rol	eax,cl

			add	eax,dtb

			mov	dta,eax

ENDM

GG			MACRO	dta,dtb,dtc,dtd,x,s,t				; a = b + ((a + G(b,c,d) + x + t) << s)

			mov	eax,dtb
			mov	ebx,dtc
			mov	ecx,dtd

			; G(x,y,z) = (x and z) or (y and (not z))
			and	eax,ecx
			not	ecx
			and	ecx,ebx
			or	eax,ecx

			add	eax,dta
			add	eax,x
			add	eax,t

			mov	cl,s
			rol	eax,cl

			add	eax,dtb

			mov	dta,eax

ENDM

HH			MACRO	dta,dtb,dtc,dtd,x,s,t				; a = b + ((a + H(b,c,d) + x + t) << s)

			mov	eax,dtb
			mov	ebx,dtc
			mov	ecx,dtd

			; H(x,y,z) = x xor y xor z
			xor	eax,ebx
			xor	eax,ecx

			add	eax,dta
			add	eax,x
			add	eax,t

			mov	cl,s
			rol	eax,cl

			add	eax,dtb

			mov	dta,eax

ENDM

II			MACRO	dta,dtb,dtc,dtd,x,s,t				; a = b + ((a + I(b,c,d) + x + t) << s)

			mov	eax,dtb
			mov	ebx,dtc
			mov	ecx,dtd

			; I(x,y,z) = y xor (x or (not z))
			not	ecx
			or	eax,ecx
			xor	eax,ebx

			add	eax,dta
			add	eax,x
			add	eax,t

			mov	cl,s
			rol	eax,cl

			add	eax,dtb

			mov	dta,eax

ENDM

.code

MD5hash	proc	uses eax ebx ecx edx edi esi,ptBuffer:dword,dtBufferLength:dword,ptMD5Result:dword,ptResult:dword

			local	dta:dword,dtb:dword,dtc:dword,dtd:dword

			; phase I · padding
			mov	edi,ptBuffer
			mov	eax,dtBufferLength

			inc	eax
			add	edi,eax
			mov	byte ptr [edi-1],080h

			xor	edx,edx

			mov	ebx,64
			div	ebx

			neg	edx
			add	edx,64

			cmp	edx,8
			jae	@f

			add	edx,64

@@:			mov	ecx,edx
			xor	al,al
			rep	stosb

			mov	eax,dtBufferLength

			inc	edx
			add	dtBufferLength,edx

			xor	edx,edx

			mov	ebx,8
			mul	ebx

			mov	dword ptr [edi-8],eax
			mov	dword ptr [edi-4],edx

			mov	edx,dtBufferLength

			mov	edi,ptBuffer

			; phase II · chaining variables initialization
			mov	esi,ptMD5Result
			assume	esi:ptr MD5RESULT

			mov	[esi].dtA,067452301h
			mov	[esi].dtB,0efcdab89h
			mov	[esi].dtC,098baddfeh
			mov	[esi].dtD,010325476h

			; phase III · hashing
hashloop:		mov	eax,[esi].dtA
			mov	dta,eax
			mov	eax,[esi].dtB
			mov	dtb,eax
			mov	eax,[esi].dtC
			mov	dtc,eax
			mov	eax,[esi].dtD
			mov	dtd,eax

			; round 1
			FF	dta,dtb,dtc,dtd,dword ptr [edi+00*4],07,0d76aa478h
			FF	dtd,dta,dtb,dtc,dword ptr [edi+01*4],12,0e8c7b756h
			FF	dtc,dtd,dta,dtb,dword ptr [edi+02*4],17,0242070dbh
			FF	dtb,dtc,dtd,dta,dword ptr [edi+03*4],22,0c1bdceeeh
			FF	dta,dtb,dtc,dtd,dword ptr [edi+04*4],07,0f57c0fafh
			FF	dtd,dta,dtb,dtc,dword ptr [edi+05*4],12,04787c62ah
			FF	dtc,dtd,dta,dtb,dword ptr [edi+06*4],17,0a8304613h
			FF	dtb,dtc,dtd,dta,dword ptr [edi+07*4],22,0fd469501h
			FF	dta,dtb,dtc,dtd,dword ptr [edi+08*4],07,0698098d8h
			FF	dtd,dta,dtb,dtc,dword ptr [edi+09*4],12,08b44f7afh
			FF	dtc,dtd,dta,dtb,dword ptr [edi+10*4],17,0ffff5bb1h
			FF	dtb,dtc,dtd,dta,dword ptr [edi+11*4],22,0895cd7beh
			FF	dta,dtb,dtc,dtd,dword ptr [edi+12*4],07,06b910122h
			FF	dtd,dta,dtb,dtc,dword ptr [edi+13*4],12,0fd987193h
			FF	dtc,dtd,dta,dtb,dword ptr [edi+14*4],17,0a679438eh
			FF	dtb,dtc,dtd,dta,dword ptr [edi+15*4],22,049b40821h

			; round 2
			GG	dta,dtb,dtc,dtd,dword ptr [edi+01*4],05,0f61e2562h
			GG	dtd,dta,dtb,dtc,dword ptr [edi+06*4],09,0c040b340h
			GG	dtc,dtd,dta,dtb,dword ptr [edi+11*4],14,0265e5a51h
			GG	dtb,dtc,dtd,dta,dword ptr [edi+00*4],20,0e9b6c7aah
			GG	dta,dtb,dtc,dtd,dword ptr [edi+05*4],05,0d62f105dh
			GG	dtd,dta,dtb,dtc,dword ptr [edi+10*4],09,002441453h
			GG	dtc,dtd,dta,dtb,dword ptr [edi+15*4],14,0d8a1e681h
			GG	dtb,dtc,dtd,dta,dword ptr [edi+04*4],20,0e7d3fbc8h
			GG	dta,dtb,dtc,dtd,dword ptr [edi+09*4],05,021e1cde6h
			GG	dtd,dta,dtb,dtc,dword ptr [edi+14*4],09,0c33707d6h
			GG	dtc,dtd,dta,dtb,dword ptr [edi+03*4],14,0f4d50d87h
			GG	dtb,dtc,dtd,dta,dword ptr [edi+08*4],20,0455a14edh
			GG	dta,dtb,dtc,dtd,dword ptr [edi+13*4],05,0a9e3e905h
			GG	dtd,dta,dtb,dtc,dword ptr [edi+02*4],09,0fcefa3f8h
			GG	dtc,dtd,dta,dtb,dword ptr [edi+07*4],14,0676f02d9h
			GG	dtb,dtc,dtd,dta,dword ptr [edi+12*4],20,08d2a4c8ah

			; round 3
			HH	dta,dtb,dtc,dtd,dword ptr [edi+05*4],04,0fffa3942h
			HH	dtd,dta,dtb,dtc,dword ptr [edi+08*4],11,08771f681h
			HH	dtc,dtd,dta,dtb,dword ptr [edi+11*4],16,06d9d6122h
			HH	dtb,dtc,dtd,dta,dword ptr [edi+14*4],23,0fde5380ch
			HH	dta,dtb,dtc,dtd,dword ptr [edi+01*4],04,0a4beea44h
			HH	dtd,dta,dtb,dtc,dword ptr [edi+04*4],11,04bdecfa9h
			HH	dtc,dtd,dta,dtb,dword ptr [edi+07*4],16,0f6bb4b60h
			HH	dtb,dtc,dtd,dta,dword ptr [edi+10*4],23,0bebfbc70h
			HH	dta,dtb,dtc,dtd,dword ptr [edi+13*4],04,0289b7ec6h
			HH	dtd,dta,dtb,dtc,dword ptr [edi+00*4],11,0eaa127fah
			HH	dtc,dtd,dta,dtb,dword ptr [edi+03*4],16,0d4ef3085h
			HH	dtb,dtc,dtd,dta,dword ptr [edi+06*4],23,004881d05h
			HH	dta,dtb,dtc,dtd,dword ptr [edi+09*4],04,0d9d4d039h
			HH	dtd,dta,dtb,dtc,dword ptr [edi+12*4],11,0e6db99e5h
			HH	dtc,dtd,dta,dtb,dword ptr [edi+15*4],16,01fa27cf8h
			HH	dtb,dtc,dtd,dta,dword ptr [edi+02*4],23,0c4ac5665h

			; round 4
			II	dta,dtb,dtc,dtd,dword ptr [edi+00*4],06,0f4292244h
			II	dtd,dta,dtb,dtc,dword ptr [edi+07*4],10,0432aff97h
			II	dtc,dtd,dta,dtb,dword ptr [edi+14*4],15,0ab9423a7h
			II	dtb,dtc,dtd,dta,dword ptr [edi+05*4],21,0fc93a039h
			II	dta,dtb,dtc,dtd,dword ptr [edi+12*4],06,0655b59c3h
			II	dtd,dta,dtb,dtc,dword ptr [edi+03*4],10,08f0ccc92h
			II	dtc,dtd,dta,dtb,dword ptr [edi+10*4],15,0ffeff47dh
			II	dtb,dtc,dtd,dta,dword ptr [edi+01*4],21,085845dd1h
			II	dta,dtb,dtc,dtd,dword ptr [edi+08*4],06,06fa87e4fh
			II	dtd,dta,dtb,dtc,dword ptr [edi+15*4],10,0fe2ce6e0h
			II	dtc,dtd,dta,dtb,dword ptr [edi+06*4],15,0a3014314h
			II	dtb,dtc,dtd,dta,dword ptr [edi+13*4],21,04e0811a1h
			II	dta,dtb,dtc,dtd,dword ptr [edi+04*4],06,0f7537e82h
			II	dtd,dta,dtb,dtc,dword ptr [edi+11*4],10,0bd3af235h
			II	dtc,dtd,dta,dtb,dword ptr [edi+02*4],15,02ad7d2bbh
			II	dtb,dtc,dtd,dta,dword ptr [edi+09*4],21,0eb86d391h

			mov	eax,dta
			add	[esi].dtA,eax
			mov	eax,dtb
			add	[esi].dtB,eax
			mov	eax,dtc
			add	[esi].dtC,eax
			mov	eax,dtd
			add	[esi].dtD,eax

			add	edi,64

			sub	edx,64
			jnz	hashloop

			; phase IV · results

			mov	ecx,4

@@:			mov	eax,dword ptr [esi]
			xchg	al,ah
			rol	eax,16
			xchg	al,ah
			mov	dword ptr [esi],eax

			add	esi,4

			loop	@b

			mov	esi,ptMD5Result

                  cmp ptResult, 0 ; NULL ?
                  je noAscii
			invoke wsprintfA,ptResult,addr szMD5Format,[esi].dtA,[esi].dtB,[esi].dtC,[esi].dtD
                  noAscii:

			ret

MD5hash		endp
