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
    cpy #15
    bne :+
        ldy #0
    :
    tya
    sta loadBank,y
    iny

    part1:
        lda $8000,x
        sta $4011
        jsr delay
        inx
        bne part1
    part2:
        lda $8100,x
        sta $4011
        jsr delay
        inx
        bne part2
    part3:
        lda $8200,x
        sta $4011
        jsr delay
        inx
        bne part3
    part4:
        lda $8300,x
        sta $4011
        jsr delay
        inx
        bne part4
    part5:
        lda $8400,x
        sta $4011
        jsr delay
        inx
        bne part5
    part6:
        lda $8500,x
        sta $4011
        jsr delay
        inx
        bne part6
    part7:
        lda $8600,x
        sta $4011
        jsr delay
        inx
        bne part7
    part8:
        lda $8700,x
        sta $4011
        jsr delay
        inx
        bne part8
    part9:
        lda $8800,x
        sta $4011
        jsr delay
        inx
        bne part9
    part10:
        lda $8900,x
        sta $4011
        jsr delay
        inx
        bne part10
    part11:
        lda $8A00,x
        sta $4011
        jsr delay
        inx
        bne part11
    part12:
        lda $8B00,x
        sta $4011
        jsr delay
        inx
        bne part12
        jmp part13
        bit $00
        bit $00
    part13:
        lda $8C00,x
        sta $4011
        jsr delay
        inx
        bne part13
    part14:
        lda $8D00,x
        sta $4011
        jsr delay
        inx
        bne part14
    part15:
        lda $8E00,x
        sta $4011
        jsr delay
        inx
        bne part15
    part16:
        lda $8F00,x
        sta $4011
        jsr delay
        inx
        bne part16
    part17:
        lda $9000,x
        sta $4011
        jsr delay
        inx
        bne part17
    part18:
        lda $9100,x
        sta $4011
        jsr delay
        inx
        bne part18
    part19:
        lda $9200,x
        sta $4011
        jsr delay
        inx
        bne part19
    part20:
        lda $9300,x
        sta $4011
        jsr delay
        inx
        bne part20
    part21:
        lda $9400,x
        sta $4011
        jsr delay
        inx
        bne part21
    part22:
        lda $9500,x
        sta $4011
        jsr delay
        inx
        bne part22
    part23:
        lda $9600,x
        sta $4011
        jsr delay
        inx
        bne part23
    part24:
        lda $9700,x
        sta $4011
        jsr delay
        inx
        bne part24
    part25:
        lda $9800,x
        sta $4011
        jsr delay
        inx
        bne part25
    part26:
        lda $9900,x
        sta $4011
        jsr delay
        inx
        bne part26
    part27:
        lda $9A00,x
        sta $4011
        jsr delay
        inx
        bne part27
    part28:
        lda $9B00,x
        sta $4011
        jsr delay
        inx
        bne part28
    part29:
        lda $9C00,x
        sta $4011
        jsr delay
        inx
        bne part29
    part30:
        lda $9D00,x
        sta $4011
        jsr delay
        inx
        bne part30
    part31:
        lda $9E00,x
        sta $4011
        jsr delay
        inx
        bne part31
    part32:
        lda $9F00,x
        sta $4011
        jsr delay
        inx
        bne part32
    part33:
        lda $A000,x
        sta $4011
        jsr delay
        inx
        bne part33
        jmp part34
        nop
    part34:
        lda $A100,x
        sta $4011
        jsr delay
        inx
        bne part34
    part35:
        lda $A200,x
        sta $4011
        jsr delay
        inx
        bne part35
    part36:
        lda $A300,x
        sta $4011
        jsr delay
        inx
        bne part36
    part37:
        lda $A400,x
        sta $4011
        jsr delay
        inx
        bne part37
    part38:
        lda $A500,x
        sta $4011
        jsr delay
        inx
        bne part38
    part39:
        lda $A600,x
        sta $4011
        jsr delay
        inx
        bne part39
    part40:
        lda $A700,x
        sta $4011
        jsr delay
        inx
        bne part40
    part41:
        lda $A800,x
        sta $4011
        jsr delay
        inx
        bne part41
    part42:
        lda $A900,x
        sta $4011
        jsr delay
        inx
        bne part42
    part43:
        lda $AA00,x
        sta $4011
        jsr delay
        inx
        bne part43
    part44:
        lda $AB00,x
        sta $4011
        jsr delay
        inx
        bne part44
    part45:
        lda $AC00,x
        sta $4011
        jsr delay
        inx
        bne part45
    part46:
        lda $AD00,x
        sta $4011
        jsr delay
        inx
        bne part46
    part47:
        lda $AE00,x
        sta $4011
        jsr delay
        inx
        bne part47
    part48:
        lda $AF00,x
        sta $4011
        jsr delay
        inx
        bne part48
    part49:
        lda $B000,x
        sta $4011
        jsr delay
        inx
        bne part49
    part50:
        lda $B100,x
        sta $4011
        jsr delay
        inx
        bne part50
    part51:
        lda $B200,x
        sta $4011
        jsr delay
        inx
        bne part51
    part52:
        lda $B300,x
        sta $4011
        jsr delay
        inx
        bne part52
    part53:
        lda $B400,x
        sta $4011
        jsr delay
        inx
        bne part53
    part54:
        lda $B500,x
        sta $4011
        jsr delay
        inx
        bne part54
        jmp part55
        nop
    part55:
        lda $B600,x
        sta $4011
        jsr delay
        inx
        bne part55
    part56:
        lda $B700,x
        sta $4011
        jsr delay
        inx
        bne part56
    part57:
        lda $B800,x
        sta $4011
        jsr delay
        inx
        bne part57
    part58:
        lda $B900,x
        sta $4011
        jsr delay
        inx
        bne part58
    part59:
        lda $BA00,x
        sta $4011
        jsr delay
        inx
        bne part59
    part60:
        lda $BB00,x
        sta $4011
        jsr delay
        inx
        bne part60
    part61:
        lda $BC00,x
        sta $4011
        jsr delay
        inx
        bne part61
    part62:
        lda $BD00,x
        sta $4011
        jsr delay
        inx
        bne part62
    part63:
        lda $BE00,x
        sta $4011
        jsr delay
        inx
        bne part63
    part64:
        lda $BF00,x
        sta $4011
        jsr delay
        inx
        bne part64

    jmp main_loop

delay:
    lda nmiflag
    beq delaynop
    dec nmiflag
    bit PPUSTATUS ; reset PPUSCROLL/PPUADDR toggle
    inc xscroll
    lda xscroll
    sta PPUSCROLL
    beq swapNametable
    rts
swapNametable:
    lda softPPUCTRL
    eor #%00000001
    sta PPUCTRL
    sta softPPUCTRL
    rts
delaynop:
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
    nop
    nop
    nop
    nop
    nop
    nop
    bit $00
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
