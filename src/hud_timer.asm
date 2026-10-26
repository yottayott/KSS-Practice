; The timer / RNG / lag frames in the HUD: 7 tiles with the game's digits ($B6-$BF), "M SS cc",
; "xxx xxx" or "  nnn  ". In Cave, Dyna Blade, Meta Knight and Milky Way always at the same place
; of the sub-game, whether there is a helper or a boss (the user, 2026-10-09): Cave row 5 from
; column 3, Dyna Blade row 4 column 7, Meta Knight row 4 column 6, Milky Way row 4 column 2; the
; lives slot is left blank. The other sub-games: over the lives slot.
;
; Lag (2026-10-13, the user): the SA-1 asks the S-CPU to run the game's HUD routine and waits
; for it ($01A2A8 -> $008C6D), so everything done there is added to the game's frame. The digits
; used to be drawn there (about 4 lines a frame: 87 lag frames in 9 rooms of 900 frames in
; BizHawk, 76 with lag_baseline.sfc). Now:
; - SA-1, at the end of its frame while it waits for the NMI anyway (sa1_wait_for_snes,
;   hud_slot_sa1): the 7 tiles into !hud_tiles, and which of them changed. The timer only counts
;   in the NMI, so it is the same value as the HUD routine saw.
; - NMI (hud_slot_upload, segment.asm): the tiles that changed to VRAM (most frames the 2 of the
;   centiseconds).
; - S-CPU, in the game's HUD routine (hud_slot_cpu, instead of its lives counter at $01F8A8):
;   only when the game drew a new layout ($00B7 = $FFFF, set by $01F7D5) the position and the
;   blank lives slot; and when the game uploads its HUD buffer ($00AF) the 7 tiles into it.

hud_small_block:                ; HUD buffer offset of the first of the 7 tiles
    dw $00A3                    ; Cave: row 5, column 3 (the lives slot there)
    dw $0087                    ; Dyna Blade: row 4, column 7 (the lives slot with a helper)
    dw $0086                    ; Meta Knight: row 4, column 6 (the lives slot there)
    dw $0082                    ; Milky Way: row 4, column 2 (the lives slot in a boss fight)
hud_small_blank:                ; the blank between the digits
    dw !hud_blank_tile          ; Cave
    dw !hud_blank_tile          ; Dyna Blade
    dw $00F0                    ; Meta Knight: $FF is an unlit "8" there, $F0 is empty
    dw !hud_blank_tile          ; Milky Way
hud_lives_blank:                ; the blank tile of the lives slot: tile | palette << 8 (0: keep it)
    dw !hud_blank_tile          ; Cave
    dw !hud_blank_tile          ; Dyna Blade
    dw !hud_blank_tile          ; Meta Knight
    dw $0CED                    ; Milky Way: the dark blue background ($FF is a white bar there)
hud_slot_index:                 ; $32EA -> the sub-game of the tables ($FF: the lives slot)
    db $FF, $01, $FF, $00, $02, $03, $FF, $FF
if !pb
hud_pb_row:                     ; the room PB (pb.asm), "  SS cc" like the timer: the row above it
    dw -$0020                   ; Cave (row 4: below is the frame)
    dw $0020                    ; Dyna Blade, Meta Knight, Milky Way: the row below
    dw $0020
    dw $0020
endif

; The HUD upload at the end of the game's HUD routine (was LDA $00AF : BEQ $F7BD : ...): the same
; few cycles on the frames it uploads nothing (2026-10-16; a JSL every frame before).
pushpc
ORG $01F79F
    if !detail_hud
    LDA.l !hud_display_mode
    CMP #$0003
    BEQ .detail
    endif
    LDA $00AF
    BEQ .rts
    JSL hud_slot_hud_upload
    .rts:
    RTS
    if !detail_hud
    .detail:
    JSL detail_hud_upload
    RTS
    endif
    assert pc() <= $01F7BE
pullpc

pushpc
ORG $01F949                     ; the score routine ($01F938), when the score changed
    JSL hud_slot_score          ; was CPY #$000F : BCC $F961
    NOP
