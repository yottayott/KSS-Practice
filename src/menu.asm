; Character Data (this is compressed data):
; JP ROM: $2550EE
; EN ROM: $285A43
; JP Text Location Pointer: $CFB430
 
struct MenuOffsets $000000
  .Title: skip 2
  .ChoiceCount: skip 2
  .UpMenu: skip 2
  .TextBank: skip 1
endstruct

struct Choices extends MenuOffsets
  .Text: skip 2
  .Code: skip 2
endstruct

!menu_vram = $0040
!menu_row_size = $0020

!menu_mirror = $7FF000

!cursor_sprite = $00E8

!dp_menu = $41
!dp_scratch = $45

!sfx_open = $41
!sfx_select = $32
!sfx_back = $28
!sfx_warp_elsewhere = $48
!sfx_ability = $44

!palette_fg = $7FFF    ; text: white (2026-10-08; gray $5294 / $6318 before, $0000 black originally)
!palette_bg = $2862    ; background: deep blue (2026-10-08; $0000 black before, $1576 orange originally)

open_custom_menu:
  LDA #$0001
  STA !custom_menu_enabled

  ; dark until the first menu screen is written (custom_menu): the screen used to show the
  ; game (or the corkboard after power on) half set up for a few frames.
  ; save the brightness first (save_registers runs later and would save the 0)
  LDA $00305F
  STA $40F6F0
  LDA #$0000
  STA $00305F

  ; the menu language of the build (!menu_english): 0 = English, 1 = Japanese (draw_string)
  LDA.w #1-!menu_english
  STA !custom_menu_language

  REP #$30
  LDA.l !custom_menu_apply_rng
  BNE .use_pending_rng_on_open
  LDA !RNG
  BRA .store_open_rng
  .use_pending_rng_on_open:
    LDA.l !store_RNG
  .store_open_rng:
    STA.l !custom_menu_open_rng


  ; load fonts
  LDA.w #font_dma_table
  LDX.W #bank(font_dma_table)
  JSL !load_dma_table

  JSR save_registers

  LDA #$0000
  STA $003061 ; set BG mode 0
  STA $003063 ; set BG1 tilemap VRAM address and size

  LDA #$0001 ; disable OAM and all other layers but 1
  STA $003072

  ; set BG tilemap offsets to $3000.w ($6000)
  ; we only use layer 1 but clobbering them all is easier
  LDA #$3333
  STA $003067

  ; disable hdma for fatty whale fight etc
  LDA #$0000
  STA $003092
  STA $00309C
  LDA #$84BB
  STA $00309B

  ; clear layer 1 scroll pos
  LDA #$0000
  STA $003037
  STA $003039
  STA $00303B
  STA $00303D
  STA $00305B
  STA $00305D

  ; clear screen darken filter
  STA $003076
  STA $003078
  STA $00307A


  LDA.w #.set_palette
  LDX.w #bank(.set_palette)
  JSL !sa1_executesnes 
  BRA +
  
  .set_palette
    ; palette
    LDA #!palette_bg
    STA $7E0502
    LDA #!palette_fg
    STA $7E0504
    RTL
  +

  ; open main menu
  LDA #menu_main
  STA !custom_menu_pointer
  LDA #$0000
  STA !custom_menu_cursor

  ; play sfx
  SEP #$20
  LDA #!sfx_open
  STA !current_sfx_long
  REP #$20
  JSR play_sound_on_snes

; main loop
custom_menu:
  ; one more pass of the menu (it reads the controller): tools/bizhawk/lag_compare.lua counts
  ; these with the game's frames ($3094) to record and play inputs (2026-10-08)
  LDA.l !menu_frames
  INC A
  STA.l !menu_frames

  ; allow for resetting the game while also in this menu
  ; jumps to custom routine in init.asm that lets us jump to the reset game routine from bank $00
  JSL check_reset

  ; setup dp_menu
  LDA !custom_menu_pointer
  STA !dp_menu
  SEP #$20
  LDA.b #bank(menu_main)
  STA !dp_menu+2
  REP #$20

  JSL !update_layers_input

  ; exit on R+Start
  LDA !p1controller_hold
  AND #!btn_r
  BEQ +
    LDA !p1controller_frame
    CMP #!btn_start
    BNE ++
      JMP exit_menu
    ++
  +

  ; exit immediately on X
  LDA !p1controller_frame
  CMP #!btn_x
  BNE +
    JMP exit_menu
  +

  ; cursor movement
  JSR update_cursor

  ; go up a menu
  LDA !p1controller_frame
  CMP #!btn_b
  BNE +
    ; play sfx
    SEP #$20
    LDA #!sfx_back
    STA !current_sfx_long
    REP #$20
    JSR play_sound_on_snes

    ; get next menu pointer
    LDY.w #MenuOffsets.UpMenu
    LDA [!dp_menu], Y

    ; if it's 0000, exit the menu
    BNE ++
      JMP exit_menu
    ++
    ; set menu
    STA !custom_menu_pointer
    LDA #$0000
    STA !custom_menu_cursor
    JMP custom_menu
  +

  ; do the thing
  LDA !p1controller_frame
  AND #!btn_a|!btn_y
  BEQ +
    ; prep sound effect
    SEP #$20
    LDA #!sfx_select
    STA !current_sfx_long
    REP #$20
    ; load the first menu function pointer
    LDA !custom_menu_cursor
    TAX
    LDA.w #MenuOffsets.Choices[0].Code
    CLC
    ADC !custom_menu_pointer
    ; add the offset to get to the right index
    CPX #$0000
    BEQ .done_adding
    .add_loop:
      CLC
      ADC.w #sizeof(MenuOffsets.Choices)
      DEX
      BNE .add_loop
    .done_adding:
    TAX
    JSR ($0000, X)
    JSR play_sound_on_snes
    ; exit if menu is now $0000
    LDA !custom_menu_pointer
    BNE ++
      JMP exit_menu
    ++
    ; restart loop in case menu changed
    JMP custom_menu
  +

  ; switch language on select
  ;LDA !p1controller_frame
  ;CMP #!btn_select
  ;BNE +
  ;  LDA !custom_menu_language
  ;  EOR #$0001
  ;  STA !custom_menu_language
  ;+

  ; build menu on snes cpu
  LDA.w #draw_screen
  LDX.w #bank(draw_screen)
  JSL !sa1_executesnes 

  ; write menu mirror to PPU
  JSR write_mirror

  ; max brightness (from the second loop on, see open_custom_menu)
  LDA #$000F
  STA $00305F

  ; loop
  JMP custom_menu
