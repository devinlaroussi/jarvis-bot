# C#-motorn för daytrade på 5 minuter (källkoden som en here-sträng, så att den följer med skripten till GitHub). Laddas av daytrade5.ps1.
$DT5_CS = @'
// Daytrade på 5 minuter med flera tidsramar (Devin 26 okt: "du ska göra det man ska göra på daytrading, försök att samla så mycket data
// som möjligt"). Används av daytrade5.ps1, både för backtest och live, så att lägen och utfall räknas likadant.
// Uppifrån och ned: riktning från 15m (EMA20 mot EMA50, aggregerad av 5m-candlarna) och VWAP, dagstrend från dagsdata före i dag,
// nivåer: gårdagens high/low (PDH/PDL), nattens high/low (ONH/ONL, för terminer och krypto), öppningsrangen 30 min (ORH/ORL), VWAP,
// dagens high/low. Setups på 5m:
//   sweep5: likviditetssvep av en nivå (PDL/ONL/ORL) med stängning tillbaka, entry när strukturen före svepet bryts (CHoCH), stopp under svepet
//   fvg5:   i riktningen, retest av ett färskt FVG (skapat av en kraftig 5m-candle) som håller, entry över retestcandlen
//   vwap5:  i riktningen och med dagstrenden, rekyl till VWAP och stängning tillbaka, entry över candlen
//   orbr:   utbrott ur öppningsrangen och retest av nivån som håller, de första 2,5 timmarna
// Order: stopporder vid entry, gäller validSec, förfaller om stoppet nås först. Utfall som testportföljen: en tredjedel vid 2R och
// stoppet till break-even, resten vid mål 2 (3R eller nästa nivå) eller vid dagens slut. Stopp före mål i samma candle (försiktigt).
using System;
using System.Collections.Generic;

public class Dt5Sig {
  public string Key; public int Side; public int Day; public double AtT; public double Entry; public double Stop; public double T1; public double T2;
  public double Risk; public double Atr5; public double Px; public double Vwap; public int Bias; public int TrendD; public string Level;
  public string Status; public string Reason; public double R; public double Mfe; public bool T1Hit; public bool Ambig; public double FillT; public double ExitT; public double Gap;
}

public class Dt5Fvg { public double Bot; public double Top; public int K; public int Dir; public bool Alive; }

public static class Dt5 {
  static int FirstGE(double[] a, double v) { int lo = 0, hi = a.Length - 1, r = a.Length; while (lo <= hi) { int m = (lo + hi) / 2; if (a[m] >= v) { r = m; hi = m - 1; } else lo = m + 1; } return r; }
  static int LastLT(double[] a, double v) { int lo = 0, hi = a.Length - 1, r = -1; while (lo <= hi) { int m = (lo + hi) / 2; if (a[m] < v) { r = m; lo = m + 1; } else hi = m - 1; } return r; }

