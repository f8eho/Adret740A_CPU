; ============================================================================
; ADRET 740A — source commentée de 740A-1.BIN
; Processeur : Motorola 6802 — syntaxe assembleur Motorola classique
; Implantation physique : $E000..$FFFF (8192 octets)
; SHA-256 de référence : 099F43F99A26C1AA3E8C988622865FF8E5EFBA2F6E3A20A678295FD10085B095
;
; Niveaux de preuve employés :
;   CONFIRMÉ  : établi par le binaire et les schémas/captures/documentation.
;   DÉDUIT    : conséquence forte du flot de contrôle et des données connues.
;   HYPOTHÈSE : interprétation plausible restant à confirmer au banc.
;   INCONNU   : rôle non attribué; le nom reste volontairement neutre.
;
; Cartographie utile confirmée ou directement visible sur le schéma CPU :
;   $0000..$00FF  page directe et variables de travail du 6802
;   $2000..$2003  interface distante/GPIB (registres utilisés au RESET)
;   $4000..$4007  PIA 6821 du panneau avant et miroirs de décodage
;   $6000..$600F  seize registres du bus instruments (adresse = poids faible)
;   $8000..$Axxx  RAM et miroirs matériels; images de configuration en $85xx
;   $C000..$DFFF  EPROM 740A-2; $E000..$FFFF EPROM 740A-1
;
; Chaque ligne porte ses octets d'origine sous la forme '; @ AAAA: XX ...'.
; Ils constituent aussi la preuve mécanique de couverture et de fidélité.
; ============================================================================

        ORG     $E000

; ---------------------------------------------------------------------------
; Symboles mémoire et périphériques effectivement employés dans cette EPROM
; ---------------------------------------------------------------------------
DP_0000                                  EQU     $0000
DP_0005                                  EQU     $0005
DP_000C                                  EQU     $000C
DP_000E                                  EQU     $000E
DP_000F                                  EQU     $000F
DP_0011                                  EQU     $0011
DP_0015                                  EQU     $0015
DP_001A                                  EQU     $001A
DP_001E                                  EQU     $001E
DP_0023                                  EQU     $0023
DP_0025                                  EQU     $0025
DP_0026                                  EQU     $0026
DP_0027                                  EQU     $0027
DP_0037                                  EQU     $0037
DP_0039                                  EQU     $0039
DP_003A                                  EQU     $003A
DP_003B                                  EQU     $003B
DP_003C                                  EQU     $003C
DP_003D                                  EQU     $003D
DP_0045                                  EQU     $0045
DP_0049                                  EQU     $0049
DP_004A                                  EQU     $004A
DP_004C                                  EQU     $004C
DP_0055                                  EQU     $0055
DP_0056                                  EQU     $0056
DP_005D                                  EQU     $005D
DP_005E                                  EQU     $005E
DP_005F                                  EQU     $005F
DP_0060                                  EQU     $0060
DP_0061                                  EQU     $0061
DP_0062                                  EQU     $0062
DP_0067                                  EQU     $0067
DP_0069                                  EQU     $0069
DP_006A                                  EQU     $006A
DP_006B                                  EQU     $006B
DP_006D                                  EQU     $006D
DP_006E                                  EQU     $006E
DP_006F                                  EQU     $006F
DP_0070                                  EQU     $0070
DP_0071                                  EQU     $0071
DP_0072                                  EQU     $0072
DP_0073                                  EQU     $0073
DP_0074                                  EQU     $0074
DP_0076                                  EQU     $0076
DP_0077                                  EQU     $0077
DP_0078                                  EQU     $0078
DP_0079                                  EQU     $0079
GPIB_REG_2                               EQU     $2002
INST_00_SYNTH_20000_UNITS                EQU     $6000
INST_01_SYNTH_20000_HUNDREDS_TENS        EQU     $6001
INST_02_SYNTH_20000_THOUSANDS            EQU     $6002
INST_03_SYNTH_80_DIVIDER                 EQU     $6003
INST_04_APPROACH_DIVIDER_N               EQU     $6004
INST_05_RF_PATH_AND_PULSE                EQU     $6005
INST_06_ATTENUATOR_AND_PULSE             EQU     $6006
INST_08_FINE_ATTENUATION                 EQU     $6008
INST_09_MODULATION_BCD_LOW               EQU     $6009
INST_10_MODULATION_BCD_HIGH_MODE         EQU     $600A
INST_11_FM_CORRECTION_N                  EQU     $600B
INST_12_RF_RANGE_MODULATION_SOURCE       EQU     $600C
INST_13_INCREMENT_DIVIDER                EQU     $600D
INST_15_RANGE_EXTENSION                  EQU     $600F
MEM_04E2                                 EQU     $04E2
MEM_1000                                 EQU     $1000
PIA_CONTROL_A_MIRROR                     EQU     $4005
PIA_CONTROL_B_MIRROR                     EQU     $4007
PIA_PORT_A_OR_DDRA                       EQU     $4000
PIA_PORT_A_OR_DDRA_MIRROR                EQU     $4004
RAM_8000                                 EQU     $8000
RAM_8002                                 EQU     $8002
RAM_8003                                 EQU     $8003
RAM_8004                                 EQU     $8004
RAM_800A                                 EQU     $800A
RAM_800B                                 EQU     $800B
RAM_800D                                 EQU     $800D
RAM_8013                                 EQU     $8013
RAM_8014                                 EQU     $8014
RAM_8018                                 EQU     $8018
RAM_8019                                 EQU     $8019
RAM_801A                                 EQU     $801A
RAM_801B                                 EQU     $801B
RAM_801C                                 EQU     $801C
RAM_8020                                 EQU     $8020
RAM_8025                                 EQU     $8025
RAM_8041                                 EQU     $8041
RAM_8042                                 EQU     $8042
RAM_8043                                 EQU     $8043
RAM_8044                                 EQU     $8044
RAM_8047                                 EQU     $8047
RAM_8048                                 EQU     $8048
RAM_8500                                 EQU     $8500
RAM_8501                                 EQU     $8501
RAM_8502                                 EQU     $8502
RAM_8503                                 EQU     $8503
RAM_8504                                 EQU     $8504
RAM_8505                                 EQU     $8505
RAM_8506                                 EQU     $8506
RAM_8508                                 EQU     $8508
RAM_850A                                 EQU     $850A
RAM_850B                                 EQU     $850B
RAM_850C                                 EQU     $850C
RAM_850D                                 EQU     $850D
RAM_850F                                 EQU     $850F
RAM_851B                                 EQU     $851B
RAM_851C                                 EQU     $851C
RAM_851E                                 EQU     $851E
RAM_851F                                 EQU     $851F
RAM_8520                                 EQU     $8520
RAM_8523                                 EQU     $8523
RAM_8524                                 EQU     $8524
RAM_8526                                 EQU     $8526
RAM_8529                                 EQU     $8529
RAM_8540                                 EQU     $8540
RAM_8541                                 EQU     $8541
RAM_8542                                 EQU     $8542
RAM_8543                                 EQU     $8543
RAM_8544                                 EQU     $8544
RAM_8548                                 EQU     $8548
RAM_854A                                 EQU     $854A
RAM_854C                                 EQU     $854C
RAM_854D                                 EQU     $854D
RAM_8560                                 EQU     $8560
RAM_8561                                 EQU     $8561
RAM_8565                                 EQU     $8565
RAM_8800                                 EQU     $8800
RAM_8801                                 EQU     $8801
RAM_8802                                 EQU     $8802
RAM_8880                                 EQU     $8880
RAM_8A00                                 EQU     $8A00
RAM_8B00                                 EQU     $8B00
RAM_8C00                                 EQU     $8C00
RAM_8C64                                 EQU     $8C64
RAM_9000                                 EQU     $9000
RAM_9400                                 EQU     $9400
RAM_9FFF                                 EQU     $9FFF
RAM_A000                                 EQU     $A000
RAM_A120                                 EQU     $A120
RAM_A240                                 EQU     $A240
RAM_A800                                 EQU     $A800
RAM_MODE_FLAGS_PULSE_D1                  EQU     $8026
ROM_DATA_C276                            EQU     $C276
ROM_DATA_E265                            EQU     $E265
ROM_DATA_E4E1                            EQU     $E4E1
ROM_DATA_F077                            EQU     $F077
ROM_DATA_FFFC                            EQU     $FFFC
ROM_DATA_FFFF                            EQU     $FFFF
attenuator_relay_table_bcd               EQU     $C1F6
reset_entry                              EQU     $C33F
loc_C428                                 EQU     $C428
loc_C522                                 EQU     $C522
loc_C5A4                                 EQU     $C5A4
sub_C687                                 EQU     $C687
sub_C9DD                                 EQU     $C9DD
sub_CA10                                 EQU     $CA10
sub_CAE9                                 EQU     $CAE9
sub_CB28                                 EQU     $CB28
update_instrument_address_6_control_bits EQU     $CC7E
irq_swi_front_panel_handler              EQU     $CC9F
loc_D388                                 EQU     $D388
loc_D51E                                 EQU     $D51E
loc_D5F3                                 EQU     $D5F3
loc_D748                                 EQU     $D748
loc_DFFC                                 EQU     $DFFC
loc_F0BD                                 EQU     $F0BD

; Suite de l'instruction STX $800A commencée à $DFFF dans 740A-2.
        FCB     $80,$0A                                 ; @ E000: 80 0A
        STX     DP_001E                                 ; @ E002: DF 1E
        LDAB    DP_003D                                 ; @ E004: D6 3D
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E006: CA 40
        STAB    DP_003D                                 ; @ E008: D7 3D
        LDAB    DP_004A                                 ; @ E00A: D6 4A
        ORAB    #$09                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E00C: CA 09
        STAB    DP_004A                                 ; @ E00E: D7 4A
        STAB    RAM_8025                                ; @ E010: F7 80 25
        LDAB    #$C0                                    ; @ E013: C6 C0
        ORAB    DP_0037                                 ; @ E015: DA 37
        STAB    DP_0037                                 ; @ E017: D7 37
        RTS                                             ; @ E019: 39
loc_E01A:
        JMP     loc_E0D5                                ; transfert sans retour vers loc_E0D5 ; @ E01A: 7E E0 D5
loc_E01D:
        LDAA    DP_004A                                 ; @ E01D: 96 4A
        ANDA    #$FE                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E01F: 84 FE
        STAA    DP_004A                                 ; @ E021: 97 4A
        LDAA    DP_0049                                 ; @ E023: 96 49
        BITA    #$E0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E025: 85 E0
        BNE     loc_E02F                                ; branche vers loc_E02F si la condition NE est vraie ; @ E027: 26 06
        LDX     #ROM_DATA_FFFF                          ; @ E029: CE FF FF
        STX     RAM_800A                                ; @ E02C: FF 80 0A
loc_E02F:
        CMPA    #$40                                    ; @ E02F: 81 40
        BHI     loc_E040                                ; branche vers loc_E040 si la condition HI est vraie ; @ E031: 22 0D
        LDAA    RAM_800B                                ; @ E033: B6 80 0B
        ASLA                                            ; @ E036: 48
        ASLA                                            ; @ E037: 48
        ASLA                                            ; @ E038: 48
        ASLA                                            ; @ E039: 48
        ABA                                             ; @ E03A: 1B
        STAA    RAM_800B                                ; @ E03B: B7 80 0B
        BRA     loc_E04B                                ; branche toujours vers loc_E04B ; @ E03E: 20 0B
loc_E040:
        LDAA    RAM_800A                                ; @ E040: B6 80 0A
        ASLA                                            ; @ E043: 48
        ASLA                                            ; @ E044: 48
        ASLA                                            ; @ E045: 48
        ASLA                                            ; @ E046: 48
        ABA                                             ; @ E047: 1B
        STAA    RAM_800A                                ; @ E048: B7 80 0A
loc_E04B:
        LDAB    DP_0049                                 ; @ E04B: D6 49
        ADDB    #$20                                    ; @ E04D: CB 20
        STAB    DP_0049                                 ; @ E04F: D7 49
        BMI     loc_E0AF                                ; branche vers loc_E0AF si la condition MI est vraie ; @ E051: 2B 5C
        LDAA    RAM_800B                                ; @ E053: B6 80 0B
        STAA    RAM_801B                                ; @ E056: B7 80 1B
        LDAA    RAM_800A                                ; @ E059: B6 80 0A
        STAA    RAM_8019                                ; @ E05C: B7 80 19
        LDAA    #$B0                                    ; @ E05F: 86 B0
        ORAA    DP_0037                                 ; @ E061: 9A 37
        STAA    DP_0037                                 ; @ E063: 97 37
        RTS                                             ; @ E065: 39
loc_E066:
        LDAA    PIA_PORT_A_OR_DDRA_MIRROR               ; accès au PIA 6821 du panneau avant ; @ E066: B6 40 04
        EORA    #$3F                                    ; @ E069: 88 3F
        TAB                                             ; @ E06B: 16
        ANDA    #$1F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E06C: 84 1F
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E06E: 84 0F
        ADDA    #$00                                    ; @ E070: 8B 00
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ E072: 19
        BITB    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E073: C5 10
        BEQ     loc_E07A                                ; branche vers loc_E07A si la condition EQ est vraie ; @ E075: 27 03
        ADDA    #$16                                    ; @ E077: 8B 16
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ E079: 19
loc_E07A:
        PSHB                                            ; @ E07A: 37
        LDAB    #$FF                                    ; @ E07B: C6 FF
        STAB    RAM_8018                                ; @ E07D: F7 80 18
        STAB    RAM_801C                                ; @ E080: F7 80 1C
        STAA    RAM_801B                                ; @ E083: B7 80 1B
        LDAA    #$AA                                    ; @ E086: 86 AA
        STAA    RAM_801A                                ; @ E088: B7 80 1A
        PULB                                            ; @ E08B: 33
        BITB    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E08C: C5 20
        BNE     loc_E0A7                                ; branche vers loc_E0A7 si la condition NE est vraie ; @ E08E: 26 17
        LDAB    #$FF                                    ; @ E090: C6 FF
        LDAA    DP_003C                                 ; @ E092: 96 3C
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E094: 8A 20
loc_E096:
        STAA    DP_003C                                 ; @ E096: 97 3C
        STAB    RAM_8019                                ; @ E098: F7 80 19
        LDAB    #$10                                    ; @ E09B: C6 10
        JSR     sub_CB28                                ; appelle sub_CB28 ; @ E09D: BD CB 28
        LDAB    #$B0                                    ; @ E0A0: C6 B0
        ORAB    DP_0037                                 ; @ E0A2: DA 37
        STAB    DP_0037                                 ; @ E0A4: D7 37
        RTS                                             ; @ E0A6: 39
loc_E0A7:
        LDAA    DP_003C                                 ; @ E0A7: 96 3C
        ANDA    #$DF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E0A9: 84 DF
        LDAB    #$D0                                    ; @ E0AB: C6 D0
        BRA     loc_E096                                ; branche toujours vers loc_E096 ; @ E0AD: 20 E7
loc_E0AF:
        BRA     loc_E0D5                                ; branche toujours vers loc_E0D5 ; @ E0AF: 20 24
loc_E0B1:
        LDAA    DP_005D                                 ; @ E0B1: 96 5D
        LDX     #loc_EAFF                               ; @ E0B3: CE EA FF
        STX     RAM_801B                                ; @ E0B6: FF 80 1B
        LDX     #ROM_DATA_FFFF                          ; @ E0B9: CE FF FF
        STX     RAM_8018                                ; @ E0BC: FF 80 18
        LDAB    DP_0049                                 ; @ E0BF: D6 49
        BITB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E0C1: C5 08
        BNE     loc_E066                                ; branche vers loc_E066 si la condition NE est vraie ; @ E0C3: 26 A1
        BITB    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E0C5: C5 01
        BNE     loc_E0CA                                ; branche vers loc_E0CA si la condition NE est vraie ; @ E0C7: 26 01
        RTS                                             ; @ E0C9: 39
loc_E0CA:
        BCC     loc_E0CF                                ; branche vers loc_E0CF si la condition CC est vraie ; @ E0CA: 24 03
        ADDA    #$98                                    ; @ E0CC: 8B 98
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ E0CE: 19
loc_E0CF:
        ADDA    #$01                                    ; @ E0CF: 8B 01
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ E0D1: 19
        BRA     loc_E0EA                                ; branche toujours vers loc_E0EA ; @ E0D2: 20 16
        FCB     $39                                     ; données '9' ; @ E0D4: 39
loc_E0D5:
        BITB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E0D5: C5 08
        BEQ     loc_E0EA                                ; branche vers loc_E0EA si la condition EQ est vraie ; @ E0D7: 27 11
        STAA    RAM_801A                                ; @ E0D9: B7 80 1A
        LDAB    #$A0                                    ; @ E0DC: C6 A0
        ORAB    DP_0037                                 ; @ E0DE: DA 37
        STAB    DP_0037                                 ; @ E0E0: D7 37
        PSHA                                            ; @ E0E2: 36
        JSR     sub_C687                                ; appelle sub_C687 ; @ E0E3: BD C6 87
        PULA                                            ; @ E0E6: 32
        JMP     loc_E27D                                ; transfert sans retour vers loc_E27D ; @ E0E7: 7E E2 7D
loc_E0EA:
        BITB    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E0EA: C5 02
        BEQ     loc_E10F                                ; branche vers loc_E10F si la condition EQ est vraie ; @ E0EC: 27 21
        CMPA    RAM_8043                                ; @ E0EE: B1 80 43
        BCS     loc_E0F7                                ; branche vers loc_E0F7 si la condition CS est vraie ; @ E0F1: 25 04
        BEQ     loc_E0F7                                ; branche vers loc_E0F7 si la condition EQ est vraie ; @ E0F3: 27 02
        LDAA    #$01                                    ; @ E0F5: 86 01
loc_E0F7:
        STAA    DP_005D                                 ; @ E0F7: 97 5D
        STAA    RAM_801A                                ; @ E0F9: B7 80 1A
        LDAB    #$30                                    ; @ E0FC: C6 30
        ORAB    DP_0037                                 ; @ E0FE: DA 37
        STAB    DP_0037                                 ; @ E100: D7 37
        LDAB    #$FF                                    ; @ E102: C6 FF
        STAB    RAM_8018                                ; @ E104: F7 80 18
        LDAB    #$20                                    ; @ E107: C6 20
        JSR     sub_CB28                                ; appelle sub_CB28 ; @ E109: BD CB 28
        JMP     loc_E172                                ; transfert sans retour vers loc_E172 ; @ E10C: 7E E1 72
loc_E10F:
        LDAB    RAM_800B                                ; @ E10F: F6 80 0B
        CMPB    RAM_8043                                ; @ E112: F1 80 43
        BCS     loc_E11B                                ; branche vers loc_E11B si la condition CS est vraie ; @ E115: 25 04
        BEQ     loc_E11B                                ; branche vers loc_E11B si la condition EQ est vraie ; @ E117: 27 02
        LDAB    #$01                                    ; @ E119: C6 01
loc_E11B:
        STAB    RAM_800B                                ; @ E11B: F7 80 0B
        LDAB    RAM_800A                                ; @ E11E: F6 80 0A
        CMPB    RAM_8043                                ; @ E121: F1 80 43
        BCS     loc_E12B                                ; branche vers loc_E12B si la condition CS est vraie ; @ E124: 25 05
        BEQ     loc_E12B                                ; branche vers loc_E12B si la condition EQ est vraie ; @ E126: 27 03
        LDAB    RAM_8043                                ; @ E128: F6 80 43
loc_E12B:
        STAB    RAM_800A                                ; @ E12B: F7 80 0A
        LDAB    RAM_800B                                ; @ E12E: F6 80 0B
        LDAA    RAM_800A                                ; @ E131: B6 80 0A
        CBA                                             ; @ E134: 11
        BCC     loc_E13D                                ; branche vers loc_E13D si la condition CC est vraie ; @ E135: 24 06
        LDAB    RAM_800A                                ; @ E137: F6 80 0A
        LDAA    RAM_800B                                ; @ E13A: B6 80 0B
loc_E13D:
        STAB    RAM_800B                                ; @ E13D: F7 80 0B
        STAB    RAM_801B                                ; @ E140: F7 80 1B
        BITB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E143: C5 0F
        BNE     loc_E14D                                ; branche vers loc_E14D si la condition NE est vraie ; @ E145: 26 06
        BITB    #$FF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E147: C5 FF
        BEQ     loc_E14D                                ; branche vers loc_E14D si la condition EQ est vraie ; @ E149: 27 02
        SUBB    #$06                                    ; @ E14B: C0 06
loc_E14D:
        DECB                                            ; @ E14D: 5A
        STAB    RAM_800D                                ; @ E14E: F7 80 0D
        STAA    RAM_800A                                ; @ E151: B7 80 0A
        STAA    RAM_8019                                ; @ E154: B7 80 19
        INCB                                            ; @ E157: 5C
        TSTB                                            ; @ E158: 5D
        BNE     loc_E15E                                ; branche vers loc_E15E si la condition NE est vraie ; @ E159: 26 03
loc_E15B:
        JMP     loc_DFFC                                ; transfert sans retour vers loc_DFFC ; @ E15B: 7E DF FC
loc_E15E:
        TSTA                                            ; @ E15E: 4D
        BEQ     loc_E15B                                ; branche vers loc_E15B si la condition EQ est vraie ; @ E15F: 27 FA
        LDX     RAM_800A                                ; @ E161: FE 80 0A
        STX     DP_001E                                 ; @ E164: DF 1E
        LDAB    #$B0                                    ; @ E166: C6 B0
        ORAB    DP_0037                                 ; @ E168: DA 37
        STAB    DP_0037                                 ; @ E16A: D7 37
        LDAB    #$80                                    ; @ E16C: C6 80
        JSR     sub_CB28                                ; appelle sub_CB28 ; @ E16E: BD CB 28
        RTS                                             ; @ E171: 39
loc_E172:
        LDAB    DP_005D                                 ; @ E172: D6 5D
        TSTB                                            ; @ E174: 5D
        BNE     loc_E17A                                ; branche vers loc_E17A si la condition NE est vraie ; @ E175: 26 03
        JMP     loc_D388                                ; transfert sans retour vers loc_D388 ; @ E177: 7E D3 88
loc_E17A:
        LDAA    RAM_8043                                ; @ E17A: B6 80 43
        CBA                                             ; @ E17D: 11
        BCC     loc_E183                                ; branche vers loc_E183 si la condition CC est vraie ; @ E17E: 24 03
        JMP     sub_CAE9                                ; transfert sans retour vers sub_CAE9 ; @ E180: 7E CA E9