update_cursor:
  LDA !custom_menu_pointer
  CMP #menu_rng_count
  BEQ ++
  CMP #menu_warp_rng_count
  BNE +
  ++
    JSR update_rng_count_editor
    RTS
  +
  CMP #menu_warp_rng_value
  BEQ ++
  CMP #menu_rng_value
  BNE +
  ++
    JSL update_rng_value_editor
    RTS
  +
  CMP #menu_warp_custom
  BNE +
    JMP update_warp_custom
  +
  if !pb
  ; segment lists: Select clears the PB of the room shown (pb.asm)
  LDA !p1controller_frame
  CMP #!btn_select
  BNE +
  JSL room_pick_clear_pb
  BCC ++
  SEP #$20
  LDA #!sfx_back
  STA !current_sfx_long
  REP #$20
  JSR play_sound_on_snes
  ++
  RTS
  +
  endif
  ; segment lists: L / R go to the segment list of the previous / next sub-game (2026-10-16)
  LDA !p1controller_frame
  AND #!btn_l|!btn_r
  BEQ +
  JSL seg_list_page
  BCC update_cursor_normal
  JMP set_menu_and_cursor
  +
  ; segment lists: Left / Right change the room of the segment
  LDA !p1controller_frame
  AND #!btn_left|!btn_right
  BEQ update_cursor_normal
  JSL room_pick_change
  RTS

update_cursor_normal:
  LDA !p1controller_frame
  CMP #!btn_up
  BNE +
    LDA !custom_menu_cursor
    DEC
    CMP #$FFFF
    BNE ++
      ; wrap to end
      LDY.w #MenuOffsets.ChoiceCount
      LDA [!dp_menu], Y
      DEC
    ++
    STA !custom_menu_cursor
  +
  LDA !p1controller_frame
  CMP #!btn_down
  BNE +
  LDA !custom_menu_cursor
  INC
  LDY.w #MenuOffsets.ChoiceCount
  CMP [!dp_menu], Y
  BNE ++
    ; wrap to begin
    LDA #$0000
  ++
  STA !custom_menu_cursor
  +
  RTS

update_rng_count_editor:
  LDA !p1controller_frame
  CMP #!btn_up
  BEQ .increment_digit
  CMP #!btn_down
  BEQ .decrement_digit
  CMP #!btn_left
  BEQ .move_left
  CMP #!btn_right
  BEQ .move_right
  RTS

  .increment_digit:
    JSR increment_rng_count_digit
    RTS
  .decrement_digit:
    JSR decrement_rng_count_digit
    RTS
  .move_left:
    JSR move_rng_count_digit_left
    RTS
  .move_right:
    JSR move_rng_count_digit_right
    RTS

exit_menu:
  LDA #$0000
  STA !custom_menu_enabled
  ; clear controller inputs
  LDA #$0000
  STA !p1controller_frame
  JSL !update_layers_input

  ; restore clobbered VRAM
  LDA.w #restore_dma_table
  LDX.w #bank(restore_dma_table)
  JSL !load_dma_table

  JSR restore_registers
  JSR apply_queued_rng_on_exit
  if !detail_hud
  JSL detail_hud_menu_exit    ; the しょうさい HUD switched on / off (detail_hud.asm)
  endif
  RTL



save_registers:
  LDA !dp_scratch
  STA $40F6C2
  LDA !dp_scratch+2
  STA $40F6C4
  LDA !dp_scratch+4
  STA $40F6C6

  LDA !dp_menu
  STA $40F6C8
  LDA !dp_menu+2
  STA $40F6CA

  LDA $003061 ; BG mode
  STA $40F6E0
  LDA $003063 ; BG1 tilemap VRAM address and size
  STA $40F6E2

  ; set BG tilemap offsets
  LDA $003067
  STA $40F6E4

  ; layer 1 scroll pos
  LDA $003037
  STA $40F6E6
  LDA $003039
  STA $40F6E8
  LDA $00303B
  STA $40F6EA
  LDA $00303D
  STA $40F6EC

  ; layer 1 scroll offset
  LDA $00305B
  STA $40F6CC
  LDA $00305D
  STA $40F6CE

  ; background darken
  LDA $003076
  STA $40F6D0
  LDA $003078
  STA $40F6D2
  LDA $00307A
  STA $40F6D4

  ; layer select
  LDA $003072
  STA $40F6EE

  ; brightness and oam flags: saved in open_custom_menu before it darkens the screen

  ; HDMA toggle
  LDA $003092
  STA $40F6F2
  ; order matters here
  LDA $00309C
  STA $40F6F4
  LDA $00309B
  STA $40F6F6

  LDA.w #.backup_palette
  LDX.w #bank(.backup_palette)
  JSL !sa1_executesnes 
  BRA +
  
  .backup_palette
    LDA $7E0502
    STA $40F6F8
    LDA $7E0504
    STA $40F6FA
    RTL
  +
  RTS

play_sound_on_snes:
  LDA.w #.onSNES
  LDX.w #bank(.onSNES)
  JSL !sa1_executesnes 
  BRA +
  .onSNES
    JSL !play_sfx_long
    RTL
  +
  RTS

run_snes_rng_routine:
  JSL !sa1_executesnes
  RTS

restore_registers:
  LDA $40F6C2
  STA !dp_scratch
  LDA $40F6C4
  STA !dp_scratch+2
  LDA $40F6C6
  STA !dp_scratch+4

  LDA $40F6C8
  STA !dp_menu
  LDA $40F6CA
  STA !dp_menu+2

  LDA $40F6E0
  STA $003061 ; BG mode
  LDA $40F6E2
  STA $003063 ; BG1 tilemap VRAM address and size

  ; set BG tilemap offsets
  LDA $40F6E4
  STA $003067

  ; layer 1 scroll pos
  LDA $40F6E6
  STA $003037
  LDA $40F6E8
  STA $003039
  LDA $40F6EA
  STA $00303B
  LDA $40F6EC
  STA $00303D

  ; layer 1 scroll offset
  LDA $40F6CC
  STA $00305B
  LDA $40F6CE
  STA $00305D

  ; background darken
  LDA $40F6D0
  STA $003076
  LDA $40F6D2
  STA $003078
  LDA $40F6D4
  STA $00307A

  ; layer select
  LDA $40F6EE
  STA $003072

  ; brightness and oam flags
  LDA $40F6F0
  STA $00305F

  ; HDMA toggle
  LDA $40F6F2
  STA $003092
  ; order matters here
  LDA $40F6F4
  STA $00309C
  LDA $40F6F6
  STA $00309B

  LDA.w #.restore_palette
  LDX.w #bank(.restore_palette)
  JSL !sa1_executesnes 
  BRA +
  
  .restore_palette
    LDA $40F6F8
    STA $7E0502
    LDA $40F6FA
    STA $7E0504
    RTL
  +

  RTS


