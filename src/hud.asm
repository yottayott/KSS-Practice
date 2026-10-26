; Custom HUD code

; Stuff for HUD in RAM:
; $7E0500 colors for all the background elements if you wanted to green screen or something
; $7E1520 HUD color palettes
; $7E1617 HUD tile art
; $7E16F7 HUD tile rotation

; -- Lives slot: the timer / RNG (see hud_slot_cpu in hud_timer.asm, $01F8A8)

; -- Display Timer
; Built in routine for displaying a double digit number for Gourmet Race timer
!display_number = $EF71

; Replace Score display routine with the following code
;ORG $01F938
;    timer_display:
;        TXA     ; Code before jumping to this routine will store the Score tile coordinate in X
;        STA $34 ; Transfer it to this temp variable as that's what the Gourmet Race routine update_tileset_kirby_pos
;        STZ $36
;        
;        ; Increment timer based on how many lag frames have occurred
;        ;LDX !active_frames
;        ;- JSR $EE52 ; Built in subroutine to calculate timer incrementation
;        ;DEX
;        ;BNE -

;        ; Above lag frame code is buggy so don't run it for now
;        JSR $EE52

;        ; Display numbers in HUD
;        SEP #$30
;        LDA !timer_minutes
;        LDY #$00
;        JSR !display_number
;        LDA !timer_seconds
;        LDY #$03
;        JSR !display_number
;        LDA !timer_milliseconds
;        LDY #$06
;        JSR !display_number
;        REP #$30
;        INC !write_to_HUD
;        RTS

; Replace GCO gold display with timer
;ORG $01F8DF
;    JSR timer_display
;    RTS

; Stop game from clearing the timer
;ORG $01F252
;    NOP
;    NOP
;    NOP