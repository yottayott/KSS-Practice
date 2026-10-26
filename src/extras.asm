; Lag counter and Select + X (2026-10-09), in the free space at the end of bank $1B. The same bank
; for the S-CPU and the SA-1.

; -- Lag counter: the lag frames of the room, the third choice of HUD (しょりおち).
; A lag frame is an NMI where the game's frame counter ($3094) did not go up (as lag_compare.lua
; counts). Counted while the timer runs (timer_count, segment_timer.asm), from 0 when the timer
; restarts; at a door the number is kept on the HUD with the time (!seg_split_hold: !lag_shown,
; else the HUD shows !lag_count). Up to 999. (Here as lag_tick until 2026-10-16.)

; -- Select + X during gameplay: the last room warp of the Warp Menu again (room_warp records the
; room in !rewarp_room; !warp_apply_settings is still the A / Y of that pick).
; Called from sa1_code (every_frame.asm, SA-1, as R+Start), keeps the register widths.
; room_warp runs on the SA-1 from the menu too (room_menu_pick); warp_to_level uses the direct
; page of the menu ($3766), the sound is played on the SNES as the menu does.
rewarp_hotkey:
    PHP
    REP #$30
    LDA !p1controller_hold
    AND.w #!btn_select
    BEQ .done
    LDA !p1controller_frame
    AND.w #!btn_x
    BEQ .done
    LDA.l !rewarp_valid             ; kept after power off: a new BW-RAM has garbage here
    CMP #!rewarp_valid_value
    BNE .done
    LDA.l !rewarp_room
    CMP #!room_count
    BCS .done
    LDA.l !reload_room_long         ; already loading a room
    AND #$00FF
    BNE .done
    LDA.l !is_paused_long           ; the pause screen does not load the room until it is closed
    AND #$00FF                      ; (the screen stayed black)
    BNE .done
    PHX
    PHY
    PHB
    PHD
    LDA #$3700
    TCD
    PEA $0000
    PLB
    PLB
    LDA.l !rewarp_room
    JSL room_warp
    REP #$30
    LDA.w #.sound_snes              ; the warp sound (warp_to_level sets it)
    LDX.w #bank(.sound_snes)
    JSL !sa1_executesnes
    REP #$30
    PLD
    PLB
    PLY
    PLX
    .done:
    PLP
    RTL

    .sound_snes:
    JSL !play_sfx_long
    RTL
