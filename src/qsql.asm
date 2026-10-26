; Save and Restore code
; DMA to VRAM could possibly be replaced with routine at $0087CB which loads tiles from WRAM (at least for autosaving)

!sfx_save_state = #$0C
!sfx_load_state = #$10
!sfx_room_reset = #$28

; !temp_stack_pointer_location and !screen_fade_from_savestate are in defines.asm
!music_from_savestate = $408FCA     ; current music RAM ($33CA) from the savestate data
!helper_ability_from_savestate = $40D8A1    ; current helper ability RAM ($74A1) from the savestate data
!ability_sfx_from_savestate = $4020AA    ; stores the ability sounds loaded in the state so that they will be reloaded properly

; !state_magic_value is in defines.asm

!apu_song_loaded = $00A8        ; WRAM, $00A8 = song and $00A9 = sample bank currently uploaded to the APU
!save_apu_song_loaded = $40FFB6

; Copy a block between WRAM and SRAM with DMA through the WRAM port ($2180).
; This is several times faster than MVN. Needs 8-bit A, 16-bit X/Y and DB in $00-$3F.
macro wram_dma(direction, wram, sram, size)
    LDX.w #(<wram>)&$FFFF
    STX $2181
    LDA.b #((<wram>)>>16)&$01
    STA $2183
    LDA.b #<direction>
    STA $4300
    LDA #$80
    STA $4301
    LDX.w #(<sram>)&$FFFF
    STX $4302
    LDA.b #(<sram>)>>16
    STA $4304
    LDX.w #<size>
    STX $4305
    LDA #$01
    STA $420B
endmacro

!dma_wram_to_sram = $80
!dma_sram_to_wram = $00

; SA-1 replacement for the wait loop inside the "run on S-CPU" routine ($008C6D).
; Every SA-1 frame ends in this loop while the S-CPU reads the controllers, which is
; exactly where savestates are taken. The SA-1 stack lives in I-RAM ($37FF) and is part of the
; savestate, but the stack pointer is a CPU register, so it is recorded here. When a state is
; loaded the recorded stack pointer is put back, otherwise the SA-1 returns through a stack
; from a different call depth (e.g. loading while paused) and crashes.
pushpc
ORG $008C93
    JML sa1_wait_for_snes
pullpc

sa1_wait_for_snes:
    PHP
    REP #$30
    PHA
    PHX
    PHY
    PHB
    PHD
    ; the end of a frame (it waits for the NMI anyway)
    LDA.l $00300C
    CMP #$8A56
    BNE .not_frame_end
    ; Kirby's "on the ground" flag is not updated while riding Wheelie, and mounting always hops,
    ; so it is 0 while riding. A warp or R+X while Kirby stands on the ground leaves it at 1
    ; (the game runs another frame before the room reloads), which lets Kirby turn in the air
    ; during a rider dash: keep it at 0 while riding (in the NMI until 2026-10-16).
    LDA.l !wheelie_rider_state_long
    AND #$00FF
    BEQ +
    LDA #$0000
    STA.l !kirby_on_ground_long
    +
    if !lag_baseline == 0
    JSL rng_count_sa1           ; the RNG count (rng_count.asm), before the HUDs draw it
    if !pb
    JSL pb_sa1                  ; the room PBs (pb.asm), before the HUDs draw the PB
    endif
    JSL hud_slot_sa1            ; the timer / RNG of the HUD (hud_timer.asm)
    if !detail_hud
    JSL detail_hud_sa1          ; the しょうさい HUD (detail_hud.asm)
    endif
    endif
    BRA +
    .not_frame_end:
    if !detail_hud
    CMP #$A2B3                  ; the game's HUD routine ($01A2B3 in the levels, $018078): the
    BEQ ++                      ; しょうさい HUD is drawn at the end of this frame
    CMP #$8078
    BNE +
    ++
    LDA.l $00300E
    CMP #$8001
    BNE +
    STA.l !detail_hud_ran
    endif
    +
    TSC
    STA.l !sa1_park_sp
    LDA #$0001
    STA.l !sa1_parked

    .loop:
        LDA.l !sa1_resume
        BNE .resume
        LDA.l $00300A       ; S-CPU wants the SA-1 to run something
        BMI .run_request
        LDA.l $00300E       ; S-CPU still busy with our request
        BMI .loop

        LDA #$0000
        STA.l !sa1_parked
        PLD
        PLB
        PLY
        PLX
        PLA
        PLP
        JML $008C9D         ; STZ $2209 : RTL

    .resume:
        ; a savestate was just loaded, switch to the stack pointer saved with it
        LDA #$0000
        STA.l !sa1_resume
        LDA.l !sa1_resume_sp
        TCS
        BRA .loop

    .run_request:
        ; same as the original code at $008CA1 / $008C8A
        LDA #$0000
        STA.l !sa1_parked   ; not idle while running the request
        STA.l $002209
        PHK
        PEA.w (.request_done-1)&$FFFF
        JML [$3008]
    .request_done:
        REP #$30
        LDA #$0000
        STA.l $00300A
        LDA #$0001
        STA.l $002209
        STA.l !sa1_parked
        BRA .loop

