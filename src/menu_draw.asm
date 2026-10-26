; Menu drawing, run on the SNES through !sa1_executesnes (draw_screen).
; Kept out of bank $19 to leave room for the menu structures there.

draw_screen:
  JSR clear_screen

  ; write header (not on long lists: their title goes there, see choice_row)
  JSR long_list
  BCS +
  LDA #menu_header
  STA !dp_scratch
  SEP #$20
  LDA #bank(menu_header)
  STA !dp_scratch+2
  REP #$20
  LDX #$0001
  LDY #$0001
  JSR draw_string
  +

  ; draw menu title
  LDY.w #MenuOffsets.Title
  LDA [!dp_menu], Y
  STA !dp_scratch
  SEP #$20
  LDY.w #MenuOffsets.TextBank
  LDA [!dp_menu], Y
  STA !dp_scratch+2
  REP #$20
  LDX #$0001
  LDY #$0003
  JSR long_list
  BCC +
  LDY #$0001
  +
  JSR draw_string

  JSR draw_rng_menu_value

  ; draw menu options
  ; X = iterator, Y = current text index
  LDX #$0000
  LDY.w #MenuOffsets.Choices[0].Text
  PHY
  .choice_print_loop
    PLY

    ; load text of current choice
    LDA [!dp_menu], Y
    PHX
    PHY
    PHA

    ; calculate display Y
    TXA
    JSR choice_row
    TAY

    ; display X is always 3
    LDX #$0003

    PLA
    STA !dp_scratch
    SEP #$20
    PHY
    LDY.w #MenuOffsets.TextBank
    LDA [!dp_menu], Y
    PLY
    STA !dp_scratch+2
    REP #$20
    JSR draw_string
    PLY
    PLX

    ; move Y to next offset
    TYA
    CLC
    ADC.w #sizeof(MenuOffsets.Choices)
    TAY

    ; increase loop counter
    INX

    PHY
    ; check for loop
    TXA
    LDY.w #MenuOffsets.ChoiceCount
    CMP [!dp_menu], Y
  BNE .choice_print_loop
  PLY

  JSR draw_rng_count_editor
  JSR draw_warp_settings

  ; draw cursor
  LDA !custom_menu_cursor
  JSR choice_row

  ; row * 64
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A

  ; second column
  CLC
  ADC #$0002

  ADC #!menu_mirror
  STA !dp_scratch
  ; set bank
  SEP #$20
  LDA.b #bank(!menu_mirror)
  STA !dp_scratch+2
  REP #$20

  LDA #!cursor_sprite
  STA [!dp_scratch]

  RTL

draw_rng_menu_value:
  REP #$30
  LDA !custom_menu_pointer
  CMP #menu_rng
  BEQ .draw
  CMP #menu_rng_count
  BNE .done
  .draw:

  ; Draw "RNG: xxx xxx" on the title row.
  LDA #$00A2
  STA.l !menu_mirror+$00E4
  LDA #$009E
  STA.l !menu_mirror+$00E6
  LDA #$0097
  STA.l !menu_mirror+$00E8
  LDA #$00EF
  STA.l !menu_mirror+$00EA
  LDA #$0000
  STA.l !menu_mirror+$00EC
  STA.l !menu_mirror+$00F4

  LDA.l !custom_menu_apply_rng
  BEQ .use_open_rng
  LDA.l !store_RNG
  BRA .draw_value
  .use_open_rng:
    LDA.l !custom_menu_open_rng
  .draw_value:
  STA.l !custom_menu_rng_temp

  AND #$00FF
  LDX #$00EE
  JSR draw_menu_triple_digit_integer

  LDA.l !custom_menu_rng_temp+1
  AND #$00FF
  LDX #$00F6
  JSR draw_menu_triple_digit_integer

  .done:
    RTS

