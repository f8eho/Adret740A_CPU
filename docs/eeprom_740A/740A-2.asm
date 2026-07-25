; ============================================================================
; ADRET 740A — source commentée de 740A-2.BIN
; Processeur : Motorola 6802 — syntaxe assembleur Motorola classique
; Implantation physique : $C000..$DFFF (8192 octets)
; SHA-256 de référence : 0F178E5DC3220DD51E5F7105D6238C6962E594B3AD1E1CF235A87AA4F26BDA31
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

        ORG     $C000

; ---------------------------------------------------------------------------
; Symboles mémoire et périphériques effectivement employés dans cette EPROM
; ---------------------------------------------------------------------------
DP_0000                                  EQU     $0000
DP_0001                                  EQU     $0001
DP_0002                                  EQU     $0002
DP_0004                                  EQU     $0004
DP_0007                                  EQU     $0007
DP_0008                                  EQU     $0008
DP_000A                                  EQU     $000A
DP_000C                                  EQU     $000C
DP_000F                                  EQU     $000F
DP_0010                                  EQU     $0010
DP_0011                                  EQU     $0011
DP_0013                                  EQU     $0013
DP_0016                                  EQU     $0016
DP_001A                                  EQU     $001A
DP_001C                                  EQU     $001C
DP_001E                                  EQU     $001E
DP_0020                                  EQU     $0020
DP_0021                                  EQU     $0021
DP_0022                                  EQU     $0022
DP_0023                                  EQU     $0023
DP_0025                                  EQU     $0025
DP_0027                                  EQU     $0027
DP_002A                                  EQU     $002A
DP_0030                                  EQU     $0030
DP_0031                                  EQU     $0031
DP_0032                                  EQU     $0032
DP_0033                                  EQU     $0033
DP_0034                                  EQU     $0034
DP_0037                                  EQU     $0037
DP_0038                                  EQU     $0038
DP_0039                                  EQU     $0039
DP_003A                                  EQU     $003A
DP_003B                                  EQU     $003B
DP_003C                                  EQU     $003C
DP_003D                                  EQU     $003D
DP_0041                                  EQU     $0041
DP_0045                                  EQU     $0045
DP_0047                                  EQU     $0047
DP_0048                                  EQU     $0048
DP_0049                                  EQU     $0049
DP_004A                                  EQU     $004A
DP_004B                                  EQU     $004B
DP_004C                                  EQU     $004C
DP_0052                                  EQU     $0052
DP_0053                                  EQU     $0053
DP_0054                                  EQU     $0054
DP_005D                                  EQU     $005D
DP_005E                                  EQU     $005E
DP_005F                                  EQU     $005F
DP_0060                                  EQU     $0060
DP_0061                                  EQU     $0061
DP_0062                                  EQU     $0062
DP_0064                                  EQU     $0064
DP_0066                                  EQU     $0066
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
DP_0075                                  EQU     $0075
DP_0076                                  EQU     $0076
DP_0077                                  EQU     $0077
DP_0079                                  EQU     $0079
DP_00C7                                  EQU     $00C7
DP_00FF                                  EQU     $00FF
GPIB_REG_0                               EQU     $2000
GPIB_REG_1                               EQU     $2001
GPIB_REG_2                               EQU     $2002
GPIB_REG_3                               EQU     $2003
INST_06_ATTENUATOR_AND_PULSE             EQU     $6006
INST_10_MODULATION_BCD_HIGH_MODE         EQU     $600A
MEM_0101                                 EQU     $0101
MEM_028F                                 EQU     $028F
MEM_03E7                                 EQU     $03E7
MEM_03E8                                 EQU     $03E8
MEM_07CF                                 EQU     $07CF
MEM_0800                                 EQU     $0800
MEM_0A00                                 EQU     $0A00
MEM_1999                                 EQU     $1999
MEM_260A                                 EQU     $260A
MEM_74FF                                 EQU     $74FF
PIA_CONTROL_A                            EQU     $4001
PIA_CONTROL_A_MIRROR                     EQU     $4005
PIA_CONTROL_B                            EQU     $4003
PIA_CONTROL_B_MIRROR                     EQU     $4007
PIA_PORT_A_OR_DDRA                       EQU     $4000
PIA_PORT_A_OR_DDRA_MIRROR                EQU     $4004
PIA_PORT_B_OR_DDRB                       EQU     $4002
RAM_8000                                 EQU     $8000
RAM_8002                                 EQU     $8002
RAM_8003                                 EQU     $8003
RAM_8004                                 EQU     $8004
RAM_8005                                 EQU     $8005
RAM_8006                                 EQU     $8006
RAM_8008                                 EQU     $8008
RAM_800A                                 EQU     $800A
RAM_800B                                 EQU     $800B
RAM_800E                                 EQU     $800E
RAM_800F                                 EQU     $800F
RAM_8010                                 EQU     $8010
RAM_8011                                 EQU     $8011
RAM_8012                                 EQU     $8012
RAM_8013                                 EQU     $8013
RAM_8014                                 EQU     $8014
RAM_8015                                 EQU     $8015
RAM_8016                                 EQU     $8016
RAM_8017                                 EQU     $8017
RAM_8018                                 EQU     $8018
RAM_8019                                 EQU     $8019
RAM_801A                                 EQU     $801A
RAM_801B                                 EQU     $801B
RAM_801C                                 EQU     $801C
RAM_801D                                 EQU     $801D
RAM_8020                                 EQU     $8020
RAM_8022                                 EQU     $8022
RAM_8023                                 EQU     $8023
RAM_8025                                 EQU     $8025
RAM_8029                                 EQU     $8029
RAM_802A                                 EQU     $802A
RAM_802B                                 EQU     $802B
RAM_802C                                 EQU     $802C
RAM_8030                                 EQU     $8030
RAM_8031                                 EQU     $8031
RAM_8032                                 EQU     $8032
RAM_8035                                 EQU     $8035
RAM_8036                                 EQU     $8036
RAM_8039                                 EQU     $8039
RAM_803A                                 EQU     $803A
RAM_803B                                 EQU     $803B
RAM_803C                                 EQU     $803C
RAM_803D                                 EQU     $803D
RAM_803E                                 EQU     $803E
RAM_803F                                 EQU     $803F
RAM_8040                                 EQU     $8040
RAM_8041                                 EQU     $8041
RAM_8043                                 EQU     $8043
RAM_8044                                 EQU     $8044
RAM_8047                                 EQU     $8047
RAM_8048                                 EQU     $8048
RAM_83FF                                 EQU     $83FF
RAM_8505                                 EQU     $8505
RAM_8506                                 EQU     $8506
RAM_850A                                 EQU     $850A
RAM_854A                                 EQU     $854A
RAM_8800                                 EQU     $8800
RAM_8C00                                 EQU     $8C00
RAM_MODE_FLAGS_PULSE_D1                  EQU     $8026
RAM_OPTION_PRESENCE_FLAGS                EQU     $800C
ROM_DATA_C21D                            EQU     $C21D
ROM_DATA_C253                            EQU     $C253
ROM_DATA_C25F                            EQU     $C25F
ROM_DATA_C26C                            EQU     $C26C
ROM_DATA_C29F                            EQU     $C29F
ROM_DATA_CC22                            EQU     $CC22
ROM_DATA_CC2C                            EQU     $CC2C
ROM_DATA_CC31                            EQU     $CC31
ROM_DATA_CC36                            EQU     $CC36
ROM_DATA_E8E8                            EQU     $E8E8
ROM_DATA_FF3F                            EQU     $FF3F
ROM_DATA_FFCA                            EQU     $FFCA
ROM_DATA_FFCD                            EQU     $FFCD
ROM_DATA_FFE0                            EQU     $FFE0
ROM_DATA_FFF4                            EQU     $FFF4
ROM_DATA_FFFB                            EQU     $FFFB
ROM_DATA_FFFF                            EQU     $FFFF
loc_E01A                                 EQU     $E01A
loc_E01D                                 EQU     $E01D
loc_E0B1                                 EQU     $E0B1
sub_E4E3                                 EQU     $E4E3
sub_EC08                                 EQU     $EC08
sub_ED73                                 EQU     $ED73
sub_EFEF                                 EQU     $EFEF
loc_F026                                 EQU     $F026

; ---------------------------------------------------------------------------
; DÉDUIT — table exponentielle de 251 mots 16 bits big-endian.
; Index : 0..250, très probablement un pas de 0,1 dB sur 0..25,0 dB.
; Valeur : arrondi d'environ 141 * 10^(index/200), de 141 à 2510.
; Cette loi est celle d'un rapport d'amplitude exprimé en décibels.
; Le consommateur exact et l'échelle 141 restent à confirmer; aucune unité
; supplémentaire n'est inventée. Le f9dasm d'origine prenait ces mots pour
; une longue suite d'opcodes 6802 désalignés.
; ---------------------------------------------------------------------------
table_exponential_0p1_db:
        FDB     $008D,$008F,$0090,$0092                 ; index 000..003 ; @ C000: 00 8D 00 8F 00 90 00 92
        FDB     $0094,$0095,$0097,$0099                 ; index 004..007 ; @ C008: 00 94 00 95 00 97 00 99
        FDB     $009B,$009C,$009E,$00A0                 ; index 008..011 ; @ C010: 00 9B 00 9C 00 9E 00 A0
        FDB     $00A2,$00A4,$00A6,$00A8                 ; index 012..015 ; @ C018: 00 A2 00 A4 00 A6 00 A8
        FDB     $00AA,$00AC,$00AE,$00B0                 ; index 016..019 ; @ C020: 00 AA 00 AC 00 AE 00 B0
        FDB     $00B2,$00B4,$00B6,$00B8                 ; index 020..023 ; @ C028: 00 B2 00 B4 00 B6 00 B8
        FDB     $00BA,$00BC,$00BE,$00C1                 ; index 024..027 ; @ C030: 00 BA 00 BC 00 BE 00 C1
        FDB     $00C3,$00C5,$00C7,$00CA                 ; index 028..031 ; @ C038: 00 C3 00 C5 00 C7 00 CA
        FDB     $00CC,$00CE,$00D1,$00D3                 ; index 032..035 ; @ C040: 00 CC 00 CE 00 D1 00 D3
        FDB     $00D6,$00D8,$00DB,$00DD                 ; index 036..039 ; @ C048: 00 D6 00 D8 00 DB 00 DD
        FDB     $00E0,$00E2,$00E5,$00E7                 ; index 040..043 ; @ C050: 00 E0 00 E2 00 E5 00 E7
        FDB     $00EA,$00ED,$00F0,$00F2                 ; index 044..047 ; @ C058: 00 EA 00 ED 00 F0 00 F2
        FDB     $00F5,$00F8,$00FB,$00FE                 ; index 048..051 ; @ C060: 00 F5 00 F8 00 FB 00 FE
        FDB     $0101,$0104,$0107,$010A                 ; index 052..055 ; @ C068: 01 01 01 04 01 07 01 0A
        FDB     $010D,$0110,$0113,$0116                 ; index 056..059 ; @ C070: 01 0D 01 10 01 13 01 16
        FDB     $011A,$011D,$0120,$0123                 ; index 060..063 ; @ C078: 01 1A 01 1D 01 20 01 23
        FDB     $0127,$012A,$012E,$0131                 ; index 064..067 ; @ C080: 01 27 01 2A 01 2E 01 31
        FDB     $0135,$0138,$013C,$0140                 ; index 068..071 ; @ C088: 01 35 01 38 01 3C 01 40
        FDB     $0143,$0147,$014B,$014F                 ; index 072..075 ; @ C090: 01 43 01 47 01 4B 01 4F
        FDB     $0152,$0156,$015A,$015E                 ; index 076..079 ; @ C098: 01 52 01 56 01 5A 01 5E
        FDB     $0162,$0166,$016B,$016F                 ; index 080..083 ; @ C0A0: 01 62 01 66 01 6B 01 6F
        FDB     $0173,$0177,$017C,$0180                 ; index 084..087 ; @ C0A8: 01 73 01 77 01 7C 01 80
        FDB     $0185,$0189,$018E,$0192                 ; index 088..091 ; @ C0B0: 01 85 01 89 01 8E 01 92
        FDB     $0197,$019C,$01A0,$01A5                 ; index 092..095 ; @ C0B8: 01 97 01 9C 01 A0 01 A5
        FDB     $01AA,$01AF,$01B4,$01B9                 ; index 096..099 ; @ C0C0: 01 AA 01 AF 01 B4 01 B9
        FDB     $01BE,$01C3,$01C9,$01CE                 ; index 100..103 ; @ C0C8: 01 BE 01 C3 01 C9 01 CE
        FDB     $01D3,$01D9,$01DE,$01E4                 ; index 104..107 ; @ C0D0: 01 D3 01 D9 01 DE 01 E4
        FDB     $01E9,$01EF,$01F5,$01FA                 ; index 108..111 ; @ C0D8: 01 E9 01 EF 01 F5 01 FA
        FDB     $0200,$0206,$020C,$0212                 ; index 112..115 ; @ C0E0: 02 00 02 06 02 0C 02 12
        FDB     $0218,$021F,$0225,$022B                 ; index 116..119 ; @ C0E8: 02 18 02 1F 02 25 02 2B
        FDB     $0232,$0238,$023F,$0245                 ; index 120..123 ; @ C0F0: 02 32 02 38 02 3F 02 45
        FDB     $024C,$0253,$025A,$0261                 ; index 124..127 ; @ C0F8: 02 4C 02 53 02 5A 02 61
        FDB     $0268,$026F,$0276,$027E                 ; index 128..131 ; @ C100: 02 68 02 6F 02 76 02 7E
        FDB     $0285,$028C,$0294,$029C                 ; index 132..135 ; @ C108: 02 85 02 8C 02 94 02 9C
        FDB     $02A3,$02AB,$02B3,$02BB                 ; index 136..139 ; @ C110: 02 A3 02 AB 02 B3 02 BB
        FDB     $02C3,$02CB,$02D4,$02DC                 ; index 140..143 ; @ C118: 02 C3 02 CB 02 D4 02 DC
        FDB     $02E4,$02ED,$02F6,$02FE                 ; index 144..147 ; @ C120: 02 E4 02 ED 02 F6 02 FE
        FDB     $0307,$0310,$0319,$0323                 ; index 148..151 ; @ C128: 03 07 03 10 03 19 03 23
        FDB     $032C,$0335,$033F,$0348                 ; index 152..155 ; @ C130: 03 2C 03 35 03 3F 03 48
        FDB     $0352,$035C,$0366,$0370                 ; index 156..159 ; @ C138: 03 52 03 5C 03 66 03 70
        FDB     $037A,$0385,$038F,$0399                 ; index 160..163 ; @ C140: 03 7A 03 85 03 8F 03 99
        FDB     $03A4,$03AF,$03BA,$03C5                 ; index 164..167 ; @ C148: 03 A4 03 AF 03 BA 03 C5
        FDB     $03D0,$03DB,$03E7,$03F2                 ; index 168..171 ; @ C150: 03 D0 03 DB 03 E7 03 F2
        FDB     $03FE,$040A,$0416,$0422                 ; index 172..175 ; @ C158: 03 FE 04 0A 04 16 04 22
        FDB     $042E,$043B,$0447,$0454                 ; index 176..179 ; @ C160: 04 2E 04 3B 04 47 04 54
        FDB     $0461,$046E,$047B,$0488                 ; index 180..183 ; @ C168: 04 61 04 6E 04 7B 04 88
        FDB     $0496,$04A3,$04B1,$04BF                 ; index 184..187 ; @ C170: 04 96 04 A3 04 B1 04 BF
        FDB     $04CD,$04DB,$04E9,$04F8                 ; index 188..191 ; @ C178: 04 CD 04 DB 04 E9 04 F8
        FDB     $0507,$0516,$0525,$0534                 ; index 192..195 ; @ C180: 05 07 05 16 05 25 05 34
        FDB     $0543,$0553,$0563,$0573                 ; index 196..199 ; @ C188: 05 43 05 53 05 63 05 73
        FDB     $0583,$0593,$05A4,$05B4                 ; index 200..203 ; @ C190: 05 83 05 93 05 A4 05 B4
        FDB     $05C5,$05D6,$05E8,$05F9                 ; index 204..207 ; @ C198: 05 C5 05 D6 05 E8 05 F9
        FDB     $060B,$061D,$062F,$0641                 ; index 208..211 ; @ C1A0: 06 0B 06 1D 06 2F 06 41
        FDB     $0654,$0667,$067A,$068D                 ; index 212..215 ; @ C1A8: 06 54 06 67 06 7A 06 8D
        FDB     $06A0,$06B4,$06C8,$06DC                 ; index 216..219 ; @ C1B0: 06 A0 06 B4 06 C8 06 DC
        FDB     $06F0,$0705,$071A,$072F                 ; index 220..223 ; @ C1B8: 06 F0 07 05 07 1A 07 2F
        FDB     $0744,$0759,$076F,$0785                 ; index 224..227 ; @ C1C0: 07 44 07 59 07 6F 07 85
        FDB     $079C,$07B2,$07C9,$07E4                 ; index 228..231 ; @ C1C8: 07 9C 07 B2 07 C9 07 E4
        FDB     $07F8,$080C,$082A,$083E                 ; index 232..235 ; @ C1D0: 07 F8 08 0C 08 2A 08 3E
        FDB     $085C,$0870,$088E,$08A2                 ; index 236..239 ; @ C1D8: 08 5C 08 70 08 8E 08 A2
        FDB     $08C0,$08D4,$08F2,$0906                 ; index 240..243 ; @ C1E0: 08 C0 08 D4 08 F2 09 06
        FDB     $0924,$0942,$0960,$0974                 ; index 244..247 ; @ C1E8: 09 24 09 42 09 60 09 74
        FDB     $0992,$09B0,$09CE                       ; index 248..250 ; @ C1F0: 09 92 09 B0 09 CE

; ---------------------------------------------------------------------------
; CONFIRMÉ — table des relais de l'atténuateur, indexée par un compteur BCD.
; Un index valide représente le nombre de pas mécaniques de 5 dB :
; $00..$09, $10..$19 puis $20..$27. Les six positions $0A..$0F et
; $1A..$1F sont des trous BCD à zéro, et non du code 6802.
; Les valeurs utiles D5..D0 correspondent à la table documentée dans
; BUS_INSTRUMENTS_NIVEAU_RF.md; D7/D6 sont fusionnés séparément.
; ---------------------------------------------------------------------------
attenuator_relay_table_bcd:
        FCB     $3F,$37,$3B,$33,$3D,$35,$39,$31         ; indices BCD $00..$07 ; @ C1F6: 3F 37 3B 33 3D 35 39 31
        FCB     $2D,$25,$00,$00,$00,$00,$00,$00         ; indices BCD $08..$0F ; @ C1FE: 2D 25 00 00 00 00 00 00
        FCB     $29,$21,$38,$30,$2C,$24,$28,$20         ; indices BCD $10..$17 ; @ C206: 29 21 38 30 2C 24 28 20
        FCB     $19,$11,$00,$00,$00,$00,$00,$00         ; indices BCD $18..$1F ; @ C20E: 19 11 00 00 00 00 00 00
        FCB     $0D,$05,$09,$01,$18,$10,$0C,$04         ; indices BCD $20..$27 ; @ C216: 0D 05 09 01 18 10 0C 04
        FCB     $70,$00,$00,$00,$67,$FF,$01,$06         ; données 'p...g...' ; @ C21E: 70 00 00 00 67 FF 01 06
        FCB     $00,$00,$0C,$80,$00,$00,$04,$80         ; données '........' ; @ C226: 00 00 0C 80 00 00 04 80
        FCB     $00,$80,$87,$FF,$00,$00,$00,$00         ; données '........' ; @ C22E: 00 80 87 FF 00 00 00 00
        FCB     $00,$00,$7C,$0A,$84,$00,$84,$00         ; données '..|.....' ; @ C236: 00 00 7C 0A 84 00 84 00
        FCB     $00,$86,$EF,$00,$00,$00,$00,$8C         ; données '........' ; @ C23E: 00 86 EF 00 00 00 00 8C
        FCB     $00,$23,$00,$00,$00,$00,$00,$00         ; données '.#......' ; @ C246: 00 23 00 00 00 00 00 00
        FCB     $88,$00,$00,$00,$00,$00,$DD,$80         ; données '........' ; @ C24E: 88 00 00 00 00 00 DD 80
        FCB     $C2,$9E,$DD,$CD,$C2,$9E,$DE,$31         ; données '.......1' ; @ C256: C2 9E DD CD C2 9E DE 31
        FCB     $DE,$79,$CF,$79,$C2,$9E,$CF,$E9         ; données '.y.y....' ; @ C25E: DE 79 CF 79 C2 9E CF E9
        FCB     $C2,$9E,$D1,$C8,$D1,$04,$D8,$97         ; données '........' ; @ C266: C2 9E D1 C8 D1 04 D8 97
        FCB     $C2,$9E,$D9,$62,$C2,$9E,$D9,$29         ; données '...b...)' ; @ C26E: C2 9E D9 62 C2 9E D9 29
        FCB     $D8,$E7,$D8,$A9,$C2,$9E,$D9,$4B         ; données '.......K' ; @ C276: D8 E7 D8 A9 C2 9E D9 4B
        FCB     $C2,$9E,$D9,$26,$D8,$DD,$D8,$DD         ; données '...&....' ; @ C27E: C2 9E D9 26 D8 DD D8 DD
        FCB     $E7,$18,$E6,$FD,$E6,$FE,$E7,$13         ; données '........' ; @ C286: E7 18 E6 FD E6 FE E7 13
        FCB     $E6,$77,$E6,$75,$E6,$76,$E6,$DB         ; données '.w.u.v..' ; @ C28E: E6 77 E6 75 E6 76 E6 DB
        FCB     $C2,$9E,$E7,$41,$E7,$4B,$E7,$55         ; données '...A.K.U' ; @ C296: C2 9E E7 41 E7 4B E7 55
        FCB     $39,$00,$1A,$14,$19,$1E,$3B,$26         ; données '9.....;&' ; @ C29E: 39 00 1A 14 19 1E 3B 26
        FCB     $29,$05,$24,$13,$18,$1F,$3F,$27         ; données ').$...?'' ; @ C2A6: 29 05 24 13 18 1F 3F 27
        FCB     $28,$06,$20,$12,$17,$1D,$3E,$2A         ; données '(. ...>*' ; @ C2AE: 28 06 20 12 17 1D 3E 2A
        FCB     $0E,$07,$21,$11,$16,$1C,$3D,$22         ; données '..!...="' ; @ C2B6: 0E 07 21 11 16 1C 3D 22
        FCB     $0B,$01,$0F,$10,$15,$1B,$3C,$2B         ; données '......<+' ; @ C2BE: 0B 01 0F 10 15 1B 3C 2B
        FCB     $0D,$03,$00,$00,$00,$00,$00,$00         ; données '........' ; @ C2C6: 0D 03 00 00 00 00 00 00
        FCB     $2E                                     ; données '.' ; @ C2CE: 2E

; ---------------------------------------------------------------------------
; ROUTINE $C2CF — sub_restore_stack_and_copy
; DÉDUIT — restauration temporaire de pile et copie avec somme de contrôle.
; Entrées : X et B sont préparés par l'appelant C42C; la RAM directe $005E..$0061 décrit la copie.
; Sorties : A reflète la somme/état calculé; la destination pointée est mise à jour.
; Registres/flags : pile S remplacée provisoirement, A/B/X et indicateurs modifiés.
; RAM/E/S : pile sauvegardée en RAM $8000; aucune écriture directe sur le bus instruments.
; Algorithme : bascule sur une pile de travail, dépile les octets, les copie et accumule leur somme.
; ---------------------------------------------------------------------------
sub_restore_stack_and_copy:
        SEI                                             ; masque les IRQ pendant la section critique ; @ C2CF: 0F
        STS     RAM_8000                                ; @ C2D0: BF 80 00
        LDS     DP_005E                                 ; @ C2D3: 9E 5E
        DES                                             ; @ C2D5: 34
        CLR     >DP_0060                                ; @ C2D6: 7F 00 60
loc_C2D9:
        PULA                                            ; @ C2D9: 32
        STAA    ,X                                      ; @ C2DA: A7 00
        ADDA    DP_0060                                 ; @ C2DC: 9B 60
        STAA    DP_0060                                 ; @ C2DE: 97 60
        INX                                             ; @ C2E0: 08
        DECB                                            ; @ C2E1: 5A
        BGT     loc_C2D9                                ; branche vers loc_C2D9 si la condition GT est vraie ; @ C2E2: 2E F5
        LDX     #DP_0061                                ; @ C2E4: CE 00 61
        TSTB                                            ; @ C2E7: 5D
        BEQ     loc_C2D9                                ; branche vers loc_C2D9 si la condition EQ est vraie ; @ C2E8: 27 EF
        LDAA    DP_0060                                 ; @ C2EA: 96 60
        SUBA    #$55                                    ; @ C2EC: 80 55
        LDX     DP_001E                                 ; @ C2EE: DE 1E
        BNE     loc_C2F7                                ; branche vers loc_C2F7 si la condition NE est vraie ; @ C2F0: 26 05
        LDX     RAM_800A                                ; @ C2F2: FE 80 0A
        STX     DP_001E                                 ; @ C2F5: DF 1E
loc_C2F7:
        LDS     RAM_8000                                ; @ C2F7: BE 80 00
        CLI                                             ; autorise à nouveau les IRQ ; @ C2FA: 0E
        RTS                                             ; @ C2FB: 39

; ---------------------------------------------------------------------------
; ROUTINE $C2FC — sub_C2FC
; INCONNU — sous-routine interne à $C2FC; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C425, $C5FB. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_C2FC:
        LDAA    PIA_PORT_A_OR_DDRA_MIRROR               ; accès au PIA 6821 du panneau avant ; @ C2FC: B6 40 04
        EORA    #$3F                                    ; @ C2FF: 88 3F
        TAB                                             ; @ C301: 16
        ANDB    #$1F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C302: C4 1F
        STAB    PIA_PORT_A_OR_DDRA_MIRROR               ; accès au PIA 6821 du panneau avant ; @ C304: F7 40 04
        TAB                                             ; @ C307: 16
        ANDB    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C308: C4 C0
        STAB    RAM_OPTION_PRESENCE_FLAGS               ; @ C30A: F7 80 0C
        LDAB    DP_003C                                 ; @ C30D: D6 3C
        ORAB    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C30F: CA 20
        ANDA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C311: 84 20
        BEQ     loc_C317                                ; branche vers loc_C317 si la condition EQ est vraie ; @ C313: 27 02
        ANDB    #$DF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C315: C4 DF
loc_C317:
        STAB    DP_003C                                 ; @ C317: D7 3C
        STAA    PIA_PORT_B_OR_DDRB                      ; accès au PIA 6821 du panneau avant ; @ C319: B7 40 02
        LDAB    GPIB_REG_3                              ; accès à l'interface distante IEEE-488 ; @ C31C: F6 20 03
        BPL     loc_C324                                ; branche vers loc_C324 si la condition PL est vraie ; @ C31F: 2A 03
        STAB    MEM_0800                                ; @ C321: F7 08 00
loc_C324:
        LDAA    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ C324: B6 20 02
        ANDA    #$30                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C327: 84 30
        LDAB    RAM_OPTION_PRESENCE_FLAGS               ; @ C329: F6 80 0C
        ANDB    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C32C: C4 C0
        ABA                                             ; @ C32E: 1B
        STAA    RAM_OPTION_PRESENCE_FLAGS               ; @ C32F: B7 80 0C
        RTS                                             ; @ C332: 39
        FCB     $CE,$CC,$9F,$FF,$FF,$F8,$CE,$E1         ; données '........' ; @ C333: CE CC 9F FF FF F8 CE E1
        FCB     $DE,$FF,$FF,$FC                         ; données '....' ; @ C33B: DE FF FF FC

; ---------------------------------------------------------------------------
; ROUTINE $C33F — reset_entry
; CONFIRMÉ — point d'entrée RESET du 6802.
; Entrées : aucune; interruptions masquées dès la première instruction.
; Sorties : PIA, interface distante, images RAM et état initial du bus instruments initialisés.
; Registres/flags : A, B, X, S et CCR modifiés; l'exécution rejoint ensuite la boucle principale.
; RAM/E/S : PIA $4000, GPIB $2000, bus instruments $6000..$600F et RAM $8000/$8500.
; Algorithme : impose d'abord un état RF sûr (adresse 6 à zéro), initialise les périphériques, les sentinelles et les images de configuration.
; ---------------------------------------------------------------------------
reset_entry:
        SEI                                             ; masque les IRQ pendant la section critique ; @ C33F: 0F
        CLRA                                            ; @ C340: 4F
        STAA    PIA_CONTROL_B                           ; accès au PIA 6821 du panneau avant ; @ C341: B7 40 03
loc_C344:
        LDAA    #$40                                    ; @ C344: 86 40
        STAA    INST_10_MODULATION_BCD_HIGH_MODE        ; émet l'adresse instrument 10 (modulation bcd high mode) ; @ C346: B7 60 0A
        LDAA    #$55                                    ; @ C349: 86 55
        STAA    RAM_8041                                ; @ C34B: B7 80 41
        CLRA                                            ; @ C34E: 4F
        STAA    INST_06_ATTENUATOR_AND_PULSE            ; émet l'adresse instrument 6 (attenuator and pulse) ; @ C34F: B7 60 06
        STAA    DP_0066                                 ; @ C352: 97 66
        STAA    RAM_8044                                ; @ C354: B7 80 44
        STAA    RAM_8047                                ; @ C357: B7 80 47
        STAA    RAM_8506                                ; @ C35A: B7 85 06
        STAA    RAM_8048                                ; @ C35D: B7 80 48
        LDAA    #$38                                    ; @ C360: 86 38
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C362: B7 20 01
        LDAA    #$09                                    ; @ C365: 86 09
        STAA    GPIB_REG_3                              ; accès à l'interface distante IEEE-488 ; @ C367: B7 20 03
        CLRB                                            ; @ C36A: 5F
        STAB    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C36B: F7 20 00
        ORAB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C36E: CA 0F
        STAB    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ C370: F7 20 02
        COMB                                            ; @ C373: 53
        STAB    RAM_MODE_FLAGS_PULSE_D1                 ; @ C374: F7 80 26
        STAB    RAM_800F                                ; @ C377: F7 80 0F
        ORAA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C37A: 8A 04
        STAA    GPIB_REG_3                              ; accès à l'interface distante IEEE-488 ; @ C37C: B7 20 03
        LDAA    #$05                                    ; @ C37F: 86 05
        STAA    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ C381: B7 20 02
        LDAA    #$34                                    ; @ C384: 86 34
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C386: B7 20 01
        LDAA    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ C389: B6 20 02
        LDAA    #$3C                                    ; @ C38C: 86 3C
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C38E: B7 20 01
        LDAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C391: B6 20 00
        LDAA    #$07                                    ; @ C394: 86 07
        STAA    DP_003D                                 ; @ C396: 97 3D
        LDX     #MEM_260A                               ; @ C398: CE 26 0A
        STX     RAM_8019                                ; @ C39B: FF 80 19
        LDX     #MEM_74FF                               ; @ C39E: CE 74 FF
        STX     RAM_801B                                ; @ C3A1: FF 80 1B
        LDX     #ROM_DATA_FFFF                          ; @ C3A4: CE FF FF
        STX     RAM_8010                                ; @ C3A7: FF 80 10
        STX     RAM_8011                                ; @ C3AA: FF 80 11
        STX     RAM_8015                                ; @ C3AD: FF 80 15
        LDAA    #$F2                                    ; @ C3B0: 86 F2
        STAA    RAM_801D                                ; @ C3B2: B7 80 1D
        LDX     #ROM_DATA_FF3F                          ; @ C3B5: CE FF 3F
        STX     RAM_8017                                ; @ C3B8: FF 80 17
        CLRA                                            ; @ C3BB: 4F
        STAA    RAM_8044                                ; @ C3BC: B7 80 44
        STAA    DP_0038                                 ; @ C3BF: 97 38
        LDAA    #$70                                    ; @ C3C1: 86 70
        STAA    DP_0037                                 ; @ C3C3: 97 37
        LDS     #RAM_83FF                               ; @ C3C5: 8E 83 FF
        JSR     sub_C687                                ; appelle sub_C687 ; @ C3C8: BD C6 87
        LDAA    #$03                                    ; @ C3CB: 86 03
loc_C3CD:
        LDX     #ROM_DATA_FFFF                          ; @ C3CD: CE FF FF
loc_C3D0:
        DEX                                             ; @ C3D0: 09
        BNE     loc_C3D0                                ; branche vers loc_C3D0 si la condition NE est vraie ; @ C3D1: 26 FD
        DECA                                            ; @ C3D3: 4A
        BNE     loc_C3CD                                ; branche vers loc_C3CD si la condition NE est vraie ; @ C3D4: 26 F7
        SEI                                             ; masque les IRQ pendant la section critique ; @ C3D6: 0F
        LDS     #ROM_DATA_C21D                          ; @ C3D7: 8E C2 1D
        LDX     #ROM_DATA_FFCA                          ; @ C3DA: CE FF CA
loc_C3DD:
        PULA                                            ; @ C3DD: 32
        CPX     #ROM_DATA_FFCD                          ; @ C3DE: 8C FF CD
        BNE     loc_C3F0                                ; branche vers loc_C3F0 si la condition NE est vraie ; @ C3E1: 26 0D
        LDAB    DP_003A                                 ; @ C3E3: D6 3A
        ANDB    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C3E5: C4 10
        BEQ     loc_C3F0                                ; branche vers loc_C3F0 si la condition EQ est vraie ; @ C3E7: 27 07
        STAB    DP_003A                                 ; @ C3E9: D7 3A
        STAB    PIA_CONTROL_A_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ C3EB: F7 40 05
        BRA     loc_C3F2                                ; branche toujours vers loc_C3F2 ; @ C3EE: 20 02
loc_C3F0:
        STAA    $6D,X                                   ; @ C3F0: A7 6D
