@include "c:\\util\\gawk\\PaGawkLib.awk"
BEGIN {
  FS = "," ;
  OFS = ";" ;
  if( outputDirectory == "" )
    outputDirectory="Out" ;
  fOut="test.csv" ;
  tAdr[0]="00 Vingtmillade octet 1" ;
  tAdr[1]="01 Vingtmillade octet 2" ;
  tAdr[2]="02 Vingtmillade octet 3" ;
  tAdr[3]="03 QuatreVingtade" ;
  tAdr[4]="04 Approche, diviseur N, D7 poursuite doubleur" ;
  tAdr[5]="05 Approche" ;
  tAdr[6]="06 Approche, DAC tracking doubleur" ;
  tAdr[7]="07 ?" # non attribué
  tAdr[8]="08 Analogique pas de 0,1dB et 1dB" ;
  tAdr[9]="09 Analogique BCD modulation b01" ;
  tAdr[10]="10 Analogique BCD modulation b11" ;
  tAdr[11]="11 Analogique Correction FM" ;
  tAdr[12]="12 FM" ;
  tAdr[13]="13 Diviseur incréments" ;
  tAdr[14]="14 ?" # non attribué
  tAdr[15]="15 Compatibilité/extension, D7..D5 dérivés adresse 12" ;

  # Table originale des relais, indexée par pas de 5 dB. La clé est le
  # champ D5..D0 de l'adresse 6 et la valeur est le numéro de pas mécanique.
  relayStep[0x3F]=0 ;  relayStep[0x37]=1 ;  relayStep[0x3B]=2 ;
  relayStep[0x33]=3 ;  relayStep[0x3D]=4 ;  relayStep[0x35]=5 ;
  relayStep[0x39]=6 ;  relayStep[0x31]=7 ;  relayStep[0x2D]=8 ;
  relayStep[0x25]=9 ;  relayStep[0x29]=10 ; relayStep[0x21]=11 ;
  relayStep[0x38]=12 ; relayStep[0x30]=13 ; relayStep[0x2C]=14 ;
  relayStep[0x24]=15 ; relayStep[0x28]=16 ; relayStep[0x20]=17 ;
  relayStep[0x19]=18 ; relayStep[0x11]=19 ; relayStep[0x0D]=20 ;
  relayStep[0x05]=21 ; relayStep[0x09]=22 ; relayStep[0x01]=23 ;
  relayStep[0x18]=24 ; relayStep[0x10]=25 ; relayStep[0x0C]=26 ;
  relayStep[0x04]=27 ;
}

function bit(value, number) {
  return and(value, lshift(1, number)) ? 1 : 0 ;
}

function hexByte(value) {
  return sprintf("%02X", and(value, 0xFF)) ;
}

function decimalTenth(value,    sign, magnitude) {
  sign = value < 0 ? "-" : "" ;
  magnitude = value < 0 ? -value : value ;
  return sprintf("%s%d.%d", sign, int(magnitude / 10), magnitude % 10) ;
}

function decimalHundredth(value) {
  return sprintf("%d.%02d", int(value / 100), value % 100) ;
}

function formatFrequency(hz,    whole, remainder, result) {
  if( hz >= 1000000 ) {
    whole = int(hz / 1000000) ;
    remainder = hz % 1000000 ;
    if( remainder == 0 )
      return whole " MHz" ;
    result = sprintf("%d.%06d", whole, remainder) ;
    sub(/0+$/, "", result) ;
    return result " MHz" ;
  }
  if( hz >= 1000 ) {
    whole = int(hz / 1000) ;
    remainder = hz % 1000 ;
    if( remainder == 0 )
      return whole " kHz" ;
    result = sprintf("%d.%03d", whole, remainder) ;
    sub(/0+$/, "", result) ;
    return result " kHz" ;
  }
  return hz " Hz" ;
}

function validBcd(value) {
  return and(value, 0x0F) <= 9 && rshift(and(value, 0xF0), 4) <= 9 ;
}

function bcdValue(value) {
  return rshift(and(value, 0xF0), 4) * 10 + and(value, 0x0F) ;
}

function decodeN(code,    m, complementN, n) {
  code = and(code, 0x7F) ;
  m = and(code, 0x07) ;
  complementN = rshift(and(code, 0x78), 3) ;
  n = 16 - complementN ;
  if( m > 4 || n < 0 || n > 16 )
    return -1 ;
  return 5 * n + m ;
}

