;KSS Practice Hack

; compile to FastROM
!_F = $800000

; give the cartridge more SRAM (256 KB since 2026-10-15: the room PBs are in bank $42, pb.asm)
ORG !_F+$00FFD8
        db $08

; These are ran first because they are not part of the main code block
incsrc "src/defines.asm"
incsrc "src/hex_edits.asm"
incsrc "src/hud.asm"   ;commenting out for optimization purposes

; These are all graphics inserts, all of them are compressed graphics. They have minor edits but the entire graphics section needs to be reinserted because of the compression.
incsrc "graphics/graphics.asm"
incsrc "graphics/hud_layouts.asm"

; All of these are ran together because they are all going to be placed in the blank space in ROM
ORG $00F140
incsrc "src/init.asm"
incsrc "src/cpu.asm"
incsrc "src/every_frame.asm"
incsrc "src/gameplay.asm"
incsrc "src/file_select.asm"
incsrc "src/subgame_title.asm"
incsrc "src/map_screens.asm"
incsrc "src/free_movement.asm"
incsrc "src/abilities.asm"
incsrc "src/kirby_colors.asm"
incsrc "src/subroutines.asm"
;incsrc "src/hblank.asm"
incsrc "src/nmi.asm"
incsrc "src/segment.asm"
incsrc "src/warp_settings.asm"
incsrc "src/mute_toggle.asm"

; make sure we don't overflow
print "bank00 end: ", pc
assert pc() <= $00FFBF

; savestate / room reload code and RNG tables (free space at the end of bank $0F)
org $0FF600
incsrc "src/room_reload.asm"
incsrc "src/qsql.asm"
incsrc "src/rng_tables.asm"
print "bank0F end: ", pc
assert pc() <= $0FFFFF

; larger free space for menu code
org $19F1A0
incsrc "src/menu_font.asm"
incsrc "src/menu.asm"
print "bank19 end: ", pc
assert pc() < $1A0000

; room table of the warp menu (free space at the end of bank $06; generated, see tools/make_room_list.py)
org $06F400
incsrc "src/room_table.asm"
pb_code:                    ; the room PBs follow (pb.asm, at the end: it uses the defines of the HUDs)
print "bank06 end: ", pc
assert pc() <= $070000

; lag counter, Select + X, the timer (free space at the end of bank $1B)
org $1BF9AC
incsrc "src/extras.asm"
incsrc "src/segment_timer.asm"   ; (moved from bank $0F, 2026-10-10: bank $0F was full)
print "bank1B end: ", pc
assert pc() <= $1BFFFF

; the しょうさい HUD (free space at the end of banks $21 and $25; its font at the end of bank $05)
if !detail_hud
org $21FC40
incsrc "src/detail_hud.asm"
endif

; the corkboard (sub-game select): A once, no show of new cards
incsrc "src/corkboard.asm"

; the timer / RNG in the HUD (free space at the end of bank $15)
if !lag_baseline == 0
org $15F7CD
incsrc "src/hud_timer.asm"
print "bank15 end: ", pc
assert pc() <= $15FFFF
endif

; the RNG count of the らんすう / しょうさい HUDs (free space at the end of bank $23; its tables at
; the end of banks $17 and $0B)
if !lag_baseline == 0
org $23FA00
incsrc "src/rng_count.asm"
print "bank23 end: ", pc
assert pc() <= $23FFFF
endif

; the room PBs, after the room table in bank $06
if !pb
org pb_code
incsrc "src/pb.asm"
print "bank06 end (PBs): ", pc
assert pc() <= $070000
endif

; make sure the ROM is expanded to the full 1MBit
ORG !_F+$1FFFFF
        db $EA



; 3FFFF
; 1FFFF
