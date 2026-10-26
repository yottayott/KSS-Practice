
; Game function stuff (this could probably be called something better)
; These values are used for seeing how many cycles are left to do DMA operations
!max_nmi_load       = $301B
!current_nmi_load   = $3019
!nmi_mirror         = $301D
!active_frames      = $3010 ;(default is 1, if game lags it will be greater)

; controller registers
!p1controller_hold        = $32C4
!p1controller_frame       = $32D4
!p1controller_frame_long  = $0032D4
!p1controller_repeat      = $32CC
!p1mirror_hold            = $3690
!p1mirror_frame           = $3694
!p1controller_direct      = $4218

; audio
!sound_buffer               = $3096
!current_ability_sfx        = $00AA
!sound_bank_1               = $00AA
!sound_bank_2               = $00AB
!current_music              = $33CA
!current_sfx                = $33CB
!current_sfx_long           = $0033CB
!volume                     = $33CC
!stereo_mono                = $33CD
!stereo_mono_long           = $0033CD

; menus and various selectable items
!selected_file              = $6D56
!timer_for_various_file_select_things   = $6724
!game_mode                  = $7390
!game_mode_long             = $007390
!advance_game_mode          = $7392
!subgame                    = $32EA
!room_number                = $32F2
!level_number               = $32EE     ; dyna level, romk chapter, mww planet
!level_number_long          = $0032EE
!corkboard_cursor           = $7A85
!subgame_menu_cursor        = $7B23
!romk_chapter               = $7A67
!romk_chapter_to_be_loaded  = $7B25
!cutscene_loaded            = $33C6
!file_delete_menu           = $679E
!map_to_load_into           = $73AE
!map_to_load_into_long      = $0073AE

;Milky Way Wishes 
!mww_current_planet         = $7A6B
!abilities_saved_1          = $7B1B
!abilities_saved_2          = $7B1C 
!abilities_saved_3          = $7B1D
!number_of_abilities        = $7B1E
!abilities_saved_1_long     = $007B1B
!abilities_saved_2_long     = $007B1C
!number_of_abilities_long   = $007B1E
!mww_ability_data_1         = $7B1B
!mww_ability_data_2         = $7B1D
!mww_last_ability_selected  = $36BC

; subgame addresses
!sb_gco_boss_status         = $7AE5

; status elements (health, lives, etc)
!kirby_hp           = $737C
!helper_hp          = $737E
!lives              = $737A
!score              = $7376
!romk_timer         = $73A0
!boss_inv_frames    = $78FC
!boss_hp            = $7A19
!boss_max_hp        = $7A1B
!boss_hp_meter      = $7A1D
!write_to_HUD       = $00AF     ; if set to 1, the HUD will update
!write_to_HUD_long  = $0000AF
!hud_last_drawn     = $0000B7   ; value last drawn in the lives slot, $FFFF forces a redraw
!hud_digit_tile     = $B6       ; HUD tile of digit 0, digits 1-9 follow
!hud_blank_tile     = $FF

; coordinates / positions 
!kirby_x_pos                = $6988
!kirby_y_pos                = $6A02
!kirby_x_pos_long           = $006988
!kirby_y_pos_long           = $006A02
!subgame_long               = $0032EA
!room_number_long           = $0032F2
!level_long                 = $0032EE
!kirby_x_long               = $00330C
!kirby_y_long               = $003310
!cutscene_long              = $00332A
!kirby_x_respawn_long       = $00330C
!kirby_y_respawn_long       = $003310
!camera_lock                = $7368
!room_size_x                = $3366
!room_bound_offset_x        = $3364
!room_size_y                = $3362
!room_bound_offset_y        = $3360

; gourmet race timer
!timer_minutes      = $7A2D
!timer_seconds      = $7A2C 
!timer_milliseconds = $7A2B

; various miscellaneous things
!animation_timer        = $6E4C
!reload_room            = $7392
!reload_room_long       = $007392
!screen_fade            = $30A1
!screen_fade_long       = $0030A1
!screen_brightness      = $305F
!screen_brightness_long = $00305F
!replay_cutscene        = $332A     ; this variable might do more than just handle cutscenes
!move_cam_hud           = $3330     ;/ these...
!is_paused              = $7368     ;\ ... two seem to do the same thing?
!is_paused_long         = $007368
!RNG                    = $3743
!RNG_long               = $003743
!RNG_sa1_long           = $000743
!intangible_to_items    = $744B
!intangible_to_items_long = $00744B