loc_E183:
        TBA                                             ; @ E183: 17
        LDX     #DP_000E                                ; @ E184: CE 00 0E
        STX     DP_0061                                 ; @ E187: DF 61
        LDAB    #$14                                    ; @ E189: C6 14
        STAB    DP_0060                                 ; @ E18B: D7 60
        TAB                                             ; @ E18D: 16
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E18E: C4 F0
        LSRB                                            ; @ E190: 54
        LSRB                                            ; @ E191: 54
        SBA                                             ; @ E192: 10
        LSRB                                            ; @ E193: 54
        SBA                                             ; @ E194: 10
        CMPA    #$2C                                    ; @ E195: 81 2C
        BCS     loc_E1A1                                ; branche vers loc_E1A1 si la condition CS est vraie ; @ E197: 25 08
        SUBA    #$2C                                    ; @ E199: 80 2C
        CMPA    #$30                                    ; @ E19B: 81 30
        BCS     loc_E1A1                                ; branche vers loc_E1A1 si la condition CS est vraie ; @ E19D: 25 02
        SUBA    #$30                                    ; @ E19F: 80 30
loc_E1A1:
        LDX     #DP_0015                                ; @ E1A1: CE 00 15
        CLR     >DP_0072                                ; @ E1A4: 7F 00 72
        STAA    DP_0073                                 ; @ E1A7: 97 73
        JSR     sub_C9DD                                ; appelle sub_C9DD ; @ E1A9: BD C9 DD
        LDX     #RAM_8C64                               ; @ E1AC: CE 8C 64
        LDAA    DP_005D                                 ; @ E1AF: 96 5D
        CMPA    #$44                                    ; @ E1B1: 81 44
        BCS     loc_E1BF                                ; branche vers loc_E1BF si la condition CS est vraie ; @ E1B3: 25 0A
        LDX     #RAM_9000                               ; @ E1B5: CE 90 00
        CMPA    #$92                                    ; @ E1B8: 81 92
        BCS     loc_E1BF                                ; branche vers loc_E1BF si la condition CS est vraie ; @ E1BA: 25 03
        LDX     #RAM_9400                               ; @ E1BC: CE 94 00
loc_E1BF:
        STX     DP_005E                                 ; @ E1BF: DF 5E
        LDAA    DP_005F                                 ; @ E1C1: 96 5F
        ADDA    DP_0077                                 ; @ E1C3: 9B 77
        STAA    DP_005F                                 ; @ E1C5: 97 5F
        LDAA    DP_005E                                 ; @ E1C7: 96 5E
        ADCA    DP_0076                                 ; @ E1C9: 99 76
        STAA    DP_005E                                 ; @ E1CB: 97 5E
        LDAB    #$02                                    ; @ E1CD: C6 02
        LDAA    DP_0049                                 ; @ E1CF: 96 49
        CMPA    #$84                                    ; @ E1D1: 81 84
        BEQ     loc_E1D8                                ; branche vers loc_E1D8 si la condition EQ est vraie ; @ E1D3: 27 03
        LSRA                                            ; @ E1D5: 44
        BCC     loc_E1F9                                ; branche vers loc_E1F9 si la condition CC est vraie ; @ E1D6: 24 21
loc_E1D8:
        INC     >DP_0062                                ; @ E1D8: 7C 00 62
        JMP     loc_C428                                ; transfert sans retour vers loc_C428 ; @ E1DB: 7E C4 28

; ---------------------------------------------------------------------------
; ROUTINE $E1DE — nmi_power_fail_handler
; CONFIRMÉ — gestionnaire NMI de perte de présence alimentation.
; Entrées : front de chute PA câblé directement sur NMI; contexte empilé matériellement.
; Sorties : état utile préparé/sauvegardé avant disparition de l'alimentation.
; Registres/flags : A, B, X et pile modifiés; la routine suit une voie dédiée de sauvegarde.
; RAM/E/S : exploite les signatures RAM ($8041 vaut normalement $AA/$55) et la zone non volatile associée.
; Algorithme : vérifie l'intégrité de l'état, prépare les pointeurs et recopie les groupes de paramètres à conserver.
; ---------------------------------------------------------------------------
nmi_power_fail_handler:
        LDAA    RAM_8041                                ; @ E1DE: B6 80 41
        CMPA    #$AA                                    ; @ E1E1: 81 AA
        BEQ     loc_E1E8                                ; branche vers loc_E1E8 si la condition EQ est vraie ; @ E1E3: 27 03
        JMP     loc_E23D                                ; transfert sans retour vers loc_E23D ; @ E1E5: 7E E2 3D
loc_E1E8:
        LDX     #RAM_8C00                               ; @ E1E8: CE 8C 00
        STX     DP_005E                                 ; @ E1EB: DF 5E
        LDX     #ROM_DATA_FFFF                          ; @ E1ED: CE FF FF
        STX     DP_0061                                 ; @ E1F0: DF 61
        LDAB    #$23                                    ; @ E1F2: C6 23
        STAB    DP_0060                                 ; @ E1F4: D7 60
        CLRB                                            ; @ E1F6: 5F
        STAB    DP_005D                                 ; @ E1F7: D7 5D
loc_E1F9:
        LDAA    #$87                                    ; @ E1F9: 86 87
        STAA    DP_0049                                 ; @ E1FB: 97 49
        BITB    DP_003D                                 ; @ E1FD: D5 3D
        BNE     loc_E209                                ; branche vers loc_E209 si la condition NE est vraie ; @ E1FF: 26 08
        LDX     DP_0023                                 ; @ E201: DE 23
        STX     DP_000F                                 ; @ E203: DF 0F
        LDAA    DP_0025                                 ; @ E205: 96 25
        STAA    DP_0011                                 ; @ E207: 97 11
loc_E209:
        LDX     #DP_000C                                ; @ E209: CE 00 0C
loc_E20C:
        BITB    $3B,X                                   ; @ E20C: E5 3B
        BNE     loc_E218                                ; branche vers loc_E218 si la condition NE est vraie ; @ E20E: 26 08
        LDAA    $24,X                                   ; @ E210: A6 24
        STAA    $10,X                                   ; @ E212: A7 10
        LDAA    $25,X                                   ; @ E214: A6 25
        STAA    $11,X                                   ; @ E216: A7 11
loc_E218:
        DEX                                             ; @ E218: 09
        DEX                                             ; @ E219: 09
        BNE     loc_E20C                                ; branche vers loc_E20C si la condition NE est vraie ; @ E21A: 26 F0
        JSR     sub_C687                                ; appelle sub_C687 ; @ E21C: BD C6 87
        LDAA    DP_001A                                 ; @ E21F: 96 1A
        PSHA                                            ; @ E221: 36
        LDAB    DP_0045                                 ; @ E222: D6 45
        BITB    #$05                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E224: C5 05
        BNE     loc_E22A                                ; branche vers loc_E22A si la condition NE est vraie ; @ E226: 26 02
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E228: 8A 20
loc_E22A:
        LDAB    DP_004C                                 ; @ E22A: D6 4C
        ASLB                                            ; @ E22C: 58
        ABA                                             ; @ E22D: 1B
        STAA    DP_001A                                 ; @ E22E: 97 1A
        LDAB    DP_0060                                 ; @ E230: D6 60
        LDX     DP_0061                                 ; @ E232: DE 61
        BSR     sub_E243                                ; appelle sub_E243 ; @ E234: 8D 0D
        PULA                                            ; @ E236: 32
        STAA    DP_001A                                 ; @ E237: 97 1A
        LDAA    DP_005D                                 ; @ E239: 96 5D
        BNE     loc_E241                                ; branche vers loc_E241 si la condition NE est vraie ; @ E23B: 26 04
loc_E23D:
        STAA    MEM_1000                                ; @ E23D: B7 10 00
        WAI                                             ; @ E240: 3E
loc_E241:
        CLI                                             ; autorise à nouveau les IRQ ; @ E241: 0E
        RTS                                             ; @ E242: 39

; ---------------------------------------------------------------------------
; ROUTINE $E243 — sub_E243
; INCONNU — sous-routine interne à $E243; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $E234. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_E243:
        SEI                                             ; masque les IRQ pendant la section critique ; @ E243: 0F
        STS     RAM_8000                                ; @ E244: BF 80 00
        LDS     DP_0061                                 ; @ E247: 9E 61
        LDAB    DP_0060                                 ; @ E249: D6 60
        LDX     DP_005E                                 ; @ E24B: DE 5E
        CLR     >DP_0060                                ; @ E24D: 7F 00 60
loc_E250:
        PULA                                            ; @ E250: 32
loc_E251:
        STAA    ,X                                      ; @ E251: A7 00
        ADDA    DP_0060                                 ; @ E253: 9B 60
        STAA    DP_0060                                 ; @ E255: 97 60
        INX                                             ; @ E257: 08
        LDAA    #$55                                    ; @ E258: 86 55
        SUBA    DP_0060                                 ; @ E25A: 90 60
        DECB                                            ; @ E25C: 5A
        BGT     loc_E250                                ; branche vers loc_E250 si la condition GT est vraie ; @ E25D: 2E F1
        BEQ     loc_E251                                ; branche vers loc_E251 si la condition EQ est vraie ; @ E25F: 27 F0
        LDS     RAM_8000                                ; @ E261: BE 80 00
        RTS                                             ; @ E264: 39
        FCB     $01,$E2,$B6,$60,$E3,$CB,$64,$E3         ; données '...`..d.' ; @ E265: 01 E2 B6 60 E3 CB 64 E3
        FCB     $FB,$40,$E4,$55,$44,$E4,$6B,$80         ; données '.@.UD.k.' ; @ E26D: FB 40 E4 55 44 E4 6B 80
        FCB     $E4,$83,$84,$E4,$89,$98,$E4,$8F         ; données '........' ; @ E275: E4 83 84 E4 89 98 E4 8F
loc_E27D:
        LDX     #ROM_DATA_E265                          ; @ E27D: CE E2 65
        LDAB    #$08                                    ; @ E280: C6 08
loc_E282:
        CMPA    ,X                                      ; @ E282: A1 00
        BNE     loc_E29A                                ; branche vers loc_E29A si la condition NE est vraie ; @ E284: 26 14
        STAA    RAM_8020                                ; @ E286: B7 80 20
        STAA    DP_005D                                 ; @ E289: 97 5D
        LDAB    #$A0                                    ; @ E28B: C6 A0
        ORAB    DP_0037                                 ; @ E28D: DA 37
        STAB    DP_0037                                 ; @ E28F: D7 37
        LDAB    #$40                                    ; @ E291: C6 40
        JSR     sub_CB28                                ; appelle sub_CB28 ; @ E293: BD CB 28
        LDX     $01,X                                   ; @ E296: EE 01
        JMP     ,X                                      ; transfert sans retour vers ,X ; @ E298: 6E 00
loc_E29A:
        INX                                             ; @ E29A: 08
        INX                                             ; @ E29B: 08
        INX                                             ; @ E29C: 08
        DECB                                            ; @ E29D: 5A
        BNE     loc_E282                                ; branche vers loc_E282 si la condition NE est vraie ; @ E29E: 26 E2
        LDAB    #$FF                                    ; @ E2A0: C6 FF
        STAB    DP_0049                                 ; @ E2A2: D7 49
        LDAA    DP_003C                                 ; @ E2A4: 96 3C
        BMI     loc_E2AD                                ; branche vers loc_E2AD si la condition MI est vraie ; @ E2A6: 2B 05
        LDAA    #$91                                    ; @ E2A8: 86 91
        JSR     sub_CAE9                                ; appelle sub_CAE9 ; @ E2AA: BD CA E9
loc_E2AD:
        LDAA    DP_003D                                 ; @ E2AD: 96 3D
        ORAA    #$60                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E2AF: 8A 60
        STAA    DP_003D                                 ; @ E2B1: 97 3D
        JMP     loc_C522                                ; transfert sans retour vers loc_C522 ; @ E2B3: 7E C5 22
        FCB     $CE,$7F,$FF,$08,$8C,$A0,$00,$27         ; données '.......'' ; @ E2B6: CE 7F FF 08 8C A0 00 27
        FCB     $22,$A6,$00,$97,$7B,$86,$01,$A7         ; données '"...{...' ; @ E2BE: 22 A6 00 97 7B 86 01 A7
        FCB     $00,$63,$00,$E6,$00,$53,$11,$27         ; données '.c...S.'' ; @ E2C6: 00 63 00 E6 00 53 11 27
        FCB     $09,$D6,$7B,$E7,$00,$86,$01,$7E         ; données '..{....~' ; @ E2CE: 09 D6 7B E7 00 86 01 7E
        FCB     $CA,$E9,$49,$24,$EA,$D6,$7B,$E7         ; données '..I$..{.' ; @ E2D6: CA E9 49 24 EA D6 7B E7
        FCB     $00,$20,$D8,$39,$DE,$4B,$27,$05         ; données '. .9.K'.' ; @ E2DE: 00 20 D8 39 DE 4B 27 05
        FCB     $86,$18,$7E,$CA,$E9,$D6,$3D,$C5         ; données '..~...=.' ; @ E2E6: 86 18 7E CA E9 D6 3D C5
        FCB     $02,$26,$01,$39,$DE,$00,$DF,$5E         ; données '.&.9...^' ; @ E2EE: 02 26 01 39 DE 00 DF 5E
        FCB     $DE,$02,$DF,$60,$96,$5E,$16,$C4         ; données '...`.^..' ; @ E2F6: DE 02 DF 60 96 5E 16 C4
        FCB     $F0,$54,$54,$10,$54,$10,$D6,$5F         ; données '.TT.T.._' ; @ E2FE: F0 54 54 10 54 10 D6 5F
        FCB     $C4,$0F,$C1,$03,$24,$DA,$5D,$27         ; données '....$.]'' ; @ E306: C4 0F C1 03 24 DA 5D 27
        FCB     $0A,$8B,$64,$C1,$02,$2D,$04,$8B         ; données '..d..-..' ; @ E30E: 0A 8B 64 C1 02 2D 04 8B
        FCB     $64,$25,$CD,$97,$74,$CE,$00,$0C         ; données 'd%..t...' ; @ E316: 64 25 CD 97 74 CE 00 0C
        FCB     $74,$00,$61,$76,$00,$60,$76,$00         ; données 't.av.`v.' ; @ E31E: 74 00 61 76 00 60 76 00
        FCB     $5F,$76,$00,$5E,$09,$26,$F1,$CE         ; données '_v.^.&..' ; @ E326: 5F 76 00 5E 09 26 F1 CE
        FCB     $00,$00,$DF,$72,$CE,$68,$27,$DF         ; données '...r.h'.' ; @ E32E: 00 00 DF 72 CE 68 27 DF
        FCB     $6D,$CE,$03,$00,$DF,$6F,$CE,$00         ; données 'm....o..' ; @ E336: 6D CE 03 00 DF 6F CE 00
        FCB     $6D,$BD,$E3,$8F,$79,$00,$73,$79         ; données 'm...y.sy' ; @ E33E: 6D BD E3 8F 79 00 73 79
        FCB     $00,$72,$96,$73,$44,$25,$25,$CE         ; données '.r.sD%%.' ; @ E346: 00 72 96 73 44 25 25 CE
        FCB     $00,$5E,$C6,$04,$A6,$03,$36,$09         ; données '.^....6.' ; @ E34E: 00 5E C6 04 A6 03 36 09
        FCB     $5A,$26,$F9,$CE,$FF,$FC,$86,$99         ; données 'Z&......' ; @ E356: 5A 26 F9 CE FF FC 86 99
        FCB     $A0,$71,$A7,$62,$08,$26,$F7,$0D         ; données '.q.b.&..' ; @ E35E: A0 71 A7 62 08 26 F7 0D
        FCB     $CE,$FF,$FC,$32,$A9,$62,$19,$A7         ; données '...2.b..' ; @ E366: CE FF FC 32 A9 62 19 A7
        FCB     $62,$08,$26,$F7,$BD,$E3,$A1,$DE         ; données 'b.&.....' ; @ E36E: 62 08 26 F7 BD E3 A1 DE
        FCB     $6D,$26,$C3,$86,$FF,$16,$98,$73         ; données 'm&.....s' ; @ E376: 6D 26 C3 86 FF 16 98 73
        FCB     $97,$73,$D8,$72,$D7,$72,$DE,$72         ; données '.s.r.r.r' ; @ E37E: 97 73 D8 72 D7 72 DE 72
        FCB     $96,$74,$A7,$00,$C6,$60,$D7,$3B         ; données '.t...`.;' ; @ E386: 96 74 A7 00 C6 60 D7 3B
        FCB     $39,$0C,$96,$5E,$A2,$00,$96,$5F         ; données '9..^..._' ; @ E38E: 39 0C 96 5E A2 00 96 5F
        FCB     $A2,$01,$96,$60,$A2,$02,$96,$61         ; données '...`...a' ; @ E396: A2 01 96 60 A2 02 96 61
        FCB     $A2,$03,$39,$0C,$74,$00,$70,$76         ; données '..9.t.pv' ; @ E39E: A2 03 39 0C 74 00 70 76
        FCB     $00,$6F,$76,$00,$6E,$76,$00,$6D         ; données '.ov.nv.m' ; @ E3A6: 00 6F 76 00 6E 76 00 6D
        FCB     $CE,$FF,$FD,$A6,$70,$16,$84,$0F         ; données '....p...' ; @ E3AE: CE FF FD A6 70 16 84 0F
        FCB     $81,$08,$25,$02,$80,$03,$C4,$F0         ; données '..%.....' ; @ E3B6: 81 08 25 02 80 03 C4 F0
        FCB     $C1,$80,$25,$02,$C0,$30,$1B,$A7         ; données '..%..0..' ; @ E3BE: C1 80 25 02 C0 30 1B A7
        FCB     $70,$08,$26,$E7,$39,$B6,$80,$08         ; données 'p.&.9...' ; @ E3C6: 70 08 26 E7 39 B6 80 08
        FCB     $44,$25,$0B,$B6,$85,$05,$84,$DF         ; données 'D%......' ; @ E3CE: 44 25 0B B6 85 05 84 DF
        FCB     $B7,$60,$05,$B7,$85,$05,$B6,$80         ; données '.`......' ; @ E3D6: B7 60 05 B7 85 05 B6 80
        FCB     $26,$9A,$48,$84,$FC,$B7,$80,$26         ; données '&.H....&' ; @ E3DE: 26 9A 48 84 FC B7 80 26
        FCB     $96,$47,$85,$01,$27,$04,$8A,$40         ; données '.G..'..@' ; @ E3E6: 96 47 85 01 27 04 8A 40
        FCB     $97,$47,$86,$40,$9A,$45,$97,$45         ; données '.G.@.E.E' ; @ E3EE: 97 47 86 40 9A 45 97 45
        FCB     $C6,$02,$7E,$DE,$31,$B6,$80,$0C         ; données '..~.1...' ; @ E3F6: C6 02 7E DE 31 B6 80 0C
        FCB     $85,$10,$26,$05,$86,$64,$7E,$CA         ; données '..&..d~.' ; @ E3FE: 85 10 26 05 86 64 7E CA
        FCB     $E9,$96,$48,$85,$40,$27,$05,$86         ; données '..H.@'..' ; @ E406: E9 96 48 85 40 27 05 86
        FCB     $79,$7E,$CA,$E9,$B6,$85,$05,$8A         ; données 'y~......' ; @ E40E: 79 7E CA E9 B6 85 05 8A
        FCB     $20,$B7,$60,$05,$B7,$85,$05,$B6         ; données ' .`.....' ; @ E416: 20 B7 60 05 B7 85 05 B6
        FCB     $80,$26,$8A,$02,$B7,$80,$26,$96         ; données '.&....&.' ; @ E41E: 80 26 8A 02 B7 80 26 96
        FCB     $1B,$26,$16,$96,$1A,$84,$03,$26         ; données '.&.....&' ; @ E426: 1B 26 16 96 1A 84 03 26
        FCB     $10,$86,$AA,$B7,$80,$16,$B7,$80         ; données '........' ; @ E42E: 10 86 AA B7 80 16 B7 80
        FCB     $15,$86,$F0,$BA,$80,$26,$B7,$80         ; données '.....&..' ; @ E436: 15 86 F0 BA 80 26 B7 80
        FCB     $26,$CE,$00,$00,$DF,$1C,$DF,$30         ; données '&......0' ; @ E43E: 26 CE 00 00 DF 1C DF 30
        FCB     $C6,$02,$FA,$80,$26,$C4,$FE,$F7         ; données '....&...' ; @ E446: C6 02 FA 80 26 C4 FE F7
        FCB     $80,$26,$C6,$02,$7E,$DE,$31,$D6         ; données '.&..~.1.' ; @ E44E: 80 26 C6 02 7E DE 31 D6
        FCB     $42,$C4,$8F,$D7,$42,$86,$EF,$97         ; données 'B...B...' ; @ E456: 42 C4 8F D7 42 86 EF 97
        FCB     $59,$CE,$00,$86,$DF,$57,$96,$41         ; données 'Y....W.A' ; @ E45E: 59 CE 00 86 DF 57 96 41
        FCB     $8A,$40,$97,$41,$39,$C6,$40,$DA         ; données '.@.A9.@.' ; @ E466: 8A 40 97 41 39 C6 40 DA
        FCB     $42,$D7,$42,$CE,$70,$96,$DF,$57         ; données 'B.B.p..W' ; @ E46E: 42 D7 42 CE 70 96 DF 57
        FCB     $86,$F6,$97,$59,$D6,$41,$CA,$48         ; données '...Y.A.H' ; @ E476: 86 F6 97 59 D6 41 CA 48
        FCB     $D7,$41,$7E,$CF,$E9,$86,$00,$B7         ; données '.A~.....' ; @ E47E: D7 41 7E CF E9 86 00 B7
        FCB     $80,$44,$39,$86,$01,$B7,$80,$44         ; données '.D9....D' ; @ E486: 80 44 39 86 01 B7 80 44
        FCB     $39,$BD,$C6,$87,$C6,$02,$CE,$FF         ; données '9.......' ; @ E48E: 39 BD C6 87 C6 02 CE FF
        FCB     $FF,$FF,$8C,$00,$09,$26,$FD,$5A         ; données '.....&.Z' ; @ E496: FF FF 8C 00 09 26 FD 5A
        FCB     $26,$F4,$86,$80,$B7,$40,$03,$7F         ; données '&....@..' ; @ E49E: 26 F4 86 80 B7 40 03 7F
        FCB     $00,$3A,$7E,$C3,$3F,$BD,$C6,$87         ; données '.:~.?...' ; @ E4A6: 00 3A 7E C3 3F BD C6 87
        FCB     $C6,$FF,$CE,$8C,$64,$E7,$00,$08         ; données '....d...' ; @ E4AE: C6 FF CE 8C 64 E7 00 08
        FCB     $8C,$94,$7F,$26,$F8,$20,$E6,$46         ; données '...&. .F' ; @ E4B6: 8C 94 7F 26 F8 20 E6 46
        FCB     $20,$20,$20,$41,$20,$20,$20,$25         ; données '   A   %' ; @ E4BE: 20 20 20 41 20 20 20 25
        FCB     $20,$50,$20,$44,$20,$53,$51,$4D         ; données ' P D SQM' ; @ E4C6: 20 50 20 44 20 53 51 4D
        FCB     $20,$52,$4D,$53,$50,$41,$4D,$46         ; données ' RMSPAMF' ; @ E4CE: 20 52 4D 53 50 41 4D 46
        FCB     $4D,$50,$4D,$52,$46,$20,$20,$50         ; données 'MPMRF  P' ; @ E4D6: 4D 50 4D 52 46 20 20 50
        FCB     $52,$52,$44,$45,$46                     ; données 'RRDEF' ; @ E4DE: 52 52 44 45 46