; Returns carry set if the SA-1 is waiting at the end of a frame in sa1_wait_for_snes,
; which is the only point where the SA-1 can safely be swapped to/from a savestate.
; Expects 16-bit A and DB = $00.
check_sa1_parked:
    LDA $3010           ; frame finished, waiting for this NMI
    BNE .no
    LDA.l !sa1_parked
    BEQ .no
    LDA $300C           ; the S-CPU request is the end of frame controller read
    CMP #$8A56
    BNE .no
    LDA $300E
    CMP #$8000
    BNE .no
    SEC
    RTS
    .no:
        CLC
        RTS

save_state:
    REP #$30
    JSR check_sa1_parked
    BCS +
    RTL
    +

    SEP #$30

    LDA !sfx_save_state          ;Sound effect played
    STA !current_sfx
    JSL !play_sfx

    JSR enable_vblank

    REP #$20
    TSC                     ; Transfer stack pointer
    STA !temp_stack_pointer_location
    LDA.l !sa1_park_sp      ; and the SA-1 stack pointer
    STA.l !state_sa1_sp

    SEP #$20
    REP #$10

    ; WRAM $7E0000-$7E1FFF to $402000-$403FFF
    %wram_dma(!dma_wram_to_sram, $7E0000, $402000, $2000)
    ; level data(?) in WRAM $7EB400-$7EFFFF to $404000-$408BFF
    %wram_dma(!dma_wram_to_sram, $7EB400, $404000, $4C00)
    ; current level layout in WRAM $7F0000-$7F2FFF to $409400-$40C3FF
    %wram_dma(!dma_wram_to_sram, $7F0000, $409400, $3000)

    .mvn_instructions:
        REP #$30

        ; Room Reload Data  ; Copy custom room reload data to another block directly next to it
        LDX.w #!room_reload_storage
        LDY.w #!room_reload_storage_state
        LDA #!reload_storage_size
        MVN $40,$40

        ; SA1
        LDX #$3000          ; Copy SA-1 IRAM $003000-$0037FF to $408C00-$4093FF
        LDY #$8C00
        LDA #$07FF
        MVN $40,$00

        ; SAVERAM
        LDX #$0000          ; Copy SaveRAM $400000-$401FFF to $40C400-$40E3FF
        LDY #$C400
        LDA #$1FFF
        MVN $40,$40

        ; the HUD timer (outside of the data above)
        LDX.w #!seg_timer_frac&$FFFF
        LDY.w #!seg_timer_saved&$FFFF
        LDA.w #!seg_timer_saved_size-1
        MVN $40,$40

        SEP #$20
        LDA #$00            ; Reset data bank
        PHA
        PLB

    .dma_instructions:
        LDA #$80        ; VRAM address goes up after the high byte ($2115 is not always $80
        STA $2115       ; here: hud_slot_upload. Set it before $2116, which starts the read)
        LDX #$0000      ; VRAM address
        STX $2116
        LDX #$0000      ; Destination offset
        STX $4302
        LDA #$41        ; Destination bank
        STA $4304
        LDX #$FFFF      ; # of bytes to copy
        STX $4305
        LDA #$39        ; read from $2139
        STA $4301
        LDA #$81        ; PPU -> CPU, write mode 1
        STA $4300
        LDA #$01
        STA $420B

    REP #$20
    LDA #!state_magic_value
    STA.l !state_magic

    JSR disable_vblank

    REP #$30
    RTL

