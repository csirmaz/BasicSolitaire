'CLASSIC SOLITAIRE by Elod P Csirmaz 2004

'Unused subrutines:
'  loadtable - load a table from solitin.txt

TYPE RegType
     ax    AS INTEGER
     bx    AS INTEGER
     cx    AS INTEGER
     dx    AS INTEGER
     bp    AS INTEGER
     si    AS INTEGER
     di    AS INTEGER
     flags AS INTEGER
END TYPE
DECLARE SUB mouse (f AS INTEGER)
DECLARE SUB INTERRUPT (intnum AS INTEGER, inreg AS RegType, outreg AS RegType)
DIM SHARED inregs AS RegType
DIM SHARED outregs AS RegType
COMMON SHARED mx AS INTEGER, my AS INTEGER, mbutton AS INTEGER
DECLARE FUNCTION myrnd! (m AS SINGLE, s AS SINGLE)
COMMON SHARED myseed AS SINGLE
REM ---------------  idaig kotott  ------------------------------------

DIM tabla(7, 24, 3) '(x,y,z) x = oszlop
'                            y = oszlopban kartya
'                            z = 1-szin 2-szam 3-rejtett
'€restart
DIM tablaorg(7, 24, 3)
DIM tabla2(7, 24, 3) '(x y z) x = oszlop
'                             y = oszlopban kartya
'(stores possibility fromdeck)z = 1-szam 2-szin1 3-szin2 (balra kint)
'(possible move for existing) z = 1-leaderre/hany kell 2-legalsot 3-ujoszlop
'                   (move)    y=1, z=1  1/2 (card/king)  z=2 (hanyadik)
DIM deck(4, 13) '1=in deck 2=topmost out
DIM outc(4)
DIM rajz(7, 2)
'(stores info about lowermost drawn card)
'language 0=English 1=Hungarian
READ mn: DIM messa$(mn)
'(language-specific messages)
'€undo
'undotype - 1=from-deck 2=to-out-from-table 3=move 4=to-out-from-deck
'undoszin
'undoszam
'undooszl - from where
'undohany
'undooszl2
'undohany2
seedgiven = 0
seed = 0
checksum = 0

'€CONFIG

'seedfile$ -file storing next unplayed table no.
seedfile$ = "table.sol"

'solutions$ -directory in which solvability info is stored
solutions$ = "solution"

language = 0 '-1=from file 0=English 1=Hungarian
'langifle$ -file storing language info
langfile$ = "language.sol"

'onemove -do move if there is only one possibility 1=yes 0=no
onemove = 1

'autoreveal -automatically reveal cards
autoreveal = 1

'timewait -time elapsing in case of automatic moves
timewait = .15

'kartya$ -signs for various cards
kartya$ = "A23456789" + CHR$(20) + "JQK"
'=---------------------------------------------------------------------

ON ERROR GOTO 0

mouse 0
mx = &H80FF: my = &H4000: mouse 10
mouse 1

GOSUB getlang

firstscreen = 1
GOSUB drinit
IF COMMAND$ <> "" THEN '€command line argument
  firstscreen = 0
  s$ = COMMAND$
  checksumuj = VAL(RIGHT$(s$, 3))
  seed = VAL(LEFT$(s$, LEN(s$) - 3))
  seedgiven = 1
  GOSUB drinit
  GOSUB osztas
END IF
WHILE 1
GOSUB drawt
GOSUB moving
WEND

SYSTEM

'mark game as solved / try again / surely hopeless
markgame:
ON ERROR GOTO markge
markerr = 0
OPEN solutions$ + "\0readme.txt" FOR INPUT AS #1
IF markerr = 1 THEN
  SHELL "md " + solutions$
  markerr = 0
  OPEN solutions$ + "\0readme.txt" FOR OUTPUT AS #1
  IF markerr = 1 THEN
    COLOR 7, 0
    CLS
    PRINT "Error creating solutions directory. Press any key..."
    WHILE INKEY$ = "": WEND
    GOSUB drinit
  ELSE
    PRINT #1, "THE SOLUTIONS DIRECTORY stores information about games"
    PRINT #1, "you have marked. A file named xxxxxxxx.??? corresponds to"
    PRINT #1, "game no. xxxxxxxx marked"
    PRINT #1, "solved if ??? is 'SLD'"
    PRINT #1, "TryAgain if ??? is 'TRY'"
    PRINT #1, "and hopeless if ??? is 'HLS'."
    CLOSE #1
  END IF
ELSE
  CLOSE #1
END IF
cc$ = STR$(seed)
cc$ = RIGHT$(cc$, LEN(cc$) - 1)
WHILE LEN(cc$) < 5: cc$ = "0" + cc$: WEND
c$ = STR$(checksum)
c$ = RIGHT$(c$, LEN(c$) - 1)
WHILE LEN(c$) < 3: c$ = "0" + c$: WEND
c$ = cc$ + c$
COLOR 14, 2
LOCATE 24, 48
PRINT "Mark: S>olved T>ryAgain H>opeless";
cc$ = ""
WHILE cc$ <> "t" AND cc$ <> "h" AND cc$ <> "s": cc$ = INKEY$: WEND
LOCATE 24, 48
SELECT CASE cc$
CASE "s": cc$ = "SLD": PRINT "Game marked as solved (SLD)      ";
CASE "t": cc$ = "TRY": PRINT "Game marked as TryAgain (TRY)    ";
CASE "h": cc$ = "HLS": PRINT "Game marked as hopeless (HLS)    ";
END SELECT
'solutions$+"\"+c$+".xxx"
KILL solutions$ + "\" + c$ + ".*"
markerr = 0
OPEN solutions$ + "\" + c$ + "." + cc$ FOR OUTPUT AS #1
IF markerr = 1 THEN
  PRINT "File error!"
ELSE
  CLOSE #1
END IF
tim = TIMER + 1
WHILE tim > TIMER AND INKEY$ = "": WEND
LOCATE 24, 48: PRINT "                             ";
ON ERROR GOTO 0
RETURN
markge:
markerr = 1
RESUME NEXT

'load seed
loadseed:
ON ERROR GOTO sfe
seederr = 1
OPEN seedfile$ FOR INPUT AS #1
INPUT #1, seed
CLOSE #1
seederr = 0
GOTO sf2
sfe:
SELECT CASE seederr
CASE 1 'error opening or reading file
 COLOR 7, 0
 CLS
 PRINT messa$(1)
 PRINT messa$(2)
 PRINT messa$(3)
 PRINT messa$(4)
 PRINT messa$(5)
sf3:
 LINE INPUT a$
 a = VAL(a$)
 IF a <> 1 AND a <> 2 AND a <> 3 THEN PRINT messa$(6): GOTO sf3
 IF a = 3 THEN SYSTEM
 RESUME sfc
CASE 2 'error opening file for write
 PRINT "*** [ERROR 01] Error writing file "; seedfile$: SYSTEM
