# Malaria Incidence Prediction in Africa

Millions of people in East and Central Africa die from malaria each year due to poor health resource allocation. This project predicts malaria incidence rates (cases per 1,000 population at risk) using machine learning across 54 African countries, enabling governments and health organizations to target interventions — such as bed net distribution and fever treatment programs — where they are needed most.

## Repository Structure

```
linear_regression_model/
└── summative/
    ├── linear_regression/
    │   ├── multivariate.ipynb          ← EDA, preprocessing, training, evaluation (all 3 models)
    │   ├── predict.py                  ← standalone prediction script using best model
    │   ├── best_model.pkl              ← saved Random Forest model
    │   ├── scaler.pkl                  ← fitted StandardScaler
    │   ├── feature_names.pkl           ← ordered feature list
    │   └── DatasetAfricaMalaria.csv    ← raw dataset (594 rows × 27 features)
    ├── API/
    │   ├── prediction.py               ← FastAPI app (/predict and /retrain endpoints)
    │   └── requirements.txt
    └── FlutterApp/
        └── malaria_predictor/
            └── lib/main.dart           ← Flutter mobile app source
```

## Dataset

**Source:** [Malaria in Africa — Kaggle (lydia70 / World Bank Open Data)](https://www.kaggle.com/datasets/lydia70/malaria-in-africa)
**Size:** 594 rows × 27 features — covering 54 African countries over 10 years (2007–2017)
**Features:** Epidemiological, demographic, and health intervention variables — bed net usage, fever treatment rates, IPT in pregnancy, sanitation access, water access, urbanization rates, and more.
**Target:** `Incidence of malaria (per 1,000 population at risk)`

## Models & Results

Three regression models were trained and compared:

| Model | MSE | MAE | R² |
|---|---|---|---|
| Linear Regression | 0.6887 | 0.6589 | 0.8372 |
| Decision Tree | 0.3443 | 0.3809 | 0.9186 |
| **Random Forest** | **0.0895** | **0.2025** | **0.9788** |

**Best model:** Random Forest Regressor (R² ≈ 0.98) — saved as `best_model.pkl`.

## Live API

| Endpoint | Method | Description |
|---|---|---|
| `/` | GET | Health check |
| `/predict` | POST | Predict malaria incidence from 26 input features |
| `/retrain` | POST | Retrain the model by uploading a new CSV |

- **Base URL:** https://malaria-predictor-api.onrender.com
- **Swagger UI:** https://malaria-predictor-api.onrender.com/docs

> The API is hosted on Render's free tier and may take 30–60 seconds to wake up after inactivity.

## Flutter Mobile App

A Material 3 Android app that calls the live API. Users select a country preset (Rwanda, Uganda, Kenya, Burundi, Tanzania, DRC) or enter all 26 features manually, then receive a predicted incidence value with a color-coded risk label (Low / Moderate / High).

**Requirements:** Flutter SDK, Android device with USB debugging or Android emulator.

```bash
cd linear_regression_model/summative/FlutterApp/malaria_predictor
flutter pub get
flutter run
```

## Demo Video

[Watch on YouTube](https://www.youtube.com/watch?v=piQf1J3AkhI)