draw_rng_count_editor:
  REP #$30
  LDA !custom_menu_pointer
  CMP #menu_rng_count
  BEQ .draw
  CMP #menu_warp_rng_count
  BEQ .draw
  RTS

  .draw:
  ; Draw "Count: 00000".
  LDA #$0093
  STA.l !menu_mirror+$0206
  LDA #$00BC
  STA.l !menu_mirror+$0208
  LDA #$00C0
  STA.l !menu_mirror+$020A
  LDA #$00F6
  STA.l !menu_mirror+$020C
  LDA #$00BF
  STA.l !menu_mirror+$020E
  LDA #$00EF
  STA.l !menu_mirror+$0210
  LDA #$0000
  STA.l !menu_mirror+$0212

  LDA.l !custom_menu_rng_count_digits
  AND #$00FF
  CLC
  ADC #$00D0
  STA.l !menu_mirror+$0214
  LDA.l !custom_menu_rng_count_digits+1
  AND #$00FF
  CLC
  ADC #$00D0
  STA.l !menu_mirror+$0216
  LDA.l !custom_menu_rng_count_digits+2
  AND #$00FF
  CLC
  ADC #$00D0
  STA.l !menu_mirror+$0218
  LDA.l !custom_menu_rng_count_digits+3
  AND #$00FF
  CLC
  ADC #$00D0
  STA.l !menu_mirror+$021A
  LDA.l !custom_menu_rng_count_digits+4
  AND #$00FF
  CLC
  ADC #$00D0
  STA.l !menu_mirror+$021C

  LDA #$0000
  STA.l !menu_mirror+$0254
  STA.l !menu_mirror+$0256
  STA.l !menu_mirror+$0258
  STA.l !menu_mirror+$025A
  STA.l !menu_mirror+$025C
  LDA.l !custom_menu_rng_count_digit
  AND #$00FF
  ASL A
  TAX
  LDA #$00ED
  STA.l !menu_mirror+$0254,X

  .done:
    RTS

draw_menu_triple_digit_integer:
  REP #$30
  LDY #$FFFF
  SEC
  .hundreds_loop:
    INY
    SBC #$0064
    BCS .hundreds_loop
  ADC #$0064
  PHA
  TYA
  CLC
  ADC #$00D0
  STA.l !menu_mirror,X
  PLA

  LDY #$FFFF
  SEC
  .tens_loop:
    INY
    SBC #$000A
    BCS .tens_loop
  ADC #$000A
  PHA
  TYA
  CLC
  ADC #$00D0
  STA.l !menu_mirror+2,X
  PLA
  CLC
  ADC #$00D0
  STA.l !menu_mirror+4,X
  RTS

; string addr (24-bit) in dp_scratch, x in X, y in Y
draw_string:
  CLC

  ; set banks
  PHY
  SEP #$20
  LDA.b #bank(!menu_mirror)
  STA !dp_scratch+5
  REP #$20
  PLY

  ; move up one tile if it's jp because tails are above
  LDA !custom_menu_language
  STA !dp_scratch+3
  ; calculate destination start addr
  INY
  TYA
  SBC !dp_scratch+3
  
  ; y * 64
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ; add X*2
  STX !dp_scratch+3
  ASL !dp_scratch+3
  ADC !dp_scratch+3
  ADC #!menu_mirror
  STA !dp_scratch+3

  ; load pointer to language string
  LDA !custom_menu_language
  ASL A
  TAY
  LDA [!dp_scratch], Y
  STA !dp_scratch

  LDX #$0001
  SEP #$20
  .loop:
  LDA #$00
  LDA [!dp_scratch]
  ; if the character is 00, skip writing
  CMP #$00
  BEQ .increment
  ; if the character is FF, stop
  CMP #$FF
  BEQ .done
  ; if the character is FE, move down a line and restore X pos
  CMP #$FE
  BNE +
    REP #$20
    LDA #$0040 ; line height
    ADC !dp_scratch+3
    STX !dp_scratch+3
    ASL !dp_scratch+3
    SBC !dp_scratch+3
    STA !dp_scratch+3
    SEP #$20
    BRA .increment
  +
  ; if the character is FD, move up a line
  ; (for drawing eng text in JP mode)
  CMP #$FD
  BNE +
    REP #$20
    LDA !dp_scratch+3
    SBC #$0040 ; line height
    STA !dp_scratch+3
    SEP #$20
    ; counteract below increments
    DEX
    DEC !dp_scratch+3
    DEC !dp_scratch+3
    BRA .increment
  +
  ; clear upper bytes
  REP #$20
  AND #$00FF
  ; write tile
  STA [!dp_scratch+3]
  SEP #$20
  .increment:
  REP #$20
  INC !dp_scratch
  INC !dp_scratch+3
  INC !dp_scratch+3
  INX
  SEP #$20
  BRA .loop

  .done:
  REP #$20
  RTS
  


