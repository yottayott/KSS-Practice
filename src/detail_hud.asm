; The しょうさい HUD (the 4th choice of the main menu's HUD, !hud_display_mode = 3; 2026-10-12, the
; user: the timer, the RNG, HP, Kirby's position with the subpixels and his speed, and the HUD
; may look completely different in this mode, the landmarks of the boss gauges included).
;
;   row 0  - - - - - - - - - - - - - - - -  (dotted line)
;   row 1  ####  TIME 0:12.34    RNG 221 189
;   row 2  ####  PB   0:11.98    CNT  00100  (the room PB, pb.asm; the RNG count, rng_count.asm,
;                                           with RNGカウント on)
;   row 3  ####  X 01A3.80  VX +02.87
;   row 4  ####  Y 00F0.00  VY -07.00
;   row 5  ####  LAG 12                BOSS 120
;   (#: Kirby's ability portrait, the game's tiles)
;
; X / Y: the pixel and the subpixel (1/256), hex. VX / VY: how far Kirby moved since the last
; frame, times 2, in decimal with 2 decimals (2026-10-15, the user; until then 8.8 in hex)
; (2026-10-12: the speed values of the game miss some moves: I-RAM
; $37B8 is his walking / hovering speed, but 0 in the Jet dash; $6BEA is the fall speed).
; BOSS: the boss's HP ($7A19, "-" without one). (Kirby's and the helper's HP until 2026-10-15.)
; TIME and LAG are the ones of the other HUD choices.
;
; - The game's HUD routine still runs every frame (the Gourmet Race timer counts there, $01EE4D),
;   it only draws into its buffer ($7E1617, 32 x 7 tiles, then the high bytes). Its upload
;   ($01F79F, here detail_hud_upload) is replaced: the game's buffer is not uploaded. The SA-1
;   writes the values into our own map (!detail_buf, the tile numbers only: the attribute is the
;   same everywhere) while it waits for the S-CPU to run the game's HUD routine (the SA-1 asks
;   for it with $008C6D and waits: $01A2A8 in the levels, $018060), and notes what changed in rows
;   1-5 since it was last sent (!detail_first / !detail_len; most frames the 2 tiles of the
;   centiseconds). The S-CPU sends that after the pad read (pads_read, nmi.asm: the SA-1 goes on
;   first), all of the map after the layout was written again.
; - Lag (2026-10-13, the user; see also hud_timer.asm): at first the layout went into the game's
;   buffer, and it was
;   written again whenever the game drew there (in Meta Knight 1 every frame), and the numbers
;   were converted with loops. In BizHawk, 900 frames with the same inputs: Meta Knight 1 had 31
;   lag frames instead of 10, Cave 3 18 instead of 10: the SA-1 waits for the HUD routine, all
;   the time it took was added to the frame. Now our own map (the layout only after a forced
;   blank / the menu), tables for hex / decimal, the HP values only when they change, and all of
;   it done by the SA-1 while it waits anyway. Then the NMI (160 bytes a frame and one font tile:
;   about 4 lines): only what changed, after the pad read. 17 rooms in BizHawk: 164 lag frames,
;   162 with lag_baseline.sfc.
; - The font (36 tiles, tools/make_detail_font.py) goes over the HUD tiles $CE-$F1: after a forced
;   blank, a Meta Knight message and when the game changes the layout ($00B1: it writes some tiles
;   there, e.g. $E4-$E8 in Spring Breeze), all of it in one frame with the map (until 2026-10-16
;   12 tiles a frame; until 2026-10-13 also one tile again every frame, in case the game writes
;   there some other time: dropped, it made the NMI longer).
; - Switched off in the menu: when it closes, the HUD tiles $B6-$FF are decompressed again (as
;   the room load does, $01E922) and the game draws its layout again ($00B1 = $FFFF).
; - Palette 1 (the portrait): colour 1 white, 2 black. The HUD's palettes are sent to CGRAM at
;   line 168 by the HUD IRQ ($01EA10, from $7E151F = colour 4). When Kirby is hit (or gets an
;   ability) the game makes colours 1-15 of palette 1 white for a few frames (the portrait
;   flashing): the whole HUD went white. Colours 1 and 2 are written back every frame (the values
;   they always have otherwise).