END SELECT
PRINT "*** [ERROR 02] seed: error error": SYSTEM
sfc:
seederr = 2
OPEN seedfile$ FOR OUTPUT AS #1
IF a = 2 THEN
  RANDOMIZE TIMER
  a = INT(RND * 1000)
ELSE
  a = 0
END IF
PRINT #1, a
CLOSE #1
seederr = 0
seed = a
GOSUB drinit
sf2:
RETURN

saveseed:
OPEN seedfile$ FOR OUTPUT AS #1
PRINT #1, seed
CLOSE #1
RETURN

'reload table from tablaorg
restart:
FOR i = 1 TO 4: FOR j = 1 TO 13: deck(i, j) = 1: NEXT: outc(i) = 0: NEXT
FOR i = 1 TO 7: FOR j = 1 TO 24: FOR k = 1 TO 3: tabla(i, j, k) = 0: tabla2(i, j, k) = 0: NEXT: NEXT: NEXT
FOR i = 1 TO 7
FOR j = 1 TO i
  tabla(i, j, 1) = tablaorg(i, j, 1)
  tabla(i, j, 2) = tablaorg(i, j, 2)
  tabla(i, j, 3) = tablaorg(i, j, 3)
  deck(tabla(i, j, 1), tabla(i, j, 2)) = 0
NEXT
NEXT
GOSUB gamenum
RETURN

'deal a new table
osztas:
  IF seedgiven = 0 THEN
    GOSUB loadseed
    seed = seed + 1
    x = myrnd(2, ABS(SIN(seed)))
    GOSUB saveseed
  ELSE
    x = myrnd(2, ABS(SIN(seed)))
  END IF
  checksum = 0
FOR i = 1 TO 4: FOR j = 1 TO 13: deck(i, j) = 1: NEXT: outc(i) = 0: NEXT
FOR i = 1 TO 7: FOR j = 1 TO 24: FOR k = 1 TO 3: tabla(i, j, k) = 0: tabla2(i, j, k) = 0: NEXT: NEXT: NEXT
FOR i = 1 TO 7
FOR j = 1 TO i
  p = 1
  WHILE p = 1
    szin = INT(myrnd(1, 0) * 4) + 1
    szam = INT(myrnd(1, 0) * 13) + 1
    IF deck(szin, szam) = 1 THEN p = 0
  WEND
  checksum = checksum + szin * szam * i * j
  deck(szin, szam) = 0
  tabla(i, j, 1) = szin
  tabla(i, j, 2) = szam
  IF j <> i THEN tabla(i, j, 3) = 1
  tablaorg(i, j, 1) = tabla(i, j, 1)
  tablaorg(i, j, 2) = tabla(i, j, 2)
  tablaorg(i, j, 3) = tabla(i, j, 3)
NEXT
NEXT
  WHILE checksum >= 1000: checksum = checksum - 1000: WEND
  IF seedgiven = 1 THEN
    IF checksum <> checksumuj THEN
      COLOR 12, 4
      LOCATE 23, 48
      BEEP
      PRINT messa$(7);
      LOCATE 24, 48
      PRINT messa$(8);
      WHILE INKEY$ = "": WEND
      GOSUB drinit
    END IF
    seedgiven = 0
  END IF
  GOSUB gamenum
RETURN

gamenum:
  COLOR 0, 2
  LOCATE 23, 50
  PRINT messa$(9);
  PRINT USING "#######"; seed;
  c$ = STR$(checksum)
  c$ = RIGHT$(c$, LEN(c$) - 1)
  WHILE LEN(c$) < 3: c$ = "0" + c$: WEND
  PRINT c$;
RETURN

'load table from solitin.txt
loadtable:
FOR i = 1 TO 4: FOR j = 1 TO 13: deck(i, j) = 1: NEXT: outc(i) = 0: NEXT
FOR i = 1 TO 7: FOR j = 1 TO 24: FOR k = 1 TO 3: tabla(i, j, k) = 0: tabla2(i, j, k) = 0: NEXT: NEXT: NEXT
OPEN "solitin.txt" FOR INPUT AS #1
FOR i = 1 TO 7
FOR j = 1 TO i
INPUT #1, tabla(i, j, 1)
INPUT #1, tabla(i, j, 2)
IF i <> j THEN tabla(i, j, 3) = 1
IF deck(tabla(i, j, 1), tabla(i, j, 2)) = 0 THEN COLOR 12, 4: PRINT "*** [ERROR 03] file error": BEEP
deck(tabla(i, j, 1), tabla(i, j, 2)) = 0
NEXT
NEXT
CLOSE #1
RETURN

drinit:
showcards = 0
mouse 2
COLOR 7, 2
CLS
COLOR 0, 2
FOR j = 1 TO 24
LOCATE j, 30: PRINT "≥";
LOCATE j, 46: PRINT "≥";
NEXT
LOCATE 8, 36: PRINT messa$(10);
LOCATE 2, 37: PRINT messa$(11);
COLOR 2, 3
LOCATE 4, 32: PRINT "›  ≥  ≥  ≥  ﬁ";
COLOR 0, 2
FOR i = 1 TO 15
LOCATE 6, i + 30: PRINT "ƒ";
NEXT
LOCATE 2, 55: PRINT messa$(12)
LOCATE 3, 55: PRINT messa$(13)
LOCATE 5, 48
COLOR 4, 3: PRINT "xx";
COLOR 0, 2: PRINT messa$(14);
LOCATE 6, 51: PRINT messa$(15);
LOCATE 8, 48
COLOR 6, 2: PRINT "xx";
COLOR 0, 2: PRINT messa$(16);
LOCATE 9, 51: PRINT messa$(17);
LOCATE 11, 48: PRINT "Æ "; messa$(18);
LOCATE 12, 48
COLOR 10, 2: PRINT "Æ";
COLOR 7, 2: PRINT "Æ";
COLOR 0, 2: PRINT messa$(19);
LOCATE 13, 51: PRINT messa$(20);
LOCATE 15, 48: PRINT messa$(21);
LOCATE 16, 48: PRINT messa$(22);
LOCATE 17, 48: PRINT messa$(23);
LOCATE 18, 48: PRINT messa$(24);
LOCATE 18, 77: PRINT MID$(kartya$, 10, 1); "=10";
LOCATE 19, 48: PRINT messa$(25);
LOCATE 20, 48: PRINT messa$(26);
LOCATE 21, 48: PRINT messa$(27);
LOCATE 22, 48: PRINT messa$(28);
IF firstscreen = 1 THEN
  COLOR 10, 2
  LOCATE 19, 58 + language * 3: PRINT "<D>";
  LOCATE 19, 69 + language * 2: PRINT "<L>";
  COLOR 0, 2
END IF
mouse 1
RETURN

