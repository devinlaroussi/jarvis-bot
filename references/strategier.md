# Strategibiblioteket

Scannern (`scripts\scan.ps1`) kör de automatiska strategierna nedan på TradingView-data. Verktygen längre ner används manuellt i djupanalys (TradingView via Claude i Chrome, eller webbsökning). Devins egen metod har alltid företräde. Grunden för allt är Devins `tradingbibeln.md`: där finns alla verktyg, inställningar och namngivna strategier med exakta regler. Här står hur de är omsatta i Jarvis.

Bibelns regim-regel: trendstrategier förlorar i range och mean reversion förlorar i trend. ADX (över 25 trend, under 20 range), volatilitet och HTF-struktur avgör vilken strategi som gäller.

## Automatiska strategier

| Nyckel | Namn | Villkor (alla måste gälla) | Entry / BOS | Stopp | Mål |
|---|---|---|---|---|---|
| `pullback` | Rekyl + absorption (Devins BOS-metod) | Pris > SMA200 och SMA50 > SMA200. Dagens låga ≤ 1 % över zonen EMA21–SMA50 och stängning ≥ 1,5 % under zonens botten. Stängning i övre halvan av dagens spann (absorption). RSI 38–56. | Över de två senaste dagarnas topp + 0,05 ATR | Under de två dagarnas lägsta − 0,25 ATR (minst 1 ATR) | Närmaste av 1-mån-, 3-mån- och 52-veckorshögsta |
| `trend` | Trendledare nära toppen (Minervinis trendmall) | Pris > SMA50 > SMA150 > SMA200, SMA200 stigande, pris ≥ 75 % av 52v-högsta och ≥ 130 % av 52v-lägsta. RSI 55–72, högst 8 % från 52v-högsta, +15 % på 3 mån. | 1-mån-högsta (om inom 4 %) annars 2-dagarstopp | EMA21 − 0,5 ATR (1,5–3 ATR) | 52v-högsta, annars 2R |
| `breakout` | Utbrott ur konsolidering (VCP/squeeze) | Upptrend. Högst 3,5 % under 3-mån-högsta. Bollingerbredd ≤ 9 % av SMA20. RSI 50–70. | 3-mån-högsta + 0,05 ATR | Bollinger nedre (1,5–2,5 ATR) | 52v-högsta, annars 2R |
| `swing` | Swing-screener 1–2 veckor (grundlistan) | Börsvärde > 10 mdr, över SMA200, SMA50 > SMA200, RSI 40–62, +10 % på 3 mån, högst 3 % från SMA50, MACD över signal, ingen rapport inom 10 dagar. | 2-dagarstopp | SMA50 − 0,5 ATR (minst 1 ATR) | 3-mån-högsta, 52v-högsta |
| `accum` | Ackumulation (köpvolym) | Pris > SMA50 > SMA200, relativ volym ≥ 2, dagen +2 % eller mer, stängning i övre fjärdedelen, RSI ≤ 74. | Över dagens topp | Dagens lägsta − 0,25 ATR (minst 1 ATR) | 1-mån-, 3-mån-, 52v-högsta |
| `gapgo` | Gap upp som håller (post-earnings drift om rapport senaste 3 dagarna) | Gap ≥ 3 %, stängning ≥ öppning, övre 40 % av spannet, relativ volym ≥ 1,5, över SMA50. | Över dagens topp | Under öppning/lägsta − 0,25 ATR (minst 1 ATR) | 3-mån-, 52v-högsta |
| `gcross` | Golden cross | SMA50 korsade över SMA200 i dag (var under i går) och priset över SMA50. | 2-dagarstopp | Under lägsta av SMA50/SMA200 − 0,5 ATR | 3-mån-, 52v-högsta |
| `oversold` | Översåld i upptrend (Connors RSI 2) | Pris > SMA200, SMA50 > SMA200, RSI(2) ≤ 10, +3 mån positivt. Kortsiktig studs, inte swing. | Över dagens topp | Dagens lägsta − 0,5 ATR (minst 0,6 ATR) | SMA20, 1-mån-högsta |
| `holygrail` | Holy Grail (Linda Raschke, från bibeln, sedan 23 okt) | Upptrend (pris > SMA200, SMA50 > SMA200), ADX(14) ≥ 30 och stigande, +DI > −DI, dagens låga ≤ 0,5 % över EMA20 och stängning högst 1 % under EMA20. | Köpstopp över dagens topp + 0,05 ATR | Dagens lägsta − 0,25 ATR (minst 1 ATR) | 1-mån-, 3-mån-, 52v-högsta |

