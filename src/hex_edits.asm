; All sub-games selectable
; allow for selection
; LDA $7A83 -> LDA #$0005
ORG $15B644
    LDA #$0005
; visibly show games unlocked
; BEQ $XX -> NOP
ORG $15B831
    LDA #$007F

; Remove original code for clearing gamemode on boot (custom init code is overriding this)
; LDA #$0000 -> NOP
ORG $00BBF7
    NOP #3

; Remove original code for resetting subgame cursor on boot
; STZ $7A8F -> NOP
ORG $00D7E1
    NOP #3

; Make file deletion instant
; LDA #$00B4 -> LDA #$0000
ORG $078736
    dw $0000

; Make death animation instant
; $B4 -> $01
ORG $088D9D
    db $01

; Don't decrease lives counter
; DEC $737A -> NOP
; Instead replace with resetting free move toggle
ORG $0387E1
    STZ !toggle_free_move

;Set BRK vector to game reset subroutine. This makes it so the game is reset on a crash rather than... crashing.
;$BCE7 is where the reset subroutine is located.
ORG $00FFE6
    dw $E7BC

; Do not clear the entirety of SRAM 
; LDA #$1EFE -> LDA #$1B6F
ORG $008C04
    LDA #$1B6F

; RNG after a reset: 221 189 ($BDDD) instead of 119 119 ($7777). In a run, skipping the title
; screen as fast as possible still advances the RNG once (2026-10-08, the user's request).
; The RNG count of the RNG menus still counts from $7777.
; LDA #$7777 : STA $3743 -> reset_rng (init.asm). Not when the game starts on the title screen
; (タイトル とばす off): going through it advances the RNG as in a run.
ORG $008C12
    JSL reset_rng
    NOP #2

; Leave every Dyna Blade stage
; always show leave menu
; BEQ $0C -> BRA $04
ORG $1F9F10
    db $80, $04
; actual logic to accept leave stage input
; BEQ $D7 -> BRA $04
ORG $1F9E5D
    db $80, $04

; Leave every MWW stage
; BNE $XX -> NOP
ORG $1FA611
    NOP #2

; Spring Breeze bosses always have New File health
; BNE $XX -> NOP 
ORG $00ED96
    NOP #2

; GCO bosses respawn 
; BEQ -> BRA for all 
; Fatty Whale
ORG $2AA800
    db $80
; Battle Windows 
ORG $2ADDE4 
    db $80
; Ghameleo Arm  
ORG $2AC303
    db $80
; Wham Bam
ORG $2AD1E5
    db $80

; No game over in Arena
; CMP #$0006 -> CMP #$00FF
ORG $0387F4
    db $FF

; Always have MWW cursor highlight "Continue"
; BEQ -> BRA
ORG $07DA3E
    db $80

; MWW pause (ability select): the 1P / 2P cursors don't blink (2026-10-10, the user's wish: screen burn-in).
; Cursor animation scripts at $CFAE26 / $CFAE3D: frame 04 / 06 for 3 frames, then 05 / 07 (blank)
; for 1 frame, loop. The blank frame becomes the normal one.
ORG $1FAE29
    db $04
ORG $1FAE40
    db $06

; Disable GCO treasure menu (so it doesn't override X button combos)
; LDA #$1040 -> LDA #$1000
ORG $00CB6C
    db $00

; Never decrease RoMK timer 
; DEC $73A0 -> NOP
ORG $00C227
    NOP #3
; Make RoMK timer reaching zero not kill you (usually for warping into RoMK room from other subgame)
; BEQ -> BRA
ORG $029078
    db $80

; Always spawn Chests and Copy Essences
; all BEQ -> BRA 
ORG $1EBF92
    db $80
ORG $1EBFB5
    db $80
ORG $1EF1EF
    db $80

; Stop Red Screen Flashing
;ORG $27E529
;    RTS
;ORG $27E547
;    RTS
;ORG $27E565    ; gray flashing
;    RTS

; Change Arena timer color
;ORG $598680
;    db $1F

; Always on quick pause 
;ORG $1F991F
;    db $80