drawt:
mouse 2
''''''''''''''''''''''''''''''''''''''''''tabla
'delete possibility info
FOR pi = 1 TO 7: FOR pj = 1 TO 24: FOR pk = 1 TO 3: tabla2(pi, pj, pk) = 0: NEXT: NEXT: NEXT
ures = 0
vanhidden = 0
FOR i = 1 TO 7
IF tabla(i, 1, 1) = 0 AND ures = 0 THEN ures = i
IF tabla(i, 1, 3) = 1 THEN vanhidden = 1
NEXT
FOR i = 1 TO 7
jmax = 0
FOR j = 1 TO 23
IF tabla(i, j, 1) > 0 THEN
  jmax = j
  LOCATE j + 1, i * 4 - 2
  '........................... RELATIONS
  IF tabla(i, j, 3) = 1 THEN
    COLOR 9, 1
    '€showhidden
    IF showcards = 0 THEN
     PRINT "##";
    ELSE
     ttc = tabla(i, j, 1)
     IF paritycolor = 1 THEN
       ttc = (ttc - 1 + (tabla(i, j, 2) MOD 2) * 2)
       ttc = (ttc MOD 4) + 1
     END IF
     IF ttc < 3 THEN COLOR 4
     PRINT CHR$(tabla(i, j, 1) + 2); MID$(kartya$, tabla(i, j, 2), 1);
    END IF
  ELSE
    COLOR 0, 7
    '€ leader might go out
    IF j < 24 THEN IF tabla(i, j + 1, 1) = 0 AND outc(tabla(i, j, 1)) = tabla(i, j, 2) - 1 THEN COLOR 0, 3
    ttc = tabla(i, j, 1)
    IF paritycolor = 1 THEN
       ttc = (ttc - 1 + (tabla(i, j, 2) MOD 2) * 2)
       ttc = (ttc MOD 4) + 1
    END IF
    IF ttc < 3 THEN COLOR 4
    PRINT CHR$(tabla(i, j, 1) + 2); MID$(kartya$, tabla(i, j, 2), 1);
    '€mark kings
    IF j > 1 AND tabla(i, j, 2) = 13 AND ures > 0 THEN
      tabla2(i, j, 1) = 1
      tabla2(i, j, 2) = 1
      tabla2(i, j, 3) = ures
      COLOR 10, 2: PRINT "Æ";
    END IF
  END IF
END IF
NEXT j
' i = oszlopszam
' jmax = legalso sor
rajz(i, 2) = jmax
IF tabla(i, jmax, 3) = 0 THEN
j = jmax
leadszin = tabla(i, jmax, 1)
leadszam = tabla(i, jmax, 2)
l = leadszam
IF leadszin < 3 THEN p1 = 3: p2 = 4 ELSE p1 = 1: p2 = 2
'€ mark possible cards from deck
pp = 1
WHILE pp = 1
  pp = 0
  l = l - 1
  IF l > 0 THEN
  '€ mark cards on table that can be moved here
  GOSUB markcard
  j = j + 1
  ttc = p1
  IF paritycolor = 1 THEN ttc = ((ttc - 1 + (l MOD 2) * 2) MOD 4) + 1
  IF ttc < 3 THEN COLOR 6, 2 ELSE COLOR 8, 2
  LOCATE j + 1, i * 4 - 2
  IF deck(p2, l) > 0 THEN
    tabla2(i, j, 2) = p2
    tabla2(i, j, 1) = l
    pp = 1: PRINT CHR$(p2 + 2);
    rajz(i, 2) = j
  END IF
  IF deck(p1, l) > 0 THEN
    tabla2(i, j, 2 + pp) = p1
    tabla2(i, j, 1) = l
    IF pp = 1 THEN LOCATE j + 1, i * 4 - 3
    pp = 1: PRINT CHR$(p1 + 2);
    rajz(i, 2) = j
  END IF
  IF pp = 1 THEN LOCATE j + 1, i * 4 - 1: PRINT MID$(kartya$, l, 1);
  IF p1 < 3 THEN p1 = 3: p2 = 4 ELSE p1 = 1: p2 = 2
  END IF
WEND
END IF
NEXT i
IF firstscreen = 0 AND vanhidden = 0 THEN
  COLOR 14, 2: LOCATE 24, 48: PRINT messa$(29);
END IF
'torles
COLOR 7, 2
FOR i = 1 TO 7
mmm = rajz(i, 1)
IF mmm < rajz(i, 2) THEN mmm = rajz(i, 2)
IF mmm < 1 THEN mmm = 1
FOR j = 1 TO mmm
IF tabla(i, j, 1) > 0 THEN 'letezo kartya
    LOCATE j + 1, i * 4 - 3: PRINT " ";
    LOCATE j + 1, i * 4
    col = 2
    IF tabla2(i, j, 1) > 0 THEN col = 0
    IF tabla2(i, j, 1) = 1 THEN col = 7
    IF tabla2(i, j, 1) = 1 AND tabla2(i, j, 2) = 1 THEN col = 10
    IF col <> 2 THEN COLOR col: PRINT "Æ";  ELSE PRINT " ";
ELSE 'nem letezo kartya
  LOCATE j + 1, i * 4 - 3
  IF tabla2(i, j, 1) = 0 THEN
    PRINT "    ";
  ELSE
    IF tabla2(i, j, 3) = 0 THEN PRINT " ";
    LOCATE j + 1, i * 4
    PRINT " ";
  END IF
END IF
NEXT
rajz(i, 1) = rajz(i, 2)
NEXT
'''''''''''''''''''''''''''''''''''''''''''''deck
FOR j = 1 TO 4
FOR i = 1 TO 13
LOCATE i + 9, j * 3 + 30
IF deck(j, i) = 0 OR (deck(j, i) = 2 AND i = 13) THEN
IF outc(j) >= i THEN COLOR 3, 2 ELSE COLOR 0, 2
PRINT "˘˘";
ELSE
IF outc(j) = i - 1 THEN COLOR 0, 3 ELSE COLOR 0, 7
IF deck(j, i) = 2 THEN COLOR 8, 2
ttc = j
IF paritycolor = 1 THEN ttc = ((ttc - 1 + (i MOD 2) * 2) MOD 4) + 1
IF ttc < 3 THEN COLOR 4
IF ttc < 3 AND deck(j, i) = 2 THEN COLOR 6
PRINT CHR$(j + 2); MID$(kartya$, i, 1);
IF i = 13 THEN 'mark king in deck if exists empty
  COLOR 10, 2
  IF ures > 0 THEN PRINT "Æ";  ELSE PRINT " ";
END IF
END IF
NEXT
NEXT
'''''''''''''''''''''''''''''''''''''''''''''outc
FOR i = 1 TO 4
LOCATE 4, i * 3 + 30
IF outc(i) <> 0 THEN
IF i < 3 THEN COLOR 4, 7 ELSE COLOR 0, 7
PRINT CHR$(i + 2); MID$(kartya$, outc(i), 1);
ELSE
COLOR 0, 3: PRINT "  ";
END IF
NEXT
mouse 1
RETURN

