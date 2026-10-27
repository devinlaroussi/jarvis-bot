# Djupanalys med bibelns verktyg för de attraktiva lägena (Devin 24 okt: "använd alla strategier och det du kan när det är rimligt,
# ... inte på alla 1000 stycken utan bara på de som ens är attraktiva"). Dot-sourcas av scan.ps1 (kandidaterna) och update.ps1 (bevakningslistan).
# Verktyg på riktig kurshistorik (Yahoo, 1 år dag + 60 dagar timme, 4h byggs av timdata):
#   FVG (dag, 4h), order block, likviditet (swingar, lika toppar/bottnar, PDH/PDL, PWH/PWL) och sweep med återtagning,
#   Fibonacci (dealing range, premium/discount, golden pocket, OTE), vecko- och månadspivåer, volymprofil (POC, VAH, VAL),
#   AVWAP från rörelsens start, Donchian (Turtle 20/55), NR7 och inside day, TTM Squeeze, Weinstein steg 2/4,
#   episodic pivot, RSI-divergens och veckotrend.
# Deep() ger zoner, konfluens i rekylzonen (stopp–pris), hinder före mål 1, setups och en betygsjustering (högst ±10).
# SMC-verktygen saknar bred oberoende forskning (bibeln: "Testa själv"), därför följs varje setup upp i scan-stats (bySetup, byConfluence).

function DeepBars($ysym) {
  $get = { param($range, $int)
    $u = "https://query2.finance.yahoo.com/v8/finance/chart/$([uri]::EscapeDataString($ysym))?range=$range&interval=$int"
    $res = (Invoke-RestMethod -Uri $u -Headers @{ 'User-Agent' = 'Mozilla/5.0' } -TimeoutSec 30).chart.result[0]; $q = $res.indicators.quote[0]
    $o = [Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $res.timestamp.Count; $i++) {
      if ($null -eq $q.close[$i] -or $null -eq $q.high[$i] -or $null -eq $q.low[$i] -or $null -eq $q.open[$i]) { continue }
      $v = if ($null -ne $q.volume -and $null -ne $q.volume[$i]) { [double]$q.volume[$i] } else { 0.0 }
      $o.Add([double[]]@([double]$res.timestamp[$i], [double]$q.open[$i], [double]$q.high[$i], [double]$q.low[$i], [double]$q.close[$i], $v))
    }
    , $o.ToArray() }
  @{ d = (& $get '1y' '1d'); h = (& $get '60d' '60m') }
}
# Slår ihop candles till längre tidsram (4h = 14400 s; veckor med $off = 345600 så att de börjar på måndag)
function Agg($bars, $sec, $off = 0) {
  $out = [Collections.Generic.List[object]]::new(); $cur = $null
  foreach ($b in $bars) { $k = [math]::Floor(($b[0] - $off) / $sec) * $sec + $off
    if ($null -eq $cur -or $cur[0] -ne $k) { if ($null -ne $cur) { $out.Add($cur) }; $cur = [double[]]@($k, $b[1], $b[2], $b[3], $b[4], $b[5]) }
    else { $cur[2] = [math]::Max($cur[2], $b[2]); $cur[3] = [math]::Min($cur[3], $b[3]); $cur[4] = $b[4]; $cur[5] += $b[5] } }
  if ($null -ne $cur) { $out.Add($cur) }; , $out.ToArray()
}
function DAtr($b, $n = 14) { if ($b.Count -lt $n + 1) { return [double]::NaN }; $s = 0.0
  for ($i = $b.Count - $n; $i -lt $b.Count; $i++) { $s += [math]::Max($b[$i][2] - $b[$i][3], [math]::Max([math]::Abs($b[$i][2] - $b[$i - 1][4]), [math]::Abs($b[$i][3] - $b[$i - 1][4]))) }; $s / $n }
function DSma($b, $n, $end = -1) { if ($end -lt 0) { $end = $b.Count - 1 }; if ($end - $n + 1 -lt 0) { return [double]::NaN }; $s = 0.0; for ($i = $end - $n + 1; $i -le $end; $i++) { $s += $b[$i][4] }; $s / $n }
function DRsi($b) { $r = [double[]]::new($b.Count); for ($i = 0; $i -lt $b.Count; $i++) { $r[$i] = [double]::NaN }; if ($b.Count -lt 16) { return , $r }
  $g = 0.0; $l = 0.0; for ($i = 1; $i -le 14; $i++) { $d = $b[$i][4] - $b[$i - 1][4]; if ($d -gt 0) { $g += $d } else { $l -= $d } }; $g /= 14; $l /= 14
  for ($i = 15; $i -lt $b.Count; $i++) { $d = $b[$i][4] - $b[$i - 1][4]; $g = ($g * 13 + [math]::Max($d, 0)) / 14; $l = ($l * 13 + [math]::Max(-$d, 0)) / 14; $r[$i] = if ($l -eq 0) { 100 } else { 100 - 100 / (1 + $g / $l) } }; , $r }