clear_screen:
  LDA #$0000
  LDX #$800
  -
  STA !menu_mirror, X
  DEX
  DEX
  BNE -
  STA !menu_mirror, X
  
  RTS


; A = choice -> its screen row: every other line from row 5; lists of more than 12 choices
; (the room list of Cave 3 has 13 rooms) start at row 3, their title is on the header row
choice_row:
  ASL A
  CLC
  ADC #$0005
  JSR long_list
  BCC +
  DEC A
  DEC A
  +
  RTS

; carry set if the menu has more than 12 choices. Keeps A / X / Y.
long_list:
  PHA
  PHY
  LDY.w #MenuOffsets.ChoiceCount
  LDA [!dp_menu], Y
  CMP #$000D
  PLY
  PLA
  RTS

; -- Warp Settings screens (menu_warp_* in menu.asm)
!warp_value_x #= $000E+2*!menu_english ; values are drawn from x = 14 (16 in English: "Warp Ability")
!warp_mark = $00E4                  ; ★ next to the current choice

draw_warp_settings:
  REP #$30
  LDA !custom_menu_pointer
  CMP #menu_warp_rng_value
  BEQ +
  CMP #menu_rng_value
  BNE ++
  +
  JMP draw_rng_value_editor
  ++
  CMP #menu_main
  BEQ .main
  JSL seg_list_first
  BCC +
  JMP .segments
  +
  LDA !custom_menu_pointer
  CMP #menu_warp_custom
  BNE +
  JMP .custom
  +
  CMP #menu_warp_ability
  BNE +
  LDA.l !warp_ability_preset
  BRA .mark
  +
  CMP #menu_warp_rng
  BEQ +
  RTS
  +
  ; the custom RNG next to "じぶんで きめる" (choice 4)
  LDA #$0004
  JSR choice_row
  JSR row_offset
  CLC
  ADC.w #$0028                      ; x = 20
  TAX
  LDA.l !warp_custom_rng
  JSR draw_rng_pair
  LDA.l !warp_rng_preset
  .mark:
    JSR choice_row
    JSR row_offset
    CLC
    ADC.w #$0034                    ; x = 26
    TAX
    LDA.w #!warp_mark
    STA.l !menu_mirror,X
    RTS

  .main:
    BRA +
  .hud_mode_texts:                  ; HUD: タイマー / らんすう / しょりおち / しょうさい
    dw text4_hud_timer, text4_hud_rng, text4_hud_lag, text4_hud_detail
    +
    ; the values next to the main menu choices (rows: choice_row)
    ; ワープ のうりょく (choice 1): the name of the preset
    LDA.l !warp_ability_preset
    ASL A
    TAX
    LDA.l warp_preset_texts,X
    LDY #$0007
    JSR draw_value_text
    ; HUD (choice 4): タイマー / らんすう / しょりおち
    LDA.l !hud_display_mode
    ASL A
    TAX
    LDA.l .hud_mode_texts,X
    LDY #$000D
    JSR draw_value_text
    ; タイトル とばす (choice 5): オン / オフ
    LDA.l !autoboot_corkboard
    AND #$00FF
    BEQ +
    LDA.w #text4_on
    BRA ++
    +
    LDA.w #text4_off
    ++
    LDY #$000F
    JSR draw_value_text
    ; オーディオ (choice 8): ステレオ / モノラル / オフ
    LDA.l !mute_toggle_long
    AND #$00FF
    CMP #$0001
    BNE +
    LDA.w #text4_off
    BRA ++
    +
    LDA.l !stereo_mono_long
    AND #$00FF
    BEQ +
    LDA.w #text4_mono
    BRA ++
    +
    LDA.w #text4_stereo
    ++
    LDY #$0015
    JSR draw_value_text
    ; ワープ らんすう (choice 2): "セットしない" or the two numbers
    LDA.l !warp_rng_preset
    BNE +
    LDA.w #text4_dont_set
    LDY #$0009
    JMP draw_value_text
    +
    CMP #$0004
    BCC +
    LDA.l !warp_custom_rng
    BRA ++
    +
    ASL A
    TAX
    LDA.l warp_rng_presets,X
    ++
    LDX.w #9*64+!warp_value_x*2
    JMP draw_rng_pair

  .custom:
    LDA.l !warp_custom_ability
    ASL A
    TAX
    LDA.l ability_name_texts,X
    LDY #$0005
    JSR draw_value_text
    ; helper: "なし" or the name of its ability
    LDA.l !warp_custom_helper
    ASL A
    TAX
    LDA.l warp_helper_choices,X
    BPL +
    LDA.w #text4_none
    BRA ++
    +
    ASL A
    TAX
    LDA.l ability_name_texts,X
    ++
    LDY #$0007
    JSR draw_value_text
    LDA.l !warp_custom_rider
    BEQ +
    LDA.w #text4_on
    BRA ++
    +
    LDA.w #text4_off
    ++
    LDY #$0009
    JMP draw_value_text

  .segments:
    ; the room chosen for each segment (A = the first segment of the list), not on もどる
    PHA
    LDA #$0000
    -
      PHA
      JSR choice_row
      TAY
      LDA $01,S
      CLC
      ADC $03,S
      TAX
      if !pb
      PHY
      PHX
      endif
      LDA.l !room_pick,X
      AND #$00FF
      ASL A
      TAX
      LDA.l room_name_texts,X
      JSR draw_value_text
      if !pb
      PLA
      PLY
      JSR draw_seg_pb
      endif
      PLA
      INC A
      INC A
      LDY.w #MenuOffsets.ChoiceCount
      CMP [!dp_menu],Y
      DEC A
      BCC -
    PLA
    RTS