markcard: 'i=oszlop l=szam, ami kell p1/p2=lehetseges szinek
FOR mi = 1 TO 7
FOR mj = 1 TO 23
IF tabla(mi, mj, 1) > 0 AND tabla(mi, mj, 3) = 0 THEN
  IF i <> mi AND tabla(mi, mj, 2) = l AND (tabla(mi, mj, 1) = p1 OR tabla(mi, mj, 1) = p2) THEN
    'a kartya jo
    IF leadszam - l < tabla2(mi, mj, 1) OR tabla2(mi, mj, 1) = 0 THEN
      tabla2(mi, mj, 1) = leadszam - l
      tabla2(mi, mj, 3) = i 'az uj oszlop
    END IF
    'ha tabla2(mi,mj,1)=1, akkor leaderre lehet rakni
    'ha nagyobb, akkor annyi-1 kartyat kell a deckrol berakni
    IF mj = 1 THEN
    tabla2(mi, mj, 2) = 1'legalsot
    ELSE
    IF tabla(mi, mj - 1, 3) = 1 THEN tabla2(mi, mj, 2) = 1'legalsot
    END IF
  END IF
END IF
NEXT
NEXT
RETURN

'=====================================================================
moving:
mbutton = 0
a$ = ""
IF autoreveal = 1 THEN GOSUB autorevealing
WHILE a$ = "" AND mbutton = 0
  a$ = INKEY$
  mouse 3
WEND
mb = mbutton
WHILE mbutton <> 0: mouse 3: WEND
IF a$ = CHR$(27) THEN mouse 2: COLOR 7, 0: CLS : SYSTEM
IF a$ = "l" THEN 'load game
  firstscreen = 0
  COLOR 14, 2
  LOCATE 24, 48
  PRINT messa$(30);
  LINE INPUT s$
  checksumuj = VAL(RIGHT$(s$, 3))
  seed = VAL(LEFT$(s$, LEN(s$) - 3))
  seedgiven = 1
  GOSUB drinit
  GOSUB osztas
END IF
IF a$ = "d" THEN
  firstscreen = 0
  GOSUB drinit: GOSUB osztas
END IF
IF firstscreen = 1 THEN GOSUB wrongclick: GOTO moving
IF mb > 2 OR a$ = "w" THEN
  GOSUB automove
  mb = 0
END IF
IF a$ = "a" THEN 'autoplay
  moved = 1
  movedfo = 0
  WHILE moved > 0
    GOSUB automove
    IF moved > 0 THEN GOSUB drawt
  WEND
END IF
IF a$ = "p" THEN paritycolor = 1 - paritycolor
IF a$ = "r" THEN GOSUB drinit: GOSUB restart
IF a$ = "s" THEN showcards = 1 - showcards
IF a$ = "m" THEN GOSUB markgame
IF a$ = "u" THEN GOSUB undo
IF mb > 0 THEN
  mx = mx / 8 + 1
  my = my / 8 + 1
IF mx < 29 AND my > 1 THEN '..........................TABLA
  oszlop = INT((mx - 1) / 4) + 1
  belul = (mx MOD 4)
  my = my - 1
  IF tabla(oszlop, my, 1) > 0 THEN '...kartya
    IF belul = 2 OR belul = 3 THEN
      IF tabla(oszlop, my, 3) = 1 THEN 'hidden
        IF tabla(oszlop, my + 1, 1) = 0 THEN '*reveal
          '€undo-nincs
          undotype = 0
          tabla(oszlop, my, 3) = 0
        ELSE
          GOSUB wrongclick
        END IF
      ELSE 'not hidden
        IF mb = 2 THEN '*move out
          IF outc(tabla(oszlop, my, 1)) = tabla(oszlop, my, 2) - 1 AND tabla(oszlop, my + 1, 1) = 0 THEN
            outc(tabla(oszlop, my, 1)) = tabla(oszlop, my, 2)
            deck(tabla(oszlop, my, 1), tabla(oszlop, my, 2)) = 2
            deck(tabla(oszlop, my, 1), tabla(oszlop, my, 2) - 1) = 0
            '€undo to-out-from-table
            undotype = 2
            undoszin = tabla(oszlop, my, 1)
            undoszam = tabla(oszlop, my, 2)
            undooszl = oszlop
            undohany = my
            tabla(oszlop, my, 1) = 0
            tabla(oszlop, my, 2) = 0
            tabla(oszlop, my, 3) = 0
          ELSE
            GOSUB wrongclick
          END IF
        ELSE '*select(move)
 'tabla2-ben a lehetseges lepeseket fogjuk tarolni
 '(x,y,z)
 'y=1
 'z=1 value: 2: king to top 1: card to below
 'z=2 value: hanyadik kartyara
 FOR pi = 1 TO 7: FOR pj = 1 TO 24: FOR pk = 1 TO 3: tabla2(pi, pj, pk) = 0: NEXT: NEXT: NEXT
          mouse 2
          pp = 0
          COLOR 14, 2
          LOCATE my + 1, oszlop * 4 - 3: PRINT "[";
          LOCATE my + 1, oszlop * 4: PRINT "]";
          'marking possibilities
          IF tabla(oszlop, my, 2) = 13 THEN 'king
            FOR mmi = 1 TO 7
              IF tabla(mmi, 1, 1) = 0 THEN
              COLOR 15, 2
              LOCATE 2, mmi * 4 - 2: PRINT "^^";
              '€onemove
              pp = pp + 1: IF pp = 1 THEN ppo = mmi
              ppk = 1
              tabla2(mmi, 1, 1) = 2
              tabla2(mmi, 1, 2) = 0
              END IF
            NEXT
          ELSE
            IF tabla(oszlop, my, 1) < 3 THEN p1 = 3: p2 = 4 ELSE p1 = 1: p2 = 2
            FOR mmi = 1 TO 7
            FOR mmj = 1 TO 23
              IF tabla(mmi, mmj + 1, 1) = 0 AND tabla(mmi, mmj, 1) > 0 AND tabla(mmi, mmj, 3) = 0 AND (tabla(mmi, mmj, 1) = p1 OR tabla(mmi, mmj, 1) = p2) AND tabla(mmi, mmj, 2) = tabla(oszlop, my, 2) + 1 THEN
              'good card
              COLOR 15, 2
              '€onemove
              pp = pp + 1: ppo = mmi: ppk = 0
              LOCATE mmj + 1, mmi * 4 - 3: PRINT "[";
              LOCATE mmj + 1, mmi * 4: PRINT "]";
              tabla2(mmi, 1, 1) = 1
              tabla2(mmi, 1, 2) = mmj
              END IF
            NEXT
            NEXT
          END IF
          mouse 1
          IF pp = 0 THEN
            GOSUB wrongclick
          ELSE  'there are possible moves
            oldy = my
            '€one move
            IF onemove = 1 AND (pp = 1 OR ppk = 1) THEN
              tim = TIMER + .15: WHILE tim > TIMER: WEND
              ujoszlop = ppo
            ELSE
            mbutton = 0
            WHILE mbutton = 0: mouse 3: WEND
            WHILE mbutton <> 0: mouse 3: WEND
            mx = mx / 8 + 1
            my = my / 8 + 1
            ujoszlop = INT((mx - 1) / 4) + 1
            END IF
            IF ujoszlop <> oszlop AND ujoszlop < 8 THEN 'NOT cancel
              also = tabla2(ujoszlop, 1, 2) + 1
              '€undo move
              undotype = 3
              undoszin = tabla(oszlop, oldy, 1)
              undoszam = tabla(oszlop, oldy, 2)
              undooszl = oszlop
              undohany = oldy
              undooszl2 = ujoszlop
              undohany2 = also
              SELECT CASE tabla2(ujoszlop, 1, 1)
              CASE 1 'move card&below to below
                WHILE tabla(oszlop, oldy, 1) > 0
                  tabla(ujoszlop, also, 1) = tabla(oszlop, oldy, 1)
                  tabla(oszlop, oldy, 1) = 0
                  tabla(ujoszlop, also, 2) = tabla(oszlop, oldy, 2)
                  tabla(oszlop, oldy, 2) = 0
                  tabla(ujoszlop, also, 3) = tabla(oszlop, oldy, 3)
                  tabla(oszlop, oldy, 3) = 0
                  also = also + 1
                  oldy = oldy + 1
                WEND
              CASE 2 'move king to top
                IF also <> 1 THEN COLOR 12, 4: PRINT "KING ERROR": SYSTEM
                WHILE tabla(oszlop, oldy, 1) > 0
                  tabla(ujoszlop, also, 1) = tabla(oszlop, oldy, 1)
                  tabla(oszlop, oldy, 1) = 0
                  tabla(ujoszlop, also, 2) = tabla(oszlop, oldy, 2)
                  tabla(oszlop, oldy, 2) = 0
                  tabla(ujoszlop, also, 3) = tabla(oszlop, oldy, 3)
                  tabla(oszlop, oldy, 3) = 0
                  also = also + 1
                  oldy = oldy + 1
                WEND
              CASE ELSE
                GOSUB wrongclick
              END SELECT
            END IF
          END IF
        END IF
      END IF
    ELSE
      GOSUB wrongclick
    END IF
  ELSE '...lehetoseg, vagy teljesen rossz click
  'info: oszlop, belul, my
    IF tabla(oszlop, my - 1, 1) > 0 THEN
    p1 = 0
    IF belul = 1 THEN p1 = tabla2(oszlop, my, 3)
    IF belul = 2 THEN p1 = tabla2(oszlop, my, 2)
    IF p1 = 0 THEN
      GOSUB wrongclick
    ELSE
      '€undo from-deck
      undotype = 1
      undoszam = tabla2(oszlop, my, 1)
      undoszin = p1
      undohany = my
      undooszl = oszlop
      tabla(oszlop, my, 2) = tabla2(oszlop, my, 1)
      tabla(oszlop, my, 1) = p1
      tabla(oszlop, my, 3) = 0
      IF deck(p1, tabla(oszlop, my, 2)) = 2 THEN 'in-from-out
        undotype = 5
        deck(p1, tabla(oszlop, my, 2) - 1) = 2
        outc(p1) = outc(p1) - 1
      END IF
      deck(p1, tabla(oszlop, my, 2)) = 0
    END IF
    ELSE
      GOSUB wrongclick
    END IF
  END IF