; NOTE: this returns through the stack of the saved state, i.e. to the instruction after
; "JSL save_state" in nmi_code.
restore_state:
    REP #$30
    LDA.l !state_magic       ; nothing (valid) saved yet
    CMP #!state_magic_value
    BNE +
    JSR check_sa1_parked
    BCS ++
    + RTL
    ++

    SEP #$30

    LDA !sfx_load_state          ;Sound effect played
    STA !current_sfx
    JSL !play_sfx

    JSR enable_vblank

    REP #$20
    LDA !temp_stack_pointer_location                 ; Restore stack pointer
    TCS

    .restore_music
        SEP #$20
        LDA !music_from_savestate
        CMP !current_music
        BEQ +
        STA !current_music
        JSL !load_music
        +

    ; keep the sound state that is currently loaded in the APU
    LDA !sound_buffer
    STA !save_sound_buffer
    LDA !sound_bank_1
    STA !save_sound_bank_1
    REP #$20
    LDA !sound_bank_2     ; make sure sound banks are reloaded if they are different
    STA !save_sound_bank_2
    LDA !apu_song_loaded  ; song / sample bank that is really in the APU right now
    STA !save_apu_song_loaded

    .restore_helper_graphics
        ; Restore helper graphics from the previous savestate
        SEP #$30
        LDA !is_shooting    ; if in nova shmup, ignore this completely
        BNE .merge

        ; BUG : Reloading a different helper in Fatty Whale boss fight locks the game
        LDA !helper_ability_from_savestate
        BEQ .merge
        CMP #$FF    ; if there wasn't a helper in the last state don't do anything
        BEQ .merge

        CMP !helper_ability
        BEQ .merge

        ; the helper number was loaded with 8-bit A, so the high byte still holds whatever
        ; was loaded before (e.g. $00A9). assign_helper_data uses all 16 bits as an index and
        ; a garbage value makes it wait for VRAM queue space forever (NMI is off -> black screen)
        REP #$30
        AND #$00FF
        LDX #$0004
        LDY #$0004
        JSL !assign_helper_data

        .merge
            REP #$30

    .restore_ram
        ; Restore savestate from SRAM

        JSR compare_level_data

        ; SA1
        LDX #$8C00          ; Copy $408C00-$4093FF to SA-1 IRAM $003000-$0037FF
        LDY #$3000
        LDA #$07FF
        MVN $00,$40

        ; The SA-1 stack now holds the loaded state, so switch the SA-1 to the stack pointer
        ; saved with it right away, before the routines below can make the SA-1 run code and
        ; push onto that stack from the old position. The SA-1 is spinning and answers at once.
        LDA.l !state_sa1_sp
        STA.l !sa1_resume_sp
        LDA #$0001
        STA.l !sa1_resume
        LDX #$0000
        - LDA.l !sa1_resume
        BEQ +
        DEX                 ; give up after a while instead of hanging
        BNE -
        +

        LDA !screen_fade
        STA !screen_fade_from_savestate

        JSR restore_level_data

        SEP #$20
        LDA #$00            ; game routines above may leave a different data bank
        PHA
        PLB
        REP #$20

        LDA !screen_fade_from_savestate
        STA !screen_fade

        SEP #$20
        ; WRAM $7E0000-$7E1FFF from $402000-$403FFF
        %wram_dma(!dma_sram_to_wram, $7E0000, $402000, $2000)
        ; level data(?) in WRAM $7EB400-$7EFFFF from $404000-$408BFF
        %wram_dma(!dma_sram_to_wram, $7EB400, $404000, $4C00)
        ; current level layout in WRAM $7F0000-$7F2FFF from $409400-$40C3FF
        %wram_dma(!dma_sram_to_wram, $7F0000, $409400, $3000)
        REP #$20

        ; Room Reload Data  ; Copy custom room reload data to another block directly next to it
        LDX.w #!room_reload_storage_state
        LDY.w #!room_reload_storage
        LDA #!reload_storage_size
        MVN $40,$40

        ; SAVERAM
        LDX #$C400          ; Copy $40C400-$40E3FF to SaveRAM $400000-$401FFF
        LDY #$0000
        LDA #$1FFF
        MVN $40,$40

        ; the HUD timer as it was at the save (no restart, a pending warp RNG is cancelled)
        LDX.w #!seg_timer_saved&$FFFF
        LDY.w #!seg_timer_frac&$FFFF
        LDA.w #!seg_timer_saved_size-1
        MVN $40,$40
        LDA #$0000
        STA.l !seg_timer_reset
        STA.l !seg_pending_rng_flag
        STA.l !seg_room_door
        LDA.l !room_number_long     ; the room of the loaded state
        AND #$00FF
        STA.l !seg_timer_room
        JSL room_loop_capture       ; and its entry, for the room loop (segment_timer.asm)
        if !pb
        LDA #$0001                  ; this room's run does not count for the PB (pb.asm)
        STA.l !pb_dirty
        endif

        SEP #$20
        LDA #$00            ; Reset data bank
        PHA
        PLB
        REP #$20

        LDA #$FFFF
        STA $3000           ; SA-1 "running" flag, must stay $FFFF

        LDA #$0001
        STA $7E04B1         ; Temporary value for DMA writes to the tileset. Clearing so this doesn't make glitchy graphics on load.

        .restore_vram:
        SEP #$20
        LDA #$80        ; VRAM address goes up after the high byte (see save_state)
        STA $2115
        LDX #$0000
        STX $2116
        LDX #$0002      ;Source Offset into source bank
        STX $4302       ;Set Source address lower 16-bits
        LDA #$41        ;Source bank
        STA $4304       ;Set Source address upper 8-bits
        LDX #$FFFF      ;# of bytes to copy
        STX $4305       ;Set DMA transfer size
        LDA #$18        ;$2118 is the destination, so
        STA $4301       ;  set lower 8-bits of destination to $18
        LDA #$01        ;Set DMA transfer mode: auto address increment
        STA $4300       ;  using write mode 1 (meaning write a word to $2118/$2119)
        LDA #$01        ;The registers we've been setting are for channel 0
        STA $420B       ;  so Start DMA transfer on channel 0 (LSB of $420B)

    LDA #$01            ; the timer / RNG of the HUD: all 7 tiles again (hud_timer.asm)
    STA.l !hud_slot_force

    JSR disable_vblank

    LDA !save_sound_buffer          ; apply previous sound buffer so consecutive sound plays
    STA !sound_buffer
    LDA !save_sound_bank_1
    STA !sound_bank_1

    REP #$30
    LDA !save_sound_bank_2
    STA !sound_bank_2
    LDA !save_apu_song_loaded
    STA !apu_song_loaded

    RTL