function rfPath(value,    path, oscillator) {
  path = and(value, 0x1F) ;
  oscillator = bit(value, 0) ? "O1" : "O2" ;
  if( path == 0x03 )
    return "hétérodyne " oscillator ;
  if( path == 0x04 || path == 0x05 )
    return oscillator " puis /2" ;
  if( path == 0x08 || path == 0x09 )
    return oscillator " direct" ;
  if( path == 0x10 || path == 0x11 )
    return oscillator " puis X2" ;
  return "chemin RF non reconnu" ;
}

function rangeFromAddress12(value,    range) {
  range = and(value, 0x86) ;
  if( range == 0x84 ) return "hétérodyne" ;
  if( range == 0x00 ) return "division par 2" ;
  if( range == 0x04 ) return "direct" ;
  if( range == 0x02 ) return "doubleur X2" ;
  return "extension RF non reconnue (" hexByte(range) ")" ;
}

function sourceFromWords(address10, address12,    sourceBits) {
  if( !bit(address10, 7) )
    return "CW" ;
  if( !bit(address10, 5) )
    return "externe" ;
  sourceBits = and(address12, 0x60) ;
  if( sourceBits == 0x60 ) return "interne 1 kHz" ;
  if( sourceBits == 0x40 ) return "interne 400 Hz" ;
  return "interne, source indéterminée" ;
}

function modulationMode(address10, address12,    modeBits) {
  if( !bit(address10, 7) )
    return "CW" ;
  if( bit(address10, 6) )
    return "AM" ;
  modeBits = and(address12, 0x18) ;
  if( modeBits == 0x10 ) return "FM basse" ;
  if( modeBits == 0x08 ) return "FM haute" ;
  if( modeBits == 0x18 ) return "PM" ;
  return "modulation active non reconnue" ;
}

function fineTenths(address8,    units, tens) {
  units = and(address8, 0x0F) ;
  tens = rshift(and(address8, 0xF0), 4) ;
  if( units > 9 )
    return -1 ;
  if( tens >= 8 )
    tens -= 2 ;
  if( tens > 13 )
    return -1 ;
  return tens * 10 + units ;
}

function address6Comment(value,    relay, step, result) {
  relay = and(value, 0x3F) ;
  result = "D7 +5 dB=" bit(value, 7) ", D6 Pulse=" bit(value, 6) ;
  if( relay == 0 )
    return result ", relais d'atténuation à 0: RF inhibée" ;
  if( relay in relayStep ) {
    step = relayStep[relay] ;
    return result ", relais=" hexByte(relay) ", pas=" step \
           " (" step * 5 " dB mécaniques)" ;
  }
  return result ", code relais inconnu=" hexByte(relay) ;
}

function address10Comment(value,    major, state) {
  major = and(value, 0x0F) + (bit(value, 4) ? 0 : 10) ;
  if( !bit(value, 7) )
    state = "CW" ;
  else if( bit(value, 6) )
    state = bit(value, 5) ? "AM interne" : "AM externe" ;
  else
    state = bit(value, 5) ? "FM/PM interne" : "FM/PM externe" ;
  return "DAC majeur=" major " (centaines), état=" state ;
}

function address12Comment(value,    modeBits, sourceBits, state) {
  modeBits = and(value, 0x18) ;
  sourceBits = and(value, 0x60) ;
  if( bit(value, 0) ) {
    if( sourceBits == 0x60 ) state = "AM, source interne 1 kHz" ;
    else if( sourceBits == 0x40 ) state = "AM, source interne 400 Hz" ;
    else if( haveReg[10] && !bit(reg[10], 7) ) state = "CW" ;
    else if( haveReg[10] && bit(reg[10], 6)) state = "AM, source externe" ;
    else state = "AM externe ou CW, à confirmer par l'adresse 10" ;
  }
  else {
    if( modeBits == 0x10 ) state = "FM basse" ;
    else if( modeBits == 0x08 ) state = "FM haute" ;
    else if( modeBits == 0x18 ) state = "PM" ;
    else state = "mode de modulation non reconnu" ;
    if( sourceBits == 0x60 ) state = state ", source interne 1 kHz" ;
    else if( sourceBits == 0x40 ) state = state ", source interne 400 Hz" ;
    else state = state ", source externe" ;
  }
  return "gamme RF=" rangeFromAddress12(value) ", " state \
         ", D0=" bit(value, 0) ;
}