ELSE '......................................DECK (up & king)
  mszin = INT((mx - 33) / 3) + 1
  mszam = my - 9
  IF (mx MOD 3) = 2 THEN mszin = 0
  IF mszin < 1 OR mszin > 4 OR mszam < 1 OR mszam > 13 THEN
    GOSUB wrongclick
  ELSE
    IF mb = 2 THEN 'move out
      IF outc(mszin) = mszam - 1 AND deck(mszin, mszam) = 1 THEN
        '€undo out-from-deck
        undotype = 4
        undoszin = mszin
        undoszam = mszam
        outc(mszin) = mszam
        deck(mszin, mszam) = 2
        deck(mszin, mszam - 1) = 0
      ELSE
        GOSUB wrongclick
      END IF
    ELSE
      ures = 0
      FOR i = 1 TO 7
      IF tabla(i, 1, 1) = 0 THEN ures = 1
      NEXT
      IF mszam = 13 AND ures = 1 AND deck(mszin, mszam) > 0 THEN
        pp = 0
        mouse 2
        COLOR 14, 2
        LOCATE 22, mszin * 3 + 29: PRINT "[";
        LOCATE 22, mszin * 3 + 32: PRINT "]";
        COLOR 15, 2
        FOR i = 1 TO 7
        IF tabla(i, 1, 1) = 0 THEN
          LOCATE 2, i * 4 - 2: PRINT "^^";
          '€onemove
          pp = pp + 1: IF pp = 1 THEN ppo = i
        END IF
        NEXT
        mouse 1
        '€onemove
        IF onemove = 1 AND pp > 0 THEN
          tim = TIMER + timewait: WHILE tim > TIMER: WEND
          oszlop = ppo
        ELSE
        mbutton = 0
        WHILE mbutton = 0: mouse 3: WEND
        mb = mbutton
        WHILE mbutton <> 0: mouse 3: WEND
        mx = mx / 8 + 1
        my = my / 8 + 1
        oszlop = INT((mx - 1) / 4) + 1
        END IF
        IF oszlop > 0 AND oszlop < 8 THEN
        IF tabla(oszlop, 1, 1) = 0 THEN
          '€undo from-deck
          undotype = 1
          undoszin = mszin
          undoszam = mszam
          undooszl = oszlop
          undohany = 1
          deck(mszin, mszam) = 0
          tabla(oszlop, 1, 1) = mszin
          tabla(oszlop, 1, 2) = mszam
          tabla(oszlop, 1, 3) = 0
        ELSE
          GOSUB wrongclick
        END IF
        ELSE
          GOSUB wrongclick
        END IF
        COLOR 14, 2
        mouse 2
        LOCATE 22, mszin * 3 + 29: PRINT " ";
        LOCATE 22, mszin * 3 + 32: PRINT " ";
        mouse 1
      ELSE
        GOSUB wrongclick
      END IF
    END IF
  END IF
END IF
END IF
RETURN