; Load all of the level data from the previous state
; Routines for loading in level tileset/background/etc:
; $0183CA - background graphics
; $0184DE - consumables (food)
; $018698 - tile data
; $018678 - level tileset

!room_graphics = $0032F6
!room_graphics_state = $408EF6

; using random spots in WRAM for these because they're temporary and we're loading the state anyway
!current_fatty_whale = $000300
!state_fatty_whale = $000302
!current_background = $000304
!state_background = $000306
!current_tileset = $000308
!state_tileset = $00030A

compare_level_data:
    ; this routine is purely meant for saving values so that later we could see if we actually need to load them in
    ; having these values load in on every state load is redundant and makes loads extremely slow
    ; this verifies that we only load the level graphics if we actually need them

    ; see if fatty whale is in the current room
    SEP #$30
    LDA !subgame
    LDX !room_number
    JSR check_fatty_whale
    STA !current_fatty_whale

    ; store current room graphics
    LDA.w !room_graphics+2
    PHA
    PLB
    REP #$20

    LDA !room_graphics
    TAX

    LDA $001D,X
    STA !current_background

    LDA $001B,X
    STA !current_tileset

    ; store state room graphics
    SEP #$20
    LDA !room_graphics_state+2
    PHA
    PLB
    REP #$20

    LDA !room_graphics_state
    TAX

    LDA $001D,X
    STA !state_background

    LDA $001B,X
    STA !state_tileset

    SEP #$20
    LDA #$00
    PHA
    PLB   ; Set data bank back to zero (this is what the original routine uses)
    REP #$30

    RTS

