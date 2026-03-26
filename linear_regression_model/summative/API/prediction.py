"""
prediction.py
-------------
FastAPI app for Malaria Incidence Prediction.
Endpoints:
  GET  /          - health check
  POST /predict   - predict malaria incidence
  POST /retrain   - retrain model with new CSV data
"""

import os
import io
import logging
import numpy as np
import pandas as pd
import joblib

from contextlib import asynccontextmanager
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from scipy.stats import skew
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.tree import DecisionTreeRegressor

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE_DIR      = os.path.dirname(os.path.abspath(__file__))
LR_DIR        = os.path.join(BASE_DIR, "..", "linear_regression")
MODEL_PATH    = os.path.join(LR_DIR, "best_model.pkl")
SCALER_PATH   = os.path.join(LR_DIR, "scaler.pkl")
FEATURES_PATH = os.path.join(LR_DIR, "feature_names.pkl")
LOG_COLS_PATH = os.path.join(LR_DIR, "log_transformed_cols.pkl")
TARGET        = "Incidence of malaria (per 1,000 population at risk)"

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Training helper
# ---------------------------------------------------------------------------

def _train_and_save(df: pd.DataFrame) -> dict:
    """Full training pipeline. Saves best_model.pkl, scaler.pkl, feature_names.pkl."""

    df = df.copy()

    # Drop high-cardinality identifier columns (same logic as notebook)
    drop_cols = [
        col for col in df.select_dtypes(include="object").columns
        if col not in ["Country Name", "Year", "Country Code"]
        and df[col].nunique() / len(df) > 0.5
    ]
    df.drop(columns=drop_cols, inplace=True, errors="ignore")

    # Label-encode remaining object columns
    for col in df.select_dtypes(include="object").columns:
        df[col] = LabelEncoder().fit_transform(df[col].astype(str))

    # Drop rows where target is null
    df.dropna(subset=[TARGET], inplace=True)

    # Impute missing values
    imputer = SimpleImputer(strategy="median")
    df = pd.DataFrame(imputer.fit_transform(df), columns=df.columns)

    # Log-transform skewed features and record which ones
    log_transformed_cols = []
    for col in df.columns:
        if col == TARGET:
            continue
        if abs(skew(df[col])) > 1.0:
            df[col] = np.log1p(df[col].clip(lower=0))
            log_transformed_cols.append(col)
    df[TARGET] = np.log1p(df[TARGET].clip(lower=0))

    features = [c for c in df.columns if c != TARGET]
    X = df[features].values
    y = df[TARGET].values

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.20, random_state=42)

    scaler = StandardScaler()
    X_train_sc = scaler.fit_transform(X_train)
    X_test_sc  = scaler.transform(X_test)

    # Train all three models
    models = {
        "Linear Regression": LinearRegression(),
        "Decision Tree":     DecisionTreeRegressor(max_depth=6, min_samples_split=5, random_state=42),
        "Random Forest":     RandomForestRegressor(n_estimators=200, max_depth=10, random_state=42, n_jobs=-1),
    }

    results = {}
    for name, m in models.items():
        m.fit(X_train_sc, y_train)
        mse = mean_squared_error(y_test, m.predict(X_test_sc))
        results[name] = {"model": m, "mse": mse}
        log.info(f"{name}: MSE={mse:.4f}")

    best_name = min(results, key=lambda k: results[k]["mse"])
    best_model = results[best_name]["model"]
    log.info(f"Best model: {best_name}")

    os.makedirs(LR_DIR, exist_ok=True)
    joblib.dump(best_model,          MODEL_PATH)
    joblib.dump(scaler,              SCALER_PATH)
    joblib.dump(features,            FEATURES_PATH)
    joblib.dump(log_transformed_cols, LOG_COLS_PATH)

    return {name: {"mse": v["mse"]} for name, v in results.items()}


LOCAL_CSV = os.path.join(BASE_DIR, "..", "linear_regression", "DatasetAfricaMalaria.csv")


def _ensure_model():
    """Train model from local CSV (or Kaggle fallback) if pkl files are missing."""
    if all(os.path.exists(p) for p in [MODEL_PATH, SCALER_PATH, FEATURES_PATH, LOG_COLS_PATH]):
        log.info("Model artifacts found — skipping training.")
        return

    log.info("Model artifacts not found — training…")

    # Try local CSV first
    if os.path.exists(LOCAL_CSV):
        log.info(f"Using local dataset: {LOCAL_CSV}")
        df = pd.read_csv(LOCAL_CSV)
    else:
        # Fallback: download from Kaggle
        log.info("Local CSV not found — downloading from Kaggle…")
        try:
            import kagglehub
            path = kagglehub.dataset_download("lydia70/malaria-in-africa")
            csv_files = [f for f in os.listdir(path) if f.endswith(".csv")]
            if not csv_files:
                raise FileNotFoundError("No CSV found in Kaggle download.")
            df = pd.read_csv(os.path.join(path, csv_files[0]))
        except Exception as exc:
            log.error(f"Could not download dataset: {exc}")
            raise RuntimeError("Model not available and dataset download failed.") from exc

    _train_and_save(df)
    log.info("Training complete.")