loc_C3F2:
        INX                                             ; @ C3F2: 08
        BNE     loc_C3DD                                ; branche vers loc_C3DD si la condition NE est vraie ; @ C3F3: 26 E8
        LDS     #RAM_83FF                               ; @ C3F5: 8E 83 FF
        CLI                                             ; autorise à nouveau les IRQ ; @ C3F8: 0E
        LDAA    #$99                                    ; @ C3F9: 86 99
        STAA    RAM_8043                                ; @ C3FB: B7 80 43
        CLRA                                            ; @ C3FE: 4F
        STAA    DP_0031                                 ; @ C3FF: 97 31
        LDAA    #$20                                    ; @ C401: 86 20
        STAA    PIA_CONTROL_B_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ C403: B7 40 07
        LDAA    #$10                                    ; @ C406: 86 10
        STAA    DP_0030                                 ; @ C408: 97 30
        STAA    RAM_8008                                ; @ C40A: B7 80 08
        LDAA    #$FD                                    ; @ C40D: 86 FD
        STAA    RAM_8023                                ; @ C40F: B7 80 23
        LDAA    #$FF                                    ; @ C412: 86 FF
        STAA    DP_002A                                 ; @ C414: 97 2A
        STAA    DP_0034                                 ; @ C416: 97 34
        STAA    RAM_800A                                ; @ C418: B7 80 0A
        STAA    RAM_800B                                ; @ C41B: B7 80 0B
        STAA    RAM_8022                                ; @ C41E: B7 80 22
        LDAA    #$70                                    ; @ C421: 86 70
        STAA    DP_0022                                 ; @ C423: 97 22
        JSR     sub_C2FC                                ; appelle sub_C2FC ; @ C425: BD C2 FC
loc_C428:
        LDAB    DP_0060                                 ; @ C428: D6 60
        LDX     DP_0061                                 ; @ C42A: DE 61
        JSR     sub_restore_stack_and_copy              ; appelle sub_restore_stack_and_copy ; @ C42C: BD C2 CF
        TSTA                                            ; @ C42F: 4D
        BNE     loc_C43D                                ; branche vers loc_C43D si la condition NE est vraie ; @ C430: 26 0B
        LDAA    DP_005D                                 ; @ C432: 96 5D
        BNE     loc_C43B                                ; branche vers loc_C43B si la condition NE est vraie ; @ C434: 26 05
        LDX     DP_001E                                 ; @ C436: DE 1E
        STX     RAM_800A                                ; @ C438: FF 80 0A
loc_C43B:
        BRA     loc_C47F                                ; branche toujours vers loc_C47F ; @ C43B: 20 42
loc_C43D:
        LDAA    #$FB                                    ; @ C43D: 86 FB
        STAA    RAM_8019                                ; @ C43F: B7 80 19
        CLRA                                            ; @ C442: 4F
        TST     >DP_003A                                ; @ C443: 7D 00 3A
        BNE     loc_C44B                                ; branche vers loc_C44B si la condition NE est vraie ; @ C446: 26 03
        JSR     sub_CAFC                                ; appelle sub_CAFC ; @ C448: BD CA FC
loc_C44B:
        JSR     sub_C687                                ; appelle sub_C687 ; @ C44B: BD C6 87
        LDAA    DP_005D                                 ; @ C44E: 96 5D
        BEQ     loc_C455                                ; branche vers loc_C455 si la condition EQ est vraie ; @ C450: 27 03
        JMP     loc_D396                                ; transfert sans retour vers loc_D396 ; @ C452: 7E D3 96
loc_C455:
        LDAA    #$4E                                    ; @ C455: 86 4E
        STAA    DP_003B                                 ; @ C457: 97 3B
        CLRA                                            ; @ C459: 4F
        LDX     #ROM_DATA_FFE0                          ; @ C45A: CE FF E0
loc_C45D:
        STAA    $20,X                                   ; @ C45D: A7 20
        INX                                             ; @ C45F: 08
        BNE     loc_C45D                                ; branche vers loc_C45D si la condition NE est vraie ; @ C460: 26 FB
        LDX     #MEM_0101                               ; @ C462: CE 01 01
        STX     DP_0016                                 ; @ C465: DF 16
        LDX     #ROM_DATA_E8E8                          ; @ C467: CE E8 E8
        STX     DP_0020                                 ; @ C46A: DF 20
        LDAA    #$F0                                    ; @ C46C: 86 F0
        STAA    DP_0022                                 ; @ C46E: 97 22
        LDX     #ROM_DATA_FFFF                          ; @ C470: CE FF FF
        STX     RAM_800A                                ; @ C473: FF 80 0A
        LDX     #RAM_8000                               ; @ C476: CE 80 00
        STX     DP_0007                                 ; @ C479: DF 07
        LDAA    #$03                                    ; @ C47B: 86 03
        STAA    DP_0013                                 ; @ C47D: 97 13
loc_C47F:
        JSR     sub_C687                                ; appelle sub_C687 ; @ C47F: BD C6 87
        LDAA    DP_005D                                 ; @ C482: 96 5D
        BNE     loc_C48E                                ; branche vers loc_C48E si la condition NE est vraie ; @ C484: 26 08
        LDAA    #$4E                                    ; @ C486: 86 4E
        STAA    DP_003B                                 ; @ C488: 97 3B
        LDAA    #$FF                                    ; @ C48A: 86 FF
        STAA    DP_0049                                 ; @ C48C: 97 49
loc_C48E:
        LDAB    DP_001A                                 ; @ C48E: D6 1A
        TBA                                             ; @ C490: 17
        LSRB                                            ; @ C491: 54
        ANDB    #$0E                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C492: C4 0E
        STAB    DP_004C                                 ; @ C494: D7 4C
        ANDA    #$E3                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C496: 84 E3
        STAA    DP_001A                                 ; @ C498: 97 1A
        LDX     #ROM_DATA_FFF4                          ; @ C49A: CE FF F4
loc_C49D:
        CLRB                                            ; @ C49D: 5F
        ASL     >DP_001A                                ; @ C49E: 78 00 1A
        BCS     loc_C4A5                                ; branche vers loc_C4A5 si la condition CS est vraie ; @ C4A1: 25 02
        ORAB    #$46                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C4A3: CA 46
loc_C4A5:
        LDAA    $49,X                                   ; @ C4A5: A6 49
        ANDA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C4A7: 84 08
        ABA                                             ; @ C4A9: 1B
        STAA    $49,X                                   ; @ C4AA: A7 49
        INX                                             ; @ C4AC: 08
        INX                                             ; @ C4AD: 08
        LDAA    $49,X                                   ; @ C4AE: A6 49
        ANDA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C4B0: 84 08
        EORB    #$46                                    ; @ C4B2: C8 46
        ABA                                             ; @ C4B4: 1B
        STAA    $49,X                                   ; @ C4B5: A7 49
        INX                                             ; @ C4B7: 08
        INX                                             ; @ C4B8: 08
        BNE     loc_C49D                                ; branche vers loc_C49D si la condition NE est vraie ; @ C4B9: 26 E2
        LSR     >DP_001A                                ; @ C4BB: 74 00 1A
        LSR     >DP_001A                                ; @ C4BE: 74 00 1A
        LSR     >DP_001A                                ; @ C4C1: 74 00 1A
        LDAA    DP_001A                                 ; @ C4C4: 96 1A
        ANDA    #$03                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C4C6: 84 03
        STAA    DP_001A                                 ; @ C4C8: 97 1A
        LDAA    #$53                                    ; @ C4CA: 86 53
        LDX     DP_004B                                 ; @ C4CC: DE 4B
        LDAB    DP_004C                                 ; @ C4CE: D6 4C
        LSRB                                            ; @ C4D0: 54
        CMPB    #$05                                    ; @ C4D1: C1 05
        BNE     loc_C4E1                                ; branche vers loc_C4E1 si la condition NE est vraie ; @ C4D3: 26 0C
        LDAB    DP_001C                                 ; @ C4D5: D6 1C
        ADDB    #$F0                                    ; @ C4D7: CB F0
        LDAB    #$06                                    ; @ C4D9: C6 06
        BCS     loc_C4EC                                ; branche vers loc_C4EC si la condition CS est vraie ; @ C4DB: 25 0F
        ORAA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C4DD: 8A 08
        BRA     loc_C4ED                                ; branche toujours vers loc_C4ED ; @ C4DF: 20 0C
loc_C4E1:
        BITB    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C4E1: C5 02
        BEQ     loc_C4EC                                ; branche vers loc_C4EC si la condition EQ est vraie ; @ C4E3: 27 07
        PSHB                                            ; @ C4E5: 37
        LDAB    $3D,X                                   ; @ C4E6: E6 3D
        ANDB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C4E8: C4 08
        ABA                                             ; @ C4EA: 1B
        PULB                                            ; @ C4EB: 33
loc_C4EC:
        INCB                                            ; @ C4EC: 5C
loc_C4ED:
        STAA    $3D,X                                   ; @ C4ED: A7 3D
        LDAA    #$FF                                    ; @ C4EF: 86 FF
        CLC                                             ; @ C4F1: 0C
loc_C4F2:
        ROLA                                            ; @ C4F2: 49
        DECB                                            ; @ C4F3: 5A
        BPL     loc_C4F2                                ; branche vers loc_C4F2 si la condition PL est vraie ; @ C4F4: 2A FC
        STAA    RAM_8023                                ; @ C4F6: B7 80 23
        LDAB    DP_004C                                 ; @ C4F9: D6 4C
        LDAA    #$0A                                    ; @ C4FB: 86 0A
        ANDB    #$0C                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C4FD: C4 0C
        BEQ     loc_C508                                ; branche vers loc_C508 si la condition EQ est vraie ; @ C4FF: 27 07
        LDAA    #$03                                    ; @ C501: 86 03
        BITA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C503: 85 08
        BNE     loc_C508                                ; branche vers loc_C508 si la condition NE est vraie ; @ C505: 26 01
        INCA                                            ; @ C507: 4C
loc_C508:
        STAA    DP_0052                                 ; @ C508: 97 52
        LDAA    DP_004A                                 ; @ C50A: 96 4A
        ANDA    #$DF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C50C: 84 DF
        LDAB    $3E,X                                   ; @ C50E: E6 3E
        BPL     loc_C514                                ; branche vers loc_C514 si la condition PL est vraie ; @ C510: 2A 02
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C512: 8A 20
loc_C514:
        STAA    DP_004A                                 ; @ C514: 97 4A
        CLRB                                            ; @ C516: 5F
loc_C517:
        LDAA    DP_003C                                 ; @ C517: 96 3C
        ANDA    #$BF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C519: 84 BF
        STAA    DP_003C                                 ; @ C51B: 97 3C
        STAA    RAM_8022                                ; @ C51D: B7 80 22
        BRA     loc_C556                                ; branche toujours vers loc_C556 ; @ C520: 20 34
loc_C522:
        CLRB                                            ; @ C522: 5F
        LDX     #DP_000C                                ; @ C523: CE 00 0C
loc_C526:
        LDAA    $3B,X                                   ; @ C526: A6 3B
        ANDA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C528: 84 07
        CMPA    #$07                                    ; @ C52A: 81 07
        BEQ     loc_C54D                                ; branche vers loc_C54D si la condition EQ est vraie ; @ C52C: 27 1F
        DEX                                             ; @ C52E: 09
        DEX                                             ; @ C52F: 09
        BNE     loc_C526                                ; branche vers loc_C526 si la condition NE est vraie ; @ C530: 26 F4
        LDX     #DP_000C                                ; @ C532: CE 00 0C
loc_C535:
        LDAA    $3B,X                                   ; @ C535: A6 3B
        ANDA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C537: 84 07
        CMPA    #$06                                    ; @ C539: 81 06
        BNE     loc_C53F                                ; branche vers loc_C53F si la condition NE est vraie ; @ C53B: 26 02
        EORA    #$05                                    ; @ C53D: 88 05
loc_C53F:
        CMPA    #$03                                    ; @ C53F: 81 03
        BEQ     loc_C517                                ; branche vers loc_C517 si la condition EQ est vraie ; @ C541: 27 D4
        CMPA    #$02                                    ; @ C543: 81 02
        BEQ     loc_C517                                ; branche vers loc_C517 si la condition EQ est vraie ; @ C545: 27 D0
        DEX                                             ; @ C547: 09
        DEX                                             ; @ C548: 09
        BNE     loc_C535                                ; branche vers loc_C535 si la condition NE est vraie ; @ C549: 26 EA
        LDAB    #$40                                    ; @ C54B: C6 40
loc_C54D:
        LDAA    #$40                                    ; @ C54D: 86 40
        ORAA    DP_003C                                 ; @ C54F: 9A 3C
        STAA    DP_003C                                 ; @ C551: 97 3C
        STAA    RAM_8022                                ; @ C553: B7 80 22
loc_C556:
        LDAA    #$BF                                    ; @ C556: 86 BF
        ANDA    DP_004A                                 ; @ C558: 94 4A
        ABA                                             ; @ C55A: 1B
        LDAB    DP_0049                                 ; @ C55B: D6 49
        INCB                                            ; @ C55D: 5C
        BNE     loc_C564                                ; branche vers loc_C564 si la condition NE est vraie ; @ C55E: 26 04
loc_C560:
        ORAA    #$9F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C560: 8A 9F
        STAB    DP_0049                                 ; @ C562: D7 49
loc_C564:
        STAA    DP_004A                                 ; @ C564: 97 4A
        STAA    RAM_8025                                ; @ C566: B7 80 25
        LDAB    DP_0049                                 ; @ C569: D6 49
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C56B: C4 0F
        CMPB    #$04                                    ; @ C56D: C1 04
        BGE     loc_C5A4                                ; branche vers loc_C5A4 si la condition GE est vraie ; @ C56F: 2C 33
        LDX     DP_004B                                 ; @ C571: DE 4B
        LDAA    $3E,X                                   ; @ C573: A6 3E
        ANDA    #$70                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C575: 84 70
        LDAB    DP_004C                                 ; @ C577: D6 4C
        LSRA                                            ; @ C579: 44
        LSRA                                            ; @ C57A: 44
        BEQ     loc_C57E                                ; branche vers loc_C57E si la condition EQ est vraie ; @ C57B: 27 01
        INCA                                            ; @ C57D: 4C
loc_C57E:
        CMPB    #$08                                    ; @ C57E: C1 08
        BEQ     loc_C584                                ; branche vers loc_C584 si la condition EQ est vraie ; @ C580: 27 02
        LSRA                                            ; @ C582: 44
        LSRA                                            ; @ C583: 44
loc_C584:
        ASLB                                            ; @ C584: 58
        ASLB                                            ; @ C585: 58
        ASLB                                            ; @ C586: 58
        ABA                                             ; @ C587: 1B
        ADDA    #$20                                    ; @ C588: 8B 20
        BITA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C58A: 85 07
        BNE     loc_C592                                ; branche vers loc_C592 si la condition NE est vraie ; @ C58C: 26 04
        LDAA    #$FF                                    ; @ C58E: 86 FF
        ORAB    #$1F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C590: CA 1F
loc_C592:
        STAA    DP_005D                                 ; @ C592: 97 5D
        LDAB    DP_0038                                 ; @ C594: D6 38
        ANDB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C596: C4 04
        SUBB    #$04                                    ; @ C598: C0 04
        LDAB    DP_003C                                 ; @ C59A: D6 3C
        BCC     loc_C5A4                                ; branche vers loc_C5A4 si la condition CC est vraie ; @ C59C: 24 06
        STAA    RAM_8020                                ; @ C59E: B7 80 20
        STAB    RAM_8022                                ; @ C5A1: F7 80 22
loc_C5A4:
        LDS     #RAM_83FF                               ; @ C5A4: 8E 83 FF
loc_C5A7:
        SEI                                             ; masque les IRQ pendant la section critique ; @ C5A7: 0F
        LDAA    PIA_CONTROL_A                           ; accès au PIA 6821 du panneau avant ; @ C5A8: B6 40 01
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C5AB: 85 02
        BEQ     loc_C5C0                                ; branche vers loc_C5C0 si la condition EQ est vraie ; @ C5AD: 27 11
        LDAA    DP_003A                                 ; @ C5AF: 96 3A
        BITA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C5B1: 85 10
        BEQ     loc_C5BB                                ; branche vers loc_C5BB si la condition EQ est vraie ; @ C5B3: 27 06
        LDAA    DP_003C                                 ; @ C5B5: 96 3C
        EORA    #$80                                    ; @ C5B7: 88 80
        STAA    DP_003C                                 ; @ C5B9: 97 3C
loc_C5BB:
        LDAA    #$10                                    ; @ C5BB: 86 10
        STAA    PIA_CONTROL_B                           ; accès au PIA 6821 du panneau avant ; @ C5BD: B7 40 03
loc_C5C0:
        LDAA    DP_0037                                 ; @ C5C0: 96 37
        BITA    #$70                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C5C2: 85 70
        BNE     loc_C5D0                                ; branche vers loc_C5D0 si la condition NE est vraie ; @ C5C4: 26 0A
        TST     >DP_0038                                ; @ C5C6: 7D 00 38
        BNE     loc_C5D0                                ; branche vers loc_C5D0 si la condition NE est vraie ; @ C5C9: 26 05
        CLR     >DP_0037                                ; @ C5CB: 7F 00 37
        BRA     loc_C5DB                                ; branche toujours vers loc_C5DB ; @ C5CE: 20 0B
loc_C5D0:
        BITA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C5D0: 85 0F
        BNE     loc_C5DB                                ; branche vers loc_C5DB si la condition NE est vraie ; @ C5D2: 26 07
        ADDA    #$02                                    ; @ C5D4: 8B 02
        STAA    DP_0037                                 ; @ C5D6: 97 37
        STAA    MEM_0800                                ; @ C5D8: B7 08 00
loc_C5DB:
        LDAB    DP_0037                                 ; @ C5DB: D6 37
        BMI     loc_C60C                                ; branche vers loc_C60C si la condition MI est vraie ; @ C5DD: 2B 2D
        LDAA    DP_003B                                 ; @ C5DF: 96 3B
        BITA    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C5E1: 85 C0
        BNE     loc_C61A                                ; branche vers loc_C61A si la condition NE est vraie ; @ C5E3: 26 35
        LDAA    DP_0039                                 ; @ C5E5: 96 39
        BNE     loc_C62A                                ; branche vers loc_C62A si la condition NE est vraie ; @ C5E7: 26 41
        LDAA    DP_003D                                 ; @ C5E9: 96 3D
        ORAA    DP_0041                                 ; @ C5EB: 9A 41
        ORAA    DP_0045                                 ; @ C5ED: 9A 45
        ORAA    DP_0047                                 ; @ C5EF: 9A 47
        BMI     loc_C630                                ; branche vers loc_C630 si la condition MI est vraie ; @ C5F1: 2B 3D
        ASLA                                            ; @ C5F3: 48
        BMI     loc_C65D                                ; branche vers loc_C65D si la condition MI est vraie ; @ C5F4: 2B 67
        LDAA    #$E7                                    ; @ C5F6: 86 E7
        STAA    PIA_PORT_A_OR_DDRA                      ; accès au PIA 6821 du panneau avant ; @ C5F8: B7 40 00
        JSR     sub_C2FC                                ; appelle sub_C2FC ; @ C5FB: BD C2 FC
        LDAA    DP_006B                                 ; @ C5FE: 96 6B
        BMI     loc_C680                                ; branche vers loc_C680 si la condition MI est vraie ; @ C600: 2B 7E
        LDAA    #$AA                                    ; @ C602: 86 AA
        STAA    RAM_8041                                ; @ C604: B7 80 41
        NOP                                             ; @ C607: 01
        CLI                                             ; autorise à nouveau les IRQ ; @ C608: 0E
        WAI                                             ; @ C609: 3E
        FCB     $20,$9B                                 ; données ' .' ; @ C60A: 20 9B
loc_C60C:
        LDAA    DP_003D                                 ; @ C60C: 96 3D
        ORAA    DP_0041                                 ; @ C60E: 9A 41
        ORAA    DP_0045                                 ; @ C610: 9A 45
        ORAA    DP_0047                                 ; @ C612: 9A 47
        ASLA                                            ; @ C614: 48
        BPL     loc_C674                                ; branche vers loc_C674 si la condition PL est vraie ; @ C615: 2A 5D
        JMP     loc_C65D                                ; transfert sans retour vers loc_C65D ; @ C617: 7E C6 5D
loc_C61A:
        CLI                                             ; autorise à nouveau les IRQ ; @ C61A: 0E
        TAB                                             ; @ C61B: 16
        BPL     loc_C624                                ; branche vers loc_C624 si la condition PL est vraie ; @ C61C: 2A 06
        JSR     sub_DA5B                                ; appelle sub_DA5B ; @ C61E: BD DA 5B
        JMP     loc_C5A7                                ; transfert sans retour vers loc_C5A7 ; @ C621: 7E C5 A7
loc_C624:
        JSR     sub_D319                                ; appelle sub_D319 ; @ C624: BD D3 19
        JMP     loc_C5A7                                ; transfert sans retour vers loc_C5A7 ; @ C627: 7E C5 A7
loc_C62A:
        JSR     sub_E4E3                                ; appelle sub_E4E3 ; @ C62A: BD E4 E3
        JMP     loc_C5A7                                ; transfert sans retour vers loc_C5A7 ; @ C62D: 7E C5 A7
loc_C630:
        LDS     #ROM_DATA_C253                          ; @ C630: 8E C2 53
        LDX     #ROM_DATA_FFFB                          ; @ C633: CE FF FB
loc_C636:
        LDAA    $42,X                                   ; @ C636: A6 42
        BMI     loc_C640                                ; branche vers loc_C640 si la condition MI est vraie ; @ C638: 2B 06
        INS                                             ; @ C63A: 31
        INS                                             ; @ C63B: 31
        INX                                             ; @ C63C: 08
        INX                                             ; @ C63D: 08
        BNE     loc_C636                                ; branche vers loc_C636 si la condition NE est vraie ; @ C63E: 26 F6
loc_C640:
        TAB                                             ; @ C640: 16
        ANDA    #$7D                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C641: 84 7D
        BITA    #$05                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C643: 85 05
        BEQ     loc_C64F                                ; branche vers loc_C64F si la condition EQ est vraie ; @ C645: 27 08
        ORAA    #$60                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C647: 8A 60
        BITA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C649: 85 01
        BEQ     loc_C64F                                ; branche vers loc_C64F si la condition EQ est vraie ; @ C64B: 27 02
        ORAA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C64D: 8A 10
loc_C64F:
        STAA    $42,X                                   ; @ C64F: A7 42
        TSX                                             ; @ C651: 30
        LDS     #RAM_83FF                               ; @ C652: 8E 83 FF
        CLI                                             ; autorise à nouveau les IRQ ; @ C655: 0E
        LDX     ,X                                      ; @ C656: EE 00
        JSR     ,X                                      ; appelle ,X ; @ C658: AD 00
        JMP     loc_C522                                ; transfert sans retour vers loc_C522 ; @ C65A: 7E C5 22
loc_C65D:
        LDS     #ROM_DATA_C25F                          ; @ C65D: 8E C2 5F
        LDX     #ROM_DATA_FFFB                          ; @ C660: CE FF FB
loc_C663:
        LDAA    $42,X                                   ; @ C663: A6 42
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C665: 85 40
        BNE     loc_C66F                                ; branche vers loc_C66F si la condition NE est vraie ; @ C667: 26 06
        INS                                             ; @ C669: 31
        INS                                             ; @ C66A: 31
        INX                                             ; @ C66B: 08
        INX                                             ; @ C66C: 08
        BNE     loc_C663                                ; branche vers loc_C663 si la condition NE est vraie ; @ C66D: 26 F4
loc_C66F:
        TAB                                             ; @ C66F: 16
        ANDA    #$AF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C670: 84 AF
        BRA     loc_C64F                                ; branche toujours vers loc_C64F ; @ C672: 20 DB
loc_C674:
        CLI                                             ; autorise à nouveau les IRQ ; @ C674: 0E
        TBA                                             ; @ C675: 17
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C676: 84 7F
        STAA    DP_0037                                 ; @ C678: 97 37
        JSR     sub_CE85                                ; appelle sub_CE85 ; @ C67A: BD CE 85
        JMP     loc_C5A7                                ; transfert sans retour vers loc_C5A7 ; @ C67D: 7E C5 A7
loc_C680:
        CLI                                             ; autorise à nouveau les IRQ ; @ C680: 0E
        JSR     sub_EFEF                                ; appelle sub_EFEF ; @ C681: BD EF EF
        JMP     loc_C5A7                                ; transfert sans retour vers loc_C5A7 ; @ C684: 7E C5 A7

; ---------------------------------------------------------------------------
; ROUTINE $C687 — sub_C687
; INCONNU — sous-routine interne à $C687; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C3C8, $C44B, $C47F, $E0E3, $E21C. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_C687:
        LDAA    DP_0037                                 ; @ C687: 96 37
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C689: 85 40
        BNE     loc_C690                                ; branche vers loc_C690 si la condition NE est vraie ; @ C68B: 26 03
        JMP     loc_C82D                                ; transfert sans retour vers loc_C82D ; @ C68D: 7E C8 2D
loc_C690:
        CLRB                                            ; @ C690: 5F
        LDX     #DP_0000                                ; @ C691: CE 00 00
        STX     RAM_8029                                ; @ C694: FF 80 29
        STX     RAM_802B                                ; @ C697: FF 80 2B
        LDAA    RAM_8013                                ; @ C69A: B6 80 13
        BPL     loc_C6A1                                ; branche vers loc_C6A1 si la condition PL est vraie ; @ C69D: 2A 02
        LDAB    #$40                                    ; @ C69F: C6 40
loc_C6A1:
        LDAA    RAM_8022                                ; @ C6A1: B6 80 22
        BPL     loc_C6A8                                ; branche vers loc_C6A8 si la condition PL est vraie ; @ C6A4: 2A 02
        ORAB    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C6A6: CA 20
loc_C6A8:
        LDAA    RAM_802A                                ; @ C6A8: B6 80 2A
        ANDA    #$03                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C6AB: 84 03
        STAA    RAM_802A                                ; @ C6AD: B7 80 2A
        ORAB    RAM_802A                                ; @ C6B0: FA 80 2A
        STAB    RAM_802A                                ; @ C6B3: F7 80 2A
        LDAB    #$40                                    ; @ C6B6: C6 40
        LDAA    RAM_8022                                ; @ C6B8: B6 80 22
        LSRA                                            ; @ C6BB: 44
        BCC     loc_C6DD                                ; branche vers loc_C6DD si la condition CC est vraie ; @ C6BC: 24 1F
        LDAB    #$C0                                    ; @ C6BE: C6 C0
        STAB    RAM_802C                                ; @ C6C0: F7 80 2C
        LDAA    RAM_8008                                ; @ C6C3: B6 80 08
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C6C6: 85 02
        BEQ     loc_C6E0                                ; branche vers loc_C6E0 si la condition EQ est vraie ; @ C6C8: 27 16
        BITA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C6CA: 85 01
        BNE     loc_C6D2                                ; branche vers loc_C6D2 si la condition NE est vraie ; @ C6CC: 26 04
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C6CE: 85 04
        BEQ     loc_C6E0                                ; branche vers loc_C6E0 si la condition EQ est vraie ; @ C6D0: 27 0E
loc_C6D2:
        BITA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C6D2: 85 08
        BEQ     loc_C6E0                                ; branche vers loc_C6E0 si la condition EQ est vraie ; @ C6D4: 27 0A
        LDAB    RAM_802C                                ; @ C6D6: F6 80 2C
        ANDB    #$3F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C6D9: C4 3F
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C6DB: CA 80
loc_C6DD:
        STAB    RAM_802C                                ; @ C6DD: F7 80 2C
loc_C6E0:
        LDAA    RAM_8014                                ; @ C6E0: B6 80 14
        LDAB    #$30                                    ; @ C6E3: C6 30
        LSRA                                            ; @ C6E5: 44
        BCC     loc_C6F2                                ; branche vers loc_C6F2 si la condition CC est vraie ; @ C6E6: 24 0A
        LDAB    #$10                                    ; @ C6E8: C6 10
        LSRA                                            ; @ C6EA: 44
        BCC     loc_C6F2                                ; branche vers loc_C6F2 si la condition CC est vraie ; @ C6EB: 24 05
        ASLB                                            ; @ C6ED: 58
        LSRA                                            ; @ C6EE: 44
        BCC     loc_C6F2                                ; branche vers loc_C6F2 si la condition CC est vraie ; @ C6EF: 24 01
        CLRB                                            ; @ C6F1: 5F
loc_C6F2:
        ORAB    RAM_802C                                ; @ C6F2: FA 80 2C
        STAB    RAM_802C                                ; @ C6F5: F7 80 2C
        CLRB                                            ; @ C6F8: 5F
        LDAA    RAM_8014                                ; @ C6F9: B6 80 14
        ASLA                                            ; @ C6FC: 48
        BCC     loc_C708                                ; branche vers loc_C708 si la condition CC est vraie ; @ C6FD: 24 09
        INCB                                            ; @ C6FF: 5C
        ASLA                                            ; @ C700: 48
        BCC     loc_C708                                ; branche vers loc_C708 si la condition CC est vraie ; @ C701: 24 05
        INCB                                            ; @ C703: 5C
        ASLA                                            ; @ C704: 48
        BCC     loc_C708                                ; branche vers loc_C708 si la condition CC est vraie ; @ C705: 24 01
        INCB                                            ; @ C707: 5C
loc_C708:
        STAB    RAM_802B                                ; @ C708: F7 80 2B
        LDAA    RAM_8010                                ; @ C70B: B6 80 10
        LDAB    #$10                                    ; @ C70E: C6 10
        ANDA    #$30                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C710: 84 30
        CMPA    #$20                                    ; @ C712: 81 20
        BEQ     loc_C71D                                ; branche vers loc_C71D si la condition EQ est vraie ; @ C714: 27 07
        LSRB                                            ; @ C716: 54
        CMPA    #$30                                    ; @ C717: 81 30
        BNE     loc_C71D                                ; branche vers loc_C71D si la condition NE est vraie ; @ C719: 26 02
        LDAB    #$18                                    ; @ C71B: C6 18
loc_C71D:
        LDAA    RAM_800F                                ; @ C71D: B6 80 0F
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C720: 85 20
        BEQ     loc_C726                                ; branche vers loc_C726 si la condition EQ est vraie ; @ C722: 27 02
        ORAB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C724: CA 04
loc_C726:
        ORAB    RAM_802A                                ; @ C726: FA 80 2A
        STAB    RAM_802A                                ; @ C729: F7 80 2A
        LDAB    #$04                                    ; @ C72C: C6 04
        BITA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C72E: 85 08
        BNE     loc_C734                                ; branche vers loc_C734 si la condition NE est vraie ; @ C730: 26 02
        LDAB    #$08                                    ; @ C732: C6 08
loc_C734:
        LSRA                                            ; @ C734: 44
        BCC     loc_C74C                                ; branche vers loc_C74C si la condition CC est vraie ; @ C735: 24 15
        LDAB    #$0C                                    ; @ C737: C6 0C
        LSRA                                            ; @ C739: 44
        BCC     loc_C74C                                ; branche vers loc_C74C si la condition CC est vraie ; @ C73A: 24 10
        LDAB    #$10                                    ; @ C73C: C6 10
        LSRA                                            ; @ C73E: 44
        BCC     loc_C74C                                ; branche vers loc_C74C si la condition CC est vraie ; @ C73F: 24 0B
        LDAB    #$14                                    ; @ C741: C6 14
        LSRA                                            ; @ C743: 44
        BCC     loc_C74C                                ; branche vers loc_C74C si la condition CC est vraie ; @ C744: 24 06
        CLRB                                            ; @ C746: 5F
        LSRA                                            ; @ C747: 44
        BCC     loc_C74C                                ; branche vers loc_C74C si la condition CC est vraie ; @ C748: 24 02
        LDAB    #$1C                                    ; @ C74A: C6 1C
loc_C74C:
        ORAB    RAM_802B                                ; @ C74C: FA 80 2B
        STAB    RAM_802B                                ; @ C74F: F7 80 2B
        LDAA    RAM_8023                                ; @ C752: B6 80 23
        LDAB    #$80                                    ; @ C755: C6 80
        ASLA                                            ; @ C757: 48
        BCC     loc_C76C                                ; branche vers loc_C76C si la condition CC est vraie ; @ C758: 24 12
        LDAB    #$A0                                    ; @ C75A: C6 A0
        ASLA                                            ; @ C75C: 48
        BCC     loc_C76C                                ; branche vers loc_C76C si la condition CC est vraie ; @ C75D: 24 0D
        LDAB    #$C0                                    ; @ C75F: C6 C0
        ASLA                                            ; @ C761: 48
        BCC     loc_C76C                                ; branche vers loc_C76C si la condition CC est vraie ; @ C762: 24 08
        LDAB    #$E0                                    ; @ C764: C6 E0
        ASLA                                            ; @ C766: 48
        ASLA                                            ; @ C767: 48
        BCC     loc_C76C                                ; branche vers loc_C76C si la condition CC est vraie ; @ C768: 24 02
        LDAB    #$60                                    ; @ C76A: C6 60
loc_C76C:
        ORAB    RAM_802B                                ; @ C76C: FA 80 2B
        STAB    RAM_802B                                ; @ C76F: F7 80 2B
        LDAA    RAM_8022                                ; @ C772: B6 80 22
        BPL     loc_C77E                                ; branche vers loc_C77E si la condition PL est vraie ; @ C775: 2A 07
        LDAA    RAM_8025                                ; @ C777: B6 80 25
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C77A: 85 20
        BEQ     loc_C786                                ; branche vers loc_C786 si la condition EQ est vraie ; @ C77C: 27 08
loc_C77E:
        LDAB    #$80                                    ; @ C77E: C6 80
        ORAB    RAM_802A                                ; @ C780: FA 80 2A
        STAB    RAM_802A                                ; @ C783: F7 80 2A
