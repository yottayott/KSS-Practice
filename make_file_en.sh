#!/bin/bash

# English menu (the texts of make_file.sh are Japanese)
cp original.sfc patched_en.sfc

# asar in this folder
./asar -Dmenu_english=1 patch.asm patched_en.sfc