; abilities
!normal                 = 00
!cutter                 = 01
!beam                   = 02
!yoyo                   = 03
!ninja                  = 04
!wing                   = 05
!fighter                = 06
!jet                    = 07
!sword                  = 08
!fire                   = 09
!stone                  = 0A 
!bomb                   = 0B 
!plasma                 = 0C
!wheel                  = 0D 
!ice                    = 0E 
!mirror                 = 0F
!copy                   = 10
!suplex                 = 11
!hammer                 = 12
!parasol                = 13
!mike                   = 14
!sleep                  = 15
!paint                  = 16
!cook                   = 17
!crash                  = 18

; ability information RAM addresses
!ability                = $749F
!helper_ability         = $74A1
!ability_long           = $00749F
!kirby_action_long      = $007493
!kirby_hp_long          = $00737C
!helper_hp_long         = $00737E
!kirby_on_ground_long   = $0036EC   ; $36EA,Y set by the collision check ($03B3EB), Y = 2 for Kirby
!helper_action_long     = $007495
!message_wait_long      = $006028   ; 3 bytes: $CF4EA8 while a RoMK message stops the game until a button
!is_shooting_long       = $007577
!mww_last_ability_selected_long = $0036BC
!helper_ability_long    = $0074A1
!wheelie_rider_state_long = $007569
!helper_info1           = $7496
!helper_info2           = $74A0
!helper_info3           = $74A2
!wheelie_rider_state    = $7569
!kirby_invincible       = $35F1
!kirby_invincible_time  = $35F5
!kirby_inv_flash        = $75B1
!helper_invincible      = $35F3
!helper_invincible_time = $35F7
!helper_inv_flash       = $75B3
!kirby_speed            = $74C8
!helper_speed           = $74CA
!is_shooting            = $7577     ; shmup section, the "shooting" ability

; item tracking
!lives_collected        = $14C7     ; persists between rooms (item does not respawn between rooms)
!tomatoes_collected     = $14CF     ; persists between rooms
!food_collected         = $14D7     ; gets cleared in between rooms (these always respawn)
!romk_cutscenes_done    = $771D     ; persists between rooms, 3 bytes large

; blank addresses used for storing information
!respawn_timer              = $7B5A
!temp_pointer               = $7B5C
!mww_ability_route          = $7B71     ; ぎんが のうりょく: 0 off, 1 Any%, 2 Any% Plasma, 3 100%
!mww_ability_route_long     = $007B71
!mww_planet_rta             = $7B60
!QSQL_timer                 = $7B62
!QSQL_timer_long            = $007B62
!QSQL_transfer              = $7B64
!is_reloading_room          = $7B68
!toggle_free_move           = $7B70
!toggle_free_move_long      = $007B70
!mute_toggle                = $7B7E
!mute_toggle_long           = $007B7E
!save_sound_buffer          = $40FFF0   ; (1 byte)
!screen_fade_from_savestate = $40FFDE   ; qsql.asm: the brightness while a state loads
!temp_stack_pointer_location = $40FFE0  ; qsql.asm: the S-CPU stack pointer of the saved state
!save_sound_bank_1          = $40FFEA
!save_sound_bank_2          = $40FFFB
!toggle_custom_colors       = $40FFFD
!custom_menu_enabled        = $40FFC0
!custom_menu_language       = $40FFC2
!custom_menu_pointer        = $40FFC4
!custom_menu_cursor         = $40FFC6
!custom_menu_action         = $40FFC8
!custom_menu_subgame_warp   = $40FFCA
!is_warping                 = $40FFCC
!autoboot_corkboard         = $40FFCE
!toggle_screen_flash        = $40FFD0
!sa1_adjustment             = $40FFD2
!custom_menu_saved_rng      = $40FFD4
!custom_menu_apply_rng      = $40FFD6
!custom_menu_rng_count_digits      = $40FFA0
!custom_menu_rng_count_digit       = $40FFA6
!custom_menu_rng_count_initialized = $40FFA8
!custom_menu_rng_temp       = $40FFD8
!custom_menu_open_rng       = $40FFDA