function decodeWrite(address, value,    high, low, decoded, n, expected,
                     relay, step, fine, derived, result) {
  if( address == 0 ) {
    result = "carte 20000: unités de C=" rshift(and(value, 0xF0), 4) ;
    if( and(value, 0x0F) != 0 ) result = result ", quartet bas inattendu" ;
    return result ;
  }
  if( address == 1 ) {
    high = rshift(and(value, 0xF0), 4) ;
    low = and(value, 0x0F) ;
    return "carte 20000: centaines de C=" high ", dizaines de C=" low ;
  }
  if( address == 2 ) {
    result = "carte 20000: milliers de C=" and(value, 0x0F) ;
    if( and(value, 0xF0) != 0 ) result = result ", quartet haut inattendu" ;
    return result ;
  }
  if( address == 3 ) {
    decoded = xor(value, 0xFE) ;
    if( !validBcd(decoded) )
      return "carte 80: code BCD invalide après XOR FE (" hexByte(decoded) ")" ;
    return "carte 80: R=" bcdValue(decoded) ", Q=" 178 + bcdValue(decoded) ;
  }
  if( address == 4 ) {
    n = decodeN(value) ;
    result = n < 0 ? "code diviseur N invalide" : "diviseur N=" n ;
    return result ", D7 poursuite doubleur=" bit(value, 7) ;
  }
  if( address == 5 ) {
    result = "chemin=" rfPath(value) ;
    if( bit(value, 5))
      result = result ", D5=1 (sous-gamme basse ou Pulse)" ;
    if( bit(value, 6)) result = result ", D6 extension supérieure=1" ;
    return result ;
  }
  if( address == 6 )
    return address6Comment(value) ;
  if( address == 7 || address == 14 )
    return "adresse non attribuée dans les EPROM 740A connues" ;
  if( address == 8 ) {
    fine = fineTenths(value) ;
    return fine < 0 ? "code d'atténuation fine invalide" \
                    : "atténuation fine corrigée=" decimalTenth(fine) " dB" ;
  }
  if( address == 9 ) {
    if( !validBcd(value) ) return "deux chiffres faibles BCD invalides" ;
    return "DAC modulation, deux chiffres faibles=" sprintf("%02d", bcdValue(value)) ;
  }
  if( address == 10 )
    return address10Comment(value) ;
  if( address == 11 )
    return "N binaire=" and(value, 0x7F) ", D7 transitoire=" bit(value, 7) ;
  if( address == 12 )
    return address12Comment(value) ;
  if( address == 13 ) {
    n = decodeN(value) ;
    result = n < 0 ? "code diviseur N invalide" : "diviseur N=" n ;
    result = result ", D7 complément de A12.D0=" bit(value, 7) ;
    if( haveReg[12] ) {
      expected = bit(reg[12], 0) ? 0 : 1 ;
      result = result (bit(value, 7) == expected ? " (cohérent)" : " (INCOHÉRENT)") ;
    }
    return result ;
  }
  if( address == 15 ) {
    derived = and(value, 0xE0) ;
    result = "extension basse=" and(value, 0x1F) ", champ dérivé=" hexByte(derived) ;
    if( haveReg[12] ) {
      expected = and(lshift(and(reg[12], 0x0E), 4), 0xE0) ;
      result = result (derived == expected ? " (cohérent avec A12)" \
                                          : " (INCOHÉRENT avec A12)") ;
    }
    return result ;
  }
  return "décodage non disponible" ;
}

function pushHistory(address, value,    i) {
  for( i=11 ; i>0 ; --i ) {
    historyAddress[i] = historyAddress[i-1] ;
    historyValue[i] = historyValue[i-1] ;
  }
  historyAddress[0] = address ;
  historyValue[0] = value ;
  if( historyCount < 12 ) ++historyCount ;
}

function historyIsFrequencyGroup() {
  return historyCount >= 10 &&
         historyAddress[9] == 12 && historyAddress[8] == 15 &&
         historyAddress[7] == 5  && historyAddress[6] == 11 &&
         historyAddress[5] == 4  && historyAddress[4] == 13 &&
         historyAddress[3] == 0  && historyAddress[2] == 1 &&
         historyAddress[1] == 2  && historyAddress[0] == 3 ;
}