pullpc

; S-CPU, the game's HUD routine, instead of drawing the lives counter ($01F8A8, in its place:
; 2026-10-16, a JSL every frame before). X = the middle tile of the lives slot in the HUD buffer
; (bank $7E), 16-bit A/X/Y.
pushpc
ORG $01F8A8
    LDA $00B7                   ; (!hud_last_drawn) the game drew a new layout
    INC A
    BNE +
    JSL hud_slot_cpu
    +
    LDA #$0001                  ; the HUD is there: the SA-1 draws the tiles at the end of the frame
    STA.l !hud_slot_live
    RTS
    assert pc() <= $01F8DF
pullpc

hud_slot_cpu:
    JSR hud_slot_layout
    RTL

; S-CPU, the end of the game's HUD routine when it uploads its buffer ($00AF, $01F79F above;
; 16-bit A/X/Y): the game's code that was here (upload the HUD buffer, if the transfer budget
; allows), with the 7 tiles put into the buffer first. Not before: the game asks for the upload
; ($00AF) after its lives counter in some scenes (2026-10-13: the start of Meta Knight, every
; frame, showed the time of the room before).
hud_slot_hud_upload:
    LDA.l $003019
    CLC
    ADC #$0226
    CMP.l $00301B
    BCS .rtl
    LDA.l !hud_slot_live        ; (the slot is set up in this scene)
    BEQ +
    LDA.l !hud_slot_addr
    TAX
    LDA.l !hud_tiles
    STA.l $7E0000,X
    LDA.l !hud_tiles+2
    STA.l $7E0002,X
    LDA.l !hud_tiles+4
    STA.l $7E0004,X
    SEP #$20
    LDA.l !hud_tiles+6
    STA.l $7E0006,X
    REP #$20
    +
    if !pb
    ; the PB row, after it changed or a new layout (not on every upload: Meta Knight uploads every
    ; frame in some rooms)
    LDA.l !hud_pb_buf
    BEQ +
    LDA #$0000
    STA.l !hud_pb_buf
    LDA.l !hud_pb_addr
    BEQ +
    TAX
    LDA.l !hud_pb_tiles
    STA.l $7E0000,X
    LDA.l !hud_pb_tiles+2
    STA.l $7E0002,X
    LDA.l !hud_pb_tiles+4
    STA.l $7E0004,X
    SEP #$20
    LDA.l !hud_pb_tiles+6
    STA.l $7E0006,X
    REP #$20
    +
    endif
    LDA #$0000
    STA.l $0000AF
    LDX #$0001
    LDA #$F7BE
    JSL $0086E5
    .rtl:
    RTL