### Blankning (short), sedan 23 okt

Spegelbilden av köpstrategierna. BOS nedåt = stängning under senaste lägsta, stopp ovanför senaste toppen (minst 1 ATR), mål vid stöd under. Regler i `handelsplan.md` avsnitt 7.

| Nyckel | Namn | Villkor | Entry (BOS nedåt) | Stopp | Mål |
|---|---|---|---|---|---|
| `sbounce` | Blanka rekyl i nedtrend | Pris < SMA200 och SMA50 < SMA200. Dagens topp når zonen EMA21–SMA50 och stängning högst 1,5 % över zonen, stängning i nedre halvan av spannet, RSI 44–62. | Under de två senaste dagarnas lägsta − 0,05 ATR | Över de två dagarnas topp + 0,25 ATR | 1-mån-, 3-mån-, 52v-lägsta |
| `strend` | Blanka svag trend (steg 4) | Pris < SMA50 < SMA150 < SMA200, SMA200 faller, högst 8 % över 52v-lägsta, RSI 28–45, −15 % på 3 mån. | 1-mån-lägsta (om inom 4 %), annars 2-dagarsbotten | EMA21 + 0,5 ATR (1,5–3 ATR) | 52v-lägsta, annars 2R |
| `sbreak` | Blanka utbrott nedåt | Nedtrend, högst 3,5 % över 3-mån-lägsta, Bollingerbredd ≤ 9 %, RSI 30–50. | 3-mån-lägsta − 0,05 ATR | Bollinger övre (1,5–2,5 ATR) | 52v-lägsta, annars 2R |
| `sgapdown` | Blanka gap ned som håller | Gap ≤ −3 %, stängning ≤ öppning, nedre 40 % av spannet, relativ volym ≥ 1,5, under SMA50. | Under dagens lägsta | Över öppning/topp + 0,25 ATR | 3-mån-, 52v-lägsta |
| `soverbought` | Blanka överköpt i nedtrend | Pris < SMA200, SMA50 < SMA200, RSI(2) ≥ 90, 3 mån negativt. Kort studs nedåt. | Under dagens lägsta | Dagens topp + 0,5 ATR | SMA20, 1-mån-lägsta |
| `sdcross` | Blanka death cross | SMA50 korsade under SMA200 i dag och priset under SMA50. | 2-dagarsbotten | Över högsta av SMA50/SMA200 + 0,5 ATR | 3-mån-, 52v-lägsta |

Betyg för blankning: samma poäng för R/R, närhet och rapport, men steg 4 +15 (nedtrend +8), relativ svaghet 15 × (1 − percentil), 3 mån ≥ 10 procentenheter svagare än index +5, säljvolym +5, stängning nära botten +5, TradingViews betyg under −0,1 +5. Avdrag: RSI under 28 −10 och högst B, risk-on −8, neutral −4; risk-off +4. `sbounce` +5 och `sgapdown` +3.

Koppling till bibelns namngivna strategier: `trend` = Minervinis trendmall (utan VCP-mätning), `breakout` = VCP/TTM Squeeze-idén (smala Bollingerband nära toppen; utbrottet ska ha minst 1,5–2 × snittvolym, kontrollera vid BOS), `oversold` = Connors RSI(2), `holygrail` = Raschke, `pullback` = Devins absorption + BOS i bibelns pullback-familj, `gapgo` = earnings drift (PEAD) / episodic pivot light.

Universum: USA över 10 mdr USD, Sverige över 5 mdr SEK, krypto topp 120 (utan stablecoins och wrappade tokens; BTC, ETH, SOL och XRP ligger i bevakningslistan och visas inte som kandidater). Stopp bredare än 15 % tas bort. Gemensamt: likviditet minst 30 MUSD/dag (USA), 10 MSEK/dag (Sverige) eller 50 MUSD/dygn (krypto). Kandidater utan minst 1:1,5 till ett verkligt motstånd tas bort, utom när det inte finns något motstånd ovanför (då mål = 2R och flaggas). Max 3 per sektor i urvalet.