restore_level_data:
    .prepare_level_restore
        LDA #$8000      ; Prevents an infinite loop when loading background data
        STA !screen_fade

        ; check fatty whale status
        SEP #$30
        LDA !subgame
        LDX !room_number
        JSR check_fatty_whale
        STA !state_fatty_whale
        BNE .reload_background  ; skip consumables reload if Fatty Whale exists

    .reload_consumables
        ; always run (unless fatty whale check skips it), it doesn't waste many cycles and there are some edge cases that are impractical to check for
        ; ironically enough it's probably a good thing this runs because then the state would load too quickly
        REP #$30
        JSL load_consumables

    .reload_background
        REP #$30
        LDA.w !state_background
        CMP.w !current_background
        BEQ .reload_tileset
        JSL load_background

    .reload_tileset
        LDA.w !state_tileset
        CMP.w !current_tileset
        BEQ .end_level_restore
        JSL load_tileset

    ; Load Fatty Whale last so we ensure its graphics always override the buffer
    .reload_fatty_whale
        SEP #$30
        LDA !state_fatty_whale
        BNE .load_fatty_whale_room
        BRA .end_level_restore

        .load_fatty_whale_room
            ; see if we are already in a room where Fatty Whale graphics are loaded, so we don't need to reload them again.
            LDA !current_fatty_whale
            BNE .end_level_restore
            REP #$30
            JSL $D52924
    
    .end_level_restore
        REP #$30
        RTS

    pushpc
    ; writing code in bank 01 so that short jumps can be performed in the same bank as the built-in routines
    ORG $01FFE0
        load_consumables:
            JSR $84DE
            RTL
        load_background:
            JSR $83CA
            RTL
        load_tileset:
            JSR $8678
            RTL
    pullpc

check_fatty_whale:
    ; check subgame
    CMP #$03
    BEQ .gco
    CMP #$05
    BEQ .mww
    CMP #$06
    BEQ .arena
    BRA .false

    .gco
    CPX #$37
    BEQ .true
    BRA .false

    .mww
    CPX #$08
    BEQ .true
    BRA .false

    .arena
    CPX #$09
    BEQ .true
    BRA .false

    .true
        LDA #$01
        RTS

    .false
        LDA #$00
        RTS

; Save stuff such as HP, ability, invincibility timer, RNG, etc.
auto_save_on_room_load:
    SEP #$10
    REP #$20

    ; ability info
    LDA !ability
    STA !store_ability
    LDA !helper_ability
    STA !store_helper_ability
    LDA !wheelie_rider_state
    STA !store_wheelie_rider_state

    ; health
    LDA !kirby_hp 
    STA !store_kirby_hp 
    LDA !helper_hp 
    STA !store_helper_hp 

    ; items
    LDA !lives_collected
    STA !store_lives_collected
    LDA !tomatoes_collected
    STA !store_tomatoes_collected
    LDA !romk_cutscenes_done
    STA !store_romk_cutscenes
    LDA !romk_cutscenes_done+2
    STA !store_romk_cutscenes+2

    ; mww abilities
    LDA !mww_ability_data_1
    STA !store_abilities_1
    LDA !mww_ability_data_2
    STA !store_abilities_2
    LDA !mww_last_ability_selected
    STA !store_last_ability_selected

    ; invincibility status 
    LDA !kirby_invincible
    STA !store_kirby_invincibility_state
    LDA !kirby_invincible_time
    STA !store_kirby_invincibility_timer
    LDA !kirby_speed
    STA !store_kirby_speed
    LDA !kirby_inv_flash
    STA !store_kirby_flashing

    LDA !helper_invincible
    STA !store_helper_invincibility_state
    LDA !helper_invincible_time
    STA !store_helper_invincibility_timer
    LDA !helper_speed
    STA !store_helper_speed
    LDA !helper_inv_flash
    STA !store_helper_flashing
    
    ; audio
    LDA !current_ability_sfx
    STA !store_ability_sfx

    LDA !current_music
    STA !store_music

    LDA !RNG
    STA !store_RNG

    STZ !is_reloading_room
    RTS

