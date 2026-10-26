pushpc
; Jump to NMI custom code at the end of the NMI handler, after the screen registers and the
; transfers to VRAM are done. It used to run at the start ($0081B7) and delayed all of them:
; in Dyna Blade 1 they then did not fit in vblank any more and the screen flickered on the
; FXPAK PRO about once in 10 seconds, even before the room loop (2026-10-07).
; The usual frame is done by nmi_fast (segment_timer.asm): the timer and whether anything else
; is needed; only then the code below (2026-10-16, fewer cycles in every NMI).
ORG $0083C1
    JSL nmi_fast            ; was SEP #$10 : LDX #$FF
pullpc

; JML from nmi_fast when the R+X / savestate cooldown counts down or a button was pressed (not
; on lag frames, not with the menu open). The return address of the JSL at $0083C1 is on the
; stack: a successful restore_state returns here too, through the stack of the saved state.
nmi_code:
    REP #$30
    PHY

    ; The NMI handler uses direct page $3000 here. The savestate code needs the S-CPU's own
    ; direct page ($3700, set at $008C0E): the game routines it calls (e.g. load_background)
    ; overwrite SA-1 variables with $3000.
    PHD
    LDA #$3700
    TCD
    PHB
    PHK
    PLB

    ; Ghost test
    ;JSL $06F25E

    LDA !QSQL_timer             ; make sure that a save or load hasn't occured in the last however many frames
    BNE .countdown_QSQL_timer

    .check_save_input:
        LDA !p1controller_hold
        CMP #$2010
        BNE .check_load_input
        LDA !p1controller_frame
        CMP #$2000              ; R + Select = save state
        BNE .check_load_input
        ; a successful restore_state also returns here (through the saved stack)
        JSL save_state
        BRA .return

    .check_load_input:
        LDA !p1controller_hold
        CMP #$2020
        BNE .check_roomload_input
        LDA !p1controller_frame
        CMP #$2000              ; L + Select = load state
        BNE .check_roomload_input
        JSL restore_state       ; (puts the timer back as it was at the save)
        BRA .return

    .check_roomload_input:
        LDA !p1controller_hold
        AND #$0010
        ORA !p1controller_frame
        CMP #$0050
        BNE .return
        LDA #$0003              ; 0:00.00 when the screen lights up again
        STA.l !seg_timer_reset
        JSL restore_current_room
        JSR nmi_enable_again
        BRA .return

    .countdown_QSQL_timer:
        ; room loop: a request also sets the timer, so that normal frames do not get
        ; any longer here (a few more cycles every frame made Dyna Blade 1 flash black)
        JSR room_loop_check
        BCC +
        JSR nmi_enable_again
        BRA .return
        +
        DEC !QSQL_timer

    .return:
        REP #$30
        PLB
        PLD
        PLY
        SEP #$10                ; replaced code
        LDX #$FF
        RTL

if !lag_baseline == 0
; At the end of each of its frames the SA-1 asks the S-CPU to read the pads ($008A56: it waits for
; the NMI, then for the auto read). The S-CPU's request loop (in WRAM, $000E, copied from $00818C)
; then lets the SA-1 go on (STZ $300E) and waits for the next request. Here the SA-1 goes on
; first, then the timer / RNG and the しょうさい HUD are written to VRAM (still in vblank, about
; line 241): the SA-1's next frame does not wait for them (2026-10-13: in the NMI they made it
; shorter, about 1 line with the timer, 3 with the しょうさい HUD).
pushpc
ORG $008A97
    JMP pads_read               ; was DEX : DEX : BPL $8A66 : RTL
    NOP
pullpc

; (2026-10-16: as few cycles as possible before the SA-1 goes on: they are added to every frame)
pads_read:
    DEX
    DEX
    BPL .next
    LDA $01,S                   ; called from the request loop (return address $000D)?
    CMP #$000D
    BNE .rtl
    STZ $300E                   ; the SA-1 goes on (DB is $00 here, as for $3010 in $008A56)
    PHB
    PHK
    PLB
    LDA.l !custom_menu_enabled
    BNE +
    JSR hud_slot_upload         ; the timer / RNG on the HUD (segment.asm)
    if !detail_hud
    JSL detail_hud_nmi          ; the しょうさい HUD (detail_hud.asm)
    endif
    +
    PLB
    ; back into the loop after its STZ $300E (the SA-1 may have asked for something new already)
    PLA
    SEP #$20
    PLA
    REP #$20
    JML $000011
    .rtl:
    RTL
    .next:
    JMP $8A66
endif

; restore_current_room (R+X) disables NMI (enable_vblank). When this code ran at the start of the
; NMI, the rest of the handler enabled it again; now that it runs at the end, do it here
; (the game keeps the value of $4200 in $3091, see $008178). Otherwise the game froze.
nmi_enable_again:
    SEP #$20
    LDA $3091
    STA $4200
    REP #$20
    RTS