loc_C786:
        LDAA    RAM_8025                                ; @ C786: B6 80 25
        BITA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C789: 85 08
        BEQ     loc_C795                                ; branche vers loc_C795 si la condition EQ est vraie ; @ C78B: 27 08
        LDAB    #$01                                    ; @ C78D: C6 01
        ORAB    RAM_802C                                ; @ C78F: FA 80 2C
        STAB    RAM_802C                                ; @ C792: F7 80 2C
loc_C795:
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C795: 85 04
        BEQ     loc_C7A1                                ; branche vers loc_C7A1 si la condition EQ est vraie ; @ C797: 27 08
        LDAB    #$02                                    ; @ C799: C6 02
        ORAB    RAM_802C                                ; @ C79B: FA 80 2C
        STAB    RAM_802C                                ; @ C79E: F7 80 2C
loc_C7A1:
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7A1: 85 40
        BEQ     loc_C7A9                                ; branche vers loc_C7A9 si la condition EQ est vraie ; @ C7A3: 27 04
        LDAB    #$04                                    ; @ C7A5: C6 04
        BRA     loc_C7B2                                ; branche toujours vers loc_C7B2 ; @ C7A7: 20 09
loc_C7A9:
        LDAA    RAM_8022                                ; @ C7A9: B6 80 22
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7AC: 85 40
        BEQ     loc_C7B8                                ; branche vers loc_C7B8 si la condition EQ est vraie ; @ C7AE: 27 08
        LDAB    #$08                                    ; @ C7B0: C6 08
loc_C7B2:
        ORAB    RAM_802C                                ; @ C7B2: FA 80 2C
        STAB    RAM_802C                                ; @ C7B5: F7 80 2C
loc_C7B8:
        CLRB                                            ; @ C7B8: 5F
        LDAA    RAM_8010                                ; @ C7B9: B6 80 10
        BITA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7BC: 85 08
        BEQ     loc_C7C2                                ; branche vers loc_C7C2 si la condition EQ est vraie ; @ C7BE: 27 02
        ORAB    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7C0: CA 02
loc_C7C2:
        LDAA    RAM_MODE_FLAGS_PULSE_D1                 ; @ C7C2: B6 80 26
        BITA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7C5: 85 10
        BEQ     loc_C7CB                                ; branche vers loc_C7CB si la condition EQ est vraie ; @ C7C7: 27 02
        ORAB    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7C9: CA 01
loc_C7CB:
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7CB: 85 02
        BEQ     loc_C7D1                                ; branche vers loc_C7D1 si la condition EQ est vraie ; @ C7CD: 27 02
        ORAB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7CF: CA 04
loc_C7D1:
        STAB    RAM_8029                                ; @ C7D1: F7 80 29
        LDAB    #$01                                    ; @ C7D4: C6 01
        LSRA                                            ; @ C7D6: 44
        BCS     loc_C7E3                                ; branche vers loc_C7E3 si la condition CS est vraie ; @ C7D7: 25 0A
        LDAA    RAM_MODE_FLAGS_PULSE_D1                 ; @ C7D9: B6 80 26
        LDAB    #$02                                    ; @ C7DC: C6 02
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7DE: 85 02
        BNE     loc_C7E3                                ; branche vers loc_C7E3 si la condition NE est vraie ; @ C7E0: 26 01
        CLRB                                            ; @ C7E2: 5F
loc_C7E3:
        ORAB    RAM_802A                                ; @ C7E3: FA 80 2A
        STAB    RAM_802A                                ; @ C7E6: F7 80 2A
        SEI                                             ; masque les IRQ pendant la section critique ; @ C7E9: 0F
        LDAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C7EA: B6 20 01
        ANDA    #$F3                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7ED: 84 F3
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C7EF: B7 20 01
        LDAB    #$FF                                    ; @ C7F2: C6 FF
        STAB    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C7F4: F7 20 00
        ORAA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C7F7: 8A 04
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C7F9: B7 20 01
        LDAB    #$01                                    ; @ C7FC: C6 01
        LDX     #RAM_8029                               ; @ C7FE: CE 80 29
loc_C801:
        LDAA    ,X                                      ; @ C801: A6 00
        STAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C803: B7 20 00
        STAB    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ C806: F7 20 02
        PSHB                                            ; @ C809: 37
        CLRB                                            ; @ C80A: 5F
        STAB    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ C80B: F7 20 02
        PULB                                            ; @ C80E: 33
        INX                                             ; @ C80F: 08
        INCB                                            ; @ C810: 5C
        CMPB    #$05                                    ; @ C811: C1 05
        BNE     loc_C801                                ; branche vers loc_C801 si la condition NE est vraie ; @ C813: 26 EC
        LDAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C815: F6 20 01
        ANDB    #$FB                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C818: C4 FB
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C81A: F7 20 01
        CLRA                                            ; @ C81D: 4F
        STAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C81E: B7 20 00
        ORAB    #$0C                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C821: CA 0C
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C823: F7 20 01
        CLI                                             ; autorise à nouveau les IRQ ; @ C826: 0E
        LDAA    DP_0037                                 ; @ C827: 96 37
        ANDA    #$BF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C829: 84 BF
        STAA    DP_0037                                 ; @ C82B: 97 37
loc_C82D:
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C82D: 85 20
        BNE     loc_C834                                ; branche vers loc_C834 si la condition NE est vraie ; @ C82F: 26 03
        JMP     loc_C8EC                                ; transfert sans retour vers loc_C8EC ; @ C831: 7E C8 EC
loc_C834:
        LDX     #RAM_801C                               ; @ C834: CE 80 1C
loc_C837:
        LDAA    ,X                                      ; @ C837: A6 00
        TAB                                             ; @ C839: 16
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C83A: 84 0F
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C83C: 8A 80
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C83E: C4 F0
        LSRB                                            ; @ C840: 54
        LSRB                                            ; @ C841: 54
        LSRB                                            ; @ C842: 54
        LSRB                                            ; @ C843: 54
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C844: CA 80
        PSHB                                            ; @ C846: 37
        PSHA                                            ; @ C847: 36
        DEX                                             ; @ C848: 09
        CPX     #RAM_8017                               ; @ C849: 8C 80 17
        BNE     loc_C837                                ; branche vers loc_C837 si la condition NE est vraie ; @ C84C: 26 E9
        LDAA    DP_0038                                 ; @ C84E: 96 38
        BNE     loc_C8AD                                ; branche vers loc_C8AD si la condition NE est vraie ; @ C850: 26 5B
        LDAA    DP_003D                                 ; @ C852: 96 3D
        ANDA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C854: 84 07
        EORA    #$07                                    ; @ C856: 88 07
        BEQ     loc_C894                                ; branche vers loc_C894 si la condition EQ est vraie ; @ C858: 27 3A
        LDX     #RAM_8030                               ; @ C85A: CE 80 30
        LDAB    #$04                                    ; @ C85D: C6 04
loc_C85F:
        PULA                                            ; @ C85F: 32
        DECB                                            ; @ C860: 5A
        TSTB                                            ; @ C861: 5D
        BNE     loc_C86A                                ; branche vers loc_C86A si la condition NE est vraie ; @ C862: 26 06
        CMPA    #$89                                    ; @ C864: 81 89
        BHI     loc_C86A                                ; branche vers loc_C86A si la condition HI est vraie ; @ C866: 22 02
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C868: 84 7F
loc_C86A:
        STAA    ,X                                      ; @ C86A: A7 00
        INX                                             ; @ C86C: 08
        CPX     #RAM_803A                               ; @ C86D: 8C 80 3A
        BNE     loc_C85F                                ; branche vers loc_C85F si la condition NE est vraie ; @ C870: 26 ED
        LDAA    RAM_8035                                ; @ C872: B6 80 35
        CMPA    #$89                                    ; @ C875: 81 89
        BHI     loc_C891                                ; branche vers loc_C891 si la condition HI est vraie ; @ C877: 22 18
        LDAA    RAM_8036                                ; @ C879: B6 80 36
        CMPA    #$89                                    ; @ C87C: 81 89
        BHI     loc_C891                                ; branche vers loc_C891 si la condition HI est vraie ; @ C87E: 22 11
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C880: 84 7F
        STAA    RAM_8036                                ; @ C882: B7 80 36
        LDAA    RAM_8039                                ; @ C885: B6 80 39
        CMPA    #$89                                    ; @ C888: 81 89
        BHI     loc_C891                                ; branche vers loc_C891 si la condition HI est vraie ; @ C88A: 22 05
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C88C: 84 7F
        STAA    RAM_8039                                ; @ C88E: B7 80 39
loc_C891:
        JMP     loc_C8B9                                ; transfert sans retour vers loc_C8B9 ; @ C891: 7E C8 B9
loc_C894:
        LDAB    RAM_801D                                ; @ C894: F6 80 1D
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C897: C4 0F
        LDX     #RAM_8030                               ; @ C899: CE 80 30
loc_C89C:
        PULA                                            ; @ C89C: 32
        TSTB                                            ; @ C89D: 5D
        BNE     loc_C8A2                                ; branche vers loc_C8A2 si la condition NE est vraie ; @ C89E: 26 02
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8A0: 84 7F
loc_C8A2:
        STAA    ,X                                      ; @ C8A2: A7 00
        DECB                                            ; @ C8A4: 5A
        INX                                             ; @ C8A5: 08
        CPX     #RAM_803A                               ; @ C8A6: 8C 80 3A
        BNE     loc_C89C                                ; branche vers loc_C89C si la condition NE est vraie ; @ C8A9: 26 F1
        BRA     loc_C8B9                                ; branche toujours vers loc_C8B9 ; @ C8AB: 20 0C
loc_C8AD:
        LDX     #RAM_8030                               ; @ C8AD: CE 80 30
loc_C8B0:
        PULA                                            ; @ C8B0: 32
        STAA    ,X                                      ; @ C8B1: A7 00
        INX                                             ; @ C8B3: 08
        CPX     #RAM_803A                               ; @ C8B4: 8C 80 3A
        BNE     loc_C8B0                                ; branche vers loc_C8B0 si la condition NE est vraie ; @ C8B7: 26 F7
loc_C8B9:
        SEI                                             ; masque les IRQ pendant la section critique ; @ C8B9: 0F
        LDAB    #$07                                    ; @ C8BA: C6 07
        JSR     sub_C9AC                                ; appelle sub_C9AC ; @ C8BC: BD C9 AC
        LDX     #RAM_8032                               ; @ C8BF: CE 80 32
loc_C8C2:
        LDAA    ,X                                      ; @ C8C2: A6 00
        STAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C8C4: B7 20 00
        ANDB    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8C7: C4 F7
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C8C9: F7 20 01
        ORAB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8CC: CA 08
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C8CE: F7 20 01
        INX                                             ; @ C8D1: 08
        CPX     #RAM_803A                               ; @ C8D2: 8C 80 3A
        BNE     loc_C8C2                                ; branche vers loc_C8C2 si la condition NE est vraie ; @ C8D5: 26 EB
        ANDB    #$FB                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8D7: C4 FB
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C8D9: F7 20 01
        CLRA                                            ; @ C8DC: 4F
        STAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C8DD: B7 20 00
        ORAB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8E0: CA 04
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C8E2: F7 20 01
        CLI                                             ; autorise à nouveau les IRQ ; @ C8E5: 0E
        LDAA    DP_0037                                 ; @ C8E6: 96 37
        ANDA    #$DF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8E8: 84 DF
        STAA    DP_0037                                 ; @ C8EA: 97 37
loc_C8EC:
        BITA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8EC: 85 10
        BNE     loc_C8F1                                ; branche vers loc_C8F1 si la condition NE est vraie ; @ C8EE: 26 01
        RTS                                             ; @ C8F0: 39
loc_C8F1:
        LDAA    RAM_8011                                ; @ C8F1: B6 80 11
        TAB                                             ; @ C8F4: 16
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8F5: 84 0F
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C8F7: 8A 80
        STAA    RAM_803A                                ; @ C8F9: B7 80 3A
        LSRB                                            ; @ C8FC: 54
        LSRB                                            ; @ C8FD: 54
        LSRB                                            ; @ C8FE: 54
        LSRB                                            ; @ C8FF: 54
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C900: CA 80
        STAB    RAM_803B                                ; @ C902: F7 80 3B
        LDAA    RAM_8012                                ; @ C905: B6 80 12
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C908: 84 0F
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C90A: 8A 80
        STAA    RAM_803C                                ; @ C90C: B7 80 3C
        LDAB    RAM_8010                                ; @ C90F: F6 80 10
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C912: C4 0F
        LDX     #RAM_803A                               ; @ C914: CE 80 3A
loc_C917:
        LSRB                                            ; @ C917: 54
        BCS     loc_C920                                ; branche vers loc_C920 si la condition CS est vraie ; @ C918: 25 06
        LDAA    ,X                                      ; @ C91A: A6 00
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C91C: 84 7F
        STAA    ,X                                      ; @ C91E: A7 00
loc_C920:
        INX                                             ; @ C920: 08
        CPX     #RAM_803D                               ; @ C921: 8C 80 3D
        BNE     loc_C917                                ; branche vers loc_C917 si la condition NE est vraie ; @ C924: 26 F1
        LDAA    RAM_8015                                ; @ C926: B6 80 15
        TAB                                             ; @ C929: 16
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C92A: 84 0F
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C92C: 8A 80
        STAA    RAM_803D                                ; @ C92E: B7 80 3D
        LSRB                                            ; @ C931: 54
        LSRB                                            ; @ C932: 54
        LSRB                                            ; @ C933: 54
        LSRB                                            ; @ C934: 54
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C935: CA 80
        STAB    RAM_803E                                ; @ C937: F7 80 3E
        LDAA    RAM_8016                                ; @ C93A: B6 80 16
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C93D: 84 0F
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C93F: 8A 80
        STAA    RAM_803F                                ; @ C941: B7 80 3F
        LDX     #RAM_803D                               ; @ C944: CE 80 3D
        LDAB    RAM_MODE_FLAGS_PULSE_D1                 ; @ C947: F6 80 26
loc_C94A:
        ASLB                                            ; @ C94A: 58
        BCS     loc_C953                                ; branche vers loc_C953 si la condition CS est vraie ; @ C94B: 25 06
        LDAA    ,X                                      ; @ C94D: A6 00
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C94F: 84 7F
        STAA    ,X                                      ; @ C951: A7 00
loc_C953:
        INX                                             ; @ C953: 08
        CPX     #RAM_8040                               ; @ C954: 8C 80 40
        BNE     loc_C94A                                ; branche vers loc_C94A si la condition NE est vraie ; @ C957: 26 F1
        SEI                                             ; masque les IRQ pendant la section critique ; @ C959: 0F
        LDAB    #$06                                    ; @ C95A: C6 06
        BSR     sub_C9AC                                ; appelle sub_C9AC ; @ C95C: 8D 4E
        LDX     #RAM_803A                               ; @ C95E: CE 80 3A
loc_C961:
        LDAA    ,X                                      ; @ C961: A6 00
        STAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C963: B7 20 00
        ANDB    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C966: C4 F7
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C968: F7 20 01
        ORAB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C96B: CA 08
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C96D: F7 20 01
        INX                                             ; @ C970: 08
        CPX     #RAM_8040                               ; @ C971: 8C 80 40
        BNE     loc_C961                                ; branche vers loc_C961 si la condition NE est vraie ; @ C974: 26 EB
        LDAA    RAM_8030                                ; @ C976: B6 80 30
        STAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C979: B7 20 00
        ANDB    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C97C: C4 F7
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C97E: F7 20 01
        ORAB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C981: CA 08
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C983: F7 20 01
        LDAA    RAM_8031                                ; @ C986: B6 80 31
        STAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C989: B7 20 00
        ANDB    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C98C: C4 F7
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C98E: F7 20 01
        ORAB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C991: CA 08
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C993: F7 20 01
        ANDB    #$FB                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C996: C4 FB
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C998: F7 20 01
        CLRA                                            ; @ C99B: 4F
        STAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C99C: B7 20 00
        ORAB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C99F: CA 04
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C9A1: F7 20 01
        LDAA    DP_0037                                 ; @ C9A4: 96 37
        ANDA    #$EF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C9A6: 84 EF
        STAA    DP_0037                                 ; @ C9A8: 97 37
        CLI                                             ; autorise à nouveau les IRQ ; @ C9AA: 0E
        RTS                                             ; @ C9AB: 39

; ---------------------------------------------------------------------------
; ROUTINE $C9AC — sub_C9AC
; INCONNU — sous-routine interne à $C9AC; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C8BC, $C95C. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_C9AC:
        LDAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C9AC: B6 20 01
        ANDA    #$FB                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C9AF: 84 FB
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C9B1: B7 20 01
        PSHB                                            ; @ C9B4: 37
        LDAB    #$FF                                    ; @ C9B5: C6 FF
        STAB    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C9B7: F7 20 00
        PULB                                            ; @ C9BA: 33
        ADDB    #$08                                    ; @ C9BB: CB 08
        STAB    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ C9BD: F7 20 02
        ORAA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C9C0: 8A 04
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C9C2: B7 20 01
        PSHB                                            ; @ C9C5: 37
        LDAB    #$90                                    ; @ C9C6: C6 90
        STAB    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ C9C8: F7 20 00
        PULB                                            ; @ C9CB: 33
        ANDA    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C9CC: 84 F7
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C9CE: B7 20 01
        ORAA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C9D1: 8A 08
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ C9D3: B7 20 01
        ANDB    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ C9D6: C4 F7
        STAB    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ C9D8: F7 20 02
        TAB                                             ; @ C9DB: 16
        RTS                                             ; @ C9DC: 39

; ---------------------------------------------------------------------------
; ROUTINE $C9DD — sub_C9DD
; INCONNU — sous-routine interne à $C9DD; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $CBB9, $DC6A, $DCEA, $E1A9. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_C9DD:
        STX     DP_0074                                 ; @ C9DD: DF 74
        LDX     #DP_0000                                ; @ C9DF: CE 00 00
        STX     DP_0076                                 ; @ C9E2: DF 76
        LDAB    #$10                                    ; @ C9E4: C6 10
loc_C9E6:
        ASL     >DP_0077                                ; @ C9E6: 78 00 77
        ROL     >DP_0076                                ; @ C9E9: 79 00 76
        ROL     >DP_0075                                ; @ C9EC: 79 00 75
        ROL     >DP_0074                                ; @ C9EF: 79 00 74
        BCC     loc_CA0C                                ; branche vers loc_CA0C si la condition CC est vraie ; @ C9F2: 24 18
        LDAA    DP_0073                                 ; @ C9F4: 96 73
        ADDA    DP_0077                                 ; @ C9F6: 9B 77
        STAA    DP_0077                                 ; @ C9F8: 97 77
        LDAA    DP_0072                                 ; @ C9FA: 96 72
        ADCA    DP_0076                                 ; @ C9FC: 99 76
        STAA    DP_0076                                 ; @ C9FE: 97 76
        LDAA    #$00                                    ; @ CA00: 86 00
        ADCA    DP_0075                                 ; @ CA02: 99 75
        STAA    DP_0075                                 ; @ CA04: 97 75
        LDAA    #$00                                    ; @ CA06: 86 00
        ADCA    DP_0074                                 ; @ CA08: 99 74
        STAA    DP_0074                                 ; @ CA0A: 97 74
loc_CA0C:
        DECB                                            ; @ CA0C: 5A
        BNE     loc_C9E6                                ; branche vers loc_C9E6 si la condition NE est vraie ; @ CA0D: 26 D7
        RTS                                             ; @ CA0F: 39

; ---------------------------------------------------------------------------
; ROUTINE $CA10 — sub_CA10
; INCONNU — sous-routine interne à $CA10; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $E63D. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CA10:
        TSTB                                            ; @ CA10: 5D
        BEQ     loc_CA3E                                ; branche vers loc_CA3E si la condition EQ est vraie ; @ CA11: 27 2B
        CLRA                                            ; @ CA13: 4F
        ASLB                                            ; @ CA14: 58
        ASLB                                            ; @ CA15: 58
        BPL     loc_CA3F                                ; branche vers loc_CA3F si la condition PL est vraie ; @ CA16: 2A 27
loc_CA18:
        LSR     >DP_0071                                ; @ CA18: 74 00 71
        ROR     >DP_0070                                ; @ CA1B: 76 00 70
        ROR     >DP_006F                                ; @ CA1E: 76 00 6F
        ROR     >DP_006E                                ; @ CA21: 76 00 6E
        ROR     >DP_006D                                ; @ CA24: 76 00 6D
        RORA                                            ; @ CA27: 46
        INCB                                            ; @ CA28: 5C
        BNE     loc_CA18                                ; branche vers loc_CA18 si la condition NE est vraie ; @ CA29: 26 ED
        CMPA    #$50                                    ; @ CA2B: 81 50
        BCS     loc_CA3D                                ; branche vers loc_CA3D si la condition CS est vraie ; @ CA2D: 25 0E
        SEC                                             ; @ CA2F: 0D
        LDX     #ROM_DATA_FFFB                          ; @ CA30: CE FF FB
loc_CA33:
        LDAA    $72,X                                   ; @ CA33: A6 72
        ADCA    #$00                                    ; @ CA35: 89 00
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CA37: 19
        STAA    $72,X                                   ; @ CA38: A7 72
        INX                                             ; @ CA3A: 08
        BNE     loc_CA33                                ; branche vers loc_CA33 si la condition NE est vraie ; @ CA3B: 26 F6
loc_CA3D:
        CLC                                             ; @ CA3D: 0C
loc_CA3E:
        RTS                                             ; @ CA3E: 39
loc_CA3F:
        ASL     >DP_006D                                ; @ CA3F: 78 00 6D
        ROL     >DP_006E                                ; @ CA42: 79 00 6E
        ROL     >DP_006F                                ; @ CA45: 79 00 6F
        ROL     >DP_0070                                ; @ CA48: 79 00 70
        ROL     >DP_0071                                ; @ CA4B: 79 00 71
        ADCA    #$00                                    ; @ CA4E: 89 00
        DECB                                            ; @ CA50: 5A
        BNE     loc_CA3F                                ; branche vers loc_CA3F si la condition NE est vraie ; @ CA51: 26 EC
        ADDA    #$FF                                    ; @ CA53: 8B FF
        RTS                                             ; @ CA55: 39
        FCB     $5D,$27,$0A,$C1,$1C,$2E,$06,$27         ; données ']'.....'' ; @ CA56: 5D 27 0A C1 1C 2E 06 27
        FCB     $02,$8B,$03,$8B,$03,$DF,$5E,$F6         ; données '......^.' ; @ CA5E: 02 8B 03 8B 03 DF 5E F6
        FCB     $80,$02,$2A,$01,$1B,$36,$CE,$00         ; données '..*..6..' ; @ CA66: 80 02 2A 01 1B 36 CE 00
        FCB     $05,$C6,$FA,$A6,$6C,$85,$F0,$26         ; données '....l..&' ; @ CA6E: 05 C6 FA A6 6C 85 F0 26
        FCB     $08,$5C,$4D,$26,$04,$5C,$09,$26         ; données '.\M&.\.&' ; @ CA76: 08 5C 4D 26 04 5C 09 26
        FCB     $F2,$32,$10,$2C,$03,$1B,$16,$4F         ; données '.2.,...O' ; @ CA7E: F2 32 10 2C 03 1B 16 4F
        FCB     $B7,$80,$02,$BD,$CA,$10,$5A,$96         ; données '......Z.' ; @ CA86: B7 80 02 BD CA 10 5A 96
        FCB     $5E,$90,$6D,$96,$5F,$92,$6E,$B6         ; données '^.m._.n.' ; @ CA8E: 5E 90 6D 96 5F 92 6E B6
        FCB     $80,$02,$4C,$25,$EB,$39,$8D,$B8         ; données '..L%.9..' ; @ CA96: 80 02 4C 25 EB 39 8D B8
        FCB     $CE,$00,$02,$E6,$6C,$17,$C4,$F0         ; données '....l...' ; @ CA9E: CE 00 02 E6 6C 17 C4 F0
        FCB     $54,$54,$10,$54,$10,$09,$27,$1B         ; données 'TT.T..'.' ; @ CAA6: 54 54 10 54 10 09 27 1B
        FCB     $5F,$97,$73,$48,$9B,$73,$59,$48         ; données '_.sH.sYH' ; @ CAAE: 5F 97 73 48 9B 73 59 48
        FCB     $59,$48,$59,$48,$59,$9B,$73,$C9         ; données 'YHYHY.s.' ; @ CAB6: 59 48 59 48 59 9B 73 C9
        FCB     $00,$48,$59,$48,$59,$97,$73,$D7         ; données '.HYHY.s.' ; @ CABE: 00 48 59 48 59 97 73 D7
        FCB     $72,$20,$D8,$F6,$80,$02,$58,$58         ; données 'r ....XX' ; @ CAC6: 72 20 D8 F6 80 02 58 58
        FCB     $58,$58,$9B,$73,$D9,$72,$97,$73         ; données 'XX.s.r.s' ; @ CACE: 58 58 9B 73 D9 72 97 73
        FCB     $D7,$72,$17,$84,$0F,$F6,$80,$02         ; données '.r......' ; @ CAD6: D7 72 17 84 0F F6 80 02
        FCB     $DE,$72,$39                             ; données '.r9' ; @ CADE: DE 72 39
loc_CAE1:
        LDAB    #$21                                    ; @ CAE1: C6 21

; ---------------------------------------------------------------------------
; ROUTINE $CAE3 — sub_CAE3
; INCONNU — sous-routine interne à $CAE3; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $D672. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CAE3:
        LDAA    DP_004C                                 ; @ CAE3: 96 4C
        ASLA                                            ; @ CAE5: 48
        ASLA                                            ; @ CAE6: 48
        ASLA                                            ; @ CAE7: 48
        ABA                                             ; @ CAE8: 1B

; ---------------------------------------------------------------------------
; ROUTINE $CAE9 — sub_CAE9
; INCONNU — sous-routine interne à $CAE9; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $E2AA, $F224. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CAE9:
        STAA    RAM_801A                                ; @ CAE9: B7 80 1A
        LDAB    #$FF                                    ; @ CAEC: C6 FF
        STAB    RAM_8018                                ; @ CAEE: F7 80 18
        STAB    RAM_8019                                ; @ CAF1: F7 80 19
        STAB    RAM_801C                                ; @ CAF4: F7 80 1C
        LDAB    #$BA                                    ; @ CAF7: C6 BA
        STAB    RAM_801B                                ; @ CAF9: F7 80 1B

; ---------------------------------------------------------------------------
; ROUTINE $CAFC — sub_CAFC
; INCONNU — sous-routine interne à $CAFC; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C448. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CAFC:
        LDAB    #$F0                                    ; @ CAFC: C6 F0
        ORAB    DP_0037                                 ; @ CAFE: DA 37
        STAB    DP_0037                                 ; @ CB00: D7 37
        LSRA                                            ; @ CB02: 44
        LSRA                                            ; @ CB03: 44
        LSRA                                            ; @ CB04: 44
        LSRA                                            ; @ CB05: 44
        SEI                                             ; masque les IRQ pendant la section critique ; @ CB06: 0F
        LDAB    DP_003A                                 ; @ CB07: D6 3A
        BITB    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CB09: C5 10
        BEQ     loc_CB17                                ; branche vers loc_CB17 si la condition EQ est vraie ; @ CB0B: 27 0A
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CB0D: C4 F0
        ABA                                             ; @ CB0F: 1B
        ORAA    #$60                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CB10: 8A 60
        STAA    DP_003A                                 ; @ CB12: 97 3A
        STAA    PIA_CONTROL_A_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ CB14: B7 40 05
loc_CB17:
        CLI                                             ; autorise à nouveau les IRQ ; @ CB17: 0E
        LDAA    #$0F                                    ; @ CB18: 86 0F
        ORAA    DP_003C                                 ; @ CB1A: 9A 3C
        ANDA    #$FE                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CB1C: 84 FE
        STAA    RAM_8022                                ; @ CB1E: B7 80 22
        STAA    DP_003C                                 ; @ CB21: 97 3C
        LDAB    #$04                                    ; @ CB23: C6 04
        CLR     >DP_003B                                ; @ CB25: 7F 00 3B

; ---------------------------------------------------------------------------
; ROUTINE $CB28 — sub_CB28
; INCONNU — sous-routine interne à $CB28; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $D3ED, $D59D, $D87C, $E09D, $E109, $E16E, $E293. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CB28:
        ORAB    DP_0038                                 ; @ CB28: DA 38
        STAB    DP_0038                                 ; @ CB2A: D7 38
        RTS                                             ; @ CB2C: 39

; ---------------------------------------------------------------------------
; ROUTINE $CB2D — sub_CB2D
; INCONNU — sous-routine interne à $CB2D; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $D46E. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CB2D:
        LDAA    #$99                                    ; @ CB2D: 86 99
        SUBA    DP_005E                                 ; @ CB2F: 90 5E
        ADDA    #$01                                    ; @ CB31: 8B 01
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CB33: 19
        STAA    DP_005E                                 ; @ CB34: 97 5E
        LDAA    #$99                                    ; @ CB36: 86 99
        ADCA    #$00                                    ; @ CB38: 89 00
        SUBA    DP_005F                                 ; @ CB3A: 90 5F
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CB3C: 19
        STAA    DP_005F                                 ; @ CB3D: 97 5F
        RTS                                             ; @ CB3F: 39

; ---------------------------------------------------------------------------
; ROUTINE $CB40 — sub_CB40
; INCONNU — sous-routine interne à $CB40; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $DD5D. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CB40:
        STAB    DP_0074                                 ; @ CB40: D7 74
        TAB                                             ; @ CB42: 16
        TPA                                             ; @ CB43: 07
        PSHA                                            ; @ CB44: 36
        TBA                                             ; @ CB45: 17
        LDAB    DP_0074                                 ; @ CB46: D6 74
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CB48: C4 7F
        BNE     loc_CB56                                ; branche vers loc_CB56 si la condition NE est vraie ; @ CB4A: 26 0A
        LDAB    #$22                                    ; @ CB4C: C6 22
        INS                                             ; @ CB4E: 31
        BCS     loc_CB54                                ; branche vers loc_CB54 si la condition CS est vraie ; @ CB4F: 25 03
        JMP     sub_CAE3                                ; transfert sans retour vers sub_CAE3 ; @ CB51: 7E CA E3
loc_CB54:
        CLC                                             ; @ CB54: 0C
        RTS                                             ; @ CB55: 39
loc_CB56:
        TSTA                                            ; @ CB56: 4D
        BNE     loc_CB5C                                ; branche vers loc_CB5C si la condition NE est vraie ; @ CB57: 26 03
        DECB                                            ; @ CB59: 5A
        ADDA    #$64                                    ; @ CB5A: 8B 64
loc_CB5C:
        CMPB    #$0F                                    ; @ CB5C: C1 0F
        BCS     loc_CB66                                ; branche vers loc_CB66 si la condition CS est vraie ; @ CB5E: 25 06
        BNE     loc_CB70                                ; branche vers loc_CB70 si la condition NE est vraie ; @ CB60: 26 0E
        CMPA    #$1E                                    ; @ CB62: 81 1E
        BGT     loc_CB70                                ; branche vers loc_CB70 si la condition GT est vraie ; @ CB64: 2E 0A
loc_CB66:
        TST     >DP_0074                                ; @ CB66: 7D 00 74
        BPL     loc_CB6D                                ; branche vers loc_CB6D si la condition PL est vraie ; @ CB69: 2A 02
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CB6B: CA 80
loc_CB6D:
        INS                                             ; @ CB6D: 31
        SEC                                             ; @ CB6E: 0D
        RTS                                             ; @ CB6F: 39
loc_CB70:
        PULA                                            ; @ CB70: 32
        LSRA                                            ; @ CB71: 44
        BCS     loc_CB77                                ; branche vers loc_CB77 si la condition CS est vraie ; @ CB72: 25 03
        JMP     loc_CAE1                                ; transfert sans retour vers loc_CAE1 ; @ CB74: 7E CA E1
loc_CB77:
        CLC                                             ; @ CB77: 0C
        RTS                                             ; @ CB78: 39

; ---------------------------------------------------------------------------
; ROUTINE $CB79 — sub_CB79
; INCONNU — sous-routine interne à $CB79; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $DBD4. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CB79:
        STAA    DP_0061                                 ; @ CB79: 97 61
        TBA                                             ; @ CB7B: 17
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CB7C: C4 0F
        STAB    DP_0060                                 ; @ CB7E: D7 60
        ANDA    #$30                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CB80: 84 30
        LDAB    DP_0062                                 ; @ CB82: D6 62
        SBA                                             ; @ CB84: 10
        BEQ     loc_CBD6                                ; branche vers loc_CBD6 si la condition EQ est vraie ; @ CB85: 27 4F
        STAA    DP_0062                                 ; @ CB87: 97 62
        LDAA    RAM_8006                                ; @ CB89: B6 80 06
        CMPA    #$0A                                    ; @ CB8C: 81 0A
        BNE     sub_CB9C                                ; branche vers sub_CB9C si la condition NE est vraie ; @ CB8E: 26 0C
        TSTB                                            ; @ CB90: 5D
        BEQ     loc_CB98                                ; branche vers loc_CB98 si la condition EQ est vraie ; @ CB91: 27 05
        LDAA    DP_0062                                 ; @ CB93: 96 62
        ABA                                             ; @ CB95: 1B
        BNE     sub_CB9C                                ; branche vers sub_CB9C si la condition NE est vraie ; @ CB96: 26 04
loc_CB98:
        LDAA    #$77                                    ; @ CB98: 86 77
        SEC                                             ; @ CB9A: 0D
        RTS                                             ; @ CB9B: 39

; ---------------------------------------------------------------------------
; ROUTINE $CB9C — sub_CB9C
; INCONNU — sous-routine interne à $CB9C; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $DC04. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CB9C:
        LDX     DP_005E                                 ; @ CB9C: DE 5E
        LDAA    DP_0062                                 ; @ CB9E: 96 62
        PSHA                                            ; @ CBA0: 36
        BPL     loc_CBA9                                ; branche vers loc_CBA9 si la condition PL est vraie ; @ CBA1: 2A 06
        LDX     DP_0060                                 ; @ CBA3: DE 60
        CLRA                                            ; @ CBA5: 4F
        NEG     >DP_0062                                ; @ CBA6: 70 00 62
