; The room PBs (2026-10-15, the user): the best time of each room of the route (room_table), kept
; after power off, shown on the timer HUD (a row next to the timer, hud_timer.asm) and the しょうさい
; HUD (PB, detail_hud.asm), and in the segment lists of the Warp Menu (Select clears the PB of the
; room shown, the main menu's じこベスト けす all of them).
;
; A time counts only for a run of the room through the route:
; - in: the room is found in room_table by how it was entered ($32EA / $32EE / $32F2, the entry
;   type $332A and for a door its position $330C / $3310, as tools/make_room_list.py took them),
;   on the first lit frame (the timer's 0:00.00). Entering it by another door (back the way the
;   route came) finds nothing: no PB is shown, nothing is kept.
; - out: the next room of the route (the door goes there: !pb_door_*, also with the room loop; or
;   the room found next is the next one), or the end of the level for the last room of a level
;   (a door to $7FFF, or the game leaves the level: $7390 is not 3 any more).
; - not: free movement or an ability hotkey in the run, a state load, Kirby's HP 0 when the screen
;   started to fade. (L+R+X counts since 2026-10-25, the user.)
; The time is the one the HUD keeps at the door (the fade starts, !seg_split_*).
;
; Lag (2026-10-15, the user: as little as possible): the NMI only sets flags (!pb_exit when the
; fade starts, !pb_start on the first lit frame), the door routine notes where it goes; all the
; rest is done by the SA-1 at the end of its frame, while it waits for the NMI anyway (pb_sa1).
;
; BW-RAM bank $42 (the header asks for 256 KB since 2026-10-15). pb_boot_check makes sure it is
; there and not a mirror of bank $40 (128 KB: then !pb_ok stays 0 and nothing of this runs).

; at power on (init, 16-bit A). Keeps X / Y.
pb_boot_check:
    PHP
    REP #$20
    LDA #$0000
    STA.l !pb_ok
    STA.l $40E4FE                   ; (the menu's VRAM backup: free while the menu is closed)
    LDA #$5AA5
    STA.l $42E4FE
    LDA.l $40E4FE
    BNE .done                       ; bank $42 is bank $40 again
    LDA.l $42E4FE
    CMP #$5AA5
    BNE .done                       ; nothing there
    LDA #$0001
    STA.l !pb_ok
    LDA.l !pb_magic
    CMP #!pb_magic_value
    BEQ +
    JSL pb_clear_all                ; the first time
    LDA #!pb_magic_value
    STA.l !pb_magic
    +
    LDA #$FFFF
    STA.l !pb_room
    LDA #$0000
    STA.l !pb_dirty
    STA.l !pb_exit
    STA.l !pb_start
    STA.l !pb_door_kind
    .done:
    LDA #$FFFE
    STA.l !hud_pb_shown
    PLP
    RTL

; all the PBs cleared (16-bit A)
pb_clear_all:
    PHP
    REP #$30
    PHX
    LDA #$FFFF
    LDX.w #!room_count*2-2
    -
    STA.l !pb_table,X
    DEX
    DEX
    BPL -
    PLX
    PLP
    RTL

; A = the PB of the room of this attempt, $FFFF none (16-bit A/X)
pb_current:
    LDA.l !pb_room
    BMI .none
    ASL A
    TAX
    LDA.l !pb_table,X
    RTL
    .none:
    LDA #$FFFF
    RTL

; menu (segment lists): A = segment -> X = the room shown next to it (room_table). 16-bit A/X.
pb_seg_room:
    TAX
    LDA.l !room_pick,X
    AND #$00FF
    PHA
    TXA
    ASL A
    TAX
    PLA
    CLC
    ADC.l room_seg_first,X
    TAX
    RTL

; menu: A = segment -> A = the PB of the room shown next to it ($FFFF none). 16-bit A/X.
pb_seg_value:
    PHX
    TAX
    LDA.l !pb_ok
    BNE +
    LDX.w #$FFFF
    BRA ++
    +
    TXA
    JSL pb_seg_room
    TXA
    ASL A
    TAX
    LDA.l !pb_table,X
    TAX
    ++
    TXA
    PLX
    RTL

; menu, Select in a segment list: A = segment, the PB of the room shown next to it cleared
pb_seg_clear:
    PHX
    JSL pb_seg_room
    LDA.l !pb_ok
    BEQ +
    TXA
    ASL A
    TAX
    LDA #$FFFF
    STA.l !pb_table,X
    +
    PLX
    RTL

; SA-1, at the end of its frame (sa1_wait_for_snes, qsql.asm), 16-bit A/X/Y
pb_sa1:
    LDA.l !pb_ok
    BEQ .rtl
    LDA.l !pb_start                 ; the timer started at 0:00.00
    BEQ +
    LDA #$0000
    STA.l !pb_start
    JSR pb_new_attempt
    +
    LDA.l !pb_exit
    BEQ .rtl
    CMP #$0002
    BEQ .armed
    ; the screen started to fade: the time kept on the HUD, unless Kirby is dead
    LDA.l !kirby_hp_long
    BNE +
    LDA #$0000
    STA.l !pb_exit
    .rtl:
    RTL
    +
    LDA.l !seg_split_sec            ; * 100 = * 64 + * 32 + * 4
    ASL A
    ASL A
    STA.l !pb_tmp+2
    ASL A
    ASL A
    ASL A
    PHA
    ASL A
    CLC
    ADC $01,S
    CLC
    ADC.l !pb_tmp+2
    PLX
    CLC
    ADC.l !seg_split_cs
    PHA
    LDA.l !seg_split_min
    TAY
    PLA
    CPY #$0000
    BEQ ++
    -
    CLC
    ADC.w #6000
    BCS +                           ; (more than 655.35 seconds: kept as 655.34)
    DEY
    BNE -
    BRA ++
    +
    LDA #$FFFE
    ++
    STA.l !pb_time
    LDA #$0002
    STA.l !pb_exit
    RTL
    .armed:
    ; out of the level (a map, a cutscene, the goal game, the ending): the end of its last room
    LDA.l !game_mode_long
    AND #$00FF
    CMP #$0003
    BEQ +
    JSR pb_clean
    BCC ++
    JSR pb_last_of_level
    BCC ++
    JSR pb_record
    ++
    LDA #$0000
    STA.l !pb_exit
    LDA #$FFFF
    STA.l !pb_room
    RTL
    +
    ; lit again in the same room (the pause screen, or the fade did not go on): not the end
    LDA.l !seg_timer_state
    BNE +
    LDA.l !screen_brightness_long
    AND #$008F
    CMP #$000F
    BNE +
    LDA #$0000
    STA.l !pb_exit
    +
    RTL

; the first lit frame of a room (the timer is at 0:00.00): did the last one end in the next room of
; the route? And which room is this?
pb_new_attempt:
    JSR pb_search
    STA.l !pb_tmp
    LDA.l !pb_exit
    CMP #$0002
    BNE .next
    JSR pb_clean
    BCC .next
    LDA.l !pb_door_kind
    BEQ .by_room
    CMP #$0002
    BCC .door
    JSR pb_last_of_level            ; a door out of the level ($7FFF)
    BCC .next
    BRA .record
    .door:
    JSR pb_door_is_next
    BCS .record
    .by_room:
    LDA.l !pb_room
    INC A
    CMP.l !pb_tmp
    BNE .next
    .record:
    JSR pb_record
    .next:
    LDA #$0000
    STA.l !pb_exit
    STA.l !pb_door_kind
    LDA.l !pb_tmp
    STA.l !pb_room
    LDA.l !toggle_free_move_long    ; free movement still on (a door with it)
    AND #$00FF
    BEQ +
    LDA #$0001
    +
    STA.l !pb_dirty
    RTS

; carry set: the attempt in !pb_room may be kept (a room of the route, nothing that does not count)
pb_clean:
    LDA.l !pb_room
    BMI .no
    LDA.l !pb_dirty
    BNE .no
    SEC
    RTS
    .no:
    CLC
    RTS

; !pb_time is the PB of !pb_room if it is faster
pb_record:
    LDA.l !pb_room
    ASL A
    TAX
    LDA.l !pb_time
    CMP.l !pb_table,X
    BCS +
    STA.l !pb_table,X
    +
    RTS

; A = room -> X = its offset in room_table (* 12)
pb_offset:
    ASL A
    ASL A
    PHA
    ASL A
    CLC
    ADC $01,S
    TAX
    PLA
    RTS

; carry set: !pb_room is the last room of its level in the route (the next one is in another level
; or sub-game, or there is none)
pb_last_of_level:
    LDA.l !pb_room
    INC A
    CMP.w #!room_count
    BCS .yes
    JSR pb_offset
    LDA.l room_table+8,X            ; sub-game
    STA.l !pb_tmp+2
    LDA.l room_table,X              ; level << 8
    PHA
    LDA.l !pb_room
    JSR pb_offset
    PLA
    EOR.l room_table,X
    AND #$FF00
    BNE .yes
    LDA.l room_table+8,X
    CMP.l !pb_tmp+2
    BNE .yes
    CLC
    RTS
    .yes:
    SEC
    RTS

; carry set: the door entered (!pb_door_*) goes into the next room of the route, where its entry is
; (a door keeps the sub-game and the level)
pb_door_is_next:
    LDA.l !pb_room
    INC A
    CMP.w #!room_count
    BCS .no
    PHA
    LDA.l !pb_room
    JSR pb_offset
    LDA.l room_table,X              ; level << 8
    AND #$FF00
    STA.l !pb_tmp+2
    LDA.l room_table+8,X
    PLX                             ; (the next room)
    PHA
    TXA
    JSR pb_offset
    PLA
    CMP.l room_table+8,X
    BNE .no
    LDA.l room_table,X
    AND #$FF00
    CMP.l !pb_tmp+2
    BNE .no
    LDA.l room_table+2,X
    BEQ +                           ; (0: a warp star's room, the room loop: room_loop_retarget)
    CMP #$0002
    BNE .no
    +
    LDA.l room_table,X
    AND #$00FF
    STA.l !pb_tmp+2
    LDA.l !pb_door_room
    AND #$00FF
    CMP.l !pb_tmp+2
    BNE .no
    LDA.l room_table+4,X
    CMP.l !pb_door_x
    BNE .no
    LDA.l room_table+6,X
    CMP.l !pb_door_y
    BNE .no
    SEC
    RTS
    .no:
    CLC
    RTS

; A = the room of room_table entered this way, $FFFF none
pb_search:
    LDA.l !room_number_long
    AND #$00FF
    STA.l !pb_key
    LDA.l !level_long
    AND #$00FF
    XBA
    ORA.l !pb_key
    STA.l !pb_key                   ; room | level << 8
    LDA.l !cutscene_long            ; how the room was entered ($332A): 0 (the room's entrance) is
    BNE +                           ; 1 (its start position) once the entrance was played, also
    INC A                           ; on the first lit frame after a warp: both are 1 here
    +
    STA.l !pb_key+2
    LDA.l !kirby_x_respawn_long
    STA.l !pb_key+4
    LDA.l !kirby_y_respawn_long
    STA.l !pb_key+6
    LDA.l !subgame_long
    AND #$00FF
    STA.l !pb_key+8
    LDX #$0000
    LDY #$0000
    .loop:
    LDA.l room_table,X
    CMP.l !pb_key
    BNE .next
    LDA.l room_table+8,X
    CMP.l !pb_key+8
    BNE .next
    LDA.l room_table+2,X
    BNE +
    INC A                           ; (0 = 1, as above)
    +
    CMP.l !pb_key+2
    BNE .next
    CMP #$0002                      ; a door: where
    BNE .found
    LDA.l room_table+4,X
    CMP.l !pb_key+4
    BNE .next
    LDA.l room_table+6,X
    CMP.l !pb_key+6
    BNE .next
    .found:
    TYA
    RTS
    .next:
    TXA
    CLC
    ADC.w #!room_entry_size
    TAX
    INY
    CPY.w #!room_count
    BCC .loop
    LDA #$FFFF
    RTS

if !detail_hud
; the しょうさい HUD (detail_values, DB = bank(!detail_buf)): "PB M:SS.cc" in row 2 when it changed
; (!detail_cache: Kirby's HP until 2026-10-15), carry set then. "-:--.--" without one.
pb_detail:
    LDA.l !pb_ok
    BEQ .rtl
    JSL pb_current
    CMP.l !detail_cache
    BEQ .rtl
    STA.l !detail_cache
    CMP #$FFFF
    BEQ .none
    LDX #$0000
    -
    CMP.w #6000
    BCC +
    SBC.w #6000
    INX
    BRA -
    +
    CPX #$000A                      ; (10 minutes or more: 9:59.99)
    BCC +
    LDX #$0009
    LDA.w #5999
    +
    PHA
    TXA
    CLC
    ADC.w #!dt
    SEP #$20
    STA.l !detail_buf+$49
    REP #$20
    PLA
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
    LDX #$004B
    JSR .dec2
    PLA
    LDX #$004E
    JSR .dec2
    SEC                             ; (written)
    RTL
    .rtl:
    CLC
    RTL
    ; A = 0-99 at X, X+1
    .dec2:
    PHX
    TAX
    LDA.l detail_bcd,X
    AND #$00FF
    ASL A
    TAX
    LDA.l detail_hex,X
    PLX
    STA.l !detail_buf,X
    RTS
    .none:
    LDA.w #(!dt_minus)|((!dt_minus)<<8)
    STA.l !detail_buf+$4B
    STA.l !detail_buf+$4E
    SEP #$20
    STA.l !detail_buf+$49
    REP #$20
    SEC
    RTL
endif