function Zone($tool, $fam, $kind, $lo, $hi, $note) { [pscustomobject]@{ tool = $tool; fam = $fam; kind = $kind; lo = [double][math]::Min($lo, $hi); hi = [double][math]::Max($lo, $hi); note = $note } }

# FVG: candle 1:s och candle 3:s vekar överlappar inte och mittcandlen är en displacement. Bara zoner som inte stängts igenom.
function Fvgs($b, $atr, $tf, $look = 60) {
  $out = @(); $n = $b.Count
  for ($i = [math]::Max(2, $n - $look); $i -lt $n; $i++) {
    $c1 = $b[$i - 2]; $c2 = $b[$i - 1]; $c3 = $b[$i]; $rg = $c2[2] - $c2[3]; if ($rg -le 0) { continue }
    if (-not ($rg -ge $atr -or [math]::Abs($c2[4] - $c2[1]) / $rg -ge 0.6)) { continue }
    if ($c3[3] -gt $c1[2]) { $lo = $c1[2]; $hi = $c3[3]; $bull = $true } elseif ($c3[2] -lt $c1[3]) { $lo = $c3[2]; $hi = $c1[3]; $bull = $false } else { continue }
    if ($hi - $lo -lt 0.1 * $atr) { continue }
    $dead = $false; $deep = $null
    for ($j = $i + 1; $j -lt $n; $j++) {
      if ($bull) { if ($b[$j][4] -lt $lo) { $dead = $true; break }; if ($null -eq $deep -or $b[$j][3] -lt $deep) { $deep = $b[$j][3] } }
      else { if ($b[$j][4] -gt $hi) { $dead = $true; break }; if ($null -eq $deep -or $b[$j][2] -gt $deep) { $deep = $b[$j][2] } } }
    if ($dead) { continue }
    $mid = ($lo + $hi) / 2
    $st = if ($null -eq $deep) { 'ofylld' } elseif ($bull) { if ($deep -ge $hi) { 'ofylld' } elseif ($deep -le $mid) { 'fylld till hälften' } else { 'delvis fylld' } } else { if ($deep -le $lo) { 'ofylld' } elseif ($deep -ge $mid) { 'fylld till hälften' } else { 'delvis fylld' } }
    $out += Zone "FVG $tf" 'FVG' $(if ($bull) { 'stöd' } else { 'motstånd' }) $lo $hi "$st, 50 % vid $(DF $mid)"
  }
  $out
}
# Order block: sista motsatta candlen före en displacement som bryter strukturen (stängning över/under de 10 senaste toppar/bottnar)
function Obs($b, $atr, $tf, $look = 60) {
  $out = @(); $n = $b.Count
  for ($i = [math]::Max(11, $n - $look); $i -lt $n; $i++) {
    $c = $b[$i]; $rg = $c[2] - $c[3]; if ($rg -lt 1.5 * $atr) { continue }
    $hh = -1e18; $ll = 1e18; for ($j = $i - 10; $j -lt $i; $j++) { $hh = [math]::Max($hh, $b[$j][2]); $ll = [math]::Min($ll, $b[$j][3]) }
    $bull = $c[4] -gt $c[1] -and $c[4] -ge $c[3] + 0.7 * $rg -and $c[4] -gt $hh
    $bear = $c[4] -lt $c[1] -and $c[4] -le $c[2] - 0.7 * $rg -and $c[4] -lt $ll
    if (-not ($bull -or $bear)) { continue }
    $k = -1; for ($j = $i - 1; $j -ge $i - 3; $j--) { if (($bull -and $b[$j][4] -lt $b[$j][1]) -or ($bear -and $b[$j][4] -gt $b[$j][1])) { $k = $j; break } }
    if ($k -lt 0) { continue }
    $lo = $b[$k][3]; $hi = $b[$k][2]; $dead = $false
    for ($j = $i + 1; $j -lt $n; $j++) { if (($bull -and $b[$j][4] -lt $lo) -or ($bear -and $b[$j][4] -gt $hi)) { $dead = $true; break } }
    if (-not $dead) { $out += Zone "Order block $tf" 'OB' $(if ($bull) { 'stöd' } else { 'motstånd' }) $lo $hi 'inte bruten' }
  }
  $out
}
function SwingPts($b, $k = 2, $look = 120) {
  $hs = @(); $ls = @(); $n = $b.Count
  for ($i = [math]::Max($k, $n - $look); $i -lt $n - $k; $i++) { $isH = $true; $isL = $true
    for ($j = 1; $j -le $k; $j++) { if ($b[$i][2] -le $b[$i - $j][2] -or $b[$i][2] -lt $b[$i + $j][2]) { $isH = $false }; if ($b[$i][3] -ge $b[$i - $j][3] -or $b[$i][3] -gt $b[$i + $j][3]) { $isL = $false } }
    if ($isH) { $hs += , @($i, $b[$i][2]) }; if ($isL) { $ls += , @($i, $b[$i][3]) } }
  @{ h = $hs; l = $ls }
}
$script:DDEC = 2
function DF($v) { ([double]$v).ToString("N$script:DDEC", [Globalization.CultureInfo]::GetCultureInfo('sv-SE')) }