loc_CBA9:
        ABA                                             ; @ CBA9: 1B
        STX     DP_0072                                 ; @ CBAA: DF 72
        PSHA                                            ; @ CBAC: 36
        LDX     #MEM_1999                               ; @ CBAD: CE 19 99
        LDAA    DP_0062                                 ; @ CBB0: 96 62
        SUBA    #$10                                    ; @ CBB2: 80 10
        BEQ     loc_CBB9                                ; branche vers loc_CBB9 si la condition EQ est vraie ; @ CBB4: 27 03
        LDX     #MEM_028F                               ; @ CBB6: CE 02 8F
loc_CBB9:
        JSR     sub_C9DD                                ; appelle sub_C9DD ; @ CBB9: BD C9 DD
        PULB                                            ; @ CBBC: 33
        PULA                                            ; @ CBBD: 32
        ASLA                                            ; @ CBBE: 48
        LDX     #DP_0002                                ; @ CBBF: CE 00 02
        BCS     loc_CBC7                                ; branche vers loc_CBC7 si la condition CS est vraie ; @ CBC2: 25 03
        LDX     #DP_0000                                ; @ CBC4: CE 00 00
loc_CBC7:
        ASL     >DP_0076                                ; @ CBC7: 78 00 76
        LDAA    DP_0075                                 ; @ CBCA: 96 75
        ADCA    #$00                                    ; @ CBCC: 89 00
        STAA    $5F,X                                   ; @ CBCE: A7 5F
        LDAA    DP_0074                                 ; @ CBD0: 96 74
        ADCA    #$00                                    ; @ CBD2: 89 00
        STAA    $5E,X                                   ; @ CBD4: A7 5E
loc_CBD6:
        CLC                                             ; @ CBD6: 0C
        RTS                                             ; @ CBD7: 39

; ---------------------------------------------------------------------------
; ROUTINE $CBD8 — sub_CBD8
; INCONNU — sous-routine interne à $CBD8; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $D667. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CBD8:
        LDAA    DP_006E                                 ; @ CBD8: 96 6E
        TAB                                             ; @ CBDA: 16
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CBDB: C4 F0
        LSRB                                            ; @ CBDD: 54
        LSRB                                            ; @ CBDE: 54
        SBA                                             ; @ CBDF: 10
        LSRB                                            ; @ CBE0: 54
        SBA                                             ; @ CBE1: 10
        PSHA                                            ; @ CBE2: 36
        LDAA    DP_006D                                 ; @ CBE3: 96 6D
        TAB                                             ; @ CBE5: 16
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CBE6: C4 F0
        LSRB                                            ; @ CBE8: 54
        LSRB                                            ; @ CBE9: 54
        SBA                                             ; @ CBEA: 10
        LSRB                                            ; @ CBEB: 54
        SBA                                             ; @ CBEC: 10
        PULB                                            ; @ CBED: 33
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CBEE: CA 80
        RTS                                             ; @ CBF0: 39

; ---------------------------------------------------------------------------
; ROUTINE $CBF1 — sub_CBF1
; INCONNU — sous-routine interne à $CBF1; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $D45B. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CBF1:
        LDAA    $01,X                                   ; @ CBF1: A6 01
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CBF3: 84 F0
        LSRA                                            ; @ CBF5: 44
        LSRA                                            ; @ CBF6: 44
        LSRA                                            ; @ CBF7: 44
        ADDA    #$00                                    ; @ CBF8: 8B 00
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CBFA: 19
        TAB                                             ; @ CBFB: 16
        ABA                                             ; @ CBFC: 1B
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CBFD: 19
        ABA                                             ; @ CBFE: 1B
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CBFF: 19
        TAB                                             ; @ CC00: 16
        CLRA                                            ; @ CC01: 4F
        STAA    DP_0062                                 ; @ CC02: 97 62
        STAA    DP_0061                                 ; @ CC04: 97 61
        STAA    DP_0060                                 ; @ CC06: 97 60
        ADDA    $01,X                                   ; @ CC08: AB 01
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CC0A: 19
        ABA                                             ; @ CC0B: 1B
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CC0C: 19
        STAA    DP_005E                                 ; @ CC0D: 97 5E
        LDAA    ,X                                      ; @ CC0F: A6 00
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CC11: 84 0F
        ADCA    #$00                                    ; @ CC13: 89 00
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CC15: 19
        LDAB    ,X                                      ; @ CC16: E6 00
        BITB    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CC18: C5 10
        BEQ     loc_CC1F                                ; branche vers loc_CC1F si la condition EQ est vraie ; @ CC1A: 27 03
        ADDA    #$16                                    ; @ CC1C: 8B 16
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ CC1E: 19
loc_CC1F:
        STAA    DP_005F                                 ; @ CC1F: 97 5F
        RTS                                             ; @ CC21: 39
        FCB     $00,$00,$10,$00,$00,$00,$00,$50         ; données '.......P' ; @ CC22: 00 00 10 00 00 00 00 50
        FCB     $01,$00,$00,$00,$00,$60,$05,$00         ; données '.....`..' ; @ CC2A: 01 00 00 00 00 60 05 00
        FCB     $00,$00,$20,$11,$60,$99,$99,$99         ; données '.. .`...' ; @ CC32: 00 00 20 11 60 99 99 99
        FCB     $41                                     ; données 'A' ; @ CC3A: 41

; ---------------------------------------------------------------------------
; ROUTINE $CC3B — sub_CC3B
; INCONNU — sous-routine interne à $CC3B; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $CC5D, $CC78, $DB13. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CC3B:
        LDAB    DP_005E                                 ; @ CC3B: D6 5E
        SUBB    ,X                                      ; @ CC3D: E0 00
        LDAB    DP_005F                                 ; @ CC3F: D6 5F
        SBCB    $01,X                                   ; @ CC41: E2 01
        LDAB    DP_0060                                 ; @ CC43: D6 60
        SBCB    $02,X                                   ; @ CC45: E2 02
        LDAB    DP_0061                                 ; @ CC47: D6 61
        SBCB    $03,X                                   ; @ CC49: E2 03
        LDAB    DP_0062                                 ; @ CC4B: D6 62
        SBCB    $04,X                                   ; @ CC4D: E2 04
        RTS                                             ; @ CC4F: 39
loc_CC50:
        LDAB    DP_003D                                 ; @ CC50: D6 3D
        ANDB    #$BF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CC52: C4 BF
        STAB    DP_003D                                 ; @ CC54: D7 3D
        SEC                                             ; @ CC56: 0D
        RTS                                             ; @ CC57: 39

; ---------------------------------------------------------------------------
; ROUTINE $CC58 — sub_CC58
; INCONNU — sous-routine interne à $CC58; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $DB1E. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CC58:
        LDAA    #$22                                    ; @ CC58: 86 22
        LDX     #ROM_DATA_CC22                          ; @ CC5A: CE CC 22
        BSR     sub_CC3B                                ; appelle sub_CC3B ; @ CC5D: 8D DC
        BCS     loc_CC50                                ; branche vers loc_CC50 si la condition CS est vraie ; @ CC5F: 25 EF
        LDAB    DP_0062                                 ; @ CC61: D6 62
        BMI     loc_CC50                                ; branche vers loc_CC50 si la condition MI est vraie ; @ CC63: 2B EB
        LDAA    #$21                                    ; @ CC65: 86 21
        LDX     #ROM_DATA_CC31                          ; @ CC67: CE CC 31
        LDAB    RAM_OPTION_PRESENCE_FLAGS               ; @ CC6A: F6 80 0C
        BMI     loc_CC78                                ; branche vers loc_CC78 si la condition MI est vraie ; @ CC6D: 2B 09
        LDX     #ROM_DATA_CC36                          ; @ CC6F: CE CC 36
        ASLB                                            ; @ CC72: 58
        BMI     loc_CC78                                ; branche vers loc_CC78 si la condition MI est vraie ; @ CC73: 2B 03
        LDX     #ROM_DATA_CC2C                          ; @ CC75: CE CC 2C
loc_CC78:
        BSR     sub_CC3B                                ; appelle sub_CC3B ; @ CC78: 8D C1
        BCC     loc_CC50                                ; branche vers loc_CC50 si la condition CC est vraie ; @ CC7A: 24 D4
        CLC                                             ; @ CC7C: 0C
        RTS                                             ; @ CC7D: 39

; ---------------------------------------------------------------------------
; ROUTINE $CC7E — update_instrument_address_6_control_bits
; CONFIRMÉ — finalisation et émission du mot de l'adresse instrument 6.
; Entrées : images de niveau/modulation en RAM $8505, $8506, $850A et $854A.
; Sorties : image $8506 et registre instrument 6 mis à jour.
; Registres/flags : A et B modifiés; X inchangé.
; RAM/E/S : écrit $6006; préserve D6 Pulse, recalcule D7 (+5 dB/AM) et conserve D5..D0.
; Algorithme : teste le chemin RF et les états niveau/AM avant d'ajouter éventuellement D7.
; ---------------------------------------------------------------------------
update_instrument_address_6_control_bits:
        LDAB    RAM_8506                                ; @ CC7E: F6 85 06
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CC81: C4 7F
        LDAA    RAM_8505                                ; @ CC83: B6 85 05
        ASRA                                            ; @ CC86: 47
        ASRA                                            ; @ CC87: 47
        BCC     loc_CC98                                ; branche vers loc_CC98 si la condition CC est vraie ; @ CC88: 24 0E
        LDAA    RAM_850A                                ; @ CC8A: B6 85 0A
        ASLA                                            ; @ CC8D: 48
        ASLA                                            ; @ CC8E: 48
        BCS     loc_CC96                                ; branche vers loc_CC96 si la condition CS est vraie ; @ CC8F: 25 05
        LDAA    RAM_854A                                ; @ CC91: B6 85 4A
        BEQ     loc_CC98                                ; branche vers loc_CC98 si la condition EQ est vraie ; @ CC94: 27 02
loc_CC96:
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CC96: CA 80
loc_CC98:
        STAB    RAM_8506                                ; @ CC98: F7 85 06
        STAB    INST_06_ATTENUATOR_AND_PULSE            ; émet l'adresse instrument 6 (attenuator and pulse) ; @ CC9B: F7 60 06
        RTS                                             ; @ CC9E: 39

; ---------------------------------------------------------------------------
; ROUTINE $CC9F — irq_swi_front_panel_handler
; CONFIRMÉ — gestionnaire commun IRQ et SWI, principalement panneau avant.
; Entrées : événement signalé par le PIA 6821; contexte processeur empilé par le 6802.
; Sorties : événement clavier/roue décodé, mémoires d'affichage et états de commande mis à jour.
; Registres/flags : contexte interrompu manipulé puis restauré par RTI dans les branches terminales.
; RAM/E/S : lit les ports/contrôles PIA $4000..$4007 et touche les images RAM $8000/$8C00.
; Algorithme : attend la fin d'un état transitoire du port A, distingue les causes CA/CB puis distribue clavier, roue et temporisations.
; ---------------------------------------------------------------------------
irq_swi_front_panel_handler:
        LDAA    PIA_PORT_A_OR_DDRA                      ; accès au PIA 6821 du panneau avant ; @ CC9F: B6 40 00
        CMPA    #$92                                    ; @ CCA2: 81 92
        BEQ     irq_swi_front_panel_handler             ; branche vers irq_swi_front_panel_handler si la condition EQ est vraie ; @ CCA4: 27 F9
        COMA                                            ; @ CCA6: 43
        BGT     loc_CCAC                                ; branche vers loc_CCAC si la condition GT est vraie ; @ CCA7: 2E 03
        JMP     loc_CE3D                                ; transfert sans retour vers loc_CE3D ; @ CCA9: 7E CE 3D
loc_CCAC:
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CCAC: 85 04
        BNE     loc_CD25                                ; branche vers loc_CD25 si la condition NE est vraie ; @ CCAE: 26 75
        LDAA    PIA_CONTROL_A                           ; accès au PIA 6821 du panneau avant ; @ CCB0: B6 40 01
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CCB3: 85 02
        BEQ     loc_CCCD                                ; branche vers loc_CCCD si la condition EQ est vraie ; @ CCB5: 27 16
        LDAB    #$02                                    ; @ CCB7: C6 02
loc_CCB9:
        LDX     #ROM_DATA_FFFF                          ; @ CCB9: CE FF FF
        STX     RAM_8C00                                ; @ CCBC: FF 8C 00
loc_CCBF:
        DEX                                             ; @ CCBF: 09
        BNE     loc_CCBF                                ; branche vers loc_CCBF si la condition NE est vraie ; @ CCC0: 26 FD
        DECB                                            ; @ CCC2: 5A
        BNE     loc_CCB9                                ; branche vers loc_CCB9 si la condition NE est vraie ; @ CCC3: 26 F4
        LDAB    #$E3                                    ; @ CCC5: C6 E3
        STAB    PIA_PORT_A_OR_DDRA                      ; accès au PIA 6821 du panneau avant ; @ CCC7: F7 40 00
        JMP     loc_C344                                ; transfert sans retour vers loc_C344 ; @ CCCA: 7E C3 44
loc_CCCD:
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CCCD: 85 04
        BEQ     loc_CCE6                                ; branche vers loc_CCE6 si la condition EQ est vraie ; @ CCCF: 27 15
loc_CCD1:
        LDAA    PIA_CONTROL_A                           ; accès au PIA 6821 du panneau avant ; @ CCD1: B6 40 01
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CCD4: 85 04
        BNE     loc_CCD1                                ; branche vers loc_CCD1 si la condition NE est vraie ; @ CCD6: 26 F9
        LDAB    DP_003A                                 ; @ CCD8: D6 3A
        ANDB    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CCDA: C4 10
        STAB    DP_003A                                 ; @ CCDC: D7 3A
        STAB    PIA_CONTROL_A_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ CCDE: F7 40 05
        LDX     #RAM_8800                               ; @ CCE1: CE 88 00
        STX     DP_0067                                 ; @ CCE4: DF 67
loc_CCE6:
        TAB                                             ; @ CCE6: 16
        ASLB                                            ; @ CCE7: 58
        EORB    DP_003C                                 ; @ CCE8: D8 3C
        BMI     loc_CD19                                ; branche vers loc_CD19 si la condition MI est vraie ; @ CCEA: 2B 2D
loc_CCEC:
        LDAB    DP_003C                                 ; @ CCEC: D6 3C
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CCEE: CA 80
        ASLA                                            ; @ CCF0: 48
        BPL     loc_CD00                                ; branche vers loc_CD00 si la condition PL est vraie ; @ CCF1: 2A 0D
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CCF3: C4 7F
        LDAA    DP_0041                                 ; @ CCF5: 96 41
        ORAA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CCF7: 8A 08
        STAA    DP_0041                                 ; @ CCF9: 97 41
        CLRA                                            ; @ CCFB: 4F
        STAA    DP_0079                                 ; @ CCFC: 97 79
        STAA    DP_0069                                 ; @ CCFE: 97 69
loc_CD00:
        STAB    DP_003C                                 ; @ CD00: D7 3C
        LDAA    DP_003A                                 ; @ CD02: 96 3A
        ANDA    #$EF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CD04: 84 EF
        STAB    RAM_8022                                ; @ CD06: F7 80 22
        BMI     loc_CD0D                                ; branche vers loc_CD0D si la condition MI est vraie ; @ CD09: 2B 02
        ORAA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CD0B: 8A 10
loc_CD0D:
        STAA    DP_003A                                 ; @ CD0D: 97 3A
        STAA    PIA_CONTROL_A_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ CD0F: B7 40 05
        LDAA    #$C0                                    ; @ CD12: 86 C0
        ORAA    DP_0037                                 ; @ CD14: 9A 37
        STAA    DP_0037                                 ; @ CD16: 97 37
        RTI                                             ; @ CD18: 3B
loc_CD19:
        BITA    #$81                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CD19: 85 81
        BEQ     loc_CD22                                ; branche vers loc_CD22 si la condition EQ est vraie ; @ CD1B: 27 05
        LDAB    #$10                                    ; @ CD1D: C6 10
        STAB    PIA_CONTROL_B                           ; accès au PIA 6821 du panneau avant ; @ CD1F: F7 40 03
loc_CD22:
        RTI                                             ; @ CD22: 3B
loc_CD23:
        PULA                                            ; @ CD23: 32
        RTI                                             ; @ CD24: 3B
loc_CD25:
        LSRA                                            ; @ CD25: 44
        BCS     loc_CD6D                                ; branche vers loc_CD6D si la condition CS est vraie ; @ CD26: 25 45
        LDAB    PIA_CONTROL_B_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ CD28: F6 40 07
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CD2B: C4 7F
        BEQ     loc_CD22                                ; branche vers loc_CD22 si la condition EQ est vraie ; @ CD2D: 27 F3
        CMPB    #$7F                                    ; @ CD2F: C1 7F
        BEQ     loc_CD22                                ; branche vers loc_CD22 si la condition EQ est vraie ; @ CD31: 27 EF
        PSHA                                            ; @ CD33: 36
        LDAA    DP_003C                                 ; @ CD34: 96 3C
        BPL     loc_CD3C                                ; branche vers loc_CD3C si la condition PL est vraie ; @ CD36: 2A 04
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CD38: 85 20
        BNE     loc_CD23                                ; branche vers loc_CD23 si la condition NE est vraie ; @ CD3A: 26 E7
loc_CD3C:
        CMPB    #$0A                                    ; @ CD3C: C1 0A
        BEQ     loc_CD79                                ; branche vers loc_CD79 si la condition EQ est vraie ; @ CD3E: 27 39
        CMPB    #$3F                                    ; @ CD40: C1 3F
        BEQ     loc_CD79                                ; branche vers loc_CD79 si la condition EQ est vraie ; @ CD42: 27 35
        CMPB    #$0D                                    ; @ CD44: C1 0D
        BEQ     loc_CD7C                                ; branche vers loc_CD7C si la condition EQ est vraie ; @ CD46: 27 34
        CMPB    #$21                                    ; @ CD48: C1 21
        BEQ     loc_CD7F                                ; branche vers loc_CD7F si la condition EQ est vraie ; @ CD4A: 27 33
        CMPB    #$20                                    ; @ CD4C: C1 20
        BEQ     loc_CD67                                ; branche vers loc_CD67 si la condition EQ est vraie ; @ CD4E: 27 17
loc_CD50:
        LDX     DP_0053                                 ; @ CD50: DE 53
        STAB    ,X                                      ; @ CD52: E7 00
        INC     >DP_0054                                ; @ CD54: 7C 00 54
        LDAA    #$A7                                    ; @ CD57: 86 A7
        INC     >DP_0039                                ; @ CD59: 7C 00 39
        BPL     loc_CD60                                ; branche vers loc_CD60 si la condition PL est vraie ; @ CD5C: 2A 02
        LDAA    #$84                                    ; @ CD5E: 86 84
loc_CD60:
        STAA    PIA_PORT_A_OR_DDRA                      ; accès au PIA 6821 du panneau avant ; @ CD60: B7 40 00
        CMPB    #$0D                                    ; @ CD63: C1 0D
        BEQ     loc_CD23                                ; branche vers loc_CD23 si la condition EQ est vraie ; @ CD65: 27 BC
loc_CD67:
        PULA                                            ; @ CD67: 32
        ADDA    #$00                                    ; @ CD68: 8B 00
        BPL     loc_CD6D                                ; branche vers loc_CD6D si la condition PL est vraie ; @ CD6A: 2A 01
        RTI                                             ; @ CD6C: 3B
loc_CD6D:
        BITA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CD6D: 85 10
        BNE     loc_CD82                                ; branche vers loc_CD82 si la condition NE est vraie ; @ CD6F: 26 11
        LDAB    #$10                                    ; @ CD71: C6 10
        STAB    PIA_CONTROL_B                           ; accès au PIA 6821 du panneau avant ; @ CD73: F7 40 03
loc_CD76:
        LDAB    #$F0                                    ; @ CD76: C6 F0
        PSHB                                            ; @ CD78: 37
loc_CD79:
        JMP     loc_CDD7                                ; transfert sans retour vers loc_CDD7 ; @ CD79: 7E CD D7
loc_CD7C:
        JMP     loc_CDD9                                ; transfert sans retour vers loc_CDD9 ; @ CD7C: 7E CD D9
loc_CD7F:
        JMP     loc_CDCD                                ; transfert sans retour vers loc_CDCD ; @ CD7F: 7E CD CD
loc_CD82:
        BITA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CD82: 85 01
        BEQ     loc_CD76                                ; branche vers loc_CD76 si la condition EQ est vraie ; @ CD84: 27 F0
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CD86: 85 20
        BNE     loc_CD22                                ; branche vers loc_CD22 si la condition NE est vraie ; @ CD88: 26 98
        LDAB    DP_0066                                 ; @ CD8A: D6 66
        BNE     loc_CDAA                                ; branche vers loc_CDAA si la condition NE est vraie ; @ CD8C: 26 1C
        INCB                                            ; @ CD8E: 5C
        STAB    DP_0066                                 ; @ CD8F: D7 66
        LDX     #RAM_8800                               ; @ CD91: CE 88 00
        STX     DP_0067                                 ; @ CD94: DF 67
        LDAA    #$53                                    ; @ CD96: 86 53
        STAA    ,X                                      ; @ CD98: A7 00
        LDAA    #$74                                    ; @ CD9A: 86 74
        STAA    $01,X                                   ; @ CD9C: A7 01
        LDAA    #$62                                    ; @ CD9E: 86 62
        STAA    $02,X                                   ; @ CDA0: A7 02
        LDAA    #$0D                                    ; @ CDA2: 86 0D
        STAA    $03,X                                   ; @ CDA4: A7 03
        LDAA    #$0A                                    ; @ CDA6: 86 0A
        STAA    $04,X                                   ; @ CDA8: A7 04
loc_CDAA:
        CMPB    #$02                                    ; @ CDAA: C1 02
        BEQ     loc_CDC9                                ; branche vers loc_CDC9 si la condition EQ est vraie ; @ CDAC: 27 1B
        LDX     DP_0067                                 ; @ CDAE: DE 67
        LDAA    ,X                                      ; @ CDB0: A6 00
        CMPA    #$0A                                    ; @ CDB2: 81 0A
        BEQ     loc_CDBD                                ; branche vers loc_CDBD si la condition EQ est vraie ; @ CDB4: 27 07
        STAA    PIA_CONTROL_B_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ CDB6: B7 40 07
        INX                                             ; @ CDB9: 08
        STX     DP_0067                                 ; @ CDBA: DF 67
        RTI                                             ; @ CDBC: 3B
loc_CDBD:
        LDAB    #$20                                    ; @ CDBD: C6 20
        STAA    PIA_CONTROL_B_MIRROR                    ; accès au PIA 6821 du panneau avant ; @ CDBF: B7 40 07
        STAB    PIA_CONTROL_B                           ; accès au PIA 6821 du panneau avant ; @ CDC2: F7 40 03
        INC     >DP_0066                                ; @ CDC5: 7C 00 66
        RTI                                             ; @ CDC8: 3B
loc_CDC9:
        CLR     >DP_0066                                ; @ CDC9: 7F 00 66
        RTI                                             ; @ CDCC: 3B
loc_CDCD:
        LDAA    DP_006A                                 ; @ CDCD: 96 6A
        INCA                                            ; @ CDCF: 4C
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CDD0: 8A 80
        STAA    DP_006A                                 ; @ CDD2: 97 6A
        JMP     loc_CD50                                ; transfert sans retour vers loc_CD50 ; @ CDD4: 7E CD 50
loc_CDD7:
        LDAB    #$0D                                    ; @ CDD7: C6 0D
loc_CDD9:
        LDAA    DP_006A                                 ; @ CDD9: 96 6A
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CDDB: 84 0F
        BNE     loc_CDEF                                ; branche vers loc_CDEF si la condition NE est vraie ; @ CDDD: 26 10
        LDAA    DP_006A                                 ; @ CDDF: 96 6A
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CDE1: 84 7F
        STAA    DP_006A                                 ; @ CDE3: 97 6A
        LDX     DP_0053                                 ; @ CDE5: DE 53
        DEX                                             ; @ CDE7: 09
        CMPB    ,X                                      ; @ CDE8: E1 00
        BEQ     loc_CDF2                                ; branche vers loc_CDF2 si la condition EQ est vraie ; @ CDEA: 27 06
        JMP     loc_CD50                                ; transfert sans retour vers loc_CD50 ; @ CDEC: 7E CD 50
loc_CDEF:
        DEC     >DP_006A                                ; @ CDEF: 7A 00 6A
loc_CDF2:
        PULA                                            ; @ CDF2: 32
        RTI                                             ; @ CDF3: 3B
loc_CDF4:
        LDAA    #$05                                    ; @ CDF4: 86 05
        STAA    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ CDF6: B7 20 02
        LDAA    #$38                                    ; @ CDF9: 86 38
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ CDFB: B7 20 01
        CLRB                                            ; @ CDFE: 5F
        STAB    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ CDFF: F7 20 00
        LDAA    #$34                                    ; @ CE02: 86 34
        STAA    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ CE04: B7 20 01
        LDAA    GPIB_REG_0                              ; accès à l'interface distante IEEE-488 ; @ CE07: B6 20 00
        LDAB    #$3C                                    ; @ CE0A: C6 3C
        STAB    GPIB_REG_1                              ; accès à l'interface distante IEEE-488 ; @ CE0C: F7 20 01
        BITA    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE0F: 85 C0
        BEQ     loc_CE3C                                ; branche vers loc_CE3C si la condition EQ est vraie ; @ CE11: 27 29
        LDAB    DP_003C                                 ; @ CE13: D6 3C
        BMI     loc_CE34                                ; branche vers loc_CE34 si la condition MI est vraie ; @ CE15: 2B 1D
        CMPA    #$6F                                    ; @ CE17: 81 6F
        BNE     loc_CE3C                                ; branche vers loc_CE3C si la condition NE est vraie ; @ CE19: 26 21
        LDAA    #$04                                    ; @ CE1B: 86 04
        STAA    PIA_CONTROL_B                           ; accès au PIA 6821 du panneau avant ; @ CE1D: B7 40 03
        CLRB                                            ; @ CE20: 5F
        STAB    PIA_CONTROL_B                           ; accès au PIA 6821 du panneau avant ; @ CE21: F7 40 03
        LDAA    PIA_CONTROL_A                           ; accès au PIA 6821 du panneau avant ; @ CE24: B6 40 01
        BITB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE27: C5 40
        BNE     loc_CE3C                                ; branche vers loc_CE3C si la condition NE est vraie ; @ CE29: 26 11
        LDAB    #$C0                                    ; @ CE2B: C6 C0
        ORAB    DP_0037                                 ; @ CE2D: DA 37
        STAB    DP_0037                                 ; @ CE2F: D7 37
        JMP     loc_CCEC                                ; transfert sans retour vers loc_CCEC ; @ CE31: 7E CC EC
loc_CE34:
        LDAB    DP_003B                                 ; @ CE34: D6 3B
        BITB    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE36: C5 C0
        BNE     loc_CE3C                                ; branche vers loc_CE3C si la condition NE est vraie ; @ CE38: 26 02
        STAA    DP_003B                                 ; @ CE3A: 97 3B
loc_CE3C:
        RTI                                             ; @ CE3C: 3B
loc_CE3D:
        LDAA    GPIB_REG_3                              ; accès à l'interface distante IEEE-488 ; @ CE3D: B6 20 03
        BPL     loc_CE6E                                ; branche vers loc_CE6E si la condition PL est vraie ; @ CE40: 2A 2C
        PSHA                                            ; @ CE42: 36
        LDAB    DP_0037                                 ; @ CE43: D6 37
        TST     >DP_0038                                ; @ CE45: 7D 00 38
        BNE     loc_CE56                                ; branche vers loc_CE56 si la condition NE est vraie ; @ CE48: 26 0C
        BITB    #$70                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE4A: C5 70
        BNE     loc_CE56                                ; branche vers loc_CE56 si la condition NE est vraie ; @ CE4C: 26 08
        CLR     >DP_0037                                ; @ CE4E: 7F 00 37
        PULA                                            ; @ CE51: 32
        LDAA    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ CE52: B6 20 02
        RTI                                             ; @ CE55: 3B
loc_CE56:
        TBA                                             ; @ CE56: 17
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE57: 84 0F
        CMPA    #$0F                                    ; @ CE59: 81 0F
        BNE     loc_CE5F                                ; branche vers loc_CE5F si la condition NE est vraie ; @ CE5B: 26 02
        CLRA                                            ; @ CE5D: 4F
        INCA                                            ; @ CE5E: 4C
loc_CE5F:
        INCA                                            ; @ CE5F: 4C
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE60: C4 F0
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE62: 8A 80
        ABA                                             ; @ CE64: 1B
        STAA    DP_0037                                 ; @ CE65: 97 37
        STAA    MEM_0800                                ; @ CE67: B7 08 00
        LDAA    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ CE6A: B6 20 02
        PULA                                            ; @ CE6D: 32
loc_CE6E:
        ASLA                                            ; @ CE6E: 48
        BPL     loc_CDF4                                ; branche vers loc_CDF4 si la condition PL est vraie ; @ CE6F: 2A 83
        LDAB    GPIB_REG_2                              ; accès à l'interface distante IEEE-488 ; @ CE71: F6 20 02
        ROLB                                            ; @ CE74: 59
        ROLB                                            ; @ CE75: 59
        ROLB                                            ; @ CE76: 59
        ANDB    #$03                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE77: C4 03
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE79: CA 80
        STAB    DP_006B                                 ; @ CE7B: D7 6B
        LDAA    DP_0038                                 ; @ CE7D: 96 38
        BEQ     loc_CE84                                ; branche vers loc_CE84 si la condition EQ est vraie ; @ CE7F: 27 03
        STAA    MEM_0800                                ; @ CE81: B7 08 00
loc_CE84:
        RTI                                             ; @ CE84: 3B

; ---------------------------------------------------------------------------
; ROUTINE $CE85 — sub_CE85
; INCONNU — sous-routine interne à $CE85; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C67A. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_CE85:
        LDAA    DP_0038                                 ; @ CE85: 96 38
        TSTA                                            ; @ CE87: 4D
        BNE     loc_CE8D                                ; branche vers loc_CE8D si la condition NE est vraie ; @ CE88: 26 03
        JMP     sub_C687                                ; transfert sans retour vers sub_C687 ; @ CE8A: 7E C6 87
loc_CE8D:
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CE8D: C4 0F
        PSHA                                            ; @ CE8F: 36
        LDAA    DP_0049                                 ; @ CE90: 96 49
        CMPA    #$87                                    ; @ CE92: 81 87
        PULA                                            ; @ CE94: 32
        BNE     loc_CE9E                                ; branche vers loc_CE9E si la condition NE est vraie ; @ CE95: 26 07
        CMPB    #$06                                    ; @ CE97: C1 06
        BEQ     loc_CEA5                                ; branche vers loc_CEA5 si la condition EQ est vraie ; @ CE99: 27 0A
        JMP     loc_CF70                                ; transfert sans retour vers loc_CF70 ; @ CE9B: 7E CF 70
loc_CE9E:
        CMPB    #$0A                                    ; @ CE9E: C1 0A
        BEQ     loc_CEA5                                ; branche vers loc_CEA5 si la condition EQ est vraie ; @ CEA0: 27 03
        JMP     loc_CF70                                ; transfert sans retour vers loc_CF70 ; @ CEA2: 7E CF 70
loc_CEA5:
        CLRB                                            ; @ CEA5: 5F
        STAB    DP_0038                                 ; @ CEA6: D7 38
        BITA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEA8: 85 01
        BEQ     loc_CEEA                                ; branche vers loc_CEEA si la condition EQ est vraie ; @ CEAA: 27 3E
        LDX     #DP_000C                                ; @ CEAC: CE 00 0C
loc_CEAF:
        LDAB    $3B,X                                   ; @ CEAF: E6 3B
        BITB    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEB1: C5 02
        BEQ     loc_CEC7                                ; branche vers loc_CEC7 si la condition EQ est vraie ; @ CEB3: 27 12
        BITB    #$05                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEB5: C5 05
        BEQ     loc_CEC7                                ; branche vers loc_CEC7 si la condition EQ est vraie ; @ CEB7: 27 0E
        PSHB                                            ; @ CEB9: 37
        LDAB    DP_003C                                 ; @ CEBA: D6 3C
        ORAB    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEBC: CA 01
        STAB    DP_003C                                 ; @ CEBE: D7 3C
        PULB                                            ; @ CEC0: 33
        ANDB    #$DF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEC1: C4 DF
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEC3: CA 40
        STAB    $3B,X                                   ; @ CEC5: E7 3B
loc_CEC7:
        DEX                                             ; @ CEC7: 09
        DEX                                             ; @ CEC8: 09
        BNE     loc_CEAF                                ; branche vers loc_CEAF si la condition NE est vraie ; @ CEC9: 26 E4
        LDAB    RAM_8025                                ; @ CECB: F6 80 25
        BITB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CECE: C5 40
        BEQ     loc_CEEA                                ; branche vers loc_CEEA si la condition EQ est vraie ; @ CED0: 27 18
        LDAB    DP_0041                                 ; @ CED2: D6 41
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CED4: CA 40
        STAB    DP_0041                                 ; @ CED6: D7 41
        LDX     DP_0030                                 ; @ CED8: DE 30
        BEQ     loc_CEE4                                ; branche vers loc_CEE4 si la condition EQ est vraie ; @ CEDA: 27 08
        LDAB    DP_0047                                 ; @ CEDC: D6 47
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEDE: CA 40
        STAB    DP_0047                                 ; @ CEE0: D7 47
        BRA     loc_CEEA                                ; branche toujours vers loc_CEEA ; @ CEE2: 20 06
loc_CEE4:
        LDAB    DP_0045                                 ; @ CEE4: D6 45
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEE6: CA 40
        STAB    DP_0045                                 ; @ CEE8: D7 45
loc_CEEA:
        BITA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEEA: 85 10
        BEQ     loc_CEF4                                ; branche vers loc_CEF4 si la condition EQ est vraie ; @ CEEC: 27 06
        LDAB    DP_003D                                 ; @ CEEE: D6 3D
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEF0: CA 40
        STAB    DP_003D                                 ; @ CEF2: D7 3D
