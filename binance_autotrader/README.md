# Binance AutoTrader — Flutter Android App

A full-featured cryptocurrency auto-trading Android app built with Flutter, connecting to the Binance REST + WebSocket APIs.

## Features

- **EMA/MACD/RSI/Bollinger Bands** composite scoring strategy (4/4 conditions = signal)
- **Background trading engine** using Android foreground service (survives app close)
- **Paper trading mode** (default) — $1,000 virtual balance, no real funds at risk
- **Real-time dashboard** with signal strength, live balance, daily P&L stats
- **Trade history** with paper vs live comparison
- **Interactive charts** — Price + EMA9/21/50, Bollinger Bands, RSI subplot, MACD histogram
- **Push notifications** for trade entries, exits, profit targets, and risk alerts
- **Encrypted API key storage** via Android Keystore (AES-GCM + RSA OAEP)
- **Daily profit target**: $10/day (configurable) — engine auto-stops when reached
- **Max daily loss protection** — auto-stops engine on breach

## Architecture

Clean Architecture with 3 layers:

```
Domain Layer:    Entities → Repository Interfaces → Use Cases
Data Layer:      REST Client → WebSocket Service → Hive Repositories → Secure Storage
Presentation:    Riverpod Providers → Notifiers → Screens → Widgets
```

## Setup

### Prerequisites
- Flutter SDK ≥ 3.3.0
- Android Studio / SDK 34
- Binance account (API keys optional for paper mode)

### Installation

```bash
# Install dependencies
flutter pub get

# Run code generation (Hive adapters)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on Android device/emulator
flutter run
```

### API Keys

1. Open the **Settings** tab
2. Enter your Binance API key and secret
3. Tap **Test** to verify connectivity
4. Keys are encrypted and stored in Android Keystore — never transmitted to third parties

### Important Notes

- **Paper mode is the default** — switch to Live only after thorough paper testing
- Switching to Live mode requires explicit confirmation and understanding of risks
- The $10/day target is a strategy goal, not a guarantee
- Requires Android 5.0+ (API 21)
- For reliable background operation on MIUI/One UI, disable battery optimization in Settings

## Strategy

The composite signal requires **4 out of 4** indicators to align:

| Indicator | Bull Condition | Bear Condition |
|-----------|---------------|----------------|
| EMA 9/21/50 | Price > EMA9 > EMA21 > EMA50 | Price < EMA9 < EMA21 < EMA50 |
| MACD | Histogram > 0 and rising | Histogram < 0 and falling |
| RSI | 60–80 range | 20–40 range |
| Bollinger Bands | Price > Upper Band | Price < Lower Band |

**Position sizing**: 1% risk per trade, max 5% of balance, SL = 1.5× ATR

## Screens

1. **Dashboard** — Engine control, balance, daily stats, signal strength
2. **Active Trades** — Open positions with manual close option
3. **Trade History** — Closed trades with P&L, win rate, filters
4. **Charts** — Real-time price chart with indicator overlays
5. **Paper Trading** — Paper vs live comparison, mode toggle
6. **Settings** — API keys, strategy params, risk management

## Disclaimer

**This software is for educational purposes only. Cryptocurrency trading involves substantial risk of loss. Past performance does not guarantee future results. Only trade with funds you can afford to lose entirely.**