; ---------------------------------------------------------------------------
; ROUTINE $E4E3 — sub_E4E3
; INCONNU — sous-routine interne à $E4E3; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C62A. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_E4E3:
        DECA                                            ; @ E4E3: 4A
        STAA    DP_0039                                 ; @ E4E4: 97 39
        BMI     loc_E4ED                                ; branche vers loc_E4ED si la condition MI est vraie ; @ E4E6: 2B 05
        LDAA    #$A7                                    ; @ E4E8: 86 A7
        STAA    PIA_PORT_A_OR_DDRA                      ; accès au PIA 6821 du panneau avant ; @ E4EA: B7 40 00
loc_E4ED:
        LDX     DP_0055                                 ; @ E4ED: DE 55
        LDAA    ,X                                      ; @ E4EF: A6 00
        INC     >DP_0056                                ; @ E4F1: 7C 00 56
        LDAB    RAM_8047                                ; @ E4F4: F6 80 47
        BPL     loc_E4FC                                ; branche vers loc_E4FC si la condition PL est vraie ; @ E4F7: 2A 03
        JMP     resume_front_panel_dispatch             ; transfert sans retour vers resume_front_panel_dispatch ; @ E4F9: 7E F0 8F
loc_E4FC:
        CLI                                             ; autorise à nouveau les IRQ ; @ E4FC: 0E
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E4FD: 85 40
        BEQ     loc_E503                                ; branche vers loc_E503 si la condition EQ est vraie ; @ E4FF: 27 02
        ANDA    #$5F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E501: 84 5F
loc_E503:
        LDAB    DP_0069                                 ; @ E503: D6 69
        BEQ     loc_E55E                                ; branche vers loc_E55E si la condition EQ est vraie ; @ E505: 27 57
        BPL     loc_E50C                                ; branche vers loc_E50C si la condition PL est vraie ; @ E507: 2A 03
        JMP     loc_E5EE                                ; transfert sans retour vers loc_E5EE ; @ E509: 7E E5 EE
loc_E50C:
        JMP     loc_E5A9                                ; transfert sans retour vers loc_E5A9 ; @ E50C: 7E E5 A9
loc_E50F:
        CMPA    ,X                                      ; @ E50F: A1 00
        BNE     loc_E523                                ; branche vers loc_E523 si la condition NE est vraie ; @ E511: 26 10
loc_E513:
        LDAA    loc_E07A                                ; @ E513: 96 7A
        CMPA    $01,X                                   ; @ E515: A1 01
        BEQ     loc_E532                                ; branche vers loc_E532 si la condition EQ est vraie ; @ E517: 27 19
        LDAA    $01,X                                   ; @ E519: A6 01
        CMPA    #$20                                    ; @ E51B: 81 20
        BNE     loc_E521                                ; branche vers loc_E521 si la condition NE est vraie ; @ E51D: 26 02
        STAB    DP_0069                                 ; @ E51F: D7 69
loc_E521:
        LDAA    DP_0079                                 ; @ E521: 96 79
loc_E523:
        DEX                                             ; @ E523: 09
        DEX                                             ; @ E524: 09
        DECB                                            ; @ E525: 5A
        BNE     loc_E50F                                ; branche vers loc_E50F si la condition NE est vraie ; @ E526: 26 E7
        LDAB    DP_0069                                 ; @ E528: D6 69
        BEQ     loc_E572                                ; branche vers loc_E572 si la condition EQ est vraie ; @ E52A: 27 46
        INC     >DP_0039                                ; @ E52C: 7C 00 39
        DEC     >DP_0056                                ; @ E52F: 7A 00 56
loc_E532:
        STAB    DP_0069                                 ; @ E532: D7 69
        CLRA                                            ; @ E534: 4F
        STAA    RAM_8004                                ; @ E535: B7 80 04
        STAA    DP_0078                                 ; @ E538: 97 78
        STAA    DP_0071                                 ; @ E53A: 97 71
        STAA    DP_0079                                 ; @ E53C: 97 79
        INCA                                            ; @ E53E: 4C
        STAA    RAM_8002                                ; @ E53F: B7 80 02
        STAA    RAM_8003                                ; @ E542: B7 80 03
        LDX     #DP_0000                                ; @ E545: CE 00 00
        STX     DP_006D                                 ; @ E548: DF 6D
        STX     DP_006F                                 ; @ E54A: DF 6F
        CMPB    #$0B                                    ; @ E54C: C1 0B
        BGT     loc_E55D                                ; branche vers loc_E55D si la condition GT est vraie ; @ E54E: 2E 0D
        CMPB    #$07                                    ; @ E550: C1 07
        BLE     loc_E556                                ; branche vers loc_E556 si la condition LE est vraie ; @ E552: 2F 02
        ADDB    #$04                                    ; @ E554: CB 04
loc_E556:
        LDX     loc_E04B                                ; @ E556: DE 4B
        LDAA    $3D,X                                   ; @ E558: A6 3D
        JMP     loc_D748                                ; transfert sans retour vers loc_D748 ; @ E55A: 7E D7 48
loc_E55D:
        RTS                                             ; @ E55D: 39
loc_E55E:
        STAA    loc_E07A                                ; @ E55E: 97 7A
        LDAA    DP_0079                                 ; @ E560: 96 79
        BEQ     loc_E575                                ; branche vers loc_E575 si la condition EQ est vraie ; @ E562: 27 11
        LDAB    #$13                                    ; @ E564: C6 13
        LDX     #ROM_DATA_E4E1                          ; @ E566: CE E4 E1
loc_E569:
        CMPA    ,X                                      ; @ E569: A1 00
        BEQ     loc_E513                                ; branche vers loc_E513 si la condition EQ est vraie ; @ E56B: 27 A6
        DEX                                             ; @ E56D: 09
        DEX                                             ; @ E56E: 09
        DECB                                            ; @ E56F: 5A
        BNE     loc_E569                                ; branche vers loc_E569 si la condition NE est vraie ; @ E570: 26 F7
loc_E572:
        INC     RAM_8048                                ; @ E572: 7C 80 48
loc_E575:
        LDAA    loc_E07A                                ; @ E575: 96 7A
loc_E577:
        LDAB    DP_006A                                 ; @ E577: D6 6A
        CMPA    #$21                                    ; @ E579: 81 21
        BNE     loc_E581                                ; branche vers loc_E581 si la condition NE est vraie ; @ E57B: 26 04
        CLRA                                            ; @ E57D: 4F
loc_E57E:
        STAA    DP_0079                                 ; @ E57E: 97 79
loc_E580:
        RTS                                             ; @ E580: 39
loc_E581:
        CMPA    #$0D                                    ; @ E581: 81 0D
        BNE     loc_E57E                                ; branche vers loc_E57E si la condition NE est vraie ; @ E583: 26 F9
        TSTB                                            ; @ E585: 5D
        BMI     loc_E580                                ; branche vers loc_E580 si la condition MI est vraie ; @ E586: 2B F8
        CLR     >DP_0069                                ; @ E588: 7F 00 69
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E58B: C4 7F
        STAB    DP_006A                                 ; @ E58D: D7 6A
        LDX     #DP_0000                                ; @ E58F: CE 00 00
        STX     DP_0079                                 ; @ E592: DF 79
        TST     RAM_8048                                ; @ E594: 7D 80 48
        BEQ     loc_E5A5                                ; branche vers loc_E5A5 si la condition EQ est vraie ; @ E597: 27 0C
        LDAA    #$70                                    ; @ E599: 86 70
        SEI                                             ; masque les IRQ pendant la section critique ; @ E59B: 0F
        STAA    DP_003A                                 ; @ E59C: 97 3A
        STAA    PIA_CONTROL_A_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ E59E: B7 40 05
        CLI                                             ; autorise à nouveau les IRQ ; @ E5A1: 0E
        CLR     RAM_8048                                ; @ E5A2: 7F 80 48
loc_E5A5:
        JMP     loc_D5F3                                ; transfert sans retour vers loc_D5F3 ; @ E5A5: 7E D5 F3
        FCB     $39                                     ; données '9' ; @ E5A8: 39
loc_E5A9:
        CMPA    #$39                                    ; @ E5A9: 81 39
        BGT     loc_E5C7                                ; branche vers loc_E5C7 si la condition GT est vraie ; @ E5AB: 2E 1A
        CMPA    #$30                                    ; @ E5AD: 81 30
        BMI     loc_E5C7                                ; branche vers loc_E5C7 si la condition MI est vraie ; @ E5AF: 2B 16
        SUBA    #$30                                    ; @ E5B1: 80 30
        LDAB    RAM_8004                                ; @ E5B3: F6 80 04
        CMPB    #$0A                                    ; @ E5B6: C1 0A
        BEQ     loc_E5BE                                ; branche vers loc_E5BE si la condition EQ est vraie ; @ E5B8: 27 04
        TAB                                             ; @ E5BA: 16
        JMP     loc_D51E                                ; transfert sans retour vers loc_D51E ; @ E5BB: 7E D5 1E
loc_E5BE:
        LDAB    RAM_8002                                ; @ E5BE: F6 80 02
        BGT     loc_E5C4                                ; branche vers loc_E5C4 si la condition GT est vraie ; @ E5C1: 2E 01
        RTS                                             ; @ E5C3: 39
loc_E5C4:
        JMP     loc_E66D                                ; transfert sans retour vers loc_E66D ; @ E5C4: 7E E6 6D
loc_E5C7:
        CMPA    #$2E                                    ; @ E5C7: 81 2E
        BNE     loc_E5CF                                ; branche vers loc_E5CF si la condition NE est vraie ; @ E5C9: 26 04
        CLR     RAM_8002                                ; @ E5CB: 7F 80 02
        RTS                                             ; @ E5CE: 39
loc_E5CF:
        TST     RAM_8004                                ; @ E5CF: 7D 80 04
        BNE     loc_E5E5                                ; branche vers loc_E5E5 si la condition NE est vraie ; @ E5D2: 26 11
        CMPA    #$2D                                    ; @ E5D4: 81 2D
        BEQ     loc_E5E0                                ; branche vers loc_E5E0 si la condition EQ est vraie ; @ E5D6: 27 08
        LDX     #DP_0000                                ; @ E5D8: CE 00 00
        STX     DP_0079                                 ; @ E5DB: DF 79
        JMP     loc_E577                                ; transfert sans retour vers loc_E577 ; @ E5DD: 7E E5 77
loc_E5E0:
        ORAB    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E5E0: CA 20
        STAB    DP_0069                                 ; @ E5E2: D7 69
        RTS                                             ; @ E5E4: 39
loc_E5E5:
        CMPA    #$45                                    ; @ E5E5: 81 45
        BNE     loc_E61B                                ; branche vers loc_E61B si la condition NE est vraie ; @ E5E7: 26 32
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E5E9: CA 80
        STAB    DP_0069                                 ; @ E5EB: D7 69
        RTS                                             ; @ E5ED: 39
loc_E5EE:
        TST     RAM_8004                                ; @ E5EE: 7D 80 04
        BEQ     loc_E607                                ; branche vers loc_E607 si la condition EQ est vraie ; @ E5F1: 27 14
        CLR     RAM_8004                                ; @ E5F3: 7F 80 04
        CMPA    #$2B                                    ; @ E5F6: 81 2B
        BEQ     loc_E606                                ; branche vers loc_E606 si la condition EQ est vraie ; @ E5F8: 27 0C
        CMPA    #$20                                    ; @ E5FA: 81 20
        BEQ     loc_E606                                ; branche vers loc_E606 si la condition EQ est vraie ; @ E5FC: 27 08
        CMPA    #$2D                                    ; @ E5FE: 81 2D
        BNE     loc_E607                                ; branche vers loc_E607 si la condition NE est vraie ; @ E600: 26 05
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E602: CA 40
        STAB    DP_0069                                 ; @ E604: D7 69
loc_E606:
        RTS                                             ; @ E606: 39
loc_E607:
        CMPA    #$39                                    ; @ E607: 81 39
        BGT     loc_E621                                ; branche vers loc_E621 si la condition GT est vraie ; @ E609: 2E 16
        CMPA    #$30                                    ; @ E60B: 81 30
        BMI     loc_E621                                ; branche vers loc_E621 si la condition MI est vraie ; @ E60D: 2B 12
        SUBA    #$30                                    ; @ E60F: 80 30
        LDAB    DP_0078                                 ; @ E611: D6 78
        ASLB                                            ; @ E613: 58
        ASLB                                            ; @ E614: 58
        ABA                                             ; @ E615: 1B
        ASLB                                            ; @ E616: 58
        ABA                                             ; @ E617: 1B
        STAA    DP_0078                                 ; @ E618: 97 78
        RTS                                             ; @ E61A: 39
loc_E61B:
        CLR     >DP_0079                                ; @ E61B: 7F 00 79
        CLR     >loc_E07A                               ; @ E61E: 7F 00 7A
loc_E621:
        DEC     >DP_0056                                ; @ E621: 7A 00 56
        INC     >DP_0039                                ; @ E624: 7C 00 39
        LDAA    DP_0078                                 ; @ E627: 96 78
        BITB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E629: C5 40
        BEQ     loc_E62E                                ; branche vers loc_E62E si la condition EQ est vraie ; @ E62B: 27 01
        NEGA                                            ; @ E62D: 40
loc_E62E:
        ANDB    #$1F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E62E: C4 1F
        CMPB    #$07                                    ; @ E630: C1 07
        BLE     loc_E64E                                ; branche vers loc_E64E si la condition LE est vraie ; @ E632: 2F 1A
        STAB    DP_0060                                 ; @ E634: D7 60
        LDAB    RAM_8002                                ; @ E636: F6 80 02
        BPL     loc_E63C                                ; branche vers loc_E63C si la condition PL est vraie ; @ E639: 2A 01
        ABA                                             ; @ E63B: 1B
loc_E63C:
        TAB                                             ; @ E63C: 16
        JSR     sub_CA10                                ; appelle sub_CA10 ; @ E63D: BD CA 10
        BCS     loc_E66D                                ; branche vers loc_E66D si la condition CS est vraie ; @ E640: 25 2B
        LDX     DP_0070                                 ; @ E642: DE 70
        BNE     loc_E66D                                ; branche vers loc_E66D si la condition NE est vraie ; @ E644: 26 27
        LDX     DP_006E                                 ; @ E646: DE 6E
        BNE     loc_E663                                ; branche vers loc_E663 si la condition NE est vraie ; @ E648: 26 19
loc_E64A:
        LDAB    DP_0060                                 ; @ E64A: D6 60
        LDAA    DP_006D                                 ; @ E64C: 96 6D
loc_E64E:
        ASLB                                            ; @ E64E: 58
        LDX     #ROM_DATA_C276                          ; @ E64F: CE C2 76
        STX     DP_005E                                 ; @ E652: DF 5E
        ADDB    DP_005F                                 ; @ E654: DB 5F
        STAB    DP_005F                                 ; @ E656: D7 5F
        LDX     DP_005E                                 ; @ E658: DE 5E
        LDX     ,X                                      ; @ E65A: EE 00
        LDAB    DP_0069                                 ; @ E65C: D6 69
        CLR     >DP_0069                                ; @ E65E: 7F 00 69
        JMP     ,X                                      ; transfert sans retour vers ,X ; @ E661: 6E 00
loc_E663:
        LDAA    DP_006F                                 ; @ E663: 96 6F
        BNE     loc_E66D                                ; branche vers loc_E66D si la condition NE est vraie ; @ E665: 26 06
        LDAB    DP_0060                                 ; @ E667: D6 60
        CMPB    #$08                                    ; @ E669: C1 08
        BEQ     loc_E64A                                ; branche vers loc_E64A si la condition EQ est vraie ; @ E66B: 27 DD
loc_E66D:
        LDAA    #$91                                    ; @ E66D: 86 91
        CLR     >DP_0069                                ; @ E66F: 7F 00 69
        JMP     sub_CAE9                                ; transfert sans retour vers sub_CAE9 ; @ E672: 7E CA E9
        FCB     $01,$01,$CE,$00,$21,$81,$04,$24         ; données '....!..$' ; @ E675: 01 01 CE 00 21 81 04 24
        FCB     $EF,$81,$02,$25,$19,$D6,$48,$C5         ; données '...%..H.' ; @ E67D: EF 81 02 25 19 D6 48 C5
        FCB     $60,$27,$09,$86,$78,$C5,$20,$26         ; données '`'..x. &' ; @ E685: 60 27 09 86 78 C5 20 26
        FCB     $01,$4C,$20,$DE,$D6,$46,$C5,$40         ; données '.L ..F.@' ; @ E68D: 01 4C 20 DE D6 46 C5 40
        FCB     $27,$04,$86,$69,$20,$D4,$C6,$F7         ; données ''..i ...' ; @ E695: 27 04 86 69 20 D4 C6 F7
        FCB     $58,$4A,$2A,$FC,$A6,$00,$84,$0F         ; données 'XJ*.....' ; @ E69D: 58 4A 2A FC A6 00 84 0F
        FCB     $C4,$F0,$1B,$A7,$00,$96,$20,$B7         ; données '...... .' ; @ E6A5: C4 F0 1B A7 00 96 20 B7
        FCB     $80,$17,$96,$21,$B7,$80,$14,$F6         ; données '...!....' ; @ E6AD: 80 17 96 21 B7 80 14 F6
        FCB     $80,$08,$C4,$07,$85,$10,$27,$02         ; données '......'.' ; @ E6B5: 80 08 C4 07 85 10 27 02
        FCB     $CA,$08,$F7,$80,$08,$C6,$40,$44         ; données '......@D' ; @ E6BD: CA 08 F7 80 08 C6 40 44
        FCB     $25,$06,$DA,$45,$D7,$45,$20,$04         ; données '%..E.E .' ; @ E6C5: 25 06 DA 45 D7 45 20 04
        FCB     $DA,$47,$D7,$47,$86,$40,$9A,$37         ; données '.G.G.@.7' ; @ E6CD: DA 47 D7 47 86 40 9A 37
        FCB     $97,$37,$BD,$EC,$08,$39,$81,$01         ; données '.7...9..' ; @ E6D5: 97 37 BD EC 08 39 81 01
        FCB     $2E,$8E,$5F,$5A,$56,$4A,$2A,$FC         ; données '.._ZVJ*.' ; @ E6DD: 2E 8E 5F 5A 56 4A 2A FC
        FCB     $86,$0F,$C4,$F0,$94,$22,$1B,$97         ; données '....."..' ; @ E6E5: 86 0F C4 F0 94 22 1B 97
        FCB     $22,$B7,$80,$13,$86,$40,$9A,$37         ; données '"....@.7' ; @ E6ED: 22 B7 80 13 86 40 9A 37
        FCB     $97,$37,$7E,$DF,$73,$7E,$E6,$6D         ; données '.7~.s~.m' ; @ E6F5: 97 37 7E DF 73 7E E6 6D
        FCB     $01,$B1,$80,$43,$27,$02,$24,$F5         ; données '...C'.$.' ; @ E6FD: 01 B1 80 43 27 02 24 F5
        FCB     $CE,$EA,$FF,$FF,$80,$1B,$C6,$FF         ; données '........' ; @ E705: CE EA FF FF 80 1B C6 FF
        FCB     $F7,$80,$19,$7E,$E0,$EE,$D6,$49         ; données '...~...I' ; @ E70D: F7 80 19 7E E0 EE D6 49
        FCB     $7E,$E0,$D9,$DE,$6D,$26,$03,$7E         ; données '~...m&.~' ; @ E715: 7E E0 D9 DE 6D 26 03 7E
        FCB     $DF,$FC,$96,$6D,$B1,$80,$43,$27         ; données '...m..C'' ; @ E71D: DF FC 96 6D B1 80 43 27
        FCB     $02,$24,$D2,$96,$6E,$B1,$80,$43         ; données '.$..n..C' ; @ E725: 02 24 D2 96 6E B1 80 43
        FCB     $27,$02,$24,$C9,$FF,$80,$0A,$B6         ; données ''.$.....' ; @ E72D: 27 02 24 C9 FF 80 0A B6
        FCB     $80,$0B,$26,$02,$86,$01,$B7,$80         ; données '..&.....' ; @ E735: 80 0B 26 02 86 01 B7 80
        FCB     $0B,$7E,$E1,$0F,$81,$74,$26,$05         ; données '.~...t&.' ; @ E73D: 0B 7E E1 0F 81 74 26 05
        FCB     $86,$80,$B7,$80,$47,$39,$81,$74         ; données '....G9.t' ; @ E745: 86 80 B7 80 47 39 81 74
        FCB     $26,$05,$86,$C0,$B7,$80,$47,$39         ; données '&.....G9' ; @ E74D: 26 05 86 C0 B7 80 47 39
        FCB     $81,$74,$26,$05,$86,$A0,$B7,$80         ; données '.t&.....' ; @ E755: 81 74 26 05 86 A0 B7 80
        FCB     $47,$39                                 ; données 'G9' ; @ E75D: 47 39

; ---------------------------------------------------------------------------
; ROUTINE $E75F — program_frequency_plan
; CONFIRMÉ — calcul et programmation du plan de fréquence.
; Entrées : fréquence demandée sous forme BCD dans la zone de travail $8500/$851x.
; Sorties : séquence des adresses instruments 12, 15, 5, 11, 4, 13 puis 0..3.
; Registres/flags : A, B, X, S et CCR modifiés; pile de travail utilisée pour les chiffres BCD.
; RAM/E/S : images $8500..$8565 et registres $6000..$600F.
; Algorithme : choisit gamme directe/divisée/hétérodyne, calcule N=28..67, le reste de 8 MHz et les diviseurs 20000/80.
; ---------------------------------------------------------------------------
program_frequency_plan:
        SEI                                             ; masque les IRQ pendant la section critique ; @ E75F: 0F
        CLR     RAM_8565                                ; @ E760: 7F 85 65
        COM     RAM_8565                                ; @ E763: 73 85 65
        LDAA    RAM_850C                                ; @ E766: B6 85 0C
        ANDA    #$79                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E769: 84 79
        ADDA    #$06                                    ; @ E76B: 8B 06
        STAA    RAM_850C                                ; @ E76D: B7 85 0C
        STS     RAM_8000                                ; @ E770: BF 80 00
        LDS     #RAM_851F                               ; @ E773: 8E 85 1F
        LDX     #DP_0027                                ; @ E776: CE 00 27
        LDAB    #$05                                    ; @ E779: C6 05
