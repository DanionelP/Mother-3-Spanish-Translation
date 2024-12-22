// Automatically created by soundconv.exe

// Ready Set Go - Part 1
org $811FA6C; dd $8B9F7F8    // point to sound block
org $8B9F7F8; db $00,$00,$00,$00,$00,$60,$F6,$00,$00,$00,$00,$00,$00,$00,$00,$00
org $8B9F804; dw $E20       // length of sound data (minus header)
org $8B9F808; incbin sound_readysetgo_a.bin

// Ready Set Go - Part 2
org $811FA78; dd $8BA0628    // point to sound block
org $8BA0628; db $00,$00,$00,$00,$00,$60,$F6,$00,$00,$00,$00,$00,$00,$00,$00,$00
org $8BA0634; dw $E20       // length of sound data (minus header)
org $8BA0638; incbin sound_readysetgo_b.bin

// Ready Set Go - Part 3
org $811FA84; dd $8BA1458    // point to sound block
org $8BA1458; db $00,$00,$00,$00,$00,$60,$F6,$00,$00,$00,$00,$00,$00,$00,$00,$00
org $8BA1464; dw $E22       // length of sound data (minus header)
org $8BA1468; incbin sound_readysetgo_c.bin

// Look Over There
org $8B6B2E4; dw $1870       // length of sound data
org $8B6B2E8; incbin lookoverthere_eng.snd
