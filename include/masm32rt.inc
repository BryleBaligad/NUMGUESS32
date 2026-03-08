comment * �����������������������������������������������������������������

    The MASM32 Runtime Library include file.

    Differing from most compilers, MASM does not contain any built in
    run time library so it is difficult for a programmer starting with
    MASM to to get any code up and running without having to learn a lot
    of extra information just to do basic things.
    
    This file simplifies entry into assembler programming by making the
    full capacity of the MASM32 library, macro system and include files
    available to programmers undertaking this quest.

    It specifies the normal conditions for building a 32 bit Windows
    program with the minimum processor type, memory model and the need
    for case sensitive capacity.

    The include files are declared in the correct order so that the
    windows.inc file is always first followed by static libraries and
    import libraries for Windows API functions.

    Where there is a corresponding library for either static or import
    libraries, it is included after the include files.

    NOTE : It is to the advantage of the programmer once they have their
    basic code up and running to properly understand the architecture
    of a MASM executable file so that they can construct their own
    projects to more accurately reflect their own application design.

  ����������������������������������������������������������������������� *

      .486                                      ; create 32 bit code
      .model flat, stdcall                      ; 32 bit memory model
      option casemap :none                      ; case sensitive 

;     include files
;     ~~~~~~~~~~~~~
      include include\windows.inc       ; main windows include file
      include include\masm32.inc        ; masm32 library include

    ; -------------------------
    ; Windows API include files
    ; -------------------------
      include include\gdi32.inc
      include include\user32.inc
      include include\kernel32.inc
      include include\Comctl32.inc
      include include\comdlg32.inc
      include include\shell32.inc
      include include\oleaut32.inc
      include include\ole32.inc
      include include\msvcrt.inc

      include include\dialogs.inc       ; macro file for dialogs
      include macros\macros.asm         ; masm32 macro file

;     libraries
;     ~~~~~~~~~
      includelib lib\masm32.lib         ; masm32 static library

    ; ------------------------------------------
    ; import libraries for Windows API functions
    ; ------------------------------------------
      includelib lib\gdi32.lib
      includelib lib\user32.lib
      includelib lib\kernel32.lib
      includelib lib\Comctl32.lib
      includelib lib\comdlg32.lib
      includelib lib\shell32.lib
      includelib lib\oleaut32.lib
      includelib lib\ole32.lib
      includelib lib\msvcrt.lib

; �������������������������������������������������������������������������
