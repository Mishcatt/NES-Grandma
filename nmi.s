;--------------------------------------
; NMI - the NMI handler
nmi:
    pha         ; back up registers (important)
    txa
    pha
    tya
    pha
    bit PPUSTATUS ; reset PPUSCROLL/PPUADDR toggle

    lda #$3f
    sta PPUADDR
    lda #$00
    sta PPUADDR

    ldx currentWaifuPalette
    lda bgPaletteWaifu, x
    sta PPUDATA
    inx
    lda bgPaletteWaifu, x
    sta PPUDATA
    inx
    lda bgPaletteWaifu, x
    sta PPUDATA
    inx
    lda bgPaletteWaifu, x
    sta PPUDATA
    inx

    ldx currentLogoPalette
    lda bgPaletteLogo, x
    sta PPUDATA
    inx
    lda bgPaletteLogo, x
    sta PPUDATA
    inx
    lda bgPaletteLogo, x
    sta PPUDATA
    inx
    lda bgPaletteLogo, x
    sta PPUDATA
    inx

    ldx currentBannerPalette
    lda bgPaletteBanner, x
    sta PPUDATA
    inx
    lda bgPaletteBanner, x
    sta PPUDATA
    inx
    lda bgPaletteBanner, x
    sta PPUDATA
    inx
    lda bgPaletteBanner, x
    sta PPUDATA
    inx

    lda nmibank
    tay
    sta loadBank, y
    inc frameCounter

    lda currentPaletteSequence
    beq @check_dma_flag
        inc currentPaletteSequence
        cmp #$10
        bne :+
            lda #4
            sta currentLogoPalette
        :
        cmp #$20
        bne :+
            lda #8
            sta currentLogoPalette
        :
        cmp #$30
        bne :+
            lda #12
            sta currentLogoPalette
        :
        cmp #$70
        bne :+
            lda #4
            sta currentWaifuPalette
            sta currentBannerPalette
        :
        cmp #$80
        bne :+
            lda #8
            sta currentWaifuPalette
            sta currentBannerPalette
        :
        cmp #$90
        bne :+
            lda #12
            sta currentWaifuPalette
            sta currentBannerPalette
        :
        cmp #$c0
        bne :+
            lda #0
            sta pauseScroll
        :
        

    @check_dma_flag:
        ; lda dmaflag
        ; beq @check_draw_flag
            lda #0
            sta dmaflag
            sta OAMADDR
            lda #>OAM
            sta OAMDMA ; do sprite DMA


    @check_ppu_flag:
        ; lda ppuflag
        ; beq @music_handler
            lda softPPUMASK   ; copy buffered PPUCTRL/PPUMASK (conditional via ppuflag)
            sta PPUMASK
            lda softPPUCTRL
            sta PPUCTRL
            bit PPUSTATUS
            lda xscroll    ; set X/Y scroll (conditional via ppuflag)
            sta PPUSCROLL
            lda yscroll
            sta PPUSCROLL
            lda #0
            sta ppuflag

    ; @music_handler:
        ; jsr famistudio_update

    lda #1         
    sta nmiflag   ; set the nmi_flag flag so that main_loop will continue

    pla            ; restore regs and exit
    tay
    pla
    tax
    pla
    rti