# ---------------------------------------------------------------------------
# App lifecycle
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    _ensure_model()
    yield


app = FastAPI(
    title="Malaria Incidence Prediction API",
    description="Predicts malaria incidence (per 1,000 population at risk) for African countries.",
    version="1.0.0",
    lifespan=lifespan,
)

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:8080",
        "http://localhost:3000",
        "http://10.0.2.2",          # Android emulator → host
        "http://10.0.2.2:8000",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization", "X-Requested-With"],
)

# ---------------------------------------------------------------------------
# Pydantic input schema  (26 features, matching notebook feature order)
# ---------------------------------------------------------------------------

class MalariaInput(BaseModel):
    country_name: float = Field(
        ..., ge=0, le=53,
        description="Label-encoded country name (0–53)",
        json_schema_extra={"example": 48}
    )
    year: int = Field(
        ..., ge=2007, le=2017,
        description="Year of observation",
        json_schema_extra={"example": 2015}
    )
    country_code: float = Field(
        ..., ge=0, le=53,
        description="Label-encoded ISO country code (0–53)",
        json_schema_extra={"example": 48}
    )
    malaria_cases_reported: float = Field(
        ..., ge=0, le=20_000_000,
        description="Absolute malaria cases reported",
        json_schema_extra={"example": 10000}
    )
    bed_nets_pct: float = Field(
        ..., ge=0, le=100,
        description="Use of insecticide-treated bed nets (% of under-5 population)",
        json_schema_extra={"example": 42.0}
    )
    fever_antimalarial_pct: float = Field(
        ..., ge=0, le=100,
        description="Children with fever receiving antimalarial drugs (%)",
        json_schema_extra={"example": 35.0}
    )
    ipt_pregnancy_pct: float = Field(
        ..., ge=0, le=100,
        description="IPT of malaria in pregnancy (% of pregnant women)",
        json_schema_extra={"example": 20.0}
    )
    safe_water_total_pct: float = Field(
        ..., ge=0, le=100,
        description="People using safely managed drinking water (% of population)",
        json_schema_extra={"example": 30.0}
    )
    safe_water_rural_pct: float = Field(
        ..., ge=0, le=100,
        description="Safely managed drinking water, rural (% of rural population)",
        json_schema_extra={"example": 20.0}
    )
    safe_water_urban_pct: float = Field(
        ..., ge=0, le=100,
        description="Safely managed drinking water, urban (% of urban population)",
        json_schema_extra={"example": 55.0}
    )
    safe_sanitation_total_pct: float = Field(
        ..., ge=0, le=100,
        description="People using safely managed sanitation (% of population)",
        json_schema_extra={"example": 15.0}
    )
    safe_sanitation_rural_pct: float = Field(
        ..., ge=0, le=100,
        description="Safely managed sanitation, rural (% of rural population)",
        json_schema_extra={"example": 8.0}
    )
    safe_sanitation_urban_pct: float = Field(
        ..., ge=0, le=100,
        description="Safely managed sanitation, urban (% of urban population)",
        json_schema_extra={"example": 35.0}
    )
    rural_population_pct: float = Field(
        ..., ge=0, le=100,
        description="Rural population (% of total population)",
        json_schema_extra={"example": 80.0}
    )
    rural_population_growth: float = Field(
        ..., ge=-10, le=10,
        description="Rural population growth (annual %)",
        json_schema_extra={"example": 2.5}
    )
    urban_population_pct: float = Field(
        ..., ge=0, le=100,
        description="Urban population (% of total population)",
        json_schema_extra={"example": 20.0}
    )
    urban_population_growth: float = Field(
        ..., ge=-10, le=10,
        description="Urban population growth (annual %)",
        json_schema_extra={"example": 4.0}
    )
    basic_water_total_pct: float = Field(
        ..., ge=0, le=100,
        description="People using at least basic drinking water (% of population)",
        json_schema_extra={"example": 70.0}
    )
    basic_water_rural_pct: float = Field(
        ..., ge=0, le=100,
        description="Basic drinking water, rural (% of rural population)",
        json_schema_extra={"example": 60.0}
    )
    basic_water_urban_pct: float = Field(
        ..., ge=0, le=100,
        description="Basic drinking water, urban (% of urban population)",
        json_schema_extra={"example": 90.0}
    )
    basic_sanitation_total_pct: float = Field(
        ..., ge=0, le=100,
        description="People using at least basic sanitation (% of population)",
        json_schema_extra={"example": 25.0}
    )
    basic_sanitation_rural_pct: float = Field(
        ..., ge=0, le=100,
        description="Basic sanitation, rural (% of rural population)",
        json_schema_extra={"example": 15.0}
    )
    basic_sanitation_urban_pct: float = Field(
        ..., ge=0, le=100,
        description="Basic sanitation, urban (% of urban population)",
        json_schema_extra={"example": 55.0}
    )
    latitude: float = Field(
        ..., ge=-35.0, le=38.0,
        description="Country centroid latitude",
        json_schema_extra={"example": 1.37}
    )
    longitude: float = Field(
        ..., ge=-18.0, le=52.0,
        description="Country centroid longitude",
        json_schema_extra={"example": 32.29}
    )
    geometry: float = Field(
        ..., ge=0, le=53,
        description="Label-encoded geometry identifier (0–53)",
        json_schema_extra={"example": 48}
    )