!dt             = $CE           ; tile of glyph 0 (0-9 A-F, then the ones below)
!dt_blank       = !dt+16
!dt_colon       = !dt+17
!dt_dot         = !dt+18
!dt_plus        = !dt+19
!dt_minus       = !dt+20
!dt_line        = !dt+21
!dt_ti          = !dt+22        ; the labels, 2 small letters a tile
!dt_me          = !dt+23
!dt_rn          = !dt+24
!dt_g           = !dt+25
!dt_x           = !dt+26
!dt_y           = !dt+27
!dt_vx          = !dt+28
!dt_vy          = !dt+29
!dt_pb          = !dt+30        ; (HP until 2026-10-15)
!dt_cn          = !dt+31        ; (HE, LP of HELPER until 2026-10-17)
!dt_t           = !dt+32
!dt_bo          = !dt+33
!dt_ss          = !dt+34
!dt_la          = !dt+35
!detail_glyphs  = $0024         ; 36
!detail_attr    = $24           ; palette 1, priority (as the portrait)
!detail_speed_scale = 2         ; VX / VY are shown times this (1, 2 or 3; 2026-10-15, the user: the
                                ; differences were too small to see)

; the font in the free space at the end of bank $05 (not right after the game's data, $05FA8E)
pushpc
ORG $05FB00
detail_font:
    incbin "../graphics/bin/detail_font.bin"
assert pc() <= $060000
pullpc

; the tables of the numbers, in the free space at the end of bank $2B (from $2BFD4F)
pushpc
ORG $2BFD60
detail_hex:                     ; a byte -> its two hex digits (the tiles, the high one first)
    !detail_n = 0
    while !detail_n < 256
    db !dt+(!detail_n>>4), !dt+(!detail_n&15)
    !detail_n #= !detail_n+1
    endwhile
detail_bcd:                     ; 0-99 -> BCD
    !detail_n = 0
    while !detail_n < 10
    !detail_m = 0
    while !detail_m < 10
    db (!detail_n<<4)|!detail_m
    !detail_m #= !detail_m+1
    endwhile
    !detail_n #= !detail_n+1
    endwhile
assert pc() <= $2C0000
pullpc

; S-CPU, the end of the game's HUD routine in the しょうさい HUD (JML from hud_slot_hud_upload,
; hud_timer.asm; 16-bit A/X/Y)
detail_hud_upload:
    ; a Meta Knight message on the HUD: the game's HUD as it is (its tiles back once), and our
    ; font and layout again after it
    JSR detail_msg
    BCC .no_msg
    LDA.l !detail_msg_on
    BNE +
    INC A
    STA.l !detail_msg_on
    JSL detail_hud_restore      ; (the game draws its layout again: $00B1 = $FFFF)
    +
    ; the game's upload ($01F79F)
    LDA.l $0000AF
    BEQ +
    LDA.l $003019
    CLC
    ADC #$0226
    CMP.l $00301B
    BCS +
    LDA #$0000
    STA.l $0000AF
    LDX #$0001
    LDA #$F7BE
    JSL $0086E5
    +
    RTL
    .no_msg:
    LDA.l !detail_msg_on
    BEQ +
    LDA #$0000
    STA.l !detail_msg_on
    STA.l !detail_font_next
    INC A
    STA.l !detail_relayout
    +
    ; a new layout: the game has written some of its tiles over the font
    LDA.l $0000B1
    CMP.l !detail_layout
    BEQ +
    STA.l !detail_layout
    LDA #$0000
    STA.l !detail_font_next
    +
    LDA #$0000                  ; never the game's upload
    STA.l $0000AF
    STA.l $7E153B               ; palette 1, colour 1 white, colour 2 black (the portrait flashes)
    LDA #$7FFF
    STA.l $7E1539
    RTL

; Carry set: Meta Knight shows a message on the HUD (its HUD routine $01F14E: $7A21 is not $FF ->
; the layout of the messages, 8: a portrait and a window, the text over it). 2026-10-15, the
; user: our map hid the portrait and the window and the text went over our numbers. Either CPU.
detail_msg:
    LDA.l !subgame
    AND #$00FF
    CMP #$0004
    BNE +
    LDA.l $007A21
    AND #$00FF
    CMP #$00FF
    BEQ +
    SEC
    RTS
    +
    CLC
    RTS