; A new layout. X = the lives slot (its middle tile), 16-bit A/X/Y.
hud_slot_layout:
    LDA #$0000                  ; (not $FFFF any more)
    STA.l !hud_last_drawn
    LDA #$0001                  ; all 7 tiles to VRAM
    STA.l !hud_slot_force
    JSR hud_slot_get_sub
    BCS +
    ; the other sub-games: over the lives slot (no PB row)
    if !pb
    LDA #$0000
    STA.l !hud_pb_addr
    endif
    TXA
    SEC
    SBC #$0003
    STA.l !hud_slot_addr
    LDA.w #!hud_blank_tile
    STA.l !hud_slot_blank
    JMP .vram
    +
    PHX
    ASL
    TAX
    LDA.l hud_small_blank,X
    STA.l !hud_slot_blank
    LDA.l hud_small_block,X
    CLC
    ADC #$1617
    STA.l !hud_slot_addr
    if !pb
    ; the PB row next to it (the RNG count of the らんすう HUD is there too, rng_count.asm)
    LDA.l hud_pb_row,X
    CLC
    ADC.l !hud_slot_addr
    STA.l !hud_pb_addr
    LDA #$0001                  ; its tiles into the buffer at the upload
    STA.l !hud_pb_buf
    endif
    LDA.l hud_lives_blank,X     ; tile | palette << 8 (0: keep)
    STA.l !hud_tmp
    PLX
    ; the palette of the digits: as in the lives slot
    LDA.l $7E0000+$E0,X
    STA.l !hud_tmp2
    ; the lives slot (7 tiles) blank: its digits are not drawn any more
    SEP #$20
    LDY #$0007
    -
    LDA.l !hud_tmp
    STA.l $7E0000-3,X
    LDA.l !hud_tmp+1
    BEQ +
    STA.l $7E0000-3+$E0,X
    +
    INX
    DEY
    BNE -
    ; Milky Way: the ends of the score ("SC:" and the last digit) on both sides of the digits
    REP #$20
    LDA.l !hud_tmp
    CMP #$0CED
    BNE ++
    SEP #$20
    LDX #$0081                  ; row 4, column 1
    JSR .score_end
    LDX #$0089                  ; row 4, column 9
    JSR .score_end
    LDX #$008A                  ; row 4, column 10
    JSR .score_end
    ++
    ; palette / priority of the digits
    REP #$20
    LDA.l !hud_slot_addr
    TAX
    SEP #$20
    LDY #$0007
    LDA.l !hud_tmp2
    -
    STA.l $7E0000+$E0,X
    INX
    DEY
    BNE -
    if !pb
    REP #$20                    ; the PB row: the same
    LDA.l !hud_pb_addr
    BEQ ++
    TAX
    SEP #$20
    LDY #$0007
    LDA.l !hud_tmp2
    -
    STA.l $7E0000+$E0,X
    INX
    DEY
    BNE -
    ++
    SEP #$20
    endif
    LDA #$01                    ; the game sends the whole HUD to VRAM (as when it draws a layout)
    STA.l !write_to_HUD_long
    REP #$20
    .vram:
    LDA.l !hud_slot_addr        ; HUD tile numbers: the low bytes of VRAM $5800 + offset
    SEC
    SBC #$1617-$5800
    STA.l !hud_slot_vram
    if !pb
    LDA.l !hud_pb_addr
    SEC
    SBC #$1617-$5800
    STA.l !hud_pb_vram
    endif
    RTS

; X = a tile of the HUD (offset), 8-bit A: a digit, "SC" ($CE, $CF) or the white bar ($FF, its
; end $EF) -> the background
.score_end:
    LDA.l $7E1617,X
    CMP #$CE
    BEQ ++
    CMP #$CF
    BEQ ++
    CMP #$EF
    BEQ ++
    CMP #$FF
    BEQ ++
    CMP #$B6
    BCC +
    CMP #$C0
    BCS +
    ++
    LDA #$ED
    STA.l $7E1617,X
    LDA #$0C
    STA.l $7E1617+$E0,X
    +
    RTS

; The score routine ($01F938) when the score changed (A / Y = the score), instead of
; CPY #$000F : BCC $F961. In Milky Way the score is under the digits: never draw it (return as
; the routine does when the score did not change, $01F948). 2026-10-13: here and not at its
; start, which every frame went through (about 0.2 lines of the HUD routine the SA-1 waits for).
hud_slot_score:
    PHA
    LDA.l !subgame
    AND #$00FF
    CMP #$0005
    BEQ .mww
    PLA
    CPY #$000F
    BCC +
    RTL                         ; on at $01F94E (BNE with these flags)
    +
    PHA
    LDA #$F960                  ; on at $01F961
    BRA .return
    .mww:
    LDA #$F947                  ; on at $01F948 (RTS)
    .return:
    STA $03,S                   ; the return address (RTL adds 1)
    PLA
    RTL

; A = the sub-game of the tables (0 Cave, 1 Dyna Blade, 2 Meta Knight, 3 Milky Way), carry set;
; carry clear for the other sub-games. 16-bit A, keeps X / Y.
hud_slot_get_sub:
    PHX
    LDA.l !subgame
    AND #$00FF
    CMP #$0008
    BCS +
    TAX
    LDA.l hud_slot_index,X
    AND #$00FF
    CMP #$0004
    BCS +
    PLX
    SEC
    RTS
    +
    PLX
    CLC
    RTS

