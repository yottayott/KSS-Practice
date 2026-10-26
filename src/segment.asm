; Segment practice: the timer / RNG of the HUD in VRAM, and the location display of the practice menu

; NMI (S-CPU, at the end of the handler): writes the tiles of the timer / RNG that changed to VRAM
; (hud_timer.asm: the SA-1 draws them into !hud_tiles at the end of its frame). The HUD tile
; numbers are the low bytes of VRAM $5800 + (buffer address - $1617) (see the HUD upload at
; $01F7BE). Waits for the next frame if vblank is already over. 16-bit A/X/Y, DB = $00.
hud_slot_upload:
    LDA.l !hud_slot_dirty
    BEQ .done
    SEP #$20
    LDA $4212
    BPL .later              ; not in vblank any more
    ; nor when it is about to end (line 256 or later: the low byte of the line in vblank,
    ; 225-261, is then below $E1; 2026-10-09)
    LDA $2137               ; latch the counters
    LDA $213F               ; (resets the low / high order of $213D)
    LDA $213D
    CMP #$E1
    BCS .go
    .later:
    REP #$20
    .done:
    RTS
    .go:
    STZ $2115               ; increment after writing the low byte
    REP #$20
    if !pb
    LDA.l !hud_slot_dirty   ; bit 0: the timer / RNG, bit 1: the PB row (hud_timer.asm)
    LSR A
    BCC .pb
    endif
    LDA.l !hud_slot_first
    TAX
    CLC
    ADC.l !hud_slot_vram
    STA $2116
    LDA.l !hud_slot_count
    TAY
    SEP #$20
    -
    LDA.l !hud_tiles,X
    STA $2118
    INX
    DEY
    BNE -
    if !pb
    REP #$20
    .pb:
    LDA.l !hud_slot_dirty
    AND #$0002
    BEQ +
    LDA.l !hud_pb_vram
    STA $2116
    LDX #$0000
    SEP #$20
    -
    LDA.l !hud_pb_tiles,X
    STA $2118
    INX
    CPX #$0007
    BNE -
    +
    SEP #$20
    endif
    LDA #$80                ; back to the usual $80: the state save / load read and write all of
    STA $2115               ; VRAM without setting it, which garbled the graphics (2026-10-08)
    REP #$20
    LDA #$0000
    STA.l !hud_slot_dirty
    RTS



; -- Room loop (L+R+B during gameplay: On / Off, see room_loop_hotkey in qsql.asm)
; Entering a door reloads the current room like R+X (same ability, health, invincibility and
; RNG as when the room was entered) instead of going to the next room.
; Doors that end the level ($7FFF, e.g. the door to the goal game) loop too (user request, 2026-10-07).
; (A segment loop was tried on 2026-10-07 and removed again: the user did not need it.)

pushpc
; door routine (SA-1): keep the entry of the current room before the door data overwrites it
ORG $0191C6
    JSL room_loop_keep_entry
    NOP
; door routine: the destination room is set and the fade out is started
ORG $01924E
    JML room_loop_door
pullpc

; 16-bit A/X/Y, X = Kirby or helper (do not touch)
room_loop_keep_entry:
    LDA.l !room_loop_request
    BNE +
    LDA $332A
    STA.l !room_loop_entry_type
    LDA $330C
    STA.l !room_loop_entry_x
    LDA $3310
    STA.l !room_loop_entry_y
    +
    LDA $32FA               ; replaced code
    STA $14
    RTL

; A = destination room, X = $7394 (0 = normal door, 3 = level exit)
; Room loop: the door goes on as a normal door into the current room, so the screen fades out
; fully first (user request, 2026-10-08: before, the room was reloaded on the next frame and the
; fade out was cut short). On the last frame of the fade, before the game reloads the room,
; room_loop_check (NMI) puts the values back like R+X.
room_loop_door:
    PHA
    if !pb
    ; where the door goes, for the room PB (pb.asm: is it the next room of the route?). $330C /
    ; $3310 are the door's by now; before the room loop puts the current entry back.
    STA.l !pb_door_room
    TXA
    INC A
    STA.l !pb_door_kind
    LDA $330C
    STA.l !pb_door_x
    LDA $3310
    STA.l !pb_door_y
    endif
    LDA.l !room_loop_on
    BEQ .normal_pla
    ; put the entry of the current room back
    LDA.l !room_loop_entry_type
    CMP #$0001              ; the first room of a level: its entrance again, as R+X does
    BNE +                   ; (restore_current_room; 2026-10-19, the user: Kirby started at the
    LDA #$0000              ; room's start position instead in Meta Knight 1)
    +
    STA $332A
    LDA.l !room_loop_entry_x
    STA $330C
    LDA.l !room_loop_entry_y
    STA $3310
    LDA #$0001
    STA.l !room_loop_request
    ; the NMI only looks at the request while the R+X / savestate cooldown timer counts down:
    ; in some rooms (Dyna Blade 1) the NMI timing is so tight that a few more cycles on every
    ; frame made the screen flash black (2026-10-07). Keep it running until the fade is over.
    LDA #$0020
    STA.l !QSQL_timer_long
    PLA
    STZ $7394               ; a normal door, also for a level exit
    LDA #$0002              ; the room loop (2: was told apart for the とおし timer, removed 2026-10-15)
    BRA .store_room
    .normal_pla:
    PLA
    .normal:
    STX $7394               ; replaced code
    STA $32F2
    LDA #$0001              ; the room timer starts again after this fade (segment_timer.asm)
    .store_room:
    STA.l !seg_room_door
    LDA #$000F
    STA $3334
    INC $73A4
    RTL

; Called from the NMI while the cooldown timer runs (not on lag frames).
; When the door's fade out is over (the game reloads the room on the next frame), put the
; values back like R+X. Carry clear (the NMI goes on as usual).
room_loop_check:
    LDA.l !room_loop_request
    BEQ .done
    LDA.l !screen_brightness_long   ; 0 or forced blank
    AND #$000F
    BNE .done
    LDA.l !room_loop_request
    CMP #$0002                      ; not a door: the game goes to the current room again
    BNE +
    JSL room_loop_retarget          ; (segment_timer.asm)
    +
    LDA #$0000
    STA.l !room_loop_request
    STA.l !seg_pending_rng_flag     ; a room reload cancels a pending warp RNG
    JSL room_loop_restore
    SEP #$20                        ; NMI on again (off while it uploads the ability sounds)
    LDA $3091
    STA $4200
    REP #$20
    .done:
    CLC
    RTS