; savestate <-> SA-1 synchronisation (outside of the savestate data on purpose)
!seg_pending_rider          = $40FFB8   ; 1 from a room warp that rides Wheelie until the timer starts

; room loop (top item of the main menu): a door reloads the current room like R+X instead of
; going to the next room
!room_loop_on               = $40FE42   ; 0 = off, 1 = on
!room_loop_request          = $40FE44   ; set by the door hook (SA-1), the NMI then reloads the room
!hud_slot_dirty             = $40FE4C   ; 1: the lives slot (timer / RNG) changed, the NMI writes it to VRAM
!hud_slot_addr              = $40FE4E   ; its first tile in the HUD buffer ($7E1617 + offset)
!room_loop_entry_type       = $40FE46   ; $332A / $330C / $3310 of the current room, taken before a door overwrites them
!room_loop_entry_x          = $40FE48
!room_loop_entry_y          = $40FE4A
!menu_frames                = $40FE54   ; passes of the practice menu loop (for lag_compare.lua)
!sa1_park_sp                = $40FFAA   ; SA-1 stack pointer while waiting at the end of a frame
!sa1_parked                 = $40FFAC   ; 1 while the SA-1 is in that wait loop
!sa1_resume                 = $40FFAE   ; set by restore_state, SA-1 then switches to !sa1_resume_sp
!sa1_resume_sp              = $40FFB0
!state_sa1_sp               = $40FFB2   ; SA-1 stack pointer belonging to the saved state
!state_magic                = $40FFB4   ; marks that a state with the current layout exists
!state_magic_value          = $5157     ; ($5157: the NMI hook is a JSL, 2026-10-16; $5156: the timer is saved with the state, 2026-10-08) change this whenever the savestate layout changes so old states are rejected
; segment practice (outside of the savestate data, in the $40FF00-$40FF3F gap:
; $40E400-$40F6C1 and $40F700-$40FE41 are VRAM backups made by the menu (font_dma_table),
; $40F6C2-$40F6FB are the registers saved by the menu)
!seg_pending_rng            = $40FF06   ; RNG to set when the segment timer starts
!seg_pending_rng_flag       = $40FF08
!seg_temp                   = $40FF0A

; Warp Settings and the room lists (in $40FE42-$40FEFF, left free by the menu's tilemap backup;
; not part of the savestate, so loading a state keeps them; kept over power off)
!warp_ability_preset        = $40FE60   ; 0 = don't set, 1 Normal, 2 Jet, 3 Hammer + Wheelie, 4 Plasma, 5 custom
!warp_custom_ability        = $40FE62   ; custom: Kirby's ability (0-$18)
!warp_custom_helper         = $40FE64   ; custom: index into warp_helper_choices (0 = no helper)
!warp_custom_rider          = $40FE66   ; custom: 1 = ride Wheelie (only when the helper is Wheelie)
!warp_rng_preset            = $40FE68   ; 0 = don't set, 1 = 221 189, 2 = 118 013, 3 = 031 005, 4 = custom
!warp_custom_rng            = $40FE6A
!warp_settings_magic        = $40FE6C   ; !warp_settings_magic_value once the defaults are in
!warp_settings_magic_value  = $5754     ; change this when the layout above changes (or to put the defaults in again)
!warp_table_bank            = $40FE6E   ; data bank of the table warp_to_level reads
!warp_apply_settings        = $40FE70   ; 1 = the room was picked with A (set the Warp Settings), 0 = Y
!warp_res_ability           = $40FE72   ; the settings resolved by room_warp
!warp_res_helper            = $40FE74
!warp_res_rider             = $40FE76
!room_last_valid            = $40FE78   ; 1 after a room warp (cleared at power on): Warp Menu opens that segment list
!seg_timer_saved            = $40FE7C   ; $40FF14-$40FF27 (timer, split, state) at the last state save
!seg_timer_saved_size       = $0014
!seg_room_door              = $40FE90   ; 1 = a door was entered (room_loop_door), the next dark is a new room
!seg_timer_room             = $40FE92   ; the room the timer started in