loc_E77B:
        LDAA    ,X                                      ; @ E77B: A6 00
        PSHA                                            ; @ E77D: 36
        DEX                                             ; @ E77E: 09
        DECB                                            ; @ E77F: 5A
        BNE     loc_E77B                                ; branche vers loc_E77B si la condition NE est vraie ; @ E780: 26 F9
        LDS     #RAM_8B00                               ; @ E782: 8E 8B 00
        INS                                             ; @ E785: 31
        INS                                             ; @ E786: 31
        STS     RAM_8A00                                ; @ E787: BF 8A 00
        LDX     #RAM_851E                               ; @ E78A: CE 85 1E
        LDAA    ,X                                      ; @ E78D: A6 00
        PSHA                                            ; @ E78F: 36
        ASLA                                            ; @ E790: 48
        ASLA                                            ; @ E791: 48
        ASLA                                            ; @ E792: 48
        ASLA                                            ; @ E793: 48
        DEX                                             ; @ E794: 09
        LDAB    ,X                                      ; @ E795: E6 00
        LSRB                                            ; @ E797: 54
        LSRB                                            ; @ E798: 54
        LSRB                                            ; @ E799: 54
        LSRB                                            ; @ E79A: 54
        ABA                                             ; @ E79B: 1B
        PSHA                                            ; @ E79C: 36
        INS                                             ; @ E79D: 31
        PULB                                            ; @ E79E: 33
        INX                                             ; @ E79F: 08
        INX                                             ; @ E7A0: 08
        LDAA    ,X                                      ; @ E7A1: A6 00
        CMPA    #$10                                    ; @ E7A3: 81 10
        BCS     loc_E7FC                                ; branche vers loc_E7FC si la condition CS est vraie ; @ E7A5: 25 55
        CMPA    #$42                                    ; @ E7A7: 81 42
        BCS     loc_E7AC                                ; branche vers loc_E7AC si la condition CS est vraie ; @ E7A9: 25 01
        WAI                                             ; @ E7AB: 3E
loc_E7AC:
        CMPA    #$36                                    ; @ E7AC: 81 36
        BCS     loc_E7BE                                ; branche vers loc_E7BE si la condition CS est vraie ; @ E7AE: 25 0E
        CMPA    #$37                                    ; @ E7B0: 81 37
        BCS     loc_E7B7                                ; branche vers loc_E7B7 si la condition CS est vraie ; @ E7B2: 25 03
        JMP     loc_E871                                ; transfert sans retour vers loc_E871 ; @ E7B4: 7E E8 71
loc_E7B7:
        CMPB    #$68                                    ; @ E7B7: C1 68
        BCS     loc_E7F0                                ; branche vers loc_E7F0 si la condition CS est vraie ; @ E7B9: 25 35
        JMP     loc_E871                                ; transfert sans retour vers loc_E871 ; @ E7BB: 7E E8 71
loc_E7BE:
        CMPA    #$28                                    ; @ E7BE: 81 28
        BCS     loc_E7C5                                ; branche vers loc_E7C5 si la condition CS est vraie ; @ E7C0: 25 03
        JMP     loc_E87B                                ; transfert sans retour vers loc_E87B ; @ E7C2: 7E E8 7B
loc_E7C5:
        CMPA    #$18                                    ; @ E7C5: 81 18
        BCS     loc_E7D7                                ; branche vers loc_E7D7 si la condition CS est vraie ; @ E7C7: 25 0E
        CMPA    #$19                                    ; @ E7C9: 81 19
        BCS     loc_E7D0                                ; branche vers loc_E7D0 si la condition CS est vraie ; @ E7CB: 25 03
        JMP     loc_E892                                ; transfert sans retour vers loc_E892 ; @ E7CD: 7E E8 92
loc_E7D0:
        CMPB    #$40                                    ; @ E7D0: C1 40
        BCS     loc_E7F3                                ; branche vers loc_E7F3 si la condition CS est vraie ; @ E7D2: 25 1F
        JMP     loc_E892                                ; transfert sans retour vers loc_E892 ; @ E7D4: 7E E8 92
loc_E7D7:
        CMPA    #$14                                    ; @ E7D7: 81 14
        BCS     loc_E7DE                                ; branche vers loc_E7DE si la condition CS est vraie ; @ E7D9: 25 03
        JMP     loc_E89C                                ; transfert sans retour vers loc_E89C ; @ E7DB: 7E E8 9C
loc_E7DE:
        CMPA    #$11                                    ; @ E7DE: 81 11
        BCS     loc_E7F6                                ; branche vers loc_E7F6 si la condition CS est vraie ; @ E7E0: 25 14
        CMPA    #$12                                    ; @ E7E2: 81 12
        BCS     loc_E7E9                                ; branche vers loc_E7E9 si la condition CS est vraie ; @ E7E4: 25 03
        JMP     loc_E8B0                                ; transfert sans retour vers loc_E8B0 ; @ E7E6: 7E E8 B0
loc_E7E9:
        CMPB    #$20                                    ; @ E7E9: C1 20
        BCS     loc_E7F9                                ; branche vers loc_E7F9 si la condition CS est vraie ; @ E7EB: 25 0C
        JMP     loc_E8B0                                ; transfert sans retour vers loc_E8B0 ; @ E7ED: 7E E8 B0
loc_E7F0:
        JMP     loc_E87B                                ; transfert sans retour vers loc_E87B ; @ E7F0: 7E E8 7B
loc_E7F3:
        JMP     loc_E89C                                ; transfert sans retour vers loc_E89C ; @ E7F3: 7E E8 9C
loc_E7F6:
        JMP     loc_E8C7                                ; transfert sans retour vers loc_E8C7 ; @ E7F6: 7E E8 C7
loc_E7F9:
        JMP     loc_E8C7                                ; transfert sans retour vers loc_E8C7 ; @ E7F9: 7E E8 C7
loc_E7FC:
        CMPA    #$07                                    ; @ E7FC: 81 07
        BCS     loc_E811                                ; branche vers loc_E811 si la condition CS est vraie ; @ E7FE: 25 11
        CMPA    #$08                                    ; @ E800: 81 08
        BCS     loc_E807                                ; branche vers loc_E807 si la condition CS est vraie ; @ E802: 25 03
        JMP     loc_E8C7                                ; transfert sans retour vers loc_E8C7 ; @ E804: 7E E8 C7
loc_E807:
        CMPB    #$36                                    ; @ E807: C1 36
        BCS     loc_E80E                                ; branche vers loc_E80E si la condition CS est vraie ; @ E809: 25 03
        JMP     loc_E8C7                                ; transfert sans retour vers loc_E8C7 ; @ E80B: 7E E8 C7
loc_E80E:
        JMP     loc_E8D1                                ; transfert sans retour vers loc_E8D1 ; @ E80E: 7E E8 D1
loc_E811:
        CMPA    #$05                                    ; @ E811: 81 05
        BCS     loc_E823                                ; branche vers loc_E823 si la condition CS est vraie ; @ E813: 25 0E
        CMPA    #$06                                    ; @ E815: 81 06
        BCS     loc_E81C                                ; branche vers loc_E81C si la condition CS est vraie ; @ E817: 25 03
        JMP     loc_E8D1                                ; transfert sans retour vers loc_E8D1 ; @ E819: 7E E8 D1
loc_E81C:
        CMPB    #$60                                    ; @ E81C: C1 60
        BCS     loc_E862                                ; branche vers loc_E862 si la condition CS est vraie ; @ E81E: 25 42
        JMP     loc_E8D1                                ; transfert sans retour vers loc_E8D1 ; @ E820: 7E E8 D1
loc_E823:
        CMPA    #$03                                    ; @ E823: 81 03
        BCS     loc_E835                                ; branche vers loc_E835 si la condition CS est vraie ; @ E825: 25 0E
        CMPA    #$04                                    ; @ E827: 81 04
        BCS     loc_E82E                                ; branche vers loc_E82E si la condition CS est vraie ; @ E829: 25 03
        JMP     loc_E8E9                                ; transfert sans retour vers loc_E8E9 ; @ E82B: 7E E8 E9
loc_E82E:
        CMPB    #$68                                    ; @ E82E: C1 68
        BCS     loc_E865                                ; branche vers loc_E865 si la condition CS est vraie ; @ E830: 25 33
        JMP     loc_E8E9                                ; transfert sans retour vers loc_E8E9 ; @ E832: 7E E8 E9
loc_E835:
        CMPA    #$02                                    ; @ E835: 81 02
        BCS     loc_E840                                ; branche vers loc_E840 si la condition CS est vraie ; @ E837: 25 07
        CMPB    #$80                                    ; @ E839: C1 80
        BCS     loc_E868                                ; branche vers loc_E868 si la condition CS est vraie ; @ E83B: 25 2B
        JMP     loc_E8FD                                ; transfert sans retour vers loc_E8FD ; @ E83D: 7E E8 FD
loc_E840:
        CMPA    #$01                                    ; @ E840: 81 01
        BCS     loc_E852                                ; branche vers loc_E852 si la condition CS est vraie ; @ E842: 25 0E
        CMPB    #$84                                    ; @ E844: C1 84
        BCS     loc_E84B                                ; branche vers loc_E84B si la condition CS est vraie ; @ E846: 25 03
        JMP     loc_E911                                ; transfert sans retour vers loc_E911 ; @ E848: 7E E9 11
loc_E84B:
        CMPB    #$22                                    ; @ E84B: C1 22
        BCS     loc_E86B                                ; branche vers loc_E86B si la condition CS est vraie ; @ E84D: 25 1C
        JMP     loc_E91B                                ; transfert sans retour vers loc_E91B ; @ E84F: 7E E9 1B
loc_E852:
        DES                                             ; @ E852: 34
        PULB                                            ; @ E853: 33
        CMPB    #$02                                    ; @ E854: C1 02
        BCC     loc_E86B                                ; branche vers loc_E86B si la condition CC est vraie ; @ E856: 24 13
        DES                                             ; @ E858: 34
        DES                                             ; @ E859: 34
        PULB                                            ; @ E85A: 33
        CMPB    #$15                                    ; @ E85B: C1 15
        BCS     loc_E86E                                ; branche vers loc_E86E si la condition CS est vraie ; @ E85D: 25 0F
        JMP     loc_E930                                ; transfert sans retour vers loc_E930 ; @ E85F: 7E E9 30
loc_E862:
        JMP     loc_E8E9                                ; transfert sans retour vers loc_E8E9 ; @ E862: 7E E8 E9
loc_E865:
        JMP     loc_E8FD                                ; transfert sans retour vers loc_E8FD ; @ E865: 7E E8 FD
loc_E868:
        JMP     loc_E911                                ; transfert sans retour vers loc_E911 ; @ E868: 7E E9 11
loc_E86B:
        JMP     loc_E930                                ; transfert sans retour vers loc_E930 ; @ E86B: 7E E9 30
loc_E86E:
        JMP     loc_E93A                                ; transfert sans retour vers loc_E93A ; @ E86E: 7E E9 3A
loc_E871:
        LDS     RAM_8A00                                ; @ E871: BE 8A 00
        LDAA    #$51                                    ; @ E874: 86 51
        STAA    RAM_8505                                ; @ E876: B7 85 05
        BRA     loc_E883                                ; branche toujours vers loc_E883 ; @ E879: 20 08
loc_E87B:
        LDS     RAM_8A00                                ; @ E87B: BE 8A 00
        LDAA    #$50                                    ; @ E87E: 86 50
        STAA    RAM_8505                                ; @ E880: B7 85 05
loc_E883:
        JSR     sub_EB5C                                ; appelle sub_EB5C ; @ E883: BD EB 5C
        JSR     sub_EB38                                ; appelle sub_EB38 ; @ E886: BD EB 38
        LDAA    RAM_850C                                ; @ E889: B6 85 0C
        STAA    RAM_850C                                ; @ E88C: B7 85 0C
        JMP     loc_E958                                ; transfert sans retour vers loc_E958 ; @ E88F: 7E E9 58
loc_E892:
        LDS     RAM_8A00                                ; @ E892: BE 8A 00
        LDAA    #$41                                    ; @ E895: 86 41
        STAA    RAM_8505                                ; @ E897: B7 85 05
        BRA     loc_E8A4                                ; branche toujours vers loc_E8A4 ; @ E89A: 20 08
loc_E89C:
        LDS     RAM_8A00                                ; @ E89C: BE 8A 00
        LDAA    #$40                                    ; @ E89F: 86 40
        STAA    RAM_8505                                ; @ E8A1: B7 85 05
loc_E8A4:
        JSR     sub_EB38                                ; appelle sub_EB38 ; @ E8A4: BD EB 38
        LDAA    RAM_850C                                ; @ E8A7: B6 85 0C
        STAA    RAM_850C                                ; @ E8AA: B7 85 0C
        JMP     loc_E958                                ; transfert sans retour vers loc_E958 ; @ E8AD: 7E E9 58
loc_E8B0:
        LDS     RAM_8A00                                ; @ E8B0: BE 8A 00
        LDAA    #$45                                    ; @ E8B3: 86 45
        STAA    RAM_8505                                ; @ E8B5: B7 85 05
        JSR     sub_EBA3                                ; appelle sub_EBA3 ; @ E8B8: BD EB A3
        JSR     sub_EB38                                ; appelle sub_EB38 ; @ E8BB: BD EB 38
        LDAA    RAM_850C                                ; @ E8BE: B6 85 0C
        STAA    RAM_850C                                ; @ E8C1: B7 85 0C
        JMP     loc_E958                                ; transfert sans retour vers loc_E958 ; @ E8C4: 7E E9 58
loc_E8C7:
        LDS     RAM_8A00                                ; @ E8C7: BE 8A 00
        LDAA    #$11                                    ; @ E8CA: 86 11
        STAA    RAM_8505                                ; @ E8CC: B7 85 05
        BRA     loc_E8D9                                ; branche toujours vers loc_E8D9 ; @ E8CF: 20 08
loc_E8D1:
        LDS     RAM_8A00                                ; @ E8D1: BE 8A 00
        LDAA    #$10                                    ; @ E8D4: 86 10
        STAA    RAM_8505                                ; @ E8D6: B7 85 05
loc_E8D9:
        JSR     sub_EB5C                                ; appelle sub_EB5C ; @ E8D9: BD EB 5C
        LDAA    #$F9                                    ; @ E8DC: 86 F9
        ANDA    RAM_850C                                ; @ E8DE: B4 85 0C
        ADDA    #$02                                    ; @ E8E1: 8B 02
        STAA    RAM_850C                                ; @ E8E3: B7 85 0C
        JMP     loc_E958                                ; transfert sans retour vers loc_E958 ; @ E8E6: 7E E9 58
loc_E8E9:
        LDS     RAM_8A00                                ; @ E8E9: BE 8A 00
        LDAA    #$09                                    ; @ E8EC: 86 09
        STAA    RAM_8505                                ; @ E8EE: B7 85 05
        LDAA    #$F9                                    ; @ E8F1: 86 F9
        ANDA    RAM_850C                                ; @ E8F3: B4 85 0C
        ADDA    #$04                                    ; @ E8F6: 8B 04
        STAA    RAM_850C                                ; @ E8F8: B7 85 0C
        BRA     loc_E958                                ; branche toujours vers loc_E958 ; @ E8FB: 20 5B
loc_E8FD:
        LDS     RAM_8A00                                ; @ E8FD: BE 8A 00
        LDAA    #$08                                    ; @ E900: 86 08
        STAA    RAM_8505                                ; @ E902: B7 85 05
        LDAA    #$F9                                    ; @ E905: 86 F9
        ANDA    RAM_850C                                ; @ E907: B4 85 0C
        ADDA    #$04                                    ; @ E90A: 8B 04
        STAA    RAM_850C                                ; @ E90C: B7 85 0C
        BRA     loc_E958                                ; branche toujours vers loc_E958 ; @ E90F: 20 47
loc_E911:
        LDS     RAM_8A00                                ; @ E911: BE 8A 00
        LDAA    #$05                                    ; @ E914: 86 05
        STAA    RAM_8505                                ; @ E916: B7 85 05
        BRA     loc_E923                                ; branche toujours vers loc_E923 ; @ E919: 20 08
loc_E91B:
        LDS     RAM_8A00                                ; @ E91B: BE 8A 00
        LDAA    #$04                                    ; @ E91E: 86 04
        STAA    RAM_8505                                ; @ E920: B7 85 05
loc_E923:
        JSR     sub_EBA3                                ; appelle sub_EBA3 ; @ E923: BD EB A3
        LDAA    #$F9                                    ; @ E926: 86 F9
        ANDA    RAM_850C                                ; @ E928: B4 85 0C
        STAA    RAM_850C                                ; @ E92B: B7 85 0C
        BRA     loc_E958                                ; branche toujours vers loc_E958 ; @ E92E: 20 28
loc_E930:
        LDS     RAM_8A00                                ; @ E930: BE 8A 00
        LDAA    #$03                                    ; @ E933: 86 03
        STAA    RAM_8505                                ; @ E935: B7 85 05
        BRA     loc_E945                                ; branche toujours vers loc_E945 ; @ E938: 20 0B
loc_E93A:
        LDS     RAM_8A00                                ; @ E93A: BE 8A 00
        LDAA    #$23                                    ; @ E93D: 86 23
        STAA    RAM_8505                                ; @ E93F: B7 85 05
        CLR     RAM_8565                                ; @ E942: 7F 85 65
loc_E945:
        LDAA    RAM_851F                                ; @ E945: B6 85 1F
        LDAB    #$04                                    ; @ E948: C6 04
        ABA                                             ; @ E94A: 1B
        STAA    RAM_851F                                ; @ E94B: B7 85 1F
        LDAA    RAM_850C                                ; @ E94E: B6 85 0C
        ANDA    #$F9                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E951: 84 F9
        ADDA    #$84                                    ; @ E953: 8B 84
        STAA    RAM_850C                                ; @ E955: B7 85 0C
loc_E958:
        STAA    INST_12_RF_RANGE_MODULATION_SOURCE      ; émet l'adresse instrument 12 (rf range modulation source) ; @ E958: B7 60 0C
        LDAB    #$0F                                    ; @ E95B: C6 0F
loc_E95D:
        DECB                                            ; @ E95D: 5A
        BNE     loc_E95D                                ; branche vers loc_E95D si la condition NE est vraie ; @ E95E: 26 FD
        LDAA    RAM_850F                                ; @ E960: B6 85 0F
        ANDA    #$1F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E963: 84 1F
        LDAB    RAM_850C                                ; @ E965: F6 85 0C
        ANDB    #$0E                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E968: C4 0E
        ASLB                                            ; @ E96A: 58
        ASLB                                            ; @ E96B: 58
        ASLB                                            ; @ E96C: 58
        ASLB                                            ; @ E96D: 58
        ABA                                             ; @ E96E: 1B
        STAA    INST_15_RANGE_EXTENSION                 ; émet l'adresse instrument 15 (range extension) ; @ E96F: B7 60 0F
        STAA    RAM_850F                                ; @ E972: B7 85 0F
        LDAB    #$0F                                    ; @ E975: C6 0F
loc_E977:
        DECB                                            ; @ E977: 5A
        BNE     loc_E977                                ; branche vers loc_E977 si la condition NE est vraie ; @ E978: 26 FD
        LDAA    RAM_8505                                ; @ E97A: B6 85 05
        LDAB    RAM_MODE_FLAGS_PULSE_D1                 ; @ E97D: F6 80 26
        BITB    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E980: C5 02
        BEQ     loc_E986                                ; branche vers loc_E986 si la condition EQ est vraie ; @ E982: 27 02
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E984: 8A 20
loc_E986:
        STAA    INST_05_RF_PATH_AND_PULSE               ; émet l'adresse instrument 5 (rf path and pulse) ; @ E986: B7 60 05
        STAA    RAM_8505                                ; @ E989: B7 85 05
        STS     RAM_8A00                                ; @ E98C: BF 8A 00
        LDS     #RAM_8524                               ; @ E98F: 8E 85 24
        LDX     #RAM_851F                               ; @ E992: CE 85 1F
        LDAB    #$05                                    ; @ E995: C6 05
loc_E997:
        LDAA    ,X                                      ; @ E997: A6 00
        PSHA                                            ; @ E999: 36
        CLRA                                            ; @ E99A: 4F
        STAA    ,X                                      ; @ E99B: A7 00
        DEX                                             ; @ E99D: 09
        DECB                                            ; @ E99E: 5A
        BNE     loc_E997                                ; branche vers loc_E997 si la condition NE est vraie ; @ E99F: 26 F6
        LDS     #RAM_8B00                               ; @ E9A1: 8E 8B 00
        LDAA    RAM_8523                                ; @ E9A4: B6 85 23
        STAA    RAM_851B                                ; @ E9A7: B7 85 1B
        LDAA    RAM_8524                                ; @ E9AA: B6 85 24
        STAA    RAM_851C                                ; @ E9AD: B7 85 1C
        LDAA    RAM_851B                                ; @ E9B0: B6 85 1B
        COMA                                            ; @ E9B3: 43
        CLC                                             ; @ E9B4: 0C
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ E9B5: 19
        BCC     loc_E9BB                                ; branche vers loc_E9BB si la condition CC est vraie ; @ E9B6: 24 03
        JSR     sub_EB2F                                ; appelle sub_EB2F ; @ E9B8: BD EB 2F
loc_E9BB:
        ADDA    #$16                                    ; @ E9BB: 8B 16
        CLC                                             ; @ E9BD: 0C
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ E9BE: 19
        BCC     loc_E9C4                                ; branche vers loc_E9C4 si la condition CC est vraie ; @ E9BF: 24 03
        JSR     sub_EB2F                                ; appelle sub_EB2F ; @ E9C1: BD EB 2F
loc_E9C4:
        ADDA    #$02                                    ; @ E9C4: 8B 02
        COMA                                            ; @ E9C6: 43
        STAA    RAM_851B                                ; @ E9C7: B7 85 1B
        STAA    RAM_8526                                ; @ E9CA: B7 85 26
        JSR     sub_EB5C                                ; appelle sub_EB5C ; @ E9CD: BD EB 5C
        JSR     sub_EB5C                                ; appelle sub_EB5C ; @ E9D0: BD EB 5C
        JSR     sub_EB5C                                ; appelle sub_EB5C ; @ E9D3: BD EB 5C
        LDAA    RAM_851B                                ; @ E9D6: B6 85 1B
        STAA    RAM_850B                                ; @ E9D9: B7 85 0B
        TAB                                             ; @ E9DC: 16
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E9DD: C4 F0
        LSRB                                            ; @ E9DF: 54
        LSRB                                            ; @ E9E0: 54
        SBA                                             ; @ E9E1: 10
        LSRB                                            ; @ E9E2: 54
        SBA                                             ; @ E9E3: 10
        LDAB    #$42                                    ; @ E9E4: C6 42
        ANDB    RAM_8529                                ; @ E9E6: F4 85 29
        CMPB    #$42                                    ; @ E9E9: C1 42
        BNE     loc_E9F1                                ; branche vers loc_E9F1 si la condition NE est vraie ; @ E9EB: 26 04
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E9ED: 84 7F
        BRA     loc_E9F3                                ; branche toujours vers loc_E9F3 ; @ E9EF: 20 02