# plan: @{ side; entry; stop; t1 } eller $null (då blir beslutszonen närmaste stöd under priset)
function Deep($D, $H, $plan, $dec = 2, $strategy = '') {
  $script:DDEC = $dec
  $n = $D.Count; if ($n -lt 60) { return $null }
  $atr = DAtr $D; if (-not ($atr -gt 0)) { return $null }
  $px = $D[$n - 1][4]; $Z = @(); $setups = @(); $notes = @()
  $sh = $plan -and $plan.side -eq 'short'; $g = if ($sh) { -1 } else { 1 }
  $H4 = if ($H -and $H.Count -gt 30) { Agg $H 14400 } else { @() }; $atr4 = if ($H4.Count -gt 20) { DAtr $H4 } else { [double]::NaN }
  # --- zoner från alla verktyg ---
  $Z += Fvgs $D $atr 'dag'; if ($atr4 -gt 0) { $Z += Fvgs $H4 $atr4 '4h' 90 }
  $Z += Obs $D $atr 'dag'; if ($atr4 -gt 0) { $Z += Obs $H4 $atr4 '4h' 90 }
  $sw = SwingPts $D
  foreach ($s in $sw.l | Select-Object -Last 6) { $Z += Zone 'Swingbotten' 'Likviditet' 'stöd' $s[1] $s[1] "$($n - 1 - $s[0]) dagar sedan" }
  foreach ($s in $sw.h | Select-Object -Last 6) { $Z += Zone 'Swingtopp' 'Likviditet' 'motstånd' $s[1] $s[1] "$($n - 1 - $s[0]) dagar sedan" }
  # lika bottnar/toppar inom 0,2 ATR = likviditetspool (stopp ligger där)
  $L6 = @($sw.l | Select-Object -Last 8); for ($i = 0; $i -lt $L6.Count; $i++) { for ($j = $i + 1; $j -lt $L6.Count; $j++) { if ([math]::Abs($L6[$i][1] - $L6[$j][1]) -le 0.2 * $atr) { $Z += Zone 'Lika bottnar' 'Likviditet' 'stöd' ([math]::Min($L6[$i][1], $L6[$j][1])) ([math]::Max($L6[$i][1], $L6[$j][1])) 'säljlikviditet under' } } }
  $H6 = @($sw.h | Select-Object -Last 8); for ($i = 0; $i -lt $H6.Count; $i++) { for ($j = $i + 1; $j -lt $H6.Count; $j++) { if ([math]::Abs($H6[$i][1] - $H6[$j][1]) -le 0.2 * $atr) { $Z += Zone 'Lika toppar' 'Likviditet' 'motstånd' ([math]::Min($H6[$i][1], $H6[$j][1])) ([math]::Max($H6[$i][1], $H6[$j][1])) 'köplikviditet över' } } }
  $Z += Zone 'PDL' 'Likviditet' 'stöd' $D[$n - 2][3] $D[$n - 2][3] 'föregående dags lägsta'; $Z += Zone 'PDH' 'Likviditet' 'motstånd' $D[$n - 2][2] $D[$n - 2][2] 'föregående dags högsta'
  # vecko- och månadsdata
  $wk = Agg $D 604800 345600; $W = $wk.Count
  # obs: PowerShell skiljer inte på stora och små bokstäver i variabelnamn, och kommatecken binder starkare än räknesätten
  if ($W -ge 3) { $pw = $wk[$W - 2]; $Z += Zone 'PWL' 'Likviditet' 'stöd' $pw[3] $pw[3] 'förra veckans lägsta'; $Z += Zone 'PWH' 'Likviditet' 'motstånd' $pw[2] $pw[2] 'förra veckans högsta'
    $piv = ($pw[2] + $pw[3] + $pw[4]) / 3; $rg = $pw[2] - $pw[3]
    foreach ($q in @(@('Veckopivå P', $piv), @('Veckopivå S1', (2 * $piv - $pw[2])), @('Veckopivå R1', (2 * $piv - $pw[3])), @('Veckopivå S2', ($piv - $rg)), @('Veckopivå R2', ($piv + $rg)))) { $Z += Zone $q[0] 'Pivå' $(if ($q[1] -lt $px) { 'stöd' } else { 'motstånd' }) $q[1] $q[1] '' } }
  $mo = @($D | Group-Object { [DateTimeOffset]::FromUnixTimeSeconds([int64]$_[0]).UtcDateTime.ToString('yyyy-MM') })
  if ($mo.Count -ge 2) { $pm = @($mo[$mo.Count - 2].Group); $mh = ($pm | ForEach-Object { $_[2] } | Measure-Object -Maximum).Maximum; $ml = ($pm | ForEach-Object { $_[3] } | Measure-Object -Minimum).Minimum; $mc = $pm[-1][4]
    $piv = ($mh + $ml + $mc) / 3; foreach ($q in @(@('Månadspivå P', $piv), @('Månadspivå S1', (2 * $piv - $mh)), @('Månadspivå R1', (2 * $piv - $ml)))) { $Z += Zone $q[0] 'Pivå' $(if ($q[1] -lt $px) { 'stöd' } else { 'motstånd' }) $q[1] $q[1] '' } }
  # Fibonacci över dealing range (60 dagar): premium/discount, golden pocket, OTE
  $R = @($D[($n - 60)..($n - 1)]); $hiI = 0; $loI = 0; for ($i = 1; $i -lt $R.Count; $i++) { if ($R[$i][2] -gt $R[$hiI][2]) { $hiI = $i }; if ($R[$i][3] -lt $R[$loI][3]) { $loI = $i } }
  $rh = $R[$hiI][2]; $rl = $R[$loI][3]; $rr = $rh - $rl; $upSwing = $loI -lt $hiI
  $eq = $rl + $rr / 2; $zonePos = if ($rr -gt 0) { ($px - $rl) / $rr } else { 0.5 }
  $fib = { param($r) if ($upSwing) { $rh - $r * $rr } else { $rl + $r * $rr } }
  if ($rr -gt 0) {
    $gp = @((& $fib 0.618), (& $fib 0.65)); $ote = @((& $fib 0.618), (& $fib 0.786))
    $Z += Zone 'Fib golden pocket' 'Fib' $(if ($upSwing) { 'stöd' } else { 'motstånd' }) $gp[0] $gp[1] "61,8–65 % av $(if ($upSwing) { 'uppgången' } else { 'nedgången' })"
    $Z += Zone 'Fib OTE' 'Fib' $(if ($upSwing) { 'stöd' } else { 'motstånd' }) $ote[0] $ote[1] '61,8–78,6 %'
    $Z += Zone 'Fib 50 %' 'Fib' $(if ($px -gt $eq) { 'stöd' } else { 'motstånd' }) $eq $eq 'jämvikt (premium över, discount under)'
    $Z += Zone 'Fib 38,2 %' 'Fib' $(if ($upSwing) { 'stöd' } else { 'motstånd' }) (& $fib 0.382) (& $fib 0.382) ''
  }
  # volymprofil 60 dagar: POC, VAH, VAL (bara med riktig volym)
  $vol = ($R | ForEach-Object { $_[5] } | Measure-Object -Sum).Sum
  if ($vol -gt 0 -and $rr -gt 0) {
    $nb = 40; $bins = [double[]]::new($nb); $bw = $rr / $nb
    foreach ($b in $R) { $b0 = [math]::Max(0, [math]::Min($nb - 1, [math]::Floor(($b[3] - $rl) / $bw))); $b1 = [math]::Max(0, [math]::Min($nb - 1, [math]::Floor(($b[2] - $rl) / $bw))); $k = $b1 - $b0 + 1; for ($i = $b0; $i -le $b1; $i++) { $bins[$i] += $b[5] / $k } }
    $poc = 0; for ($i = 1; $i -lt $nb; $i++) { if ($bins[$i] -gt $bins[$poc]) { $poc = $i } }
    $lo = $poc; $hi = $poc; $acc = $bins[$poc]; while ($acc -lt 0.7 * $vol -and ($lo -gt 0 -or $hi -lt $nb - 1)) { $dn = if ($lo -gt 0) { $bins[$lo - 1] } else { -1 }; $upv = if ($hi -lt $nb - 1) { $bins[$hi + 1] } else { -1 }; if ($upv -ge $dn) { $hi++; $acc += $bins[$hi] } else { $lo--; $acc += $bins[$lo] } }
    $pocP = $rl + ($poc + 0.5) * $bw; $vah = $rl + ($hi + 1) * $bw; $val = $rl + $lo * $bw
    $Z += Zone 'POC' 'Volymprofil' $(if ($pocP -lt $px) { 'stöd' } else { 'motstånd' }) $pocP $pocP '60 dagar'
    $Z += Zone 'VAL' 'Volymprofil' 'stöd' $val $val 'värdeområdets botten'; $Z += Zone 'VAH' 'Volymprofil' 'motstånd' $vah $vah 'värdeområdets topp'
    # AVWAP från rörelsens start (botten vid köp, toppen vid blankning)
    $ai = if ($sh) { $hiI } else { $loI }; $pv = 0.0; $vv = 0.0; for ($i = $ai; $i -lt $R.Count; $i++) { $tp = ($R[$i][2] + $R[$i][3] + $R[$i][4]) / 3; $pv += $tp * $R[$i][5]; $vv += $R[$i][5] }
    if ($vv -gt 0) { $av = $pv / $vv; $Z += Zone 'AVWAP' 'AVWAP' $(if ($av -lt $px) { 'stöd' } else { 'motstånd' }) $av $av "från $(if ($sh) { 'toppen' } else { 'botten' }) för $($R.Count - 1 - $ai) dagar sedan" }
  }
  foreach ($m in @(@('SMA50', 50), @('SMA200', 200))) { $v = DSma $D $m[1]; if ($v -gt 0) { $Z += Zone $m[0] 'Glidande medel' $(if ($v -lt $px) { 'stöd' } else { 'motstånd' }) $v $v '' } }

  # --- setups (signaler) ---
  $last = $D[$n - 1]; $prev = $D[$n - 2]
  # sweep och återtagning: de två senaste dagarna sticker under 20-dagarslägsta (eller över högsta) och stänger tillbaka
  foreach ($i in ($n - 1), ($n - 2)) { $lo20 = 1e18; $hi20 = -1e18; for ($j = $i - 20; $j -lt $i; $j++) { $lo20 = [math]::Min($lo20, $D[$j][3]); $hi20 = [math]::Max($hi20, $D[$j][2]) }
    if ($D[$i][3] -lt $lo20 -and $D[$i][4] -gt $lo20 -and $px -gt $lo20) { $setups += @{ k = 'sweep'; side = 'long'; t = "Sweep av 20-dagarslägsta $(DF $lo20) och stängning tillbaka över" }; break }
    if ($D[$i][2] -gt $hi20 -and $D[$i][4] -lt $hi20 -and $px -lt $hi20) { $setups += @{ k = 'sweep'; side = 'short'; t = "Sweep av 20-dagarshögsta $(DF $hi20) och stängning tillbaka under" }; break } }
  # Donchian / Turtle 20 och 55
  $h20 = -1e18; $l20 = 1e18; $h55 = -1e18; $l55 = 1e18
  for ($j = $n - 56; $j -lt $n - 1; $j++) { if ($j -lt 0) { continue }; if ($j -ge $n - 21) { $h20 = [math]::Max($h20, $D[$j][2]); $l20 = [math]::Min($l20, $D[$j][3]) }; $h55 = [math]::Max($h55, $D[$j][2]); $l55 = [math]::Min($l55, $D[$j][3]) }
  if ($px -gt $h55) { $setups += @{ k = 'turtle'; side = 'long'; t = "Turtle 55: stängning över 55-dagarshögsta $(DF $h55)" } } elseif ($px -gt $h20) { $setups += @{ k = 'turtle'; side = 'long'; t = "Turtle 20: stängning över 20-dagarshögsta $(DF $h20)" } }
  if ($px -lt $l55) { $setups += @{ k = 'turtle'; side = 'short'; t = "Turtle 55: stängning under 55-dagarslägsta $(DF $l55)" } } elseif ($px -lt $l20) { $setups += @{ k = 'turtle'; side = 'short'; t = "Turtle 20: stängning under 20-dagarslägsta $(DF $l20)" } }
  # NR7 och inside day: snäv range före rörelse
  $rgs = @(for ($j = $n - 7; $j -lt $n; $j++) { $D[$j][2] - $D[$j][3] }); $nr7 = ($last[2] - $last[3]) -le ($rgs | Measure-Object -Minimum).Minimum
  $inside = $last[2] -lt $prev[2] -and $last[3] -gt $prev[3]
  if ($nr7 -or $inside) { $setups += @{ k = 'nr7'; side = 'both'; t = $(if ($nr7 -and $inside) { 'NR7 och inside day: snävaste dagen på en vecka, utbrott nära' } elseif ($nr7) { 'NR7: snävaste dagen på sju dagar' } else { 'Inside day: dagens range inom gårdagens' }) } }
  # TTM Squeeze: Bollinger (20, 2) inuti Keltner (20, 1,5 ATR); avfyrad när den släpper
  $sq = { param($e) $m = DSma $D 20 $e; $s = 0.0; for ($j = $e - 19; $j -le $e; $j++) { $s += [math]::Pow($D[$j][4] - $m, 2) }; $sd = [math]::Sqrt($s / 20); (2 * $sd) -lt (1.5 * $atr) }
  $sqNow = & $sq ($n - 1); $sqPrev = & $sq ($n - 2); $mom = $px - ((($h20 + $l20) / 2) + (DSma $D 20)) / 2
  if ($sqPrev -and -not $sqNow) { $setups += @{ k = 'squeeze'; side = $(if ($mom -gt 0) { 'long' } else { 'short' }); t = "TTM Squeeze avfyrad $(if ($mom -gt 0) { 'uppåt' } else { 'nedåt' })" } }
  elseif ($sqNow) { $notes += 'TTM Squeeze på: volatiliteten är ihoptryckt, ett utbrott brukar komma' }
  # Weinstein: steg 2-utbrott (över stigande 30-veckors med volym) eller steg 4
  $s150 = DSma $D 150; $s150p = DSma $D 150 ($n - 21); $v50 = 0.0; for ($j = $n - 51; $j -lt $n - 1; $j++) { $v50 += $D[$j][5] }; $v50 /= 50
  $vr = if ($v50 -gt 0) { $last[5] / $v50 } else { 0 }
  if ($s150 -gt 0 -and $px -gt $s150 -and $s150 -gt $s150p -and $px -gt $h55 -and $vr -ge 1.5) { $setups += @{ k = 'weinstein'; side = 'long'; t = "Weinstein steg 2: utbrott över stigande 30-veckors med $([math]::Round($vr, 1))x volym" } }
  if ($s150 -gt 0 -and $px -lt $s150 -and $s150 -lt $s150p -and $px -lt $l55 -and $vr -ge 1.5) { $setups += @{ k = 'weinstein'; side = 'short'; t = "Weinstein steg 4: brott under fallande 30-veckors med $([math]::Round($vr, 1))x volym" } }
  # episodic pivot: gap på minst 8 % med 3x volym de senaste fem dagarna, och kursen håller
  for ($j = $n - 5; $j -lt $n; $j++) { $gp2 = ($D[$j][1] - $D[$j - 1][4]) / $D[$j - 1][4]; $vx = if ($v50 -gt 0) { $D[$j][5] / $v50 } else { 0 }
    if ($gp2 -ge 0.08 -and $vx -ge 3 -and $px -ge $D[$j][3]) { $setups += @{ k = 'ep'; side = 'long'; t = "Episodic pivot: gap +$([math]::Round($gp2 * 100)) % med $([math]::Round($vx))x volym, håller" }; break }
    if ($gp2 -le -0.08 -and $vx -ge 3 -and $px -le $D[$j][2]) { $setups += @{ k = 'ep'; side = 'short'; t = "Episodic pivot nedåt: gap $([math]::Round($gp2 * 100)) % med $([math]::Round($vx))x volym, håller" }; break } }
  # RSI-divergens på de två senaste swingarna (40 dagar)
  $rsi = DRsi $D; $l2 = @($sw.l | Where-Object { $_[0] -ge $n - 40 } | Select-Object -Last 2); $hh2 = @($sw.h | Where-Object { $_[0] -ge $n - 40 } | Select-Object -Last 2)
  if ($l2.Count -eq 2 -and $l2[1][1] -lt $l2[0][1] -and $rsi[$l2[1][0]] -gt $rsi[$l2[0][0]] + 2) { $setups += @{ k = 'div'; side = 'long'; t = 'Positiv RSI-divergens: lägre botten i pris, högre i RSI' } }
  if ($hh2.Count -eq 2 -and $hh2[1][1] -gt $hh2[0][1] -and $rsi[$hh2[1][0]] -lt $rsi[$hh2[0][0]] - 2) { $setups += @{ k = 'div'; side = 'short'; t = 'Negativ RSI-divergens: högre topp i pris, lägre i RSI' } }
  # veckotrend (10 och 30 veckor)
  $wc = @($wk | ForEach-Object { $_[4] }); $w10 = if ($W -ge 10) { ($wc[($W - 10)..($W - 1)] | Measure-Object -Average).Average } else { [double]::NaN }; $w30 = if ($W -ge 30) { ($wc[($W - 30)..($W - 1)] | Measure-Object -Average).Average } else { [double]::NaN }
  $wTrend = if ($w30 -gt 0 -and $px -gt $w10 -and $w10 -gt $w30) { 'upp' } elseif ($w30 -gt 0 -and $px -lt $w10 -and $w10 -lt $w30) { 'ned' } else { 'sidled' }

  # --- rekylzonen och konfluens ---
  # Rekylzonen är där nivån ska hålla: mellan stoppet och priset (eller entry om priset redan är förbi). Konfluens = flest
  # verktygsfamiljer i ett kluster inom 0,6 ATR (bibeln: nivåer inom ungefär en halv ATR från varandra bildar ett kluster).
  if ($plan -and $plan.entry -gt 0 -and $plan.stop -gt 0) {
    if ($sh) { $zlo = [math]::Max($px, $plan.entry) - 0.1 * $atr; $zhi = $plan.stop + 0.1 * $atr } else { $zlo = $plan.stop - 0.1 * $atr; $zhi = [math]::Min($px, $plan.entry) + 0.1 * $atr }
  } else { $zlo = $px - 1.5 * $atr; $zhi = $px + 0.1 * $atr }   # bevakning utan plan: närmaste stöd under priset
  $want = if ($sh) { 'motstånd' } else { 'stöd' }
  $hit = @($Z | Where-Object { $zhi -gt $zlo -and $_.hi -ge $zlo -and $_.lo -le $zhi -and ($_.kind -eq $want -or $_.fam -in 'Fib', 'Volymprofil', 'Pivå', 'AVWAP', 'Glidande medel') } | Sort-Object { ($_.lo + $_.hi) / 2 })
  $best = @(); $bestF = 0; $bestD = 1e18
  foreach ($a0 in $hit) { $m0 = ($a0.lo + $a0.hi) / 2; $cl = @($hit | Where-Object { $m = ($_.lo + $_.hi) / 2; $m -ge $m0 - 1e-9 -and $m -le $m0 + 0.6 * $atr })
    $nf0 = @($cl | ForEach-Object { $_.fam } | Sort-Object -Unique).Count; $dd = [math]::Abs($m0 - $px)
    if ($nf0 -gt $bestF -or ($nf0 -eq $bestF -and $dd -lt $bestD)) { $best = $cl; $bestF = $nf0; $bestD = $dd } }
  $fams = @($best | ForEach-Object { $_.fam } | Sort-Object -Unique)
  # klustrets läge räknas på zonernas mitt, så att en bred FVG inte gör nivån bredare än den är
  $clLo = if ($best.Count) { ($best | ForEach-Object { ($_.lo + $_.hi) / 2 } | Measure-Object -Minimum).Minimum } else { $null }; $clHi = if ($best.Count) { ($best | ForEach-Object { ($_.lo + $_.hi) / 2 } | Measure-Object -Maximum).Maximum } else { $null }
  # FVG eller order block i rekylzonen i trendens riktning = SMC-entrymodellen (sweep/absorption → BOS → rekyl in i FVG/OB)
  $smc = @($hit | Where-Object { $_.fam -in 'FVG', 'OB' -and $_.kind -eq $want } | Sort-Object { [math]::Abs(($_.lo + $_.hi) / 2 - $px) })
  if ($smc.Count) { $setups += @{ k = 'fvg'; side = $(if ($sh) { 'short' } else { 'long' }); t = "$($smc[0].tool) $(DF $smc[0].lo)–$(DF $smc[0].hi) i rekylzonen ($($smc[0].note))" } }
  # hinder före mål 1: minst två verktyg på samma ställe mellan entry + 0,3R och mål 1
  $obst = $null
  if ($plan -and $plan.t1 -gt 0 -and $g * ($plan.t1 - $plan.entry) -gt 0) { $risk = [math]::Abs($plan.entry - $plan.stop); $a = $plan.entry + $g * 0.3 * $risk; $b2 = $plan.t1 - $g * 0.1 * $risk; $olo = [math]::Min($a, $b2); $ohi = [math]::Max($a, $b2)
    $opp = if ($sh) { 'stöd' } else { 'motstånd' }
    $cand = @($Z | Where-Object { $_.kind -eq $opp -and $_.fam -ne 'Glidande medel' -and $_.hi -ge $olo -and $_.lo -le $ohi } | Sort-Object { $g * $_.lo })
    foreach ($c in $cand) { $near = @($cand | Where-Object { [math]::Abs(($_.lo + $_.hi) / 2 - ($c.lo + $c.hi) / 2) -le 0.5 * $atr } | ForEach-Object { $_.fam } | Sort-Object -Unique)
      if ($near.Count -ge 2) { $obst = "$($near -join ' + ') vid $(DF (($c.lo + $c.hi) / 2)) före mål 1"; break } } }

  # --- betygsjustering (högst ±12) ---
  $adj = 0; $why = @()
  # de flesta lägen har något verktyg i närheten, så skalan är centrerad: bara starka kluster lyfter, svaga drar ned
  $nf = $fams.Count; if ($nf -ge 4) { $adj += 6 } elseif ($nf -eq 3) { $adj += 4 } elseif ($nf -eq 2) { $adj += 1 } elseif ($nf -eq 1) { $adj -= 2; $why += 'bara ett verktyg i rekylzonen' } else { $adj -= 5; $why += 'ingen nivå med konfluens i rekylzonen' }
  $side = if ($sh) { 'short' } else { 'long' }
  $al = @($setups | Where-Object { $_.side -eq $side -or $_.side -eq 'both' }); $ag = @($setups | Where-Object { $_.side -ne $side -and $_.side -ne 'both' })
  foreach ($s in $al) { $adj += @{ sweep = 4; fvg = 2; squeeze = 3; turtle = 2; weinstein = 3; ep = 3; nr7 = 1; div = 3 }[$s.k] }
  foreach ($s in $ag) { if ($s.k -in 'div', 'sweep', 'squeeze', 'weinstein', 'ep') { $adj -= 4; $why += "emot: $($s.t)" } }
  if ($obst) { $adj -= 5; $why += "hinder: $obst" }
  if (($wTrend -eq 'ned' -and -not $sh) -or ($wTrend -eq 'upp' -and $sh)) { $adj -= 5; $why += "veckotrenden är $wTrend" } elseif (($wTrend -eq 'upp' -and -not $sh) -or ($wTrend -eq 'ned' -and $sh)) { $adj += 2 }
  if ($strategy -in 'pullback', 'holygrail', 'swing', 'oversold' -and $zonePos -lt 0.5 -and $upSwing) { $adj += 3 } elseif ($strategy -in 'sbounce', 'soverbought' -and $zonePos -gt 0.5 -and -not $upSwing) { $adj += 3 }
  $adj = [math]::Max(-10, [math]::Min(10, $adj))

  $top = @($best | Sort-Object { [array]::IndexOf(@('FVG', 'OB', 'Fib', 'Volymprofil', 'AVWAP', 'Likviditet', 'Pivå', 'Glidande medel'), $_.fam) } | Group-Object fam | ForEach-Object { $_.Group[0] })
  $ztxt = ($top | ForEach-Object { if ([math]::Abs($_.hi - $_.lo) -lt 1e-9) { "$($_.tool) $(DF $_.lo)" } else { "$($_.tool) $(DF $_.lo)–$(DF $_.hi)" } }) -join ', '
  $pd = if ($rr -gt 0) { if ($zonePos -gt 0.5) { "premium ($([math]::Round($zonePos * 100)) % av rangen)" } else { "discount ($([math]::Round($zonePos * 100)) % av rangen)" } } else { '' }
  $text = $(if ($nf) { "Starkaste nivån $(DF $clLo)–$(DF $clHi) med $nf verktyg: $ztxt." } else { 'Ingen nivå med konfluens i rekylzonen.' }) + $(if ($al.Count) { ' ' + (($al | ForEach-Object { $_.t }) -join '. ') + '.' } else { '' }) + $(if ($obst) { " Hinder: $obst." } else { '' }) + " Veckotrend $wTrend, pris i $pd."
  [ordered]@{
    at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'); atr = [math]::Round($atr, 6); confl = $nf; fams = $fams; adj = $adj; why = $why; text = $text
    cluster = $(if ($nf) { @([math]::Round($clLo, 6), [math]::Round($clHi, 6)) } else { $null })
    zone = @([math]::Round($zlo, 6), [math]::Round($zhi, 6)); tools = @($top | ForEach-Object { [ordered]@{ tool = $_.tool; fam = $_.fam; lo = [math]::Round($_.lo, 6); hi = [math]::Round($_.hi, 6); note = $_.note } })
    setups = @($setups | ForEach-Object { [ordered]@{ k = $_.k; side = $_.side; t = $_.t } }); obstacle = $obst; weekly = $wTrend; premium = $(if ($rr -gt 0) { [math]::Round($zonePos, 2) } else { $null }); notes = $notes
    levels = @($Z | Where-Object { [math]::Abs((($_.lo + $_.hi) / 2) - $px) -le 3 * $atr -and $_.fam -in 'FVG', 'OB', 'Volymprofil', 'Fib', 'AVWAP' } | Sort-Object { ($_.lo + $_.hi) / 2 } -Descending | Select-Object -First 12 | ForEach-Object { [ordered]@{ tool = $_.tool; kind = $_.kind; lo = [math]::Round($_.lo, 6); hi = [math]::Round($_.hi, 6); note = $_.note } })
  }
}
