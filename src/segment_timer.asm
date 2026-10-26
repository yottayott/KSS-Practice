; HUD timer (moved from segment.asm to bank $0F in 2026-10-08: bank $00 was full; to bank $1B on
; 2026-10-10: bank $0F was full)

; -- Segment timer
; The timer counts real time (lag frames included) in minutes, seconds and centiseconds.
; It stops while a RoMK message waits for a button ($6028), so that skipping a message doesn't
; change the room time.
; It times each room (2026-10-08): 0:00.00 is the first frame the screen starts to light up
; after a warp, a door, R+X or the room loop. When the screen starts to fade out, the time at
; that moment is kept on the HUD until the screen is fully lit again, plus !split_show_frames.
; If the screen lights up again without going dark (no new room), the timer goes on.
; A savestate load puts the timer back as it was when the state was saved (qsql.asm).

!split_show_frames = $005A          ; 1.5 seconds
!timer_frac_per_frame = $A9F7       ; 100 / 60.0988 = 1.663927 centiseconds per frame (fraction part)

;  nmi_fast is the NMI's part (JSL from $0083C1) on every frame, lag frames included. The usual
; frame (lit, the timer running, nothing kept on the HUD, no restart) is counted right there
; (timer_count); anything else goes through segment_timer_tick. 2026-10-16 (the user: less lag):
; the NMI part was about 1.9 lines of every frame, all of it before the SA-1 can go on with its
; next frame. !seg_prev_brightness is the brightness of the last NMI, with $0100 added while the
; timer is not running or the HUD keeps a time: it is $000F only when the next NMI may be a usual
; one.
; Kirby's "on the ground" flag while riding Wheelie: sa1_wait_for_snes (qsql.asm) since 2026-10-16.