loc_E9F1:
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ E9F1: 8A 80
loc_E9F3:
        STAA    INST_11_FM_CORRECTION_N                 ; émet l'adresse instrument 11 (fm correction n) ; @ E9F3: B7 60 0B
        LDAB    #$0F                                    ; @ E9F6: C6 0F
loc_E9F8:
        DECB                                            ; @ E9F8: 5A
        BNE     loc_E9F8                                ; branche vers loc_E9F8 si la condition NE est vraie ; @ E9F9: 26 FD
        STAA    DP_0005                                 ; @ E9FB: 97 05
        LDAA    RAM_851B                                ; @ E9FD: B6 85 1B
        COMA                                            ; @ EA00: 43
        CLC                                             ; @ EA01: 0C
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EA02: 19
        ADDA    #$05                                    ; @ EA03: 8B 05
        COMA                                            ; @ EA05: 43
        CLRB                                            ; @ EA06: 5F
        ABA                                             ; @ EA07: 1B
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EA08: 19
        TAB                                             ; @ EA09: 16
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EA0A: C4 0F
        CMPB    #$05                                    ; @ EA0C: C1 05
        BMI     loc_EA12                                ; branche vers loc_EA12 si la condition MI est vraie ; @ EA0E: 2B 02
        ADDA    #$03                                    ; @ EA10: 8B 03
loc_EA12:
        EORA    #$F8                                    ; @ EA12: 88 F8
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EA14: 8A 80
        STAA    RAM_8504                                ; @ EA16: B7 85 04
        LDX     #RAM_8520                               ; @ EA19: CE 85 20
        LDAA    ,X                                      ; @ EA1C: A6 00
        STAA    RAM_8500                                ; @ EA1E: B7 85 00
        LDAA    $01,X                                   ; @ EA21: A6 01
        STAA    RAM_8501                                ; @ EA23: B7 85 01
        LDAA    $02,X                                   ; @ EA26: A6 02
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EA28: 84 0F
        STAA    RAM_8502                                ; @ EA2A: B7 85 02
        LDAA    $02,X                                   ; @ EA2D: A6 02
        EORA    #$E0                                    ; @ EA2F: 88 E0
        LSRA                                            ; @ EA31: 44
        LSRA                                            ; @ EA32: 44
        LSRA                                            ; @ EA33: 44
        LSRA                                            ; @ EA34: 44
        STAA    RAM_8503                                ; @ EA35: B7 85 03
        LDAA    RAM_851B                                ; @ EA38: B6 85 1B
        STAA    DP_0074                                 ; @ EA3B: 97 74
        LDAA    RAM_8505                                ; @ EA3D: B6 85 05
        ASLA                                            ; @ EA40: 48
        ASLA                                            ; @ EA41: 48
        ASLA                                            ; @ EA42: 48
        ASLA                                            ; @ EA43: 48
        BCC     loc_EAA7                                ; branche vers loc_EAA7 si la condition CC est vraie ; @ EA44: 24 61
        LDAA    RAM_8504                                ; @ EA46: B6 85 04
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EA49: 84 7F
        STAA    RAM_8504                                ; @ EA4B: B7 85 04
        LDAA    DP_0027                                 ; @ EA4E: 96 27
        LDAB    DP_0026                                 ; @ EA50: D6 26
        CMPA    #$10                                    ; @ EA52: 81 10
        BMI     loc_EA58                                ; branche vers loc_EA58 si la condition MI est vraie ; @ EA54: 2B 02
        SUBA    #$0A                                    ; @ EA56: 80 0A
loc_EA58:
        CMPA    #$05                                    ; @ EA58: 81 05
        BNE     loc_EA67                                ; branche vers loc_EA67 si la condition NE est vraie ; @ EA5A: 26 0B
loc_EA5C:
        LDAB    RAM_8504                                ; @ EA5C: F6 85 04
        ADDB    #$80                                    ; @ EA5F: CB 80
        STAB    RAM_8504                                ; @ EA61: F7 85 04
        JMP     loc_EAA7                                ; transfert sans retour vers loc_EAA7 ; @ EA64: 7E EA A7
loc_EA67:
        CMPA    #$09                                    ; @ EA67: 81 09
        BMI     loc_EA76                                ; branche vers loc_EA76 si la condition MI est vraie ; @ EA69: 2B 0B
        CMPB    #$64                                    ; @ EA6B: C1 64
        BCC     loc_EA5C                                ; branche vers loc_EA5C si la condition CC est vraie ; @ EA6D: 24 ED
        CMPB    #$24                                    ; @ EA6F: C1 24
        BCC     loc_EAA7                                ; branche vers loc_EAA7 si la condition CC est vraie ; @ EA71: 24 34
        JMP     loc_EA5C                                ; transfert sans retour vers loc_EA5C ; @ EA73: 7E EA 5C
loc_EA76:
        CMPA    #$08                                    ; @ EA76: 81 08
        BMI     loc_EA89                                ; branche vers loc_EA89 si la condition MI est vraie ; @ EA78: 2B 0F
        CMPB    #$84                                    ; @ EA7A: C1 84
        BCC     loc_EA5C                                ; branche vers loc_EA5C si la condition CC est vraie ; @ EA7C: 24 DE
        CMPB    #$44                                    ; @ EA7E: C1 44
        BCC     loc_EAA7                                ; branche vers loc_EAA7 si la condition CC est vraie ; @ EA80: 24 25
        CMPB    #$04                                    ; @ EA82: C1 04
        BCC     loc_EA5C                                ; branche vers loc_EA5C si la condition CC est vraie ; @ EA84: 24 D6
        JMP     loc_EAA7                                ; transfert sans retour vers loc_EAA7 ; @ EA86: 7E EA A7
loc_EA89:
        CMPA    #$07                                    ; @ EA89: 81 07
        BMI     loc_EA98                                ; branche vers loc_EA98 si la condition MI est vraie ; @ EA8B: 2B 0B
        CMPB    #$64                                    ; @ EA8D: C1 64
        BCC     loc_EAA7                                ; branche vers loc_EAA7 si la condition CC est vraie ; @ EA8F: 24 16
        CMPB    #$24                                    ; @ EA91: C1 24
        BCC     loc_EA5C                                ; branche vers loc_EA5C si la condition CC est vraie ; @ EA93: 24 C7
        JMP     loc_EAA7                                ; transfert sans retour vers loc_EAA7 ; @ EA95: 7E EA A7
loc_EA98:
        CMPB    #$84                                    ; @ EA98: C1 84
        BCC     loc_EAA7                                ; branche vers loc_EAA7 si la condition CC est vraie ; @ EA9A: 24 0B
        CMPB    #$44                                    ; @ EA9C: C1 44
        BCC     loc_EA5C                                ; branche vers loc_EA5C si la condition CC est vraie ; @ EA9E: 24 BC
        CMPB    #$04                                    ; @ EAA0: C1 04
        BCC     loc_EAA7                                ; branche vers loc_EAA7 si la condition CC est vraie ; @ EAA2: 24 03
        JMP     loc_EA5C                                ; transfert sans retour vers loc_EA5C ; @ EAA4: 7E EA 5C
loc_EAA7:
        LDAB    RAM_8504                                ; @ EAA7: F6 85 04
        STAB    INST_04_APPROACH_DIVIDER_N              ; émet l'adresse instrument 4 (approach divider n) ; @ EAAA: F7 60 04
        LDAA    #$0F                                    ; @ EAAD: 86 0F
loc_EAAF:
        DECA                                            ; @ EAAF: 4A
        BNE     loc_EAAF                                ; branche vers loc_EAAF si la condition NE est vraie ; @ EAB0: 26 FD
        STAB    DP_0005                                 ; @ EAB2: D7 05
        LDAA    RAM_850C                                ; @ EAB4: B6 85 0C
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EAB7: C4 7F
        ANDA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EAB9: 84 01
        BNE     loc_EABF                                ; branche vers loc_EABF si la condition NE est vraie ; @ EABB: 26 02
        ADDB    #$80                                    ; @ EABD: CB 80
loc_EABF:
        STAB    RAM_850D                                ; @ EABF: F7 85 0D
        STAB    INST_13_INCREMENT_DIVIDER               ; émet l'adresse instrument 13 (increment divider) ; @ EAC2: F7 60 0D
        LDAA    #$0F                                    ; @ EAC5: 86 0F
loc_EAC7:
        DECA                                            ; @ EAC7: 4A
        BNE     loc_EAC7                                ; branche vers loc_EAC7 si la condition NE est vraie ; @ EAC8: 26 FD
        STAB    DP_0005                                 ; @ EACA: D7 05
        LDAB    RAM_8500                                ; @ EACC: F6 85 00
        TBA                                             ; @ EACF: 17
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EAD0: 84 0F
        BEQ     loc_EAD6                                ; branche vers loc_EAD6 si la condition EQ est vraie ; @ EAD2: 27 02
        ADDB    #$03                                    ; @ EAD4: CB 03
loc_EAD6:
        STAB    INST_00_SYNTH_20000_UNITS               ; émet l'adresse instrument 0 (synth 20000 units) ; @ EAD6: F7 60 00
        STAB    DP_0005                                 ; @ EAD9: D7 05
        LDAB    RAM_8500                                ; @ EADB: F6 85 00
        LDAA    DP_0074                                 ; @ EADE: 96 74
        STAA    RAM_851B                                ; @ EAE0: B7 85 1B
        CLR     RAM_851C                                ; @ EAE3: 7F 85 1C
        JSR     sub_EBA3                                ; appelle sub_EBA3 ; @ EAE6: BD EB A3
        LDAB    RAM_8501                                ; @ EAE9: F6 85 01
        STAB    INST_01_SYNTH_20000_HUNDREDS_TENS       ; émet l'adresse instrument 1 (synth 20000 hundreds tens) ; @ EAEC: F7 60 01
        STAB    DP_0005                                 ; @ EAEF: D7 05
        JSR     sub_EBA3                                ; appelle sub_EBA3 ; @ EAF1: BD EB A3
        LDAB    RAM_8502                                ; @ EAF4: F6 85 02
        STAB    INST_02_SYNTH_20000_THOUSANDS           ; émet l'adresse instrument 2 (synth 20000 thousands) ; @ EAF7: F7 60 02
        STAB    DP_0005                                 ; @ EAFA: D7 05
        JSR     sub_EBA3                                ; appelle sub_EBA3 ; @ EAFC: BD EB A3
loc_EAFF:
        LDAA    RAM_8526                                ; @ EAFF: B6 85 26
        COMA                                            ; @ EB02: 43
        CLC                                             ; @ EB03: 0C
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EB04: 19
        LDAB    RAM_851B                                ; @ EB05: F6 85 1B
        ABA                                             ; @ EB08: 1B
        COMA                                            ; @ EB09: 43
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EB0A: 19
        COMA                                            ; @ EB0B: 43
        ASLA                                            ; @ EB0C: 48
        ASLA                                            ; @ EB0D: 48
        ASLA                                            ; @ EB0E: 48
        ASLA                                            ; @ EB0F: 48
        LDAB    RAM_8503                                ; @ EB10: F6 85 03
        ABA                                             ; @ EB13: 1B
        STAA    RAM_8503                                ; @ EB14: B7 85 03
        LDS     RAM_8000                                ; @ EB17: BE 80 00
        LDAB    #$0F                                    ; @ EB1A: C6 0F
loc_EB1C:
        DECB                                            ; @ EB1C: 5A
        BNE     loc_EB1C                                ; branche vers loc_EB1C si la condition NE est vraie ; @ EB1D: 26 FD
        STAA    INST_03_SYNTH_80_DIVIDER                ; émet l'adresse instrument 3 (synth 80 divider) ; @ EB1F: B7 60 03
        STAA    DP_0005                                 ; @ EB22: 97 05
        LDAB    #$0F                                    ; @ EB24: C6 0F
loc_EB26:
        DECB                                            ; @ EB26: 5A
        BNE     loc_EB26                                ; branche vers loc_EB26 si la condition NE est vraie ; @ EB27: 26 FD
        JSR     update_instrument_address_6_control_bits ; appelle update_instrument_address_6_control_bits ; @ EB29: BD CC 7E
        JMP     loc_EE8D                                ; transfert sans retour vers loc_EE8D ; @ EB2C: 7E EE 8D

; ---------------------------------------------------------------------------
; ROUTINE $EB2F — sub_EB2F
; INCONNU — sous-routine interne à $EB2F; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $E9B8, $E9C1. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EB2F:
        LDAB    RAM_851C                                ; @ EB2F: F6 85 1C
        SBCB    #$00                                    ; @ EB32: C2 00
        STAB    RAM_851C                                ; @ EB34: F7 85 1C
        RTS                                             ; @ EB37: 39

; ---------------------------------------------------------------------------
; ROUTINE $EB38 — sub_EB38
; INCONNU — sous-routine interne à $EB38; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $E886, $E8A4, $E8BB. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EB38:
        JSR     sub_EBCD                                ; appelle sub_EBCD ; @ EB38: BD EB CD
        STS     RAM_8A00                                ; @ EB3B: BF 8A 00
        LDAB    #$05                                    ; @ EB3E: C6 05
        LDX     #RAM_851B                               ; @ EB40: CE 85 1B
loc_EB43:
        PSHB                                            ; @ EB43: 37
        LDAA    ,X                                      ; @ EB44: A6 00
        LSRA                                            ; @ EB46: 44
        LSRA                                            ; @ EB47: 44
        LSRA                                            ; @ EB48: 44
        LDAB    $01,X                                   ; @ EB49: E6 01
        ASLB                                            ; @ EB4B: 58
        ASLB                                            ; @ EB4C: 58
        ASLB                                            ; @ EB4D: 58
        ASLB                                            ; @ EB4E: 58
        ASLB                                            ; @ EB4F: 58
        ABA                                             ; @ EB50: 1B
        STAA    ,X                                      ; @ EB51: A7 00
        INX                                             ; @ EB53: 08
        PULB                                            ; @ EB54: 33
        DECB                                            ; @ EB55: 5A
        BNE     loc_EB43                                ; branche vers loc_EB43 si la condition NE est vraie ; @ EB56: 26 EB
        LDS     RAM_8A00                                ; @ EB58: BE 8A 00
        RTS                                             ; @ EB5B: 39

; ---------------------------------------------------------------------------
; ROUTINE $EB5C — sub_EB5C
; INCONNU — sous-routine interne à $EB5C; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $E883, $E8D9, $E9CD, $E9D0, $E9D3. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EB5C:
        CLC                                             ; @ EB5C: 0C
        STS     RAM_8A00                                ; @ EB5D: BF 8A 00
        CLRB                                            ; @ EB60: 5F
        PSHB                                            ; @ EB61: 37
        LDX     #RAM_851F                               ; @ EB62: CE 85 1F
        LDAB    #$05                                    ; @ EB65: C6 05
        PSHB                                            ; @ EB67: 37
loc_EB68:
        INS                                             ; @ EB68: 31
        PULB                                            ; @ EB69: 33
        TPA                                             ; @ EB6A: 07
        ANDA    #$FE                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EB6B: 84 FE
        ABA                                             ; @ EB6D: 1B
        TAP                                             ; @ EB6E: 06
        LDAA    ,X                                      ; @ EB6F: A6 00
        RORA                                            ; @ EB71: 46
        STAA    ,X                                      ; @ EB72: A7 00
        TPA                                             ; @ EB74: 07
        ANDA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EB75: 84 01
        PSHA                                            ; @ EB77: 36
        LDAA    ,X                                      ; @ EB78: A6 00
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EB7A: 84 0F
        CMPA    #$07                                    ; @ EB7C: 81 07
        BHI     loc_EB93                                ; branche vers loc_EB93 si la condition HI est vraie ; @ EB7E: 22 13
loc_EB80:
        LDAA    ,X                                      ; @ EB80: A6 00
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EB82: 84 F0
        CMPA    #$70                                    ; @ EB84: 81 70
        BHI     loc_EB9B                                ; branche vers loc_EB9B si la condition HI est vraie ; @ EB86: 22 13
loc_EB88:
        DEX                                             ; @ EB88: 09
        DES                                             ; @ EB89: 34
        PULB                                            ; @ EB8A: 33
        DECB                                            ; @ EB8B: 5A
        PSHB                                            ; @ EB8C: 37
        BNE     loc_EB68                                ; branche vers loc_EB68 si la condition NE est vraie ; @ EB8D: 26 D9
        LDS     RAM_8A00                                ; @ EB8F: BE 8A 00
        RTS                                             ; @ EB92: 39
loc_EB93:
        LDAA    ,X                                      ; @ EB93: A6 00
        SUBA    #$03                                    ; @ EB95: 80 03
        STAA    ,X                                      ; @ EB97: A7 00
        BRA     loc_EB80                                ; branche toujours vers loc_EB80 ; @ EB99: 20 E5
loc_EB9B:
        LDAA    ,X                                      ; @ EB9B: A6 00
        SUBA    #$30                                    ; @ EB9D: 80 30
        STAA    ,X                                      ; @ EB9F: A7 00
        BRA     loc_EB88                                ; branche toujours vers loc_EB88 ; @ EBA1: 20 E5

; ---------------------------------------------------------------------------
; ROUTINE $EBA3 — sub_EBA3
; INCONNU — sous-routine interne à $EBA3; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $E8B8, $E923, $EAE6, $EAF1, $EAFC. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EBA3:
        JSR     sub_EBCD                                ; appelle sub_EBCD ; @ EBA3: BD EB CD
        CLC                                             ; @ EBA6: 0C
        STS     RAM_8A00                                ; @ EBA7: BF 8A 00
        CLRB                                            ; @ EBAA: 5F
        PSHB                                            ; @ EBAB: 37
        LDX     #RAM_851B                               ; @ EBAC: CE 85 1B
        LDAB    #$05                                    ; @ EBAF: C6 05
        PSHB                                            ; @ EBB1: 37
loc_EBB2:
        INS                                             ; @ EBB2: 31
        PULB                                            ; @ EBB3: 33
        TPA                                             ; @ EBB4: 07
        ANDA    #$FE                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EBB5: 84 FE
        ABA                                             ; @ EBB7: 1B
        TAP                                             ; @ EBB8: 06
        LDAA    ,X                                      ; @ EBB9: A6 00
        ROLA                                            ; @ EBBB: 49
        STAA    ,X                                      ; @ EBBC: A7 00
        TPA                                             ; @ EBBE: 07
        ANDA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EBBF: 84 01
        PSHA                                            ; @ EBC1: 36
        INX                                             ; @ EBC2: 08
        DES                                             ; @ EBC3: 34
        PULB                                            ; @ EBC4: 33
        DECB                                            ; @ EBC5: 5A
        PSHB                                            ; @ EBC6: 37
        BNE     loc_EBB2                                ; branche vers loc_EBB2 si la condition NE est vraie ; @ EBC7: 26 E9
        LDS     RAM_8A00                                ; @ EBC9: BE 8A 00
        RTS                                             ; @ EBCC: 39

; ---------------------------------------------------------------------------
; ROUTINE $EBCD — sub_EBCD
; INCONNU — sous-routine interne à $EBCD; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $EB38, $EBA3. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EBCD:
        LDAB    #$05                                    ; @ EBCD: C6 05
        LDX     #RAM_851B                               ; @ EBCF: CE 85 1B
loc_EBD2:
        LDAA    ,X                                      ; @ EBD2: A6 00
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EBD4: 84 0F
        CMPA    #$04                                    ; @ EBD6: 81 04
        BHI     loc_EBE7                                ; branche vers loc_EBE7 si la condition HI est vraie ; @ EBD8: 22 0D
        LDAA    ,X                                      ; @ EBDA: A6 00
loc_EBDC:
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EBDC: 84 F0
        CMPA    #$40                                    ; @ EBDE: 81 40
        BHI     loc_EBEF                                ; branche vers loc_EBEF si la condition HI est vraie ; @ EBE0: 22 0D
loc_EBE2:
        INX                                             ; @ EBE2: 08
        DECB                                            ; @ EBE3: 5A
        BNE     loc_EBD2                                ; branche vers loc_EBD2 si la condition NE est vraie ; @ EBE4: 26 EC
        RTS                                             ; @ EBE6: 39
loc_EBE7:
        LDAA    ,X                                      ; @ EBE7: A6 00
        ADDA    #$03                                    ; @ EBE9: 8B 03
        STAA    ,X                                      ; @ EBEB: A7 00
        BRA     loc_EBDC                                ; branche toujours vers loc_EBDC ; @ EBED: 20 ED
loc_EBEF:
        LDAA    ,X                                      ; @ EBEF: A6 00
        ADDA    #$30                                    ; @ EBF1: 8B 30
        STAA    ,X                                      ; @ EBF3: A7 00
        BRA     loc_EBE2                                ; branche toujours vers loc_EBE2 ; @ EBF5: 20 EB
        FCB     $01                                     ; données '.' ; @ EBF7: 01

; ---------------------------------------------------------------------------
; ROUTINE $EBF8 — program_modulation
; CONFIRMÉ — composition et programmation AM/FM/PM.
; Entrées : valeur BCD, mode et source dans $005E..$0060 et images $8013/$8014/$8026.
; Sorties : écrit les adresses 9, 10, 12, 13, 11 et 6; l'AM peut écrire 6 une première fois.
; Registres/flags : A, B et X modifiés; interruptions masquées pendant la transaction.
; RAM/E/S : images $8500..$8542/$8529 et bus instruments $6006/$6009..$600D.
; Algorithme : code quatre chiffres BCD, fusionne gamme/source avec la gamme RF et applique l'interaction AM/+5 dB/Pulse.
; ---------------------------------------------------------------------------
program_modulation:
        SEI                                             ; masque les IRQ pendant la section critique ; @ EBF8: 0F
        LDAA    DP_005E                                 ; @ EBF9: 96 5E
        STAA    RAM_8540                                ; @ EBFB: B7 85 40
        LDAA    DP_005F                                 ; @ EBFE: 96 5F
        STAA    RAM_8541                                ; @ EC00: B7 85 41
        LDAA    DP_0060                                 ; @ EC03: 96 60
        STAA    RAM_8542                                ; @ EC05: B7 85 42