  // live = true: bara den sista stängda candlen före liveT utvärderas och utfallet räknas inte (Status = "live")
  public static List<Dt5Sig> Run(double[] T, double[] O, double[] H, double[] L, double[] C, double[] V,
      double[] dStart, double[] sOpen, double[] sEnd, double[] dMid,
      double[] Dt, double[] Dh, double[] Dl, double[] Dc,
      bool hasOn, int cadence, int validSec, string enabled, double evalFromOff, double evalToOff, bool live, double liveT, double[] dayGap) {
    List<Dt5Sig> res = new List<Dt5Sig>(); int n = T.Length; if (n < 60) return res;
    bool enSweep = enabled.Contains("sweep5"), enFvg = enabled.Contains("fvg5"), enVwap = enabled.Contains("vwap5"), enOrb = enabled.Contains("orbr"), enOrb15 = enabled.Contains("orb15");
    double[] tr = new double[n]; for (int i = 1; i < n; i++) tr[i] = Math.Max(H[i] - L[i], Math.Max(Math.Abs(H[i] - C[i - 1]), Math.Abs(L[i] - C[i - 1])));
    // EMA20/EMA50 på 15m-stängningar, räknade med de 15m-candlar som är klara när 5m-candlen k stänger
    double[] E20 = new double[n], E50 = new double[n]; double e20 = double.NaN, e50 = double.NaN, k20 = 2.0 / 21, k50 = 2.0 / 51, lastC = 0; long cur = -1;
    for (int k = 0; k < n; k++) {
      long b = (long)Math.Floor(T[k] / 900.0);
      if (cur >= 0 && b != cur) { if (double.IsNaN(e20)) { e20 = lastC; e50 = lastC; } else { e20 = lastC * k20 + e20 * (1 - k20); e50 = lastC * k50 + e50 * (1 - k50); } }
      cur = b; lastC = C[k];
      if (((long)T[k] + 300) % 900 == 0) { if (double.IsNaN(e20)) { E20[k] = lastC; E50[k] = lastC; } else { E20[k] = lastC * k20 + e20 * (1 - k20); E50[k] = lastC * k50 + e50 * (1 - k50); } }
      else { E20[k] = e20; E50[k] = e50; }
    }
    int nd = sOpen.Length;
    for (int d = 1; d < nd; d++) {
      // aktier i rörelse: dayGap[d] = dagens gap (NaN = ingen rörelse den dagen, hoppas över); null = alla dagar
      curGap = (dayGap != null && d < dayGap.Length) ? dayGap[d] : double.NaN; if (dayGap != null && double.IsNaN(curGap)) continue;
      int i0 = FirstGE(T, dStart[d]); int iE = LastLT(T, sEnd[d]); if (i0 >= n || iE < i0 + 10 || i0 < 30) continue;
      int p0 = FirstGE(T, dStart[d - 1]); int pE = LastLT(T, Math.Min(sEnd[d - 1], dStart[d])); if (pE < p0 + 5) continue;
      double PDH = double.MinValue, PDL = double.MaxValue; for (int i = p0; i <= pE; i++) { if (H[i] > PDH) PDH = H[i]; if (L[i] < PDL) PDL = L[i]; }
      int oS = FirstGE(T, sOpen[d]); if (oS > iE) continue;
      double ONH = double.NaN, ONL = double.NaN;
      if (hasOn && oS > i0) { ONH = double.MinValue; ONL = double.MaxValue; for (int i = i0; i < oS; i++) { if (H[i] > ONH) ONH = H[i]; if (L[i] < ONL) ONL = L[i]; } }
      int orEnd = FirstGE(T, sOpen[d] + 1800) - 1; double ORH = double.NaN, ORL = double.NaN;
      if (orEnd - oS + 1 >= 3) { ORH = double.MinValue; ORL = double.MaxValue; for (int i = oS; i <= orEnd; i++) { if (H[i] > ORH) ORH = H[i]; if (L[i] < ORL) ORL = L[i]; } }
      int jD = LastLT(Dt, dMid[d]); if (jD < 21) continue;
      double sma20 = 0; for (int i = jD - 19; i <= jD; i++) sma20 += Dc[i]; sma20 /= 20;
      int trendD = (Dc[jD] > sma20 && Dc[jD] > Dc[jD - 4]) ? 1 : ((Dc[jD] < sma20 && Dc[jD] < Dc[jD - 4]) ? -1 : 0);
      double pv = 0, vv = 0, HOD = double.MinValue, LOD = double.MaxValue; int brokeUp = -1, brokeDn = -1;
      List<Dt5Fvg> fvgs = new List<Dt5Fvg>(); List<int> swH = new List<int>(), swL = new List<int>(); HashSet<string> done = new HashSet<string>();
      // strukturen före dagens början (två timmar bakåt) räknas också
      for (int m = Math.Max(2, i0 - 24); m < i0 - 2; m++) { if (H[m] > H[m - 1] && H[m] > H[m - 2] && H[m] >= H[m + 1] && H[m] >= H[m + 2]) swH.Add(m); if (L[m] < L[m - 1] && L[m] < L[m - 2] && L[m] <= L[m + 1] && L[m] <= L[m + 2]) swL.Add(m); }
      double evFrom = sOpen[d] + evalFromOff, evTo = sEnd[d] - evalToOff;
      int lastK = live ? LastLT(T, liveT - 300 + 1) : -1;   // live: senaste candlen som är stängd
      for (int k = i0; k <= iE; k++) {
        double w = V[k] > 0 ? V[k] : 1; pv += (H[k] + L[k] + C[k]) / 3 * w; vv += w; double vwap = pv / vv;
        if (H[k] > HOD) HOD = H[k]; if (L[k] < LOD) LOD = L[k];
        double atr5 = 0; for (int i = k - 13; i <= k; i++) atr5 += tr[i]; atr5 /= 14; if (!(atr5 > 0)) continue;
        int m2 = k - 2; if (m2 - 2 >= 0 && m2 >= i0 - 2) { if (H[m2] > H[m2 - 1] && H[m2] > H[m2 - 2] && H[m2] >= H[m2 + 1] && H[m2] >= H[m2 + 2]) swH.Add(m2); if (L[m2] < L[m2 - 1] && L[m2] < L[m2 - 2] && L[m2] <= L[m2 + 1] && L[m2] <= L[m2 + 2]) swL.Add(m2); }
        if (k - 2 >= i0) {
          if (L[k] > H[k - 2] && L[k] - H[k - 2] >= 0.25 * atr5 && C[k - 1] > O[k - 1] && C[k - 1] - O[k - 1] >= 0.8 * atr5) { Dt5Fvg f = new Dt5Fvg(); f.Bot = H[k - 2]; f.Top = L[k]; f.K = k; f.Dir = 1; f.Alive = true; fvgs.Add(f); }
          if (H[k] < L[k - 2] && L[k - 2] - H[k] >= 0.25 * atr5 && C[k - 1] < O[k - 1] && O[k - 1] - C[k - 1] >= 0.8 * atr5) { Dt5Fvg f = new Dt5Fvg(); f.Bot = H[k]; f.Top = L[k - 2]; f.K = k; f.Dir = -1; f.Alive = true; fvgs.Add(f); }
        }
        foreach (Dt5Fvg f in fvgs) { if (!f.Alive || f.K == k) continue; if (f.Dir > 0 && C[k] < f.Bot) f.Alive = false; if (f.Dir < 0 && C[k] > f.Top) f.Alive = false; }
        if (!double.IsNaN(ORH) && k > orEnd) { if (brokeUp < 0 && C[k] > ORH) brokeUp = k; if (brokeDn < 0 && C[k] < ORL) brokeDn = k; }
        double t = T[k] + 300;
        if (live) { if (k != lastK) continue; } else { if (t < evFrom || t > evTo) continue; if (cadence > 300 && ((long)t % cadence) != 0) continue; }
        if (live && (t < evFrom || t > evTo)) continue;
        if (double.IsNaN(E20[k]) || double.IsNaN(E50[k])) continue;
        double px = C[k]; int bias = (px > vwap && E20[k] > E50[k]) ? 1 : ((px < vwap && E20[k] < E50[k]) ? -1 : 0); double buf = 0.1 * atr5;
        double[] upLv = new double[] { PDH, ONH, ORH, HOD, vwap }, dnLv = new double[] { PDL, ONL, ORL, LOD, vwap };
        if (enSweep) {
          for (int sd = 1; sd >= -1; sd -= 2) {
            string key = "sweep5" + (sd > 0 ? "L" : "S"); if (done.Contains(key)) continue;
            double[] levs = sd > 0 ? new double[] { PDL, ONL, (t >= sOpen[d] + 1800 ? ORL : double.NaN) } : new double[] { PDH, ONH, (t >= sOpen[d] + 1800 ? ORH : double.NaN) };
            string[] nm = new string[] { "PD", "ON", "OR" };
            for (int li = 0; li < 3; li++) {
              double lev = levs[li]; if (double.IsNaN(lev) || lev == double.MinValue || lev == double.MaxValue) continue;
              int jS = -1; for (int j = Math.Max(i0, k - 5); j <= k; j++) { if (sd > 0 ? L[j] < lev - 0.05 * atr5 : H[j] > lev + 0.05 * atr5) { jS = j; break; } }
              if (jS < 0 || (li == 2 && jS <= orEnd)) continue;
              if (sd > 0 ? !(C[k] > lev) : !(C[k] < lev)) continue;
              double ext = sd > 0 ? double.MaxValue : double.MinValue; for (int j = jS; j <= k; j++) ext = sd > 0 ? Math.Min(ext, L[j]) : Math.Max(ext, H[j]);
              double ch = double.NaN; List<int> sw = sd > 0 ? swH : swL;
              for (int q = sw.Count - 1; q >= 0; q--) { int m = sw[q]; if (m < jS && m >= jS - 24) { ch = sd > 0 ? H[m] : L[m]; break; } }
              if (double.IsNaN(ch)) { ch = sd > 0 ? double.MinValue : double.MaxValue; for (int j = Math.Max(0, jS - 6); j < jS; j++) ch = sd > 0 ? Math.Max(ch, H[j]) : Math.Min(ch, L[j]); }
              double entry = ch + sd * buf, stop = ext - sd * buf;
              if (sd * (entry - C[k]) <= 0 || sd * (entry - C[k]) > 1.5 * atr5) continue;
              if (Add(res, "sweep5", sd, entry, stop, atr5, t, d, px, vwap, bias, trendD, nm[li], sd > 0 ? upLv : dnLv, T, O, H, L, C, k, iE, validSec, live)) { done.Add(key); break; }
            }
          }
        }
        if (enFvg && bias != 0) {
          int sd = bias; string key = "fvg5" + (sd > 0 ? "L" : "S");
          if (!done.Contains(key)) for (int q = fvgs.Count - 1; q >= 0; q--) {
            Dt5Fvg f = fvgs[q]; if (!f.Alive || f.Dir != sd || f.K < k - 12 || f.K >= k) continue;
            bool touch = sd > 0 ? (L[k] <= f.Top && C[k] >= f.Bot) : (H[k] >= f.Bot && C[k] <= f.Top); if (!touch) continue;
            double entry = sd > 0 ? H[k] + buf : L[k] - buf, stop = sd > 0 ? Math.Min(f.Bot, L[k]) - buf : Math.Max(f.Top, H[k]) + buf;
            if (Add(res, "fvg5", sd, entry, stop, atr5, t, d, px, vwap, bias, trendD, "FVG", sd > 0 ? upLv : dnLv, T, O, H, L, C, k, iE, validSec, live)) { done.Add(key); break; }
          }
        }
        if (enVwap && bias != 0 && trendD != -bias && k > i0) {
          int sd = bias; string key = "vwap5" + (sd > 0 ? "L" : "S");
          bool rec = sd > 0 ? (L[k] <= vwap + 0.1 * atr5 && C[k] > vwap && C[k - 1] <= vwap + 0.1 * atr5) : (H[k] >= vwap - 0.1 * atr5 && C[k] < vwap && C[k - 1] >= vwap - 0.1 * atr5);
          if (rec && !done.Contains(key)) { double entry = sd > 0 ? H[k] + buf : L[k] - buf, stop = sd > 0 ? Math.Min(L[k - 1], L[k]) - buf : Math.Max(H[k - 1], H[k]) + buf;
            if (Add(res, "vwap5", sd, entry, stop, atr5, t, d, px, vwap, bias, trendD, "VWAP", sd > 0 ? upLv : dnLv, T, O, H, L, C, k, iE, validSec, live)) done.Add(key); }
        }
        // ORB 15 min för aktier i rörelse: utbrott ur de första 15 minuterna i gapets riktning (utan gap: båda hållen), stopp i rangens mitt,
        // under den första timmen
        if (enOrb15 && oS + 2 <= iE && k >= oS + 2 && T[oS + 2] < sOpen[d] + 900 && t <= sOpen[d] + 3600) {
          double h15 = Math.Max(H[oS], Math.Max(H[oS + 1], H[oS + 2])), l15 = Math.Min(L[oS], Math.Min(L[oS + 1], L[oS + 2])), m15 = (h15 + l15) / 2;
          bool upOk = double.IsNaN(curGap) || curGap > 0, dnOk = double.IsNaN(curGap) || curGap < 0;
          if (upOk && !done.Contains("orb15L") && C[k] <= h15 + 0.3 * atr5 && C[k] >= m15) { if (Add(res, "orb15", 1, h15 + buf, m15 - buf, atr5, t, d, px, vwap, bias, trendD, "OR15", upLv, T, O, H, L, C, k, iE, validSec, live)) done.Add("orb15L"); }
          if (dnOk && !done.Contains("orb15S") && C[k] >= l15 - 0.3 * atr5 && C[k] <= m15) { if (Add(res, "orb15", -1, l15 - buf, m15 + buf, atr5, t, d, px, vwap, bias, trendD, "OR15", dnLv, T, O, H, L, C, k, iE, validSec, live)) done.Add("orb15S"); }
        }
        if (enOrb && !double.IsNaN(ORH) && t <= sOpen[d] + 9000) {
          if (brokeUp >= 0 && k > brokeUp && L[k] <= ORH + 0.2 * atr5 && C[k] > ORH && !done.Contains("orbrL")) { if (Add(res, "orbr", 1, H[k] + buf, Math.Min(L[k], ORH - 0.3 * atr5) - buf, atr5, t, d, px, vwap, bias, trendD, "OR", upLv, T, O, H, L, C, k, iE, validSec, live)) done.Add("orbrL"); }
          if (brokeDn >= 0 && k > brokeDn && H[k] >= ORL - 0.2 * atr5 && C[k] < ORL && !done.Contains("orbrS")) { if (Add(res, "orbr", -1, L[k] - buf, Math.Max(H[k], ORL + 0.3 * atr5) + buf, atr5, t, d, px, vwap, bias, trendD, "OR", dnLv, T, O, H, L, C, k, iE, validSec, live)) done.Add("orbrS"); }
        }
      }
    }
    return res;
  }
  static double curGap = double.NaN;