## Betyg (0–100)

- R/R till första nivån: ≥ 3 → 25, ≥ 2 → 18, ≥ 1,5 → 8. Mål = 2R utan motstånd → 10.
- Trend: steg 2 → 15, upptrend → 8.
- Relativ styrka: percentil på 6 månaders utveckling inom universumet × 15.
- Närhet till trigger: ≤ 1,5 % → 10, ≤ 3 % → 5.
- Volym över 1,2 × snitt på en uppgång → 5. Stängning i övre tredjedelen → 5. TradingViews tekniska betyg > 0,1 → 5, < −0,3 → −5.
- Avdrag: RSI > 72 → −10. Rapport inom 7 dagar → −20, inom 14 → −10. Stopp bredare än 8 % → −8. Risk-off → −8 (utom översåld), Försiktig → −4 för trend och utbrott.
- Relativ styrka mot jämförelseindex (S&P 500 för USA, OMXS30 för Sverige, BTC för krypto) på 3 månader: ≥ +10 procentenheter → +5, ≤ −10 → −3 och flagga.
- Rekyl-strategin (Devins metod) får +5, ackumulation och gap +3. Krypto −3 (större svängningar). Försiktig marknad −4 även för golden cross.
- A ≥ 65, B ≥ 50, C ≥ 38. D visas inte. Tak enligt Devins regler: under 1:2 till nivå, rapport inom 14 dagar eller RSI över 72 ger högst B. Rapport inom 7 dagar ger högst C.

## Sektorrotation och bredd

- Medianutveckling per sektor (USA, minst 5 bolag) för vecka, 1 och 3 månader, samt andel över SMA50 och SMA200. Används för att se vart pengarna går. Kandidater i de starkaste sektorerna väger tyngre i bedömningen, i de svagaste lättare.
- Bredd: andel av universumet över SMA50 och SMA200 (USA och Sverige). Under 50 % över 200-dagars = skör marknad.

## Marknadsläge (regime)

- Risk-on: S&P 500 > SMA50 > SMA200 och VIX < 18. Normal storlek.
- Neutral: över 200-dagars utan tydlig riktning. Bara A och B.
- Försiktig: S&P under SMA50 eller VIX 18–25. Halv storlek, kräv BOS med volym.
- Risk-off: S&P under SMA200 eller VIX > 25. Inga nya långa swingar utom A, halv storlek.

## Djupanalys med bibelns verktyg (automatisk, sedan 24 okt)

Devin 24 okt: "använd alla strategier och det du kan när det är rimligt ... bara på de som ens är attraktiva". Scannern letar brett bland alla instrument med de färdiga värdena från TradingView. Därefter hämtar `scripts\djupanalys.ps1` kurshistorik (Yahoo: 1 år dag, 60 dagar timme, 4h byggs av timdata) för de högst 40 attraktiva lägena (betyg A eller B, högst 8 % från triggern) och för bevakningslistan (via `update.ps1`, mot nivåerna BOS och fel om i Jarvis). Det tar cirka 25 sekunder.

