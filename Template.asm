; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
; General Asm Template by Lahar 
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

.686					;Use 686 instuction set to have all inel commands
.model flat, stdcall	;Use flat memory model since we are in 32bit 
option casemap: none	;Variables and others are case sensitive

include Template.inc	;Include our files containing libraries
include md5.asm
include CRC32.asm

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
; Our initialised variables will go into in this .data section
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
.data
	szAppName	db	"Enter Password",0
	szNoPass	db	"Password fields cannot be empty !",0
	szError		db	"Error",0
	szPassSaved	db	"Password saved successfully",0
	szSuccess	db	"Success",0
	szPassNotEqual	db	"Entered passwords are not same !",0
	format			db	"%0.8X",0
	szKeyPath		db	"Software\Shutdowner",0
	szTimer			db	"Timer",0
	
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
; Our uninitialised variables will go into in this .data? section
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
.data?
	hInstance	HINSTANCE	?
	szPass		db	120 dup	(?)
	szRePass	db	120 dup (?)
	ptResult	db	500	dup (?)
	szBuffer	dword ?
	szmd5	MD5RESULT <>
	
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
; Our constant values will go onto this section
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
.const
	IDD_DLGBOX	equ	1001
	IDC_EXIT	equ	1002
	IDC_PASSEDIT	equ	1003
	IDC_REPASSEDIT	equ	1005
	IDC_CHECK 	equ	1004
	IDC_CHKSHOW	equ	1009
	APP_ICON	equ	2000

; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
; This is the section to write our main code
; ллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
.code

start:	
	invoke GetModuleHandle, NULL
	mov hInstance, eax
	invoke InitCommonControls
	invoke DialogBoxParam, hInstance, IDD_DLGBOX, NULL, addr DlgProc, NULL
	invoke ExitProcess, NULL

DlgProc		proc	hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	.if uMsg == WM_INITDIALOG
		invoke SetWindowText, hWnd, addr szAppName
		invoke LoadIcon, hInstance, APP_ICON
		invoke SendMessage, hWnd, WM_SETICON, 1, eax
	.elseif uMsg == WM_COMMAND
		mov eax, wParam
		.if eax == IDC_EXIT
			invoke GetDlgItemText, hWnd, IDC_PASSEDIT, addr szPass, 120
			.if eax != 0
				invoke GetDlgItemText, hWnd, IDC_REPASSEDIT, addr szRePass, 120
				.if eax !=0
					invoke lstrcmp, addr szPass, addr szRePass
					.if eax == 0
						invoke MessageBox, hWnd, addr szPassSaved, addr szSuccess, MB_OK+MB_ICONINFORMATION
						invoke GetDlgItem, hWnd, IDC_EXIT
						invoke EnableWindow, eax, FALSE
						invoke lstrlen, addr szPass
						invoke MD5hash, addr szPass, eax, addr szmd5, addr ptResult
						invoke lstrlen, addr szPass
						invoke CRC32, eax, addr ptResult
						xor eax, 0faceba55h
						invoke wsprintf, addr szBuffer, addr format, eax						
						invoke KeyValueCreateString,addr szKeyPath,addr szTimer, addr szBuffer,1
					.else
						invoke MessageBox, hWnd, addr szPassNotEqual, addr szError, MB_OK+MB_ICONERROR
					.endif		
				.else
					invoke MessageBox, hWnd, addr szNoPass, addr szError, MB_OK+MB_ICONERROR	
					ret	
				.endif	
			.else
				invoke MessageBox, hWnd, addr szNoPass, addr szError, MB_OK+MB_ICONERROR
				ret
			.endif	
		.elseif eax == IDC_CHKSHOW
			invoke IsDlgButtonChecked, hWnd, IDC_CHKSHOW
    		.if EAX == BST_CHECKED
				invoke SendDlgItemMessage, hWnd, IDC_PASSEDIT,EM_SETPASSWORDCHAR, 0 ,0		
				invoke SendDlgItemMessage, hWnd, IDC_REPASSEDIT,EM_SETPASSWORDCHAR, 0 ,0	
			.elseif EAX == BST_UNCHECKED
				invoke SendDlgItemMessage, hWnd, IDC_PASSEDIT,EM_SETPASSWORDCHAR, "*"  ,0		
				invoke SendDlgItemMessage, hWnd, IDC_REPASSEDIT,EM_SETPASSWORDCHAR, "*"  ,0
			.endif		
		
		.endif
	.elseif uMsg == WM_CLOSE
		invoke EndDialog, hWnd, NULL
	.endif
	
	xor eax, eax				 
	Ret
DlgProc EndP

KeyValueCreateString proc szKeyApp:LPSTR, szOperation:LPSTR, szValues:LPSTR, szMode:BYTE
LOCAL szRegHandle1 :DWORD
LOCAL szRegHandle2 :DWORD
DW_SIZE_STRING	EQU	260
	.if szMode == 1
		invoke RegCreateKeyEx,HKEY_LOCAL_MACHINE, szKeyApp,0,0,REG_OPTION_NON_VOLATILE,KEY_CREATE_SUB_KEY + KEY_SET_VALUE ,NULL,addr szRegHandle1, addr szRegHandle2
		invoke RegSetValueEx, szRegHandle1,szOperation,NULL,REG_SZ, szValues,  DW_SIZE_STRING
		invoke RegCloseKey, szRegHandle1
	.elseif szMode == 0	
		invoke RegOpenKeyEx,HKEY_LOCAL_MACHINE, szKeyApp,0,KEY_ALL_ACCESS, addr szRegHandle1
		invoke RegDeleteValue,szRegHandle1, szOperation
		invoke RegCloseKey, szRegHandle1
	.endif	
	Ret
KeyValueCreateString EndP


end start	
	 