# Malaria Incidence Prediction in Africa

## Mission & Problem

Millions of people in East and Central Africa die from malaria each year due to poor health resource allocation. This project predicts malaria incidence rates (cases per 1,000 population at risk) using machine learning across 54 African countries, enabling governments and health organizations to target interventions — such as bed net distribution and fever treatment programs — where they are needed most.

## Dataset

**Source:** [Malaria in Africa — Kaggle (lydia70 / World Bank Open Data)](https://www.kaggle.com/datasets/lydia70/malaria-in-africa)
**Size:** 594 rows × 27 features — covering 54 African countries over 10 years (2007–2017)
**Features:** Epidemiological, demographic, and health intervention variables: bed net usage, fever treatment rates, antenatal care visits, reported malaria cases, sanitation access, water access, urbanization rates, and more.
**Target:** `Incidence of malaria (per 1,000 population at risk)`

## Models & Results

Three regression models trained and compared:

| Model | MSE | MAE | R² |
|---|---|---|---|
| Linear Regression | 0.6887 | 0.6589 | 0.8372 |
| Decision Tree | 0.3443 | 0.3809 | 0.9186 |
| **Random Forest** | **0.0895** | **0.2025** | **0.9788** |

**Best model:** Random Forest Regressor (lowest loss, R² ≈ 0.98) — saved as `best_model.pkl`.

## API

- **Prediction endpoint (POST):** https://malaria-predictor-api.onrender.com/predict
- **Swagger UI:** https://malaria-predictor-api.onrender.com/docs
- **Retraining endpoint (POST):** https://malaria-predictor-api.onrender.com/retrain

> Note: The API is hosted on Render's free tier and may take 30–60 seconds to respond after inactivity.

## Demo Video

[Watch on YouTube](https://www.youtube.com/watch?v=piQf1J3AkhI)

## Flutter App — How to Run

**Requirements:** Flutter SDK installed, Android device with USB Debugging enabled (or Android emulator).

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Clone this repo and navigate to the app:
```bash
cd linear_regression_model/summative/FlutterApp/malaria_predictor
```
3. Install dependencies and run:
```bash
flutter pub get
flutter run
```

The app connects to the live API at `https://malaria-predictor-api.onrender.com/predict`. No local setup required.

## Repository Structure

```
linear_regression_model/
└── summative/
    ├── linear_regression/
    │   ├── multivariate.ipynb   ← EDA, preprocessing, training, evaluation (all 3 models)
    │   └── predict.py           ← standalone prediction script using best model
    ├── API/
    │   ├── prediction.py        ← FastAPI app with /predict and /retrain endpoints
    │   └── requirements.txt
    └── FlutterApp/
        └── malaria_predictor/
            └── lib/main.dart    ← Flutter app source
```