# Map Pydantic field names → notebook feature names (order must match FEATURES_PATH)
FIELD_TO_FEATURE = {
    "country_name":              "Country Name",
    "year":                      "Year",
    "country_code":              "Country Code",
    "malaria_cases_reported":    "Malaria cases reported",
    "bed_nets_pct":              "Use of insecticide-treated bed nets (% of under-5 population)",
    "fever_antimalarial_pct":    "Children with fever receiving antimalarial drugs (% of children under age 5 with fever)",
    "ipt_pregnancy_pct":         "Intermittent preventive treatment (IPT) of malaria in pregnancy (% of pregnant women)",
    "safe_water_total_pct":      "People using safely managed drinking water services (% of population)",
    "safe_water_rural_pct":      "People using safely managed drinking water services, rural (% of rural population)",
    "safe_water_urban_pct":      "People using safely managed drinking water services, urban (% of urban population)",
    "safe_sanitation_total_pct": "People using safely managed sanitation services (% of population)",
    "safe_sanitation_rural_pct": "People using safely managed sanitation services, rural (% of rural population)",
    "safe_sanitation_urban_pct": "People using safely managed sanitation services, urban  (% of urban population)",
    "rural_population_pct":      "Rural population (% of total population)",
    "rural_population_growth":   "Rural population growth (annual %)",
    "urban_population_pct":      "Urban population (% of total population)",
    "urban_population_growth":   "Urban population growth (annual %)",
    "basic_water_total_pct":     "People using at least basic drinking water services (% of population)",
    "basic_water_rural_pct":     "People using at least basic drinking water services, rural (% of rural population)",
    "basic_water_urban_pct":     "People using at least basic drinking water services, urban (% of urban population)",
    "basic_sanitation_total_pct":"People using at least basic sanitation services (% of population)",
    "basic_sanitation_rural_pct":"People using at least basic sanitation services, rural (% of rural population)",
    "basic_sanitation_urban_pct":"People using at least basic sanitation services, urban  (% of urban population)",
    "latitude":                  "latitude",
    "longitude":                 "longitude",
    "geometry":                  "geometry",
}


def _predict_from_dict(input_dict: dict) -> float:
    model    = joblib.load(MODEL_PATH)
    scaler   = joblib.load(SCALER_PATH)
    features = joblib.load(FEATURES_PATH)
    log_cols = joblib.load(LOG_COLS_PATH)

    row = np.array([input_dict.get(f, 0.0) for f in features], dtype=float)
    for i, f in enumerate(features):
        if f in log_cols:
            row[i] = np.log1p(max(row[i], 0))
    scaled   = scaler.transform(row.reshape(1, -1))
    log_pred = model.predict(scaled)[0]
    return float(np.expm1(log_pred))


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/", tags=["Health"])
def health():
    return {"status": "ok", "message": "Malaria Incidence Prediction API is running."}


@app.post("/predict", tags=["Prediction"])
def predict(data: MalariaInput):
    """Predict malaria incidence (per 1,000 population at risk)."""
    if not all(os.path.exists(p) for p in [MODEL_PATH, SCALER_PATH, FEATURES_PATH, LOG_COLS_PATH]):
        raise HTTPException(status_code=503, detail="Model not ready. Try /retrain first.")

    # Build feature dict using full column names
    raw = data.model_dump()
    input_dict = {FIELD_TO_FEATURE[k]: v for k, v in raw.items()}

    prediction = _predict_from_dict(input_dict)
    return {
        "predicted_malaria_incidence_per_1000": round(prediction, 4),
        "unit": "cases per 1,000 population at risk",
    }


@app.post("/retrain", tags=["Retraining"])
async def retrain(file: UploadFile = File(..., description="CSV file with new malaria data")):
    """
    Retrain the model with new data.
    Upload a CSV with the same schema as the original dataset.
    The best-performing model is saved and replaces the current one.
    """
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only CSV files are accepted.")

    contents = await file.read()
    try:
        df = pd.read_csv(io.BytesIO(contents))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not parse CSV: {exc}")

    if TARGET not in df.columns:
        raise HTTPException(
            status_code=422,
            detail=f"CSV must contain the target column: '{TARGET}'"
        )

    try:
        metrics = _train_and_save(df)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Training failed: {exc}")

    return {
        "message": "Model retrained and saved successfully.",
        "model_metrics": metrics,
    }
