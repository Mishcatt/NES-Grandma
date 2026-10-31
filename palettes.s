bgInitPalettes:
    ; Background Palette
    .byte $0F, $0F, $0F, $0F ; black, black, black
    .byte $0F, $0F, $0F, $0F ; black, black, black
    .byte $0F, $0F, $0F, $0F ; black, black, black
    .byte $0F, $00, $10, $30 ; dark_gray, light_gray, white

bgPaletteWaifu:
    .byte $0F, $0F, $0F, $0F ; black, black, black
    .byte $0F, $0F, $0F, $00 ; dark_gray, light_gray, white
    .byte $0F, $0F, $00, $10 ; dark_gray, light_gray, white
    .byte $0F, $00, $10, $30 ; dark_gray, light_gray, white

bgPaletteLogo:
    .byte $0F, $0F, $0F, $0F ; black, black, black
    .byte $0F, $0F, $00, $0F ; dark_red, white, red
    .byte $0F, $0F, $10, $06 ; dark_red, white, red
    .byte $0F, $06, $30, $16 ; dark_red, white, red

bgPaletteBanner:
    .byte $0F, $0F, $0F, $0F ; black, black, black
    .byte $0F, $0F, $00, $0F ; black, gray, black
    .byte $0F, $00, $10, $06 ; dark_gray, light_gray, dark_red
    .byte $0F, $10, $30, $16 ; light_gray, white, red

spritePalettes:
    ; Sprite Palette
    .byte $0F, $00, $00, $10 ; dark_gray, gray, light_gray
    .byte $0F, $00, $00, $30 ; dark_gray, gray, white
    .byte $0F, $00, $10, $30 ; dark_gray, light_gray, white
    .byte $0F, $10, $30, $16 ; light_gray, white, red