- **Verktyg:** FVG (dag och 4h, med displacement; bara zoner som inte stängts igenom, med fyllnadsgrad och 50 %-nivå), order block (sista motsatta candlen före en displacement som bryter de 10 senaste toppar/bottnar), likviditet (swingtoppar och -bottnar, lika toppar/bottnar inom 0,2 ATR, PDH/PDL, PWH/PWL), Fibonacci över 60 dagars dealing range (38,2 %, 50 %, golden pocket 61,8–65 %, OTE 61,8–78,6 %, premium/discount), vecko- och månadspivåer (klassiska), volymprofil 60 dagar (POC, VAH, VAL), AVWAP från rörelsens botten (köp) eller topp (blankning), SMA50 och SMA200.
- **Setups (signaler):** sweep av 20-dagarslägsta/-högsta med stängning tillbaka (Wyckoffs spring, turtle soup), Turtle 20/55 (Donchian), NR7 och inside day, TTM Squeeze (Bollinger 20/2 inuti Keltner 1,5 ATR; avfyrad när den släpper, riktning från momentum), Weinstein steg 2/4 (utbrott över stigande 30-veckors med minst 1,5x volym), episodic pivot (gap minst 8 % på minst 3x volym som håller), RSI-divergens på de två senaste swingarna, och FVG/order block i rekylzonen (SMC-entrymodellen).
- **Konfluens:** rekylzonen är mellan stoppet och priset (där nivån ska hålla). Konfluens = flest verktygsfamiljer i ett kluster inom 0,6 ATR (bibelns fib-kluster). **Hinder:** minst två verktyg på samma ställe mellan entry + 0,3R och mål 1. **Veckotrend** från 10 och 30 veckors medel.
- **Betyget:** konfluens 4+ ger +6, 3 ger +4, 2 ger +1, 1 ger −2 och 0 ger −5; setups i rätt riktning +1 till +4, setups emot −4, hinder −5, veckotrend emot −5. Justeringen görs relativ (minus medianen för dagens lägen, högst ±10), så att djupanalysen rangordnar men inte blåser upp betygen. Devins regler (1:2, rapport, RSI) sätter fortfarande tak för betyget.
- **Facit:** `scan-stats.json` har `bySetup` och `byConfluence`, så att vi ser om FVG, sweep och de andra faktiskt träffar. Bibeln om SMC: ingen bred oberoende forskning, "Testa själv". Ändra vikterna först efter 20–30 avgjorda signaler per grupp och logga i `kalibrering.md`.
- **I handelsplanen:** använd djupanalysens nivå (`deep.tools`) i `confluence` och lägg hinder före mål 1, setups emot och veckotrend emot bland `against`.

## Manuella verktyg i djupanalys

- **Devins entry:** nivå → absorption (långa vekar, hög volym, inga nya bottnar) → BOS på 1h/4h → entry på rekylen → stopp under absorptionsbotten → 1 % risk → mål nästa motstånd, minst 1:2.
- **Stockrobbers nivåtrappa:** två stöd, två motstånd, BOS över R1 öppnar R2, brott under S1 pekar mot S2. Intradag: en 5-minuterscandle ska stänga bortom nivån. Top-down: makro, tema, bolag, teknik, portfölj. Tre scenarier inför KPI/PPI/Fed. Alltid två motargument.
- **Volymprofil (FRVP):** köp i zonen vid värdeområdets kant, inte mitt i. Stopp bakom ett tunt volymområde. Rita om vid ny topp, botten eller utbrott. Använd riktig volym (börs/terminer), inte CFD.
- **Fibonacci:** dra topp till botten för en uppgång (0 % på toppen). Kontrollera att punkterna är riktiga vändpunkter. Bryts 78,6 % går kursen ofta till 100 %. Sammanfallande nivåer (FRVP + fib + glidande medel) är starkast.
- **Elliott:** impuls 1–5, korrektion A-B-C. C-mål 1,0 / 1,272 / 1,618 × A.
- **Indikatorer:** RSI 14 (70+ avstå, 25–35 med divergens = möjlig studs), MACD 12/26/9, Bollinger, ATR (stoppavstånd, avstånd till knockout), Stochastic, EMA 9/21, SMA 50/100/200 och 50/100 veckor, säsongsmönster.
- **Bottenkonfluens:** stödzon + VIX slutar stiga + divergens + avtagande säljtryck + marknaden slutar falla på dåliga nyheter.
- **Krypto:** ETF-flöden vecka för vecka (flera veckor med inflöde krävs). Token skilt från bolag.
- **Barriärsannolikhet:** P(mål före stopp) ≈ stoppavstånd / (stoppavstånd + målavstånd). Det ger förväntat värde noll utan edge. Edge måste komma från setup, trend och timing, inte från R/R i sig.
- **Fundamenta (Stockrobber):** tes med bevis, senaste rapport och guidning, EPS-revideringar, orderingång, marginaltrend, värdering mot eget snitt, katalysator och rapportdatum, peer read-across.

## Från bibeln i varje djupanalys

