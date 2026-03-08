include include\masm32rt.inc 

include include\winmm.inc

szText macro name, text:vararg
    local lbl
    jmp   lbl
    name db text, 0
    lbl:
endm

WinMain proto :dword, :dword, :dword, :dword
WndProc proto :dword, :dword, :dword, :dword

.data
    ClassName   db "NumGuessWindow", 0
    AppName     db "Number Guessing Game", 0
    szStaticClass db "STATIC", 0
    szButtonClass db "BUTTON", 0
    szEditClass db "EDIT", 0
    hInstance   dd ?
    lpszCmdLine dd ?

    spookyNumber dd ?
    rand_state dd 69420

    buffer db 64 dup(?)
    buffer2 db 64 dup(?)

    hWnd dd ?          ; window handle
    hEdit dd ?         ; textbox handle
    hHigherLower dd ?  ; higher/lower label handle
    hDebugText dd ?    ; debug text
    hBigText dd ?      ; bigtext
    hClearButton dd ?  ; clear button
    hGuessButton dd ?  ; guess button
    hGuessCount dd ?   ; guess count text
    hGuessRange dd ?   ; guess range text

    szBeepName db "BEEP", 0
    szTadaName db "TADA", 0
    szFahhName db "FAHH", 0

    hYouWin dd ?
    hIconStatic dd ?
    hIconStatic1 dd ?
    hIconStatic2 dd ?
    hIconStatic3 dd ?

    guessCount dd 0
    lowestRange dd 1
    highestRange dd 100

    currentAnimFrame dd 101
    maxAnimFrame dd 157

.code
RandomNum proc              ; LCG because masm32 rand doesn't work for some reason
    invoke GetTickCount
    mov rand_state, eax

    mov eax, rand_state
    imul eax, 1103515245
    add eax, 12345
    mov rand_state, eax
    mov ecx, 100
    xor edx, edx
    div ecx
    inc edx
    mov spookyNumber, edx
    ret
RandomNum endp

start:
    invoke RandomNum

    invoke GetModuleHandle, NULL
    mov    hInstance,       eax

    invoke GetCommandLine
    mov    lpszCmdLine, eax

    invoke WinMain, hInstance, NULL, lpszCmdLine, SW_SHOWDEFAULT

    invoke ExitProcess, eax