write_mirror:
  ; set transfer mode 03
  LDA #$0003
  STA !dma_type

  ; set source and size
  LDA #!menu_mirror
  STA !dma_src
  LDA #$007F
  STA !dma_src_bank
  LDA #$0740
  STA !dma_size

  ; set dest
  LDA #$0000
  STA !dma_dest

  JSL !write_to_dma_buffer
  RTS


; Code for handling room warps

!subgame_long = $0032EA
!room_number_long = $0032F2
!level_long = $0032EE
!cutscene_long = $00332A
!kirby_x_long = $00330C 
!kirby_y_long = $003310

pushpc
ORG $01DF960
  warp_to_level:
    STA !custom_menu_level_table

    ; check current gamemode, if not in the actual game state, set an address so that the next game mode change gets set to the game state
    .check_game_mode
      LDA !game_mode
      CMP #$0003
      BEQ .reset_warp

      LDA #$0001      ; set warp to 1 to tell the game swap to set the game mode to 3 later
      BRA .apply_warp
      
    .reset_warp
      LDA #$0000    ; set this to 0 if already in the game state just in case it was set to 1 somehow

    .apply_warp
      STA !is_warping


    SEP #$30

    LDA.l !warp_table_bank        ; the table's bank (room_table)
    PHA
    PLB
    
    LDY #$00

    ; current_sfx will be played when this returns
    LDA #!sfx_warp_elsewhere
    STA !current_sfx_long

    LDA (!custom_menu_level_table)
    STA !room_number_long

    INY

    LDA (!custom_menu_level_table),Y
    STA !level_long

    ; the room and level are 8-bit here: clear the high bytes (a Goal Game door leaves the room
    ; at $7FFF, the level exit, and a room load of $7F01 hangs)
    LDA #$00
    STA !room_number_long+1
    STA !level_long+1

    REP #$20

    INY

    ; Start writing level data
    LDA !custom_menu_subgame_warp
    STA !subgame_long

    LDA (!custom_menu_level_table),Y
    STA !cutscene_long

    INY
    INY

    LDA (!custom_menu_level_table),Y
    STA !kirby_x_long

    INY
    INY

    LDA (!custom_menu_level_table),Y
    STA !kirby_y_long

    LDA #$0001
    STA !reload_room_long

    ; set current menu to $0000 to exit cleanly
    SEP #$30
    
    LDA #$00
    PHA
    PLB

    ; apply the map to warp to after defeating a stage
    ; also apply ability config if warping to MWW
    LDA !subgame
    CMP #$05  ; MWW
    BNE +

    LDA #$02
    STA !map_to_load_into

    ; load in MWW ability state
    LDX !level_number
    JSL convert_planet_id
    ; the abilities of the start of the planet (the original hack warped to the end of a
    ; level and counted one planet more here)
    JSL mww_assign_starting_abilities

    REP #$20
    SEP #$10
    BRA .end_transfer

    +
    CMP #$02  ; Dyna
    BNE +
    STZ !map_to_load_into
    BRA .end_transfer

    +
    CMP #$04  ; RoMK
    BNE +
    LDA #$01
    STA !map_to_load_into

    +
    .end_transfer
      REP #$30
      LDA #$0002          ; restart the segment timer once the screen lights up again
      STA.l !seg_timer_reset
      LDA #$0000
      STA !custom_menu_pointer
      STA !screen_brightness_long
      STA !screen_fade_long
      RTL

incsrc "room_warp.asm"
assert pc() <= $1E0000


; hijacks from different gamemodes so that you can warp from anywhere
; title screen
ORG $00BDF3
  JSR check_gamemode_on_change
; corkboard
ORG $00BE38
  JSR check_gamemode_on_change
; sound test
ORG $00C6FB
  JSR check_gamemode_on_change
; mini-games
ORG $00C715
  JSR check_gamemode_on_change

; for loading room coordinates correctly (they are usually otherwise reset to the first set)
ORG $00D947
  JSR check_gamemode_on_coordinates_load

pullpc


; audio settings code
turn_on_mute:
  LDA #$01
  STA !mute_toggle
  STZ !volume
  BRA finalize_apuio

stereo_mono:
  STA !stereo_mono  ; use menu cursor to store if stereo or mono
  LDA !mute_toggle
  BEQ +
  STZ !mute_toggle
  LDA #$FF 
  JSL check_if_muted_long   ; (was STA !volume)

finalize_apuio:
  TXA
  + REP #$20
  RTS

; DMA tables
; If byte 0 is negative, data is decompressed
; For mode explanations see https://github.com/Ankouno/KSS-disassembly/blob/9863c88e7f987e71bca858cd6a466ea04b5b8339/Bank00.asm#L869
;[mode] [datasize] [addr rev][pg] [addr dest]
font_dma_table:
; Entry 0: Back up existing data in destination to SRAM in free space at E400
; HACK: the first value is duplicated, so we read two extra bytes
db $15
dw $12C2
dl $40E400
dw $3000
; Entry 1: Decompress JP font to VRAM 3000.w ($6000) (same as vanilla)
db $83
dw $0890
dl jp_text_start
dw $3000
; Entry 2: Decompress EN font to VRAM 3600.w
db $83
dw $06C0
dl en_text_start
dw $3480
; Entry 3: Back up the area we will use for tilemap data (write_mirror writes $0740 bytes,
; +2 for the duplicated first value). $40FE42-$40FEFF is left free (room loop, Warp Settings).
db $15
dw $0742
dl $40F700
dw $0000
; End of table
db $FF

restore_dma_table:
; Entry 0: Restore data in destination to SRAM in free space at E400
; HACK: the first value from the read previously was duplicated, so we start two bytes late
db $03, $C0, $12, $02, $E4, $40, $00, $30
; Entry 1: Restore beginning of VRAM
; HACK: the first value from the read previously was duplicated, so we start two bytes late
db $03, $40, $07, $02, $F7, $40, $00, $00
; End of table
db $FF

menu_header: %text("KSS Practice Hack ★ 10/22/2026","スパデラ れんしゅう　ハック    ★ １０/２２/２０２６")

option_noop:
  RTS

set_rng_to_a:
  STA.l !store_RNG
  JSR queue_rng_apply
  RTS

apply_queued_rng_on_exit:
  REP #$30
  LDA.l !custom_menu_apply_rng
  BNE .use_queued_rng
  LDA.l !custom_menu_open_rng
  STA.l !store_RNG
  BRA .write_rng
  .use_queued_rng:
    LDA.l !store_RNG
  .write_rng:
  STA.l !store_RNG
  LDA.l !store_RNG
  STA !RNG
  STA $0743
  STA.l !RNG_long
  STA.l !RNG_sa1_long
  LDA.w #apply_stored_rng_on_snes
  LDX.w #bank(apply_stored_rng_on_snes)
  JSR run_snes_rng_routine
  .done
    RTS