; SA-1, at the end of its frame (sa1_wait_for_snes, qsql.asm; 16-bit A/X/Y), when the game's HUD
; routine ran in this frame (!detail_hud_ran): our map. 2026-10-16 (the user: less lag): here and
; not while the S-CPU runs the HUD routine (when the SA-1 took longer than that, the frame got
; longer: 17 rooms, 159 lag frames, 138 with lag_baseline.sfc), and the values note what changed
; as they are written (!detail_lo / !detail_hi) instead of comparing rows 1-5 with a copy.
detail_hud_sa1:
    LDA.l !detail_hud_ran
    BEQ .no
    LDA #$0000
    STA.l !detail_hud_ran
    LDA.l !hud_display_mode
    CMP #$0003
    BEQ +
    .no:
    RTL
    +
    ; the menu has closed: its VRAM backup (where our map is) goes back to VRAM in the NMIs
    ; (queued by $0086E5: $3015 is where the NMI reads the queue, $3017 where it is written; the
    ; game queues more all the time). Wait until the NMI has read up to where the queue ended
    ; then (BizHawk 2026-10-13: the stage's tiles got our numbers).
    LDA.l !detail_hold
    BEQ +
    SEC
    SBC.l $003015
    AND #$03FF                  ; not read yet: up to the end of the queue now
    BEQ ++
    PHA
    LDA.l $003017
    SEC
    SBC.l $003015
    AND #$03FF
    CMP $01,S
    PLA
    BCS .no
    ++
    LDA #$0000
    STA.l !detail_hold
    +
    JSR detail_msg              ; a Meta Knight message: nothing (our layout again after it)
    BCC +
    LDA #$0000
    STA.l !detail_ready
    INC A
    STA.l !detail_relayout
    RTL
    +
    PHB
    PEA.w ((bank(!detail_buf)<<8)|bank(!detail_buf))+0
    PLB
    PLB
    ; what changed: nothing yet, or what the S-CPU has not sent yet (!detail_ready still 1)
    LDA #$FFFF
    STA.w !detail_lo
    STZ.w !detail_hi
    LDA.w !detail_ready
    STZ.w !detail_ready         ; (the S-CPU does not send it half written)
    BEQ +
    LDA.w !detail_first
    STA.w !detail_lo
    CLC
    ADC.w !detail_len
    DEC A
    DEC A
    STA.w !detail_hi
    +
    LDA.w !detail_relayout      ; after a forced blank / the menu: our layout again
    BEQ +
    STZ.w !detail_relayout
    JSR detail_layout
    LDA #$0001
    STA.w !detail_full
    +
    JSR detail_values
    LDA.w !detail_hi            ; what the S-CPU sends of rows 1-5 (most frames the 2 tiles of
    SEC                         ; the centiseconds)
    SBC.w !detail_lo
    BCC +
    INC A
    INC A
    STA.w !detail_len
    LDA.w !detail_lo
    STA.w !detail_first
    BRA .ready
    +
    LDA.w !detail_full          ; (the whole map)
    BEQ +
    .ready:
    LDA #$0001
    STA.w !detail_ready
    +
    PLB
    RTL

; DB = bank(!detail_buf): the blank layout and the labels into our map
detail_layout:
    LDA.w #(!dt_blank)|((!dt_blank)<<8)
    STA.w !detail_buf
    LDX.w #!detail_buf&$FFFF
    LDY.w #(!detail_buf+2)&$FFFF
    LDA #$00DD
    MVN bank(!detail_buf),bank(!detail_buf)
    LDA.w #(!dt_line)|((!dt_line)<<8)
    STA.w !detail_buf
    LDX.w #!detail_buf&$FFFF
    LDY.w #(!detail_buf+2)&$FFFF
    LDA #$001D
    MVN bank(!detail_buf),bank(!detail_buf)
    LDX #$0000
    -
    LDA.l detail_labels,X       ; map offset, tile
    AND #$00FF
    CMP #$00FF
    BEQ +
    TAY
    LDA.l detail_labels+1,X
    SEP #$20
    STA.w !detail_buf,Y
    REP #$20
    INX
    INX
    BRA -
    +
    LDA #$7FFF                  ; the HP values: none of them yet
    STA.w !detail_cache
    STA.w !detail_cache+2
    STA.w !detail_cache+4
    STA.w !detail_cache+6
    JSL rng_count_layout        ; the RNG count's label (rng_count.asm)
    RTS

; DB = bank(!detail_buf): the values into our map (Y = map offset in the helpers)
detail_values:
    ; TIME: the time kept at a door while it is shown, else the running time
    LDX #$0000
    LDA.w !seg_split_hold
    BEQ +
    LDX #$0008
    +
    LDA.w !seg_timer_min,X
    PHA
    LDA.w !seg_timer_sec,X
    PHA
    LDA.w !seg_timer_cs,X
    LDY #$002E
    JSR .dec2
    PLA
    LDY #$002B
    JSR .dec2
    PLA
    CLC
    ADC.w #!dt
    LDY #$0029
    JSR .put1
    ; RNG: "xxx xxx", the low byte first (as in the menus)
    LDA.l !RNG_long
    AND #$00FF
    LDY #$0035
    JSR .dec3
    LDA.l !RNG_long+1
    AND #$00FF
    LDY #$0039
    JSR .dec3
    JSL rng_count_detail        ; the RNG count under it (rng_count.asm), carry set: written
    BCC +
    LDY #$0057
    JSR .mark
    LDY #$005A
    JSR .mark
    +
    ; what moves Kirby: his object, or Wheelie (the helper's object, $6240) while he rides it
    ; ($7569): he is put on it with whole pixels and his subpixels stay as they are (2026-10-15,
    ; the user: the rider dash showed +05.00 / +04.00 instead of +04.E8)
    LDX #$0000
    LDA.l !wheelie_rider_state_long
    AND #$00FF
    BEQ +
    LDA.l $006240
    BMI +
    TAX
    +
    STX.w !detail_obj
    ; X, Y: Kirby's pixel.the subpixel of what moves him (the high byte of $6A7A,Y / $6AF4,Y)
    LDA.l $006989
    LDY #$0068
    JSR .hex
    LDA.l $006988
    LDY #$006A
    JSR .hex
    LDX.w !detail_obj
    LDA.l $006A7D,X
    LDY #$006D
    JSR .hex
    LDA.l $006A03
    LDY #$0088
    JSR .hex
    LDA.l $006A02
    LDY #$008A
    JSR .hex
    LDX.w !detail_obj
    LDA.l $006AF7,X
    LDY #$008D
    JSR .hex
    ; VX, VY: how far it moved since the last frame (the low byte of the pixel and the subpixel,
    ; 8.8: a door or a warp, getting on or off Wheelie show something wrong for a frame)
    LDX.w !detail_obj
    SEP #$20
    LDA.l $006A7D,X
    XBA
    LDA.l $006988,X
    XBA
    REP #$20
    TAX
    SEC
    SBC.w !detail_prev
    STX.w !detail_prev
    LDY #$0072
    JSR .speed
    LDX.w !detail_obj
    SEP #$20
    LDA.l $006AF7,X
    XBA
    LDA.l $006A02,X
    XBA
    REP #$20
    TAX
    SEC
    SBC.w !detail_prev+2
    STX.w !detail_prev+2
    LDY #$0092
    JSR .speed
    ; the boss's HP (negative: none). Not Kirby's and the helper's any more (2026-10-15, the user)
    LDA.l $007A19
    LDX #$0004
    LDY #$00BC
    JSR .cached
    LDA.w !lag_count            ; (the one kept at a door while the time is)
    LDX.w !seg_split_hold
    BEQ +
    LDA.w !lag_shown
    +
    LDX #$0006
    LDY #$00A9
    JSR .cached
    if !pb
    JSL pb_detail               ; the room PB (pb.asm; !detail_cache+0), carry set: written
    BCC +
    LDY #$0049
    JSR .mark
    LDY #$004E
    JSR .mark
    +
    endif
    RTS

; A = 0-99 at Y, Y+1
.dec2:
    TAX
    LDA.l detail_bcd,X
; the low byte of A at Y, Y+1 (hex)
.hex:
    AND #$00FF
    ASL
    TAX
    LDA.l detail_hex,X
; A = 2 tiles at Y, Y+1, noted if they changed
.put2:
    CMP.w !detail_buf,Y
    BEQ .rts
    STA.w !detail_buf,Y
; Y (and Y + 1) changed
.mark:
    CPY.w !detail_lo
    BCS +
    STY.w !detail_lo
    +
    CPY.w !detail_hi
    BCC .rts
    STY.w !detail_hi
    .rts:
    RTS

; the low byte of A at Y, noted if it changed
.put1:
    SEP #$20
    CMP.w !detail_buf,Y
    BEQ +
    STA.w !detail_buf,Y
    REP #$20
    BRA .mark
    +
    REP #$20
    RTS

; A = 0-999 at Y, Y+1, Y+2 (leading zeros; Y ends at Y+1)
.dec3:
    LDX.w #!dt
    -
    CMP #$0064
    BCC +
    SBC #$0064
    INX
    BRA -
    +
    PHA
    TXA
    JSR .put1
    INY
    PLA
    BRA .dec2

; A = the value (negative: "  -"), X = its cache, Y = map offset: written when it changed,
; 0-999 with leading blanks
.cached:
    CMP.w !detail_cache,X
    BEQ .rts
    STA.w !detail_cache,X
    JSR .mark                   ; (Y to Y + 2)
    INY
    JSR .mark
    DEY
    CMP #$0000
    BMI .none
    CMP #$03E8
    BCC +
    LDA #$03E7
    +
    PHY
    JSR .dec3
    PLY
    SEP #$20
    LDA.w !detail_buf,Y
    CMP #!dt
    BNE +
    LDA #!dt_blank
    STA.w !detail_buf,Y
    LDA.w !detail_buf+1,Y
    CMP #!dt
    BNE +
    LDA #!dt_blank
    STA.w !detail_buf+1,Y
    +
    REP #$20
    RTS

.none:
    LDA.w #(!dt_blank)|((!dt_blank)<<8)
    STA.w !detail_buf,Y
    SEP #$20
    LDA #!dt_minus
    STA.w !detail_buf+2,Y
    REP #$20
    RTS

; A = 8.8 signed at Y-Y+5: "+II.FF", in decimal (the fraction in 1/100, rounded down)
.speed:
    if !detail_speed_scale == 2
    ASL
    elseif !detail_speed_scale == 3
    STA.w !detail_tmp2
    ASL
    CLC
    ADC.w !detail_tmp2
    endif
    LDX.w #!dt_plus
    CMP #$8000
    BCC +
    EOR #$FFFF
    INC A
    LDX.w #!dt_minus
    +
    PHA
    TXA
    JSR .put1
    INY
    LDA $01,S                   ; the pixels: 2 decimal digits (99 at most)
    XBA
    AND #$00FF
    CMP #$0064
    BCC +
    LDA #$0063
    +
    JSR .dec2
    INY
    INY
    INY
    PLA                         ; the fraction: 1/256 -> 1/100 (2026-10-15, the user: decimal)
    AND #$00FF
    ASL
    ASL
    STA.w !detail_tmp2          ; * 4
    ASL
    ASL
    ASL
    PHA                         ; * 32
    ASL                         ; * 64
    CLC
    ADC $01,S
    CLC
    ADC.w !detail_tmp2
    PLX
    XBA
    AND #$00FF
    JMP .dec2

print "bank21 end: ", pc
assert pc() <= $21FFFF

; the NMI and the menu part: free space at the end of bank $25
org $25FCA0

; S-CPU, after the pad read (pads_read, nmi.asm; 16-bit A/X/Y, DB = $00): the font and the map
; to VRAM. The font all at once, with the map, before line 248 (about 10 lines); else the whole
; map before line 252 (about 3 lines), rows 1-5 only before line 256; DMA channel 0 is put back.
; The font: 2026-10-16, the user: 12 tiles a frame, and only on frames the SA-1 wrote (it writes
; only what changed: nothing while the time at a door is kept after a room loop, and the font
; stopped at 12 tiles), so the HUD showed the game's tiles for words; after a Meta Knight message
; the map came a frame or two before the font.
detail_hud_nmi:
    LDA.l !hud_display_mode
    CMP #$0003
    BEQ +
    RTL
    +
    LDA.l !detail_font_next     ; the font still to write: also on frames the SA-1 did not write
    CMP.w #!detail_glyphs
    BCS .no_font
    ; only in a level: after a forced blank on the corkboard, its map is where the font goes
    ; (2026-10-19, the user: the corkboard was garbled at power on)
    LDA.l !game_mode_long
    AND #$00FF
    CMP #$0003
    BEQ +
    RTL
    .no_font:
    LDA.l !detail_ready
    BNE +
    RTL                         ; nothing drawn this frame (a lag frame, or not in a level)
    +
    SEP #$20
    LDA $4212
    BPL .late
    LDA $2137                   ; latch the counters
    LDA $213F                   ; (resets the low / high order of $213D)
    LDA $213D
    XBA
    LDA $213D
    AND #$01
    XBA
    REP #$20
    ; the game's NMI ends near line 240 (242-243 while Jet charges, 2026-10-12: a limit of 242 left
    ; the HUD still then)
    TAY
    ; line 0-224: vblank was over by the time the line was read (2026-10-19, the user: flicker
    ; in Meta Knight 3 when jumping: $4212 was read on line 261, the line on line 0, and the DMA
    ; went into the picture of the next frame)
    CPY #$00E1
    BCC .late
    LDA.l !detail_font_next
    CMP.w #!detail_glyphs
    BCS +
    CPY #$00F8                  ; the font: before line 248, else nothing yet (ready kept)
    BCC .go
    RTL
    +
    CPY #$00FC
    BCC .go
    CPY #$0100
    BCC .light
    .late:
    REP #$20
    RTL
    .light:
    ; late: the tile numbers of rows 1-5 only (the whole map in the next frame)
    LDA $4300
    PHA
    LDA $4302
    PHA
    LDA $4304
    PHA
    LDA $4306
    PHA
    SEP #$20
    LDA.b #bank(!detail_buf)
    STA $4304
    REP #$20
    LDA #$1800
    STA $4300
    JSR .rows
    LDA #$0000
    STA.l !detail_ready
    JMP .restore
    .go:
    LDA $4300
    PHA
    LDA $4302
    PHA
    LDA $4304
    PHA
    LDA $4306
    PHA
    LDA #$0001
    STA.l !detail_vram

    ; the font: what is left of it, after a forced blank / new layout / a message
    LDA.l !detail_font_next
    CMP.w #!detail_glyphs
    BCS .map
    PHA
    LDA.w #!detail_glyphs
    STA.l !detail_font_next
    SEC
    SBC $01,S
    ASL
    ASL
    ASL
    ASL
    ASL
    STA $4305
    PLA
    PHA
    ASL
    ASL
    ASL
    ASL
    CLC
    ADC.w #$5000+(!dt*16)       ; HUD tiles: VRAM word $5000 + tile * 16
    STA $2116
    PLA
    ASL
    ASL
    ASL
    ASL
    ASL
    CLC
    ADC.w #detail_font
    STA $4302
    LDA #$1801                  ; to $2118, 2 registers
    STA $4300
    SEP #$20
    LDA #$80
    STA $2115
    LDA.b #bank(detail_font)
    STA $4304
    LDA #$01
    STA $420B
    REP #$20
    LDA.l !detail_ready         ; the SA-1 has not written this frame: the map later
    BNE .map
    JMP .restore

    ; the map: what changed in rows 1-5, or all of it
    .map:
    SEP #$20
    STZ $2115                   ; increment after the low byte
    LDA.b #bank(!detail_buf)
    STA $4304
    REP #$20
    LDA #$1800                  ; to $2118 only
    STA $4300
    LDA.l !detail_full
    BNE +
    JSR .rows
    BRA .done
    +
    LDA #$0000
    STA.l !detail_full
    LDA #$5800
    STA $2116
    LDA.w #!detail_buf&$FFFF
    STA $4302
    LDA #$00E0
    STA $4305
    SEP #$20
    LDA #$01
    STA $420B
    LDA #$80                    ; the high bytes: all the same
    STA $2115
    LDA.b #bank(detail_attr_byte)
    STA $4304
    REP #$20
    LDA #$5800
    STA $2116
    LDA.w #detail_attr_byte
    STA $4302
    LDA #$00E0
    STA $4305
    LDA #$1908                  ; to $2119, the same source byte
    STA $4300
    SEP #$20
    LDA #$01
    STA $420B
    .done:
    LDA #$80                    ; back to the usual $80 (the state save / load, 2026-10-08)
    STA $2115
    REP #$20
    LDA #$0000
    STA.l !detail_ready
    .restore:
    PLA
    STA $4306
    PLA
    STA $4304
    PLA
    STA $4302
    PLA
    STA $4300
    RTL

; the tile numbers that changed in rows 1-5 (!detail_first / !detail_len; DMA channel 0 set to
; $2118 from bank(!detail_buf)). 16-bit A.
.rows:
    SEP #$20
    STZ $2115                   ; increment after the low byte
    REP #$20
    LDA.l !detail_first
    CLC
    ADC #$5800
    STA $2116
    LDA.l !detail_first
    CLC
    ADC.w #!detail_buf&$FFFF
    STA $4302
    LDA.l !detail_len
    STA $4305
    SEP #$20
    LDA #$01
    STA $420B
    LDA #$80
    STA $2115
    REP #$20
    RTS

detail_attr_byte:
    db !detail_attr

; (map offset, tile) pairs of the layout (detail_layout; here: bank $21 is full)
detail_labels:
    db $26, !dt_ti, $27, !dt_me, $2A, !dt_colon, $2D, !dt_dot
    db $32, !dt_rn, $33, !dt_g
    db $66, !dt_x, $6C, !dt_dot, $70, !dt_vx, $75, !dt_dot
    db $86, !dt_y, $8C, !dt_dot, $90, !dt_vy, $95, !dt_dot
    db $A6, !dt_la, $A7, !dt_g
    db $B9, !dt_bo, $BA, !dt_ss
    if !pb
    db $46, !dt_pb, $4A, !dt_colon, $4D, !dt_dot
    endif
    ; Kirby's ability portrait (the game's HUD tiles $8E-$A1, 4 x 5, in every sub-game; 2026-10-15,
    ; the user: keep it), rows 1-5, columns 1-4
    !detail_n = 0
    while !detail_n < 5
    !detail_m = 0
    while !detail_m < 4
    db $21+!detail_n*32+!detail_m, $8E+!detail_n*4+!detail_m
    !detail_m #= !detail_m+1
    endwhile
    !detail_n #= !detail_n+1
    endwhile
    db $FF

