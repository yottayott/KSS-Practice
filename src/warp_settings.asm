; Warp Settings: the parts of the menu that only change values (moved out of bank $19, which is
; full with the room lists). Called with JSL from menu.asm, 16-bit A/X/Y.

; menu_warp_custom: Left / Right on the line of the cursor (A = the buttons)
warp_custom_change:
  ; Y = +1 or -1
  LDY #$0001
  AND #!btn_left
  BEQ +
  LDY #$FFFF
  +
  LDA !custom_menu_cursor
  BEQ .ability
  CMP #$0001
  BEQ .helper
  CMP #$0002
  BEQ .rider
  RTL
  .ability:
    TYA
    CLC
    ADC.l !warp_custom_ability
    BPL +
    LDA #$0018
    +
    CMP #$0019
    BCC +
    LDA #$0000
    +
    STA.l !warp_custom_ability
    RTL
  .helper:
    TYA
    CLC
    ADC.l !warp_custom_helper
    BPL +
    LDA.w #!warp_helper_choice_count-1
    +
    CMP.w #!warp_helper_choice_count
    BCC +
    LDA #$0000
    +
    STA.l !warp_custom_helper
    RTL
  .rider:
    LDA.l !warp_custom_rider
    EOR #$0001
    STA.l !warp_custom_rider
    RTL

; the custom RNG to the digits of the editor
; A = the value
rng_edit_init:
  PHP
  REP #$30
  PHA
  AND #$00FF
  LDX #$0000
  JSR rng_number_to_digits
  PLA
  XBA
  AND #$00FF
  JSR rng_number_to_digits
  LDA #$0000
  STA.l !rng_edit_digit
  PLP
  RTL

; A = 0-255 -> 3 digits from X, X += 3
rng_number_to_digits:
  LDY #$0064
  JSR .digit
  LDY #$000A
  JSR .digit
  LDY #$0001
  .digit:
    ; digit = A / Y, A = A mod Y
    PHY
    LDY #$0000
    .sub:
    CMP $01,S
    BCC .done
    SBC $01,S
    INY
    BRA .sub
    .done:
    PHA
    TYA
    SEP #$20
    STA.l !rng_edit_digits,X
    REP #$20
    PLA
    PLY
    INX
    RTS

; 3 digits from X -> A, X += 3. Uses Y and !seg_temp.
rng_digits_to_number:
  LDA #$0000
  LDY #$0003
  .loop:
    ASL A
    STA.l !seg_temp         ; 2n
    ASL A
    ASL A
    CLC
    ADC.l !seg_temp         ; 10n
    STA.l !seg_temp
    LDA.l !rng_edit_digits,X
    AND #$00FF
    CLC
    ADC.l !seg_temp
    INX
    DEY
    BNE .loop
  RTS

; the digits of the editor -> A = RNG, carry set if a number is over 255
rng_edit_value:
  LDX #$0000
  JSR rng_digits_to_number
  CMP #$0100
  BCS .invalid
  PHA
  JSR rng_digits_to_number
  CMP #$0100
  BCS .invalid_pull
  XBA
  ORA $01,S
  STA $01,S
  PLA
  CLC
  RTL
  .invalid_pull:
    PLA
  .invalid:
    SEC
    RTL

update_rng_value_editor:
  LDA.l !rng_edit_digit
  TAX
  LDA !p1controller_frame
  CMP #!btn_up
  BEQ .up
  CMP #!btn_down
  BEQ .down
  CMP #!btn_left
  BEQ .left
  CMP #!btn_right
  BEQ .right
  RTL
  .up:
    SEP #$20
    LDA.l !rng_edit_digits,X
    INC A
    CMP #$0A
    BCC +
    LDA #$00
    +
    STA.l !rng_edit_digits,X
    REP #$20
    RTL
  .down:
    SEP #$20
    LDA.l !rng_edit_digits,X
    DEC A
    BPL +
    LDA #$09
    +
    STA.l !rng_edit_digits,X
    REP #$20
    RTL
  .left:
    DEX
    BPL +
    LDX #$0005
    +
    TXA
    STA.l !rng_edit_digit
    RTL
  .right:
    INX
    CPX #$0006
    BCC +
    LDX #$0000
    +
    TXA
    STA.l !rng_edit_digit
    RTL


; texts (bank text4) for the menu drawing (menu_draw.asm, bank $03 is full)
warp_preset_texts:
  dw text4_dont_set, text4_ab_00, text4_ab_07, text4_hammer_wheelie, text4_ab_0C, text4_custom