autorevealing:
FOR tmpj = 1 TO 7
  FOR tmpi = 1 TO 7
    IF tabla(tmpj, tmpi, 3) = 1 AND tabla(tmpj, tmpi + 1, 1) = 0 THEN
      COLOR 11, 2
      LOCATE tmpi + 1, tmpj * 4 - 3: PRINT "[";
      LOCATE tmpi + 1, tmpj * 4: PRINT "]";
      tim = TIMER + timewait
      WHILE tim > TIMER: WEND
      tabla(tmpj, tmpi, 3) = 0
      a$ = "autoreveal" 'so that screen is redrawn
      undotype = 0
    END IF
  NEXT
NEXT
RETURN

undo:
SELECT CASE undotype
CASE 1 'from-deck
  deck(undoszin, undoszam) = 1
  tabla(undooszl, undohany, 1) = 0
  tabla(undooszl, undohany, 2) = 0
  tabla(undooszl, undohany, 3) = 0
CASE 5 'from-out
  outc(undoszin) = undoszam
  tabla(undooszl, undohany, 1) = 0
  tabla(undooszl, undohany, 2) = 0
  tabla(undooszl, undohany, 3) = 0
CASE 2 'out-from-table
  IF outc(undoszin) = undoszam AND tabla(undooszl, undohany, 1) = 0 THEN
    outc(undoszin) = undoszam - 1
    tabla(undooszl, undohany, 1) = undoszin
    tabla(undooszl, undohany, 2) = undoszam
    tabla(undooszl, undohany, 3) = 0
  ELSE
    COLOR 12, 4: PRINT "*** [ERROR 04] undo 2 error";
  END IF
CASE 3 'move
  IF tabla(undooszl, undohany, 1) = 0 THEN
    ui = undohany2
    uii = undohany
    WHILE tabla(undooszl2, ui, 1) > 0
      tabla(undooszl, uii, 1) = tabla(undooszl2, ui, 1)
      tabla(undooszl, uii, 2) = tabla(undooszl2, ui, 2)
      tabla(undooszl, uii, 3) = tabla(undooszl2, ui, 3)
      tabla(undooszl2, ui, 1) = 0
      tabla(undooszl2, ui, 2) = 0
      tabla(undooszl2, ui, 3) = 0
      uii = uii + 1
      ui = ui + 1
    WEND
  ELSE
    COLOR 12, 4: PRINT "*** [ERROR 05] undo 3 error";
  END IF
CASE 4 'out-from-deck
  IF outc(undoszin) = undoszam THEN
    outc(undoszin) = undoszam - 1
    deck(undoszin, undoszam) = 1
  ELSE
    COLOR 12, 4: PRINT "*** [ERROR 06] undo 4 error";
  END IF
CASE ELSE
  GOSUB wrongclick
END SELECT
'Checking deck=2
FOR tmpi = 1 TO 4
FOR tmpj = 1 TO 13
IF deck(tmpi, tmpj) = 2 THEN deck(tmpi, tmpj) = 0
NEXT
deck(tmpi, outc(tmpi)) = 2
NEXT
undotype = 0
RETURN

wrongclick:
SOUND 1000, .03
RETURN

'=================================================================
automove:
undotype = 0
moved = 0
'*****reveal
FOR i = 1 TO 7
FOR j = 1 TO 23
IF moved = 0 AND tabla(i, j, 3) = 1 AND tabla(i, j + 1, 1) = 0 THEN
  moved = 1
  tabla(i, j, 3) = 0
END IF
NEXT
NEXT
IF moved = 1 THEN GOTO amoveend
'*****out-fromtable
IF movedfo = 0 THEN
p = 13
FOR i = 1 TO 4
IF outc(i) < p THEN p = outc(i)
NEXT
FOR i = 1 TO 7
FOR j = 1 TO 23
IF moved = 0 AND tabla(i, j + 1, 1) = 0 AND tabla(i, j, 2) <= p + 3 AND tabla(i, j, 2) = outc(tabla(i, j, 1)) + 1 THEN
  moved = 1
  outc(tabla(i, j, 1)) = tabla(i, j, 2)
  deck(tabla(i, j, 1), tabla(i, j, 2)) = 2
  deck(tabla(i, j, 1), tabla(i, j, 2) - 1) = 0
  tabla(i, j, 1) = 0
  tabla(i, j, 2) = 0
  tabla(i, j, 3) = 0
END IF
NEXT
NEXT
END IF
movedfo = 0
IF moved = 1 THEN GOTO amoveend
'*****out-fromdeck
FOR i = 1 TO 4
  IF outc(i) < 13 THEN
  IF deck(i, outc(i) + 1) = 1 AND moved = 0 AND outc(i) <= p + 2 THEN
    moved = 1
    deck(i, outc(i) + 1) = 2
    deck(i, outc(i)) = 0
    outc(i) = outc(i) + 1
    IF outc(i) = 13 THEN COLOR 7, 2: LOCATE 22, i * 3 + 32: PRINT " ";
  END IF
  END IF
NEXT
IF moved = 1 THEN GOTO amoveend
'*****leaderre
'ha nincs legalso kiraly, akkor csak akkor, ha nem a legfelso
'€€€ES HA EGY HELYRE TOBB VAN
'€ES HA TOBB LEHETSEGES HELY VAN?
nincskiraly = 1
FOR i = 1 TO 7
FOR j = 2 TO 24
IF tabla(i, j - 1, 3) = 1 AND tabla(i, j, 2) = 13 AND tabla(i, j, 3) = 0 THEN nincskiraly = 0
NEXT
NEXT
FOR i = 1 TO 7
FOR j = 1 TO 24
IF j > nincskiraly AND moved = 0 AND tabla(i, j, 1) > 0 THEN
IF tabla2(i, j, 2) = 1 AND tabla2(i, j, 1) = 1 THEN 'legalsot=1 & leaderre/hany kell=1
  'ujoszlop=tabla2(i,j,3)
  p = 24
  pt = tabla2(i, j, 3)
  WHILE tabla(pt, p, 1) = 0 AND p > 0
    p = p - 1
  WEND
  p = p + 1
  q = j
  WHILE tabla(i, q, 1) > 0
    tabla(tabla2(i, j, 3), p, 1) = tabla(i, q, 1)
    tabla(tabla2(i, j, 3), p, 2) = tabla(i, q, 2)
    tabla(tabla2(i, j, 3), p, 3) = tabla(i, q, 3)
    tabla(i, q, 1) = 0
    tabla(i, q, 2) = 0
    tabla(i, q, 3) = 0
    q = q + 1
    p = p + 1
  WEND
  moved = 1