; JSL from $0083C1 (the end of the game's NMI handler; was SEP #$10 : LDX #$FF). D = $3000,
; DB = $00.
nmi_fast:
    REP #$30
    LDA.l !custom_menu_enabled      ; the menu is open: nothing
    BNE .return
    LDA $5F                        ; $305F, the brightness (bit 7: forced blank)
    AND #$00FF
    CMP.l !seg_prev_brightness      ; as on the last NMI, and a usual frame?
    BNE .slow
    LDA.l !seg_timer_reset
    BNE .slow
    JSR timer_count
    BRA .hotkeys
    .slow:
    JSL segment_timer_tick
    .hotkeys:
    LDA $10                         ; $3010 (!active_frames): a lag frame, no hotkeys
    BNE .return
    LDA.l !QSQL_timer_long          ; the R+X / savestate cooldown, or a button pressed this frame:
    ORA.l !p1controller_frame_long  ; the hotkeys, the room loop (nmi_code, nmi.asm)
    BEQ .return
    JML nmi_code
    .return:
    SEP #$10                        ; replaced code
    LDX #$FF
    RTL

; The timer on a usual frame (the same as segment_timer_tick .count with a lit screen and nothing
; kept on the HUD). D = $3000, 16-bit A/X/Y.
timer_count:
    ; a RoMK message that stops the game until a button ($6028 = $CF4EA8): don't count
    LDA.l !message_wait_long
    CMP #$4EA8
    BNE +
    LDA.l !message_wait_long+2
    AND #$00FF
    CMP #$00CF
    BEQ .rts
    +
    if !lag_baseline == 0
    ; the lag frames of the room: an NMI where the game's frame counter ($3094) did not go up
    LDA $94
    CMP.l !lag_prev_frame
    STA.l !lag_prev_frame
    BNE +
    LDA.l !lag_count
    CMP.w #999
    BCS +
    INC A
    STA.l !lag_count
    +
    endif
    LDA.l !seg_timer_frac
    CLC
    ADC #!timer_frac_per_frame
    STA.l !seg_timer_frac
    LDA.l !seg_timer_cs
    ADC #$0001
    CMP #$0064
    BCS .second
    STA.l !seg_timer_cs
    .rts:
    RTS
    .second:
    SBC #$0064
    STA.l !seg_timer_cs
    LDA.l !seg_timer_sec
    INC A
    CMP #$003C
    BCC .store_sec
    LDA.l !seg_timer_min
    CMP #$0009
    BCS .max_time
    INC A
    STA.l !seg_timer_min
    LDA #$0000
    .store_sec:
    STA.l !seg_timer_sec
    RTS
    .max_time:
    LDA #$0063                      ; stop at 9:59.99 (seconds stay at 59)
    STA.l !seg_timer_cs
    RTS

; The NMI on the other frames (JSL from nmi_fast; 16-bit A/X/Y, DB = $00, D = $3000).
segment_timer_tick:
    ; Y = brightness (0-$0F), forced blank counts as dark (and the しょうさい HUD after it)
    LDA !screen_brightness
    BIT #$0080
    BEQ +
    if !detail_hud
    JSL detail_hud_blank
    endif
    LDA #$0000
    +
    AND #$000F
    TAY

    ; restart requested? (1 = run right away, 2 = warp: wait for the screen to go dark and
    ; light up, 3 = R+X: wait for it to light up)
    LDA.l !seg_timer_reset
    BEQ .tick
    CMP #$0002
    BEQ +
    TAX
    LDA #$0000
    STA.l !seg_pending_rng_flag     ; a room reload cancels a pending warp RNG
    TXA
    +
    DEC A                           ; 1 -> state 0, 2 -> 1, 3 -> 4
    CMP #$0002
    BNE +
    LDA #$0004
    +
    STA.l !seg_timer_state
    LDA #$0000
    STA.l !seg_room_door
    STA.l !seg_timer_reset
    STA.l !seg_timer_frac
    STA.l !seg_timer_cs
    STA.l !seg_timer_sec
    STA.l !seg_timer_min
    STA.l !seg_split_hold
    if !lag_baseline == 0
    STA.l !lag_count                ; (the lag frames of the room from 0 too)
    endif
    JMP .done

    .done_far:
    JMP .done

    .tick:
    LDA.l !seg_timer_state
    BNE .not_running
    JMP .count
    .not_running:
    CMP #$0003
    BCS +
    JMP .warp_states
    +
    BEQ .room_fading
    ; room: the first lit frame is 0:00.00
    CPY #$0000
    BEQ .done_far
    LDA #$0000
    STA.l !seg_timer_state
    JSR .remember_room
    JMP .done

    .remember_room:
    LDA.l !room_number_long
    AND #$00FF
    STA.l !seg_timer_room
    if !pb
    LDA #$0001                      ; which room of the route it is: the SA-1 looks (pb.asm)
    STA.l !pb_start
    endif
    RTS

    .room_fading:
    JSR room_loop_other_end         ; a warp star / a boss with the room loop on
    ; dark: a new room if a door was entered or the room changed (a warp star...), then 0
    ; (the time shown on the HUD is kept). Else (the pause screen) the same room goes on.
    CPY #$0000
    BNE +
    LDA.l !seg_room_door
    BNE .new_room
    LDA.l !room_number_long
    AND #$00FF
    CMP.l !seg_timer_room
    BNE .new_room
    LDA #$0000
    STA.l !seg_timer_state
    STA.l !seg_split_hold           ; show the running time again
    BRA .count_far
    .new_room:
    LDA #$0004
    STA.l !seg_timer_state
    LDA #$0000
    STA.l !seg_timer_frac
    STA.l !seg_timer_cs
    STA.l !seg_timer_sec
    STA.l !seg_timer_min
    STA.l !seg_room_door
    if !lag_baseline == 0
    STA.l !lag_count
    endif
    BRA .skip
    +
    ; lit again without going dark: the same room goes on
    CPY #$000F
    BNE .count_far
    LDA #$0000
    STA.l !seg_timer_state
    .count_far:
    JMP .count

    .warp_states:
    CMP #$0001
    BNE .wait_for_light

    ; waiting for the screen to go dark
    CPY #$0000
    BNE .skip
    LDA #$0002
    STA.l !seg_timer_state
    BRA .skip

    .wait_for_light:
    ; the first lit frame is 0:00.00, set the segment's RNG now
    CPY #$0000
    BEQ .skip
    LDA #$0000
    STA.l !seg_timer_state
    STA.l !seg_pending_rider        ; the warp is done
    JSR .remember_room
    ; the map to go to after the level (RoMK 1, MWW 2, else 0 = Dyna Blade's map) is set by the
    ; sub-game select ($07DEE1), which a warp from the title screen skips: after RoMK 7 the game
    ; went to the Dyna Blade map (2026-10-07). Only on this one frame, not to lengthen the NMI.
    LDA.l !subgame_long
    AND #$00FF
    TAX
    LDA.l $07DEFF,X
    AND #$00FF
    STA.l !map_to_load_into_long
    LDA.l !seg_pending_rng_flag
    BEQ .skip
    LDA #$0000
    STA.l !seg_pending_rng_flag
    LDA.l !seg_pending_rng
    STA !RNG
    STA.l !store_RNG                ; room reloads (R+X) replay it too
    BRA .skip

    .skip:
    JMP .done

    .count:
    JSR timer_count                 ; (not while a RoMK message waits for a button)

    .split_check:
    ; the screen starts to fade out: keep the current time on the HUD
    LDA.l !seg_prev_brightness
    AND #$00FF
    CMP #$000F
    BNE .hold
    CPY #$000F
    BEQ .hold
    LDA.l !seg_timer_cs
    STA.l !seg_split_cs
    LDA.l !seg_timer_sec
    STA.l !seg_split_sec
    LDA.l !seg_timer_min
    STA.l !seg_split_min
    LDA #$FFFF
    STA.l !seg_split_hold
    if !lag_baseline == 0
    LDA.l !lag_count                ; the lag frames are kept with it (extras.asm)
    STA.l !lag_shown
    endif
    LDA.l !seg_timer_state          ; a room ends here (a warp waits for the dark itself)
    BNE .done
    LDA #$0003
    STA.l !seg_timer_state
    if !pb
    LDA #$0001                      ; the time for the room PB: the SA-1 takes it (pb.asm)
    STA.l !pb_exit
    endif
    BRA .done

    .hold:
    LDA.l !seg_split_hold
    BEQ .done
    CMP #$FFFF
    BNE .hold_countdown
    ; frozen until the screen is fully lit again
    CPY #$000F
    BNE .done
    LDA #!split_show_frames
    BRA .store_hold
    .hold_countdown:
    DEC A
    .store_hold:
    STA.l !seg_split_hold

    .done:
    ; the brightness for the next NMI, + $0100 if that cannot be a usual frame (nmi_fast)
    LDA.l !seg_timer_state
    ORA.l !seg_split_hold
    BEQ +
    LDA #$0100
    +
    STA.l !seg_prev_brightness
    TYA
    ORA.l !seg_prev_brightness
    STA.l !seg_prev_brightness
    RTL

; -- Room loop at the ends that are not doors (2026-10-21, the user: a warp star at the end of
; Dyna Blade 3, a MWW boss and the other bosses went on to the next room / the goal). The door
; hook (room_loop_door, segment.asm) does not see them: a warp star sets the next room ($32F2) and
; its entry when Kirby touches it, a boss sets $7394 (3 = the end of the level) as the screen
; starts to fade. Here the fade of the room is watched, and on its last frame (room_loop_check)
; the game's next step becomes a reload of the current room, like the door.

; The entry of the room as it is loaded (room_reload_code, qsql.asm; also after a state load):
; a warp star overwrites $332A / $330C / $3310 long before the fade. 16-bit A.
room_loop_capture:
    LDA.l !cutscene_long
    STA.l !room_loop_entry_type
    LDA.l !kirby_x_respawn_long
    STA.l !room_loop_entry_x
    LDA.l !kirby_y_respawn_long
    STA.l !room_loop_entry_y
    RTL

; segment_timer_tick .room_fading (each NMI of the fade out of a room; 16-bit, Y kept): the room
; ends without a door -> a room loop request (2) as the door's (1).
room_loop_other_end:
    LDA.l !room_loop_on
    BEQ .rts
    LDA.l !room_loop_request
    BNE .rts
    LDA.l !game_mode_long
    AND #$00FF
    CMP #$0003
    BNE .rts
    LDA.l $007394                   ; the end of the level / an ending
    BNE .loop
    LDA.l !room_number_long         ; another room (a warp star)
    AND #$00FF
    CMP.l !seg_timer_room
    BEQ .rts
    .loop:
    LDA #$0002
    STA.l !room_loop_request
    STA.l !seg_room_door            ; (the room loop: a new room for the timer)
    LDA #$0020                      ; the NMI looks at the request while this counts (nmi.asm)
    STA.l !QSQL_timer_long
    .rts:
    RTS

; room_loop_check (NMI, the screen is dark) for request 2: the game's next step is the current
; room again, as a door into it. 16-bit A.
room_loop_retarget:
    if !pb
    ; where it was going, for the room PB (as a door: pb.asm)
    LDA.l !room_number_long
    STA.l !pb_door_room
    LDA.l $007394
    INC A
    STA.l !pb_door_kind
    LDA.l !kirby_x_respawn_long
    STA.l !pb_door_x
    LDA.l !kirby_y_respawn_long
    STA.l !pb_door_y
    endif
    LDA #$0000
    STA.l $007394                   ; a room load (not the end of the level)
    ; a boss: the entry is still the room's (as R+X); a warp star: the one taken at the load
    LDA.l !room_number_long
    AND #$00FF
    CMP.l !seg_timer_room
    BEQ .entry
    LDA.l !seg_timer_room
    STA.l !room_number_long
    LDA.l !room_loop_entry_type
    STA.l !cutscene_long
    LDA.l !room_loop_entry_x
    STA.l !kirby_x_respawn_long
    LDA.l !room_loop_entry_y
    STA.l !kirby_y_respawn_long
    .entry:
    LDA.l !cutscene_long
    CMP #$0001                      ; the first room of a level: its entrance (as R+X)
    BNE +
    LDA #$0000
    STA.l !cutscene_long
    +
    RTL