; ---------------------------------------------------------------------------
; ROUTINE $EC08 — sub_EC08
; INCONNU — sous-routine interne à $EC08; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $DF5D. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EC08:
        LDX     #RAM_8013                               ; @ EC08: CE 80 13
        LDAA    ,X                                      ; @ EC0B: A6 00
        COMA                                            ; @ EC0D: 43
        ANDA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC0E: 84 80
        TAB                                             ; @ EC10: 16
        LDX     #RAM_8014                               ; @ EC11: CE 80 14
        LDAA    ,X                                      ; @ EC14: A6 00
        ANDA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC16: 84 10
        BEQ     loc_EC30                                ; branche vers loc_EC30 si la condition EQ est vraie ; @ EC18: 27 16
        LDAA    ,X                                      ; @ EC1A: A6 00
        ANDA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC1C: 84 20
        BNE     loc_EC24                                ; branche vers loc_EC24 si la condition NE est vraie ; @ EC1E: 26 04
        ADDB    #$10                                    ; @ EC20: CB 10
        BRA     loc_EC30                                ; branche toujours vers loc_EC30 ; @ EC22: 20 0C
loc_EC24:
        LDAA    ,X                                      ; @ EC24: A6 00
        ANDA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC26: 84 40
        BEQ     loc_EC2E                                ; branche vers loc_EC2E si la condition EQ est vraie ; @ EC28: 27 04
        ADDB    #$30                                    ; @ EC2A: CB 30
        BRA     loc_EC30                                ; branche toujours vers loc_EC30 ; @ EC2C: 20 02
loc_EC2E:
        ADDB    #$20                                    ; @ EC2E: CB 20
loc_EC30:
        LDAA    RAM_8529                                ; @ EC30: B6 85 29
        ANDA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC33: 84 07
        ABA                                             ; @ EC35: 1B
        TAB                                             ; @ EC36: 16
        LDX     #RAM_MODE_FLAGS_PULSE_D1                ; @ EC37: CE 80 26
        LDAA    ,X                                      ; @ EC3A: A6 00
        ANDA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC3C: 84 02
        BEQ     loc_EC42                                ; branche vers loc_EC42 si la condition EQ est vraie ; @ EC3E: 27 02
        ADDB    #$08                                    ; @ EC40: CB 08
loc_EC42:
        STAB    RAM_8529                                ; @ EC42: F7 85 29
        CLC                                             ; @ EC45: 0C
        LDX     #RAM_8500                               ; @ EC46: CE 85 00
        BSR     sub_ECA5                                ; appelle sub_ECA5 ; @ EC49: 8D 5A
        LDAA    RAM_8529                                ; @ EC4B: B6 85 29
        LSRA                                            ; @ EC4E: 44
        BCS     loc_ECB4                                ; branche vers loc_ECB4 si la condition CS est vraie ; @ EC4F: 25 63
        LSRA                                            ; @ EC51: 44
        BCS     loc_ECD0                                ; branche vers loc_ECD0 si la condition CS est vraie ; @ EC52: 25 7C
        LSRA                                            ; @ EC54: 44
        BCS     loc_ECA1                                ; branche vers loc_ECA1 si la condition CS est vraie ; @ EC55: 25 4A
        LSRA                                            ; @ EC57: 44
        BCS     loc_ECA3                                ; branche vers loc_ECA3 si la condition CS est vraie ; @ EC58: 25 49
loc_EC5A:
        LDAA    RAM_850C                                ; @ EC5A: B6 85 0C
        TAB                                             ; @ EC5D: 16
        ANDA    #$FE                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC5E: 84 FE
        ANDB    #$18                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC60: C4 18
        BNE     loc_EC66                                ; branche vers loc_EC66 si la condition NE est vraie ; @ EC62: 26 02
        ADDA    #$01                                    ; @ EC64: 8B 01
loc_EC66:
        STAA    RAM_850C                                ; @ EC66: B7 85 0C
        STAA    INST_12_RF_RANGE_MODULATION_SOURCE      ; émet l'adresse instrument 12 (rf range modulation source) ; @ EC69: B7 60 0C
        LDAB    #$2F                                    ; @ EC6C: C6 2F
loc_EC6E:
        DECB                                            ; @ EC6E: 5A
        BNE     loc_EC6E                                ; branche vers loc_EC6E si la condition NE est vraie ; @ EC6F: 26 FD
        LDAB    RAM_850D                                ; @ EC71: F6 85 0D
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC74: C4 7F
        ANDA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC76: 84 01
        BNE     loc_EC7C                                ; branche vers loc_EC7C si la condition NE est vraie ; @ EC78: 26 02
        ADDB    #$80                                    ; @ EC7A: CB 80
loc_EC7C:
        STAB    RAM_850D                                ; @ EC7C: F7 85 0D
        STAB    INST_13_INCREMENT_DIVIDER               ; émet l'adresse instrument 13 (increment divider) ; @ EC7F: F7 60 0D
        LDAA    #$0F                                    ; @ EC82: 86 0F
loc_EC84:
        DECA                                            ; @ EC84: 4A
        BNE     loc_EC84                                ; branche vers loc_EC84 si la condition NE est vraie ; @ EC85: 26 FD
        STAB    DP_0005                                 ; @ EC87: D7 05
        LDAA    RAM_850B                                ; @ EC89: B6 85 0B
        TAB                                             ; @ EC8C: 16
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EC8D: C4 F0
        LSRB                                            ; @ EC8F: 54
        LSRB                                            ; @ EC90: 54
        SBA                                             ; @ EC91: 10
        LSRB                                            ; @ EC92: 54
        SBA                                             ; @ EC93: 10
        STAA    INST_11_FM_CORRECTION_N                 ; émet l'adresse instrument 11 (fm correction n) ; @ EC94: B7 60 0B
        LDAB    #$1F                                    ; @ EC97: C6 1F
loc_EC99:
        DECB                                            ; @ EC99: 5A
        BNE     loc_EC99                                ; branche vers loc_EC99 si la condition NE est vraie ; @ EC9A: 26 FD
        JSR     update_instrument_address_6_control_bits ; appelle update_instrument_address_6_control_bits ; @ EC9C: BD CC 7E
        CLI                                             ; autorise à nouveau les IRQ ; @ EC9F: 0E
        RTS                                             ; @ ECA0: 39
loc_ECA1:
        BRA     loc_ECE1                                ; branche toujours vers loc_ECE1 ; @ ECA1: 20 3E
loc_ECA3:
        BRA     loc_ECE9                                ; branche toujours vers loc_ECE9 ; @ ECA3: 20 44

; ---------------------------------------------------------------------------
; ROUTINE $ECA5 — sub_ECA5
; INCONNU — sous-routine interne à $ECA5; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $EC49. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_ECA5:
        LDAA    #$BF                                    ; @ ECA5: 86 BF
        ANDA    $06,X                                   ; @ ECA7: A4 06
        STAA    $06,X                                   ; @ ECA9: A7 06
        CLR     $0A,X                                   ; @ ECAB: 6F 0A
        LDAB    $0C,X                                   ; @ ECAD: E6 0C
        ANDB    #$86                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ ECAF: C4 86
        STAB    $0C,X                                   ; @ ECB1: E7 0C
        RTS                                             ; @ ECB3: 39
loc_ECB4:
        LDAA    $0A,X                                   ; @ ECB4: A6 0A
        ADDA    #$40                                    ; @ ECB6: 8B 40
        STAA    $0A,X                                   ; @ ECB8: A7 0A
        LDAA    #$08                                    ; @ ECBA: 86 08
        ANDA    RAM_8529                                ; @ ECBC: B4 85 29
        CMPA    #$08                                    ; @ ECBF: 81 08
        BEQ     loc_ECA3                                ; branche vers loc_ECA3 si la condition EQ est vraie ; @ ECC1: 27 E0
        LDAA    RAM_8506                                ; @ ECC3: B6 85 06
        STAA    INST_06_ATTENUATOR_AND_PULSE            ; émet l'adresse instrument 6 (attenuator and pulse) ; @ ECC6: B7 60 06
        LDAB    #$0F                                    ; @ ECC9: C6 0F
loc_ECCB:
        DECB                                            ; @ ECCB: 5A
        BNE     loc_ECCB                                ; branche vers loc_ECCB si la condition NE est vraie ; @ ECCC: 26 FD
        BRA     loc_ECF2                                ; branche toujours vers loc_ECF2 ; @ ECCE: 20 22
loc_ECD0:
        LDAB    $0C,X                                   ; @ ECD0: E6 0C
        LDAA    RAM_8542                                ; @ ECD2: B6 85 42
        BEQ     loc_ECDB                                ; branche vers loc_ECDB si la condition EQ est vraie ; @ ECD5: 27 04
        ADDB    #$08                                    ; @ ECD7: CB 08
        BRA     loc_ECDD                                ; branche toujours vers loc_ECDD ; @ ECD9: 20 02
loc_ECDB:
        ADDB    #$10                                    ; @ ECDB: CB 10
loc_ECDD:
        STAB    $0C,X                                   ; @ ECDD: E7 0C
        BRA     loc_ECF2                                ; branche toujours vers loc_ECF2 ; @ ECDF: 20 11
loc_ECE1:
        LDAA    $0C,X                                   ; @ ECE1: A6 0C
        ADDA    #$18                                    ; @ ECE3: 8B 18
        STAA    $0C,X                                   ; @ ECE5: A7 0C
        BRA     loc_ECF2                                ; branche toujours vers loc_ECF2 ; @ ECE7: 20 09
loc_ECE9:
        LDAA    $06,X                                   ; @ ECE9: A6 06
        ADDA    #$40                                    ; @ ECEB: 8B 40
        STAA    $06,X                                   ; @ ECED: A7 06
        STAA    INST_06_ATTENUATOR_AND_PULSE            ; émet l'adresse instrument 6 (attenuator and pulse) ; @ ECEF: B7 60 06
loc_ECF2:
        LDAA    #$30                                    ; @ ECF2: 86 30
        ANDA    RAM_8529                                ; @ ECF4: B4 85 29
        BEQ     loc_ED32                                ; branche vers loc_ED32 si la condition EQ est vraie ; @ ECF7: 27 39
        CMPA    #$10                                    ; @ ECF9: 81 10
        BEQ     loc_ED26                                ; branche vers loc_ED26 si la condition EQ est vraie ; @ ECFB: 27 29
        LDAA    $0A,X                                   ; @ ECFD: A6 0A
        ADDA    #$20                                    ; @ ECFF: 8B 20
        STAA    $0A,X                                   ; @ ED01: A7 0A
        LDAA    $0C,X                                   ; @ ED03: A6 0C
        ADDA    #$40                                    ; @ ED05: 8B 40
        STAA    $0C,X                                   ; @ ED07: A7 0C
        LDAA    #$30                                    ; @ ED09: 86 30
        ANDA    RAM_8529                                ; @ ED0B: B4 85 29
        CMPA    #$20                                    ; @ ED0E: 81 20
        BEQ     loc_ED14                                ; branche vers loc_ED14 si la condition EQ est vraie ; @ ED10: 27 02
        BRA     loc_ED1A                                ; branche toujours vers loc_ED1A ; @ ED12: 20 06
loc_ED14:
        LDAA    $0C,X                                   ; @ ED14: A6 0C
        ADDA    #$20                                    ; @ ED16: 8B 20
        STAA    $0C,X                                   ; @ ED18: A7 0C
loc_ED1A:
        LDAA    RAM_850A                                ; @ ED1A: B6 85 0A
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ ED1D: 84 7F
        ADDA    #$80                                    ; @ ED1F: 8B 80
        STAA    RAM_850A                                ; @ ED21: B7 85 0A
        BRA     loc_ED44                                ; branche toujours vers loc_ED44 ; @ ED24: 20 1E
loc_ED26:
        LDAA    RAM_850A                                ; @ ED26: B6 85 0A
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ ED29: 84 7F
        ADDA    #$80                                    ; @ ED2B: 8B 80
        STAA    RAM_850A                                ; @ ED2D: B7 85 0A
        BRA     loc_ED44                                ; branche toujours vers loc_ED44 ; @ ED30: 20 12
loc_ED32:
        LDAA    RAM_850A                                ; @ ED32: B6 85 0A
        ANDA    #$3F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ ED35: 84 3F
        STAA    RAM_850A                                ; @ ED37: B7 85 0A
        LDAA    RAM_850C                                ; @ ED3A: B6 85 0C
        ANDA    #$E6                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ ED3D: 84 E6
        STAA    RAM_850C                                ; @ ED3F: B7 85 0C
        INC     $0C,X                                   ; @ ED42: 6C 0C
loc_ED44:
        LDAA    RAM_8540                                ; @ ED44: B6 85 40
        STAA    $09,X                                   ; @ ED47: A7 09
        STAA    INST_09_MODULATION_BCD_LOW              ; émet l'adresse instrument 9 (modulation bcd low) ; @ ED49: B7 60 09
        LDAB    #$1F                                    ; @ ED4C: C6 1F
loc_ED4E:
        DECB                                            ; @ ED4E: 5A
        BNE     loc_ED4E                                ; branche vers loc_ED4E si la condition NE est vraie ; @ ED4F: 26 FD
        LDAA    RAM_8541                                ; @ ED51: B6 85 41
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ ED54: 84 0F
        LDAB    #$F0                                    ; @ ED56: C6 F0
        ANDB    $0A,X                                   ; @ ED58: E4 0A
        ABA                                             ; @ ED5A: 1B
        LDAB    #$10                                    ; @ ED5B: C6 10
        ANDB    RAM_8541                                ; @ ED5D: F4 85 41
        CMPB    #$10                                    ; @ ED60: C1 10
        BEQ     loc_ED66                                ; branche vers loc_ED66 si la condition EQ est vraie ; @ ED62: 27 02
        ADDA    #$10                                    ; @ ED64: 8B 10
loc_ED66:
        STAA    $0A,X                                   ; @ ED66: A7 0A
        STAA    INST_10_MODULATION_BCD_HIGH_MODE        ; émet l'adresse instrument 10 (modulation bcd high mode) ; @ ED68: B7 60 0A
        LDAB    #$1F                                    ; @ ED6B: C6 1F
loc_ED6D:
        DECB                                            ; @ ED6D: 5A
        BNE     loc_ED6D                                ; branche vers loc_ED6D si la condition NE est vraie ; @ ED6E: 26 FD
        JMP     loc_EC5A                                ; transfert sans retour vers loc_EC5A ; @ ED70: 7E EC 5A

; ---------------------------------------------------------------------------
; ROUTINE $ED73 — sub_ED73
; INCONNU — sous-routine interne à $ED73; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $DF0F. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_ED73:
        SEI                                             ; masque les IRQ pendant la section critique ; @ ED73: 0F

; ---------------------------------------------------------------------------
; ROUTINE $ED74 — program_rf_level
; CONFIRMÉ — calcul et programmation du niveau RF.
; Entrées : niveau demandé en BCD dans $005E..$0060; $FF est la sentinelle RF OFF.
; Sorties : séquence adresse 6, adresse 8, adresse 6 et images de niveau actualisées.
; Registres/flags : A, B et X modifiés; calculs décimaux via DAA.
; RAM/E/S : table BCD $C1F6, travail $8543..$8561, registres instruments $6006/$6008.
; Algorithme : décompose le niveau en pas mécaniques de 5 dB et atténuation fine, applique la table de relais puis recalcule D7.
; ---------------------------------------------------------------------------
program_rf_level:
        CLR     RAM_854A                                ; @ ED74: 7F 85 4A
        CLR     RAM_8548                                ; @ ED77: 7F 85 48
        LDX     #RAM_8560                               ; @ ED7A: CE 85 60
        LDAA    DP_005E                                 ; @ ED7D: 96 5E
        CMPA    #$FF                                    ; @ ED7F: 81 FF
        BNE     loc_ED91                                ; branche vers loc_ED91 si la condition NE est vraie ; @ ED81: 26 0E
        LDAB    RAM_8506                                ; @ ED83: F6 85 06
        ANDB    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ ED86: C4 C0
        STAB    RAM_8506                                ; @ ED88: F7 85 06
        STAB    INST_06_ATTENUATOR_AND_PULSE            ; émet l'adresse instrument 6 (attenuator and pulse) ; @ ED8B: F7 60 06
        JMP     loc_EF70                                ; transfert sans retour vers loc_EF70 ; @ ED8E: 7E EF 70
loc_ED91:
        STAA    ,X                                      ; @ ED91: A7 00
        LDAA    DP_005F                                 ; @ ED93: 96 5F
        STAA    $01,X                                   ; @ ED95: A7 01
        LDAA    DP_0060                                 ; @ ED97: 96 60
        STAA    $02,X                                   ; @ ED99: A7 02
        BEQ     loc_EDAF                                ; branche vers loc_EDAF si la condition EQ est vraie ; @ ED9B: 27 12
        CLC                                             ; @ ED9D: 0C
        LDAA    #$70                                    ; @ ED9E: 86 70
        ADDA    ,X                                      ; @ EDA0: AB 00
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EDA2: 19
        STAA    ,X                                      ; @ EDA3: A7 00
        LDAB    #$00                                    ; @ EDA5: C6 00
        ADCB    $01,X                                   ; @ EDA7: E9 01
        TBA                                             ; @ EDA9: 17
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EDAA: 19
        STAA    $01,X                                   ; @ EDAB: A7 01
        BRA     loc_EDE4                                ; branche toujours vers loc_EDE4 ; @ EDAD: 20 35
loc_EDAF:
        CLC                                             ; @ EDAF: 0C
        LDAA    ,X                                      ; @ EDB0: A6 00
        CMPA    #$70                                    ; @ EDB2: 81 70
        BMI     loc_EDBD                                ; branche vers loc_EDBD si la condition MI est vraie ; @ EDB4: 2B 07
        CMPA    #$75                                    ; @ EDB6: 81 75
        BHI     loc_EDBD                                ; branche vers loc_EDBD si la condition HI est vraie ; @ EDB8: 22 03
        INC     RAM_8548                                ; @ EDBA: 7C 85 48
loc_EDBD:
        LDAA    #$95                                    ; @ EDBD: 86 95
        CLC                                             ; @ EDBF: 0C
        ADDA    ,X                                      ; @ EDC0: AB 00
        COMA                                            ; @ EDC2: 43
        CLC                                             ; @ EDC3: 0C
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EDC4: 19
        BCC     loc_EDD7                                ; branche vers loc_EDD7 si la condition CC est vraie ; @ EDC5: 24 10
loc_EDC7:
        CLR     $01,X                                   ; @ EDC7: 6F 01
        INC     RAM_854A                                ; @ EDC9: 7C 85 4A
        COM     ,X                                      ; @ EDCC: 63 00
        CLC                                             ; @ EDCE: 0C
        LDAA    ,X                                      ; @ EDCF: A6 00
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EDD1: 19
        ADDA    #$70                                    ; @ EDD2: 8B 70
        COMA                                            ; @ EDD4: 43
        CLC                                             ; @ EDD5: 0C
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EDD6: 19
loc_EDD7:
        LDAB    $01,X                                   ; @ EDD7: E6 01
        BNE     loc_EDC7                                ; branche vers loc_EDC7 si la condition NE est vraie ; @ EDD9: 26 EC
        LDAB    RAM_8548                                ; @ EDDB: F6 85 48
        BEQ     loc_EDE2                                ; branche vers loc_EDE2 si la condition EQ est vraie ; @ EDDE: 27 02
        SUBA    #$60                                    ; @ EDE0: 80 60
loc_EDE2:
        STAA    ,X                                      ; @ EDE2: A7 00
loc_EDE4:
        LDAA    RAM_8560                                ; @ EDE4: B6 85 60
        LSRA                                            ; @ EDE7: 44
        LSRA                                            ; @ EDE8: 44
        LSRA                                            ; @ EDE9: 44
        LSRA                                            ; @ EDEA: 44
        LDAB    RAM_8561                                ; @ EDEB: F6 85 61
        ASLB                                            ; @ EDEE: 58
        ASLB                                            ; @ EDEF: 58
        ASLB                                            ; @ EDF0: 58
        ASLB                                            ; @ EDF1: 58
        ABA                                             ; @ EDF2: 1B
        STAA    RAM_8543                                ; @ EDF3: B7 85 43
        LDAA    RAM_8561                                ; @ EDF6: B6 85 61
        LSRA                                            ; @ EDF9: 44
        LSRA                                            ; @ EDFA: 44
        LSRA                                            ; @ EDFB: 44
        LSRA                                            ; @ EDFC: 44
        STAA    RAM_8544                                ; @ EDFD: B7 85 44
        LDX     #RAM_8543                               ; @ EE00: CE 85 43
        JSR     sub_EF83                                ; appelle sub_EF83 ; @ EE03: BD EF 83
        CLRB                                            ; @ EE06: 5F
        CLC                                             ; @ EE07: 0C
        LDX     #attenuator_relay_table_bcd             ; @ EE08: CE C1 F6
        STX     RAM_854C                                ; @ EE0B: FF 85 4C
        LDAA    RAM_8543                                ; @ EE0E: B6 85 43
        STAA    RAM_8042                                ; @ EE11: B7 80 42
        ADDA    RAM_854D                                ; @ EE14: BB 85 4D
        STAA    RAM_854D                                ; @ EE17: B7 85 4D
        ADCB    RAM_854C                                ; @ EE1A: F9 85 4C
        STAB    RAM_854C                                ; @ EE1D: F7 85 4C
        LDX     RAM_854C                                ; @ EE20: FE 85 4C
        LDAA    ,X                                      ; @ EE23: A6 00
        LDAB    RAM_854A                                ; @ EE25: F6 85 4A
        BEQ     loc_EE2C                                ; branche vers loc_EE2C si la condition EQ est vraie ; @ EE28: 27 02
        LDAA    #$3F                                    ; @ EE2A: 86 3F
loc_EE2C:
        LDAB    RAM_8506                                ; @ EE2C: F6 85 06
        ANDB    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EE2F: C4 C0
        ABA                                             ; @ EE31: 1B
        STAA    RAM_8506                                ; @ EE32: B7 85 06
        STAA    INST_06_ATTENUATOR_AND_PULSE            ; émet l'adresse instrument 6 (attenuator and pulse) ; @ EE35: B7 60 06
        LDX     #RAM_8543                               ; @ EE38: CE 85 43
        JSR     sub_EFB8                                ; appelle sub_EFB8 ; @ EE3B: BD EF B8
        CLC                                             ; @ EE3E: 0C
        COM     RAM_8560                                ; @ EE3F: 73 85 60
        LDAA    RAM_8560                                ; @ EE42: B6 85 60
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EE45: 19
        ADDA    ,X                                      ; @ EE46: AB 00
        COMA                                            ; @ EE48: 43
        CLC                                             ; @ EE49: 0C
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EE4A: 19
        CLR     $01,X                                   ; @ EE4B: 6F 01
        TAB                                             ; @ EE4D: 16
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EE4E: 84 0F
        STAA    RAM_8508                                ; @ EE50: B7 85 08
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EE53: C4 F0
        ADDB    #$60                                    ; @ EE55: CB 60
        LDAA    RAM_854A                                ; @ EE57: B6 85 4A
        BEQ     loc_EE80                                ; branche vers loc_EE80 si la condition EQ est vraie ; @ EE5A: 27 24
        SUBB    #$60                                    ; @ EE5C: C0 60
        LDAA    DP_005F                                 ; @ EE5E: 96 5F
        BEQ     loc_EE6E                                ; branche vers loc_EE6E si la condition EQ est vraie ; @ EE60: 27 0C
        LDAA    DP_005E                                 ; @ EE62: 96 5E
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EE64: 84 F0
        CMPA    #$20                                    ; @ EE66: 81 20
        BMI     loc_EE6E                                ; branche vers loc_EE6E si la condition MI est vraie ; @ EE68: 2B 04
        LDAA    #$55                                    ; @ EE6A: 86 55
        BRA     loc_EE70                                ; branche toujours vers loc_EE70 ; @ EE6C: 20 02
