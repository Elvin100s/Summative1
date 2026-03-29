# Malaria Incidence Prediction — ML Pipeline

**Mission:** Malaria remains one of the leading causes of death in sub-Saharan Africa. This project predicts malaria incidence rates (cases per 1,000 population at risk) across 54 African countries to support early intervention, resource allocation, and public health decision-making. The best-performing model is served via a FastAPI REST API and consumed by a Flutter mobile app.

## Dataset

**Source:** [Malaria in Africa — Kaggle (lydia70 / World Bank Open Data)](https://www.kaggle.com/datasets/lydia70/malaria-in-africa)
**File:** `summative/linear_regression/DatasetAfricaMalaria.csv`
**Size:** 594 rows × 27 features — 54 African countries, 2007–2017

### Features (26 inputs)

| Category | Features |
|---|---|
| Identity | Country Name (encoded), Country Code (encoded), Year, Geometry (encoded) |
| Disease | Malaria cases reported, Bed net usage %, Fever antimalarial treatment %, IPT in pregnancy % |
| Safe Water | Total, Rural, Urban % with safely managed drinking water |
| Safe Sanitation | Total, Rural, Urban % with safely managed sanitation |
| Population | Rural %, Rural growth %, Urban %, Urban growth % |
| Basic Water | Total, Rural, Urban % with at least basic drinking water |
| Basic Sanitation | Total, Rural, Urban % with at least basic sanitation |
| Geography | Latitude, Longitude |

**Target:** `Incidence of malaria (per 1,000 population at risk)`

## Notebook — `summative/linear_regression/multivariate.ipynb`

The notebook performs the full ML pipeline in order:

1. **EDA** — distribution plots, correlation matrix, missing value analysis
2. **Preprocessing** — label encoding of categorical columns, median imputation, log-transform of skewed features (|skew| > 1), StandardScaler normalization
3. **Training** — 80/20 train-test split (random_state=42), three models trained:
   - `LinearRegression()`
   - `DecisionTreeRegressor(max_depth=6, min_samples_split=5)`
   - `RandomForestRegressor(n_estimators=200, max_depth=10)`
4. **Evaluation** — MSE, MAE, R² on the test set
5. **Artifact saving** — `best_model.pkl`, `scaler.pkl`, `feature_names.pkl`, `log_transformed_cols.pkl`

## Model Results

| Model | MSE | MAE | R² |
|---|---|---|---|
| Linear Regression | 0.6887 | 0.6589 | 0.8372 |
| Decision Tree | 0.3443 | 0.3809 | 0.9186 |
| **Random Forest** | **0.0895** | **0.2025** | **0.9788** |

**Best model:** Random Forest (R² ≈ 0.98). Metrics are computed on log-transformed targets; predictions are inverse-transformed (expm1) before returning.

## API — `summative/API/prediction.py`

FastAPI application with three endpoints:

### `GET /`
Health check. Returns `{"status": "ok"}`.

### `POST /predict`
Accepts a JSON body with all 26 features and returns the predicted incidence.

**Request body example:**
```json
{
  "country_name": 39,
  "year": 2015,
  "country_code": 37,
  "malaria_cases_reported": 2694566,
  "bed_nets_pct": 67.7,
  "fever_antimalarial_pct": 11.4,
  "ipt_pregnancy_pct": 11.5,
  "safe_water_total_pct": 28.39,
  "safe_water_rural_pct": 10.68,
  "safe_water_urban_pct": 41.05,
  "safe_sanitation_total_pct": 25.41,
  "safe_sanitation_rural_pct": 15.95,
  "safe_sanitation_urban_pct": 22.75,
  "rural_population_pct": 83.0,
  "rural_population_growth": 2.5,
  "urban_population_pct": 17.0,
  "urban_population_growth": 2.76,
  "basic_water_total_pct": 56.26,
  "basic_water_rural_pct": 51.22,
  "basic_water_urban_pct": 80.85,
  "basic_sanitation_total_pct": 64.24,
  "basic_sanitation_rural_pct": 66.47,
  "basic_sanitation_urban_pct": 53.37,
  "latitude": -1.94,
  "longitude": 29.87,
  "geometry": 2
}
```

**Response:**
```json
{
  "predicted_malaria_incidence_per_1000": 142.37,
  "unit": "cases per 1,000 population at risk"
}
```

### `POST /retrain`
Upload a CSV file with the same schema as the original dataset. Retrains all three models, selects the best by MSE, and overwrites the saved artifacts.

**curl example:**
```bash
curl -X POST https://malaria-predictor-api.onrender.com/retrain \
  -F "file=@DatasetAfricaMalaria.csv"
```

## Live Endpoints

- **API base:** https://malaria-predictor-api.onrender.com
- **Swagger UI:** https://malaria-predictor-api.onrender.com/docs
- **Predict:** https://malaria-predictor-api.onrender.com/predict
- **Retrain:** https://malaria-predictor-api.onrender.com/retrain

> Hosted on Render free tier — may take 30–60 seconds to respond after inactivity.

## Run the API Locally

```bash
cd summative/API
pip install -r requirements.txt
uvicorn prediction:app --reload
```

The API will auto-train from `summative/linear_regression/DatasetAfricaMalaria.csv` on first startup if `.pkl` files are missing.

## Flutter App

See `summative/FlutterApp/malaria_predictor/README.md` for setup and usage.

## Demo Video

[Watch on YouTube](https://www.youtube.com/watch?v=piQf1J3AkhI)