function frequencyGroupComment(    a0, a1, a2, a3, c, m, decoded3, q,
                                  pointA, n, delta, synth, path, output,
                                  consistency) {
  a0 = historyValue[3] ; a1 = historyValue[2] ;
  a2 = historyValue[1] ; a3 = historyValue[0] ;
  if( and(a0, 0x0F) != 0 || and(a2, 0xF0) != 0 )
    return "Groupe fréquence: codage 20000 invalide" ;
  if( rshift(and(a0, 0xF0), 4) > 9 || !validBcd(a1) || and(a2, 0x0F) > 9 )
    return "Groupe fréquence: chiffre C invalide" ;
  decoded3 = xor(a3, 0xFE) ;
  if( !validBcd(decoded3) )
    return "Groupe fréquence: code carte 80 invalide" ;

  c = and(a2, 0x0F) * 1000 + rshift(and(a1, 0xF0), 4) * 100 + \
      and(a1, 0x0F) * 10 + rshift(and(a0, 0xF0), 4) ;
  m = 2 * (c + 20000) ;
  q = 178 + bcdValue(decoded3) ;
  pointA = q * 500000 + m * 25 ;
  n = decodeN(historyValue[5]) ;
  if( n < 0 || pointA % 5 != 0 )
    return "Groupe fréquence: N ou point A invalide" ;
  delta = pointA / 5 - 18000000 ;
  synth = 18000000 + n * 8000000 + delta ;
  path = and(historyValue[7], 0x1F) ;
  if( path == 0x03 ) output = synth - 400000000 ;
  else if( path == 0x04 || path == 0x05 ) output = synth / 2 ;
  else if( path == 0x08 || path == 0x09 ) output = synth ;
  else if( path == 0x10 || path == 0x11 ) output = synth * 2 ;
  else return "Groupe fréquence: chemin RF non reconnu, point A=" \
              formatFrequency(pointA) ", N=" n ;

  consistency = and(historyValue[6], 0x7F) == n ? "" \
                : ", attention A11.N incohérent" ;
  return "Groupe fréquence 12/15/5/11/4/13/0/1/2/3: sortie=" \
         formatFrequency(output) ", synthèse=" formatFrequency(synth) \
         ", point A=" formatFrequency(pointA) ", N=" n ", chemin=" \
         rfPath(historyValue[7]) consistency ;
}

function historyIsLevelGroup() {
  return historyCount >= 3 && historyAddress[2] == 6 &&
         historyAddress[1] == 8 && historyAddress[0] == 6 ;
}

function levelGroupComment(    relay, step, fine, level, finalState) {
  relay = and(historyValue[0], 0x3F) ;
  fine = fineTenths(historyValue[1]) ;
  finalState = relay == 0 ? "RF inhibée" : "RF programmée" ;
  if( relay == 0 || !(relay in relayStep) || fine < 0 )
    return "Groupe niveau 6/8/6: " finalState \
           ", niveau non déductible, fine=" \
           (fine < 0 ? "invalide" : decimalTenth(fine) " dB") ;
  step = relayStep[relay] ;
  level = 138 - 50 * step - fine ;
  return "Groupe niveau 6/8/6: " finalState ", relais=" step * 5 \
         " dB, fine=" decimalTenth(fine) " dB, niveau=" \
         decimalTenth(level) " dBm si correction=0" ;
}

function historyIsModulationGroup(    sixWords, sevenWords) {
  sixWords = historyCount >= 6 && historyAddress[5] == 9 &&
             historyAddress[4] == 10 && historyAddress[3] == 12 &&
             historyAddress[2] == 13 && historyAddress[1] == 11 &&
             historyAddress[0] == 6 ;
  sevenWords = historyCount >= 7 && historyAddress[6] == 6 && sixWords ;
  return sixWords || sevenWords ;
}