loc_CEF4:
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CEF4: 85 20
        BEQ     loc_CF04                                ; branche vers loc_CF04 si la condition EQ est vraie ; @ CEF6: 27 0C
        LDAB    #$40                                    ; @ CEF8: C6 40
        ORAB    DP_003D                                 ; @ CEFA: DA 3D
        STAB    DP_003D                                 ; @ CEFC: D7 3D
        BRA     loc_CF04                                ; branche toujours vers loc_CF04 ; @ CEFE: 20 04
        FCB     $DA,$47,$D7,$47                         ; données '.G.G' ; @ CF00: DA 47 D7 47
loc_CF04:
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF04: 85 40
        BEQ     loc_CF0E                                ; branche vers loc_CF0E si la condition EQ est vraie ; @ CF06: 27 06
        LDAB    DP_003D                                 ; @ CF08: D6 3D
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF0A: CA 40
        STAB    DP_003D                                 ; @ CF0C: D7 3D
loc_CF0E:
        BITA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF0E: 85 80
        BEQ     loc_CF1E                                ; branche vers loc_CF1E si la condition EQ est vraie ; @ CF10: 27 0C
        LDAB    DP_003D                                 ; @ CF12: D6 3D
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF14: CA 40
        STAB    DP_003D                                 ; @ CF16: D7 3D
        LDAB    #$80                                    ; @ CF18: C6 80
        ORAB    DP_0049                                 ; @ CF1A: DA 49
        STAB    DP_0049                                 ; @ CF1C: D7 49
loc_CF1E:
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF1E: 85 04
        BEQ     loc_CF40                                ; branche vers loc_CF40 si la condition EQ est vraie ; @ CF20: 27 1E
        LDAB    DP_003C                                 ; @ CF22: D6 3C
        ORAB    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF24: CA 01
        BITB    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF26: C5 10
        BEQ     loc_CF2E                                ; branche vers loc_CF2E si la condition EQ est vraie ; @ CF28: 27 04
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF2A: C4 F0
        ORAB    #$05                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF2C: CA 05
loc_CF2E:
        STAB    DP_003C                                 ; @ CF2E: D7 3C
        STAB    RAM_8022                                ; @ CF30: F7 80 22
        LDAB    DP_003D                                 ; @ CF33: D6 3D
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF35: CA 40
        TST     >DP_004C                                ; @ CF37: 7D 00 4C
        BNE     loc_CF3E                                ; branche vers loc_CF3E si la condition NE est vraie ; @ CF3A: 26 02
        ORAB    #$60                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF3C: CA 60
loc_CF3E:
        STAB    DP_003D                                 ; @ CF3E: D7 3D
loc_CF40:
        TAB                                             ; @ CF40: 16
        ANDA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF41: 84 02
        BITB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF43: C5 08
        BEQ     loc_CF4E                                ; branche vers loc_CF4E si la condition EQ est vraie ; @ CF45: 27 07
        LDAB    #$01                                    ; @ CF47: C6 01
        STAB    RAM_8003                                ; @ CF49: F7 80 03
        BRA     loc_CF57                                ; branche toujours vers loc_CF57 ; @ CF4C: 20 09
loc_CF4E:
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF4E: 85 02
        BEQ     loc_CF63                                ; branche vers loc_CF63 si la condition EQ est vraie ; @ CF50: 27 11
        LDAB    RAM_8003                                ; @ CF52: F6 80 03
        BGT     loc_CF61                                ; branche vers loc_CF61 si la condition GT est vraie ; @ CF55: 2E 0A
loc_CF57:
        LDX     DP_004B                                 ; @ CF57: DE 4B
        LDAB    $3D,X                                   ; @ CF59: E6 3D
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF5B: CA 40
        STAB    $3D,X                                   ; @ CF5D: E7 3D
        BRA     loc_CF63                                ; branche toujours vers loc_CF63 ; @ CF5F: 20 02
loc_CF61:
        ANDA    #$FD                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ CF61: 84 FD
loc_CF63:
        STAA    DP_0038                                 ; @ CF63: 97 38
        BGT     loc_CF6D                                ; branche vers loc_CF6D si la condition GT est vraie ; @ CF65: 2E 06
        BMI     loc_CF6D                                ; branche vers loc_CF6D si la condition MI est vraie ; @ CF67: 2B 04
        LDAA    #$F0                                    ; @ CF69: 86 F0
        STAA    DP_0037                                 ; @ CF6B: 97 37
loc_CF6D:
        JMP     sub_C687                                ; transfert sans retour vers sub_C687 ; @ CF6D: 7E C6 87
loc_CF70:
        PSHA                                            ; @ CF70: 36
        LDAA    DP_0049                                 ; @ CF71: 96 49
        CMPA    #$87                                    ; @ CF73: 81 87
        PULA                                            ; @ CF75: 32
        BNE     loc_CF4E                                ; branche vers loc_CF4E si la condition NE est vraie ; @ CF76: 26 D6
        RTS                                             ; @ CF78: 39
        FCB     $37,$96,$49,$84,$8F,$81,$84,$27         ; données '7.I....'' ; @ CF79: 37 96 49 84 8F 81 84 27
        FCB     $15,$81,$87,$27,$11,$7F,$00,$49         ; données '...'...I' ; @ CF81: 15 81 87 27 11 7F 00 49
        FCB     $96,$4A,$8A,$0F,$97,$4A,$B6,$80         ; données '.J...J..' ; @ CF89: 96 4A 8A 0F 97 4A B6 80
        FCB     $25,$8A,$0C,$B7,$80,$25,$CE,$00         ; données '%....%..' ; @ CF91: 25 8A 0C B7 80 25 CE 00
        FCB     $23,$C5,$20,$26,$18,$CE,$00,$0F         ; données '#. &....' ; @ CF99: 23 C5 20 26 18 CE 00 0F
        FCB     $86,$7F,$C8,$05,$C5,$05,$26,$0F         ; données '......&.' ; @ CFA1: 86 7F C8 05 C5 05 26 0F
        FCB     $CE,$00,$6D,$F6,$80,$02,$2E,$09         ; données '..m.....' ; @ CFA9: CE 00 6D F6 80 02 2E 09
        FCB     $1B,$88,$0F,$20,$04,$86,$3F,$C6         ; données '... ..?.' ; @ CFB1: 1B 88 0F 20 04 86 3F C6
        FCB     $01,$37,$B7,$80,$1D,$B7,$80,$09         ; données '.7......' ; @ CFB9: 01 37 B7 80 1D B7 80 09
        FCB     $33,$32,$BD,$D1,$F4,$F6,$80,$09         ; données '32......' ; @ CFC1: 33 32 BD D1 F4 F6 80 09
        FCB     $BD,$D2,$9E,$DE,$5E,$FF,$80,$18         ; données '....^...' ; @ CFC9: BD D2 9E DE 5E FF 80 18
        FCB     $DE,$60,$FF,$80,$1A,$96,$62,$B7         ; données '.`....b.' ; @ CFD1: DE 60 FF 80 1A 96 62 B7
        FCB     $80,$1C,$86,$70,$7D,$00,$38,$26         ; données '...p}.8&' ; @ CFD9: 80 1C 86 70 7D 00 38 26
        FCB     $02,$86,$F0,$9A,$37,$97,$37,$39         ; données '....7.79' ; @ CFE1: 02 86 F0 9A 37 97 37 39
        FCB     $37,$CE,$00,$2A,$86,$BF,$36,$C5         ; données '7..*..6.' ; @ CFE9: 37 CE 00 2A 86 BF 36 C5
        FCB     $20,$26,$7E,$CE,$00,$16,$C8,$05         ; données ' &~.....' ; @ CFF1: 20 26 7E CE 00 16 C8 05
        FCB     $C5,$05,$26,$75,$86,$3F,$F6,$80         ; données '..&u.?..' ; @ CFF9: C5 05 26 75 86 3F F6 80
        FCB     $02,$CE,$00,$6D,$37,$E6,$01,$C4         ; données '...m7...' ; @ D001: 02 CE 00 6D 37 E6 01 C4
        FCB     $F0,$2F,$02,$84,$DF,$F6,$83,$FD         ; données './......' ; @ D009: F0 2F 02 84 DF F6 83 FD
        FCB     $C5,$20,$26,$02,$84,$3F,$B7,$80         ; données '. &..?..' ; @ D011: C5 20 26 02 84 3F B7 80
        FCB     $0F,$33,$32,$37,$FB,$83,$FC,$2E         ; données '.327....' ; @ D019: 0F 33 32 37 FB 83 FC 2E
        FCB     $0B,$4A,$24,$08,$1B,$C1,$FA,$26         ; données '.J$....&' ; @ D021: 0B 4A 24 08 1B C1 FA 26
        FCB     $02,$80,$02,$4C,$B7,$80,$10,$33         ; données '...L...3' ; @ D029: 02 80 02 4C B7 80 10 33
        FCB     $32,$BD,$D1,$F4,$BD,$D2,$9E,$DE         ; données '2.......' ; @ D031: 32 BD D1 F4 BD D2 9E DE
        FCB     $5E,$FF,$80,$11,$96,$38,$44,$25         ; données '^....8D%' ; @ D039: 5E FF 80 11 96 38 44 25
        FCB     $22,$96,$41,$85,$20,$27,$1C,$96         ; données '".A. '..' ; @ D041: 22 96 41 85 20 27 1C 96
        FCB     $22,$85,$80,$26,$16,$CE,$AA,$AA         ; données '"..&....' ; @ D049: 22 85 80 26 16 CE AA AA
        FCB     $FF,$80,$11,$B6,$80,$10,$8A,$0F         ; données '........' ; @ D051: FF 80 11 B6 80 10 8A 0F
        FCB     $B7,$80,$10,$B6,$80,$0F,$8A,$20         ; données '....... ' ; @ D059: B7 80 10 B6 80 0F 8A 20
        FCB     $B7,$80,$0F,$86,$50,$7D,$00,$38         ; données '....P}.8' ; @ D061: B7 80 0F 86 50 7D 00 38
        FCB     $26,$02,$86,$D0,$9A,$37,$97,$37         ; données '&....7.7' ; @ D069: 26 02 86 D0 9A 37 97 37
        FCB     $39,$B6,$83,$FD,$85,$08,$27,$35         ; données '9.....'5' ; @ D071: 39 B6 83 FD 85 08 27 35
        FCB     $BD,$CB,$F1,$F6,$83,$FC,$CA,$30         ; données '.......0' ; @ D079: BD CB F1 F6 83 FC CA 30
        FCB     $86,$FE,$6D,$00,$2B,$1C,$C4,$CF         ; données '..m.+...' ; @ D081: 86 FE 6D 00 2B 1C C4 CF
        FCB     $CE,$00,$57,$96,$5E,$AB,$00,$19         ; données '..W.^...' ; @ D089: CE 00 57 96 5E AB 00 19
        FCB     $97,$5E,$96,$5F,$A9,$01,$19,$97         ; données '.^._....' ; @ D091: 97 5E 96 5F A9 01 19 97
        FCB     $5F,$25,$05,$BD,$CB,$2D,$CA,$20         ; données '_%...-. ' ; @ D099: 5F 25 05 BD CB 2D CA 20
        FCB     $A6,$02,$F7,$83,$FC,$C6,$FF,$CE         ; données '........' ; @ D0A1: A6 02 F7 83 FC C6 FF CE
        FCB     $00,$5E,$7E,$D0,$05,$E6,$00,$A6         ; données '.^~.....' ; @ D0A9: 00 5E 7E D0 05 E6 00 A6
        FCB     $01,$54,$24,$02,$8B,$64,$CE,$C0         ; données '.T$..d..' ; @ D0B1: 01 54 24 02 8B 64 CE C0
        FCB     $50,$DF,$5E,$48,$24,$03,$7C,$00         ; données 'P.^H$.|.' ; @ D0B9: 50 DF 5E 48 24 03 7C 00
        FCB     $5E,$9B,$5F,$24,$03,$7C,$00,$5E         ; données '^._$.|.^' ; @ D0C1: 5E 9B 5F 24 03 7C 00 5E
        FCB     $97,$5F,$DE,$5E,$EE,$00,$DF,$72         ; données '._.^...r' ; @ D0C9: 97 5F DE 5E EE 00 DF 72
        FCB     $BD,$D2,$DF,$B6,$83,$FC,$96,$5F         ; données '......._' ; @ D0D1: BD D2 DF B6 83 FC 96 5F
        FCB     $81,$20,$2C,$03,$5D,$26,$13,$37         ; données '. ,.]&.7' ; @ D0D9: 81 20 2C 03 5D 26 13 37
        FCB     $D6,$5E,$CB,$03,$44,$56,$44,$56         ; données '.^..DVDV' ; @ D0E1: D6 5E CB 03 44 56 44 56
        FCB     $44,$56,$44,$56,$97,$5F,$D7,$5E         ; données 'DVDV._.^' ; @ D0E9: 44 56 44 56 97 5F D7 5E
        FCB     $33,$5C,$86,$F7,$C0,$04,$2B,$05         ; données '3\....+.' ; @ D0F1: 33 5C 86 F7 C0 04 2B 05
        FCB     $47,$C0,$03,$2A,$FB,$CE,$00,$5E         ; données 'G..*...^' ; @ D0F9: 47 C0 03 2A FB CE 00 5E
        FCB     $7E,$D0,$05,$96,$45,$37,$36,$96         ; données '~...E76.' ; @ D101: 7E D0 05 96 45 37 36 96
        FCB     $38,$44,$32,$25,$04,$84,$BB,$97         ; données '8D2%....' ; @ D109: 38 44 32 25 04 84 BB 97
        FCB     $45,$CE,$00,$30,$86,$03,$C5,$08         ; données 'E..0....' ; @ D111: 45 CE 00 30 86 03 C5 08
        FCB     $27,$02,$86,$05,$36,$C5,$20,$26         ; données ''...6. &' ; @ D119: 27 02 86 05 36 C5 20 26
        FCB     $11,$CE,$00,$1C,$C8,$05,$C5,$05         ; données '........' ; @ D121: 11 CE 00 1C C8 05 C5 05
        FCB     $26,$08,$CE,$00,$6D,$F6,$80,$02         ; données '&...m...' ; @ D129: 26 08 CE 00 6D F6 80 02
        FCB     $20,$14,$BD,$D2,$D0,$86,$05,$5D         ; données ' ......]' ; @ D131: 20 14 BD D2 D0 86 05 5D
        FCB     $27,$07,$C0,$04,$86,$03,$5C,$5C         ; données ''.....\\' ; @ D139: 27 07 C0 04 86 03 5C 5C
        FCB     $5C,$5A,$5A,$B7,$83,$FC,$37,$86         ; données '\ZZ...7.' ; @ D141: 5C 5A 5A B7 83 FC 37 86
        FCB     $FF,$5D,$2E,$04,$46,$5C,$2F,$FC         ; données '.]..F\/.' ; @ D149: FF 5D 2E 04 46 5C 2F FC
        FCB     $F6,$80,$26,$C4,$0F,$84,$F0,$1B         ; données '..&.....' ; @ D151: F6 80 26 C4 0F 84 F0 1B
        FCB     $B7,$80,$26,$33,$B6,$83,$FD,$BD         ; données '..&3....' ; @ D159: B7 80 26 33 B6 83 FD BD
        FCB     $D1,$F4,$BD,$D2,$9E,$DE,$5E,$FF         ; données '......^.' ; @ D161: D1 F4 BD D2 9E DE 5E FF
        FCB     $80,$15,$B6,$80,$26,$84,$F6,$D6         ; données '....&...' ; @ D169: 80 15 B6 80 26 84 F6 D6
        FCB     $5F,$C4,$F0,$C1,$10,$26,$02,$8A         ; données '_....&..' ; @ D171: 5F C4 F0 C1 10 26 02 8A
        FCB     $01,$B7,$80,$26,$96,$38,$44,$25         ; données '...&.8D%' ; @ D179: 01 B7 80 26 96 38 44 25
        FCB     $1E,$96,$45,$9A,$47,$85,$02,$26         ; données '..E.G..&' ; @ D181: 1E 96 45 9A 47 85 02 26
        FCB     $16,$96,$21,$85,$10,$26,$10,$CE         ; données '..!..&..' ; @ D189: 16 96 21 85 10 26 10 CE
        FCB     $AA,$AA,$FF,$80,$15,$B6,$80,$26         ; données '.......&' ; @ D191: AA AA FF 80 15 B6 80 26
        FCB     $84,$FE,$8A,$F0,$B7,$80,$26,$96         ; données '......&.' ; @ D199: 84 FE 8A F0 B7 80 26 96
        FCB     $21,$84,$F8,$33,$1B,$B7,$80,$14         ; données '!..3....' ; @ D1A1: 21 84 F8 33 1B B7 80 14
        FCB     $97,$21,$33,$96,$22,$84,$FC,$C5         ; données '.!3."...' ; @ D1A9: 97 21 33 96 22 84 FC C5
        FCB     $20,$27,$01,$4C,$97,$22,$B7,$80         ; données ' '.L."..' ; @ D1B1: 20 27 01 4C 97 22 B7 80
        FCB     $13,$86,$50,$7D,$00,$38,$26,$02         ; données '..P}.8&.' ; @ D1B9: 13 86 50 7D 00 38 26 02
        FCB     $86,$D0,$9A,$37,$97,$37,$39,$96         ; données '...7.79.' ; @ D1C1: 86 D0 9A 37 97 37 39 96
        FCB     $47,$37,$36,$96,$38,$44,$32,$25         ; données 'G76.8D2%' ; @ D1C9: 47 37 36 96 38 44 32 25
        FCB     $04,$84,$BB,$97,$47,$CE,$00,$2E         ; données '....G...' ; @ D1D1: 04 84 BB 97 47 CE 00 2E
        FCB     $86,$06,$36,$C5,$20,$26,$09,$CE         ; données '..6. &..' ; @ D1D9: 86 06 36 C5 20 26 09 CE
        FCB     $00,$1A,$C8,$05,$C5,$05,$27,$08         ; données '......'.' ; @ D1E1: 00 1A C8 05 C5 05 27 08
        FCB     $BD,$D2,$D0,$C6,$FF,$7E,$D1,$47         ; données '.....~.G' ; @ D1E9: BD D2 D0 C6 FF 7E D1 47
        FCB     $7E,$D1,$2B,$36,$A6,$00,$97,$5E         ; données '~.+6...^' ; @ D1F1: 7E D1 2B 36 A6 00 97 5E
        FCB     $A6,$01,$97,$5F,$A6,$02,$97,$60         ; données '..._...`' ; @ D1F9: A6 01 97 5F A6 02 97 60
        FCB     $EE,$03,$DF,$61,$32,$85,$10,$27         ; données '...a2..'' ; @ D201: EE 03 DF 61 32 85 10 27
        FCB     $2B,$36,$96,$69,$26,$25,$CE,$00         ; données '+6.i&%..' ; @ D209: 2B 36 96 69 26 25 CE 00
        FCB     $05,$A6,$5D,$43,$85,$0F,$26,$02         ; données '..]C..&.' ; @ D211: 05 A6 5D 43 85 0F 26 02
        FCB     $8A,$0F,$85,$F0,$26,$02,$8A,$F0         ; données '....&...' ; @ D219: 8A 0F 85 F0 26 02 8A F0
        FCB     $43,$A7,$6C,$09,$26,$EB,$F7,$80         ; données 'C.l.&...' ; @ D221: 43 A7 6C 09 26 EB F7 80
        FCB     $02,$96,$52,$B7,$80,$04,$86,$01         ; données '..R.....' ; @ D229: 02 96 52 B7 80 04 86 01
        FCB     $B7,$80,$03,$32,$36,$96,$62,$2A         ; données '...26.b*' ; @ D231: B7 80 03 32 36 96 62 2A
        FCB     $21,$0D,$CE,$FF,$FB,$86,$99,$89         ; données '!.......' ; @ D239: 21 0D CE FF FB 86 99 89
        FCB     $00,$A0,$63,$19,$A7,$63,$08,$26         ; données '..c..c.&' ; @ D241: 00 A0 63 19 A7 63 08 26
        FCB     $F4,$85,$F0,$27,$09,$36,$86,$22         ; données '...'.6."' ; @ D249: F4 85 F0 27 09 36 86 22
        FCB     $BD,$CA,$E9,$32,$84,$0F,$8A,$D0         ; données '...2....' ; @ D251: BD CA E9 32 84 0F 8A D0
        FCB     $97,$62,$32,$44,$86,$01,$24,$08         ; données '.b2D..$.' ; @ D259: 97 62 32 44 86 01 24 08
        FCB     $B6,$80,$03,$11,$2E,$02,$16,$5A         ; données '.......Z' ; @ D261: B6 80 03 11 2E 02 16 5A
        FCB     $97,$73,$CB,$0A,$27,$2E,$CE,$00         ; données '.s..'...' ; @ D269: 97 73 CB 0A 27 2E CE 00
        FCB     $05,$A6,$5D,$81,$D0,$24,$0C,$85         ; données '..]..$..' ; @ D271: 05 A6 5D 81 D0 24 0C 85
        FCB     $F0,$26,$21,$81,$0F,$27,$1D,$8A         ; données '.&!..'..' ; @ D279: F0 26 21 81 0F 27 1D 8A
        FCB     $F0,$A7,$5D,$5A,$27,$16,$09,$27         ; données '..]Z'..'' ; @ D281: F0 A7 5D 5A 27 16 09 27
        FCB     $13,$85,$0F,$26,$0F,$A6,$5D,$81         ; données '...&..].' ; @ D289: 13 85 0F 26 0F A6 5D 81
        FCB     $F0,$24,$09,$A6,$5E,$8A,$0F,$A7         ; données '.$..^...' ; @ D291: F0 24 09 A6 5E 8A 0F A7
        FCB     $5E,$5A,$26,$D5,$39,$96,$73,$4A         ; données '^Z&.9.sJ' ; @ D299: 5E 5A 26 D5 39 96 73 4A
        FCB     $27,$FA,$D6,$38,$C5,$02,$27,$F4         ; données ''..8..'.' ; @ D2A1: 27 FA D6 38 C5 02 27 F4
        FCB     $D6,$37,$54,$25,$EF,$7F,$00,$72         ; données '.7T%...r' ; @ D2A9: D6 37 54 25 EF 7F 00 72
        FCB     $43,$44,$97,$73,$DE,$72,$A6,$5E         ; données 'CD.s.r.^' ; @ D2B1: 43 44 97 73 DE 72 A6 5E
        FCB     $16,$8A,$F0,$CA,$0F,$25,$08,$4C         ; données '.....%.L' ; @ D2B9: 16 8A F0 CA 0F 25 08 4C
        FCB     $26,$02,$C4,$F0,$E7,$5E,$39,$5C         ; données '&....^9\' ; @ D2C1: 26 02 C4 F0 E7 5E 39 5C
        FCB     $26,$02,$84,$0F,$A7,$5E,$39,$A6         ; données '&....^9.' ; @ D2C9: 26 02 84 0F A7 5E 39 A6
        FCB     $00,$E6,$01,$D7,$73,$16,$54,$54         ; données '....s.TT' ; @ D2D1: 00 E6 01 D7 73 16 54 54
        FCB     $54,$54,$84,$0F,$97,$72,$CE,$00         ; données 'TT...r..' ; @ D2D9: 54 54 84 0F 97 72 CE 00
        FCB     $00,$DF,$5E,$DF,$60,$DF,$61,$CE         ; données '..^.`.a.' ; @ D2E1: 00 DF 5E DF 60 DF 61 CE
        FCB     $00,$10,$78,$00,$73,$79,$00,$72         ; données '..x.sy.r' ; @ D2E9: 00 10 78 00 73 79 00 72
        FCB     $96,$5E,$99,$5E,$19,$97,$5E,$96         ; données '.^.^..^.' ; @ D2F1: 96 5E 99 5E 19 97 5E 96
        FCB     $5F,$99,$5F,$19,$97,$5F,$09,$26         ; données '_._.._.&' ; @ D2F9: 5F 99 5F 19 97 5F 09 26
        FCB     $E9,$CE,$00,$5E,$39                     ; données '...^9' ; @ D301: E9 CE 00 5E 39
loc_D306:
        CMPB    #$2E                                    ; @ D306: C1 2E
        BEQ     loc_D311                                ; branche vers loc_D311 si la condition EQ est vraie ; @ D308: 27 07
        SUBB    #$3B                                    ; @ D30A: C0 3B
        BMI     loc_D318                                ; branche vers loc_D318 si la condition MI est vraie ; @ D30C: 2B 0A
        JMP     loc_DEDE                                ; transfert sans retour vers loc_DEDE ; @ D30E: 7E DE DE
loc_D311:
        LDAA    #$FF                                    ; @ D311: 86 FF
        STAA    DP_0049                                 ; @ D313: 97 49
        JMP     loc_E0B1                                ; transfert sans retour vers loc_E0B1 ; @ D315: 7E E0 B1
loc_D318:
        RTS                                             ; @ D318: 39

; ---------------------------------------------------------------------------
; ROUTINE $D319 — sub_D319
; INCONNU — sous-routine interne à $D319; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C624. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_D319:
        STAB    RAM_800E                                ; @ D319: F7 80 0E
        ANDB    #$3F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D31C: C4 3F
        TBA                                             ; @ D31E: 17
        ANDA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D31F: 84 07
        ASRB                                            ; @ D321: 57
        ASRB                                            ; @ D322: 57
        ASRB                                            ; @ D323: 57
        BEQ     loc_D32B                                ; branche vers loc_D32B si la condition EQ est vraie ; @ D324: 27 05
loc_D326:
        ADDA    #$08                                    ; @ D326: 8B 08
        DECB                                            ; @ D328: 5A
        BNE     loc_D326                                ; branche vers loc_D326 si la condition NE est vraie ; @ D329: 26 FB
loc_D32B:
        LDX     #ROM_DATA_C29F                          ; @ D32B: CE C2 9F
        STX     DP_005E                                 ; @ D32E: DF 5E
        ADDA    DP_005F                                 ; @ D330: 9B 5F
        STAA    DP_005F                                 ; @ D332: 97 5F
        LDAA    DP_005E                                 ; @ D334: 96 5E
        ADCA    #$00                                    ; @ D336: 89 00
        STAA    DP_005E                                 ; @ D338: 97 5E
        LDX     DP_005E                                 ; @ D33A: DE 5E
        LDAB    ,X                                      ; @ D33C: E6 00
        STAB    DP_003B                                 ; @ D33E: D7 3B
        BEQ     loc_D318                                ; branche vers loc_D318 si la condition EQ est vraie ; @ D340: 27 D6
        CMPB    #$2B                                    ; @ D342: C1 2B
        BGT     loc_D306                                ; branche vers loc_D306 si la condition GT est vraie ; @ D344: 2E C0
        LDX     DP_004B                                 ; @ D346: DE 4B
        LDAA    $3D,X                                   ; @ D348: A6 3D
        CMPB    #$10                                    ; @ D34A: C1 10
        BGE     loc_D358                                ; branche vers loc_D358 si la condition GE est vraie ; @ D34C: 2C 0A
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D34E: 85 04
        BNE     loc_D355                                ; branche vers loc_D355 si la condition NE est vraie ; @ D350: 26 03
        JMP     loc_D748                                ; transfert sans retour vers loc_D748 ; @ D352: 7E D7 48
loc_D355:
        JMP     loc_D5AA                                ; transfert sans retour vers loc_D5AA ; @ D355: 7E D5 AA
loc_D358:
        CMPB    #$1A                                    ; @ D358: C1 1A
        BGT     loc_D35F                                ; branche vers loc_D35F si la condition GT est vraie ; @ D35A: 2E 03
        JMP     loc_D48E                                ; transfert sans retour vers loc_D48E ; @ D35C: 7E D4 8E
loc_D35F:
        CMPB    #$24                                    ; @ D35F: C1 24
        BNE     loc_D366                                ; branche vers loc_D366 si la condition NE est vraie ; @ D361: 26 03
        JMP     loc_D48C                                ; transfert sans retour vers loc_D48C ; @ D363: 7E D4 8C
loc_D366:
        CMPB    #$20                                    ; @ D366: C1 20
        BNE     loc_D36D                                ; branche vers loc_D36D si la condition NE est vraie ; @ D368: 26 03
        JMP     loc_D3F3                                ; transfert sans retour vers loc_D3F3 ; @ D36A: 7E D3 F3
loc_D36D:
        CMPB    #$21                                    ; @ D36D: C1 21
        BEQ     loc_D374                                ; branche vers loc_D374 si la condition EQ est vraie ; @ D36F: 27 03
        JMP     loc_D5A2                                ; transfert sans retour vers loc_D5A2 ; @ D371: 7E D5 A2
loc_D374:
        CLRA                                            ; @ D374: 4F
        STAA    DP_0072                                 ; @ D375: 97 72
        LDAA    RAM_8025                                ; @ D377: B6 80 25
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D37A: 85 40
        BEQ     loc_D388                                ; branche vers loc_D388 si la condition EQ est vraie ; @ D37C: 27 0A
        LDAA    #$FF                                    ; @ D37E: 86 FF
        STAA    DP_0072                                 ; @ D380: 97 72
        LDAA    DP_0041                                 ; @ D382: 96 41
        ORAA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D384: 8A 40
        STAA    DP_0041                                 ; @ D386: 97 41
loc_D388:
        LDAA    #$FF                                    ; @ D388: 86 FF
        LDAB    DP_0049                                 ; @ D38A: D6 49
        BEQ     loc_D3AE                                ; branche vers loc_D3AE si la condition EQ est vraie ; @ D38C: 27 20
        STAA    DP_0049                                 ; @ D38E: 97 49
        ANDB    #$87                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D390: C4 87
        CMPB    #$87                                    ; @ D392: C1 87
        BNE     loc_D3AE                                ; branche vers loc_D3AE si la condition NE est vraie ; @ D394: 26 18
loc_D396:
        LDAA    DP_0032                                 ; @ D396: 96 32
        STAA    DP_0020                                 ; @ D398: 97 20
        LDX     DP_0033                                 ; @ D39A: DE 33
        STX     DP_0021                                 ; @ D39C: DF 21
        LDAA    DP_0021                                 ; @ D39E: 96 21
        STAA    RAM_8017                                ; @ D3A0: B7 80 17
        LDAA    DP_0022                                 ; @ D3A3: 96 22
        STAA    RAM_8013                                ; @ D3A5: B7 80 13
        LDAA    DP_00FF                                 ; @ D3A8: 96 FF
        STAA    DP_0072                                 ; @ D3AA: 97 72
        LDAA    #$FD                                    ; @ D3AC: 86 FD
loc_D3AE:
        LDX     #DP_000C                                ; @ D3AE: CE 00 0C
loc_D3B1:
        TAB                                             ; @ D3B1: 16
        ANDB    $3B,X                                   ; @ D3B2: E4 3B
        BITB    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D3B4: C5 07
        BEQ     loc_D3BE                                ; branche vers loc_D3BE si la condition EQ est vraie ; @ D3B6: 27 06
        BITB    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D3B8: C5 20
        BNE     loc_D3BE                                ; branche vers loc_D3BE si la condition NE est vraie ; @ D3BA: 26 02
        ORAB    #$60                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D3BC: CA 60
loc_D3BE:
        STAB    $3B,X                                   ; @ D3BE: E7 3B
        DEX                                             ; @ D3C0: 09
        DEX                                             ; @ D3C1: 09
        BNE     loc_D3B1                                ; branche vers loc_D3B1 si la condition NE est vraie ; @ D3C2: 26 ED
        LDAB    DP_0030                                 ; @ D3C4: D6 30
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D3C6: C4 0F
        BNE     loc_D3DC                                ; branche vers loc_D3DC si la condition NE est vraie ; @ D3C8: 26 12
        LDAB    DP_0031                                 ; @ D3CA: D6 31
        BNE     loc_D3DC                                ; branche vers loc_D3DC si la condition NE est vraie ; @ D3CC: 26 0E
        LDAB    DP_0047                                 ; @ D3CE: D6 47
        ANDB    #$9F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D3D0: C4 9F
        STAB    DP_0047                                 ; @ D3D2: D7 47
        LDAB    DP_0045                                 ; @ D3D4: D6 45
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D3D6: CA 40
        STAB    DP_0045                                 ; @ D3D8: D7 45
        BRA     loc_D3E8                                ; branche toujours vers loc_D3E8 ; @ D3DA: 20 0C
loc_D3DC:
        LDAB    DP_0045                                 ; @ D3DC: D6 45
        ANDB    #$9F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D3DE: C4 9F
        STAB    DP_0045                                 ; @ D3E0: D7 45
        LDAB    DP_0047                                 ; @ D3E2: D6 47
        ORAB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D3E4: CA 40
        STAB    DP_0047                                 ; @ D3E6: D7 47
loc_D3E8:
        LDAB    #$01                                    ; @ D3E8: C6 01
        STAB    RAM_8003                                ; @ D3EA: F7 80 03
        JSR     sub_CB28                                ; appelle sub_CB28 ; @ D3ED: BD CB 28
        JMP     loc_C522                                ; transfert sans retour vers loc_C522 ; @ D3F0: 7E C5 22
loc_D3F3:
        LDAB    DP_0049                                 ; @ D3F3: D6 49
        CMPB    #$87                                    ; @ D3F5: C1 87
        BNE     loc_D3FF                                ; branche vers loc_D3FF si la condition NE est vraie ; @ D3F7: 26 06
        LDAB    #$FF                                    ; @ D3F9: C6 FF
        STAB    DP_0049                                 ; @ D3FB: D7 49
        BRA     loc_D388                                ; branche toujours vers loc_D388 ; @ D3FD: 20 89
loc_D3FF:
        LDAA    DP_0052                                 ; @ D3FF: 96 52
        LDAB    DP_0048                                 ; @ D401: D6 48
        BITB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D403: C5 40
        BEQ     loc_D408                                ; branche vers loc_D408 si la condition EQ est vraie ; @ D405: 27 01
        DECA                                            ; @ D407: 4A
