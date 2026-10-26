@echo off

rem English menu (the texts of make_file.bat are Japanese)
copy original.sfc patched_en.sfc

asar -Dmenu_english=1 patch.asm patched_en.sfc

pause