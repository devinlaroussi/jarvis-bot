# Kunskapsbank för Jarvis

Fakta och tumregler som används i varje analys. Grunden är Devins `tradingbibeln.md`; här står det korta som behövs ofta, plus det som är specifikt för Devin. Det som är ett förslag (inte Devins egen regel) är markerat som förslag. Kontrollera alltid produktspecifika siffror på Avanzas produktsida.

## Marknadstider (svensk tid)

- Stockholmsbörsen: 09.00–17.30.
- USA (NYSE/Nasdaq): 15.30–22.00. Under de veckor då USA och Europa inte bytt till/från sommartid samtidigt är det 14.30–21.00. USA byter andra söndagen i mars och första söndagen i november, EU sista söndagen i mars och sista söndagen i oktober. 2026: 26–30 oktober öppnar USA 14.30.
- Krypto: dygnet runt, alla dagar. Helger har tunnare likviditet och fler svep genom nivåer. Dagscandlen stänger vid UTC-midnatt: 02.00 sommartid, 01.00 vintertid.
- Guld, silver och koppar (terminer): nästan dygnet runt söndag kväll till fredag kväll. Dagscandlen för guld och forex stänger cirka 23.00 (17.00 New York).
- Högst volym: Stockholm första och sista timmen, USA 15.30–17.00, London–New York-överlappet cirka 14.00–17.30. Killzones (ICT): Asien cirka 02–06, London 08–11, New York 13–16.
- Övriga tider: ECB 14.15, Riksbanken 09.30, EIA-oljelager onsdagar 16.30.
- USA-siffror (KPI, jobbrapport, PCE, PPI) släpps normalt 14.30 svensk tid (13.30 när tidsskillnaden är en timme mindre). Feds räntebesked 20.00, presskonferens 20.30 (en timme tidigare under omställningsveckorna).
- Scannerns USA-data före 15.30 är föregående dags stängning. Säg det i svaret.

## Avanzas hävstångsprodukter

- **Mini future (Mini L/S):** har en finansieringsnivå och en stop loss-nivå strax före. Hävstång ≈ underliggande / (underliggande − finansieringsnivå) för Mini L, så hävstången stiger när kursen närmar sig stoppet. Finansieringsnivån justeras löpande (finansieringskostnad). Träffas stop loss-nivån avvecklas produkten och ett eventuellt restvärde betalas ut, vilket kan bli nära noll vid gap.
- **Turbo (Turbo L/S):** knockout-nivån är en barriär. Nås den förfaller produkten normalt värdelös. Därför ska knockout ligga under S2 och helst minst 1,5–2 ATR från entry (lärdom från en tidigare affär).
- **Bull/Bear (X2–X15):** fast daglig hävstång som nollställs varje dag. I en fram-och-tillbaka-marknad tappar de värde även om underliggande står still. Exempel: +10 % och sedan −10 % ger underliggande −1 %, men X5 ger +50 % och sedan −50 % = −25 %. Passar för några timmar till dagar, inte för att vänta på en vändning i veckor.
- **Storlek med hävstång:** risk i kr = 1 % × kapital. Produkten rör sig ungefär stoppavstånd i % × aktuell hävstång. Köp för = risk i kr / (stoppavstånd × hävstång). För minis: räkna med hävstången vid stoppnivån, inte vid entry (den är högre där).
- **Övrigt:** emittentrisk (produkten är en skuld från banken), spread mellan köp och sälj, och valutarisk om produkten inte är valutasäkrad. Ange ISIN eller produktnamn när du hänvisar till en produkt.

## Skatt (kort, allmänt)

- ISK och kapitalförsäkring: schablonskatt på kapitalunderlaget. Inkomstår 2026: cirka 1,065 % effektivt (statslåneräntan + 1 procentenhet = 3,55 %, × 30 %), och de första 300 000 kr är skattefria (gemensam grundnivå för ISK och KF). Vinster beskattas inte separat och förluster ger inget avdrag. Aktiv trading görs därför oftast på ISK.
- Vanlig depå (AF): vinster beskattas med 30 %. Förluster på noterade aktier och fonder kvittas fullt mot vinster av samma slag, resten till 70 %. Brytpunkt mot ISK cirka 3,55 % avkastning per år. Varje affär redovisas på K4.
- Krypto direkt: 30 % på vinst, varje byte är en avyttring (genomsnittsmetoden, K4 avsnitt D), förluster 70 % avdragsgilla. Krypto-ETP kan ligga på ISK. Kontrollera alltid Skatteverkets aktuella regler.

## Makro: vad som brukar röra vad

