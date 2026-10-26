
; Room warps (all rooms of the Any% route): warp to a room, then set the abilities and the RNG
; of the Warp Settings (A in the room list) or leave them as they are (Y).
; The room table is generated from a recording of a run (tools/make_room_list.py) and lives in
; bank $06; warp_to_level reads it with the data bank in !warp_table_bank.

; One entry per room, !room_entry_size bytes:
;   +$00  room (8-bit), level (8-bit), room entry type, x, y   (the warp_to_level layout)
;         entry type: 0 = the room's own entrance (level start, Warp Star), 1 = its start position,
;         2 = door at x/y
;   +$08  subgame
;   +$0A  flags: bit 1 = starts in the shooting section
!room_entry_size = $000C
!room_flag_shooting = $0002
!helper_full_health = $0046        ; a helper spawned without a helper before had 0 HP and died
!rider_action = $0042               ; action of Kirby and Wheelie while riding (see $1EE039 / $21FB1D)
!seg_no_helper = $FFFF

macro room(room, level, entry, x, y, subgame, flags)
    db <room>, <level>
    dw <entry>, <x>, <y>, <subgame>, <flags>
endmacro

!gco = $0003
!dyna = $0001
!romk = $0004
!mww = $0005
!wheelie = $000D

; ability presets of the Warp Settings (1-4; 0 = don't set, 5 = custom): ability, helper, rider
warp_ability_presets:
    dw $0000, !seg_no_helper, $0000     ; 0 (not used)
    dw $0000, !seg_no_helper, $0000     ; 1 Normal
    dw $0007, !seg_no_helper, $0000     ; 2 Jet
    dw $0012, !wheelie,       $0001     ; 3 Hammer + riding Wheelie
    dw $000C, !seg_no_helper, $0000     ; 4 Plasma

; RNG presets (1-3; 0 = don't set, 4 = custom), as shown on the HUD: low byte first
warp_rng_presets:
    dw $0000, $BDDD, $0D76, $051F       ; -, 221 189 (after a reset), 118 013 (after Fatty Whale), 031 005 (after Crash)

; A = room number. Runs on the SA-1 from the practice menu.
; !warp_apply_settings: 1 = set the abilities and the RNG of the Warp Settings, 0 = don't.
room_warp:
    REP #$30
    STA.l !rewarp_room              ; for Select + X (extras.asm)
    PHA
    LDA #!rewarp_valid_value
    STA.l !rewarp_valid
    PLA
    if !pb
    ; the room PB: a new run from the warp (the room is found when the timer starts, pb.asm)
    PHA
    LDA #$0000
    STA.l !pb_exit
    STA.l !pb_door_kind
    PLA
    endif
    ; free movement off, as R+X and a death do: the room load puts Kirby's collision routine
    ; ($633E) back, but the flag stayed on, so Kirby moved fast and could be hit
    PHA
    SEP #$20
    LDA #$00
    STA.l !toggle_free_move_long
    STA.l !intangible_to_items_long
    REP #$20
    PLA
    ; X = A * 12
    ASL A
    ASL A
    STA.l !seg_temp
    ASL A
    CLC
    ADC.l !seg_temp
    TAX

    LDA.l room_table+$08,X
    STA.l !custom_menu_subgame_warp
    ; RoMK: the messages as in a new game (2026-10-21, the user: back to the first room of the
    ; segment with Select + X, its message did not show). $771D-$771F are bits of the messages
    ; seen, kept for the whole game (e.g. bit 5 of $771D = the first room of Meta Knight 3)
    CMP #!romk
    BNE +
    LDA #$0000
    STA.l $00771D
    STA.l $00771E
    +

    LDA #$0000
    STA.l !seg_pending_rider
    LDA.l !warp_apply_settings
    BNE +
    JMP .abilities_done
    +
    JSR warp_resolve_ability
    LDA.l !warp_ability_preset
    BNE +
    JMP .mww_essence
    +
    LDA.l !warp_res_rider
    BEQ .not_riding

    ; riding Wheelie: same as restore_on_room_restart, the room load sets it up
    SEP #$20
    LDA #$01
    STA.l !wheelie_rider_state_long
    LDA.l !warp_res_ability
    STA.l !ability_long
    LDA #$00
    STA.l $0036C8                   ; swimming flag, has to be clear or the game crashes
    STA.l !helper_ability_long+1
    STA.l $007496
    LDA.l !warp_res_helper
    STA.l !helper_ability_long
    REP #$20
    LDA #!rider_action
    STA.l !kirby_action_long
    STA.l !helper_action_long
    LDA #!helper_full_health
    STA.l !helper_hp_long
    LDA #$0001
    STA.l !seg_pending_rider
    ; Kirby's "on the ground" flag is not updated while riding: mounting always hops, so it is 0,
    ; but here Kirby may stand on the ground and 1 lets Kirby turn in the air during a rider dash
    LDA #$0000
    STA.l !kirby_on_ground_long
    BRA .mww_essence

    .not_riding:
    SEP #$20
    LDA #$00
    STA.l !wheelie_rider_state_long
    REP #$20

    LDA.l !warp_res_ability
    CMP.l !ability_long
    BEQ .helper
    ; same as quick_select_ability / restore_on_room_restart while in a level,
    ; outside of a level only change the value and let the level load it
    PHA
    LDA.l !game_mode_long
    AND #$00FF
    CMP #$0003
    BNE .set_ability_value
    PLA
    PHX
    LDY #$0002
    JSL !assign_ability_data
    REP #$30
    PLX
    BRA .helper
    .set_ability_value:
    PLA
    STA.l !ability_long

    .helper:
    ; same as restore_on_room_restart, the helper appears when the room loads
    LDA.l !warp_res_helper
    CMP #!seg_no_helper
    BEQ .no_helper
    STA.l !helper_ability_long
    LDA #$0000
    STA.l $007496
    LDA #!helper_full_health
    STA.l !helper_hp_long
    BRA .mww_essence
    .no_helper:
    LDA.l !helper_ability_long
    CMP #!seg_no_helper
    BEQ .mww_essence
    LDA #!seg_no_helper
    STA.l !helper_ability_long
    STA.l $0062C0

    .mww_essence:
    ; X on MWW starts from the first copy essence, like when a planet is entered (see $03A1D8)
    LDA #$0000
    STA.l !mww_last_ability_selected_long
    .abilities_done:

    ; the shooting section is set up by the MWW map ($159E37), set it here instead
    LDA.l room_table+$0A,X
    AND #!room_flag_shooting
    BEQ +
    LDA #$0001
    +
    STA.l !is_shooting_long

    ; RNG: set on the first lit frame, when the timer starts (segment_timer_tick)
    LDA #$0000
    STA.l !seg_pending_rng_flag
    STA.l !custom_menu_apply_rng        ; drop an RNG queued from the RNG menu
    LDA.l !warp_apply_settings
    BEQ .rng_done
    LDA.l !warp_rng_preset
    BEQ .rng_done
    CMP #$0004
    BCC +
    LDA.l !warp_custom_rng
    BRA ++
    +
    PHX
    ASL A
    TAX
    LDA.l warp_rng_presets,X
    PLX
    ++
    STA.l !seg_pending_rng
    LDA #$0001
    STA.l !seg_pending_rng_flag
    .rng_done:

    LDA.w #bank(room_table)
    STA.l !warp_table_bank
    PHX
    TXA
    CLC
    ADC.w #room_table
    JSL warp_to_level
    REP #$30
    PLX

    ; MWW copy essences, Any% (and Any% Plasma): warp_to_level puts in the ones of the start of
    ; the planet; the route takes Jet in room 3 of Milky Way 1 and Hammer in room 2 of Milky
    ; Way 4, so the rooms after those have them too (2026-10-08, the user)
    SEP #$20
    LDA.l !mww_ability_route_long
    BEQ .mww_done
    CMP #$03
    BCS .mww_done
    CPX.w #($0057+3)*!room_entry_size   ; Milky Way 1, room 4 -
    BCC .mww_done
    CPX.w #$005F*!room_entry_size
    BCS +
    LDA #$08                        ; Jet
    STA.l !abilities_saved_2_long
    LDA #$01
    STA.l !number_of_abilities_long
    BRA .mww_done
    +
    CPX.w #($0068+2)*!room_entry_size   ; Milky Way 4, room 3 -
    BCC .mww_done
    CPX.w #$006C*!room_entry_size
    BCS .mww_done
    LDA.l !abilities_saved_1_long
    BIT #$40
    BNE .mww_done
    ORA #$40                        ; Hammer
    STA.l !abilities_saved_1_long
    LDA.l !number_of_abilities_long
    INC A
    STA.l !number_of_abilities_long
    .mww_done:
    REP #$30
    ; the ability sounds in the APU: the ones of Kirby's ability (S-CPU)
    LDA.w #warp_ability_sfx
    LDX.w #bank(warp_ability_sfx)
    JSL !sa1_executesnes
    REP #$30
    RTL

; S-CPU (through !sa1_executesnes from room_warp), during the warp's fade, before the room load
; keeps $AA for R+X (2026-10-10, the user). Getting an ability uploads its sound bank to the
; APU unless it is already there ($AA), which makes the freeze about 10 frames longer: after a
; warp it depended on what was got before the warp. Now the bank of Kirby's ability is there, as
; in a run where Kirby got that ability (the user's choice), and none for no ability. The same
; as the game ($03A28D: bank = $03A29B[ability]; $00D29E: slot = $DDFFDC[bank], 1 -> 0;
; $00D2E2 uploads unless $AA,slot already has it).
warp_ability_sfx:
    PHP
    PHB
    SEP #$30
    LDA #$00
    PHA
    PLB
    LDA.l !ability_long
    CMP #$19                        ; (the table has the 25 abilities $00-$18)
    BCS ++
    TAX
    LDA.l $03A29B,X
    BNE +
    ++
    LDA #$00
    STA.w !current_ability_sfx      ; no ability: no bank (the next ability loads)
    BRA .done
    +
    TAX
    LDA.l $DDFFDC,X
    CMP #$01
    BNE +
    LDA #$00
    +
    TAY
    TXA
    JSL $00D2AE                     ; PHD, D = 0, JSR $D2E2, PLD, REP #$30
    .done:
    PLB
    PLP
    RTL

; The ability preset (or the custom choice) -> !warp_res_ability / _helper / _rider. Keeps X.
warp_resolve_ability:
    PHX
    LDA.l !warp_ability_preset
    CMP #$0005
    BCC .preset
    ; custom: helper from the helper list, riding only with Wheelie
    LDA.l !warp_custom_ability
    STA.l !warp_res_ability
    LDA.l !warp_custom_helper
    ASL A
    TAX
    LDA.l warp_helper_choices,X
    STA.l !warp_res_helper
    CMP #!wheelie
    BEQ +
    LDA #$0000
    BRA ++
    +
    LDA.l !warp_custom_rider
    ++
    STA.l !warp_res_rider
    PLX
    RTS
    .preset:
    ; X = preset * 6
    ASL A
    STA.l !seg_temp
    ASL A
    CLC
    ADC.l !seg_temp
    TAX
    LDA.l warp_ability_presets,X
    STA.l !warp_res_ability
    LDA.l warp_ability_presets+2,X
    STA.l !warp_res_helper
    LDA.l warp_ability_presets+4,X
    STA.l !warp_res_rider
    PLX
    RTS

; helpers the custom setting can choose (index 0 = no helper)
warp_helper_choices:
    dw !seg_no_helper
    dw $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A
    dw $000B, $000C, $000D, $000E, $000F, $0010, $0012, $0013

; Puts the default Warp Settings in (first boot, or when !warp_settings_magic_value changes)
warp_settings_defaults:
    PHP
    REP #$30
    LDA #$0001
    STA.l !warp_ability_preset          ; Normal
    STA.l !warp_rng_preset              ; 221 189
    LDA #$0000
    STA.l !warp_custom_ability
    STA.l !warp_custom_helper
    STA.l !warp_custom_rider
    LDA #$BDDD
    STA.l !warp_custom_rng
    SEP #$20
    LDA #$01
    STA.l !mww_ability_route_long       ; ぎんが のうりょく: Any%
    REP #$20
    LDA #!warp_settings_magic_value
    STA.l !warp_settings_magic
    PLP
    RTL

; Kirby's setup when a sub-game starts (warping from the title screen or another sub-game)
; clears the Wheelie riding flag: keep it for a room warp that rides Wheelie.
pushpc
org $03A116
    JSL warp_kirby_init_riding   ; was STZ $7569 : JSL $03A25E
    NOP #3
pullpc

warp_kirby_init_riding:
    LDA.l !seg_pending_rider
    STA.l !wheelie_rider_state_long
    JSL $03A25E
    RTL