apply_stored_rng_on_snes:
  REP #$30
  LDA.l !store_RNG
  STA !RNG
  STA.l !RNG_long
  LDA #$FFFF
  STA $00B7
  SEP #$20
  LDA #$01
  STA !write_to_HUD
  REP #$30
  RTL

queue_rng_apply:
  LDA #$0020
  STA.l !custom_menu_apply_rng
  RTS

init_rng_count_editor:
  SEP #$20
  LDA.l !custom_menu_rng_count_initialized
  CMP #$A5
  BEQ .sanitize
  LDA #$00
  STA.l !custom_menu_rng_count_digits
  STA.l !custom_menu_rng_count_digits+1
  STA.l !custom_menu_rng_count_digits+2
  STA.l !custom_menu_rng_count_digits+3
  STA.l !custom_menu_rng_count_digits+4
  STA.l !custom_menu_rng_count_digit
  LDA #$A5
  STA.l !custom_menu_rng_count_initialized
  .sanitize:
  REP #$30
  LDX #$0000
  .sanitize_digits:
    SEP #$20
    LDA.l !custom_menu_rng_count_digits,X
    CMP #$0A
    BCC .digit_ok
    LDA #$00
    STA.l !custom_menu_rng_count_digits,X
    .digit_ok:
    REP #$30
    INX
    CPX #$0005
    BNE .sanitize_digits
  SEP #$20
  LDA.l !custom_menu_rng_count_digit
  CMP #$05
  BCC .done
  LDA #$00
  STA.l !custom_menu_rng_count_digit
  .done:
  REP #$30
  RTS

increment_rng_count_digit:
  REP #$30
  LDA.l !custom_menu_rng_count_digit
  AND #$00FF
  TAX
  SEP #$20
  LDA.l !custom_menu_rng_count_digits,X
  CMP #$09
  BCC .increment
  LDA #$00
  BRA .store
  .increment:
    INC A
  .store:
    STA.l !custom_menu_rng_count_digits,X
    REP #$30
    RTS

decrement_rng_count_digit:
  REP #$30
  LDA.l !custom_menu_rng_count_digit
  AND #$00FF
  TAX
  SEP #$20
  LDA.l !custom_menu_rng_count_digits,X
  BNE .decrement
  LDA #$09
  BRA .store
  .decrement:
    DEC A
  .store:
    STA.l !custom_menu_rng_count_digits,X
    REP #$30
    RTS

move_rng_count_digit_left:
  REP #$30
  LDA.l !custom_menu_rng_count_digit
  AND #$00FF
  BEQ .wrap
  DEC A
  BRA .store
  .wrap:
    LDA #$0004
  .store:
    SEP #$20
    STA.l !custom_menu_rng_count_digit
    REP #$30
    RTS

move_rng_count_digit_right:
  REP #$30
  LDA.l !custom_menu_rng_count_digit
  AND #$00FF
  CMP #$0004
  BCS .wrap
  INC A
  BRA .store
  .wrap:
    LDA #$0000
  .store:
    SEP #$20
    STA.l !custom_menu_rng_count_digit
    REP #$30
    RTS

sync_current_rng_to_store:
  REP #$30
  LDA.l !custom_menu_apply_rng
  BNE .done
  LDA.l !custom_menu_open_rng
  STA.l !store_RNG
  .done
  RTS

; A = jump table offset (!rng_jump_*)
advance_rng_steps_from_current:
  REP #$30
  PHA
  JSR sync_current_rng_to_store
  PLA
  TAX
  JSR rng_jump
  JSR queue_rng_apply
  RTS

!rng_jump_1     = 0*34
!rng_jump_10    = 1*34
!rng_jump_100   = 2*34
!rng_jump_1000  = 3*34
!rng_jump_10000 = 4*34

; Advance !store_RNG by 1/10/100/1000/10000 steps at once, X = table offset.
; Uses the precomputed tables in rng_tables.asm instead of stepping 11 bits per advance,
; so a full 5 digit count takes a few thousand cycles instead of several seconds.
rng_jump:
  LDA.l !store_RNG
  TAY
  LDA.l rng_jump_tables+32,X  ; constant part
  .bit_loop:
    CPY #$0000
    BEQ .done
    PHA
    TYA
    LSR A
    TAY
    PLA
    BCC .next_bit
    EOR.l rng_jump_tables,X
  .next_bit:
    INX
    INX
    BRA .bit_loop
  .done:
  STA.l !store_RNG
  RTS

apply_rng_count:
  JSR rng_count_compute
  JSR queue_rng_apply
  RTS

; the RNG after the count of the editor (from $7777) -> !store_RNG
rng_count_compute:
  REP #$30
  JSR init_rng_count_editor
  LDA #$7777
  STA.l !store_RNG

  ; digits are stored most significant first
  LDY #$0000
  .digit_loop:
    TYX
    LDA.l !custom_menu_rng_count_digits,X
    AND #$00FF
    BEQ .next_digit
    PHY
    PHA                 ; 3,S = times left
    TYA
    ASL A
    TAX
    LDA.l .digit_tables,X
    PHA                 ; 1,S = table offset
    .repeat:
      LDA $01,S
      TAX
      JSR rng_jump
      LDA $03,S
      DEC A
      STA $03,S
      BNE .repeat
    PLA
    PLA
    PLY
  .next_digit:
    INY
    CPY #$0005
    BNE .digit_loop
  RTS

  .digit_tables:
    dw !rng_jump_10000, !rng_jump_1000, !rng_jump_100, !rng_jump_10, !rng_jump_1

set_menu_and_cursor:
  STA !custom_menu_pointer
  LDA #$0000
  STA !custom_menu_cursor
  RTS

back_to_main:
  LDA #menu_main
  JSR set_menu_and_cursor
  RTS

; back to the main menu, the cursor on choice A
main_menu_at:
  PHA
  LDA #menu_main
  JSR set_menu_and_cursor
  PLA
  STA !custom_menu_cursor
  RTS

back_one:
  ; get next menu pointer
  LDY.w #MenuOffsets.UpMenu
  LDA [!dp_menu], Y
  JSR set_menu_and_cursor
  RTS