function modulationGroupComment(    address9, address10, address12, low,
                                   major, scaled, mode, source, value, n,
                                   prefix) {
  address9 = historyValue[5] ;
  address10 = historyValue[4] ;
  address12 = historyValue[3] ;
  if( !validBcd(address9) || and(address10, 0x0F) > 9 )
    return "Groupe modulation: valeur BCD invalide" ;
  low = bcdValue(address9) ;
  major = and(address10, 0x0F) + (bit(address10, 4) ? 0 : 10) ;
  scaled = major * 100 + low ;
  mode = modulationMode(address10, address12) ;
  source = sourceFromWords(address10, address12) ;
  if( mode == "AM" ) value = decimalTenth(scaled) " %" ;
  else if( mode == "FM basse" ) value = formatFrequency(scaled * 10) ;
  else if( mode == "FM haute" ) value = formatFrequency(scaled * 100) ;
  else if( mode == "PM" ) value = decimalHundredth(scaled) " rad" ;
  else value = "DAC V=" scaled ", unité liée au mode mémorisé" ;
  n = and(historyValue[1], 0x7F) ;
  # Deux transactions FM successives sont naturellement séparées par le
  # dernier A6 de la précédente. Ne pas prendre ce mot pour le A6 initial,
  # lequel appartient uniquement à la branche AM (ou AM mémorisée en CW).
  prefix = (mode == "AM" || mode == "CW") &&
           historyCount >= 7 && historyAddress[6] == 6 \
           ? "6/9/10/12/13/11/6" : "9/10/12/13/11/6" ;
  return "Groupe modulation " prefix ": mode=" mode ", valeur=" value \
         ", source=" source ", N=" n ;
}

function groupComment(    result) {
  if( historyIsFrequencyGroup() )
    return frequencyGroupComment() ;
  if( historyIsModulationGroup() )
    return modulationGroupComment() ;
  if( historyIsLevelGroup() )
    return levelGroupComment() ;
  return "" ;
}


# ; CSV, generated by libsigrok4DSL 0.2.0 on Sun Nov 05 15:33:50 2023
# ; Channels (13/16)
# ; Sample rate: 1 MHz
# ; Sample count: 2.896 M Samples
# Time(s), D0, D1, D2, D3, D4, D5, D6, D7, A0, A1, A2, A3, Chargt
# 0,0,0,0,0,0,0,0,0,1,1,1,1,1
# 0.095445,0,0,0,0,0,0,0,0,0,1,0,1,1
# 0.095456,0,0,0,0,0,0,0,0,0,1,0,0,1
# 0.095472,0,0,0,0,0,0,0,0,0,1,1,0,1
#
# Sortie : temps ; bits + adresse ; valeur décimale ; commentaire détaillé.
# La dernière ligne d'un groupe reconnu reçoit aussi sa synthèse après " | ".
# Le répertoire peut être remplacé par : gawk -v outputDirectory=... -f ...

BEGINFILE {
  fileBase=FILENAME ;
  print FILENAME
  sub(/^.*[\\\\\/]/,"",fileBase) ;
  fOut=outputDirectory "/Dec_" fileBase ;
  haveChargt=0 ;
  chargtOld=0 ;
  historyCount=0 ;
  delete historyAddress ;
  delete historyValue ;
  delete reg ;
  delete haveReg ;
}

FNR>5 {
  tm=$1 ;
  d0=$2 ; d1=$3 ; d2=$4 ; d3=$5 ; d4=$6 ; d5=$7 ; d6=$8 ; d7=$9 ;
  data = d0 + d1*2 + d2*4 + d3*8 + d4*16 + d5*32 + d6*64 + d7*128 ;
  libData = d7 d6 d5 d4 d3 d2 d1 d0 ;
  a0=$10 ; a1=$11 ; a2=$12 ; a3=$13 ;
  adr = a0 + a1*2 + a2*4 + a3*8 ;
  if( adr+0 in tAdr )
    libAdr=a3 a2 a1 a0 " " tAdr[adr] ;
  else
    libAdr=adr " Err. adresse." ;
  chargt=$14+0 ;
  # The CSV contains one row for every logic-state change.  A bus write is
  # valid only on the falling edge of Chargt, not for every row where the
  # signal happens to be low.
  if( haveChargt && chargtOld==1 && chargt==0 )
  {
    reg[adr]=data ;
    haveReg[adr]=1 ;
    pushHistory(adr, data) ;
    comment=decodeWrite(adr, data) ;
    group=groupComment() ;
    if( group!="" )
      comment=comment " | " group ;
    print sprintf("%0.8f", tm),libData " " libAdr, data, comment > fOut ;
  }
  chargtOld=chargt ;
  haveChargt=1 ;
}

ENDFILE {
  if( fOut!="" )
    close(fOut) ;
}
