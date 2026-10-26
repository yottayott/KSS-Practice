; game reset long jump in bank $00
check_reset:
  JSR !check_game_reset
  RTL

check_gamemode_on_change:
  TAX
  LDA !is_warping
  BEQ +

  LDX #$0003

  + STX !game_mode
  RTS

check_gamemode_on_coordinates_load:
  LDA !is_warping
  BNE +

  STZ $332A
  RTS

  + LDA #$0000
  STA !is_warping
  RTS

; screen flashing toggle: removed from the segment practice version (the boss flash is as in the original game)
;; screen flashing code
;pushpc

;ORG $27E42E
;  JSR check_white_flash
;ORG $27E435
;  JSR check_red_flash

;ORG $27FF10
;  check_white_flash:
;    LDA !toggle_screen_flash
;    BEQ +
;      JMP $E565 ; dim screen
;    + JMP $E529 ; flash white

;  check_red_flash:
;    LDA !toggle_screen_flash
;    BEQ +
;      JMP $E565 ; dim screen
;    + JMP $E547 ; flash red

;pullpc