; Boss Screen Flashing and the language choice were removed from the segment practice
; version (commented out below; the language is chosen when building, !menu_english). じこベスト
; けす is gone (2026-10-26): the PB of one room is cleared with Select in the segment lists.
; Skip Title Screen is back (2026-10-26) as タイトル とばす, switched with A on the main menu
; like HUD (it was a screen of its own).
; 2026-10-08: the Warp Settings, HUD Display and Audio Settings screens are gone: HUD and Audio
; change with A on the main menu, the warp ability / RNG are main menu choices (their values
; are drawn next to them: draw_warp_settings in menu_draw.asm). "げんざい らんすう" (the RNG
; Settings before) changes the RNG of the game now, "ワープ らんすう" the RNG set by a warp.
menu_main:
  dw text_main, $000B, $0000
  db bank(text)
  dw text_warp, .opt1_code
  dw text_warp_ability, .ability_code
  dw text_warp_rng, .warp_rng_code
  dw text_rng, .opt3_code
  dw text_hud, .hud_code
  dw text_autoboot, .autoboot_code
  dw text_mww_abilities, .opt2_code
  dw text_color, .opt4_code
  dw text_audio, .audio_code
  dw text_sa1adjustment, .opt8_code
  dw text_about, .about_code
  ; the room loop is switched with L+R+B during gameplay (room_loop_hotkey in qsql.asm)
  .ability_code:
    LDA #menu_warp_ability
    JSR set_menu_and_cursor
    LDA.l !warp_ability_preset
    STA !custom_menu_cursor
    RTS
  .warp_rng_code:
    LDA #menu_warp_rng
    JSR set_menu_and_cursor
    LDA.l !warp_rng_preset
    STA !custom_menu_cursor
    RTS
  .hud_code:
    ; timer -> RNG -> lag frames (-> しょうさい, !detail_hud) -> timer
    LDA !hud_display_mode
    INC A
    CMP.w #3+!detail_hud
    BCC +
    LDA #$0000
    +
    STA !hud_display_mode
    RTS
  .autoboot_code:
    ; power on: the title screen <-> the corkboard with file 1 (init.asm)
    SEP #$20
    LDA.l !autoboot_corkboard
    EOR #$01
    STA.l !autoboot_corkboard
    REP #$20
    RTS
  .audio_code:
    ; stereo -> mono -> off -> stereo
    SEP #$20
    LDA !mute_toggle
    CMP #$01
    BEQ ++                      ; off -> stereo (A = 1 - 1 = 0)
    LDA !stereo_mono
    BEQ +                       ; stereo -> mono
    JMP turn_on_mute            ; mono -> off
    +
    INC A
    JMP stereo_mono
    ++
    DEC A
    JMP stereo_mono
  .opt1_code:
    ; after a warp: straight to the segment list of that segment, on it
    LDA.l !room_last_valid
    BEQ +
    LDA.l !room_list_menu
    STA !custom_menu_pointer
    LDA.l !room_list_seg
    SEC
    SBC.l !room_list_first
    STA !custom_menu_cursor
    RTS
    +
    LDA #menu_warp
    JMP set_menu_and_cursor
  .opt2_code:
    LDA #menu_mww_abilities
    JSR set_menu_and_cursor
    RTS
  .opt3_code:
    LDA #menu_rng
    JSR set_menu_and_cursor
    RTS
  .opt4_code:
    LDA #menu_colors
    JSR set_menu_and_cursor
    RTS
  .opt8_code:
    LDA #menu_sa1adjustment
    JSR set_menu_and_cursor
    RTS
  .about_code:
    LDA #menu_about
    JMP set_menu_and_cursor

menu_rng:
  dw text3_rng, $0008, menu_main
  db bank(text3)
  dw text3_rng_count, .count_code
  dw text3_rng_value, .value_code
  dw text3_rng_reset, .reset_code
  dw text3_rng_demo, .demo_code
  dw text3_rng_advance_1, .advance_1_code
  dw text3_rng_advance_10, .advance_10_code
  dw text3_rng_advance_100, .advance_100_code
  dw text3_back, back_one
  .reset_code:
    LDA #$BDDD
    JSR set_rng_to_a
    RTS
  .demo_code:
    LDA #$0000
    JSR set_rng_to_a
    RTS
  .advance_1_code:
    LDA.w #!rng_jump_1
    JSR advance_rng_steps_from_current
    RTS
  .advance_10_code:
    LDA.w #!rng_jump_10
    JSR advance_rng_steps_from_current
    RTS
  .advance_100_code:
    LDA.w #!rng_jump_100
    JSR advance_rng_steps_from_current
    RTS
  .count_code:
    JSR init_rng_count_editor
    LDA #menu_rng_count
    JSR set_menu_and_cursor
    RTS
  .value_code:
    ; the RNG shown on the title row (set in this menu, or the one when the menu was opened)
    LDA.l !custom_menu_apply_rng
    BEQ +
    LDA.l !store_RNG
    BRA ++
    +
    LDA.l !custom_menu_open_rng
    ++
    JSL rng_edit_init
    LDA #menu_rng_value
    JMP set_menu_and_cursor

; the value editor of ワープ らんすう, for the RNG of the game (げんざい らんすう)
menu_rng_value:
  dw text4_by_value, $0001, menu_rng
  db bank(text4)
  dw text4_ok, .apply_code
  .apply_code:
    JSL rng_edit_value
    BCS +
    JSR set_rng_to_a
    LDA #menu_rng
    JMP set_menu_and_cursor
    +
    SEP #$20
    LDA #!sfx_back
    STA !current_sfx_long
    REP #$20
    RTS

menu_rng_count:
  dw text3_rng_count_title, $0001, menu_rng
  db bank(text3)
  dw text3_rng_apply_count, .apply_code
  .apply_code:
    JSR apply_rng_count
    RTS

menu_warp:
  dw text5_warp, $0005, menu_main
  db bank(text5)
  dw text5_gco, .gco_code
  dw text5_dyna, .dyna_code
  dw text5_romk, .romk_code
  dw text5_mww, .mww_code
  dw text5_back, back_one
  .gco_code:
    LDA #menu_seg_gco
    JMP set_menu_and_cursor
  .dyna_code:
    LDA #menu_seg_dyna
    JMP set_menu_and_cursor
  .romk_code:
    LDA #menu_seg_romk
    JMP set_menu_and_cursor
  .mww_code:
    LDA #menu_seg_mww
    JMP set_menu_and_cursor

; segment lists: Left / Right choose the room (shown next to the segment, draw_warp_settings),
; A warps there with the Warp Settings, Y without (2026-10-15, a room list for each segment before)
menu_seg_gco:
  dw text5_gco, $0004, menu_warp
  db bank(text5)
  dw text5_cave_1, room_menu_pick
  dw text5_cave_2, room_menu_pick
  dw text5_cave_3, room_menu_pick
  dw text5_back, back_one

menu_seg_dyna:
  dw text5_dyna, $0006, menu_warp
  db bank(text5)
  dw text5_dyna_1, room_menu_pick
  dw text5_dyna_2, room_menu_pick
  dw text5_dyna_3, room_menu_pick
  dw text5_dyna_4, room_menu_pick
  dw text5_dyna_5, room_menu_pick
  dw text5_back, back_one