; Comparison build for lag tests (lag_baseline.asm sets it to 1): the timer / RNG display (the
; HUD lives slot) and the gameplay hotkeys (abilities, free movement, L+R+B) are off, the menu,
; the warps and the timer itself (it sets the warp RNG) stay.
!lag_baseline ?= 0
; the menu language, chosen when building: 0 = Japanese, 1 = English (make_file_en.bat / .sh,
; asar -Dmenu_english=1). Only the texts of that language are in the ROM.
!menu_english ?= 0
!detail_hud                 #= 1-!lag_baseline   ; the しょうさい HUD (detail_hud.asm), not in the comparison build
; the timer / RNG of the HUD (hud_timer.asm)
!hud_tiles                  = $40FED2   ; 8 bytes: the 7 tiles shown (drawn by the SA-1 at the end of its frame)
!hud_slot_live              = $40FEDA   ; 1: the game's HUD routine ran this frame (the SA-1 draws the tiles)
!hud_slot_force             = $40FEDC   ; 1: all 7 tiles to VRAM (a new layout, a state load)
!hud_slot_blank             = $40FEDE   ; the blank tile of the sub-game
!hud_tmp                    = $40FEE0
!hud_tmp2                   = $40FEE2
!hud_slot_vram              = $40FEE6   ; VRAM address of the first of the 7 tiles
!lag_count                  = $40FEE8   ; lag frames of the room so far (extras.asm, up to 999)
!lag_shown                  = $40FEEA   ; the one on the HUD (kept at a door, as the time)
!lag_prev_frame             = $40FEEC   ; the game's frame counter ($3094) at the last NMI
!rewarp_room                = $40FEF6   ; the room of the last warp of the Warp Menu (room_table)
!rewarp_valid               = $40FEF8   ; $5257 ("WR") once there was one (kept after power off)
!rewarp_valid_value         = $5257
!hud_slot_first             = $40FEF2   ; hud_slot_upload: the first of the 7 tiles to write (0-6)
!hud_slot_count             = $40FEF4   ;   and how many (1-7)
!warp_helper_choice_count   = $0013     ; entries of warp_helper_choices (room_warp.asm)
!room_list_seg              = $40FEC2   ; segment of the last warp
!room_list_menu             = $40FEC4   ; its segment list (Warp Menu opens it after a warp)
!room_list_first            = $40FEC6   ; first segment of that list
!room_pick                  = $40FEA0   ; 23 bytes: the room (0 = the first) shown next to each segment
                                        ; of the segment lists, Left / Right change it (cleared at power on)
!rng_edit_digit             = $40FEC8   ; selected digit (0-5) of the RNG value editor
!rng_edit_digits            = $40FECA   ; 6 decimal digits "xxx xxx", one byte each (+1 spare)

