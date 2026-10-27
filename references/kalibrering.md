# Kalibreringslogg för scannern

Skriv en rad per ändring: datum, vad som ändrades i `scripts\scan.ps1`, varför (med siffror från `data\scan-stats.json`).

| Datum | Ändring | Varför |
|---|---|---|
| 2026-10-23 | Första versionen (v2). Minsta stopp 1 ATR (0,6 för översåld), krav på minst 1:1,5 till nivå, strängare betyg (A ≥ 65), rapport inom 7 dagar −20 och inom 14 −10, D-betyg visas inte, indexdata krävs för marknadsläget. | Första körningen gav orealistiska stopp (Solventum 0,4 %, R/R 16) och för många A-betyg. Indexen saknades först, så läget blev felaktigt Neutral i stället för Försiktig. |
| 2026-10-26 | Daytrade-scannern (scripts\daytrade-lib.ps1, $DT_CFG): stoppet minst så brett att kostnaden tur och retur blir högst 0,1R (för index och råvaror via turbo cirka 1 %, aktier 2 %, krypto 3 %), inga ORB-lägen och inga redo lägen från kl 19. Samtidigt rättat: den pågående 15m-candlen räknades som stängd när Yahoo lade till en punkt för senaste avslutet. | Backtest 4 aug–23 okt (daytrade-facit.ps1 -Backtest, 18 instrument, 2 696 lägen): brutto −0,03R och netto −0,36R per trade, kostnaden 0,33R (DAX 0,45R, krypto 0,52R). ORB sämst i båda halvorna (−0,16R och −0,06R brutto), kl 19–20 sämst i båda halvorna. Med ändringen: netto −0,10R, vinstfaktor 0,67. Betyg A gick inte bättre än B–D, så betygen har ännu ingen förklaringskraft; fynden om låg volym och mot dagstrenden höll inte i båda halvorna och ändrades inte. |