menu_seg_romk:
  dw text5_romk, $0008, menu_warp
  db bank(text5)
  dw text5_romk_1, room_menu_pick
  dw text5_romk_2, room_menu_pick
  dw text5_romk_3, room_menu_pick
  dw text5_romk_4, room_menu_pick
  dw text5_romk_5, room_menu_pick
  dw text5_romk_6, room_menu_pick
  dw text5_romk_7, room_menu_pick
  dw text5_back, back_one

menu_seg_mww:
  dw text5_mww, $0009, menu_warp
  db bank(text5)
  dw text5_mww_1, room_menu_pick
  dw text5_mww_2, room_menu_pick
  dw text5_mww_3, room_menu_pick
  dw text5_mww_4, room_menu_pick
  dw text5_mww_5, room_menu_pick
  dw text5_mww_6, room_menu_pick
  dw text5_mww_7, room_menu_pick
  dw text5_mww_8, room_menu_pick
  dw text5_back, back_one

room_menu_pick:
  LDA !p1controller_frame
  AND #!btn_y
  BEQ +
  LDA #$0000
  BRA ++
  +
  LDA #$0001
  ++
  STA.l !warp_apply_settings
  LDA #$0001
  STA.l !room_last_valid
  JSL room_pick_room
  JSL room_warp
  RTS

; -- Warp Settings (ワープ のうりょく / ワープ らんすう on the main menu); the values are drawn by
; draw_warp_settings
menu_warp_ability:
  dw text4_warp_ability, $0007, menu_main
  db bank(text4)
  dw text4_dont_set, .set_code
  dw text4_ab_00, .set_code
  dw text4_ab_07, .set_code
  dw text4_hammer_wheelie, .set_code
  dw text4_ab_0C, .set_code
  dw text4_custom, .custom_code
  dw text4_back, back_one
  .set_code:
    LDA !custom_menu_cursor
    STA.l !warp_ability_preset
    LDA #$0001
    JMP main_menu_at
  .custom_code:
    LDA #menu_warp_custom
    JMP set_menu_and_cursor

; Left / Right change the value of the line (update_warp_custom), A takes them
menu_warp_custom:
  dw text4_custom, $0004, menu_warp_ability
  db bank(text4)
  dw text4_kirby, .ok_code
  dw text4_helper, .ok_code
  dw text4_ride, .ok_code
  dw text4_ok, .ok_code
  .ok_code:
    LDA #$0005
    STA.l !warp_ability_preset
    LDA #$0001
    JMP main_menu_at

update_warp_custom:
  LDA !p1controller_frame
  AND #!btn_left|!btn_right
  BNE +
  JMP update_cursor_normal
  +
  JSL warp_custom_change
  RTS

menu_warp_rng:
  dw text4_warp_rng, $0007, menu_main
  db bank(text4)
  dw text4_dont_set, .set_code
  dw text4_rng_reset, .set_code
  dw text4_rng_whale, .set_code
  dw text4_rng_crash, .set_code
  dw text4_by_value, .custom_code
  dw text4_by_count, .count_code
  dw text4_back, back_one
  .set_code:
    LDA !custom_menu_cursor
    STA.l !warp_rng_preset
    LDA #$0002
    JMP main_menu_at
  .custom_code:
    LDA.l !warp_custom_rng
    JSL rng_edit_init
    LDA #menu_warp_rng_value
    JMP set_menu_and_cursor
  .count_code:
    JSR init_rng_count_editor
    LDA #menu_warp_rng_count
    JMP set_menu_and_cursor

; the count editor of げんざい らんすう, for the warp RNG (the RNG of the game stays as it is)
menu_warp_rng_count:
  dw text4_by_count, $0001, menu_warp_rng
  db bank(text4)
  dw text4_ok, .apply_code
  .apply_code:
    LDA.l !store_RNG
    PHA
    LDA.l !custom_menu_apply_rng
    PHA
    JSR rng_count_compute
    LDA.l !store_RNG
    STA.l !warp_custom_rng
    PLA
    STA.l !custom_menu_apply_rng
    PLA
    STA.l !store_RNG
    LDA #$0004
    STA.l !warp_rng_preset
    LDA #$0002
    JMP main_menu_at

; value editor: Up/Down change the digit, Left/Right pick it (update_rng_value_editor)
menu_warp_rng_value:
  dw text4_by_value, $0001, menu_warp_rng
  db bank(text4)
  dw text4_ok, warp_rng_value_apply

; "OK": both numbers have to be 0-255
warp_rng_value_apply:
  JSL rng_edit_value
  BCS .invalid
  STA.l !warp_custom_rng
  LDA #$0004
  STA.l !warp_rng_preset
  LDA #$0002
  JMP main_menu_at
  .invalid:
    SEP #$20
    LDA #!sfx_back
    STA !current_sfx_long
    REP #$20
    RTS

menu_mww_abilities:
  dw text_mww_abilities, $0005, menu_main
  db bank(text)
  dw text_mww_abilities_opt1, .setmwwability_code
  dw text_mww_abilities_opt2, .setmwwability_code
  dw text_mww_abilities_opt3, .setmwwability_code
  dw text_mww_abilities_opt4, .setmwwability_code
  dw text_back, back_one
  .setmwwability_code
    LDA !custom_menu_cursor
    STA !mww_ability_route

    SEP #$30
    LDA #!sfx_ability
    STA !current_sfx_long
    REP #$30

    LDA #menu_main
    JSR set_menu_and_cursor
    RTS

menu_colors:
  dw text_color, $000B, menu_main
  db bank(text)
  dw text_colors_opt1, .setcolor_code
  dw text_colors_opt2, .setcolor_code
  dw text_colors_opt3, .setcolor_code
  dw text_colors_opt4, .setcolor_code
  dw text_colors_opt5, .setcolor_code
  dw text_colors_opt6, .setcolor_code
  dw text_colors_opt7, .setcolor_code
  dw text_colors_opt8, .setcolor_code
  dw text_colors_opt9, .setcolor_code
  dw text_colors_opta, .setcolor_code
  dw text_back, back_to_main
  .setcolor_code:
    LDA !custom_menu_cursor
    STA !toggle_custom_colors

    SEP #$30
    LDA #!sfx_ability
    STA !current_sfx_long
    REP #$30

    LDA #menu_main
    JSR set_menu_and_cursor
    RTS