  static bool Add(List<Dt5Sig> res, string key, int sd, double entry, double stop, double atr5, double t, int d, double px, double vwap, int bias, int trendD, string lev, double[] lvls,
      double[] T, double[] O, double[] H, double[] L, double[] C, int k, int iE, int validSec, bool live) {
    double risk = sd * (entry - stop); if (risk < 0.8 * atr5) { stop = entry - sd * 0.8 * atr5; risk = 0.8 * atr5; } if (risk > 4 * atr5) return false;
    double t1 = entry + sd * 2 * risk, t2 = entry + sd * 3 * risk, best = double.NaN;
    foreach (double lv in lvls) { if (double.IsNaN(lv) || lv == double.MinValue || lv == double.MaxValue) continue; if (sd * (lv - t1) > 0 && (double.IsNaN(best) || sd * (lv - best) < 0)) best = lv; }
    if (!double.IsNaN(best) && sd * (best - t2) > 0) t2 = best;
    Dt5Sig s = new Dt5Sig(); s.Gap = curGap; s.Key = key; s.Side = sd; s.Day = d; s.AtT = t; s.Entry = entry; s.Stop = stop; s.T1 = t1; s.T2 = t2; s.Risk = risk; s.Atr5 = atr5; s.Px = px; s.Vwap = vwap; s.Bias = bias; s.TrendD = trendD; s.Level = lev;
    if (live) s.Status = "live"; else Sim(s, sd, T, O, H, L, C, k + 1, iE, t + validSec);
    res.Add(s); return true;
  }

