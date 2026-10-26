; called when the SA-1 starts

pushpc

org $00BBCC
  JSL init

; after the save files are checked ($00EEC9 / $00EE51): load file 1 for the corkboard (only when
; the game starts there, the main menu's タイトル とばす; the 100% file is made either way).
; init runs before that check, and with a new SRAM (snes9x fills it differently from BizHawk)
; the corkboard cursor read there was garbage and the corkboard hung (2026-10-07).
org $00BBE0
  JSL boot_load_file          ; was LDA $7F01 : AND #$00FF
  NOP #2

pullpc

boot_load_file:
  PHP
  REP #$30
  PHX
  PHY
  ; make file 1 a 100% file first (like Up + X on the file select, file_select.asm), keeping its
  ; corkboard cursor
  LDA $7F06
  AND #$00FF
  PHA
  LDX #$0000
  JSR make_100_file
  REP #$30
  PLA
  CMP #$00FF                  ; the file was empty: the first card
  BNE +
  LDA #$0000
  + SEP #$20
  STA $7F06
  REP #$30
  ; its checksum: the game's sum of the bytes $7F0A-$7F52 ($00EEA4, X = file), checked at power on
  ; (make_100_file writes a fixed one, wrong when the bytes it leaves differ)
  LDX #$0000
  JSL $00EEA4
  STA $7F04
  LDA.l !autoboot_corkboard
  AND #$00FF
  BEQ .title
  LDX #$0000
  LDY #$0000
  JSL $00EBE8
  REP #$30
  ; corkboard cursor
  LDA $7F06
  AND #$00FF
  CMP #$00FF
  BNE +
  LDA #$0000
  + STA $7A8F
  JSL $CAB827
  REP #$30
  .title:
  PLY
  PLX
  PLP
  LDA $7F01                   ; replaced code
  AND #$00FF
  RTL

; the RNG after a reset ($008C12, SA-1, 16-bit A): 221 189 ($BDDD) when the game starts on the
; corkboard (タイトル とばす on, as in a run, hex_edits.asm), else the game's 119 119 ($7777).
; (!autoboot_corkboard is made 0 / 1 later, in init: a value above 1 is the title screen there too)
reset_rng:
  LDA.l !autoboot_corkboard
  AND #$00FF
  CMP #$0001
  BEQ +
  LDA #$7777
  BRA ++
  +
  LDA #$BDDD
  ++
  STA $3743
  RTL

init:
  LDA #$0000
  STA !custom_menu_enabled
  STA !is_warping
  STA.l !custom_menu_apply_rng
  STA.l !custom_menu_open_rng
  STA.l !sa1_parked
  STA.l !sa1_resume

  ; start the segment timer, show it unless the RNG was chosen
  LDA #$0001
  STA.l !seg_timer_reset
  LDA.l !hud_display_mode
  CMP.w #3+!detail_hud              ; 3 = しょうさい, if that is on
  BCS ++
  BRA +
  ++
  LDA #$0000
  STA.l !hud_display_mode
  +

  if !pb
  JSL pb_boot_check                 ; the room PBs (pb.asm)
  endif

  ; the RNG count (rng_count.asm): nothing counted yet
  LDA #$5555                        ; (no count, as $5555 has)
  STA.l !rng_cnt_val
  LDA #$FFFF
  STA.l !rng_cnt
  LDA #$0000
  STA.l !hud_pb_kind

  ; the room loop is always off after power on
  LDA #$0000
  STA.l !room_loop_on
  STA.l !room_loop_request
  STA.l !hud_slot_dirty
  STA.l !hud_slot_live
  STA.l !hud_slot_force
  if !pb
  STA.l !hud_pb_addr
  STA.l !hud_pb_buf
  endif
  STA.l !seg_pending_rng_flag
  STA.l !seg_pending_rider
  STA.l !room_last_valid
  ; the room of each segment in the segment lists: the first
  PHP
  REP #$10
  PHX
  LDX #$0016
  -
  STA.l !room_pick,X
  DEX
  DEX
  BPL -
  PLX
  PLP
  ; !rewarp_room / !rewarp_valid (Select + X) are kept after power off (2026-10-10)

  ; Warp Settings: load the defaults on the first boot
  LDA.l !warp_settings_magic
  CMP #!warp_settings_magic_value
  BEQ +
  JSL warp_settings_defaults
  +

  ; set custom colors to zero if they are in an invalid range
  LDA !toggle_custom_colors
  CMP #$000A
  BCC +
  LDA #$0000
  STA !toggle_custom_colors
  +

  ; set mww ability route to Any% if it is in an invalid range (first boot)
  SEP #$20
  LDA !mww_ability_route
  CMP #$04
  BCC +
  LDA #$01
  STA !mww_ability_route
  + 
  REP #$20

  ; set sa-1 adjustment to zero if it is in an invalid range
  LDA !sa1_adjustment
  CMP #$0015    ; menu stores 0-$14 (the last option used to get reset on boot)
  BCC +
  LDA #$0000
  STA !sa1_adjustment
  +

  ; decide whether to boot into original title screen or corkboard (the main menu's
  ; タイトル とばす, as in the original hack; file 1 is loaded by boot_load_file, after the game
  ; has checked the save files)
  SEP #$30
  LDA !autoboot_corkboard
  ; check if it is above 2 (most likely on first boot)
  CMP #$02
  BCC +
  LDA #$00
  STA !autoboot_corkboard
  +
  STA !game_mode

;  ; load in file 1 save data if we're autobooting to corkboard
;  BEQ .skip_save_load
;  LDX #$00
;  LDY #$00
;  JSL $00EBE8

;  ; load corkboard cursor
;  LDA $7F06
;  AND #$00FF
;  CMP #$00FF
;  BNE +
;  LDA #$0000
;  + STA $7A8F

;  JSL $CAB827

;  .skip_save_load:
  
  REP #$30

  ; code which was replaced
  JSL $0084BE

  ; return
  RTL