ability_name_texts:
  dw text4_ab_00, text4_ab_01, text4_ab_02, text4_ab_03, text4_ab_04, text4_ab_05, text4_ab_06
  dw text4_ab_07, text4_ab_08, text4_ab_09, text4_ab_0A, text4_ab_0B, text4_ab_0C, text4_ab_0D
  dw text4_ab_0E, text4_ab_0F, text4_ab_10, text4_ab_11, text4_ab_12, text4_ab_13, text4_ab_14
  dw text4_ab_15, text4_ab_16, text4_ab_17, text4_ab_18

room_name_texts:
  dw text4_room_1, text4_room_2, text4_room_3, text4_room_4, text4_room_5, text4_room_6
  dw text4_room_7, text4_room_8, text4_room_9, text4_room_10, text4_room_11, text4_room_12
  dw text4_room_13

; the segment lists (Warp Menu > sub-game): each segment shows a room (!room_pick) that
; Left / Right change, A / Y warp there (2026-10-15, the room lists before)

; A = menu -> carry set and A = its first segment if it is a segment list
seg_list_first:
  LDX #$0006
  -
  CMP.l room_list_set_seg_menus,X
  BEQ +
  DEX
  DEX
  BPL -
  CLC
  RTL
  +
  LDA.l room_list_set_seg_first,X
  SEC
  RTL

; L / R in a segment list (A = the buttons) -> carry set and A = the segment list of the previous
; / next sub-game (wraps), carry clear if not in a segment list
seg_list_page:
  STA.l !seg_temp
  LDA.l !custom_menu_pointer
  JSL seg_list_first                ; X = the sub-game * 2
  BCC .no
  LDA.l !seg_temp
  AND #!btn_l
  BEQ .next
  DEX
  DEX
  BPL .menu
  LDX #$0006
  BRA .menu
  .next:
  INX
  INX
  CPX #$0008
  BCC .menu
  LDX #$0000
  .menu:
  LDA.l room_list_set_seg_menus,X
  SEC
  .no:
  RTL

; the segment of the cursor -> X = segment, A = its number of rooms, carry clear if the cursor
; is on もどる (or not in a segment list)
seg_list_cursor:
  LDA.l !custom_menu_pointer
  JSL seg_list_first
  BCC .no
  CLC
  ADC.l !custom_menu_cursor
  TAX
  LDY #$0002                        ; MenuOffsets.ChoiceCount (menu.asm comes later)
  LDA.l !custom_menu_cursor
  INC A
  CMP [$41],Y                       ; [!dp_menu]
  BCS .no
  PHX
  TXA
  ASL A
  TAX
  LDA.l room_seg_first+2,X
  SEC
  SBC.l room_seg_first,X
  PLX
  SEC
  RTS
  .no:
    CLC
    RTS

; Left / Right in a segment list (A = the buttons): the room of the segment of the cursor
room_pick_change:
  STA.l !seg_temp
  JSR seg_list_cursor
  BCC .done
  TAY                               ; rooms
  LDA.l !seg_temp
  AND #!btn_left
  BEQ .right
  LDA.l !room_pick,X
  AND #$00FF
  BNE +
  TYA
  +
  DEC A
  BRA .store
  .right:
  LDA.l !room_pick,X
  AND #$00FF
  INC A
  STA.l !seg_temp
  TYA
  DEC A
  CMP.l !seg_temp
  LDA.l !seg_temp
  BCS .store                        ; room + 1 < rooms
  LDA #$0000
  .store:
  SEP #$20
  STA.l !room_pick,X
  REP #$20
  .done:
  RTL

if !pb
; Select in a segment list: the PB of the room shown next to the segment of the cursor is cleared
; (carry set; clear when the cursor is not on a segment)
room_pick_clear_pb:
  JSR seg_list_cursor
  BCC +
  TXA
  JSL pb_seg_clear
  SEC
  +
  RTL
endif

; A / Y in a segment list -> A = the room (room_table), it is the last segment for Warp Menu
room_pick_room:
  JSR seg_list_cursor
  TXA
  JSL room_list_set_seg             ; keeps A
  TAX
  LDA.l !room_pick,X
  AND #$00FF
  PHA
  TXA
  ASL A
  TAX
  PLA
  CLC
  ADC.l room_seg_first,X
  RTL

; A = segment: it becomes the last one (Warp Menu opens its segment list on it). Keeps A.
room_list_set_seg:
  STA.l !room_list_seg
  LDX #$0006
  -
  CMP.l .first,X
  BCS +
  DEX
  DEX
  BRA -
  +
  PHA
  LDA.l .first,X
  STA.l !room_list_first
  LDA.l .menus,X
  STA.l !room_list_menu
  PLA
  RTL
  .first:
    dw $0000, $0003, $0008, $000F
  .menus:
    dw menu_seg_gco, menu_seg_dyna, menu_seg_romk, menu_seg_mww