; the room PBs (pb.asm; 2026-10-15). Off in the lag comparison build.
!pb                         #= 1-!lag_baseline
!hud_pb_tiles               = $40FFF2   ; 8 bytes: the 7 tiles of the PB row of the timer HUD (was $40FFDC,
                                        ; over the state's stack pointer: a state load then froze, 2026-10-15)
!hud_pb_addr                = $40FFE4   ; its first tile in the HUD buffer ($7E1617 + offset), 0 = no PB row
!hud_pb_vram                = $40FFE6   ; VRAM address of its first tile
!hud_pb_buf                 = $40FFE8   ; 1: put the 7 tiles into the game's HUD buffer at its next upload
!pb_ok                      = $40FFEC   ; 1: BW-RAM bank $42 is there (pb_boot_check), else no PBs at all
!hud_pb_shown               = $40FFEE   ; the PB drawn in the PB row ($FFFF none, $FFFE: draw it again)
; bank $42 (the cartridge has 256 KB of BW-RAM since 2026-10-15): if it were a mirror of bank $40
; (128 KB), this is the menu's VRAM backup there, only used while the menu is open
!pb_magic                   = $42E400
!pb_magic_value             = $5042     ; "BP"
!pb_room                    = $42E402   ; the room of this attempt (room_table), $FFFF: not a room of the route
!pb_dirty                   = $42E404   ; 1: free movement, an ability hotkey or a state load in this attempt
!pb_exit                    = $42E408   ; 1: the screen started to fade (NMI), 2: its time is in !pb_time
!pb_time                    = $42E40A   ; the time at that fade, centiseconds
!pb_start                   = $42E40C   ; 1: the timer started at 0:00.00 (NMI): which room is it?
!pb_door_kind               = $42E40E   ; a door was entered: 1 + $7394 (1 a door, 4 the end of the level), 0 none
!pb_door_room               = $42E410   ;   its room ($32F2), x and y ($330C / $3310)
!pb_door_x                  = $42E412
!pb_door_y                  = $42E414
!pb_tmp                     = $42E416   ; 4 bytes
!pb_key                     = $42E41A   ; 10 bytes: room | level << 8, entry, x, y, sub-game (as room_table)
!pb_table                   = $42E500   ; 2 bytes a room (room_table): the PB in centiseconds, $FFFF none

;segment timer (outside of the savestate data, in the $40FF00-$40FF3F gap)
!seg_timer_frac             = $40FF14
!seg_timer_cs               = $40FF16
!seg_timer_sec              = $40FF18
!seg_timer_min              = $40FF1A
!seg_timer_state            = $40FF1C   ; 0 = running, 1 / 2 = warp: waiting for the screen to go dark / light up,
                                        ; 3 = room: fading out (still counting), 4 = room: waiting for the light
!seg_split_cs               = $40FF1E   ; the split time must stay 8 bytes after the running time
!seg_split_sec              = $40FF20
!seg_split_min              = $40FF22
!seg_split_hold             = $40FF24   ; 0 = show the running time, $FFFF = keep the split until lit, else frames left
!seg_prev_brightness        = $40FF26
!seg_timer_reset            = $40FF28   ; 1 = restart the timer now, 2 = after the next fade (warp),
                                        ; 3 = once the screen lights up (R+X)
!hud_display_mode           = $40FF2A   ; 0 = timer, 1 = RNG, 2 = lag frames, 3 = しょうさい
; the RNG count on the らんすう / しょうさい HUDs (rng_count.asm)
!rng_cnt_val                = $40FFBA   ; the RNG last counted, and its count ($FFFF: none)
!rng_cnt                    = $40FFBC
!rng_cnt_target             = $40FFBE   ; the RNG now (while counting)
!rng_cnt_v                  = $40FEEE   ; scratch of rng_count_lookup / rng_count_step
!rng_cnt_s                  = $40FEF0
!hud_pb_kind                = $40FEE4   ; what the PB row of the timer HUD shows: 0 the PB, 1 the RNG count
; the しょうさい HUD (detail_hud.asm)
!detail_font_next           = $40FEB8   ; 0: write the font (after a forced blank / new layout / a message), 36 = all there
!detail_msg_on              = $40FEBA   ; 1: a Meta Knight message is on the HUD (the game's HUD meanwhile)
!detail_ready               = $40FEBC   ; 1: the SA-1 wrote the values this frame (the NMI writes rows 1-5)
!detail_relayout            = $40FE9C   ; 1: our layout is needed (after a forced blank / the menu)
!detail_full                = $40FF10   ; 1: the layout was written (the NMI writes all of the map)
!detail_layout              = $40FEBE   ; the HUD layout of the game ($00B1) last seen
!detail_vram                = $40FEC0   ; 1: the font / map are in VRAM (put the game's HUD back when it is switched off)
!detail_prev                = $40FF00   ; Kirby's X last frame: low byte of the pixel << 8 | subpixel; Y at +2
!detail_buf                 = $40FC00   ; our HUD map, the tile numbers of rows 0-6 (224 bytes), and then
!detail_cache               = $40FCE0   ; the HP / helper / boss / lag values on it (4 words). In the menu's
                                        ; VRAM backup: the layout is written again when the menu closes
!detail_first               = $40FE94   ; what the S-CPU sends of the map: the first byte (offset), how many
!detail_len                 = $40FE96
!detail_lo                  = $40FF0C   ; the SA-1 writing the values: the first and the last offset that changed
!detail_hi                  = $40FF12
!detail_hud_ran             = $40FEFA   ; not 0: the game's HUD routine ran this frame (sa1_wait_for_snes)
!detail_tmp2                = $40FE9A
!detail_obj                 = $40FEFC   ; the object of X / Y / VX / VY: Kirby (0), Wheelie while he rides it
!detail_hold                = $40FEFE   ; the menu has closed: $8000 | the end of the DMA queue then

!custom_menu_level_table    = $66       ; called as $3766 in menu code

; for saving certain values on room reload 
!room_reload_storage                = $40FF40

!store_ability                      = !room_reload_storage
!store_helper_ability               = !room_reload_storage+$2
!store_wheelie_rider_state          = !room_reload_storage+$4
!store_kirby_hp                     = !room_reload_storage+$6
!store_helper_hp                    = !room_reload_storage+$8
!store_abilities_1                  = !room_reload_storage+$A
!store_abilities_2                  = !room_reload_storage+$C
!store_kirby_invincibility_timer    = !room_reload_storage+$E
!store_kirby_invincibility_state    = !room_reload_storage+$10
!store_helper_invincibility_timer   = !room_reload_storage+$12
!store_helper_invincibility_state   = !room_reload_storage+$14
!store_kirby_speed                  = !room_reload_storage+$16
!store_helper_speed                 = !room_reload_storage+$18
!store_music                        = !room_reload_storage+$1A
!store_RNG                          = !room_reload_storage+$1C
!store_lives_collected              = !room_reload_storage+$1E
!store_tomatoes_collected           = !room_reload_storage+$20
!store_romk_cutscenes               = !room_reload_storage+$22
!store_kirby_flashing               = !room_reload_storage+$26
!store_helper_flashing              = !room_reload_storage+$28
!store_ability_sfx                  = !room_reload_storage+$2A
!store_last_ability_selected        = !room_reload_storage+$2C

!reload_storage_size                = $002D     ; MVN count (bytes - 1), the last entry is 2 bytes
!room_reload_storage_state          = !room_reload_storage+$30

; subroutines
!reset_game                 = $BCE7
!check_game_reset           = $BCDE
!update_romk_vram           = $07E55D
!assign_ability_data        = $029C71
!assign_helper_data         = $029D2F
!finalize_cutscene          = $00CF98
!erase_file                 = $00ECD0
!load_music                 = $00CF98
!update_tileset             = $0087CB
!update_tileset_kirby_pos   = $0085EA
;!update_soundbank           = $00D2F0          ;$00D1D0
!global_jump_pointer        = $633E
!pause_game_loop            = $00A2D4
!resume_game_loop           = $00A2EF
!close_pause_menu           = $CF9AB2
!draw_text                  = $1FB449
!draw_pause_menu            = $CF999B
!dim_screen                 = $C005C7
!update_layers_input        = $008A06
!sa1_executesnes            = $008C6D

; practice menu (also used outside of menu.asm)
!menu_mirror        = $7FF000
!dp_scratch         = $45

; internal dma queue
!write_to_dma_buffer        = $00875a
!load_dma_table             = $0086e5

; arguments for the above
!dma_type                   = $003731 ;8bit
; index into table at $00869D
!dma_size                   = $003732 ;16bit
!dma_src                    = $003734 ;16bit
!dma_src_bank               = $003736 ;8bit
!dma_dest                   = $003737 ;16bit

;tables 
!mww_planet_x_pos           = $CAA6F5
!mww_planet_y_pos           = $CAA709

; useless subroutines that ill keep here anyway cuz theyre nice to have somewhere
!debug_reload_display       = $DBE7
!play_sfx                   = $D155
!play_sfx_long              = $00D155

; controller buttons
!btn_b      = $8000
!btn_y      = $4000
!btn_select = $2000
!btn_start  = $1000
!btn_up     = $0800
!btn_down   = $0400
!btn_left   = $0200
!btn_right  = $0100
!btn_a      = $0080
!btn_x      = $0040
!btn_l      = $0020
!btn_r      = $0010
