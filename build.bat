rc.exe /fo resources.res resources.rc
ml.exe /c /coff numguess32.asm
link.exe numguess32.obj /libpath:lib resources.res shlwapi.lib kernel32.lib user32.lib gdi32.lib winmm.lib /entry:start /subsystem:windows