WinMain proc hInst :dword, hPrevInst :dword, szCmdLine :dword, nShowCmd :dword
    local wc :WNDCLASSEX
    local msg :MSG
    local lf :LOGFONT
    local hFont :HFONT

    szText szClassName,   "MainWindow"
    szText szWindowTitle, "Number Guessing Game"

    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW or CS_BYTEALIGNWINDOW
	mov wc.lpfnWndProc, WndProc
	mov wc.cbClsExtra, NULL
	mov wc.cbWndExtra, NULL

	push hInst
	pop wc.hInstance

	invoke CreateSolidBrush, 0f0f0f0h
    mov wc.hbrBackground, eax
	mov wc.lpszMenuName,  NULL
	mov wc.lpszClassName, offset szClassName

	invoke LoadIcon, hInst, 101
	mov wc.hIcon, eax
	mov wc.hIconSm, eax

	invoke LoadCursor, hInst, IDC_ARROW
	mov wc.hCursor, eax

	invoke RegisterClassEx, addr wc

    ; create window
	invoke CreateWindowEx, WS_EX_APPWINDOW, addr szClassName, addr szWindowTitle,
				WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, 
				CW_USEDEFAULT, CW_USEDEFAULT, 400, 300, 
				NULL, NULL, hInst, NULL

	mov hWnd, eax

    ; create label
    szText szLabel, "Guess a Number!"
    invoke CreateWindowEx, 0, addr szStaticClass, addr szLabel, 
                WS_CHILD or WS_VISIBLE or SS_CENTER, 
                0, 0, 400, 60, 
                hWnd, 1001, hInst, NULL
    mov hBigText, eax

    ; prepare font
    invoke GetStockObject, DEFAULT_GUI_FONT
    mov ebx, eax
    invoke GetObject, ebx, sizeof LOGFONT, addr lf
    mov lf.lfHeight, -32
    mov lf.lfWeight, 700
    mov dword ptr lf.lfItalic, 0
    mov dword ptr lf.lfUnderline, 0
    mov lf.lfCharSet, DEFAULT_CHARSET
    lea edi, lf.lfFaceName
    invoke lstrcpy, edi, chr$("Comic Sans MS")
    invoke CreateFontIndirect, addr lf
    mov hFont, eax

    ; apply font to bigtext
    invoke SendMessage, hBigText, WM_SETFONT, hFont, TRUE

    ; create image things
    invoke CreateWindowEx, 0, addr szStaticClass, 0,
        WS_CHILD or SS_ICON or SS_REALSIZEIMAGE,
        -50, 100, 100, 280,
        hWnd, 1010, hInst, NULL
    mov hIconStatic, eax

    invoke CreateWindowEx, 0, addr szStaticClass, 0,
        WS_CHILD or SS_ICON or SS_REALSIZEIMAGE,
        110, 100, 100, 280,
        hWnd, 1010, hInst, NULL
    mov hIconStatic1, eax

    invoke CreateWindowEx, 0, addr szStaticClass, 0,
        WS_CHILD or SS_ICON or SS_REALSIZEIMAGE,
        270, 100, 100, 280,
        hWnd, 1010, hInst, NULL
    mov hIconStatic2, eax

    invoke CreateWindowEx, 0, addr szStaticClass, 0,
        WS_CHILD or SS_ICON or SS_REALSIZEIMAGE,
        430, 100, 100, 280,
        hWnd, 1010, hInst, NULL
    mov hIconStatic3, eax

    invoke CreateWindowEx, 0, addr szStaticClass, 0,
        WS_CHILD or SS_ICON or SS_REALSIZEIMAGE,
        50, 0, 600, 60,
        hWnd, 1010, hInst, NULL
    mov hYouWin, eax

    ; create debug text
    szText szDebug, "Debug: 0"
    invoke CreateWindowEx, 0, addr szStaticClass, addr szDebug, 
                WS_CHILD  or SS_LEFTNOWORDWRAP, 
                0, 0, 80, 20, 
                hWnd, 1006, hInst, NULL
    mov hDebugText, eax

    ; create higher/lower text
    szText szMiddleText, 0
    invoke CreateWindowEx, 0, addr szStaticClass, addr szMiddleText, 
                WS_CHILD or WS_VISIBLE or SS_CENTER, 
                0, 80, 400, 70, 
                hWnd, 1005, hInst, NULL
    mov hHigherLower, eax

    ; apply font to hHigherLower
    mov lf.lfHeight, -48
    invoke CreateFontIndirect, addr lf
    mov hFont, eax
    invoke SendMessage, hHigherLower, WM_SETFONT, hFont, TRUE

    ; create textbox
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, addr szEditClass, NULL,
            WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL or ES_NUMBER,
            100, 190, 155, 24,
            hWnd, 1002, hInst, NULL
    mov hEdit, eax

    ; set textbox font
    mov lf.lfHeight, -12
    invoke CreateFontIndirect, addr lf
    mov hFont, eax
    invoke SendMessage, hEdit, WM_SETFONT, hFont, TRUE

    ; create clear button
    szText szClearButtonText, "Clear"

    invoke CreateWindowEx, 0, addr szButtonClass, addr szClearButtonText,
            WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
            260, 190, 60, 25,
            hWnd, 1003, hInst, NULL
    mov hClearButton, eax

    ; set clear button font
    invoke CreateFontIndirect, addr lf
    mov hFont, eax
    invoke SendMessage, hClearButton, WM_SETFONT, hFont, TRUE

    ; create button
    szText szButtonText, "Guess!"

    invoke CreateWindowEx, 0, addr szButtonClass, addr szButtonText,
            WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
            155, 220, 80, 30,
            hWnd, 1004, hInst, NULL
    mov hGuessButton, eax

    ; set button font
    mov lf.lfHeight, -16
    invoke CreateFontIndirect, addr lf
    mov hFont, eax

    invoke SendMessage, hGuessButton, WM_SETFONT, hFont, TRUE

    szText szGuessCount, "Guesses: 0"
    invoke CreateWindowEx, 0, addr szStaticClass, addr szGuessCount, 
                WS_CHILD or WS_VISIBLE or SS_LEFTNOWORDWRAP, 
                8, 240, 100, 20, 
                hWnd, 1006, hInst, NULL
    mov hGuessCount, eax
    invoke SendMessage, hGuessCount, WM_SETFONT, hFont, TRUE

    szText szGuessRange, "Range: 1 - 100"
    invoke CreateWindowEx, 0, addr szStaticClass, addr szGuessRange, 
                WS_CHILD or WS_VISIBLE or SS_RIGHT, 
                255, 240, 130, 25, 
                hWnd, 1006, hInst, NULL
    mov hGuessRange, eax
    invoke SendMessage, hGuessRange, WM_SETFONT, hFont, TRUE

    ; invoke wsprintf, addr buffer, chr$("Debug: %d"), spookyNumber
    ; invoke SetWindowText, hDebugText, addr buffer

    ; Show window (last inst)
	invoke ShowWindow, hWnd, nShowCmd
	invoke UpdateWindow, hWnd

