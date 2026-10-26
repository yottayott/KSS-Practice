pushpc
; Jump to SA-1 custom code from main SA-1 routine
ORG $008A51
    JMP sa1_code
pullpc

; This code will run on every single frame on the SA-1

sa1_code:
    ; run artificial cycles
    ; the table must be read with a long address: the data bank here is whatever the game
    ; was using, and reading another bank gives a random (up to 65535 loop) delay every frame
    LDA !sa1_adjustment
    BEQ +
    AND #$00FE
    CMP #$0016
    BCS +
    TAX
    LDA.l sa1_table,X
    - DEC A
    BNE -
    +

    ; custom menu code
    ; if the menu is already open, don't check for hotkeys to avoid recursion
    LDA !custom_menu_enabled
    BNE .done

    LDA.l !custom_menu_apply_rng
    BEQ +
    JSR apply_custom_menu_rng_on_sa1
    +

    LDA !p1controller_frame ; nothing pressed this frame: no hotkey (2026-10-16, fewer cycles)
    BEQ .done

    ; on R+Start, open the custom menu
    LDA !p1controller_hold  ; skip if there is a conflict with reset combo
    AND #$2030              ; checks if L+R+Select are being held
    CMP #$2030
    BEQ +

    AND #!btn_r
    BEQ +
    
    LDA !p1controller_frame
    CMP #!btn_start
    BNE +
    JSL open_custom_menu
    BRA .done
    +

    ; Select + X: the last warp again, wherever the menu can be opened (extras.asm)
    JSL rewarp_hotkey

.done:
    ; run code that was replaced by JMP to here 
    PLY
    PLX
    PLA
    PLP
    RTL

apply_custom_menu_rng_on_sa1:
    REP #$30
    LDA.l !custom_menu_apply_rng
    BEQ .done
    DEC A
    STA.l !custom_menu_apply_rng
    LDA.l !store_RNG
    STA !RNG
    STA $0743
    STA.l !RNG_long
    STA.l !RNG_sa1_long
    .done
        REP #$30
        RTS

sa1_table:
    dw $0000
    dw $0BC0
    dw $0E10
    dw $1060
    dw $12B0
    dw $1500
    dw $1750
    dw $19A0
    dw $1BF0
    dw $1E40
    dw $2090