; Reload saved values when room is reloaded
restore_on_room_restart:
    SEP #$30

    STZ !toggle_free_move

    LDA #$01
    STA !active_frames  ; avoid game hanging if room is reset while loading something else

    .check_wheelie_rider
        LDA !store_wheelie_rider_state
        STA !wheelie_rider_state 
        BEQ .restore_kirby_ability    ; if it equals #$0000 then we don't need to do anything special

        LDA !store_ability
        STA !ability
        STZ $36C8       ; address used for tracking if swimming. needs to be cleared or game will crash
        STZ !helper_ability+1   ; clear this byte so that it isn't #$FF if it is
        REP #$20
        LDA #$0042    ; riding action of Kirby and Wheelie, otherwise Kirby moves as if not riding
        STA $7493     ; after getting off and reloading the room
        STA $7495
        STZ $36EC     ; Kirby's "on the ground" flag: not updated while riding, 1 lets Kirby turn in the air
        SEP #$20
        LDA #$0D      ; Wheel ability (for Wheelie). Forcing this here because you'd only be riding on Wheelie.
        BRA .reload_helper

    .restore_kirby_ability
        REP #$30
        LDA !store_ability
        CMP !ability
        BEQ +
        LDY #$0002          ; same as quick_select_ability (that one is in another bank)
        JSL !assign_ability_data
        +

    .restore_helper_ability
        LDA !store_helper_ability
        CMP !helper_ability
        BEQ .no_change
        CMP #$FFFF
        BEQ .unload_helper

    .reload_helper
        STZ $7496       ; address used to store helper state, but if it's #$FFFF then the helper ability will reset
        STA !helper_ability
        BRA .skip
    
    .unload_helper
        LDA #$FFFF
        STA !helper_ability
        STA $62C0
        BRA .skip
    
    .no_change
        STZ $7496       ; Reset this to eliminate edge cases where it could be FFFF so that helper respawns

    .skip

    REP #$30

    ; health
    LDA !store_kirby_hp
    STA !kirby_hp
    LDA !store_helper_hp 
    STA !helper_hp

    ; items
    LDA !store_lives_collected
    STA !lives_collected
    LDA !store_tomatoes_collected
    STA !tomatoes_collected
    LDA !store_romk_cutscenes
    STA !romk_cutscenes_done
    LDA !store_romk_cutscenes+2
    STA !romk_cutscenes_done+2

    ; mww abilities
    LDA !store_abilities_1
    STA !mww_ability_data_1
    LDA !store_abilities_2
    STA !mww_ability_data_2
    LDA !store_last_ability_selected
    STA !mww_last_ability_selected

    ; invincibility status 
    LDA !store_kirby_invincibility_state
    STA !kirby_invincible
    LDA !store_kirby_invincibility_timer
    BEQ +
    ; room reload subtracts $5A from this value, so we re-add it here.
    ; if timer value is $00 then don't add anything
    CLC
    ADC #$005A
    + STA !kirby_invincible_time
    LDA !store_kirby_speed
    STA !kirby_speed
    LDA !store_kirby_flashing
    STA !kirby_inv_flash

    LDA !store_helper_invincibility_state
    STA !helper_invincible
    LDA !store_helper_invincibility_timer
    BEQ +
    CLC
    ADC #$005A
    + STA !helper_invincible_time
    LDA !store_helper_speed
    STA !helper_speed
    LDA !store_helper_flashing
    STA !helper_inv_flash
    
    ; audio: the ability sounds in the APU as when the room was entered. Getting an ability
    ; uploads its sound bank unless it is the one in $AA, which made the freeze 10 frames
    ; shorter after R+X / the room loop (2026-10-10). Writing $AA alone would play wrong sounds
    ; after another ability was got in the room: upload the bank ($00D2AE: A = bank, Y = slot 0,
    ; DB = $00). Bank 0 is no bank (its pointer is not ROM): nothing loaded, the next ability loads.
    SEP #$30
    LDA !store_ability_sfx
    CMP !current_ability_sfx
    BEQ .sfx_done
    CMP #$00
    BNE +
    STZ !current_ability_sfx
    BRA .sfx_done
    +
    ; the upload takes about 11 frames: no NMI meanwhile (this runs in the NMI; R+X has already
    ; disabled it, the room loop enables it again after room_loop_restore)
    STZ $4200
    PHB
    PHA
    LDA #$00
    PHA
    PLB
    PLA
    LDY #$00
    JSL $00D2AE                     ; returns with REP #$30
    SEP #$30
    PLB
    LDA $4210                       ; clear the NMI flag of the frames it took
    .sfx_done:

    SEP #$20
    REP #$10
    ; don't load new music if it is boss music (the music gets reloaded anyway)
    ; this is only really intended for invincibility candy
    LDA !current_music
    CMP #$05
    BEQ .skip_music_load
    CMP #$06
    BEQ .skip_music_load
    LDA !store_music
    CMP !current_music
    BEQ .skip_music_load
    STA !current_music
    JSL !load_music

    .skip_music_load
    REP #$30

    LDA !store_RNG
    STA !RNG

    ; STZ !is_reloading_room
    RTS

