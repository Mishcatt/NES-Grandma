.include "registers.s"
.include "const.s"
.include "vars.s"

.segment "BANK00"
    .incbin "stepgrandma00.raw", 0, 16384
.segment "BANK01"
    .incbin "stepgrandma01.raw", 0, 16384
.segment "BANK02"
    .incbin "stepgrandma02.raw", 0, 16384
.segment "BANK03"
    .incbin "stepgrandma03.raw", 0, 16384
.segment "BANK04"
    .incbin "stepgrandma04.raw", 0, 16384
.segment "BANK05"
    .incbin "stepgrandma05.raw", 0, 16384
.segment "BANK06"
    .incbin "stepgrandma06.raw", 0, 16384
.segment "BANK07"
    .incbin "stepgrandma07.raw", 0, 16384
.segment "BANK08"
    .incbin "stepgrandma08.raw", 0, 16384
.segment "BANK09"
    .incbin "stepgrandma09.raw", 0, 16384
.segment "BANK10"
    .incbin "stepgrandma10.raw", 0, 16384
.segment "BANK11"
    .incbin "stepgrandma11.raw", 0, 16384
.segment "BANK12"
    .incbin "stepgrandma12.raw", 0, 16384
.segment "BANK13"
    .incbin "stepgrandma13.raw", 0, 16384
.segment "BANK14"
    .incbin "stepgrandma14.raw", 0, 16384

.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 16              ; 16x 16KB PRG code
  .byte 0               ; CHR-RAM
  .byte $21, $00        ; Mapper 2 UNROM, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr irq

; "nes" linker config requires a STARTUP section, even if it's empty
;.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

reset:
    sei		; disable IRQs
    cld		; disable decimal mode
    ldx #$40
    stx JOYPAD2	; disable APU frame IRQ
    ldx #$ff 	; Set up stack
    txs		;  .
    inx		; now X = 0
    stx PPUCTRL	; disable NMI
    stx PPUMASK 	; disable rendering
    stx DMC_FREQ 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
    bit PPUSTATUS
    bpl vblankwait1

clear_memory:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
    bit PPUSTATUS
    bpl vblankwait2

load_palettes:
    bit PPUSTATUS ; clear w register by reading Status
    lda #$3f
    sta PPUADDR
    lda #$00
    sta PPUADDR

    ldx #$00
    @bgloop:
        lda bgInitPalettes, x
        sta PPUDATA
        inx
        cpx #$10
        bne @bgloop
    ldx #$00
    @spriteloop:
        lda spritePalettes, x
        sta PPUDATA
        inx
        cpx #$10
        bne @spriteloop

load_initial_sprites:
    ldx #$00
    @loop:
        lda sprites, x
        sta OAM, x         ; Load the sprites into OAM
        inx
        cpx #SpriteLastByte
        bne @loop
    ; inc dmaflag

load_nametable:
    ldx #$00
    lda #%00001000  ; Disable NMI, sprite tile 1, horizontal increment
    sta PPUCTRL
    bit PPUSTATUS   ; clear w register by reading Status
    lda #$20        ; load nametable 0 address
    sta PPUADDR
    lda #$00
    sta PPUADDR
    @loop1:
        lda Nametable1A, x
        sta PPUDATA
        inx
        bne @loop1
    @loop2:
        lda Nametable1B, x
        sta PPUDATA
        inx
        bne @loop2
    @loop3:
        lda Nametable1C, x
        sta PPUDATA
        inx
        bne @loop3
    @loop4:
        lda Nametable1D, x
        sta PPUDATA
        inx
        cpx #240
        bne @loop4
    bit PPUSTATUS   ; clear w register by reading Status
    lda #$28        ; load nametable 2 address
    sta PPUADDR
    lda #$00
    sta PPUADDR
    ldx #$00
    @loop5:
        lda Nametable2A, x
        sta PPUDATA
        inx
        bne @loop5
    @loop6:
        lda Nametable2B, x
        sta PPUDATA
        inx
        bne @loop6
    @loop7:
        lda Nametable2C, x
        sta PPUDATA
        inx
        bne @loop7
    @loop8:
        lda Nametable2D, x
        sta PPUDATA
        inx
        cpx #240
        bne @loop8

load_attributes:
    bit PPUSTATUS   ; clear w register by reading Status
    lda #$23        ; load attribute table 0 address
    sta PPUADDR
    lda #$C0
    sta PPUADDR
    ldx #$00
    @loop1:
        lda Attributes1, x
        sta PPUDATA
        inx
        cpx #64
        bne @loop1
    bit PPUSTATUS   ; clear w register by reading Status
    lda #$2B        ; load attribute table 2 address
    sta PPUADDR
    lda #$C0
    sta PPUADDR
    ldx #$00
    @loop2:
        lda Attributes2, x
        sta PPUDATA
        inx
        cpx #64
        bne @loop2

set_scroll:
    lda #$00
    sta xscroll
    sta yscroll
    bit PPUSTATUS
    lda xscroll    ; set X/Y scroll (conditional via ppuflag)
    sta PPUSCROLL
    lda yscroll
    sta PPUSCROLL
    ; inc ppuflag

init_variables:
    lda #1
    sta split1bank
    sta currentSplit1bank
    sta nmibank
    sta scrollDelay
    sta pauseScroll
    sta currentPaletteSequence
    lda #3
    sta split2bank

set_bank:
    lda #0
    tay
    sta loadBank, y

enable_rendering:
    lda #%10001000	; Enable NMI, sprite tile 1, horizontal increment
    sta PPUCTRL
    sta softPPUCTRL
    lda #%00011110	; Enable Sprites and Background
    sta PPUMASK
    sta softPPUMASK
    ; inc drawflag
    sta nmiflag ; zero the NMI flag
    cli         ; enable interrupts

ldx #0
ldy #0
main_loop:
    lda #$80
    sta dataAddr2
    cpx #15
    bne :+
        ldx #0
    :
    txa
    sta loadBank,x
    inx
    nop
    jmp playMusicFast

    playMusic:
        jsr delay
    playMusicFast:
        lda (dataAddr1),y
        sta $4011
        iny
        bne playMusic
    inc dataAddr2
    lda dataAddr2
    cmp #$C0
    bne :+
        lda #$80
        sta dataAddr2
        jmp main_loop
    :
    jsr delaySmall
    jmp playMusicFast

delay:
    lda nmiflag
    beq delayLong
    dec nmiflag
    bit PPUSTATUS ; reset PPUSCROLL/PPUADDR toggle
    dec xscroll
    lda xscroll
    sta PPUSCROLL
    beq swapNametable
    jmp delayScroll
swapNametable:
    lda softPPUCTRL ; 3 cycle
    eor #%00000001  ; 2 cycle
    sta PPUCTRL     ; 4 cycle
    sta softPPUCTRL ; 3 cycle = 12 cycles = 6 NOPs
    jmp delayNametable
delayLong:
    nop
    nop
    nop
    nop
    nop
delaySmall:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
delayScroll:
    nop
    nop
    nop
    nop
    nop
    nop
delayNametable:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rts

nmi:
    inc nmiflag
    rti

irq:
    rti

loadCHR:
.incbin "step-grandma.chr", 0, 8192

.include "sprites.s"
.include "palettes.s"
.include "picture.s"