MessagePump:

	invoke GetMessage, addr msg, NULL, 0, 0

	cmp eax, 0
	je  MessagePumpEnd

	invoke TranslateMessage, addr msg
	invoke DispatchMessage,  addr msg

	jmp MessagePump

MessagePumpEnd:
	mov eax, msg.wParam
	ret

WinMain endp

WndProc proc hWin :dword, uMsg :dword, wParam :dword, lParam :dword
    .if uMsg == WM_COMMAND
        mov eax, wParam
        shr eax, 16
        .if eax == BN_CLICKED
            mov eax, wParam
            and eax, 0FFFFh
            .if eax == 1003     ; clear text
                invoke SetWindowText, hEdit, chr$(0)
                invoke SetWindowText, hHigherLower, chr$(0)
                invoke PlaySound, addr szBeepName, hInstance, SND_RESOURCE or SND_ASYNC
            .elseif eax == 1004 ; guess button
                inc guessCount
                invoke wsprintf, addr buffer2, chr$("Guesses: %d"), guessCount
                invoke SetWindowText, hGuessCount, addr buffer2

                invoke GetWindowText, hEdit, addr buffer, 16 
                invoke PlaySound, addr szBeepName, hInstance, SND_RESOURCE or SND_ASYNC

                .if eax == 0
                    invoke PlaySound, addr szFahhName, hInstance, SND_RESOURCE or SND_ASYNC
                    invoke SetWindowText, hEdit, chr$("0")
                    invoke SetWindowText, hHigherLower, chr$("Higher!")
                    ret
                .endif

                invoke crt_atoi, addr buffer
                mov ebx, eax

                ; invoke wsprintf, addr buffer2, chr$("Input:%s Atoi:%d Secret:%d"), 
                ; addr buffer, ebx, spookyNumber
                ; invoke SetWindowText, hDebugText, addr buffer2

                mov eax, spookyNumber

                .if ebx == eax
                    ; hide other controls
                    invoke ShowWindow, hHigherLower, SW_HIDE
                    invoke ShowWindow, hEdit, SW_HIDE
                    invoke ShowWindow, hClearButton, SW_HIDE
                    invoke ShowWindow, hGuessButton, SW_HIDE

                    invoke SetWindowPos, hWnd, 0, 0, 0, 600, 400, SWP_NOMOVE

                    invoke PlaySound, addr szTadaName, hInstance, SND_RESOURCE or SND_ASYNC

                    invoke ShowWindow, hYouWin, SW_SHOW
                    invoke ShowWindow, hIconStatic, SW_SHOW
                    invoke ShowWindow, hIconStatic1, SW_SHOW
                    invoke ShowWindow, hIconStatic2, SW_SHOW
                    invoke ShowWindow, hIconStatic3, SW_SHOW

                    invoke LoadImage, hInstance, 158, IMAGE_ICON, 500, 100, 0
                    invoke SendMessage, hYouWin, STM_SETIMAGE, IMAGE_ICON, eax

                AnimLoop:
                    invoke LoadImage, hInstance, currentAnimFrame, IMAGE_ICON, 180, 260, 0
                    invoke SendMessage, hIconStatic, STM_SETIMAGE, IMAGE_ICON, eax
                    invoke SendMessage, hIconStatic1, STM_SETIMAGE, IMAGE_ICON, eax
                    invoke SendMessage, hIconStatic2, STM_SETIMAGE, IMAGE_ICON, eax
                    invoke SendMessage, hIconStatic3, STM_SETIMAGE, IMAGE_ICON, eax
                    invoke LoadIcon, hInstance, currentAnimFrame
                    invoke SendMessage, hWnd, WM_SETICON, ICON_BIG, eax

                    invoke Sleep, 50
                    mov eax, currentAnimFrame
                    inc eax
                    mov currentAnimFrame, eax
                    mov ebx, maxAnimFrame
                    cmp eax, ebx
                    jne AnimLoop

                    invoke RandomNum
                    invoke SetWindowText, hEdit, chr$(0)
                    invoke SetWindowText, hHigherLower, chr$(0)

                    ; reset everything
                    invoke SetWindowPos, hWnd, 0, 0, 0, 400, 300, SWP_NOMOVE or SWP_NOZORDER
                    mov currentAnimFrame, 101
                    invoke ShowWindow, hEdit, SW_SHOW
                    invoke ShowWindow, hClearButton, SW_SHOW
                    invoke ShowWindow, hGuessButton, SW_SHOW
                    invoke ShowWindow, hHigherLower, SW_SHOW
                    invoke ShowWindow, hYouWin, SW_HIDE
                    invoke ShowWindow, hIconStatic, SW_HIDE
                    invoke ShowWindow, hIconStatic1, SW_HIDE
                    invoke ShowWindow, hIconStatic2, SW_HIDE
                    invoke ShowWindow, hIconStatic3, SW_HIDE

                    mov guessCount, 0
                    invoke wsprintf, addr buffer2, chr$("Guesses: %d"), guessCount
                    invoke SetWindowText, hGuessCount, addr buffer2

                    mov lowestRange, 1
                    mov highestRange, 100
                    invoke wsprintf, addr buffer2, chr$("Range: %d - %d"), lowestRange, highestRange
                    invoke SetWindowText, hGuessRange, addr buffer2

                    invoke wsprintf, addr buffer, chr$("Debug: %d"), spookyNumber
                    invoke SetWindowText, hDebugText, addr buffer
                .elseif ebx < eax
                    mov lowestRange, ebx
                    inc lowestRange
                    invoke wsprintf, addr buffer2, chr$("Range: %d - %d"), lowestRange, highestRange
                    invoke SetWindowText, hGuessRange, addr buffer2

                    invoke PlaySound, addr szFahhName, hInstance, SND_RESOURCE or SND_ASYNC
                    invoke SetWindowText, hHigherLower, chr$("Higher!")
                .else
                    mov highestRange, ebx
                    dec highestRange
                    invoke wsprintf, addr buffer2, chr$("Range: %d - %d"), lowestRange, highestRange
                    invoke SetWindowText, hGuessRange, addr buffer2

                    invoke PlaySound, addr szFahhName, hInstance, SND_RESOURCE or SND_ASYNC
                    invoke SetWindowText, hHigherLower, chr$("Lower!")
                .endif
            .endif
        .elseif eax == EN_CHANGE
            invoke PlaySound, addr szBeepName, hInstance, SND_RESOURCE or SND_ASYNC
        .endif
        ret
    .endif

    .if uMsg == WM_CTLCOLORSTATIC
        invoke GetDlgCtrlID, lParam
        invoke SetBkMode, wParam, TRANSPARENT
        invoke CreateSolidBrush, 0F0F0F0h
        ret
    .endif

	.if uMsg == WM_DESTROY
		invoke PostQuitMessage, 0
		xor eax, eax
		ret
	.endif

	invoke	DefWindowProc, hWin, uMsg, wParam, lParam

	ret

WndProc endp

end start