  static void Sim(Dt5Sig s, int sd, double[] T, double[] O, double[] H, double[] L, double[] C, int k0, int iE, double validUntil) {
    double entry = s.Entry, stop = s.Stop, t1 = s.T1, t2 = s.T2, risk = Math.Abs(entry - stop);
    int state = 0; double fill = 0, rem = 1, acc = 0, stopNow = stop, lastC = double.NaN, mfe = 0; bool t1d = false, amb = false; string reason = "ej utlöst";
    for (int k = k0; k <= iE; k++) {
      double op = O[k], fav = sd > 0 ? H[k] : L[k], adv = sd > 0 ? L[k] : H[k]; lastC = C[k];
      if (state == 0) {
        if (T[k] >= validUntil) { reason = "ej utlöst"; break; }
        if (sd * (fav - entry) >= 0) { fill = sd * (op - entry) > 0 ? op : entry; state = 1; s.FillT = T[k];
          if (sd * (adv - stopNow) <= 0) { acc = sd * (stopNow - fill); rem = 0; reason = "stopp"; amb = true; s.ExitT = T[k]; break; }
          continue; }
        if (sd * (adv - stop) <= 0) { reason = "förföll"; break; }
        continue;
      }
      mfe = Math.Max(mfe, sd * (fav - fill) / risk);
      bool hitStop = sd * (adv - stopNow) <= 0, hitT = sd * (fav - (t1d ? t2 : t1)) >= 0; if (hitStop && hitT) amb = true;
      if (hitStop) { double ex = sd * (op - stopNow) < 0 ? op : stopNow; acc += rem * sd * (ex - fill); rem = 0; reason = t1d ? "break-even" : "stopp"; s.ExitT = T[k]; break; }
      if (!t1d && sd * (fav - t1) >= 0) { acc += (1.0 / 3) * sd * (t1 - fill); rem = 2.0 / 3; t1d = true; stopNow = fill;
        if (sd * (fav - t2) >= 0) { acc += rem * sd * (t2 - fill); rem = 0; reason = "mål 2"; s.ExitT = T[k]; break; } continue; }
      if (t1d && sd * (fav - t2) >= 0) { acc += rem * sd * (t2 - fill); rem = 0; reason = "mål 2"; s.ExitT = T[k]; break; }
    }
    if (state == 0) { s.Status = reason == "förföll" ? "förföll" : "ej utlöst"; s.Reason = reason; s.R = 0; return; }
    if (rem > 0) { acc += rem * sd * (lastC - fill); reason = t1d ? "dagsslut efter mål 1" : "dagsslut"; }
    s.Status = "utlöst"; s.Reason = reason; s.R = acc / risk; s.Mfe = mfe; s.T1Hit = t1d; s.Ambig = amb;
  }
}
'@
if (-not ('Dt5' -as [type])) { Add-Type -TypeDefinition $DT5_CS -Language CSharp }