;menu_audio:   (2026-10-08: "オーディオ" on the main menu switches it with A)
;  dw text_audio, $0004, menu_main
;  db bank(text)
;  dw text_audio_opt1, .stereomono_code
;  dw text_audio_opt2, .stereomono_code
;  dw text_audio_opt3, .audiooff_code
;  dw text_back, back_one
;  .stereomono_code:
;    SEP #$20
;    LDA !custom_menu_cursor
;    JSR stereo_mono
;    LDA #menu_main
;    JSR set_menu_and_cursor
;    RTS
;  .audiooff_code:
;    SEP #$20
;    JSR turn_on_mute
;    LDA #menu_main
;    JSR set_menu_and_cursor
;    RTS

;menu_noflash:
;  dw text_noflash, $0003, menu_main
;  db bank(text)
;  dw text_on, .noflash_code
;  dw text_off, .noflash_code
;  dw text_back, back_one
;  .noflash_code:
;    LDA !custom_menu_cursor
;    STA !toggle_screen_flash
;    LDA #menu_main
;    JSR set_menu_and_cursor
;    RTS

menu_sa1adjustment:
  dw text3_sa1adjustment, $000C, menu_main
  db bank(text3)
  dw text3_off, .sa1_code
  dw text3_sa1adjustment_1, .sa1_code
  dw text3_sa1adjustment_2, .sa1_code
  dw text3_sa1adjustment_3, .sa1_code
  dw text3_sa1adjustment_4, .sa1_code
  dw text3_sa1adjustment_5, .sa1_code
  dw text3_sa1adjustment_6, .sa1_code
  dw text3_sa1adjustment_7, .sa1_code
  dw text3_sa1adjustment_8, .sa1_code
  dw text3_sa1adjustment_9, .sa1_code
  dw text3_sa1adjustment_A, .sa1_code
  dw text3_back, back_one
  .sa1_code
    LDA !custom_menu_cursor
    ASL
    STA !sa1_adjustment

    LDA #menu_main
    JSR set_menu_and_cursor
    RTS

; クレジット: the credits of the original practice hack (back 2026-10-26)
menu_about:
  dw text2_about_1, $000A, menu_main
  db bank(text2)
  dw text2_about_2, option_noop
  dw text2_about_3, .aero_sound
  dw text2_about_4, option_noop
  dw text2_about_5, .scout_sound
  dw text2_about_6, option_noop
  dw text2_about_7, option_noop
  dw text2_about_8, option_noop
  dw text2_about_9, option_noop
  dw text2_about_A, option_noop
  dw text2_about_B, option_noop
  .aero_sound:
    SEP #$30
    LDA #$54
    STA !current_sfx_long
    REP #$30
    RTS
  .scout_sound:
    SEP #$30
    LDA #$20
    STA !current_sfx_long
    REP #$30
    RTS
  ;.and_more:
  ;  SEP #$20
  ;  LDA #$2E
  ;  JSL !load_music
  ;  REP #$20
  ;  RTS

pushpc
org $29F780

text:
  .back: %text("Back", "もどる")

  .about: %text("Credits", "クレジット")
  .sa1adjustment:  %text("SA-1 Adjustment", "SA1")

  .autoboot: %text("Skip Title", "タイトル　とばす")

  .main:     %text("Main Menu", "メインメニュー")
  .warp_ability: %text("Warp Ability", "ワープ　のうりょく")
  .warp_rng: %text("Warp RNG", "ワープ　らんすう")
  .hud: %text("HUD", "HUD")
  .color:    %text("Kirby Color", "カービィ　いろ")
;  .language: %lang_swap_text("にほんご　メニュー", "English menu")

  .rng: %text("RNG Now", "げんざい　らんすう")

;  .spring:  %text("Spring Breeze", "はるかぜと ともに")
;  .gourmet: %text("Gourmet Race", "グルメ レース")




  .warp:    %text("Warp Menu", "ワープ　メニュー")

  .mww_abilities: %text("MWW Abilities", "ぎんが　のうりょく")
    ..opt1: %text("Use Save Data", "セーブ　とおり")
    ..opt2: %text("Any%", "ANY%")
    ..opt3: %text("Any% (Plasma)", "ANY% （プラズマ）")
    ..opt4: %en_jp_text("100%")

  .audio: %text("Audio", "オーディオ")
    ..opt1: %text("Stereo", "ステレオ")
    ..opt2: %text("Mono", "モノラル")
    ..opt3: %text("No Music", "おんがく　なし")

  .colors
    ..opt1:  %text("Default", "おまかせ　（スタンダード）")
    ..opt2:  %text("Pink (Always)", "ピンク　（いつも）")
    ..opt3:  %text("Red", "レッド")
    ..opt4:  %text("Yellow", "イエロー")
    ..opt5:  %text("Light blue", "ソーダ")
    ..opt6:  %text("Blue", "ブルー")
    ..opt7:  %text("Sapphire", "サファイア")
    ..opt8:  %text("Purple", "ラベンダー")
    ..opt9:  %text("Brown", "チョコレート")
    ..opta:  %text("Chalk", "モノトーン")
  
;  .noflash: %text("Boss Screen Flashing", "ボスを　たおすときの　てんめつ")

assert pc() <= $2A0000

org $02FC30

; the credits screen (menu_about)
text2:
  .about: 
    ..1: %text("Credits", "クレジット")
    ..2: %text("Lead Programmer", "チーフプログラマー")
    ..3: %en_jp_text("  Aero   🐾  aeropaws.dog")
    ..4: %text("Menu Programmer", "メニュープログラマー")
    ..5: %en_jp_different_text("  scout  🐇  bittybunny.com","  スカウト   🐇  bittybunny.com")
    ..6: %text("Thank You","スペシャルサンクス")
    ..7: %en_jp_text("  theJuice   GoldenEpsilon")
    ..8: %text("  Mikan      Yotta","  みかん        Yotta")
    ..9: %text("  zzzHonki   WaddleDX","  ぷーれ        まどら")
    ..A: %en_jp_text("  Ankou      RGMechEx   ")
    ..B: %en_jp_text("               and more...")

assert pc() <= $030000

;まどら
ORG $03F820 

text3:
  .back: %text("Back", "もどる")
  .off: %text("Off", "オフ")

  .rng: %text("RNG Now", "げんざい　らんすう")
    ..reset: %text("After Reset RNG", "らんすう　リセットあと")
    ..demo: %text("After Demo RNG", "らんすう　デモあと")
    ..advance_1: %text("Advance RNG x1", "らんすう　１かい　すすめる")
    ..advance_10: %text("Advance RNG x10", "らんすう　１０かい　すすめる")
    ..advance_100: %text("Advance RNG x100", "らんすう　１００かい　すすめる")
    ..count: %text("Set RNG Count", "カウントで　きめる")
    ..value: %text("Set RNG Value", "あたいで　きめる")
    ..count_title: %text("RNG Count", "RNGカウント")
    ..apply_count: %text("Apply Count", "カウントを　はんえい")

  .sa1adjustment: %text("SA-1 Adjustment", "SA1")
  ..1: %en_jp_text("+$0BC0")
  ..2: %en_jp_text("+$0E10")
  ..3: %en_jp_text("+$1060")
  ..4: %en_jp_text("+$12B0")
  ..5: %en_jp_text("+$1500")
  ..6: %en_jp_text("+$1750")
  ..7: %en_jp_text("+$19A0")
  ..8: %en_jp_text("+$1BF0")
  ..9: %en_jp_text("+$1E40")
  ..A: %en_jp_text("+$2090")