loc_D408:
        LDAB    RAM_8003                                ; @ D408: F6 80 03
        DECB                                            ; @ D40B: 5A
        ABA                                             ; @ D40C: 1B
        BLE     loc_D489                                ; branche vers loc_D489 si la condition LE est vraie ; @ D40D: 2F 7A
        LDX     DP_004B                                 ; @ D40F: DE 4B
        LDAA    $3D,X                                   ; @ D411: A6 3D
        ANDA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D413: 84 07
        CMPA    #$07                                    ; @ D415: 81 07
        BEQ     loc_D486                                ; branche vers loc_D486 si la condition EQ est vraie ; @ D417: 27 6D
        PSHB                                            ; @ D419: 37
        CPX     #DP_0000                                ; @ D41A: 8C 00 00
        BNE     loc_D442                                ; branche vers loc_D442 si la condition NE est vraie ; @ D41D: 26 23
        LDX     DP_0023                                 ; @ D41F: DE 23
        STX     DP_006D                                 ; @ D421: DF 6D
        LDX     DP_0025                                 ; @ D423: DE 25
        STX     DP_006F                                 ; @ D425: DF 6F
        LDAB    DP_0027                                 ; @ D427: D6 27
        STAB    DP_0071                                 ; @ D429: D7 71
        CMPA    #$01                                    ; @ D42B: 81 01
        BEQ     loc_D43B                                ; branche vers loc_D43B si la condition EQ est vraie ; @ D42D: 27 0C
        LDX     DP_000F                                 ; @ D42F: DE 0F
        STX     DP_006D                                 ; @ D431: DF 6D
        LDX     DP_0011                                 ; @ D433: DE 11
        STX     DP_006F                                 ; @ D435: DF 6F
        LDAB    DP_0013                                 ; @ D437: D6 13
        STAB    DP_0071                                 ; @ D439: D7 71
loc_D43B:
        LDAB    #$01                                    ; @ D43B: C6 01
        STAB    RAM_8002                                ; @ D43D: F7 80 02
        BRA     loc_D485                                ; branche toujours vers loc_D485 ; @ D440: 20 43
loc_D442:
        CPX     #DP_0004                                ; @ D442: 8C 00 04
        BNE     loc_D484                                ; branche vers loc_D484 si la condition NE est vraie ; @ D445: 26 3D
        LDAB    DP_0041                                 ; @ D447: D6 41
        ORAB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D449: CA 08
        STAB    DP_0041                                 ; @ D44B: D7 41
        LDX     #DP_002A                                ; @ D44D: CE 00 2A
        CMPA    #$01                                    ; @ D450: 81 01
        BEQ     loc_D457                                ; branche vers loc_D457 si la condition EQ est vraie ; @ D452: 27 03
        LDX     #DP_0016                                ; @ D454: CE 00 16
loc_D457:
        LDAB    ,X                                      ; @ D457: E6 00
        LDAA    $01,X                                   ; @ D459: A6 01
        JSR     sub_CBF1                                ; appelle sub_CBF1 ; @ D45B: BD CB F1
        LDAA    DP_005E                                 ; @ D45E: 96 5E
        ADDA    #$00                                    ; @ D460: 8B 00
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ D462: 19
        STAA    DP_005E                                 ; @ D463: 97 5E
        LDAA    DP_005F                                 ; @ D465: 96 5F
        ADCA    #$86                                    ; @ D467: 89 86
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ D469: 19
        STAA    DP_005F                                 ; @ D46A: 97 5F
        BCS     loc_D471                                ; branche vers loc_D471 si la condition CS est vraie ; @ D46C: 25 03
        JSR     sub_CB2D                                ; appelle sub_CB2D ; @ D46E: BD CB 2D
loc_D471:
        LDX     DP_005E                                 ; @ D471: DE 5E
        STX     DP_006D                                 ; @ D473: DF 6D
        LDX     DP_0060                                 ; @ D475: DE 60
        STX     DP_006F                                 ; @ D477: DF 6F
        LDAA    DP_0062                                 ; @ D479: 96 62
        STAA    DP_0071                                 ; @ D47B: 97 71
        LDAA    #$FF                                    ; @ D47D: 86 FF
        STAA    RAM_8002                                ; @ D47F: B7 80 02
        BRA     loc_D485                                ; branche toujours vers loc_D485 ; @ D482: 20 01
loc_D484:
        NOP                                             ; @ D484: 01
loc_D485:
        PULB                                            ; @ D485: 33
loc_D486:
        STAB    RAM_8003                                ; @ D486: F7 80 03
loc_D489:
        JMP     loc_D59B                                ; transfert sans retour vers loc_D59B ; @ D489: 7E D5 9B
loc_D48C:
        CLRA                                            ; @ D48C: 4F
        CLRB                                            ; @ D48D: 5F
loc_D48E:
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D48E: C4 0F
        TST     >DP_0049                                ; @ D490: 7D 00 49
        BLE     loc_D498                                ; branche vers loc_D498 si la condition LE est vraie ; @ D493: 2F 03
        JMP     loc_DFA9                                ; transfert sans retour vers loc_DFA9 ; @ D495: 7E DF A9
loc_D498:
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D498: 85 04
        BNE     loc_D4D7                                ; branche vers loc_D4D7 si la condition NE est vraie ; @ D49A: 26 3B
        ANDA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D49C: 84 07
        CMPA    #$03                                    ; @ D49E: 81 03
        BNE     loc_D4A9                                ; branche vers loc_D4A9 si la condition NE est vraie ; @ D4A0: 26 07
        LDAA    DP_0049                                 ; @ D4A2: 96 49
        CMPA    #$87                                    ; @ D4A4: 81 87
        BEQ     loc_D4A9                                ; branche vers loc_D4A9 si la condition EQ est vraie ; @ D4A6: 27 01
        RTS                                             ; @ D4A8: 39
loc_D4A9:
        TST     >DP_004C                                ; @ D4A9: 7D 00 4C
        BNE     loc_D4C3                                ; branche vers loc_D4C3 si la condition NE est vraie ; @ D4AC: 26 15
        LDAA    DP_0038                                 ; @ D4AE: 96 38
        CMPA    #$04                                    ; @ D4B0: 81 04
        BNE     loc_D4C3                                ; branche vers loc_D4C3 si la condition NE est vraie ; @ D4B2: 26 0F
        LDX     #DP_0000                                ; @ D4B4: CE 00 00
        STX     DP_0037                                 ; @ D4B7: DF 37
        LDAA    RAM_8022                                ; @ D4B9: B6 80 22
        ORAA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D4BC: 8A 01
        STAA    RAM_8022                                ; @ D4BE: B7 80 22
        STAA    DP_003C                                 ; @ D4C1: 97 3C
loc_D4C3:
        CLRA                                            ; @ D4C3: 4F
        LDX     #DP_0000                                ; @ D4C4: CE 00 00
        STX     DP_006E                                 ; @ D4C7: DF 6E
        STX     DP_0070                                 ; @ D4C9: DF 70
        STAA    RAM_8004                                ; @ D4CB: B7 80 04
        STAA    DP_006D                                 ; @ D4CE: 97 6D
        INCA                                            ; @ D4D0: 4C
        STAA    RAM_8003                                ; @ D4D1: B7 80 03
        STAA    RAM_8002                                ; @ D4D4: B7 80 02
loc_D4D7:
        LDAA    DP_0071                                 ; @ D4D7: 96 71
        CMPA    #$99                                    ; @ D4D9: 81 99
        BCC     loc_D48C                                ; branche vers loc_D48C si la condition CC est vraie ; @ D4DB: 24 AF
        CMPB    #$0A                                    ; @ D4DD: C1 0A
        LDAA    RAM_8003                                ; @ D4DF: B6 80 03
        BLE     loc_D51C                                ; branche vers loc_D51C si la condition LE est vraie ; @ D4E2: 2F 38
        LDAA    #$00                                    ; @ D4E4: 86 00
        BCC     loc_D54C                                ; branche vers loc_D54C si la condition CC est vraie ; @ D4E6: 24 64
        LDAA    RAM_8004                                ; @ D4E8: B6 80 04
        CMPA    DP_0052                                 ; @ D4EB: 91 52
        BEQ     loc_D500                                ; branche vers loc_D500 si la condition EQ est vraie ; @ D4ED: 27 11
        LDAA    DP_0071                                 ; @ D4EF: 96 71
        BITA    #$FC                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D4F1: 85 FC
        BNE     loc_D500                                ; branche vers loc_D500 si la condition NE est vraie ; @ D4F3: 26 0B
        TST     >DP_004C                                ; @ D4F5: 7D 00 4C
        BEQ     loc_D51E                                ; branche vers loc_D51E si la condition EQ est vraie ; @ D4F8: 27 24
        LDAA    DP_006E                                 ; @ D4FA: 96 6E
        BITA    #$FE                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D4FC: 85 FE
        BEQ     loc_D51E                                ; branche vers loc_D51E si la condition EQ est vraie ; @ D4FE: 27 1E
loc_D500:
        LDAA    RAM_8002                                ; @ D500: B6 80 02
        BLE     loc_D51B                                ; branche vers loc_D51B si la condition LE est vraie ; @ D503: 2F 16
loc_D505:
        LDX     DP_004B                                 ; @ D505: DE 4B
        LDAA    #$71                                    ; @ D507: 86 71
        CPX     #DP_0004                                ; @ D509: 8C 00 04
        BNE     loc_D516                                ; branche vers loc_D516 si la condition NE est vraie ; @ D50C: 26 08
        LDAB    $3D,X                                   ; @ D50E: E6 3D
        BITB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D510: C5 08
        BEQ     loc_D516                                ; branche vers loc_D516 si la condition EQ est vraie ; @ D512: 27 02
        LDAA    #$79                                    ; @ D514: 86 79
loc_D516:
        STAA    $3D,X                                   ; @ D516: A7 3D
        JMP     loc_CAE1                                ; transfert sans retour vers loc_CAE1 ; @ D518: 7E CA E1
loc_D51B:
        RTS                                             ; @ D51B: 39
loc_D51C:
        BRA     loc_D566                                ; branche toujours vers loc_D566 ; @ D51C: 20 48
loc_D51E:
        LDX     #DP_0004                                ; @ D51E: CE 00 04
        LDAA    DP_006D                                 ; @ D521: 96 6D
loc_D523:
        ASLA                                            ; @ D523: 48
        ROL     >DP_006E                                ; @ D524: 79 00 6E
        ROL     >DP_006F                                ; @ D527: 79 00 6F
        ROL     >DP_0070                                ; @ D52A: 79 00 70
        ROL     >DP_0071                                ; @ D52D: 79 00 71
        DEX                                             ; @ D530: 09
        BNE     loc_D523                                ; branche vers loc_D523 si la condition NE est vraie ; @ D531: 26 F0
        ABA                                             ; @ D533: 1B
        STAA    DP_006D                                 ; @ D534: 97 6D
        LDAA    RAM_8002                                ; @ D536: B6 80 02
        DECA                                            ; @ D539: 4A
        BNE     loc_D549                                ; branche vers loc_D549 si la condition NE est vraie ; @ D53A: 26 0D
        INCA                                            ; @ D53C: 4C
        LDAB    RAM_8004                                ; @ D53D: F6 80 04
        DECB                                            ; @ D540: 5A
        BNE     loc_D549                                ; branche vers loc_D549 si la condition NE est vraie ; @ D541: 26 06
        LDAB    DP_006D                                 ; @ D543: D6 6D
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D545: C4 F0
        BEQ     loc_D54C                                ; branche vers loc_D54C si la condition EQ est vraie ; @ D547: 27 03
loc_D549:
        INC     RAM_8004                                ; @ D549: 7C 80 04
loc_D54C:
        STAA    RAM_8002                                ; @ D54C: B7 80 02
        LDAB    DP_003C                                 ; @ D54F: D6 3C
        BMI     loc_D554                                ; branche vers loc_D554 si la condition MI est vraie ; @ D551: 2B 01
        RTS                                             ; @ D553: 39
loc_D554:
        LDX     DP_004B                                 ; @ D554: DE 4B
        LDAA    $3D,X                                   ; @ D556: A6 3D
        ORAA    #$47                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D558: 8A 47
        ANDA    #$DF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D55A: 84 DF
        STAA    $3D,X                                   ; @ D55C: A7 3D
        LDAA    #$BF                                    ; @ D55E: 86 BF
        ANDA    DP_004A                                 ; @ D560: 94 4A
        CLRB                                            ; @ D562: 5F
        JMP     loc_C522                                ; transfert sans retour vers loc_C522 ; @ D563: 7E C5 22
loc_D566:
        DECA                                            ; @ D566: 4A
        BCC     loc_D54C                                ; branche vers loc_D54C si la condition CC est vraie ; @ D567: 24 E3
        COMA                                            ; @ D569: 43
        CLR     >DP_005E                                ; @ D56A: 7F 00 5E
        LSRA                                            ; @ D56D: 44
        STAA    DP_005F                                 ; @ D56E: 97 5F
        LDX     DP_005E                                 ; @ D570: DE 5E
        LDAA    #$F0                                    ; @ D572: 86 F0
        BCC     loc_D57C                                ; branche vers loc_D57C si la condition CC est vraie ; @ D574: 24 06
        ASLB                                            ; @ D576: 58
        ASLB                                            ; @ D577: 58
        ASLB                                            ; @ D578: 58
        ASLB                                            ; @ D579: 58
        LDAA    #$0F                                    ; @ D57A: 86 0F
loc_D57C:
        ANDA    $6D,X                                   ; @ D57C: A4 6D
        ABA                                             ; @ D57E: 1B
        STAA    $6D,X                                   ; @ D57F: A7 6D
        LDAB    DP_004C                                 ; @ D581: D6 4C
        BNE     loc_D590                                ; branche vers loc_D590 si la condition NE est vraie ; @ D583: 26 0B
        LDAA    DP_0071                                 ; @ D585: 96 71
        CMPA    #$42                                    ; @ D587: 81 42
        BCC     loc_D58D                                ; branche vers loc_D58D si la condition CC est vraie ; @ D589: 24 02
        BRA     loc_D596                                ; branche toujours vers loc_D596 ; @ D58B: 20 09
loc_D58D:
        JMP     loc_D505                                ; transfert sans retour vers loc_D505 ; @ D58D: 7E D5 05
loc_D590:
        LDAA    DP_006E                                 ; @ D590: 96 6E
        CMPA    #$20                                    ; @ D592: 81 20
        BCC     loc_D58D                                ; branche vers loc_D58D si la condition CC est vraie ; @ D594: 24 F7
loc_D596:
        INC     RAM_8003                                ; @ D596: 7C 80 03
        BGT     loc_D554                                ; branche vers loc_D554 si la condition GT est vraie ; @ D599: 2E B9
loc_D59B:
        LDAB    #$02                                    ; @ D59B: C6 02
        JSR     sub_CB28                                ; appelle sub_CB28 ; @ D59D: BD CB 28
        BRA     loc_D554                                ; branche toujours vers loc_D554 ; @ D5A0: 20 B2
loc_D5A2:
        CMPB    #$20                                    ; @ D5A2: C1 20
        BITA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D5A4: 85 04
        BEQ     loc_D5CA                                ; branche vers loc_D5CA si la condition EQ est vraie ; @ D5A6: 27 22
        BCS     loc_D5B0                                ; branche vers loc_D5B0 si la condition CS est vraie ; @ D5A8: 25 06
loc_D5AA:
        LDAB    RAM_800E                                ; @ D5AA: F6 80 0E
        STAB    DP_003B                                 ; @ D5AD: D7 3B
        CLRB                                            ; @ D5AF: 5F
loc_D5B0:
        LDX     #ROM_DATA_C26C                          ; @ D5B0: CE C2 6C
        PSHA                                            ; @ D5B3: 36
        LDAA    #$01                                    ; @ D5B4: 86 01
        STAA    RAM_8003                                ; @ D5B6: B7 80 03
        LDAA    DP_004C                                 ; @ D5B9: 96 4C
        STX     DP_005E                                 ; @ D5BB: DF 5E
        ADDA    DP_005F                                 ; @ D5BD: 9B 5F
        STAA    DP_005F                                 ; @ D5BF: 97 5F
        LDX     DP_005E                                 ; @ D5C1: DE 5E
        LDX     ,X                                      ; @ D5C3: EE 00
        PULA                                            ; @ D5C5: 32
        CMPB    #$1E                                    ; @ D5C6: C1 1E
        JMP     ,X                                      ; transfert sans retour vers ,X ; @ D5C8: 6E 00
loc_D5CA:
        BCC     loc_D5EF                                ; branche vers loc_D5EF si la condition CC est vraie ; @ D5CA: 24 23
        TST     >DP_004C                                ; @ D5CC: 7D 00 4C
        BEQ     loc_D5E9                                ; branche vers loc_D5E9 si la condition EQ est vraie ; @ D5CF: 27 18
        CMPB    #$1E                                    ; @ D5D1: C1 1E
        LDAB    DP_004C                                 ; @ D5D3: D6 4C
        BITB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D5D5: C5 04
        BEQ     loc_D5E9                                ; branche vers loc_D5E9 si la condition EQ est vraie ; @ D5D7: 27 10
        ORAA    #$58                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D5D9: 8A 58
        BCC     loc_D5E7                                ; branche vers loc_D5E7 si la condition CC est vraie ; @ D5DB: 24 0A
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D5DD: 85 20
        BNE     loc_D5E5                                ; branche vers loc_D5E5 si la condition NE est vraie ; @ D5DF: 26 04
        LDAB    $12,X                                   ; @ D5E1: E6 12
        BMI     loc_D5EA                                ; branche vers loc_D5EA si la condition MI est vraie ; @ D5E3: 2B 05
loc_D5E5:
        ANDA    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D5E5: 84 F7
loc_D5E7:
        STAA    $3D,X                                   ; @ D5E7: A7 3D
loc_D5E9:
        RTS                                             ; @ D5E9: 39
loc_D5EA:
        LDAB    #$27                                    ; @ D5EA: C6 27
        JMP     sub_CAE3                                ; transfert sans retour vers sub_CAE3 ; @ D5EC: 7E CA E3
loc_D5EF:
        CMPB    #$27                                    ; @ D5EF: C1 27
        BNE     loc_D652                                ; branche vers loc_D652 si la condition NE est vraie ; @ D5F1: 26 5F
loc_D5F3:
        LDX     #ROM_DATA_FFF4                          ; @ D5F3: CE FF F4
loc_D5F6:
        LDAA    $49,X                                   ; @ D5F6: A6 49
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D5F8: 85 02
        BEQ     loc_D600                                ; branche vers loc_D600 si la condition EQ est vraie ; @ D5FA: 27 04
        ORAA    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D5FC: 8A C0
        STAA    $49,X                                   ; @ D5FE: A7 49
loc_D600:
        INX                                             ; @ D600: 08
        INX                                             ; @ D601: 08
        BNE     loc_D5F6                                ; branche vers loc_D5F6 si la condition NE est vraie ; @ D602: 26 F2
        LDAA    DP_0021                                 ; @ D604: 96 21
        BITA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D606: 85 10
        BNE     loc_D61C                                ; branche vers loc_D61C si la condition NE est vraie ; @ D608: 26 12
        LDAA    DP_0047                                 ; @ D60A: 96 47
        BITA    #$01                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D60C: 85 01
        BEQ     loc_D616                                ; branche vers loc_D616 si la condition EQ est vraie ; @ D60E: 27 06
        ORAA    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D610: 8A C0
        STAA    DP_0047                                 ; @ D612: 97 47
        BRA     loc_D61C                                ; branche toujours vers loc_D61C ; @ D614: 20 06
loc_D616:
        LDAA    DP_0045                                 ; @ D616: 96 45
        ORAA    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D618: 8A C0
        STAA    DP_0045                                 ; @ D61A: 97 45
loc_D61C:
        LDAA    DP_0049                                 ; @ D61C: 96 49
        ANDA    #$87                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D61E: 84 87
        CMPA    #$87                                    ; @ D620: 81 87
        BNE     loc_D63D                                ; branche vers loc_D63D si la condition NE est vraie ; @ D622: 26 19
        LDAA    DP_004A                                 ; @ D624: 96 4A
        ORAA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D626: 8A 04
        STAA    DP_004A                                 ; @ D628: 97 4A
        STAA    RAM_8025                                ; @ D62A: B7 80 25
        LDAA    DP_0021                                 ; @ D62D: 96 21
        STAA    RAM_8014                                ; @ D62F: B7 80 14
        LDAA    #$FF                                    ; @ D632: 86 FF
        STAA    DP_0049                                 ; @ D634: 97 49
loc_D636:
        LDAA    DP_0022                                 ; @ D636: 96 22
        BPL     loc_D64D                                ; branche vers loc_D64D si la condition PL est vraie ; @ D638: 2A 13
loc_D63A:
        JMP     sub_EC08                                ; transfert sans retour vers sub_EC08 ; @ D63A: 7E EC 08
loc_D63D:
        CMPA    #$84                                    ; @ D63D: 81 84
        BNE     loc_D648                                ; branche vers loc_D648 si la condition NE est vraie ; @ D63F: 26 07
        LDAA    DP_0021                                 ; @ D641: 96 21
        STAA    RAM_8014                                ; @ D643: B7 80 14
        BRA     loc_D636                                ; branche toujours vers loc_D636 ; @ D646: 20 EE
loc_D648:
        LDAA    DP_003C                                 ; @ D648: 96 3C
        BMI     loc_D64C                                ; branche vers loc_D64C si la condition MI est vraie ; @ D64A: 2B 00
loc_D64C:
        RTS                                             ; @ D64C: 39
loc_D64D:
        JSR     sub_DEF7                                ; appelle sub_DEF7 ; @ D64D: BD DE F7
        BRA     loc_D63A                                ; branche toujours vers loc_D63A ; @ D650: 20 E8
loc_D652:
        CMPB    #$26                                    ; @ D652: C1 26
        BEQ     loc_D659                                ; branche vers loc_D659 si la condition EQ est vraie ; @ D654: 27 03
        JMP     loc_D6C0                                ; transfert sans retour vers loc_D6C0 ; @ D656: 7E D6 C0
loc_D659:
        LDAB    DP_004C                                 ; @ D659: D6 4C
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D65B: 85 02
        BEQ     loc_D67F                                ; branche vers loc_D67F si la condition EQ est vraie ; @ D65D: 27 20
        BITB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D65F: C5 04
        BEQ     loc_D6A7                                ; branche vers loc_D6A7 si la condition EQ est vraie ; @ D661: 27 44
        BITA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D663: 85 08
        BEQ     loc_D670                                ; branche vers loc_D670 si la condition EQ est vraie ; @ D665: 27 09
        JSR     sub_CBD8                                ; appelle sub_CBD8 ; @ D667: BD CB D8
        STAA    $04,X                                   ; @ D66A: A7 04
        STAB    $03,X                                   ; @ D66C: E7 03
        BRA     loc_D679                                ; branche toujours vers loc_D679 ; @ D66E: 20 09
loc_D670:
        LDAB    #$27                                    ; @ D670: C6 27
        JSR     sub_CAE3                                ; appelle sub_CAE3 ; @ D672: BD CA E3
        LDAA    $3D,X                                   ; @ D675: A6 3D
        LDAB    DP_004C                                 ; @ D677: D6 4C
loc_D679:
        LDAB    $03,X                                   ; @ D679: E6 03
        LDAA    #$08                                    ; @ D67B: 86 08
loc_D67D:
        BRA     loc_D692                                ; branche toujours vers loc_D692 ; @ D67D: 20 13
loc_D67F:
        BITB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D67F: C5 04
        BNE     loc_D679                                ; branche vers loc_D679 si la condition NE est vraie ; @ D681: 26 F6
        TSTB                                            ; @ D683: 5D
        BNE     loc_D67D                                ; branche vers loc_D67D si la condition NE est vraie ; @ D684: 26 F7
        LDAB    DP_0000                                 ; @ D686: D6 00
        STAB    DP_000F                                 ; @ D688: D7 0F
        LDAB    DP_0001                                 ; @ D68A: D6 01
        STAB    DP_0010                                 ; @ D68C: D7 10
        LDAB    DP_0002                                 ; @ D68E: D6 02
        STAB    DP_0011                                 ; @ D690: D7 11
loc_D692:
        LDAB    $03,X                                   ; @ D692: E6 03
        STAB    $12,X                                   ; @ D694: E7 12
        LDAB    $04,X                                   ; @ D696: E6 04
        STAB    $13,X                                   ; @ D698: E7 13
loc_D69A:
        ANDA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D69A: 84 08
        ORAA    #$51                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D69C: 8A 51
        STAA    $3D,X                                   ; @ D69E: A7 3D
        LDAB    #$FF                                    ; @ D6A0: C6 FF
        STAB    DP_0049                                 ; @ D6A2: D7 49
        JMP     loc_C522                                ; transfert sans retour vers loc_C522 ; @ D6A4: 7E C5 22
loc_D6A7:
        TSTB                                            ; @ D6A7: 5D
        BNE     loc_D6B6                                ; branche vers loc_D6B6 si la condition NE est vraie ; @ D6A8: 26 0C
        LDAB    DP_000F                                 ; @ D6AA: D6 0F
        STAB    DP_0000                                 ; @ D6AC: D7 00
        LDAB    DP_0010                                 ; @ D6AE: D6 10
        STAB    DP_0001                                 ; @ D6B0: D7 01
        LDAB    DP_0011                                 ; @ D6B2: D6 11
        STAB    DP_0002                                 ; @ D6B4: D7 02
loc_D6B6:
        LDAB    $12,X                                   ; @ D6B6: E6 12
        STAB    $03,X                                   ; @ D6B8: E7 03
        LDAB    $13,X                                   ; @ D6BA: E6 13
        STAB    $04,X                                   ; @ D6BC: E7 04
        BRA     loc_D69A                                ; branche toujours vers loc_D69A ; @ D6BE: 20 DA
loc_D6C0:
        BITB    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D6C0: C5 02
        BNE     loc_D6C7                                ; branche vers loc_D6C7 si la condition NE est vraie ; @ D6C2: 26 03
        JMP     loc_DA9C                                ; transfert sans retour vers loc_DA9C ; @ D6C4: 7E DA 9C
loc_D6C7:
        CLR     >DP_0049                                ; @ D6C7: 7F 00 49
        COM     >DP_0049                                ; @ D6CA: 73 00 49
        ORAA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D6CD: 8A 40
        PSHB                                            ; @ D6CF: 37
        LDAB    DP_004C                                 ; @ D6D0: D6 4C
        BITB    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D6D2: C5 04
        BEQ     loc_D6D8                                ; branche vers loc_D6D8 si la condition EQ est vraie ; @ D6D4: 27 02
        ORAA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D6D6: 8A 08
loc_D6D8:
        PULB                                            ; @ D6D8: 33
        STAA    $3D,X                                   ; @ D6D9: A7 3D
        LDAA    $3E,X                                   ; @ D6DB: A6 3E
        SUBB    #$22                                    ; @ D6DD: C0 22
        BNE     loc_D6E7                                ; branche vers loc_D6E7 si la condition NE est vraie ; @ D6DF: 26 06
        EORA    #$80                                    ; @ D6E1: 88 80
        STAA    $3E,X                                   ; @ D6E3: A7 3E
        BRA     loc_D6F5                                ; branche toujours vers loc_D6F5 ; @ D6E5: 20 0E
loc_D6E7:
        TSTA                                            ; @ D6E7: 4D
        BMI     loc_D73B                                ; branche vers loc_D73B si la condition MI est vraie ; @ D6E8: 2B 51
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D6EA: 8A 80
        SUBB    #$08                                    ; @ D6EC: C0 08
        BMI     loc_D73B                                ; branche vers loc_D73B si la condition MI est vraie ; @ D6EE: 2B 4B
        BEQ     loc_D6F4                                ; branche vers loc_D6F4 si la condition EQ est vraie ; @ D6F0: 27 02
        LDAB    #$FE                                    ; @ D6F2: C6 FE
loc_D6F4:
        INCB                                            ; @ D6F4: 5C
loc_D6F5:
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D6F5: 84 0F
        STAA    RAM_8003                                ; @ D6F7: B7 80 03
        NEG     RAM_8003                                ; @ D6FA: 70 80 03
        ABA                                             ; @ D6FD: 1B
        BMI     loc_D71E                                ; branche vers loc_D71E si la condition MI est vraie ; @ D6FE: 2B 1E
        LDAB    DP_0052                                 ; @ D700: D6 52
        DECB                                            ; @ D702: 5A
        CBA                                             ; @ D703: 11
        BGE     loc_D71E                                ; branche vers loc_D71E si la condition GE est vraie ; @ D704: 2C 18
        TSTA                                            ; @ D706: 4D
        BNE     loc_D70E                                ; branche vers loc_D70E si la condition NE est vraie ; @ D707: 26 05
        TST     >DP_004C                                ; @ D709: 7D 00 4C
        BEQ     loc_D71E                                ; branche vers loc_D71E si la condition EQ est vraie ; @ D70C: 27 10
loc_D70E:
        STAA    RAM_8003                                ; @ D70E: B7 80 03
        NEG     RAM_8003                                ; @ D711: 70 80 03
        LDAB    $3E,X                                   ; @ D714: E6 3E
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D716: C4 F0
        ANDA    #$8F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D718: 84 8F
        ABA                                             ; @ D71A: 1B
        STAA    $3E,X                                   ; @ D71B: A7 3E
        ASLA                                            ; @ D71D: 48
loc_D71E:
        LDAB    #$40                                    ; @ D71E: C6 40
        STAB    DP_0037                                 ; @ D720: D7 37
        LDAA    DP_004A                                 ; @ D722: 96 4A
        ANDA    #$DF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D724: 84 DF
        BCC     loc_D72F                                ; branche vers loc_D72F si la condition CC est vraie ; @ D726: 24 07
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D728: 8A 20
        LDAB    #$01                                    ; @ D72A: C6 01
        STAB    RAM_8003                                ; @ D72C: F7 80 03
loc_D72F:
        STAA    DP_004A                                 ; @ D72F: 97 4A
        STAA    RAM_8025                                ; @ D731: B7 80 25
        BCS     loc_D73B                                ; branche vers loc_D73B si la condition CS est vraie ; @ D734: 25 05
        LDAB    #$0A                                    ; @ D736: C6 0A
        JMP     sub_CB28                                ; transfert sans retour vers sub_CB28 ; @ D738: 7E CB 28
loc_D73B:
        LDAA    DP_0038                                 ; @ D73B: 96 38
        ANDA    #$F5                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D73D: 84 F5
        STAA    DP_0038                                 ; @ D73F: 97 38
        LDAA    DP_0037                                 ; @ D741: 96 37
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D743: 84 F0
        STAA    DP_0037                                 ; @ D745: 97 37
        RTS                                             ; @ D747: 39
loc_D748:
        CMPB    #$07                                    ; @ D748: C1 07
        BLE     loc_D74F                                ; branche vers loc_D74F si la condition LE est vraie ; @ D74A: 2F 03
        JMP     loc_D81A                                ; transfert sans retour vers loc_D81A ; @ D74C: 7E D8 1A
loc_D74F:
        CMPB    #$07                                    ; @ D74F: C1 07
        PSHB                                            ; @ D751: 37
        BNE     loc_D755                                ; branche vers loc_D755 si la condition NE est vraie ; @ D752: 26 01
        DECB                                            ; @ D754: 5A
loc_D755:
        DECB                                            ; @ D755: 5A
        ASLB                                            ; @ D756: 58
        CMPB    DP_004C                                 ; @ D757: D1 4C
        BEQ     loc_D7A6                                ; branche vers loc_D7A6 si la condition EQ est vraie ; @ D759: 27 4B
        PSHA                                            ; @ D75B: 36
        LDAA    DP_0038                                 ; @ D75C: 96 38
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D75E: 85 02
        BEQ     loc_D795                                ; branche vers loc_D795 si la condition EQ est vraie ; @ D760: 27 33
        LDAA    #$FD                                    ; @ D762: 86 FD
        ANDA    DP_0038                                 ; @ D764: 94 38
        STAA    DP_0038                                 ; @ D766: 97 38
        LDAA    DP_004C                                 ; @ D768: 96 4C
        SUBA    #$08                                    ; @ D76A: 80 08
        BMI     loc_D772                                ; branche vers loc_D772 si la condition MI est vraie ; @ D76C: 2B 04
        BITB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D76E: C5 08
        BNE     loc_D795                                ; branche vers loc_D795 si la condition NE est vraie ; @ D770: 26 23
loc_D772:
        LDX     #DP_003D                                ; @ D772: CE 00 3D
        LDAA    DP_004C                                 ; @ D775: 96 4C
        BEQ     loc_D78A                                ; branche vers loc_D78A si la condition EQ est vraie ; @ D777: 27 11
        LDX     #DP_0041                                ; @ D779: CE 00 41
        CMPA    #$04                                    ; @ D77C: 81 04
        BEQ     loc_D78A                                ; branche vers loc_D78A si la condition EQ est vraie ; @ D77E: 27 0A
        LDX     #DP_0045                                ; @ D780: CE 00 45
        CMPA    #$08                                    ; @ D783: 81 08
        BEQ     loc_D78A                                ; branche vers loc_D78A si la condition EQ est vraie ; @ D785: 27 03
        LDX     #DP_0047                                ; @ D787: CE 00 47
loc_D78A:
        LDAA    #$40                                    ; @ D78A: 86 40
        ORAA    ,X                                      ; @ D78C: AA 00
        STAA    ,X                                      ; @ D78E: A7 00
        LDAA    #$01                                    ; @ D790: 86 01
        STAA    RAM_8003                                ; @ D792: B7 80 03
loc_D795:
        PULA                                            ; @ D795: 32
        EORA    #$05                                    ; @ D796: 88 05
        STAA    $3D,X                                   ; @ D798: A7 3D
        STAB    DP_004C                                 ; @ D79A: D7 4C
        LDX     DP_004B                                 ; @ D79C: DE 4B
        LDAA    $3D,X                                   ; @ D79E: A6 3D
        LDAB    #$53                                    ; @ D7A0: C6 53
        BITA    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D7A2: 85 02
        BNE     loc_D7A8                                ; branche vers loc_D7A8 si la condition NE est vraie ; @ D7A4: 26 02