END IF
END IF
NEXT
NEXT
IF moved = 1 THEN GOTO amoveend
'*****minimal deck (which?) // insert king (move to) // move out!
'''lehet-e ures oszlopot csinalni?
'1=van   preference:2
'2=move  preference:1
'3=out   preference:0
'4=nincs
aures = 4
aureso = 0'melyik oszlop
FOR i = 1 TO 7
IF tabla(i, 1, 1) = 0 THEN aures = 1: aureso = i
IF tabla(i, 1, 3) = 0 AND tabla(i, 1, 1) > 0 AND tabla2(i, 1, 1) = 1 AND aures > 2 THEN aures = 2: aureso = i
IF tabla(i, 1, 3) = 0 AND tabla(i, 1, 1) > 0 AND tabla(i, 2, 1) = 0 AND tabla(i, 1, 2) = outc(tabla(i, 1, 1)) + 1 AND aures > 3 THEN aures = 3: aureso = i
NEXT
'''ki lehet-e rakni valamelyik legalsot?
elviheto = 0 'az oszlop sorszama lesz az
FOR i = 1 TO 7
FOR j = 2 TO 23
IF tabla(i, j, 1) > 0 AND tabla(i, j, 3) = 0 AND tabla(i, j - 1, 3) = 1 AND tabla(i, j + 1, 1) = 0 AND tabla(i, j, 2) = outc(tabla(i, j, 1)) + 1 THEN elviheto = i
NEXT
NEXT