; S-CPU NMI (nmi_code, 16-bit A), in a forced blank (a room load writes the HUD tiles
; and map again): the font and our layout again after it. (Here and not in detail_hud_nmi: the
; SA-1 does not end a frame during a room load.)
detail_hud_blank:
    LDA.l !hud_display_mode
    CMP #$0003
    BNE +
    LDA #$0000
    STA.l !detail_font_next
    STA.l !detail_ready
    INC A
    STA.l !detail_relayout
    +
    RTL

; SA-1, when the menu closes (exit_menu): the しょうさい HUD on -> write the font and the map;
; off while they are in VRAM -> the game's HUD again.
detail_hud_menu_exit:
    REP #$30
    LDA.l !hud_display_mode
    CMP #$0003
    BNE +
    LDA #$0000
    STA.l !detail_font_next
    STA.l !detail_ready
    INC A
    STA.l !detail_relayout
    LDA.l $003017               ; the end of the DMA queue, after the menu's VRAM backup
    ORA #$8000
    STA.l !detail_hold
    RTL
    +
    LDA.l !detail_vram
    BEQ +
    LDA #$0000
    STA.l !detail_vram
    LDA.l !game_mode_long       ; out of the level, everything was loaded again
    AND #$00FF
    CMP #$0003
    BNE +
    LDA.w #detail_hud_restore
    LDX.w #bank(detail_hud_restore)
    JSL !sa1_executesnes
    REP #$30
    +
    RTL