loc_D7A6:
        LDAB    #$71                                    ; @ D7A6: C6 71
loc_D7A8:
        ANDA    #$88                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D7A8: 84 88
        ABA                                             ; @ D7AA: 1B
        LDAB    DP_0049                                 ; @ D7AB: D6 49
        BEQ     loc_D7C3                                ; branche vers loc_D7C3 si la condition EQ est vraie ; @ D7AD: 27 14
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D7AF: 85 20
        BNE     loc_D7B7                                ; branche vers loc_D7B7 si la condition NE est vraie ; @ D7B1: 26 04
        ANDB    #$87                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D7B3: C4 87
        CMPB    #$87                                    ; @ D7B5: C1 87
loc_D7B7:
        BEQ     loc_D7C3                                ; branche vers loc_D7C3 si la condition EQ est vraie ; @ D7B7: 27 0A
        LDAB    #$40                                    ; @ D7B9: C6 40
        ORAB    DP_003D                                 ; @ D7BB: DA 3D
        STAB    DP_003D                                 ; @ D7BD: D7 3D
        LDAB    #$FF                                    ; @ D7BF: C6 FF
        STAB    DP_0049                                 ; @ D7C1: D7 49
loc_D7C3:
        PULB                                            ; @ D7C3: 33
        CMPB    #$06                                    ; @ D7C4: C1 06
        BMI     loc_D7D0                                ; branche vers loc_D7D0 si la condition MI est vraie ; @ D7C6: 2B 08
        ANDA    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D7C8: 84 F7
        CMPB    #$06                                    ; @ D7CA: C1 06
        BNE     loc_D7D0                                ; branche vers loc_D7D0 si la condition NE est vraie ; @ D7CC: 26 02
        ORAA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D7CE: 8A 08
loc_D7D0:
        STAA    $3D,X                                   ; @ D7D0: A7 3D
        LDAA    #$FF                                    ; @ D7D2: 86 FF
        CLC                                             ; @ D7D4: 0C
loc_D7D5:
        ROLA                                            ; @ D7D5: 49
        DECB                                            ; @ D7D6: 5A
        BPL     loc_D7D5                                ; branche vers loc_D7D5 si la condition PL est vraie ; @ D7D7: 2A FC
        STAA    RAM_8023                                ; @ D7D9: B7 80 23
        LDAB    DP_004C                                 ; @ D7DC: D6 4C
        BITB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D7DE: C5 08
        BEQ     loc_D7F5                                ; branche vers loc_D7F5 si la condition EQ est vraie ; @ D7E0: 27 13
        LDAB    #$10                                    ; @ D7E2: C6 10
        ASLA                                            ; @ D7E4: 48
        BCC     loc_D7E8                                ; branche vers loc_D7E8 si la condition CC est vraie ; @ D7E5: 24 01
        CLRB                                            ; @ D7E7: 5F
loc_D7E8:
        LDAA    DP_0030                                 ; @ D7E8: 96 30
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D7EA: 84 0F
        BNE     loc_D7F5                                ; branche vers loc_D7F5 si la condition NE est vraie ; @ D7EC: 26 07
        TST     >DP_0031                                ; @ D7EE: 7D 00 31
        BNE     loc_D7F5                                ; branche vers loc_D7F5 si la condition NE est vraie ; @ D7F1: 26 02
        STAB    DP_0030                                 ; @ D7F3: D7 30
loc_D7F5:
        LDAA    #$C0                                    ; @ D7F5: 86 C0
        ORAA    DP_0037                                 ; @ D7F7: 9A 37
        STAA    DP_0037                                 ; @ D7F9: 97 37
        LDAA    #$0A                                    ; @ D7FB: 86 0A
        LDAB    DP_004C                                 ; @ D7FD: D6 4C
        BEQ     loc_D809                                ; branche vers loc_D809 si la condition EQ est vraie ; @ D7FF: 27 08
        LDAA    #$03                                    ; @ D801: 86 03
        CMPB    #$08                                    ; @ D803: C1 08
        BEQ     loc_D809                                ; branche vers loc_D809 si la condition EQ est vraie ; @ D805: 27 02
        LDAA    #$04                                    ; @ D807: 86 04
loc_D809:
        STAA    DP_0052                                 ; @ D809: 97 52
        LDAA    DP_004A                                 ; @ D80B: 96 4A
        ANDA    #$DF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D80D: 84 DF
        LDAB    $3E,X                                   ; @ D80F: E6 3E
        BPL     loc_D815                                ; branche vers loc_D815 si la condition PL est vraie ; @ D811: 2A 02
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D813: 8A 20
loc_D815:
        STAA    DP_004A                                 ; @ D815: 97 4A
        JMP     loc_C522                                ; transfert sans retour vers loc_C522 ; @ D817: 7E C5 22
loc_D81A:
        LDX     DP_004B                                 ; @ D81A: DE 4B
        LDAA    $3D,X                                   ; @ D81C: A6 3D
        ANDA    #$BF                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D81E: 84 BF
        STAA    $3D,X                                   ; @ D820: A7 3D
        SUBB    #$07                                    ; @ D822: C0 07
        STAB    DP_0049                                 ; @ D824: D7 49
        LDAA    #$5E                                    ; @ D826: 86 5E
        STAA    RAM_801B                                ; @ D828: B7 80 1B
        CLRA                                            ; @ D82B: 4F
        STAA    DP_005D                                 ; @ D82C: 97 5D
        DECA                                            ; @ D82E: 4A
        STAA    RAM_8018                                ; @ D82F: B7 80 18
        STAA    RAM_8019                                ; @ D832: B7 80 19
        STAA    RAM_801A                                ; @ D835: B7 80 1A
        STAA    RAM_801C                                ; @ D838: B7 80 1C
        BITB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D83B: C5 08
        BNE     loc_D890                                ; branche vers loc_D890 si la condition NE est vraie ; @ D83D: 26 51
        PSHA                                            ; @ D83F: 36
        LDAA    #$EA                                    ; @ D840: 86 EA
        STAA    RAM_801B                                ; @ D842: B7 80 1B
        PULA                                            ; @ D845: 32
        BITB    #$02                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D846: C5 02
        BNE     loc_D882                                ; branche vers loc_D882 si la condition NE est vraie ; @ D848: 26 38
        PSHA                                            ; @ D84A: 36
        LDAB    #$AA                                    ; @ D84B: C6 AA
        STAB    RAM_801A                                ; @ D84D: F7 80 1A
        LDX     #DP_0000                                ; @ D850: CE 00 00
        LDAB    RAM_800A                                ; @ D853: F6 80 0A
        CMPB    #$9A                                    ; @ D856: C1 9A
        BCS     loc_D85D                                ; branche vers loc_D85D si la condition CS est vraie ; @ D858: 25 03
        LDX     #ROM_DATA_FFFF                          ; @ D85A: CE FF FF
loc_D85D:
        LDAA    RAM_800B                                ; @ D85D: B6 80 0B
        CMPA    #$9A                                    ; @ D860: 81 9A
        BCS     loc_D867                                ; branche vers loc_D867 si la condition CS est vraie ; @ D862: 25 03
        LDX     #ROM_DATA_FFFF                          ; @ D864: CE FF FF
loc_D867:
        STAB    RAM_8019                                ; @ D867: F7 80 19
        STAA    RAM_801B                                ; @ D86A: B7 80 1B
        CPX     #DP_0000                                ; @ D86D: 8C 00 00
        BEQ     loc_D87A                                ; branche vers loc_D87A si la condition EQ est vraie ; @ D870: 27 08
        STX     RAM_8018                                ; @ D872: FF 80 18
        STX     RAM_801B                                ; @ D875: FF 80 1B
        STX     DP_001E                                 ; @ D878: DF 1E
loc_D87A:
        LDAB    #$80                                    ; @ D87A: C6 80
        JSR     sub_CB28                                ; appelle sub_CB28 ; @ D87C: BD CB 28
        PULA                                            ; @ D87F: 32
        SUBA    #$04                                    ; @ D880: 80 04
loc_D882:
        SUBA    #$04                                    ; @ D882: 80 04
        LDAB    DP_004A                                 ; @ D884: D6 4A
        ANDB    #$60                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D886: C4 60
        ANDA    #$9F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ D888: 84 9F
        ABA                                             ; @ D88A: 1B
        STAA    DP_004A                                 ; @ D88B: 97 4A
        STAA    RAM_8025                                ; @ D88D: B7 80 25
loc_D890:
        LDAA    #$F0                                    ; @ D890: 86 F0
        ORAA    DP_0037                                 ; @ D892: 9A 37
        STAA    DP_0037                                 ; @ D894: 97 37
        RTS                                             ; @ D896: 39
        FCB     $25,$01,$39,$4F,$5D,$27,$0A,$C1         ; données '%.9O]'..' ; @ D897: 25 01 39 4F 5D 27 0A C1
        FCB     $1C,$2E,$06,$27,$02,$8B,$03,$8B         ; données '...'....' ; @ D89F: 1C 2E 06 27 02 8B 03 8B
        FCB     $03,$5F,$37,$F6,$80,$02,$2A,$01         ; données '._7...*.' ; @ D8A7: 03 5F 37 F6 80 02 2A 01
        FCB     $1B,$16,$BD,$CA,$10,$86,$21,$C6         ; données '......!.' ; @ D8AF: 1B 16 BD CA 10 86 21 C6
        FCB     $43,$24,$05,$BD,$CA,$E9,$C6,$31         ; données 'C$.....1' ; @ D8B7: 43 24 05 BD CA E9 C6 31
        FCB     $D7,$3D,$96,$6D,$D6,$3B,$C1,$61         ; données '.=.m.;.a' ; @ D8BF: D7 3D 96 6D D6 3B C1 61
        FCB     $27,$02,$84,$F0,$97,$6D,$96,$71         ; données ''....m.q' ; @ D8C7: 27 02 84 F0 97 6D 96 71
        FCB     $97,$13,$DE,$6D,$DF,$0F,$DE,$6F         ; données '...m...o' ; @ D8CF: 97 13 DE 6D DF 0F DE 6F
        FCB     $DF,$11,$33,$7E,$C5,$22,$D6,$47         ; données '..3~.".G' ; @ D8D7: DF 11 33 7E C5 22 D6 47
        FCB     $C5,$08,$26,$01,$4A,$5F,$20,$0F         ; données '..&.J_ .' ; @ D8DF: C5 08 26 01 4A 5F 20 0F
        FCB     $25,$01,$39,$C1,$01,$25,$08,$84         ; données '%.9..%..' ; @ D8E7: 25 01 39 C1 01 25 08 84
        FCB     $08,$27,$08,$C1,$1D,$26,$F3,$86         ; données '.'...&..' ; @ D8EF: 08 27 08 C1 1D 26 F3 86
        FCB     $02,$20,$02,$86,$FF,$CE,$99,$19         ; données '. ......' ; @ D8F7: 02 20 02 86 FF CE 99 19
        FCB     $BD,$CA,$9C,$DF,$1C,$96,$47,$85         ; données '......G.' ; @ D8FF: BD CA 9C DF 1C 96 47 85
        FCB     $08,$26,$08,$96,$72,$8B,$10,$97         ; données '.&..r...' ; @ D907: 08 26 08 96 72 8B 10 97
        FCB     $1C,$C0,$01,$86,$53,$5D,$2F,$05         ; données '....S]/.' ; @ D90F: 1C C0 01 86 53 5D 2F 05
        FCB     $BD,$CA,$E1,$86,$71,$D6,$47,$C4         ; données '....q.G.' ; @ D917: BD CA E1 86 71 D6 47 C4
        FCB     $08,$1B,$97,$47,$7E,$C5,$22,$5F         ; données '...G~."_' ; @ D91F: 08 1B 97 47 7E C5 22 5F
        FCB     $20,$08,$5D,$27,$05,$C1,$1B,$27         ; données ' .]'...'' ; @ D927: 20 08 5D 27 05 C1 1B 27
        FCB     $01,$39,$86,$01,$5F,$CE,$99,$09         ; données '.9.._...' ; @ D92F: 01 39 86 01 5F CE 99 09
        FCB     $BD,$CA,$9C,$86,$53,$5D,$27,$05         ; données '....S]'.' ; @ D937: BD CA 9C 86 53 5D 27 05
        FCB     $BD,$CA,$E1,$86,$71,$97,$45,$DF         ; données '....q.E.' ; @ D93F: BD CA E1 86 71 97 45 DF
        FCB     $1A,$7E,$C5,$22,$58,$58,$58,$D6         ; données '.~."XXX.' ; @ D947: 1A 7E C5 22 58 58 58 D6
        FCB     $41,$C4,$08,$26,$04,$8B,$07,$20         ; données 'A..&... ' ; @ D94F: 41 C4 08 26 04 8B 07 20
        FCB     $1E,$DE,$57,$C6,$1E,$24,$02,$C6         ; données '..W..$..' ; @ D957: 1E DE 57 C6 1E 24 02 C6
        FCB     $1F,$20,$62,$8A,$80,$DE,$57,$25         ; données '. b...W%' ; @ D95F: 1F 20 62 8A 80 DE 57 25
        FCB     $03,$7E,$D9,$C3,$5D,$26,$06,$C6         ; données '.~..]&..' ; @ D967: 03 7E D9 C3 5D 26 06 C6
        FCB     $1E,$85,$08,$26,$4F,$86,$04,$CE         ; données '...&O...' ; @ D96F: 1E 85 08 26 4F 86 04 CE
        FCB     $40,$22,$BD,$CA,$9C,$97,$72,$CE         ; données '@"....r.' ; @ D977: 40 22 BD CA 9C 97 72 CE
        FCB     $C1,$18,$86,$C7,$90,$73,$86,$02         ; données '.....s..' ; @ D97F: C1 18 86 C7 90 73 86 02
        FCB     $92,$72,$24,$03,$CE,$C1,$E0,$59         ; données '.r$....Y' ; @ D987: 92 72 24 03 CE C1 E0 59
        FCB     $37,$86,$64,$D6,$73,$E0,$01,$D6         ; données '7.d.s...' ; @ D98F: 37 86 64 D6 73 E0 01 D6
        FCB     $72,$E2,$00,$24,$0E,$09,$09,$4A         ; données 'r..$...J' ; @ D997: 72 E2 00 24 0E 09 09 4A
        FCB     $2A,$F1,$C6,$22,$BD,$CA,$E3,$DE         ; données '*.."....' ; @ D99F: 2A F1 C6 22 BD CA E3 DE
        FCB     $4B,$20,$12,$DE,$4B,$33,$0C,$BD         ; données 'K ..K3..' ; @ D9A7: 4B 20 12 DE 4B 33 0C BD
        FCB     $CB,$40,$24,$09,$A7,$13,$E7,$12         ; données '.@$.....' ; @ D9AF: CB 40 24 09 A7 13 E7 12
        FCB     $86,$53,$A7,$3D,$39,$86,$71,$A7         ; données '.S.=9.q.' ; @ D9B7: 86 53 A7 3D 39 86 71 A7
        FCB     $3D,$7E,$C5,$22,$4F,$DF,$5E,$37         ; données '=~."O.^7' ; @ D9BF: 3D 7E C5 22 4F DF 5E 37
        FCB     $01,$01,$F6,$80,$02,$2A,$01,$1B         ; données '.....*..' ; @ D9C7: 01 01 F6 80 02 2A 01 1B
        FCB     $16,$5C,$C1,$06,$2A,$09,$BD,$CA         ; données '.\..*...' ; @ D9CF: 16 5C C1 06 2A 09 BD CA
        FCB     $10,$DE,$4B,$96,$6F,$27,$0F,$33         ; données '..K.o'.3' ; @ D9D7: 10 DE 4B 96 6F 27 0F 33
        FCB     $C1,$1F,$26,$03,$7E,$DA,$50,$86         ; données '..&.~.P.' ; @ D9DF: C1 1F 26 03 7E DA 50 86
        FCB     $79,$A7,$3D,$7E,$CA,$E1,$96,$6E         ; données 'y.=~...n' ; @ D9E7: 79 A7 3D 7E CA E1 96 6E
        FCB     $C6,$14,$10,$25,$08,$26,$E8,$96         ; données '...%.&..' ; @ D9EF: C6 14 10 25 08 26 E8 96
        FCB     $6D,$81,$30,$2C,$E2,$33,$C0,$1F         ; données 'm.0,.3..' ; @ D9F7: 6D 81 30 2C E2 33 C0 1F
        FCB     $27,$03,$BD,$CB,$2D,$96,$6D,$9B         ; données ''...-.m.' ; @ D9FF: 27 03 BD CB 2D 96 6D 9B
        FCB     $5E,$19,$97,$5E,$96,$6E,$99,$5F         ; données '^..^.n._' ; @ DA07: 5E 19 97 5E 96 6E 99 5F
        FCB     $19,$97,$5F,$5D,$26,$03,$BD,$CB         ; données '.._]&...' ; @ DA0F: 19 97 5F 5D 26 03 BD CB
        FCB     $2D,$96,$5F,$2B,$34,$27,$32,$81         ; données '-._+4'2.' ; @ DA17: 2D 96 5F 2B 34 27 32 81
        FCB     $01,$26,$04,$96,$5E,$27,$2A,$96         ; données '.&..^'*.' ; @ DA1F: 01 26 04 96 5E 27 2A 96
        FCB     $5F,$16,$C4,$F0,$54,$54,$10,$54         ; données '_...TT.T' ; @ DA27: 5F 16 C4 F0 54 54 10 54
        FCB     $10,$36,$96,$5E,$16,$C4,$F0,$54         ; données '.6.^...T' ; @ DA2F: 10 36 96 5E 16 C4 F0 54
        FCB     $54,$10,$54,$10,$C6,$5B,$DE,$4B         ; données 'T.T..[.K' ; @ DA37: 54 10 54 10 C6 5B DE 4B
        FCB     $E7,$3D,$33,$5D,$27,$06,$4D,$26         ; données '.=3]'.M&' ; @ DA3F: E7 3D 33 5D 27 06 4D 26
        FCB     $03,$5A,$8B,$64,$A7,$13,$E7,$12         ; données '.Z.d....' ; @ DA47: 03 5A 8B 64 A7 13 E7 12
        FCB     $39,$C6,$79,$DE,$4B,$E7,$3D,$C6         ; données '9.y.K.=.' ; @ DA4F: 39 C6 79 DE 4B E7 3D C6
        FCB     $22,$7E,$CA,$E3                         ; données '"~..' ; @ DA57: 22 7E CA E3

; ---------------------------------------------------------------------------
; ROUTINE $DA5B — sub_DA5B
; INCONNU — sous-routine interne à $DA5B; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $C61E. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_DA5B:
        CLR     >DP_003B                                ; @ DA5B: 7F 00 3B
        LDX     DP_004B                                 ; @ DA5E: DE 4B
        LDAA    $3E,X                                   ; @ DA60: A6 3E
        BPL     loc_DA65                                ; branche vers loc_DA65 si la condition PL est vraie ; @ DA62: 2A 01
        RTS                                             ; @ DA64: 39
loc_DA65:
        LDAA    $3D,X                                   ; @ DA65: A6 3D
        ANDA    #$07                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DA67: 84 07
        CMPA    #$07                                    ; @ DA69: 81 07
        BNE     loc_DA73                                ; branche vers loc_DA73 si la condition NE est vraie ; @ DA6B: 26 06
        LDAA    $3D,X                                   ; @ DA6D: A6 3D
        CLRB                                            ; @ DA6F: 5F
        JMP     loc_D5B0                                ; transfert sans retour vers loc_D5B0 ; @ DA70: 7E D5 B0
loc_DA73:
        LDAA    $3E,X                                   ; @ DA73: A6 3E
        ANDB    #$C0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DA75: C4 C0
        ASLB                                            ; @ DA77: 58
        BMI     loc_DA7C                                ; branche vers loc_DA7C si la condition MI est vraie ; @ DA78: 2B 02
        LDAB    #$81                                    ; @ DA7A: C6 81
loc_DA7C:
        CPX     #DP_0000                                ; @ DA7C: 8C 00 00
        BNE     loc_DA99                                ; branche vers loc_DA99 si la condition NE est vraie ; @ DA7F: 26 18
        STX     DP_005E                                 ; @ DA81: DF 5E
        STX     DP_0060                                 ; @ DA83: DF 60
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DA85: 84 0F
        LSRA                                            ; @ DA87: 44
        STAA    DP_0062                                 ; @ DA88: 97 62
        LDAA    #$01                                    ; @ DA8A: 86 01
        BCC     loc_DA90                                ; branche vers loc_DA90 si la condition CC est vraie ; @ DA8C: 24 02
        LDAA    #$10                                    ; @ DA8E: 86 10
loc_DA90:
        LDX     DP_0061                                 ; @ DA90: DE 61
        CLR     >DP_0062                                ; @ DA92: 7F 00 62
        STAA    $5E,X                                   ; @ DA95: A7 5E
        BRA     loc_DACA                                ; branche toujours vers loc_DACA ; @ DA97: 20 31
loc_DA99:
        JMP     loc_DB60                                ; transfert sans retour vers loc_DB60 ; @ DA99: 7E DB 60
loc_DA9C:
        LDX     DP_004B                                 ; @ DA9C: DE 4B
        BNE     loc_DA99                                ; branche vers loc_DA99 si la condition NE est vraie ; @ DA9E: 26 F9
        LDAA    DP_0049                                 ; @ DAA0: 96 49
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DAA2: 84 0F
        CMPA    #$07                                    ; @ DAA4: 81 07
        BEQ     loc_DABB                                ; branche vers loc_DABB si la condition EQ est vraie ; @ DAA6: 27 13
        CMPA    #$04                                    ; @ DAA8: 81 04
        BNE     loc_DABE                                ; branche vers loc_DABE si la condition NE est vraie ; @ DAAA: 26 12
        LDAA    RAM_800B                                ; @ DAAC: B6 80 0B
        CMPA    #$FF                                    ; @ DAAF: 81 FF
        BNE     loc_DAB7                                ; branche vers loc_DAB7 si la condition NE est vraie ; @ DAB1: 26 04
        STAA    DP_0049                                 ; @ DAB3: 97 49
        BRA     loc_DABE                                ; branche toujours vers loc_DABE ; @ DAB5: 20 07
loc_DAB7:
        LSRB                                            ; @ DAB7: 54
        JMP     loc_F026                                ; transfert sans retour vers loc_F026 ; @ DAB8: 7E F0 26
loc_DABB:
        JMP     loc_DB56                                ; transfert sans retour vers loc_DB56 ; @ DABB: 7E DB 56
loc_DABE:
        LDX     DP_0000                                 ; @ DABE: DE 00
        STX     DP_005E                                 ; @ DAC0: DF 5E
        LDX     DP_0002                                 ; @ DAC2: DE 02
        LDAA    DP_0004                                 ; @ DAC4: 96 04
        STX     DP_0060                                 ; @ DAC6: DF 60
        STAA    DP_0062                                 ; @ DAC8: 97 62
loc_DACA:
        LSRB                                            ; @ DACA: 54
        LDAA    DP_003D                                 ; @ DACB: 96 3D
        BITB    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DACD: C5 40
        BNE     loc_DAD5                                ; branche vers loc_DAD5 si la condition NE est vraie ; @ DACF: 26 04
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DAD1: 8A 20
        STAA    DP_003D                                 ; @ DAD3: 97 3D
loc_DAD5:
        LDX     #DP_000F                                ; @ DAD5: CE 00 0F
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DAD8: 85 20
        BEQ     loc_DADF                                ; branche vers loc_DADF si la condition EQ est vraie ; @ DADA: 27 03
        LDX     #DP_0023                                ; @ DADC: CE 00 23
loc_DADF:
        PSHB                                            ; @ DADF: 37
        LDAB    #$05                                    ; @ DAE0: C6 05
loc_DAE2:
        LDAA    $04,X                                   ; @ DAE2: A6 04
        PSHA                                            ; @ DAE4: 36
        DEX                                             ; @ DAE5: 09
        DECB                                            ; @ DAE6: 5A
        BNE     loc_DAE2                                ; branche vers loc_DAE2 si la condition NE est vraie ; @ DAE7: 26 F9
        LDAA    #$21                                    ; @ DAE9: 86 21
        BCC     loc_DAFC                                ; branche vers loc_DAFC si la condition CC est vraie ; @ DAEB: 24 0F
        LDX     #ROM_DATA_FFFB                          ; @ DAED: CE FF FB
loc_DAF0:
        LDAA    #$99                                    ; @ DAF0: 86 99
        SUBA    $63,X                                   ; @ DAF2: A0 63
        STAA    $63,X                                   ; @ DAF4: A7 63
        INX                                             ; @ DAF6: 08
        BNE     loc_DAF0                                ; branche vers loc_DAF0 si la condition NE est vraie ; @ DAF7: 26 F7
        SEC                                             ; @ DAF9: 0D
        LDAA    #$22                                    ; @ DAFA: 86 22
loc_DAFC:
        STAA    DP_0072                                 ; @ DAFC: 97 72
        LDX     #ROM_DATA_FFFB                          ; @ DAFE: CE FF FB
loc_DB01:
        PULA                                            ; @ DB01: 32
        ADCA    $63,X                                   ; @ DB02: A9 63
        DAA                                             ; ajuste A après une opération arithmétique BCD ; @ DB04: 19
        STAA    $63,X                                   ; @ DB05: A7 63
        INX                                             ; @ DB07: 08
        BNE     loc_DB01                                ; branche vers loc_DB01 si la condition NE est vraie ; @ DB08: 26 F7
        LDAA    DP_003D                                 ; @ DB0A: 96 3D
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB0C: 85 20
        BNE     loc_DB1E                                ; branche vers loc_DB1E si la condition NE est vraie ; @ DB0E: 26 0E
        LDX     #ROM_DATA_CC36                          ; @ DB10: CE CC 36
        JSR     sub_CC3B                                ; appelle sub_CC3B ; @ DB13: BD CC 3B
        BCC     loc_DB1B                                ; branche vers loc_DB1B si la condition CC est vraie ; @ DB16: 24 03
        CLC                                             ; @ DB18: 0C
        BRA     loc_DB21                                ; branche toujours vers loc_DB21 ; @ DB19: 20 06
loc_DB1B:
        SEC                                             ; @ DB1B: 0D
        BRA     loc_DB21                                ; branche toujours vers loc_DB21 ; @ DB1C: 20 03
loc_DB1E:
        JSR     sub_CC58                                ; appelle sub_CC58 ; @ DB1E: BD CC 58
loc_DB21:
        PULB                                            ; @ DB21: 33
        BCC     loc_DB33                                ; branche vers loc_DB33 si la condition CC est vraie ; @ DB22: 24 0F
        ROLB                                            ; @ DB24: 59
        BPL     loc_DB30                                ; branche vers loc_DB30 si la condition PL est vraie ; @ DB25: 2A 09
        LDAA    DP_003D                                 ; @ DB27: 96 3D
        ORAA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB29: 8A 40
        STAA    DP_003D                                 ; @ DB2B: 97 3D
        JMP     loc_C5A4                                ; transfert sans retour vers loc_C5A4 ; @ DB2D: 7E C5 A4
loc_DB30:
        JMP     sub_CAE9                                ; transfert sans retour vers sub_CAE9 ; @ DB30: 7E CA E9
loc_DB33:
        LDX     DP_005E                                 ; @ DB33: DE 5E
        STX     DP_000F                                 ; @ DB35: DF 0F
        LDX     DP_0060                                 ; @ DB37: DE 60
        STX     DP_0011                                 ; @ DB39: DF 11
        LDAA    DP_0062                                 ; @ DB3B: 96 62
        STAA    DP_0013                                 ; @ DB3D: 97 13
        LDAA    #$F3                                    ; @ DB3F: 86 F3
        LDX     #DP_0000                                ; @ DB41: CE 00 00
loc_DB44:
        LDAB    $3D,X                                   ; @ DB44: E6 3D
        BITB    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB46: C5 20
        BEQ     loc_DB4F                                ; branche vers loc_DB4F si la condition EQ est vraie ; @ DB48: 27 05
        STAA    $3D,X                                   ; @ DB4A: A7 3D
        JMP     loc_C522                                ; transfert sans retour vers loc_C522 ; @ DB4C: 7E C5 22
loc_DB4F:
        ANDA    #$5B                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB4F: 84 5B
        STAA    $3D,X                                   ; @ DB51: A7 3D
        JMP     loc_C522                                ; transfert sans retour vers loc_C522 ; @ DB53: 7E C5 22
loc_DB56:
        LDAA    DP_005D                                 ; @ DB56: 96 5D
        CMPA    #$FF                                    ; @ DB58: 81 FF
        BEQ     loc_DB7F                                ; branche vers loc_DB7F si la condition EQ est vraie ; @ DB5A: 27 23
        LSRB                                            ; @ DB5C: 54
        JMP     loc_E0B1                                ; transfert sans retour vers loc_E0B1 ; @ DB5D: 7E E0 B1
loc_DB60:
        BITB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB60: C5 80
        BNE     loc_DB7F                                ; branche vers loc_DB7F si la condition NE est vraie ; @ DB62: 26 1B
        LDAA    DP_0049                                 ; @ DB64: 96 49
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB66: 84 0F
        CMPA    #$07                                    ; @ DB68: 81 07
        BEQ     loc_DB56                                ; branche vers loc_DB56 si la condition EQ est vraie ; @ DB6A: 27 EA
        CMPA    #$04                                    ; @ DB6C: 81 04
        BNE     loc_DB7F                                ; branche vers loc_DB7F si la condition NE est vraie ; @ DB6E: 26 0F
        LDAA    RAM_800A                                ; @ DB70: B6 80 0A
        CMPA    #$FF                                    ; @ DB73: 81 FF
        BNE     loc_DB7B                                ; branche vers loc_DB7B si la condition NE est vraie ; @ DB75: 26 04
        STAA    DP_0049                                 ; @ DB77: 97 49
        BRA     loc_DB7F                                ; branche toujours vers loc_DB7F ; @ DB79: 20 04
loc_DB7B:
        LSRB                                            ; @ DB7B: 54
        JMP     loc_F026                                ; transfert sans retour vers loc_F026 ; @ DB7C: 7E F0 26
loc_DB7F:
        LDAA    DP_004C                                 ; @ DB7F: 96 4C
        CMPA    #$04                                    ; @ DB81: 81 04
        BEQ     loc_DB95                                ; branche vers loc_DB95 si la condition EQ est vraie ; @ DB83: 27 10
        LDAA    RAM_8025                                ; @ DB85: B6 80 25
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB88: 85 40
        BEQ     loc_DB95                                ; branche vers loc_DB95 si la condition EQ est vraie ; @ DB8A: 27 09
        LDAA    DP_0021                                 ; @ DB8C: 96 21
        BITA    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB8E: 85 10
        BNE     loc_DB95                                ; branche vers loc_DB95 si la condition NE est vraie ; @ DB90: 26 03
        JMP     loc_C5A4                                ; transfert sans retour vers loc_C5A4 ; @ DB92: 7E C5 A4
loc_DB95:
        STX     RAM_8005                                ; @ DB95: FF 80 05
        LDAA    RAM_8006                                ; @ DB98: B6 80 06
        ANDA    #$04                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DB9B: 84 04
        ADDA    #$FF                                    ; @ DB9D: 8B FF
        PSHB                                            ; @ DB9F: 37
        LDAA    $3D,X                                   ; @ DBA0: A6 3D
        BITB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DBA2: C5 80
        BNE     loc_DBAA                                ; branche vers loc_DBAA si la condition NE est vraie ; @ DBA4: 26 04
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DBA6: 8A 20
        STAA    $3D,X                                   ; @ DBA8: A7 3D
loc_DBAA:
        BITA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DBAA: 85 20
        BNE     loc_DBB4                                ; branche vers loc_DBB4 si la condition NE est vraie ; @ DBAC: 26 06
        LDAA    $13,X                                   ; @ DBAE: A6 13
        LDAB    $12,X                                   ; @ DBB0: E6 12
        BRA     loc_DBB8                                ; branche toujours vers loc_DBB8 ; @ DBB2: 20 04
loc_DBB4:
        LDAA    $27,X                                   ; @ DBB4: A6 27
        LDAB    $26,X                                   ; @ DBB6: E6 26
loc_DBB8:
        BCC     loc_DBBF                                ; branche vers loc_DBBF si la condition CC est vraie ; @ DBB8: 24 05
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DBBA: C4 7F
        JMP     loc_DCF7                                ; transfert sans retour vers loc_DCF7 ; @ DBBC: 7E DC F7
loc_DBBF:
        STAA    DP_005F                                 ; @ DBBF: 97 5F
        TBA                                             ; @ DBC1: 17
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DBC2: 84 0F
        STAA    DP_005E                                 ; @ DBC4: 97 5E
        ANDB    #$30                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DBC6: C4 30
        STAB    DP_0062                                 ; @ DBC8: D7 62
        PULA                                            ; @ DBCA: 32
        PSHA                                            ; @ DBCB: 36
        TSTA                                            ; @ DBCC: 4D
        BMI     loc_DBDD                                ; branche vers loc_DBDD si la condition MI est vraie ; @ DBCD: 2B 0E
        LSRA                                            ; @ DBCF: 44
        LDAA    $04,X                                   ; @ DBD0: A6 04
        LDAB    $03,X                                   ; @ DBD2: E6 03
        JSR     sub_CB79                                ; appelle sub_CB79 ; @ DBD4: BD CB 79
        BCC     loc_DC0B                                ; branche vers loc_DC0B si la condition CC est vraie ; @ DBD7: 24 32
        INS                                             ; @ DBD9: 31
        JMP     sub_CAE9                                ; transfert sans retour vers sub_CAE9 ; @ DBDA: 7E CA E9