'''melyik kartyahoz kell a legkevesebb a deckbol
minnum = 14 'hany kartyat kell berakni
mini = 0 'oszlop // 12 vagy 34, ha kiralyt kell berakni
minj = 0 'hanyadik kartya
king12 = 14  'meddig lehet lemenni a paklibol
king34 = 14
''mi van, ha beteszunk egy kiralyt
  ''meddig lehet lemenni a paklibol
  FOR i = 13 TO 1 STEP -1
    IF (i MOD 2) = 1 THEN
      p1 = 1: p2 = 2: p3 = 3: p4 = 4
    ELSE
      p1 = 3: p2 = 4: p3 = 1: p4 = 2
    END IF
    IF i = king12 - 1 AND (deck(p1, i) <> 0 OR deck(p2, i) <> 0) THEN king12 = i
    IF i = king34 - 1 AND (deck(p3, i) <> 0 OR deck(p4, i) <> 0) THEN king34 = i
  NEXT

'vegignezzuk, melyikhez kell a legkevesebb kartya
FOR i = 1 TO 7
FOR j = 2 TO 24
  IF tabla(i, j, 1) > 0 AND tabla(i, j, 3) = 0 AND tabla(i, j - 1, 3) = 1 THEN
    IF tabla2(i, j, 1) > 0 AND tabla2(i, j, 1) - 1 < minnum THEN
      minnum = tabla2(i, j, 1) - 1
      mini = i
      minj = j
    END IF
    IF aures <> 4 THEN
     IF (tabla(i, j, 2) MOD 2) = 1 THEN
      IF tabla(i, j, 1) < 3 THEN king = king12: kking = 12 ELSE king = king34: kking = 34
     ELSE
      IF tabla(i, j, 1) < 3 THEN king = king34: kking = 34 ELSE king = king12: kking = 12
     END IF
     IF tabla(i, j, 2) >= king - 1 THEN 'le lehet menni a kartyaig
       IF 13 - tabla(i, j, 2) < minnum THEN
         minnum = 13 - tabla(i, j, 2)
         mini = kking
         minj = -1
         minii = i
         minjj = j
       END IF
     END IF
    END IF
  END IF
NEXT
NEXT

IF mini > 0 OR elviheto > 0 THEN
  moved = 1
  IF elviheto > 0 AND (minnum > 2 OR mini = 0) THEN '€€€***
    'inkabb kiviszunk egy legalsot, ha tul sokat kene berakni
    FOR j = 2 TO 24
      IF tabla(elviheto, j - 1, 3) = 1 AND tabla(elviheto, j, 1) > 0 AND tabla(elviheto, j, 3) = 0 THEN
        outc(tabla(elviheto, j, 1)) = tabla(elviheto, j, 2)
        deck(tabla(elviheto, j, 1), tabla(elviheto, j, 2) - 1) = 0
        deck(tabla(elviheto, j, 1), tabla(elviheto, j, 2)) = 2
        tabla(elviheto, j, 1) = 0
        tabla(elviheto, j, 2) = 0
        tabla(elviheto, j, 3) = 0
      END IF
    NEXT
  ELSE
    'hat akkor behozunk egyet! a paklibol
    IF mini < 8 THEN
      'nem kiralyozni kell
      oszl = tabla2(mini, minj, 3)
      j = 1
      WHILE tabla(oszl, j, 1) > 0: j = j + 1: WEND
      tabla(oszl, j, 1) = tabla2(oszl, j, 2) '€€€*** masik szint?
      tabla(oszl, j, 2) = tabla2(oszl, j, 1)
      tabla(oszl, j, 3) = 0
      IF deck(tabla(oszl, j, 1), tabla(oszl, j, 2)) = 2 THEN
        movedfo = 1 'from-out utan ne rakja ki megint
        outc(tabla(oszl, j, 1)) = outc(tabla(oszl, j, 1)) - 1
        deck(tabla(oszl, j, 1), tabla(oszl, j, 2) - 1) = 2
      END IF
      deck(tabla(oszl, j, 1), tabla(oszl, j, 2)) = 0
    ELSE
      'kiralyozni kell
      SELECT CASE aures
      CASE 1 'van
        i = i
      CASE 2 'move
        p = 24
        WHILE tabla(tabla2(aureso, 1, 3), p, 1) = 0 AND p > 0: p = p - 1: WEND
        p = p + 1
        q = 1
        WHILE tabla(aureso, q, 1) > 0
          tabla(tabla2(aureso, 1, 3), p, 1) = tabla(aureso, q, 1)
          tabla(tabla2(aureso, 1, 3), p, 2) = tabla(aureso, q, 2)
          tabla(tabla2(aureso, 1, 3), p, 3) = tabla(aureso, q, 3)
          tabla(aureso, q, 1) = 0
          tabla(aureso, q, 2) = 0
          tabla(aureso, q, 3) = 0
          q = q + 1
          p = p + 1
        WEND
      CASE 3 'out
        outc(tabla(aureso, 1, 1)) = tabla(aureso, 1, 2)
        deck(tabla(aureso, 1, 1), tabla(aureso, 1, 2)) = 2
        deck(tabla(aureso, 1, 1), tabla(aureso, 1, 2) - 1) = 0
        tabla(aureso, 1, 1) = 0
        tabla(aureso, 1, 2) = 0
        tabla(aureso, 1, 3) = 0
      CASE ELSE: COLOR 12, 4: PRINT "aures error!": SYSTEM
      END SELECT
      SELECT CASE mini
      CASE 12
        IF deck(2, 13) <> 0 THEN mini = 2
        IF deck(1, 13) <> 0 THEN mini = 1
      CASE 34
        IF deck(4, 13) <> 0 THEN mini = 4
        IF deck(3, 13) <> 0 THEN mini = 3
      CASE ELSE: COLOR 12, 4: PRINT "mini error!": SYSTEM
      END SELECT
      IF mini < 5 THEN
      tabla(aureso, 1, 1) = mini
      tabla(aureso, 1, 2) = 13
      tabla(aureso, 1, 3) = 0
      deck(mini, 13) = 0
      LOCATE 22, mini * 3 + 32: COLOR 7, 2: PRINT " ";
      ELSE
        'elofordulhat, hogy talalt egy kiralyt a tablan
        i = i
      END IF
    END IF
  END IF
END IF
IF moved > 0 THEN GOTO amoveend

amoveend:
RETURN

'===================================================
getlang:
IF language = -1 THEN
ON ERROR GOTO getlange
lanerr = 0
OPEN langfile$ FOR INPUT AS #1
IF lanerr = 1 THEN
  COLOR 7, 0
  CLS
  PRINT "CLASSIC SOLITAIRE. By/Programozta Elìd P Csirmaz"
  PRINT "Select language / V†lasszon nyelvet"
  PRINT "1: English / Angol"
  PRINT "2: Magyar / Hungarian"
  PRINT "(Your selection will be saved for future use / A v†laszt†s†t a program elmenti)"
getlang2:
  LINE INPUT l$
  language = VAL(l$)
  IF language <> 1 AND language <> 2 THEN PRINT "Please retype your selection / 1-est vagy 2-est adjon meg!": GOTO getlang2
  language = language - 1
  OPEN langfile$ FOR OUTPUT AS #1
  PRINT #1, language
  CLOSE #1
ELSE
  INPUT #1, language
  CLOSE #1
END IF
END IF
p = 1
WHILE p = 1
  READ mn
  IF mn = -1 THEN
    p = 0
  ELSE
    READ ml, m$
    IF ml = language THEN messa$(mn) = m$
  END IF
WEND
RETURN
getlange: lanerr = 1: RESUME NEXT

'messages. 0=English 1=Hungarian
'Number of messages:
DATA 50
DATA 1,0,"CLASSIC SOLITAIRE by Elod P Csirmaz"
DATA 1,1,"KLASSZIKUS SOLITAIRE. Programozta: Csirmaz Elìd P†l"
DATA 2,0,"Error opening file storing number of next game."
DATA 2,1,"A kîvetkezì j†tÇk sz†m†t tartalmaz¢ file-t nem lehet megnyitni."
DATA 3,0,"Press '1' and 'ENTER' to create a new file pointing to the first game"
DATA 3,1,"Nyomja le az '1'-et Çs az 'ENTER'-t az elsì j†tÇkra mutat¢ file lÇtrehoz†s†hoz"
DATA 4,0,"Press '2' and 'ENTER' to create a new file pointing to a random game"
DATA 4,1,"Nyomja le a '2'-ìt Çs az 'ENTER'-t, ha egy vÇletlen j†tÇkra ugrana"
DATA 5,0,"Press '3' and 'ENTER' to quit"
DATA 5,1,"Nyomja le a '3'-mat Çs az 'ENTER'-t a kilÇpÇshez"
DATA 6,0,"Please re-enter your choice"
DATA 6,1,"°rja be £jra a v†lasztott sz†mot!"
DATA 7,0,"Wrong game no. Falling back on  "
DATA 8,0,"closest table. Press any key... "
DATA 7,1,"Rossz sz†m.Elugrunk a legkîzeleb"
DATA 8,1,"-bi j†tÇkraNyomjon le egy gombot"
DATA 9,0,"Game no. "
DATA 9,1,"J†tÇk sz†ma: "
DATA 10,0,"DECK"
DATA 10,1,"PAKLI"
DATA 11,0,"OUT"
DATA 11,1,"KINT"
DATA 12,0,"SOLITAIRE Classic"
DATA 12,1,"    SOLITAIRE    "
DATA 13,0,"by Elod P Csirmaz"
DATA 13,1,"Csirmaz Elìd P†l "
DATA 14,0,"-the card can be moved 'out'"
DATA 14,1,"-a k†rty†t 'ki' lehet rakni"
DATA 15,0,"right-click on card to move"
DATA 15,1,"kattintson a jobb egÇrgombbal"
DATA 16,0,"-card can be inserted from deck"
DATA 16,1,"-a k†rty†t ide lehet tenni a"
DATA 17,0,"left-click on symbol to insert"
DATA 17,1,"paklib¢l a bal egÇrgombbal"
DATA 18,0,"-card can be made movable"
DATA 18,1,"-a k†rtya mozgathat¢v† tehetì"
DATA 19,0,"-card is movable"
DATA 19,1,"-a k†rtya mozgathat¢: a bal"
DATA 20,0,"left-click to select/move card"
DATA 20,1,"gombbal jelîljÅk ki / mozgassuk"
DATA 21,0,"Insert Kings from deck, otherwise"
DATA 22,0,"click on possibilities listed"
DATA 23,0,"below actual cards."
DATA 24,0,""
DATA 21,1,"Kir†lyok bevitelÇhez a pakliban"
DATA 22,1,"kattintsunk, m†s esetben kattint-"
DATA 23,1,"sunk a lehetìsÇgkÇnt megjelîlt"
DATA 24,1,"k†rty†kra a t†bl†n."
DATA 25,0,"<ESC>Quit <D>Deal    <L>Load game"
DATA 26,0,"<U>Undo   <R>Restart <M>Mark game"
DATA 27,0,"<S>Show hidden cards <AW>Autoplay"
DATA 28,0,"<P>Color cards according 2 parity"
DATA 25,1,"<ESC>KilÇp   <D>Oszt†s <L>Beolvas"
DATA 26,1,"<U>Visszavon <R>Elîlrìl  <M>Jelîl"
DATA 27,1,"<S>Mindent mutat     <AW>Automata"
DATA 28,1,"<P>P†ross†g szerinti sz°nezÇs    "
DATA 29,0,"Congratulations!"
DATA 29,1,"Gratul†lok!"
DATA 30,0,"Please enter game no.: "
DATA 30,1,"Adja meg a j†tÇk sz†m†t:"
DATA -1

SUB mouse (f AS INTEGER)
'0  initialize
'1  show cursor
'2  hide cursor
'3  get coordinates, button
'4  set coordinates
'10 text cursor #blink ###bgr #int ###fore | ########char
'   mx=screen mask my=cursor mask
inregs.ax = f
IF f = 4 OR f = 10 THEN
  inregs.cx = mx
  inregs.dx = my
END IF
CALL INTERRUPT(&H33, inregs, outregs)
IF f = 3 THEN
  mbutton = outregs.bx
  mx = outregs.cx
  my = outregs.dx
END IF
END SUB

FUNCTION myrnd (m AS SINGLE, s AS SINGLE)
'm=1 -> return next random number
'm=2 -> set seed
IF m = 2 THEN
  myseed = s
  myrnd = -1
END IF
IF m = 1 THEN
  myseed = myseed * 65537
  myseed = ((17 * myseed + 19837) MOD 65537)
  myseed = myseed / 65537
  myrnd = myseed
END IF
END FUNCTION