; SA-1, at the end of its frame (sa1_wait_for_snes, qsql.asm; 16-bit A/X/Y): the 7 tiles, when
; the game's HUD routine ran this frame. The NMI writes the ones that changed.
hud_slot_sa1:
    LDA.l !hud_slot_live
    BEQ +
    if !detail_hud
    LDA.l !hud_display_mode     ; the しょうさい HUD draws all of it (detail_hud.asm)
    CMP #$0003
    BNE ++
    LDA #$0000
    STA.l !hud_slot_live
    +
    RTL
    ++
    else
    BRA ++
    +
    RTL
    ++
    endif
    PHB
    PEA.w ((bank(!hud_tiles)<<8)|bank(!hud_tiles))+0
    PLB
    PLB
    STZ.w !hud_slot_live
    ; the NMI must not write while they change; not written yet: all of them again
    LDA.w !hud_slot_dirty
    STZ.w !hud_slot_dirty
    ORA.w !hud_slot_force
    STA.w !hud_slot_force
    LDA #$0007                  ; the first (low byte) and the last (high byte) tile that changed
    STA.w !hud_tmp
    LDY #$0000
    LDA.w !hud_display_mode
    BEQ .timer
    CMP #$0002
    BNE .rng
    ; lag frames of the room: "  nnn  "
    JSR .blank
    JSR .blank
    LDA.w !lag_count            ; (the one kept at a door while the time is)
    LDX.w !seg_split_hold
    BEQ +
    LDA.w !lag_shown
    +
    JSR .dec3
    JSR .blank
    JSR .blank
    BRA .done
    .rng:
    ; RNG: "xxx xxx", the low byte first (as in the menus)
    LDA.l !RNG_long
    AND #$00FF
    JSR .dec3
    JSR .blank
    LDA.l !RNG_long+1
    AND #$00FF
    JSR .dec3
    BRA .done
    .timer:
    ; "  SS cc", the seconds up to 99.99 (no minutes since 2026-10-15, the user; "M SS cc" before):
    ; the time kept at a door while it is shown, else the running time
    LDX #$0000
    LDA.w !seg_split_hold
    BEQ +
    LDX #$0008
    +
    LDA.w !seg_timer_cs,X
    PHA
    LDA.w !seg_timer_sec,X
    PHA
    LDA.w !seg_timer_min,X
    TAX
    PLA
    CPX #$0000
    BEQ +
    -
    CLC
    ADC #$003C
    DEX
    BNE -
    +
    CMP #$0064
    BCC +
    LDA #$0063                  ; (100 seconds or more: 99 99)
    STA $01,S
    +
    PHA
    JSR .blank
    JSR .blank
    PLA
    JSR .dec2
    JSR .blank
    PLA
    JSR .dec2

    .done:
    if !pb
    LDA.w !hud_slot_force       ; (the PB row is drawn again too)
    PHA
    endif
    LDA.w !hud_slot_force
    BEQ +
    STZ.w !hud_slot_force
    LDA #$0600
    STA.w !hud_tmp
    +
    SEP #$20
    LDA.w !hud_tmp+1
    SEC
    SBC.w !hud_tmp
    BCC +                       ; nothing changed
    INC A
    STA.w !hud_slot_count
    STZ.w !hud_slot_count+1
    LDA.w !hud_tmp
    STA.w !hud_slot_first
    STZ.w !hud_slot_first+1
    LDA #$01
    STA.w !hud_slot_dirty
    +
    REP #$20
    if !pb
    PLA
    JSR .pb_row
    endif
    PLB
    RTL

