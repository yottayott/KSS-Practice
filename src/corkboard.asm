; The corkboard (sub-game select): no show of new cards.
; (A once, straight to the title screen of a sub-game, was removed on 2026-10-26: the user's choice)

pushpc
; no show of the newly unlocked cards (after power on it locked the cursor for 2.5 seconds):
; when the unlock flags changed ($7A91 = new, $7A8D = seen), just mark them all seen
ORG $15AE85
    LDA $7A91
    STA $7A8D
    RTL
pullpc
