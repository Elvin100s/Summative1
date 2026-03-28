# Malaria Predictor — Flutter App

A Material 3 Android app that predicts malaria incidence (cases per 1,000 population at risk) for African countries by calling the live prediction API.

## Features

- **Country presets** — select Rwanda, Uganda, Kenya, Burundi, Tanzania, or DRC to auto-fill all 26 input fields with real 2015 data
- **Manual entry** — edit any field freely; all fields are validated against their allowed ranges before submission
- **Sectioned form** — inputs grouped into 8 cards: Country & Year, Disease Indicators, Water Services, Sanitation Services, Population, Basic Water, Basic Sanitation, Geography
- **Color-coded results** — predicted value displayed with a risk label:
  - Green — Low Risk (< 100 cases per 1,000)
  - Orange — Moderate Risk (100–299)
  - Red — High Risk (≥ 300)
- **Error handling** — network failures and API errors shown inline

## Screenshots

The app uses a dark-green gradient header with a white card body. Each section card has a green header bar and grouped text fields with icons.

## Requirements

- Flutter SDK 3.x or later
- Android device with USB debugging enabled, or an Android emulator
- Internet connection (the app calls the live API — no local model)

## Setup & Run

1. Install Flutter: https://docs.flutter.dev/get-started/install

2. Clone the repo and navigate here:
```bash
cd linear_regression_model/summative/FlutterApp/malaria_predictor
```

3. Install dependencies:
```bash
flutter pub get
```

4. Connect an Android device or start an emulator, then run:
```bash
flutter run
```

## API Connection

The app posts to:
```
https://malaria-predictor-api.onrender.com/predict
```

No local setup is required — the model runs server-side. The app has a 30-second request timeout. If the API is cold-starting on Render's free tier, the first request may take up to 60 seconds.

## Input Fields

All 26 fields are required. Ranges are enforced client-side before sending the request.

| Field | Range | Description |
|---|---|---|
| Country Name (encoded) | 0–53 | Label-encoded country name |
| Year | 2007–2017 | Year of observation |
| Country Code (encoded) | 0–53 | Label-encoded ISO country code |
| Malaria Cases Reported | ≥ 0 | Absolute reported cases |
| Bed Net Usage % | 0–100 | % of under-5 population using ITNs |
| Fever Antimalarial % | 0–100 | % of under-5 with fever receiving antimalarials |
| IPT in Pregnancy % | 0–100 | % of pregnant women receiving IPT |
| Safe Water Total % | 0–100 | % of population with safely managed water |
| Safe Water Rural % | 0–100 | Rural subset |
| Safe Water Urban % | 0–100 | Urban subset |
| Safe Sanitation Total % | 0–100 | % of population with safely managed sanitation |
| Safe Sanitation Rural % | 0–100 | Rural subset |
| Safe Sanitation Urban % | 0–100 | Urban subset |
| Rural Population % | 0–100 | Rural population share |
| Rural Population Growth | -10–10 | Annual rural growth rate % |
| Urban Population % | 0–100 | Urban population share |
| Urban Population Growth | -10–10 | Annual urban growth rate % |
| Basic Water Total % | 0–100 | % with at least basic drinking water |
| Basic Water Rural % | 0–100 | Rural subset |
| Basic Water Urban % | 0–100 | Urban subset |
| Basic Sanitation Total % | 0–100 | % with at least basic sanitation |
| Basic Sanitation Rural % | 0–100 | Rural subset |
| Basic Sanitation Urban % | 0–100 | Urban subset |
| Latitude | -35–38 | Country centroid latitude |
| Longitude | -18–52 | Country centroid longitude |
| Geometry (encoded) | 0–53 | Label-encoded geometry identifier |

## Country Preset Values

Use the dropdown at the top of the form to load any of these presets (all from 2015 data):

| Country | Malaria Cases | Bed Nets % | Latitude | Longitude |
|---|---|---|---|---|
| Rwanda | 2,694,566 | 67.7 | -1.94 | 29.87 |
| Uganda | 7,137,662 | 74.3 | 1.37 | 32.29 |
| Kenya | 1,581,168 | 56.1 | 0.18 | 37.91 |
| Burundi | 5,428,710 | 42.9 | -3.37 | 29.92 |
| Tanzania | 4,241,364 | 42.9 | -6.37 | 34.89 |
| DRC | 12,538,805 | 42.9 | -4.04 | 21.76 |

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.x
```

## Demo Video

[Watch on YouTube](https://www.youtube.com/watch?v=piQf1J3AkhI)
