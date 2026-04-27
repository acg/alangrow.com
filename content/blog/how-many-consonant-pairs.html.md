
    {
      "#extend": [ "../_include/blog.json" ],
      "page": {
        "title": "How Many Consonant Pairs Do We Actually Use?",
        "date": "2012-02-26T00:00:00-0000",
        "root": ".."
      }
    }

Of all possible consonant pairs, how many are actually used in the English language?

The question came up at a party during a disappointing Ouija board session where the spirits conjured gibberish like "QHPEV." Someone wondered aloud how difficult it was to pick a valid pair of consonants at random. We suspected most were invalid.

This is a nice little problem for the unix text processing toolset. I used the [2006 Scrabble Tournament Word List](https://norvig.com/ngrams/TWL06.txt) because `/usr/share/dict/words` contains many proper names and non-words. To get the count:

```sh
curl https://norvig.com/ngrams/TWL06.txt |
sed -nEe 's/(..)/\1\n/gp; s/\n//g; s/^.//; s/(..)/\1\n/gp;' |
grep '[^AEIOUY][^AEIOUY]' |
sort -u |
wc -l
```

A quick rundown of the shell pipeline:

- `s/(..)/\1\n/gp` splits & print pairs at even boundaries.
- `s/\n//gp` undoes the splits.
- `s/^.//` shifts even pair boundaries to odd ones.
- `s/(..)/\1\n/gp` splits & print pairs at odd boundaries.
- `grep '[^AEIOUY][^AEIOUY]'` filters out pairs with vowels.
- `sort -u | wc -l` counts unique consonant pairs.

There are 20 consonants in the language after removing AEIOUY, so that makes 400 possible pairs of consonants. Surprisingly, the count comes to 320, so 80% of all consonant pairs are in use!

### Finding Example Words

If, like me, you're incredulous about this 80% number, then the next thing to do is report an example word for each consonant pair. How can GJ and ZD appear in real words?

We can modify the pipeline like so:

```sh
< TWL06.txt \
sed -nEe 's/(..)/\1\n/gp; s/\n//g; s/^.//; s/(..)/\1\n/gp;' |
grep '[^AEIOUY][^AEIOUY]' |
sort -u |
xargs -n1 sh -c \
  'printf "%s " "$0"; exec grep --color -m1 "$0" TWL06.txt'
```

This is inefficient. It re-greps the wordlist file 320 times. But computers are fast, and doing the stupid simple thing is also a core tenet of the unix philosophy (["when in doubt, use brute force"](http://www.catb.org/jargon/html/B/brute-force.html)). After a moment you'll see results:

    BB ABBA
    BC ABCOULOMB
    BD ABDICABLE
    BF ABFARAD
    BG CRABGRASS
    BH ABHENRIES
    BJ ABJECT
    BK BABKA
    BL ABATABLE
    BM ABMHO
    BN ABNEGATE
    BP BOMBPROOF
    BR ABBREVIATE
    BS ABCOULOMBS
    BT BOBTAIL
    BV ABVOLT
    BW ABWATT
    BZ SUBZERO
    CB ECBOLIC
    CC ACCEDE
    CD ANECDOTA
    CH ABRACHIA
    CK ABACK
    CL ACCLAIM
    CM ACMATIC
    CN ACNE
    CP SECPAR
    CQ ACQUAINT
    CR ACCREDIT
    CS ACADEMICS
    CT ABACTERIAL
    CW COLICWEED
    CZ CZAR
    DB BANDBOX
    DC BEDCHAIR
    DD ADD DF AIDFUL
    DG ABRIDGE
    DH ACIDHEAD
    DJ ADJACENCE
    DK BODKIN
    DL ABASEDLY
    DM ADMAN
    DN ABSTRACTEDNESS
    DP BALDPATE
    DQ BEDQUILT
    DR ACHLORHYDRIA
    DS ABFARADS
    DT BANDWIDTH
    DV AARDVARK
    DW AARDWOLF
    DZ ADZ
    FB GOOFBALL
    FC BEEFCAKE
    FD CHEFDOM
    FF AFF
    FG AFGHAN
    FH HALFHEARTED
    FJ FJELD
    FK OFFKEY
    FL ACRIFLAVINE
    FM ENFEOFFMENT
    FN ALOOFNESS
    FP HALFPENCE
    FR AFFRAY
    FS AIRPROOFS
    FT ABAFT
    FW BEEFWOOD
    GB BOGBEAN
    GC DOGCART
    GD AMYGDALA
    GF BAGFUL
    GG ABEGGING
    GH AARGH
    GJ GJETOST
    GK BANGKOK
    GL ABIDINGLY
    GM ABRIDGMENT
    GN ACCEPTINGNESS
    GP BAGPIPE
    GR ABOVEGROUND
    GS ABLINGS
    GT BANGTAIL
    GV DOGVANE
    GW BAGWIG
    GZ ZIGZAG
    HB AITCHBONE
    HC AHCHOO
    HD ARCHDEACON
    HF ARCHFIEND
    HG BEACHGOER
    HH AARRGHH
    HJ HIGHJACK
    HK BABUSHKA
    HL ACHLORHYDRIA
    HM ABASHMENT
    HN AMATEURISHNESS
    HP ARCHPRIEST
    HQ EARTHQUAKE
    HR ACHROMAT
    HS AAHS
    HT ABOUGHT
    HV BOSCHVARK
    HW ARCHWAY
    HZ MACHZOR
    JD SLOJD
    JJ HAJJ
    JK PIROJKI
    JN JNANA
    JR HIJRA
    JS RIJSTAFEL
    KB ANTIKICKBACK
    KC BACKCAST
    KD BACKDATE
    KF BACKFIELD
    KG BACKGAMMON
    KH ANKH
    KJ BLACKJACK
    KK BOOKKEEPER
    KL ANKLE
    KM ATTACKMAN
    KN ACKNOWLEDGE
    KP BACKPACK
    KR BACKREST
    KS AARDVARKS
    KT BACKTRACK
    KV AKVAVIT
    KW ANTICLOCKWISE
    LB ALB
    LC ACETYLCHOLINE
    LD ABUILDING
    LF AARDWOLF
    LG ALGA
    LH ALLHEAL
    LJ KABELJOU
    LK ALKAHEST
    LL ABDOMINALLY
    LM ABELMOSK
    LN ACCIDENTALNESS
    LP ALP
    LQ CALQUE
    LR ALREADY
    LS AALS
    LT ABVOLT
    LV AARDWOLVES
    LW AGALWOOD
    LX CALX
    LZ BRULZIE
    MB ABCOULOMB
    MC ARMCHAIR
    MD DUMDUM
    MF AIMFUL
    MG FILMGOER
    MH ABMHO
    MJ CIRCUMJACENT
    MK BOOMKIN
    ML AIMLESS
    MM ACCOMMODATE
    MN ALMNER
    MP ABAMP
    MQ CUMQUAT
    MR ALUMROOT
    MS ABLEISMS
    MT AMTRAC
    MV CIRCUMVALLATE
    MW BANTAMWEIGHT
    MZ HAMZA
    NB BEANBAG
    NC ABERRANCE
    ND ABANDON
    NF ANFRACTUOSITIES
    NG AAHING
    NH ALPENHORN
    NJ BANJAX
    NK ANANKE
    NL ACTIONLESS
    NM ABANDONMENT
    NN AGINNER
    NP AFFENPINSCHER
    NQ BANQUET
    NR ABHENRIES
    NS ABANDONS
    NT ABANDONMENT
    NV ANTICONVULSANT
    NW BETWEENWHILES
    NX ANTIANXIETY
    NZ APOENZYME
    PB CHAPBOOK
    PC CAMPCRAFT
    PD CLAMPDOWN
    PF CAMPFIRE
    PG CAMPGROUND
    PH ACALEPH
    PJ CHEAPJACK
    PK BUMPKIN
    PL ACCOMPLICE
    PM ANTIDEVELOPMENT
    PN ACAPNIA
    PP AIRDROPPED
    PR ACUPRESSURE
    PS ABAMPS
    PT ABRUPT
    PW DEEPWATER
    QS BUQSHA
    QW QWERTY
    RB ABSORB
    RC ACRITARCH
    RD AARDVARK
    RF AIRFARE
    RG AARGH
    RH ACHLORHYDRIA
    RJ ALFORJA
    RK AARDVARK
    RL ACTORLY
    RM ABNORMAL
    RN ABORNING
    RP ABSORPTANCE
    RQ ARQUEBUS
    RR AARRGH
    RS ABANDONERS
    RT ABORT
    RV ACERVATE
    RW AFTERWARD
    RZ BILHARZIA
    SB AMPHISBAENA
    SC ABSCESS
    SD ASDIC
    SF ARMSFUL
    SG ALMSGIVER
    SH ABASH
    SJ CROSSJACK
    SK ABELMOSK
    SL ABSTEMIOUSLY
    SM ABLEISM
    SN ABSTEMIOUSNESS
    SP ACROSPIRE
    SQ ANTIMOSQUITO
    SR ASRAMA
    SS ABBESS
    ST ABIOGENIST
    SV AASVOGEL
    SW ANSWER
    SZ GROSZ
    TB ANTBEAR
    TC ABBOTCIES
    TD CANTDOG
    TF ARTFUL
    TG BATGIRL
    TH ABSINTH
    TJ BOOTJACK
    TK CATKIN
    TL ABERRANTLY
    TM ABETMENT
    TN ABJECTNESS
    TP AGITPROP
    TQ COTQUEAN
    TR ABSTRACT
    TS ABANDONMENTS
    TT ABATTIS
    TV BODDHISATTVA
    TW ARTWORK
    TZ BLINTZ
    VD HAVDALAH
    VG AVGAS
    VK SOVKHOZ
    VL GRAVLAKS
    VN CZAREVNA
    VR BAHUVRIHI
    VS DEVS
    VV CHIVVIED
    VZ EVZONE
    WB BAWBEE
    WC BAWCOCK
    WD BAWD
    WF AWFUL
    WG BELOWGROUND
    WH ANTIWHALING
    WJ BLOWJOB
    WK AWKWARD
    WL ACKNOWLEDGE
    WM AWMOUS
    WN ADOWN
    WP BLOWPIPE
    WR ANTIWRINKLE
    WS ADVOWSON
    WT ANTIGROWTH
    WW ARROWWOOD
    WZ BLOWZED
    XB BOXBALL
    XC BOXCAR
    XD SEXDECILLION
    XF BOXFISH
    XG FLUXGATE
    XH BOXHAUL
    XL AXLE
    XM AFFIXMENT
    XN COMPLEXNESS
    XP BLAXPLOITATION
    XQ EXQUISITE
    XS AXSEED
    XT ADMIXT
    XV POXVIRUS
    XW BOXWOOD
    ZB JAZZBO
    ZC BUZZCUT
    ZD SAMIZDAT
    ZG FIZGIG
    ZH MUZHIK
    ZJ MUZJIK
    ZK BLITZKRIEG
    ZL AZLON
    ZM GIZMO
    ZN BIZNAGA
    ZP CHUTZPA
    ZQ MEZQUIT
    ZS BRITZSKA
    ZT FUZZTONE
    ZV MITZVAH
    ZW BUZZWIG
    ZZ ABUZZ