; S-CPU: the HUD tiles $B6-$FF again, as the room load ($01E922: decompressed, then $0940 bytes to
; VRAM $5B60), and the game draws its layout again (the tiles of the layout, the buffer, all of it
; uploaded; $01F7D5).
detail_hud_restore:
    REP #$30
    LDA.l !subgame_long
    AND #$00FF
    CMP #$000A
    BCC +
    LDA #$0009
    +
    CMP #$0002                  ; Gourmet Race before the race ($7B2B = 0): its own graphics
    BNE +
    LDA.l $007B2B
    BNE ++
    LDA #$000A
    BRA +
    ++
    LDA #$0002
    +
    STA.l !detail_ready         ; (scratch: the NMI does nothing with it while it is off)
    ASL
    ASL
    ASL
    CLC
    ADC.l !detail_ready         ; * 9
    CLC
    ADC.w #detail_hud_gfx
    LDX.w #bank(detail_hud_gfx)
    JSL !load_dma_table
    REP #$30
    LDA #$0000
    STA.l !detail_ready
    LDA #$FFFF
    STA.l $0000B1
    RTL

; mode $83 (decompress, then to VRAM) of !load_dma_table, one for each sub-game ($32EA 0-9), then
; Gourmet Race before the race; the sources of $01FD98 / $E8EE73
detail_hud_gfx:
    !detail_n = 0
    while !detail_n < 10
    db $83 : dw $0940 : dl read3($01FD98+3*!detail_n) : dw $5B60 : db $FF
    !detail_n #= !detail_n+1
    endwhile
    db $83 : dw $0940 : dl $E8EE73 : dw $5B60 : db $FF

print "bank25 end: ", pc
assert pc() <= $25FFFF