- **SMC-entrymodellen:** HTF-bias + pris i discount → sweep av sell-side-likviditet (PDL, Asiens low, lika bottnar) → displacement med CHoCH/MSS på LTF som lämnar FVG/order block → limit-entry i FVG/OB, stopp under sweep-veken → mål närmaste buy-side-likviditet. Det är samma idé som Devins absorption + BOS och Wyckoffs spring.
- **Konfluens:** en nivå är stark när minst två verktyg sammanfaller (S/R, fib 61,8–65 %, POC/VAL, AVWAP från rapport, PDH/PDL, månads- och veckopivåer, 200-dagars). Fib-kluster = nivåer från olika dragningar inom en halv ATR.
- **Stängning, inte veke:** ett brott kräver stängning på den egna tidsramen. Bara veken förbi = ofta likviditetsjakt.
- **Divergens är en varning, inte en trigger:** kräv CHoCH/BOS innan du agerar.
- **TradingViews Technicals-sida:** mekanisk räkning. Använd värdena som nivåer; "Strong sell" vid en botten är normalt eftersom allt släpar.
- **Stockrobber-tilläggen:** sälj en del vid M2 eller Elliott-slutmål, daglig stängning under S2 = tesen fel, två motargument, kontrollera att köpet inte ökar en drivkraft som redan är stor.

## Daytrade: backtest och facit (sedan 26 okt)