if !pb
; the PB of the room shown next to a segment (A = segment, Y = row): "SSS.cc" at x = 21 (24 in
; English: the room names are drawn from x = 16, !warp_value_x), nothing without one (pb.asm)
draw_seg_pb:
  JSL pb_seg_value
  CMP #$FFFF
  BEQ .rts
  PHA
  TYA
  JSR row_offset
  CLC
  ADC.w #(21+3*!menu_english)*2
  TAX
  PLA
  LDY #$0000
  -
    CMP #$0064
    BCC +
    SBC #$0064
    INY
    BRA -
  +
  PHA
  TYA
  JSR draw_menu_triple_digit_integer
  LDA.l !menu_mirror,X              ; no leading zeros
  CMP #$00D0
  BNE +
  LDA #$0000
  STA.l !menu_mirror,X
  LDA.l !menu_mirror+2,X
  CMP #$00D0
  BNE +
  LDA #$0000
  STA.l !menu_mirror+2,X
  +
  LDA #$00B6                        ; "."
  STA.l !menu_mirror+6,X
  PLA
  LDY #$0000
  -
    CMP #$000A
    BCC +
    SBC #$000A
    INY
    BRA -
  +
  CLC
  ADC #$00D0
  STA.l !menu_mirror+10,X
  TYA
  CLC
  ADC #$00D0
  STA.l !menu_mirror+8,X
  .rts:
  RTS
endif

; A = row -> A = its offset in the menu mirror
row_offset:
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  RTS

; A = text (bank text4), Y = row: drawn at x = 14
draw_value_text:
  STA !dp_scratch
  SEP #$20
  LDA.b #bank(text4)
  STA !dp_scratch+2
  REP #$20
  LDX.w #!warp_value_x
  JMP draw_string

; A = RNG, X = mirror offset: "xxx xxx" (low byte first, as on the HUD)
draw_rng_pair:
  PHA
  AND #$00FF
  JSR draw_menu_triple_digit_integer
  TXA
  CLC
  ADC #$0008
  TAX
  PLA
  XBA
  AND #$00FF
  JMP draw_menu_triple_digit_integer

; the value editor: "RNG: xxx xxx" on row 8, a mark below the selected digit
draw_rng_value_editor:
  LDA #$00A2
  STA.l !menu_mirror+$0206
  LDA #$009E
  STA.l !menu_mirror+$0208
  LDA #$0097
  STA.l !menu_mirror+$020A
  LDA #$00EF
  STA.l !menu_mirror+$020C
  LDY #$0000
  .digit:
    TYX
    LDA.l !rng_edit_digits,X
    AND #$00FF
    CLC
    ADC #$00D0
    PHA
    TYA
    ASL A
    TAX
    LDA.l .columns,X
    TAX
    PLA
    STA.l !menu_mirror,X
    TYA
    CMP.l !rng_edit_digit
    BNE +
    LDA #$00ED
    STA.l !menu_mirror+$0040,X
    +
    INY
    CPY #$0006
    BNE .digit
  RTS
  .columns:
    dw $0210, $0212, $0214, $0218, $021A, $021C