if !pb
; the PB row (A = !hud_slot_force): "  SS cc", blank without a PB; drawn when it changed, all 7
; tiles. DB = bank(!hud_tiles).
.pb_row:
    TAY
    LDA.w !hud_pb_addr
    BNE +
    .pb_rts0:
    RTS
    +
    ; the らんすう HUD: the RNG count there instead (rng_count.asm)
    LDA.w !hud_display_mode
    CMP #$0001
    BNE .pb_pb
    LDA.w !hud_pb_kind          ; (the PB was there: all of it again)
    BNE +
    INC A
    STA.w !hud_pb_kind
    TAY
    +
    LDA.w !rng_cnt
    CPY #$0000
    BNE +
    CMP.w !hud_pb_shown
    BEQ .pb_rts0
    +
    STA.w !hud_pb_shown
    LDY #$0000
    CMP #$FFFF                  ; (no count: blank)
    BEQ .pb_none
    JSL rng_count_split         ; "  nnnnn"
    PHX
    PHA
    LDY #$0000
    JSR .pb_blank
    JSR .pb_blank
    PLA
    JSR .pb_dec3
    PLA
    JSR .pb_dec2
    BRA .pb_mark
    .pb_pb:
    LDA.w !hud_pb_kind          ; (the RNG count was there: all of it again)
    BEQ +
    STZ.w !hud_pb_kind
    LDY #$0001
    +
    LDA #$FFFF                  ; (no PBs: the row is there for the RNG count)
    LDX.w !pb_ok
    BEQ +
    JSL pb_current              ; (pb.asm)
    +
    CPY #$0000
    BNE +
    CMP.w !hud_pb_shown
    BEQ .pb_rts
    +
    STA.w !hud_pb_shown
    LDY #$0000
    CMP #$FFFF
    BEQ .pb_none
    LDX #$0000
    -
    CMP #$0064
    BCC +
    SBC #$0064
    INX
    BRA -
    +
    CPX #$0064
    BCC +
    LDX #$0063                  ; (100 seconds or more: 99 99)
    LDA #$0063
    +
    PHA
    PHX
    JSR .pb_blank
    JSR .pb_blank
    PLA
    JSR .pb_dec2
    JSR .pb_blank
    PLA
    JSR .pb_dec2
    BRA .pb_mark
    .pb_none:
    JSR .pb_blank
    CPY #$0007
    BNE .pb_none
    .pb_mark:
    LDA #$0001                  ; into the game's buffer at its next upload, and to VRAM
    STA.w !hud_pb_buf
    LDA.w !hud_slot_dirty
    ORA #$0002
    STA.w !hud_slot_dirty
    .pb_rts:
    RTS
; A = 0-999
.pb_dec3:
    LDX #$0000
    -
    CMP #$0064
    BCC +
    SBC #$0064
    INX
    BRA -
    +
    PHA
    TXA
    JSR .pb_digit
    PLA
; A = 0-99
.pb_dec2:
    LDX #$0000
    -
    CMP #$000A
    BCC +
    SBC #$000A
    INX
    BRA -
    +
    PHA
    TXA
    JSR .pb_digit
    PLA
.pb_digit:
    CLC
    ADC.w #!hud_digit_tile
    BRA .pb_put
.pb_blank:
    LDA.w !hud_slot_blank
; A = the tile of column Y, Y + 1
.pb_put:
    SEP #$20
    STA.w !hud_pb_tiles,Y
    REP #$20
    INY
    RTS
endif

; A = 0-999: 3 digits. 16-bit A.
.dec3:
    LDX #$0000
    -
    CMP #$0064
    BCC +
    SBC #$0064
    INX
    BRA -
    +
    PHA
    TXA
    JSR .digit
    PLA
; A = 0-99: 2 digits
.dec2:
    LDX #$0000
    -
    CMP #$000A
    BCC +
    SBC #$000A
    INX
    BRA -
    +
    PHA
    TXA
    JSR .digit
    PLA
; A = 0-9
.digit:
    CLC
    ADC.w #!hud_digit_tile
    BRA .put
.blank:
    LDA.w !hud_slot_blank
; A = the tile of the next column (Y), Y + 1. Notes the columns that changed.
.put:
    SEP #$20
    CMP.w !hud_tiles,Y
    BEQ +
    STA.w !hud_tiles,Y
    TYA
    CMP.w !hud_tmp
    BCS ++
    STA.w !hud_tmp
    ++
    CMP.w !hud_tmp+1
    BCC +
    STA.w !hud_tmp+1
    +
    REP #$20
    INY
    RTS