; menu drawing (needs bank(draw_screen) for !sa1_executesnes)
incsrc "menu_draw.asm"

print "bank03 end: ", pc
assert pc() <= $040000

; segment practice texts (free space at the end of bank $07)
org $07F8B0

text4:
  .back: %text("Back", "もどる")
  .warp_ability: %text("Warp Ability", "ワープ　のうりょく")
  .warp_rng: %text("Warp RNG", "ワープ　らんすう")
  .stereo: %text("Stereo", "ステレオ")
  .mono: %text("Mono", "モノラル")
  .hud_timer: %text("Timer", "タイマー")
  .hud_rng: %text("RNG", "らんすう")
  .hud_lag: %text("Lag", "しょりおち")
  .hud_detail: %text("Detail", "しょうさい")
  .dont_set: %text("Don't Set", "セットしない")
  .hammer_wheelie: %text("Hammer + Wheelie", "ハンマーと　ウィリー")
  .custom: %text("Custom", "じぶんで　きめる")
  .by_value: %text("By Value", "あたいで　きめる")
  .by_count: %text("By Count", "カウントで　きめる")
  .kirby: %text("Kirby", "カービィ")
  .helper: %text("Helper", "ヘルパー")
  .ride: %text("Ride Wheelie", "ウィリーに　のる")
  .ok: %text("OK", "けってい")
  .none: %text("None", "なし")
  .rng_reset: %text("221 189 Reset", "２２１　１８９　リセットあと")
  .rng_whale: %text("118 013 Whale", "１１８　０１３　クジラあと")
  .rng_crash: %text("031 005 Crash", "０３１　００５　クラッシュあと")
  .on: %text("On", "オン")
  .off: %text("Off", "オフ")
  .ab_00: %text("Normal", "すっぴん")
  .ab_01: %text("Cutter", "カッター")
  .ab_02: %text("Beam", "ビーム")
  .ab_03: %text("Yo-yo", "ヨーヨー")
  .ab_04: %text("Ninja", "ニンジャ")
  .ab_05: %text("Wing", "ウィング")
  .ab_06: %text("Fighter", "ファイター")
  .ab_07: %text("Jet", "ジェット")
  .ab_08: %text("Sword", "ソード")
  .ab_09: %text("Fire", "ファイア")
  .ab_0A: %text("Stone", "ストーン")
  .ab_0B: %text("Bomb", "ボム")
  .ab_0C: %text("Plasma", "プラズマ")
  .ab_0D: %text("Wheel", "ホイール")
  .ab_0E: %text("Ice", "アイス")
  .ab_0F: %text("Mirror", "ミラー")
  .ab_10: %text("Copy", "コピー")
  .ab_11: %text("Suplex", "スープレックス")
  .ab_12: %text("Hammer", "ハンマー")
  .ab_13: %text("Parasol", "パラソル")
  .ab_14: %text("Mike", "マイク")
  .ab_15: %text("Sleep", "スリープ")
  .ab_16: %text("Paint", "ペイント")
  .ab_17: %text("Cook", "コック")
  .ab_18: %text("Crash", "クラッシュ")
  .room_1: %text("Room 1", "へや　　１")
  .room_2: %text("Room 2", "へや　　２")
  .room_3: %text("Room 3", "へや　　３")
  .room_4: %text("Room 4", "へや　　４")
  .room_5: %text("Room 5", "へや　　５")
  .room_6: %text("Room 6", "へや　　６")
  .room_7: %text("Room 7", "へや　　７")
  .room_8: %text("Room 8", "へや　　８")
  .room_9: %text("Room 9", "へや　　９")
  .room_10: %text("Room 10", "へや　１０")
  .room_11: %text("Room 11", "へや　１１")
  .room_12: %text("Room 12", "へや　１２")
  .room_13: %text("Room 13", "へや　１３")

assert pc() <= $080000

; the Warp Menu and the segment lists (free space at the end of bank $13)
org $13F988

text5:
  .back: %text("Back", "もどる")
  .warp: %text("Warp Menu", "ワープ　メニュー")
  .dyna: %text("Dyna Blade", "ダィナブレィド")
  .gco: %text("Great Cave Offensive", "どうくつ だいさくせん")
  .romk: %text("Revenge of Meta Knight", "メタナイトの ぎゃくしゅう")
  .mww: %text("Milky Way Wishes", "ぎんがに ねがいを")
  .cave_1: %text("Cave 1", "どうくつ　１")
  .cave_2: %text("Cave 2", "どうくつ　２")
  .cave_3: %text("Cave 3", "どうくつ　３")
  .dyna_1: %text("Dyna Blade 1", "ダイナ　１")
  .dyna_2: %text("Dyna Blade 2", "ダイナ　２")
  .dyna_3: %text("Dyna Blade 3", "ダイナ　３")
  .dyna_4: %text("Dyna Blade 4", "ダイナ　４")
  .dyna_5: %text("Dyna Blade 5", "ダイナ　５")
  .romk_1: %text("Meta Knight 1", "メタナイト　１")
  .romk_2: %text("Meta Knight 2", "メタナイト　２")
  .romk_3: %text("Meta Knight 3", "メタナイト　３")
  .romk_4: %text("Meta Knight 4", "メタナイト　４")
  .romk_5: %text("Meta Knight 5", "メタナイト　５")
  .romk_6: %text("Meta Knight 6", "メタナイト　６")
  .romk_7: %text("Meta Knight 7", "メタナイト　７")
  .mww_1: %text("Milky Way 1", "ぎんが　１")
  .mww_2: %text("Milky Way 2", "ぎんが　２")
  .mww_3: %text("Milky Way 3", "ぎんが　３")
  .mww_4: %text("Milky Way 4", "ぎんが　４")
  .mww_5: %text("Milky Way 5", "ぎんが　５")
  .mww_6: %text("Milky Way 6", "ぎんが　６")
  .mww_7: %text("Milky Way 7", "ぎんが　７")
  .mww_8: %text("Milky Way 8", "ぎんが　８")

assert pc() <= $140000
pullpc