loc_EE6E:
        LDAA    #$05                                    ; @ EE6E: 86 05
loc_EE70:
        ADDB    RAM_8508                                ; @ EE70: FB 85 08
        ABA                                             ; @ EE73: 1B
        COMA                                            ; @ EE74: 43
        CLC                                             ; @ EE75: 0C
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EE76: 19
        TAB                                             ; @ EE77: 16
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EE78: C4 0F
        STAB    RAM_8508                                ; @ EE7A: F7 85 08
        TAB                                             ; @ EE7D: 16
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EE7E: C4 F0
loc_EE80:
        CMPB    #$80                                    ; @ EE80: C1 80
        BMI     loc_EE86                                ; branche vers loc_EE86 si la condition MI est vraie ; @ EE82: 2B 02
        ADDB    #$40                                    ; @ EE84: CB 40
loc_EE86:
        LDAA    RAM_8508                                ; @ EE86: B6 85 08
        ABA                                             ; @ EE89: 1B
        STAA    RAM_8508                                ; @ EE8A: B7 85 08
loc_EE8D:
        LDX     RAM_801B                                ; @ EE8D: FE 80 1B
        CPX     #ROM_DATA_FFFF                          ; @ EE90: 8C FF FF
        BNE     loc_EE98                                ; branche vers loc_EE98 si la condition NE est vraie ; @ EE93: 26 03
        LDX     #DP_0000                                ; @ EE95: CE 00 00
loc_EE98:
        STX     DP_005E                                 ; @ EE98: DF 5E
        LDAA    RAM_801A                                ; @ EE9A: B6 80 1A
        STAA    DP_0060                                 ; @ EE9D: 97 60
        LDX     #ROM_DATA_FFFC                          ; @ EE9F: CE FF FC
loc_EEA2:
        LSR     >DP_005F                                ; @ EEA2: 74 00 5F
        ROR     >DP_005E                                ; @ EEA5: 76 00 5E
        ROR     >DP_0060                                ; @ EEA8: 76 00 60
        INX                                             ; @ EEAB: 08
        BNE     loc_EEA2                                ; branche vers loc_EEA2 si la condition NE est vraie ; @ EEAC: 26 F4
        LDAA    DP_005E                                 ; @ EEAE: 96 5E
        LDAB    DP_005F                                 ; @ EEB0: D6 5F
        CMPB    #$02                                    ; @ EEB2: C1 02
        BCS     loc_EEB7                                ; branche vers loc_EEB7 si la condition CS est vraie ; @ EEB4: 25 01
        CLRB                                            ; @ EEB6: 5F
loc_EEB7:
        STAB    DP_005E                                 ; @ EEB7: D7 5E
        TAB                                             ; @ EEB9: 16
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EEBA: 84 F0
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EEBC: C4 0F
        CMPA    #$A0                                    ; @ EEBE: 81 A0
        BCS     loc_EEC3                                ; branche vers loc_EEC3 si la condition CS est vraie ; @ EEC0: 25 01
        CLRA                                            ; @ EEC2: 4F
loc_EEC3:
        CMPB    #$0A                                    ; @ EEC3: C1 0A
        BCS     loc_EEC8                                ; branche vers loc_EEC8 si la condition CS est vraie ; @ EEC5: 25 01
        CLRB                                            ; @ EEC7: 5F
loc_EEC8:
        ABA                                             ; @ EEC8: 1B
        JSR     sub_EF7A                                ; appelle sub_EF7A ; @ EEC9: BD EF 7A
        LDX     #RAM_A240                               ; @ EECC: CE A2 40
        LDAB    #$05                                    ; @ EECF: C6 05
        STAB    DP_0062                                 ; @ EED1: D7 62
        LDAB    DP_005E                                 ; @ EED3: D6 5E
        ANDB    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EED5: C4 01
        BEQ     loc_EEDB                                ; branche vers loc_EEDB si la condition EQ est vraie ; @ EED7: 27 02
        ADDA    #$64                                    ; @ EED9: 8B 64
loc_EEDB:
        DECA                                            ; @ EEDB: 4A
        TSTA                                            ; @ EEDC: 4D
        BPL     loc_EEFD                                ; branche vers loc_EEFD si la condition PL est vraie ; @ EEDD: 2A 1E
        LDX     #RAM_A120                               ; @ EEDF: CE A1 20
        LDAA    #$01                                    ; @ EEE2: 86 01
        STAA    DP_0062                                 ; @ EEE4: 97 62
        LDAA    DP_0060                                 ; @ EEE6: 96 60
        TAB                                             ; @ EEE8: 16
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EEE9: 84 F0
        LSRA                                            ; @ EEEB: 44
        LSRA                                            ; @ EEEC: 44
        LSRA                                            ; @ EEED: 44
        LSRA                                            ; @ EEEE: 44
        DECA                                            ; @ EEEF: 4A
        BPL     loc_EEFD                                ; branche vers loc_EEFD si la condition PL est vraie ; @ EEF0: 2A 0B
        LDX     #RAM_A000                               ; @ EEF2: CE A0 00
        LDAA    #$01                                    ; @ EEF5: 86 01
        STAA    DP_0062                                 ; @ EEF7: 97 62
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EEF9: C4 0F
        TBA                                             ; @ EEFB: 17
        DECA                                            ; @ EEFC: 4A
loc_EEFD:
        PSHA                                            ; @ EEFD: 36
        STX     DP_005E                                 ; @ EEFE: DF 5E
        LDAA    RAM_8042                                ; @ EF00: B6 80 42
        JSR     sub_EF7A                                ; appelle sub_EF7A ; @ EF03: BD EF 7A
        CMPA    #$01                                    ; @ EF06: 81 01
        BNE     loc_EF10                                ; branche vers loc_EF10 si la condition NE est vraie ; @ EF08: 26 06
        LDAB    RAM_854A                                ; @ EF0A: F6 85 4A
        BEQ     loc_EF10                                ; branche vers loc_EF10 si la condition EQ est vraie ; @ EF0D: 27 01
        CLRA                                            ; @ EF0F: 4F
loc_EF10:
        ADDA    DP_005F                                 ; @ EF10: 9B 5F
        STAA    DP_005F                                 ; @ EF12: 97 5F
        LDAA    #$00                                    ; @ EF14: 86 00
        ADCA    DP_005E                                 ; @ EF16: 99 5E
        STAA    DP_005E                                 ; @ EF18: 97 5E
        PULA                                            ; @ EF1A: 32
loc_EF1B:
        CMPA    DP_0062                                 ; @ EF1B: 91 62
        BCS     loc_EF30                                ; branche vers loc_EF30 si la condition CS est vraie ; @ EF1D: 25 11
        SUBA    DP_0062                                 ; @ EF1F: 90 62
        PSHA                                            ; @ EF21: 36
        CLRA                                            ; @ EF22: 4F
        LDAB    #$20                                    ; @ EF23: C6 20
        ADDB    DP_005F                                 ; @ EF25: DB 5F
        STAB    DP_005F                                 ; @ EF27: D7 5F
        ADCA    DP_005E                                 ; @ EF29: 99 5E
        STAA    DP_005E                                 ; @ EF2B: 97 5E
        PULA                                            ; @ EF2D: 32
        BRA     loc_EF1B                                ; branche toujours vers loc_EF1B ; @ EF2E: 20 EB
loc_EF30:
        LDX     DP_005E                                 ; @ EF30: DE 5E
        LDAB    ,X                                      ; @ EF32: E6 00
        COMB                                            ; @ EF34: 53
        PSHB                                            ; @ EF35: 37
        LDAA    RAM_8508                                ; @ EF36: B6 85 08
        TAB                                             ; @ EF39: 16
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EF3A: C4 0F
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EF3C: 84 F0
        CMPA    #$70                                    ; @ EF3E: 81 70
        BNE     loc_EF44                                ; branche vers loc_EF44 si la condition NE est vraie ; @ EF40: 26 02
        ADDA    #$40                                    ; @ EF42: 8B 40
loc_EF44:
        ADDA    #$10                                    ; @ EF44: 8B 10
        ABA                                             ; @ EF46: 1B
        CMPA    #$80                                    ; @ EF47: 81 80
        BCS     loc_EF4D                                ; branche vers loc_EF4D si la condition CS est vraie ; @ EF49: 25 02
        SUBA    #$40                                    ; @ EF4B: 80 40
loc_EF4D:
        JSR     sub_EF7A                                ; appelle sub_EF7A ; @ EF4D: BD EF 7A
        PULB                                            ; @ EF50: 33
        ABA                                             ; @ EF51: 1B
        CLR     >DP_005E                                ; @ EF52: 7F 00 5E
        LDAB    #$0A                                    ; @ EF55: C6 0A
loc_EF57:
        CBA                                             ; @ EF57: 11
        BCS     loc_EF60                                ; branche vers loc_EF60 si la condition CS est vraie ; @ EF58: 25 06
        SBA                                             ; @ EF5A: 10
        INC     >DP_005E                                ; @ EF5B: 7C 00 5E
        BRA     loc_EF57                                ; branche toujours vers loc_EF57 ; @ EF5E: 20 F7
loc_EF60:
        LDAB    DP_005E                                 ; @ EF60: D6 5E
        ASLB                                            ; @ EF62: 58
        ASLB                                            ; @ EF63: 58
        ASLB                                            ; @ EF64: 58
        ASLB                                            ; @ EF65: 58
        ABA                                             ; @ EF66: 1B
        CMPA    #$60                                    ; @ EF67: 81 60
        BCS     write_fine_attenuation_address_8        ; branche vers write_fine_attenuation_address_8 si la condition CS est vraie ; @ EF69: 25 02
        ADDA    #$20                                    ; @ EF6B: 8B 20

; ---------------------------------------------------------------------------
; ROUTINE $EF6D — write_fine_attenuation_address_8
; CONFIRMÉ — étape d'émission de l'atténuation fine au sein du réglage de niveau.
; Entrées : A contient le code de l'adresse 8 après permutation des poids 4/8 dB et correction BCD.
; Sorties : registre instrument 8 chargé; la routine enchaîne sur la finalisation de l'adresse 6.
; Registres/flags : A conservé par l'écriture, B sert à la courte temporisation qui suit.
; RAM/E/S : écrit $6008 puis appelle $CC7E pour D7 (+5 dB/AM) et D6 (Pulse).
; Algorithme : émet le DAC fin, attend l'établissement matériel et réémet l'image finale de l'atténuateur.
; ---------------------------------------------------------------------------
write_fine_attenuation_address_8:
        STAA    INST_08_FINE_ATTENUATION                ; émet l'adresse instrument 8 (fine attenuation) ; @ EF6D: B7 60 08
loc_EF70:
        LDAB    #$1F                                    ; @ EF70: C6 1F
loc_EF72:
        DECB                                            ; @ EF72: 5A
        BNE     loc_EF72                                ; branche vers loc_EF72 si la condition NE est vraie ; @ EF73: 26 FD
        JSR     update_instrument_address_6_control_bits ; appelle update_instrument_address_6_control_bits ; @ EF75: BD CC 7E
        CLI                                             ; autorise à nouveau les IRQ ; @ EF78: 0E
        RTS                                             ; @ EF79: 39

; ---------------------------------------------------------------------------
; ROUTINE $EF7A — sub_EF7A
; INCONNU — sous-routine interne à $EF7A; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $EEC9, $EF03, $EF4D. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EF7A:
        TAB                                             ; @ EF7A: 16
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EF7B: C4 F0
        LSRB                                            ; @ EF7D: 54
        LSRB                                            ; @ EF7E: 54
        SBA                                             ; @ EF7F: 10
        LSRB                                            ; @ EF80: 54
        SBA                                             ; @ EF81: 10
        RTS                                             ; @ EF82: 39

; ---------------------------------------------------------------------------
; ROUTINE $EF83 — sub_EF83
; INCONNU — sous-routine interne à $EF83; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $EE03. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EF83:
        LDAA    ,X                                      ; @ EF83: A6 00
        LDAB    ,X                                      ; @ EF85: E6 00
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EF87: 84 0F
        CMPA    #$08                                    ; @ EF89: 81 08
        BMI     loc_EF93                                ; branche vers loc_EF93 si la condition MI est vraie ; @ EF8B: 2B 06
        LDAA    #$03                                    ; @ EF8D: 86 03
        ADDA    ,X                                      ; @ EF8F: AB 00
        STAA    ,X                                      ; @ EF91: A7 00
loc_EF93:
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EF93: C4 F0
        CMPB    #$80                                    ; @ EF95: C1 80
        BMI     loc_EF9F                                ; branche vers loc_EF9F si la condition MI est vraie ; @ EF97: 2B 06
        LDAB    #$30                                    ; @ EF99: C6 30
        ADDB    ,X                                      ; @ EF9B: EB 00
        STAB    ,X                                      ; @ EF9D: E7 00
loc_EF9F:
        CLC                                             ; @ EF9F: 0C
        ROL     ,X                                      ; @ EFA0: 69 00
        ROL     $01,X                                   ; @ EFA2: 69 01
        LDAA    ,X                                      ; @ EFA4: A6 00
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ EFA6: 19
        STAA    ,X                                      ; @ EFA7: A7 00
        BCC     loc_EFAD                                ; branche vers loc_EFAD si la condition CC est vraie ; @ EFA9: 24 02
        INC     $01,X                                   ; @ EFAB: 6C 01
loc_EFAD:
        LDAB    #$04                                    ; @ EFAD: C6 04
loc_EFAF:
        CLC                                             ; @ EFAF: 0C
        ROR     $01,X                                   ; @ EFB0: 66 01
        ROR     ,X                                      ; @ EFB2: 66 00
        DECB                                            ; @ EFB4: 5A
        BNE     loc_EFAF                                ; branche vers loc_EFAF si la condition NE est vraie ; @ EFB5: 26 F8
        RTS                                             ; @ EFB7: 39

; ---------------------------------------------------------------------------
; ROUTINE $EFB8 — sub_EFB8
; INCONNU — sous-routine interne à $EFB8; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $EE3B. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EFB8:
        LDAA    ,X                                      ; @ EFB8: A6 00
        LSRA                                            ; @ EFBA: 44
        LSRA                                            ; @ EFBB: 44
        LSRA                                            ; @ EFBC: 44
        LSRA                                            ; @ EFBD: 44
        LDAB    ,X                                      ; @ EFBE: E6 00
        ASLB                                            ; @ EFC0: 58
        ASLB                                            ; @ EFC1: 58
        ASLB                                            ; @ EFC2: 58
        ASLB                                            ; @ EFC3: 58
        STAB    ,X                                      ; @ EFC4: E7 00
        STAA    $01,X                                   ; @ EFC6: A7 01
        CLC                                             ; @ EFC8: 0C
        ROR     $01,X                                   ; @ EFC9: 66 01
        ROR     ,X                                      ; @ EFCB: 66 00
        LDAA    ,X                                      ; @ EFCD: A6 00
        LDAB    ,X                                      ; @ EFCF: E6 00
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EFD1: 84 0F
        CMPA    #$08                                    ; @ EFD3: 81 08
        BMI     loc_EFD9                                ; branche vers loc_EFD9 si la condition MI est vraie ; @ EFD5: 2B 02
        SUBA    #$03                                    ; @ EFD7: 80 03
loc_EFD9:
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EFD9: C4 F0
        CMPB    #$80                                    ; @ EFDB: C1 80
        BMI     loc_EFE1                                ; branche vers loc_EFE1 si la condition MI est vraie ; @ EFDD: 2B 02
        SUBB    #$30                                    ; @ EFDF: C0 30
loc_EFE1:
        ABA                                             ; @ EFE1: 1B
        STAA    ,X                                      ; @ EFE2: A7 00
        LDAB    #$04                                    ; @ EFE4: C6 04
loc_EFE6:
        CLC                                             ; @ EFE6: 0C
        ROL     ,X                                      ; @ EFE7: 69 00
        ROL     $01,X                                   ; @ EFE9: 69 01
        DECB                                            ; @ EFEB: 5A
        BNE     loc_EFE6                                ; branche vers loc_EFE6 si la condition NE est vraie ; @ EFEC: 26 F8
        RTS                                             ; @ EFEE: 39

; ---------------------------------------------------------------------------
; ROUTINE $EFEF — sub_EFEF
; INCONNU — sous-routine interne à $EFEF; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C681. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_EFEF:
        LDAB    DP_004A                                 ; @ EFEF: D6 4A
        BITB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EFF1: C5 08
        BEQ     loc_EFF9                                ; branche vers loc_EFF9 si la condition EQ est vraie ; @ EFF3: 27 04
        CLR     >DP_006B                                ; @ EFF5: 7F 00 6B
        RTS                                             ; @ EFF8: 39
loc_EFF9:
        LDAB    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ EFF9: F6 20 02
        ROLB                                            ; @ EFFC: 59
        ROLB                                            ; @ EFFD: 59
        ROLB                                            ; @ EFFE: 59
        ANDB    #$03                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ EFFF: C4 03
        BITB    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F001: C5 01
        BNE     loc_F00A                                ; branche vers loc_F00A si la condition NE est vraie ; @ F003: 26 05
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F005: CA 80
        STAB    DP_006B                                 ; @ F007: D7 6B
loc_F009:
        RTS                                             ; @ F009: 39
loc_F00A:
        BITA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F00A: 85 01
        BNE     loc_F013                                ; branche vers loc_F013 si la condition NE est vraie ; @ F00C: 26 05
        CLR     >DP_006B                                ; @ F00E: 7F 00 6B
        BRA     loc_F04A                                ; branche toujours vers loc_F04A ; @ F011: 20 37
loc_F013:
        BITB    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F013: C5 02
        BEQ     loc_F009                                ; branche vers loc_F009 si la condition EQ est vraie ; @ F015: 27 F2
        CLR     >DP_006B                                ; @ F017: 7F 00 6B
loc_F01A:
        LDAA    RAM_800D                                ; @ F01A: B6 80 0D
        ADDA    #$01                                    ; @ F01D: 8B 01
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ F01F: 19
        BCC     loc_F04D                                ; branche vers loc_F04D si la condition CC est vraie ; @ F020: 24 2B
        LDAA    #$9A                                    ; @ F022: 86 9A
        BRA     loc_F04D                                ; branche toujours vers loc_F04D ; @ F024: 20 27
loc_F026:
        LDAA    DP_004A                                 ; @ F026: 96 4A
        BITA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F028: 85 08
        BEQ     loc_F02D                                ; branche vers loc_F02D si la condition EQ est vraie ; @ F02A: 27 01
        RTS                                             ; @ F02C: 39
loc_F02D:
        BCC     loc_F01A                                ; branche vers loc_F01A si la condition CC est vraie ; @ F02D: 24 EB
        LDAB    RAM_8044                                ; @ F02F: F6 80 44
        BNE     loc_F04A                                ; branche vers loc_F04A si la condition NE est vraie ; @ F032: 26 16
        LDAA    RAM_800D                                ; @ F034: B6 80 0D
        BITA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F037: 85 0F
        BNE     loc_F041                                ; branche vers loc_F041 si la condition NE est vraie ; @ F039: 26 06
        BITA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F03B: 85 F0
        BEQ     loc_F054                                ; branche vers loc_F054 si la condition EQ est vraie ; @ F03D: 27 15
        SUBA    #$06                                    ; @ F03F: 80 06
loc_F041:
        SUBA    #$01                                    ; @ F041: 80 01
        CMPA    RAM_800B                                ; @ F043: B1 80 0B
        BCC     loc_F059                                ; branche vers loc_F059 si la condition CC est vraie ; @ F046: 24 11
        BRA     loc_F054                                ; branche toujours vers loc_F054 ; @ F048: 20 0A
loc_F04A:
        LDAA    RAM_800B                                ; @ F04A: B6 80 0B
loc_F04D:
        CMPA    RAM_800A                                ; @ F04D: B1 80 0A
        BCS     loc_F059                                ; branche vers loc_F059 si la condition CS est vraie ; @ F050: 25 07
        BEQ     loc_F059                                ; branche vers loc_F059 si la condition EQ est vraie ; @ F052: 27 05
loc_F054:
        LDAA    #$89                                    ; @ F054: 86 89
        JMP     sub_CAE9                                ; transfert sans retour vers sub_CAE9 ; @ F056: 7E CA E9
loc_F059:
        STAA    DP_005D                                 ; @ F059: 97 5D
        STAA    RAM_800D                                ; @ F05B: B7 80 0D
        LDAA    #$4E                                    ; @ F05E: 86 4E
        STAA    DP_003B                                 ; @ F060: 97 3B
        LDAA    #$84                                    ; @ F062: 86 84
        STAA    DP_0049                                 ; @ F064: 97 49
        LDAA    #$FF                                    ; @ F066: 86 FF
        STAA    RAM_8018                                ; @ F068: B7 80 18
        LDAA    DP_005D                                 ; @ F06B: 96 5D
        STAA    RAM_801A                                ; @ F06D: B7 80 1A
        LDX     #loc_EAFF                               ; @ F070: CE EA FF
        STX     RAM_801B                                ; @ F073: FF 80 1B
        JMP     loc_E172                                ; transfert sans retour vers loc_E172 ; @ F076: 7E E1 72
        FCB     $F0,$C5,$F0,$F4,$F1,$17,$F1,$21         ; données '.......!' ; @ F079: F0 C5 F0 F4 F1 17 F1 21
        FCB     $F1,$2C,$F1,$3D,$F1,$31,$F1,$42         ; données '.,.=.1.B' ; @ F081: F1 2C F1 3D F1 31 F1 42
        FCB     $F1,$54,$F1,$6B,$F1,$94                 ; données '.T.k..' ; @ F089: F1 54 F1 6B F1 94

