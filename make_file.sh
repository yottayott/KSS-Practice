#!/bin/bash

cp original.sfc patched.sfc

# asar in this folder
./asar patch.asm patched.sfc