- `scripts\daytrade-lib.ps1` innehåller analysen (ORB, sweep av gårdagens high/low, VWAP-trend med rekyl, betyg, redo) och utfallet, och används av både `daytrade.ps1` och `daytrade-facit.ps1`, så att live och backtest räknas likadant. Allt räknas vid tidpunkten: bara stängda candlar, gårdagens nivåer ur förra sessionen och dagstrenden ur dagsdata före i dag.
- **Utfall** som testportföljen: stopporder vid BOS efter tidpunkten, förfaller om stoppet nås först, en tredjedel vid mål 1 (2R) och stoppet till break-even, resten vid mål 2 eller vid dagens slut. Gap ger öppningskursen. Nås stopp och mål i samma 15m-candle räknas stoppet först. Kostnad tur och retur: aktier 0,2 %, krypto 0,3 %, index och råvaror via turbo 9,5x cirka 0,11 % av underliggande.
- **Backtest** (`daytrade-facit.ps1 -Backtest`, ca 1 minut): Yahoos 15m-data 60 dagar för den fasta listan (olja, metaller, index, krypto och sex USA-aktier), varje hel timme 10–20 svensk tid. Ett läge räknas första gången det syns per dag och en gång till första gången det är redo. Varianter prövas med `-Cfg "costFloorR=0.15;noOrb=1;lateHour=19" -Tag v1` utan att ändra Jarvis statistik. Dela alltid upp i två halvor innan en slutsats dras: det som bara syns i ena halvan är brus.
- **Facit live**: `daytrade.ps1` sparar varje läge i `data\daytrade-signals.json`; `daytrade-facit.ps1 -Check` (kvällsscannen) räknar utfallet när dagen är slut. Båda skriver `data\daytrade-stats.json` → `scan/daystats`.
- **Resultat 26 okt (4 aug–23 okt):** med de gamla inställningarna brutto −0,03R och netto −0,36R per trade (kostnaden 0,33R). Inget läge hade en fördel som höll i båda halvorna. ORB och kl 19–20 var sämst. Med stopp så breda att kostnaden blir högst 0,1R, utan ORB och utan lägen efter 19: netto −0,10R, vinstfaktor 0,67, träff 41 %. Sweep var bäst (−0,07R netto), krypto och metaller nära noll. Betyg A gick inte bättre än B–D. Slutsats: de mekaniska lägena förlorar i snitt; kostnaden och för tajta stopp var den största förlusten. Det som kan ge en fördel är det backtestet inte ser: dagar med en tydlig nyhet (som Genmab 26 okt), dagens urval av aktier som rör sig mest, och omdöme. Det mäts i facit live.
- **Prövade setups 26 okt (Devin: "testa nya daytradesetups … och behåll bara det som håller i båda halvorna"):** nyhetsgap som håller (gap and go: gap minst 0,5 dags-ATR, utbrott ur öppningsrangen åt gapets håll med VWAP på rätt sida), nyhetsgap som inte håller (gap fill mot gårdagens stängning), trenddag (minst 0,6 dags-ATR från öppningen, köp på nytt dagshögsta) och ORB på första timmen. De ligger i `daytrade-lib.ps1` bakom `$DT_CFG.trial` och prövades på den fasta listan plus 28 aktier som ofta gappar (`-Universe bred`), 4 aug–23 okt, 8 175 lägen. Inget höll: alla var minus netto i minst ena halvan. Nyhetsgap blanka var +0,18R i andra halvan men −0,10R i första (22 och 33 utlösta). Med bara stora gap (minst 1 dags-ATR) blev det för få lägen, och tajtare stopp (kostnad 0,2R) var sämre överallt. Inget av dem används live; kvällsscannen prövar dem igen varje fredag (`-Trials`, resultat i `data\daytrade-trials.json` och i Jarvis).
- **5 minuter med flera tidsramar (26 okt, Devin: "du ska göra det man ska göra på daytrading, försök att samla så mycket data som möjligt"):** `scripts\daytrade5.ps1` med motorn `daytrade5-engine.ps1` (C#). Riktning från 15m (EMA20/EMA50) och VWAP, dagstrend från dagsdata, nivåer PDH/PDL, nattens high/low (terminer, krypto), öppningsrangen och VWAP. Setups på 5m: likviditetssvep med CHoCH, FVG-retest i trenden, VWAP-återtagning i trenden och ORB med retest. Stopporder som gäller 30 min (var 5:e minut) eller 60 min (varje timme). Testat 4 aug–26 okt på 67 instrument (fasta listan, 28 aktier som gappar, ETF:er, europeiska index och fler aktier), 428 997 candlar och 15 919 lägen, med två kostnader. **Resultat:** brutto +0,015R per trade (noll), netto −0,12R med billig mäklare och −0,56R med Avanza. Svep blanka klarade två halvor (+0,04/+0,03R) men inte tre delar (+0,13/−0,19/+0,16R), och svep av gårdagens high/low varje timme kom bara från oktober. Inget godkänt, inget live. **Lärdom:** på 5m blir stoppet cirka 0,15 % på index, så Avanzas turbo kostar cirka 0,7R per trade; 5-minuterstrading kräver en billig produkt (terminer eller CFD). 5m-candlarna sparas i `data\bars5` och testet görs om varje fredag på längre historik (regel: plus netto med billig mäklare i alla tre delarna och minst 50 utlösta i varje).
- **Aktier i rörelse (26 okt, `daytrade5.ps1 -InPlay`):** 300 USA-aktier (de 200 med störst omsättning och de 100 mest volatila av resten), 1,38 miljoner 5m-candlar. Av 11 933 handelsdagar var 327 "i rörelse" (gap minst 3 % och volym de första 15 minuterna minst dubbelt så stor som snittet), och de gav 1 044 lägen. **Resultat:** lägen i gapets riktning (422 st) +0,14R brutto, +0,11R netto med billig mäklare och 0,00R med Avanza. Det är det bästa hittills, eftersom stoppen är bredare och avgifterna därför små. Köpsetupsen var plus i alla tre delarna: FVG-retest +0,49/+0,12/+0,46R, svep +0,81/+0,33/+0,23R, ORB med retest +0,12/+0,01/+0,12R, ORB 15 min +0,67/+0,05/+0,08R. Men de hade bara 41–64 trades var, under regelns 50 per del. Alla lägen i gapets riktning missade i sista delen (−0,005R). **Inget godkänt än.** Testet görs om varje fredag; arkivet (`data\bars5\ip-*.json`) växer, så om 4–6 veckor bör det räcka för ett ja eller nej. Om köpsetupsen håller blir nästa steg ett test framåt i testportföljen, först när Devin sagt ja.
## Idéer att lägga till när underlaget finns

- Från bibeln (Turtle, Weinstein, episodic pivot, NR7/inside day och TTM Squeeze finns sedan 24 okt i djupanalysen): Qullamaggie-utbrott, ID-NR4, Darvas-lådor, Faber 10-månaders timing för index, och intermarket-filter (koppar/guld, HYG/IEF, VIX/VIX3M). Även breaker och mitigation block, IFVG och BPR, Silver Bullet och AMD på timdata för daytrades.

- Relativ styrka mot den egna sektorn (inte bara indexet).
- Post-earnings drift över flera dagar (kräver att gapet följs upp dag 2–3).
- Gjort 25 okt: svenska bolag från 1 mdr SEK (även First North), Norden, tio europeiska länder och Kanada (se SKILL.md). Kvar: Australien och Asien (svårare att handla från Sverige och andra handelstider).
- Inside day / NR7 och veckodata (kräver historik per aktie, kan byggas på Yahoo-data för de 200 största).