; ---------------------------------------------------------------------------
; ROUTINE $F08F — resume_front_panel_dispatch
; DÉDUIT — reprise correctement alignée du distributeur panneau avant.
; Entrées : A contient le code lu; $8047 sélectionne une voie de traitement.
; Sorties : branche vers le gestionnaire correspondant au caractère/événement.
; Registres/flags : A/B/X et CCR modifiés selon la branche.
; RAM/E/S : RAM directe $006D et tables de pointeurs voisines de $F077.
; Algorithme : filtre espace, LF, CR et '?', puis indexe une table de vecteurs.
; ---------------------------------------------------------------------------
resume_front_panel_dispatch:
        LDAB    RAM_8047                                ; @ F08F: F6 80 47
        CMPA    #$20                                    ; @ F092: 81 20
        BEQ     loc_F0BD                                ; branche vers loc_F0BD si la condition EQ est vraie ; @ F094: 27 27
        CMPA    #$0A                                    ; @ F096: 81 0A
        BEQ     loc_F0BD                                ; branche vers loc_F0BD si la condition EQ est vraie ; @ F098: 27 23
        CMPA    #$0D                                    ; @ F09A: 81 0D
        BEQ     loc_F0B3                                ; branche vers loc_F0B3 si la condition EQ est vraie ; @ F09C: 27 15
        CMPA    #$3F                                    ; @ F09E: 81 3F
        BEQ     loc_F0B3                                ; branche vers loc_F0B3 si la condition EQ est vraie ; @ F0A0: 27 11
        LDX     #ROM_DATA_F077                          ; @ F0A2: CE F0 77
        LDAB    DP_006D                                 ; @ F0A5: D6 6D
loc_F0A7:
        INX                                             ; @ F0A7: 08
        INX                                             ; @ F0A8: 08
        DECB                                            ; @ F0A9: 5A
        BGE     loc_F0A7                                ; branche vers loc_F0A7 si la condition GE est vraie ; @ F0AA: 2C FB
        JSR     sub_F1E9                                ; appelle sub_F1E9 ; @ F0AC: BD F1 E9
        LDX     ,X                                      ; @ F0AF: EE 00
        JMP     ,X                                      ; transfert sans retour vers ,X ; @ F0B1: 6E 00
loc_F0B3:
        CMPB    #$C0                                    ; @ F0B3: C1 C0
        BEQ     loc_F0BF                                ; branche vers loc_F0BF si la condition EQ est vraie ; @ F0B5: 27 08
        CMPB    #$A0                                    ; @ F0B7: C1 A0
        BEQ     loc_F0C2                                ; branche vers loc_F0C2 si la condition EQ est vraie ; @ F0B9: 27 07
        CLR     >DP_006D                                ; @ F0BB: 7F 00 6D
        RTS                                             ; @ F0BE: 39
loc_F0BF:
        JMP     loc_F238                                ; transfert sans retour vers loc_F238 ; @ F0BF: 7E F2 38
loc_F0C2:
        JMP     loc_F2A6                                ; transfert sans retour vers loc_F2A6 ; @ F0C2: 7E F2 A6
        FCB     $F6,$80,$47,$54,$25,$1A,$CE,$00         ; données '..GT%...' ; @ F0C5: F6 80 47 54 25 1A CE 00
        FCB     $00,$DF,$5E,$BF,$80,$45,$8E,$9F         ; données '..^..E..' ; @ F0CD: 00 DF 5E BF 80 45 8E 9F
        FCB     $FF,$CE,$98,$00,$32,$A7,$00,$08         ; données '....2...' ; @ F0D5: FF CE 98 00 32 A7 00 08
        FCB     $8C,$A0,$00,$26,$F7,$BE,$80,$45         ; données '...&...E' ; @ F0DD: 8C A0 00 26 F7 BE 80 45
        FCB     $7C,$00,$6D,$CE,$00,$00,$DF,$5E         ; données '|.m....^' ; @ F0E5: 7C 00 6D CE 00 00 DF 5E
        FCB     $DF,$60,$DF,$61,$DF,$6E,$39,$F6         ; données '.`.a.n9.' ; @ F0ED: DF 60 DF 61 DF 6E 39 F6
        FCB     $80,$47,$CB,$04,$81,$09,$27,$10         ; données '.G....'.' ; @ F0F5: 80 47 CB 04 81 09 27 10
        FCB     $C5,$02,$27,$02,$C0,$02,$C0,$02         ; données '..'.....' ; @ F0FD: C5 02 27 02 C0 02 C0 02
        FCB     $81,$01,$27,$04,$5A,$4D,$26,$07         ; données '..'.ZM&.' ; @ F105: 81 01 27 04 5A 4D 26 07
        FCB     $F7,$80,$47,$7C,$00,$6D,$39,$7E         ; données '..G|.m9~' ; @ F10D: F7 80 47 7C 00 6D 39 7E
        FCB     $F2,$0A,$48,$48,$48,$48,$97,$61         ; données '..HHHH.a' ; @ F115: F2 0A 48 48 48 48 97 61
        FCB     $7C,$00,$6D,$39,$D6,$61,$1B,$97         ; données '|.m9.a..' ; @ F11D: 7C 00 6D 39 D6 61 1B 97
        FCB     $61,$97,$62,$7C,$00,$6D,$39,$DE         ; données 'a.b|.m9.' ; @ F125: 61 97 62 7C 00 6D 39 DE
        FCB     $6E,$09,$20,$02,$DE,$6E,$48,$48         ; données 'n. ..nHH' ; @ F12D: 6E 09 20 02 DE 6E 48 48
        FCB     $48,$48,$A7,$5F,$7C,$00,$6D,$39         ; données 'HH._|.m9' ; @ F135: 48 48 A7 5F 7C 00 6D 39
        FCB     $DE,$6E,$09,$20,$02,$DE,$6E,$7A         ; données '.n. ..nz' ; @ F13D: DE 6E 09 20 02 DE 6E 7A
        FCB     $00,$61,$E6,$5F,$1B,$A7,$5F,$9B         ; données '.a._.._.' ; @ F145: 00 61 E6 5F 1B A7 5F 9B
        FCB     $62,$97,$62,$7C,$00,$6D,$39,$7A         ; données 'b.b|.m9z' ; @ F14D: 62 97 62 7C 00 6D 39 7A
        FCB     $00,$61,$27,$0A,$48,$48,$48,$48         ; données '.a'.HHHH' ; @ F155: 00 61 27 0A 48 48 48 48
        FCB     $97,$60,$7C,$00,$6D,$39,$7C,$00         ; données '.`|.m9|.' ; @ F15D: 97 60 7C 00 6D 39 7C 00
        FCB     $6D,$7C,$00,$6D,$20,$22,$D6,$60         ; données 'm|.m ".`' ; @ F165: 6D 7C 00 6D 20 22 D6 60
        FCB     $1B,$16,$DB,$62,$D7,$62,$D6,$5E         ; données '...b.b.^' ; @ F16D: 1B 16 DB 62 D7 62 D6 5E
        FCB     $CB,$98,$D7,$72,$D6,$5F,$D7,$73         ; données '...r._.s' ; @ F175: CB 98 D7 72 D6 5F D7 73
        FCB     $DE,$72,$A7,$00,$DE,$5E,$08,$DF         ; données '.r...^..' ; @ F17D: DE 72 A7 00 DE 5E 08 DF
        FCB     $5E,$7F,$00,$60,$7A,$00,$6D,$39         ; données '^..`z.m9' ; @ F185: 5E 7F 00 60 7A 00 6D 39
        FCB     $48,$48,$48,$48,$97,$60,$39,$D6         ; données 'HHHH.`9.' ; @ F18D: 48 48 48 48 97 60 39 D6
        FCB     $60,$1B,$9B,$62,$81,$FF,$27,$03         ; données '`..b..'.' ; @ F195: 60 1B 9B 62 81 FF 27 03
        FCB     $7E,$F2,$0A,$B6,$80,$47,$81,$87         ; données '~....G..' ; @ F19D: 7E F2 0A B6 80 47 81 87
        FCB     $27,$01,$39,$BF,$80,$45,$8E,$97         ; données ''.9..E..' ; @ F1A5: 27 01 39 BF 80 45 8E 97
        FCB     $FF,$CE,$A0,$00,$32,$E6,$00,$11         ; données '....2...' ; @ F1AD: FF CE A0 00 32 E6 00 11
        FCB     $27,$0F,$A7,$00,$9F,$5E,$BE,$80         ; données ''....^..' ; @ F1B5: 27 0F A7 00 9F 5E BE 80
        FCB     $45,$BD,$F2,$2D,$BF,$80,$45,$9E         ; données 'E..-..E.' ; @ F1BD: 45 BD F2 2D BF 80 45 9E
        FCB     $5E,$08,$8C,$A8,$00,$26,$E5,$8E         ; données '^....&..' ; @ F1C5: 5E 08 8C A8 00 26 E5 8E
        FCB     $97,$FF,$CE,$A0,$00,$32,$E6,$00         ; données '.....2..' ; @ F1CD: 97 FF CE A0 00 32 E6 00
        FCB     $11,$27,$04,$86,$97,$20,$30,$08         ; données '.'... 0.' ; @ F1D5: 11 27 04 86 97 20 30 08
        FCB     $8C,$A8,$00,$26,$F0,$BE,$80,$45         ; données '...&...E' ; @ F1DD: 8C A8 00 26 F0 BE 80 45
        FCB     $86,$99,$20,$23                         ; données '.. #' ; @ F1E5: 86 99 20 23

; ---------------------------------------------------------------------------
; ROUTINE $F1E9 — sub_F1E9
; INCONNU — sous-routine interne à $F1E9; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $F0AC. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_F1E9:
        CMPA    #$53                                    ; @ F1E9: 81 53
        BEQ     loc_F209                                ; branche vers loc_F209 si la condition EQ est vraie ; @ F1EB: 27 1C
        CMPA    #$30                                    ; @ F1ED: 81 30
        BMI     loc_F20A                                ; branche vers loc_F20A si la condition MI est vraie ; @ F1EF: 2B 19
        CMPA    #$39                                    ; @ F1F1: 81 39
        BLS     loc_F1FF                                ; branche vers loc_F1FF si la condition LS est vraie ; @ F1F3: 23 0A
        ANDA    #$5F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F1F5: 84 5F
        CMPA    #$41                                    ; @ F1F7: 81 41
        BMI     loc_F20A                                ; branche vers loc_F20A si la condition MI est vraie ; @ F1F9: 2B 0F
        CMPA    #$46                                    ; @ F1FB: 81 46
        BGT     loc_F20A                                ; branche vers loc_F20A si la condition GT est vraie ; @ F1FD: 2E 0B
loc_F1FF:
        SUBA    #$30                                    ; @ F1FF: 80 30
        BITA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F201: 85 10
        BEQ     loc_F207                                ; branche vers loc_F207 si la condition EQ est vraie ; @ F203: 27 02
        ADDA    #$09                                    ; @ F205: 8B 09
loc_F207:
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F207: 84 0F
loc_F209:
        RTS                                             ; @ F209: 39
loc_F20A:
        LDAA    #$95                                    ; @ F20A: 86 95
loc_F20C:
        TAB                                             ; @ F20C: 16
        SUBB    #$60                                    ; @ F20D: C0 60
        STAB    RAM_8800                                ; @ F20F: F7 88 00
        LDAB    #$0D                                    ; @ F212: C6 0D
        STAB    RAM_8801                                ; @ F214: F7 88 01
        LDAB    #$0A                                    ; @ F217: C6 0A
        STAB    RAM_8802                                ; @ F219: F7 88 02
        INC     >loc_E066                               ; @ F21C: 7C 00 66
        LDX     #RAM_8800                               ; @ F21F: CE 88 00
        STX     DP_0067                                 ; @ F222: DF 67
        JSR     sub_CAE9                                ; appelle sub_CAE9 ; @ F224: BD CA E9
loc_F227:
        CLR     RAM_8047                                ; @ F227: 7F 80 47
        JMP     loc_C5A4                                ; transfert sans retour vers loc_C5A4 ; @ F22A: 7E C5 A4

; ---------------------------------------------------------------------------
; ROUTINE $F22D — sub_F22D
; INCONNU — sous-routine interne à $F22D; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $F2B3. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_F22D:
        STX     DP_0072                                 ; @ F22D: DF 72
        LDX     #MEM_04E2                               ; @ F22F: CE 04 E2
loc_F232:
        DEX                                             ; @ F232: 09
        BNE     loc_F232                                ; branche vers loc_F232 si la condition NE est vraie ; @ F233: 26 FD
        LDX     DP_0072                                 ; @ F235: DE 72
        RTS                                             ; @ F237: 39
loc_F238:
        LDX     #RAM_9FFF                               ; @ F238: CE 9F FF
        STX     DP_005E                                 ; @ F23B: DF 5E
        CLR     >loc_E066                               ; @ F23D: 7F 00 66
loc_F240:
        LDX     #RAM_8800                               ; @ F240: CE 88 00
        STX     DP_0067                                 ; @ F243: DF 67
loc_F245:
        STX     DP_0072                                 ; @ F245: DF 72
        LDX     DP_005E                                 ; @ F247: DE 5E
        INX                                             ; @ F249: 08
        CPX     #RAM_A800                               ; @ F24A: 8C A8 00
        BNE     loc_F255                                ; branche vers loc_F255 si la condition NE est vraie ; @ F24D: 26 06
        STX     DP_005E                                 ; @ F24F: DF 5E
        LDX     DP_0072                                 ; @ F251: DE 72
        BRA     loc_F27D                                ; branche toujours vers loc_F27D ; @ F253: 20 28
loc_F255:
        LDAB    ,X                                      ; @ F255: E6 00
        STX     DP_005E                                 ; @ F257: DF 5E
        LDX     DP_0072                                 ; @ F259: DE 72
        TBA                                             ; @ F25B: 17
        LSRA                                            ; @ F25C: 44
        LSRA                                            ; @ F25D: 44
        LSRA                                            ; @ F25E: 44
        LSRA                                            ; @ F25F: 44
        ORAA    #$30                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F260: 8A 30
        CMPA    #$39                                    ; @ F262: 81 39
        BLS     loc_F268                                ; branche vers loc_F268 si la condition LS est vraie ; @ F264: 23 02
        ADDA    #$07                                    ; @ F266: 8B 07
loc_F268:
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F268: C4 0F
        ORAB    #$30                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ F26A: CA 30
        CMPB    #$39                                    ; @ F26C: C1 39
        BLS     loc_F272                                ; branche vers loc_F272 si la condition LS est vraie ; @ F26E: 23 02
        ADDB    #$07                                    ; @ F270: CB 07
loc_F272:
        STAA    ,X                                      ; @ F272: A7 00
        STAB    $01,X                                   ; @ F274: E7 01
        INX                                             ; @ F276: 08
        INX                                             ; @ F277: 08
        CPX     #RAM_8880                               ; @ F278: 8C 88 80
        BNE     loc_F245                                ; branche vers loc_F245 si la condition NE est vraie ; @ F27B: 26 C8
loc_F27D:
        LDAA    #$0D                                    ; @ F27D: 86 0D
        STAA    ,X                                      ; @ F27F: A7 00
        LDAA    #$0A                                    ; @ F281: 86 0A
        STAA    $01,X                                   ; @ F283: A7 01
        LDAA    #$E5                                    ; @ F285: 86 E5
        STAA    PIA_PORT_A_OR_DDRA                      ; accès au PIA 6821 du panneau avant ; @ F287: B7 40 00
        LDAA    #$20                                    ; @ F28A: 86 20
        STAA    PIA_CONTROL_B_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ F28C: B7 40 07
        INC     >loc_E066                               ; @ F28F: 7C 00 66
loc_F292:
        CLI                                             ; autorise à nouveau les IRQ ; @ F292: 0E
        NOP                                             ; @ F293: 01
        NOP                                             ; @ F294: 01
        NOP                                             ; @ F295: 01
        SEI                                             ; masque les IRQ pendant la section critique ; @ F296: 0F
        TST     >loc_E066                               ; @ F297: 7D 00 66
        BNE     loc_F292                                ; branche vers loc_F292 si la condition NE est vraie ; @ F29A: 26 F6
        LDX     DP_005E                                 ; @ F29C: DE 5E
        CPX     #RAM_A800                               ; @ F29E: 8C A8 00
        BNE     loc_F240                                ; branche vers loc_F240 si la condition NE est vraie ; @ F2A1: 26 9D
        JMP     loc_F227                                ; transfert sans retour vers loc_F227 ; @ F2A3: 7E F2 27
loc_F2A6:
        LDX     #RAM_A000                               ; @ F2A6: CE A0 00
loc_F2A9:
        LDAA    ,X                                      ; @ F2A9: A6 00
        CMPA    #$FF                                    ; @ F2AB: 81 FF
        BEQ     loc_F2C1                                ; branche vers loc_F2C1 si la condition EQ est vraie ; @ F2AD: 27 12
        LDAA    #$FF                                    ; @ F2AF: 86 FF
        STAA    ,X                                      ; @ F2B1: A7 00
        JSR     sub_F22D                                ; appelle sub_F22D ; @ F2B3: BD F2 2D
        LDAA    ,X                                      ; @ F2B6: A6 00
        CMPA    #$FF                                    ; @ F2B8: 81 FF
        BEQ     loc_F2C1                                ; branche vers loc_F2C1 si la condition EQ est vraie ; @ F2BA: 27 05
        LDAA    #$96                                    ; @ F2BC: 86 96
        JMP     loc_F20C                                ; transfert sans retour vers loc_F20C ; @ F2BE: 7E F2 0C
loc_F2C1:
        INX                                             ; @ F2C1: 08
        CPX     #RAM_A800                               ; @ F2C2: 8C A8 00
        BNE     loc_F2A9                                ; branche vers loc_F2A9 si la condition NE est vraie ; @ F2C5: 26 E2
        CLR     RAM_8047                                ; @ F2C7: 7F 80 47
        RTS                                             ; @ F2CA: 39
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F2CB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F2D3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F2DB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F2E3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F2EB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F2F3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F2FB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F303: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F30B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F313: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F31B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F323: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F32B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F333: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F33B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F343: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F34B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F353: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F35B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F363: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F36B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F373: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F37B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F383: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F38B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F393: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F39B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3A3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3AB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3B3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3BB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3C3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3CB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3D3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3DB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3E3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3EB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3F3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F3FB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F403: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F40B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F413: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F41B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F423: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F42B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F433: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F43B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F443: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F44B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F453: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F45B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F463: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F46B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F473: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F47B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F483: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F48B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F493: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F49B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4A3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4AB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4B3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4BB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4C3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4CB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4D3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4DB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4E3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4EB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4F3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F4FB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F503: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F50B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F513: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F51B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F523: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F52B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F533: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F53B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F543: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F54B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F553: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F55B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F563: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F56B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F573: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F57B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F583: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F58B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F593: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F59B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5A3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5AB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5B3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5BB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5C3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5CB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5D3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5DB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5E3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5EB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5F3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F5FB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F603: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F60B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F613: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F61B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F623: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F62B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F633: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F63B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F643: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F64B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F653: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F65B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F663: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F66B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F673: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F67B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F683: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F68B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F693: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F69B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6A3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6AB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6B3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6BB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6C3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6CB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6D3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6DB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6E3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6EB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6F3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F6FB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F703: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F70B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F713: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F71B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F723: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F72B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F733: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F73B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F743: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F74B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F753: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F75B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F763: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F76B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F773: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F77B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F783: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F78B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F793: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F79B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7A3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7AB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7B3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7BB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7C3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7CB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7D3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7DB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7E3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7EB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7F3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F7FB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F803: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F80B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F813: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F81B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F823: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F82B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F833: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F83B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F843: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F84B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F853: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F85B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F863: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F86B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F873: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F87B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F883: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F88B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F893: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F89B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8A3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8AB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8B3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8BB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8C3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8CB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8D3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8DB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8E3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8EB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8F3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F8FB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F903: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F90B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F913: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F91B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F923: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F92B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F933: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F93B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F943: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F94B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F953: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F95B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F963: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F96B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F973: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F97B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F983: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F98B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F993: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F99B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9A3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9AB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9B3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9BB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9C3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9CB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9D3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9DB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9E3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9EB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9F3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ F9FB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA03: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA0B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA13: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA1B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA23: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA2B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA33: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA3B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA43: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA4B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA53: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA5B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA63: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA6B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA73: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA7B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA83: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA8B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA93: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FA9B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAA3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAAB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAB3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FABB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAC3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FACB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAD3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FADB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAE3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAEB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAF3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FAFB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB03: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB0B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB13: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB1B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB23: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB2B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB33: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB3B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB43: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB4B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB53: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB5B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB63: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB6B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB73: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB7B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB83: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB8B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB93: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FB9B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBA3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBAB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBB3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBBB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBC3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBCB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBD3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBDB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBE3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBEB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBF3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FBFB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC03: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC0B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC13: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC1B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC23: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC2B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC33: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC3B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC43: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC4B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC53: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC5B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC63: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC6B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC73: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC7B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC83: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC8B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC93: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FC9B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCA3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCAB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCB3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCBB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCC3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCCB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCD3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCDB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCE3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCEB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCF3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FCFB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD03: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD0B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD13: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD1B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD23: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD2B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD33: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD3B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD43: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD4B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD53: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD5B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD63: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD6B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD73: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD7B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD83: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD8B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD93: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FD9B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDA3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDAB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDB3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDBB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDC3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDCB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDD3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDDB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDE3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDEB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDF3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FDFB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE03: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE0B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE13: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE1B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE23: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE2B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE33: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE3B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE43: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE4B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE53: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE5B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE63: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE6B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE73: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE7B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE83: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE8B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE93: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FE9B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEA3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEAB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEB3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEBB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEC3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FECB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FED3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEDB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEE3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEEB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEF3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FEFB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF03: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF0B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF13: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF1B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF23: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF2B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF33: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF3B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF43: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF4B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF53: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF5B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF63: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF6B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF73: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF7B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF83: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF8B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF93: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FF9B: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFA3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFAB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFB3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFBB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFC3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFCB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFD3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFDB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFE3: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF         ; données '........' ; @ FFEB: FF FF FF FF FF FF FF FF
        FCB     $FF,$FF,$FF,$FF,$FF                     ; données '.....' ; @ FFF3: FF FF FF FF FF

; ---------------------------------------------------------------------------
; CONFIRMÉ — vecteurs matériels du Motorola 6802 (big-endian).
; IRQ et SWI partagent le même gestionnaire; NMI reçoit la perte de PA.
; ---------------------------------------------------------------------------
hardware_vectors:
        FDB     irq_swi_front_panel_handler                 ; IRQ  ; @ FFF8: CC 9F
        FDB     irq_swi_front_panel_handler                 ; SWI  ; @ FFFA: CC 9F
        FDB     nmi_power_fail_handler                 ; NMI  ; @ FFFC: E1 DE
        FDB     reset_entry                 ; RESET ; @ FFFE: C3 3F

        END