loc_DBDD:
        LDAA    $3E,X                                   ; @ DBDD: A6 3E
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DBDF: 84 0F
        ASLA                                            ; @ DBE1: 48
        ASLA                                            ; @ DBE2: 48
        ASLA                                            ; @ DBE3: 48
        ASLA                                            ; @ DBE4: 48
        LDX     #DP_0001                                ; @ DBE5: CE 00 01
        TSTA                                            ; @ DBE8: 4D
        BEQ     loc_DC09                                ; branche vers loc_DC09 si la condition EQ est vraie ; @ DBE9: 27 1E
        LDX     #DP_000A                                ; @ DBEB: CE 00 0A
        SUBA    #$10                                    ; @ DBEE: 80 10
        BEQ     loc_DC09                                ; branche vers loc_DC09 si la condition EQ est vraie ; @ DBF0: 27 17
        LDX     #DP_0064                                ; @ DBF2: CE 00 64
        SUBA    #$10                                    ; @ DBF5: 80 10
        BEQ     loc_DC09                                ; branche vers loc_DC09 si la condition EQ est vraie ; @ DBF7: 27 10
        LDX     #MEM_03E8                               ; @ DBF9: CE 03 E8
        SUBA    #$10                                    ; @ DBFC: 80 10
        BEQ     loc_DC09                                ; branche vers loc_DC09 si la condition EQ est vraie ; @ DBFE: 27 09
        STAA    DP_0062                                 ; @ DC00: 97 62
        STX     DP_0060                                 ; @ DC02: DF 60
        JSR     sub_CB9C                                ; appelle sub_CB9C ; @ DC04: BD CB 9C
        BRA     loc_DC0B                                ; branche toujours vers loc_DC0B ; @ DC07: 20 02
loc_DC09:
        STX     DP_0060                                 ; @ DC09: DF 60
loc_DC0B:
        PULA                                            ; @ DC0B: 32
        PSHA                                            ; @ DC0C: 36
        LSRA                                            ; @ DC0D: 44
        LDAA    DP_005F                                 ; @ DC0E: 96 5F
        BCC     loc_DC15                                ; branche vers loc_DC15 si la condition CC est vraie ; @ DC10: 24 03
        JMP     loc_DCA2                                ; transfert sans retour vers loc_DCA2 ; @ DC12: 7E DC A2
loc_DC15:
        ADDA    DP_0061                                 ; @ DC15: 9B 61
        STAA    DP_0073                                 ; @ DC17: 97 73
        LDAA    DP_005E                                 ; @ DC19: 96 5E
        ADCA    DP_0060                                 ; @ DC1B: 99 60
        STAA    DP_0072                                 ; @ DC1D: 97 72
        STAB    DP_0062                                 ; @ DC1F: D7 62
        CLRA                                            ; @ DC21: 4F
        LDX     #MEM_03E7                               ; @ DC22: CE 03 E7
        LDAB    RAM_8006                                ; @ DC25: F6 80 06
        CMPB    #$08                                    ; @ DC28: C1 08
        BEQ     loc_DC4D                                ; branche vers loc_DC4D si la condition EQ est vraie ; @ DC2A: 27 21
        LDX     #MEM_07CF                               ; @ DC2C: CE 07 CF
        LDAB    DP_0047                                 ; @ DC2F: D6 47
        ORAB    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DC31: CA 08
        LDAA    DP_0062                                 ; @ DC33: 96 62
        BEQ     loc_DC3B                                ; branche vers loc_DC3B si la condition EQ est vraie ; @ DC35: 27 04
        ANDB    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DC37: C4 F7
        LDAA    #$20                                    ; @ DC39: 86 20
loc_DC3B:
        STAB    DP_0047                                 ; @ DC3B: D7 47
        LDAB    DP_004C                                 ; @ DC3D: D6 4C
        CMPB    #$0A                                    ; @ DC3F: C1 0A
        BNE     loc_DC4D                                ; branche vers loc_DC4D si la condition NE est vraie ; @ DC41: 26 0A
        LDAB    #$BF                                    ; @ DC43: C6 BF
        TSTA                                            ; @ DC45: 4D
        BEQ     loc_DC4A                                ; branche vers loc_DC4A si la condition EQ est vraie ; @ DC46: 27 02
        LDAB    #$7F                                    ; @ DC48: C6 7F
loc_DC4A:
        STAB    RAM_8023                                ; @ DC4A: F7 80 23
loc_DC4D:
        STX     DP_005E                                 ; @ DC4D: DF 5E
        LDX     DP_004B                                 ; @ DC4F: DE 4B
        LDAB    DP_005F                                 ; @ DC51: D6 5F
        SUBB    DP_0073                                 ; @ DC53: D0 73
        LDAB    DP_005E                                 ; @ DC55: D6 5E
        SBCB    DP_0072                                 ; @ DC57: D2 72
        BCC     loc_DC7C                                ; branche vers loc_DC7C si la condition CC est vraie ; @ DC59: 24 21
        LDAB    #$21                                    ; @ DC5B: C6 21
        CMPA    DP_0062                                 ; @ DC5D: 91 62
        BLE     loc_DCB0                                ; branche vers loc_DCB0 si la condition LE est vraie ; @ DC5F: 2F 4F
        LDAA    DP_0062                                 ; @ DC61: 96 62
        ADDA    #$10                                    ; @ DC63: 8B 10
        STAA    DP_0062                                 ; @ DC65: 97 62
        LDX     #MEM_1999                               ; @ DC67: CE 19 99
        JSR     sub_C9DD                                ; appelle sub_C9DD ; @ DC6A: BD C9 DD
        ASL     >DP_0076                                ; @ DC6D: 78 00 76
        LDAA    DP_0075                                 ; @ DC70: 96 75
        LDAB    DP_0074                                 ; @ DC72: D6 74
        ADCA    #$00                                    ; @ DC74: 89 00
        ADCB    #$00                                    ; @ DC76: C9 00
        STAA    DP_0073                                 ; @ DC78: 97 73
        STAB    DP_0072                                 ; @ DC7A: D7 72
loc_DC7C:
        LDAB    DP_0062                                 ; @ DC7C: D6 62
loc_DC7E:
        ORAB    DP_0072                                 ; @ DC7E: DA 72
        LDAA    DP_0073                                 ; @ DC80: 96 73
        LDX     RAM_8005                                ; @ DC82: FE 80 05
        STAA    $13,X                                   ; @ DC85: A7 13
        STAB    $12,X                                   ; @ DC87: E7 12
        CPX     #DP_0008                                ; @ DC89: 8C 00 08
        BEQ     loc_DC99                                ; branche vers loc_DC99 si la condition EQ est vraie ; @ DC8C: 27 0B
        LDAA    #$7F                                    ; @ DC8E: 86 7F
        ANDB    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DC90: C4 F0
        BNE     loc_DC96                                ; branche vers loc_DC96 si la condition NE est vraie ; @ DC92: 26 02
        LDAA    #$BF                                    ; @ DC94: 86 BF
loc_DC96:
        STAA    RAM_8023                                ; @ DC96: B7 80 23
loc_DC99:
        LDAA    $3D,X                                   ; @ DC99: A6 3D
        ANDA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DC9B: 84 08
        ORAA    #$F3                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DC9D: 8A F3
        JMP     loc_DB44                                ; transfert sans retour vers loc_DB44 ; @ DC9F: 7E DB 44
loc_DCA2:
        SUBA    DP_0061                                 ; @ DCA2: 90 61
        STAA    DP_0073                                 ; @ DCA4: 97 73
        LDAA    DP_005E                                 ; @ DCA6: 96 5E
        SBCA    DP_0060                                 ; @ DCA8: 92 60
        STAA    DP_0072                                 ; @ DCAA: 97 72
        BCC     loc_DCC3                                ; branche vers loc_DCC3 si la condition CC est vraie ; @ DCAC: 24 15
        LDAB    #$22                                    ; @ DCAE: C6 22
loc_DCB0:
        PULA                                            ; @ DCB0: 32
        TSTA                                            ; @ DCB1: 4D
        BPL     loc_DCBF                                ; branche vers loc_DCBF si la condition PL est vraie ; @ DCB2: 2A 0B
        LDX     DP_004C                                 ; @ DCB4: DE 4C
        LDAA    $3D,X                                   ; @ DCB6: A6 3D
        ORAA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DCB8: 8A 40
        STAA    $3D,X                                   ; @ DCBA: A7 3D
        JMP     loc_C5A4                                ; transfert sans retour vers loc_C5A4 ; @ DCBC: 7E C5 A4
loc_DCBF:
        NOP                                             ; @ DCBF: 01
        JMP     sub_CAE3                                ; transfert sans retour vers sub_CAE3 ; @ DCC0: 7E CA E3
loc_DCC3:
        STAB    DP_0062                                 ; @ DCC3: D7 62
        BEQ     loc_DC7E                                ; branche vers loc_DC7E si la condition EQ est vraie ; @ DCC5: 27 B7
        LDX     #DP_00C7                                ; @ DCC7: CE 00 C7
        STX     DP_005E                                 ; @ DCCA: DF 5E
loc_DCCC:
        LDAA    DP_005F                                 ; @ DCCC: 96 5F
        SUBA    DP_0073                                 ; @ DCCE: 90 73
        LDAA    DP_005E                                 ; @ DCD0: 96 5E
        SBCA    DP_0072                                 ; @ DCD2: 92 72
        BCS     loc_DC7C                                ; branche vers loc_DC7C si la condition CS est vraie ; @ DCD4: 25 A6
        LDAB    DP_0062                                 ; @ DCD6: D6 62
        BEQ     loc_DC7E                                ; branche vers loc_DC7E si la condition EQ est vraie ; @ DCD8: 27 A4
        SUBB    #$10                                    ; @ DCDA: C0 10
        BNE     loc_DCE5                                ; branche vers loc_DCE5 si la condition NE est vraie ; @ DCDC: 26 07
        LDAA    RAM_8006                                ; @ DCDE: B6 80 06
        CMPA    #$0A                                    ; @ DCE1: 81 0A
        BEQ     loc_DC7C                                ; branche vers loc_DC7C si la condition EQ est vraie ; @ DCE3: 27 97
loc_DCE5:
        LDX     #MEM_0A00                               ; @ DCE5: CE 0A 00
        STAB    DP_0062                                 ; @ DCE8: D7 62
        JSR     sub_C9DD                                ; appelle sub_C9DD ; @ DCEA: BD C9 DD
        LDAA    DP_0076                                 ; @ DCED: 96 76
        LDAB    DP_0075                                 ; @ DCEF: D6 75
        STAA    DP_0073                                 ; @ DCF1: 97 73
        STAB    DP_0072                                 ; @ DCF3: D7 72
        BRA     loc_DCCC                                ; branche toujours vers loc_DCCC ; @ DCF5: 20 D5
loc_DCF7:
        PSHA                                            ; @ DCF7: 36
        LDAA    RAM_8025                                ; @ DCF8: B6 80 25
        BITA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DCFB: 85 40
        BEQ     loc_DD09                                ; branche vers loc_DD09 si la condition EQ est vraie ; @ DCFD: 27 0A
        LDAA    RAM_8013                                ; @ DCFF: B6 80 13
        BITA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DD02: 85 80
        BNE     loc_DD09                                ; branche vers loc_DD09 si la condition NE est vraie ; @ DD04: 26 03
        JMP     loc_C5A4                                ; transfert sans retour vers loc_C5A4 ; @ DD06: 7E C5 A4
loc_DD09:
        PULA                                            ; @ DD09: 32
        STAB    DP_0072                                 ; @ DD0A: D7 72
        STAA    DP_0073                                 ; @ DD0C: 97 73
        PULA                                            ; @ DD0E: 32
        PSHA                                            ; @ DD0F: 36
        ASRA                                            ; @ DD10: 47
        BMI     loc_DD1B                                ; branche vers loc_DD1B si la condition MI est vraie ; @ DD11: 2B 08
        LDAA    $04,X                                   ; @ DD13: A6 04
        LDAB    $03,X                                   ; @ DD15: E6 03
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DD17: C4 0F
        BRA     loc_DD2A                                ; branche toujours vers loc_DD2A ; @ DD19: 20 0F
loc_DD1B:
        LDAB    $3E,X                                   ; @ DD1B: E6 3E
        LDAA    #$01                                    ; @ DD1D: 86 01
        ANDB    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DD1F: C4 0F
        BEQ     loc_DD2A                                ; branche vers loc_DD2A si la condition EQ est vraie ; @ DD21: 27 07
        LDAA    #$0A                                    ; @ DD23: 86 0A
        DECB                                            ; @ DD25: 5A
        BEQ     loc_DD2A                                ; branche vers loc_DD2A si la condition EQ est vraie ; @ DD26: 27 02
        LDAA    #$00                                    ; @ DD28: 86 00
loc_DD2A:
        BCS     loc_DD39                                ; branche vers loc_DD39 si la condition CS est vraie ; @ DD2A: 25 0D
        ADDA    DP_0073                                 ; @ DD2C: 9B 73
        ADDB    DP_0072                                 ; @ DD2E: DB 72
        CMPA    #$64                                    ; @ DD30: 81 64
        BLS     loc_DD4D                                ; branche vers loc_DD4D si la condition LS est vraie ; @ DD32: 23 19
        SUBA    #$64                                    ; @ DD34: 80 64
        INCB                                            ; @ DD36: 5C
        BRA     loc_DD4D                                ; branche toujours vers loc_DD4D ; @ DD37: 20 14
loc_DD39:
        SUBA    DP_0073                                 ; @ DD39: 90 73
        BCS     loc_DD40                                ; branche vers loc_DD40 si la condition CS est vraie ; @ DD3B: 25 03
        SUBA    #$64                                    ; @ DD3D: 80 64
        INCB                                            ; @ DD3F: 5C
loc_DD40:
        NEGA                                            ; @ DD40: 40
        SUBB    DP_0072                                 ; @ DD41: D0 72
        NEGB                                            ; @ DD43: 50
        ANDB    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DD44: C4 7F
        TST     >DP_0072                                ; @ DD46: 7D 00 72
        BPL     loc_DD4D                                ; branche vers loc_DD4D si la condition PL est vraie ; @ DD49: 2A 02
        ORAB    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DD4B: CA 80
loc_DD4D:
        PSHB                                            ; @ DD4D: 37
        LDAB    DP_0041                                 ; @ DD4E: D6 41
        ANDB    #$03                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DD50: C4 03
        CMPB    #$03                                    ; @ DD52: C1 03
        PULB                                            ; @ DD54: 33
        BEQ     loc_DD63                                ; branche vers loc_DD63 si la condition EQ est vraie ; @ DD55: 27 0C
        STAA    DP_0074                                 ; @ DD57: 97 74
        PULA                                            ; @ DD59: 32
        ROLA                                            ; @ DD5A: 49
        LDAA    DP_0074                                 ; @ DD5B: 96 74
        JSR     sub_CB40                                ; appelle sub_CB40 ; @ DD5D: BD CB 40
        BCS     loc_DD6F                                ; branche vers loc_DD6F si la condition CS est vraie ; @ DD60: 25 0D
        RTS                                             ; @ DD62: 39
loc_DD63:
        CMPB    #$1B                                    ; @ DD63: C1 1B
        BGT     loc_DD6D                                ; branche vers loc_DD6D si la condition GT est vraie ; @ DD65: 2E 06
        BLT     loc_DD6F                                ; branche vers loc_DD6F si la condition LT est vraie ; @ DD67: 2D 06
        CMPA    #$64                                    ; @ DD69: 81 64
        BLT     loc_DD6F                                ; branche vers loc_DD6F si la condition LT est vraie ; @ DD6B: 2D 02
loc_DD6D:
        INS                                             ; @ DD6D: 31
        RTS                                             ; @ DD6E: 39
loc_DD6F:
        STAA    DP_0073                                 ; @ DD6F: 97 73
        STAB    DP_0072                                 ; @ DD71: D7 72
        STAB    $12,X                                   ; @ DD73: E7 12
        STAA    $13,X                                   ; @ DD75: A7 13
        LDAA    $3D,X                                   ; @ DD77: A6 3D
        ANDA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DD79: 84 08
        ORAA    #$F3                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DD7B: 8A F3
        JMP     loc_DB44                                ; transfert sans retour vers loc_DB44 ; @ DD7D: 7E DB 44
        FCB     $C5,$02,$27,$14,$DE,$0F,$DF,$5E         ; données '..'....^' ; @ DD80: C5 02 27 14 DE 0F DF 5E
        FCB     $DE,$11,$DF,$60,$96,$13,$97,$62         ; données '...`...b' ; @ DD88: DE 11 DF 60 96 13 97 62
        FCB     $BD,$CC,$58,$24,$03,$7E,$CA,$E9         ; données '..X$.~..' ; @ DD90: BD CC 58 24 03 7E CA E9
        FCB     $B6,$80,$08,$84,$FE,$CE,$CC,$27         ; données '.......'' ; @ DD98: B6 80 08 84 FE CE CC 27
        FCB     $BD,$CC,$3B,$24,$02,$8A,$01,$B7         ; données '..;$....' ; @ DDA0: BD CC 3B 24 02 8A 01 B7
        FCB     $80,$08,$DE,$0F,$DF,$23,$DE,$11         ; données '.....#..' ; @ DDA8: 80 08 DE 0F DF 23 DE 11
        FCB     $DF,$25,$96,$25,$B7,$80,$1A,$96         ; données '.%.%....' ; @ DDB0: DF 25 96 25 B7 80 1A 96
        FCB     $26,$B7,$80,$1B,$96,$13,$97,$27         ; données '&......'' ; @ DDB8: 26 B7 80 1B 96 13 97 27
        FCB     $B7,$80,$1C,$86,$30,$9A,$37,$97         ; données '....0.7.' ; @ DDC0: B7 80 1C 86 30 9A 37 97
        FCB     $37,$7E,$E7,$5F,$39,$4F,$C4,$02         ; données '7~._9O..' ; @ DDC8: 37 7E E7 5F 39 4F C4 02
        FCB     $27,$39,$96,$17,$D6,$16,$CE,$00         ; données ''9......' ; @ DDD0: 27 39 96 17 D6 16 CE 00
        FCB     $04,$BD,$CB,$40,$25,$01,$39,$97         ; données '...@%.9.' ; @ DDD8: 04 BD CB 40 25 01 39 97
        FCB     $17,$D7,$16,$CE,$00,$16,$E6,$00         ; données '........' ; @ DDE0: 17 D7 16 CE 00 16 E6 00
        FCB     $A6,$01,$97,$2B,$D7,$2A,$BD,$CB         ; données '...+.*..' ; @ DDE8: A6 01 97 2B D7 2A BD CB
        FCB     $F1,$7F,$00,$60,$96,$5E,$8B,$00         ; données '...`.^..' ; @ DDF0: F1 7F 00 60 96 5E 8B 00
        FCB     $19,$97,$5E,$96,$5F,$89,$86,$19         ; données '..^._...' ; @ DDF8: 19 97 5E 96 5F 89 86 19
        FCB     $97,$5F,$25,$07,$BD,$CB,$2D,$C6         ; données '._%...-.' ; @ DE00: 97 5F 25 07 BD CB 2D C6
        FCB     $FF,$D7,$60,$F6,$80,$08,$C4,$FB         ; données '..`.....' ; @ DE08: FF D7 60 F6 80 08 C4 FB
        FCB     $96,$60,$2B,$0C,$96,$5F,$26,$06         ; données '.`+.._&.' ; @ DE10: 96 60 2B 0C 96 5F 26 06
        FCB     $96,$5E,$81,$70,$25,$02,$CA,$04         ; données '.^.p%...' ; @ DE18: 96 5E 81 70 25 02 CA 04
        FCB     $F7,$80,$08,$C6,$10,$DA,$37,$D7         ; données '......7.' ; @ DE20: F7 80 08 C6 10 DA 37 D7
        FCB     $37,$D6,$22,$2A,$03,$7E,$ED,$73         ; données '7."*.~.s' ; @ DE28: 37 D6 22 2A 03 7E ED 73
        FCB     $39,$C5,$02,$27,$43,$B6,$80,$08         ; données '9..'C...' ; @ DE30: 39 C5 02 27 43 B6 80 08
        FCB     $84,$FD,$D6,$4C,$C1,$0A,$26,$04         ; données '...L..&.' ; @ DE38: 84 FD D6 4C C1 0A 26 04
        FCB     $C6,$48,$D7,$3B,$DE,$1A,$DF,$2E         ; données '.H.;....' ; @ DE40: C6 48 D7 3B DE 1A DF 2E
        FCB     $27,$02,$8A,$02,$F6,$80,$14,$C5         ; données ''.......' ; @ DE48: 27 02 8A 02 F6 80 14 C5
        FCB     $10,$27,$02,$8A,$08,$B7,$80,$08         ; données '.'......' ; @ DE50: 10 27 02 8A 08 B7 80 08
        FCB     $CE,$00,$00,$DF,$30,$DF,$1C,$CE         ; données '....0...' ; @ DE58: CE 00 00 DF 30 DF 1C CE
        FCB     $00,$2E,$BD,$D2,$D0,$86,$10,$9A         ; données '........' ; @ DE60: 00 2E BD D2 D0 86 10 9A
        FCB     $37,$97,$37,$B6,$85,$29,$84,$F8         ; données '7.7..)..' ; @ DE68: 37 97 37 B6 85 29 84 F8
        FCB     $8A,$01,$B7,$85,$29,$7E,$EB,$F8         ; données '....)~..' ; @ DE70: 8A 01 B7 85 29 7E EB F8
        FCB     $39,$B6,$80,$26,$85,$02,$27,$05         ; données '9..&..'.' ; @ DE78: 39 B6 80 26 85 02 27 05
        FCB     $86,$74,$7E,$CA,$E9,$C5,$02,$27         ; données '.t~....'' ; @ DE80: 86 74 7E CA E9 C5 02 27
        FCB     $54,$96,$4C,$81,$08,$26,$0C,$86         ; données 'T.L..&..' ; @ DE88: 54 96 4C 81 08 26 0C 86
        FCB     $50,$D6,$1C,$C5,$30,$27,$02,$86         ; données 'P...0'..' ; @ DE90: 50 D6 1C C5 30 27 02 86
        FCB     $58,$97,$3B,$DE,$1C,$DF,$30,$B6         ; données 'X.;...0.' ; @ DE98: 58 97 3B DE 1C DF 30 B6
        FCB     $80,$08,$84,$FD,$B7,$80,$08,$CE         ; données '........' ; @ DEA0: 80 08 84 FD B7 80 08 CE
        FCB     $00,$00,$DF,$2E,$DF,$1A,$CE,$00         ; données '........' ; @ DEA8: 00 00 DF 2E DF 1A CE 00
        FCB     $30,$BD,$D2,$D0,$96,$30,$85,$30         ; données '0....0.0' ; @ DEB0: 30 BD D2 D0 96 30 85 30
        FCB     $27,$0E,$85,$10,$26,$0A,$86,$FF         ; données ''...&...' ; @ DEB8: 27 0E 85 10 26 0A 86 FF
        FCB     $97,$60,$C6,$10,$DA,$37,$D7,$37         ; données '.`...7.7' ; @ DEC0: 97 60 C6 10 DA 37 D7 37
        FCB     $F6,$85,$29,$C4,$F8,$CA,$02,$96         ; données '..).....' ; @ DEC8: F6 85 29 C4 F8 CA 02 96
        FCB     $30,$84,$F0,$26,$02,$CB,$02,$F7         ; données '0..&....' ; @ DED0: 30 84 F0 26 02 CB 02 F7
        FCB     $85,$29,$7E,$EB,$F8,$39                 ; données '.)~..9' ; @ DED8: 85 29 7E EB F8 39
loc_DEDE:
        TSTB                                            ; @ DEDE: 5D
        BNE     loc_DF19                                ; branche vers loc_DF19 si la condition NE est vraie ; @ DEDF: 26 38
        LDAA    DP_0022                                 ; @ DEE1: 96 22
        BMI     sub_DEF7                                ; branche vers sub_DEF7 si la condition MI est vraie ; @ DEE3: 2B 12
        ORAA    #$80                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DEE5: 8A 80
        STAA    DP_0022                                 ; @ DEE7: 97 22
        STAA    RAM_8013                                ; @ DEE9: B7 80 13
        LDAA    DP_0041                                 ; @ DEEC: 96 41
        ORAA    #$83                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DEEE: 8A 83
        STAA    DP_0041                                 ; @ DEF0: 97 41
        LDX     DP_002A                                 ; @ DEF2: DE 2A
        STX     DP_0016                                 ; @ DEF4: DF 16
        RTS                                             ; @ DEF6: 39

; ---------------------------------------------------------------------------
; ROUTINE $DEF7 — sub_DEF7
; INCONNU — sous-routine interne à $DEF7; rôle métier non démontré.
; Entrées : contrat non établi; A, B ou X peuvent porter des paramètres.
; Sorties : contrat non établi; examiner les branches de retour et les appelants.
; Registres/flags : seules les instructions ci-dessous font foi; aucune convention ABI supposée.
; RAM/E/S : les symboles explicites du corps indiquent les zones réellement touchées.
; Appelants observés : $D64D. Algorithme conservé sans interprétation fonctionnelle forcée.
; ---------------------------------------------------------------------------
sub_DEF7:
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DEF7: 84 7F
        STAA    DP_0022                                 ; @ DEF9: 97 22
        STAA    RAM_8013                                ; @ DEFB: B7 80 13
        LDAA    #$C0                                    ; @ DEFE: 86 C0
        ORAA    DP_0037                                 ; @ DF00: 9A 37
        STAA    DP_0037                                 ; @ DF02: 97 37
        NOP                                             ; @ DF04: 01
        NOP                                             ; @ DF05: 01
        LDX     #ROM_DATA_FFFF                          ; @ DF06: CE FF FF
        STX     DP_005E                                 ; @ DF09: DF 5E
        LDAA    #$FF                                    ; @ DF0B: 86 FF
        STAA    DP_0060                                 ; @ DF0D: 97 60
        JSR     sub_ED73                                ; appelle sub_ED73 ; @ DF0F: BD ED 73
        LDAA    DP_0041                                 ; @ DF12: 96 41
        ORAA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF14: 8A 40
        STAA    DP_0041                                 ; @ DF16: 97 41
        RTS                                             ; @ DF18: 39
loc_DF19:
        LDAA    DP_0022                                 ; @ DF19: 96 22
        ANDA    #$93                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF1B: 84 93
        ORAA    #$20                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF1D: 8A 20
        DECB                                            ; @ DF1F: 5A
        BEQ     loc_DF24                                ; branche vers loc_DF24 si la condition EQ est vraie ; @ DF20: 27 02
        EORA    #$60                                    ; @ DF22: 88 60
loc_DF24:
        ASLB                                            ; @ DF24: 58
        ASLB                                            ; @ DF25: 58
        ABA                                             ; @ DF26: 1B
        STAA    DP_0022                                 ; @ DF27: 97 22
        STAA    RAM_8013                                ; @ DF29: B7 80 13
        ASRB                                            ; @ DF2C: 57
        ASRB                                            ; @ DF2D: 57
        INCB                                            ; @ DF2E: 5C
        LDAA    #$F7                                    ; @ DF2F: 86 F7
loc_DF31:
        ASLA                                            ; @ DF31: 48
        DECB                                            ; @ DF32: 5A
        BNE     loc_DF31                                ; branche vers loc_DF31 si la condition NE est vraie ; @ DF33: 26 FC
        ANDA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF35: 84 F0
        TAB                                             ; @ DF37: 16
        LDAA    DP_0021                                 ; @ DF38: 96 21
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF3A: 84 0F
        ABA                                             ; @ DF3C: 1B
        STAA    DP_0021                                 ; @ DF3D: 97 21
        STAA    RAM_8014                                ; @ DF3F: B7 80 14
        LDAA    DP_0020                                 ; @ DF42: 96 20
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF44: 84 0F
        ABA                                             ; @ DF46: 1B
        STAA    DP_0020                                 ; @ DF47: 97 20
        LDAA    RAM_8008                                ; @ DF49: B6 80 08
        ANDA    #$F7                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF4C: 84 F7
        BITB    #$10                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF4E: C5 10
        BEQ     loc_DF54                                ; branche vers loc_DF54 si la condition EQ est vraie ; @ DF50: 27 02
        ORAA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF52: 8A 08
loc_DF54:
        STAA    RAM_8008                                ; @ DF54: B7 80 08
        LDAB    #$C0                                    ; @ DF57: C6 C0
        ORAB    DP_0037                                 ; @ DF59: DA 37
        STAB    DP_0037                                 ; @ DF5B: D7 37
        JSR     sub_EC08                                ; appelle sub_EC08 ; @ DF5D: BD EC 08
        LDAA    DP_0021                                 ; @ DF60: 96 21
        LSRA                                            ; @ DF62: 44
        BCC     loc_DF6C                                ; branche vers loc_DF6C si la condition CC est vraie ; @ DF63: 24 07
        LDAA    DP_0047                                 ; @ DF65: 96 47
        ORAA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF67: 8A 40
        STAA    DP_0047                                 ; @ DF69: 97 47
        RTS                                             ; @ DF6B: 39
loc_DF6C:
        LDAA    DP_0045                                 ; @ DF6C: 96 45
        ORAA    #$40                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DF6E: 8A 40
        STAA    DP_0045                                 ; @ DF70: 97 45
        RTS                                             ; @ DF72: 39
        FCB     $B6,$80,$13,$2A,$1D,$D6,$41,$CA         ; données '...*..A.' ; @ DF73: B6 80 13 2A 1D D6 41 CA
        FCB     $83,$D7,$41,$B6,$80,$13,$8A,$80         ; données '..A.....' ; @ DF7B: 83 D7 41 B6 80 13 8A 80
        FCB     $B7,$80,$13,$97,$22,$DE,$2A,$96         ; données '....".*.' ; @ DF83: B7 80 13 97 22 DE 2A 96
        FCB     $41,$85,$02,$27,$02,$DE,$16,$DF         ; données 'A..'....' ; @ DF8B: 41 85 02 27 02 DE 16 DF
        FCB     $16,$39,$CE,$FF,$FF,$DF,$5E,$DF         ; données '.9....^.' ; @ DF93: 16 39 CE FF FF DF 5E DF
        FCB     $5F,$96,$22,$84,$7F,$B7,$80,$13         ; données '_.".....' ; @ DF9B: 5F 96 22 84 7F B7 80 13
        FCB     $97,$22,$BD,$ED,$73,$39                 ; données '."..s9' ; @ DFA3: 97 22 BD ED 73 39
loc_DFA9:
        TSTA                                            ; @ DFA9: 4D
        BNE     loc_DFC2                                ; branche vers loc_DFC2 si la condition NE est vraie ; @ DFAA: 26 16
        LDAB    #$40                                    ; @ DFAC: C6 40
        ORAB    DP_003D                                 ; @ DFAE: DA 3D
        STAB    DP_003D                                 ; @ DFB0: D7 3D
        CLRB                                            ; @ DFB2: 5F
        LDAA    DP_004A                                 ; @ DFB3: 96 4A
        BITA    #$08                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DFB5: 85 08
        BNE     loc_DFBF                                ; branche vers loc_DFBF si la condition NE est vraie ; @ DFB7: 26 06
        LDX     #ROM_DATA_FFFF                          ; @ DFB9: CE FF FF
        STX     RAM_800A                                ; @ DFBC: FF 80 0A
loc_DFBF:
        JMP     loc_C560                                ; transfert sans retour vers loc_C560 ; @ DFBF: 7E C5 60
loc_DFC2:
        LDAA    DP_0049                                 ; @ DFC2: 96 49
        ANDA    #$0F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DFC4: 84 0F
        CMPA    #$04                                    ; @ DFC6: 81 04
        BEQ     loc_DFEB                                ; branche vers loc_DFEB si la condition EQ est vraie ; @ DFC8: 27 21
        CMPB    #$0A                                    ; @ DFCA: C1 0A
        BEQ     loc_DFEA                                ; branche vers loc_DFEA si la condition EQ est vraie ; @ DFCC: 27 1C
        LDAA    DP_005D                                 ; @ DFCE: 96 5D
        ASLA                                            ; @ DFD0: 48
        ASLA                                            ; @ DFD1: 48
        ASLA                                            ; @ DFD2: 48
        ASLA                                            ; @ DFD3: 48
        ABA                                             ; @ DFD4: 1B
        STAA    DP_005D                                 ; @ DFD5: 97 5D
        LDAB    DP_0049                                 ; @ DFD7: D6 49
        ADDB    #$40                                    ; @ DFD9: CB 40
        STAB    DP_0049                                 ; @ DFDB: D7 49
        BMI     loc_E01A                                ; branche vers loc_E01A si la condition MI est vraie ; @ DFDD: 2B 3B
        ORAA    #$F0                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DFDF: 8A F0
        STAA    RAM_801A                                ; @ DFE1: B7 80 1A
        LDAA    #$B0                                    ; @ DFE4: 86 B0
        ORAA    DP_0037                                 ; @ DFE6: 9A 37
        STAA    DP_0037                                 ; @ DFE8: 97 37
loc_DFEA:
        RTS                                             ; @ DFEA: 39
loc_DFEB:
        LDAA    DP_0038                                 ; @ DFEB: 96 38
        ANDA    #$7F                                    ; masque/teste un champ de bits; voir le commentaire de routine ; @ DFED: 84 7F
        STAA    DP_0038                                 ; @ DFEF: 97 38
        CMPB    #$0A                                    ; @ DFF1: C1 0A
        BNE     loc_E01D                                ; branche vers loc_E01D si la condition NE est vraie ; @ DFF3: 26 28
        LDAA    DP_0049                                 ; @ DFF5: 96 49
        CMPA    #$19                                    ; @ DFF7: 81 19
        BLS     loc_DFFC                                ; branche vers loc_DFFC si la condition LS est vraie ; @ DFF9: 23 01
        RTS                                             ; @ DFFB: 39
loc_DFFC:
        LDX     #ROM_DATA_FFFF                          ; @ DFFC: CE FF FF

; CONFIRMÉ — instruction traversant la frontière des deux EPROM :
; $DFFF fournit l'opcode $FF (STX étendu), puis $E000..$E001
; fournissent l'opérande $800A. L'instruction logique est STX $800A.
        FCB     $FF                                     ; @ DFFF: FF

        END