- Varmare inflation än väntat ger högre räntor och starkare dollar, och pressar tillväxtaktier, guld och krypto. Kallare ger oftast det motsatta.
- Fed: marknaden handlar på överraskningen mot förväntan (CME FedWatch visar sannolikheter). Mindre positioner före beskedet.
- Oljechock: inflationsoro, energiaktier upp, tankrederier upp. Det drabbar konsument och flyg.
- Starkare dollar (DXY) brukar pressa guld, silver, koppar och tillväxtmarknader.
- VIX över 20: större svängningar, fler falska utbrott. VIX över 25–30: risk-off, kortare tidshorisont.
- Marknadsbredd: när färre än hälften av aktierna ligger över sitt 200-dagars medelvärde bär indexet få bolag och är skörare.
- Rapportsäsongen börjar cirka två veckor efter kvartalsslut (mitten av januari, april, juli och oktober), med de stora bankerna först.

## Säsongsmönster (statistik, inga garantier)

- November–april har historiskt varit starkare än maj–oktober för aktier. September har historiskt varit svagast.
- Guld har ofta varit starkt december–februari.
- Bitcoin har en halveringscykel cirka vart fjärde år (senaste i april 2024).
- Använd säsong bara som en bisak och aldrig som skäl att gå in.

## Devins korrelationer

- Guld och silver rör sig ihop, och silver svänger mer. Koppar följer tillväxt och Kina.
- BTC följer Nasdaq, riskaptit och likviditet. ETH, SOL och XRP följer BTC med större utslag.
- Micron, Alphabet och Nasdaq är samma AI- och tech-risk.
- Kontrollera att en ny trade inte ökar en drivkraft (ränta och olja, riskaptit, AI och tech) som redan är stor i portföljen.

## Risk och psykologi

- Devins regler: max 1 % risk per trade, minst 1:2, ingen entry utan BOS, ingen hämndtrading, inga nya trades samma dag efter en förlust.
- Break-even-träffprocent = 1 / (1 + R/R): 1:1 → 50 %, 1:2 → 33 %, 1:3 → 25 %. En strategi med 40 % träff och 1:2 tjänar 0,2 R per trade innan avgifter.
- Från Tradingbibeln (Devins dokument, gäller som standard): högst 3–5 % total öppen risk (Jarvis använder 5 %), korrelerade positioner (till exempel BTC + ETH + SOL, eller Micron + Alphabet) räknas som en, daglig förlustgräns −3R och veckovis −6R, paus efter två förluster i rad, break-even först efter 1–1,5R eller ny BOS (inte för tidigt), skala ut (en tredjedel vid mål 1, resten trailas), ATR-stopp 1,5–2 × ATR när strukturen inte ger en tydligare plats, högst halv Kelly.
- Förslag (stäm av med Devin): aldrig snitta ner i en hävstångsprodukt.
- Förlustsviter är normala: med 40 % träff är 8 förluster i rad ungefär 50 % sannolikt under 100 trades. En förlustsvit bevisar inte att strategin är trasig; utvärdera först efter 30–50 trades.
- Osäkerhet i träffprocent kring 50 % (95 %): ±18 procentenheter efter 30 trades, ±10 efter 100, ±4 efter 500.
- Varje trade ska in i journalen med setup, planerad risk, resultat och om reglerna följdes. Analysera journalen när den har minst 10 trades.

## Datakällor

- TradingViews scanner (`scanner.tradingview.com/<marknad>/scan`, marknader america, sweden, coin, global, cfd, futures, crypto): pris, förändring, RSI, RSI(2), MACD, SMA/EMA, ATR, ADX, Bollinger, utveckling W/1M/3M/6M/YTD, 1M/3M/52v-högsta och -lägsta, relativ volym, gap, börsvärde, sektor, bransch, rapportdatum (nästa och senaste), teknisk rating. Fält med [1] är föregående dag.
- Yahoo Finance chart-API (`query2.finance.yahoo.com/v8/finance/chart/<symbol>`): dags- och timdata. Svenska aktier har suffixet .ST (VOLV-B.ST), krypto -USD. Guld- och silverspot saknas, så använd GC=F och SI=F förskjutna till spotpriset.
- Webbsökning: nyheter, rapportdatum, guidning, Fed/KPI-förväntningar, ETF-flöden för krypto (vecka för vecka).
- TradingView i Chrome (Claude i Chrome): en egen layout och watchlist. Rita med `TradingViewApi.activeChart().createShape(...)`. Den är asynkron, så vänta på rätt symbol efter `setSymbol`, och kör högst 1–2 symboler per anrop. Rensa egna linjer via prefix i texten. Layouten måste sparas.