restore_current_room:   

    SEP #$20

    INC !is_reloading_room
    
    LDA !reload_room
    CMP #$00
    BNE .break              ; if already reloading, don't do it again
    LDA !game_mode          ; checking multiple game modes to make sure we are in an actual level
    CMP #$03                ; check if in a normal level
    BEQ .load_room
    CMP #$09                ; check if in Goal Game
    BEQ .load_room
    CMP #$0C                ; check if in The Arena
    BEQ .load_room
    CMP #$0D                ; check if in Dyna Blade Trial Room
    BEQ .load_room
    CMP #$0E                ; check if fighting Iron Ma'am 
    BEQ .load_room
    BRA .break

    .load_room:

        JSR enable_vblank

        SEP #$30
        LDA !sfx_room_reset
        STA !current_sfx
        JSR .reload_saved_values

        JSL !play_sfx
        SEP #$20
        INC !reload_room        ; tell game to reload the room
        STZ !screen_fade        ; reset screen fade so it fades back in after respawn
        STZ !screen_brightness  ; turn screen dark

        LDA !replay_cutscene
        CMP #$01                ; check if in first room in level
        BNE .break
        STZ !replay_cutscene    ; replay beginning room cutscene if it exists

        LDA #$20
        STA !QSQL_timer     ; Set amount of frames until next QSQL is allowed

    .break:
        REP #$30
        RTL

    .reload_saved_values:
        ; If holding L, do not reload stored values and instead store new ones
        REP #$30
        LDA !p1controller_hold
        AND #$0020
        CMP #$0020
        BEQ +
        JSR restore_on_room_restart
        BRA ++
        + JSR auto_save_on_room_load
        ++ SEP #$30
        RTS

enable_vblank:

    SEP #$20

    STZ $4200           ; Disable NMI
    STZ $420C           ; Disable HDMA

    - LDA $4212
    BPL -

    LDA #$80
    STA $2100           ; Force blank
    RTS

disable_vblank:

    SEP #$20

    - LDA $4212
    BPL -

    LDA $4210           ; Clear NMI flag

    LDA #$81
    STA $4200           ; NMI enable
    LDA #$A8 
    STA $4209           ; Set IRQ hblank period so HUD displays correctly
    LDA #$0F 
    STA $2100           ; Exit force blank
    LDA #$0A
    STA !QSQL_timer     ; Set amount of frames until next QSQL is allowed
    RTS

; room loop (room_loop_check, NMI): the values of R+X, the game itself reloads the room
room_loop_restore:
    SEP #$20
    INC !is_reloading_room          ; do not save the values again on this load
    JSR restore_on_room_restart
    REP #$30
    RTL

; D2E2 subroutine that loads ability sfx 

; L + R + B during gameplay: room loop on / off (also the top items of the main menu), with a
; sound: the one of getting an ability for on, the menu's "back" for off.
; Called from every_gameplay_frame (SA-1), keeps the register widths.
room_loop_hotkey:
    PHP
    REP #$30
    LDA !p1controller_hold
    AND #$0030
    CMP #$0030
    BNE .done
    LDA !p1controller_frame
    BIT #!btn_b
    BEQ .done
    PHX
    PHY
    LDA.l !room_loop_on
    EOR #$0001
    STA.l !room_loop_on
    SEP #$20
    BEQ +
    LDA #$44                ; on
    BRA ++
    +
    LDA #$28                ; off
    ++
    STA.l !current_sfx_long
    REP #$20
    LDA.w #.on_snes
    LDX.w #bank(.on_snes)
    JSL !sa1_executesnes
    REP #$30
    PLY
    PLX
    .done:
    PLP
    RTL
    .on_snes:
    JSL !play_sfx_long
    RTL
