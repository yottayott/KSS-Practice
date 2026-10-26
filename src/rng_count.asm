; The RNG count on the らんすう and しょうさい HUDs (2026-10-17, the user: for RNG manipulation
; research; always on since 2026-10-26, the main menu's "RNGカウント" is gone). The count: how many times the RNG advanced from 119 119
; ($7777, count 0; 221 189 after a reset is 1, 234 074 is 100, 65534 is 119 119 again). $5555
; and $AAAA are not on that cycle: no count ($FFFF).
;
; SA-1, at the end of its frame (sa1_wait_for_snes, before the HUDs draw it), only with one of
; these HUDs. The last value and its count are kept (!rng_cnt_val /
; !rng_cnt, always a pair that matches): most frames the RNG is the same, or a few steps on from
; it. Else (a menu, a state load, a warp) a search: step on from the value j = 0-255 times until
; the value of a count 256k (tables of tools/make_rng_count.py): the count is 256k - j. At most
; about 27000 SA-1 cycles (a sixth of a frame), and that only on those frames.

!rng_count_steps = $0040        ; the steps tried on from the last value before the search

incsrc "rng_count_tables.asm"

rng_count_sa1:
    LDA.l !hud_display_mode
    CMP #$0001
    BEQ +
    CMP #$0003
    BNE .rtl0
    +
    LDA.l !RNG_long
    CMP.l !rng_cnt_val
    BNE +
    .rtl0:
    RTL
    +
    STA.l !rng_cnt_target
    LDA.l !rng_cnt
    CMP #$FFFF                  ; (no count)
    BEQ .search
    ; a few steps on from the last value
    LDY.w #!rng_count_steps
    LDA.l !rng_cnt_val
    -
    JSR rng_count_step
    PHA
    LDA.l !rng_cnt
    INC A
    CMP.w #65534
    BCC +
    LDA #$0000
    +
    STA.l !rng_cnt
    PLA
    CMP.l !rng_cnt_target
    BEQ .found
    DEY
    BNE -
    .search:
    LDA.l !rng_cnt_target
    LDY #$0000                  ; j
    -
    PHA
    JSR rng_count_lookup
    BCS .giant
    PLA
    CMP.w #!rng_count_two
    BEQ .two
    JSR rng_count_step
    INY
    CPY #$0100
    BCC -
    LDA #$FFFF                  ; not on the cycle
    BRA .store
    .two:
    LDA #$0002                  ; the count 65536 = 2
    BRA +
    .giant:
    PLX
    +
    PHA                         ; - j
    TYA
    EOR #$FFFF
    SEC
    ADC $01,S
    PLX                         ; (keeps the carry)
    BCS .store
    ADC.w #65534                ; (carry clear)
    .store:
    STA.l !rng_cnt
    .found:
    LDA.l !rng_cnt_target
    STA.l !rng_cnt_val
    .rtl:
    RTL

; A = the next value of the RNG (one step). Uses X.
rng_count_step:
    PHA
    AND #$00FF
    ASL A
    TAX
    LDA.l rng_count_lo,X
    STA.l !rng_cnt_s
    PLA
    XBA
    AND #$00FF
    ASL A
    TAX
    LDA.l rng_count_hi,X
    EOR.l !rng_cnt_s
    RTS

; A = a value: carry set and A = 256k if it is the value of the count 256k (k = 0-255), else
; carry clear. Uses X.
rng_count_lookup:
    STA.l !rng_cnt_v
    XBA
    AND #$00FE                  ; the top 7 bits (x 2)
    TAX
    LDA.l rng_count_bucket,X
    TAX
    -
    LDA.l rng_count_giant,X     ; (sorted: on while smaller)
    CMP.l !rng_cnt_v
    BCS +
    INX
    INX
    INX
    BRA -
    +
    BNE .no
    CPX.w #256*3                ; (the end, $FFFF)
    BEQ .no
    LDA.l rng_count_giant+1,X   ; the high byte of the value, k
    AND #$FF00
    SEC
    RTS
    .no:
    CLC
    RTS

; A = the count (0-65533) -> A = the count / 100 (0-655), X = the rest (0-99): the HUDs draw
; them as 3 and 2 digits. Either CPU, 16-bit A/X/Y, uses Y.
rng_count_split:
    LDY #$0000
    -
    CMP.w #10000
    BCC +
    SBC.w #10000
    PHA
    TYA
    ADC.w #100-1                ; (carry set)
    TAY
    PLA
    BRA -
    +
    -
    CMP.w #1000
    BCC +
    SBC.w #1000
    PHA
    TYA
    ADC.w #10-1
    TAY
    PLA
    BRA -
    +
    -
    CMP.w #100
    BCC +
    SBC.w #100
    INY
    BRA -
    +
    TAX
    TYA
    RTL

if !detail_hud
; The しょうさい HUD (detail_hud.asm; DB = bank(!detail_buf), 16-bit A/X/Y). Here as bank $21 is
; full.
; detail_layout: the label "CNT" in row 2 under "RNG"
rng_count_layout:
    LDA #$FFFE                  ; (the count drawn: none, not one of its values)
    STA.w !detail_cache+2
    LDA.w #(!dt_cn)|((!dt_t)<<8)
    STA.w !detail_buf+$52
    RTL

; detail_values: the count under the RNG ("00100", "-----" without one) when it changed: carry
; set (the caller notes $57-$5B)
rng_count_detail:
    LDA.w !rng_cnt
    CMP.w !detail_cache+2
    BEQ .no
    STA.w !detail_cache+2
    CMP #$FFFF
    BNE +
    LDA.w #(!dt_minus)|((!dt_minus)<<8)
    STA.w !detail_buf+$57
    STA.w !detail_buf+$59
    STA.w !detail_buf+$5A
    SEC
    RTL
    +
    JSL rng_count_split         ; A = the count / 100, X = the rest
    PHX
    LDX #$0000
    -
    CMP #$0064
    BCC +
    SBC #$0064
    INX
    BRA -
    +
    PHA
    TXA                         ; the first digit
    CLC
    ADC.w #!dt
    SEP #$20
    STA.w !detail_buf+$57
    REP #$20
    PLA
    JSR .tiles
    STA.w !detail_buf+$58
    PLA
    JSR .tiles
    STA.w !detail_buf+$5A
    SEC
    RTL
    .no:
    CLC
    RTL

; A = 0-99 -> its 2 digits (the tiles, the high one in the low byte)
.tiles:
    TAX
    LDA.l detail_bcd,X
    AND #$00FF
    ASL A
    TAX
    LDA.l detail_hex,X
    RTS
endif
