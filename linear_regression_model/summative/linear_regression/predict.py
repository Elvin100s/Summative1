"""
predict.py
----------
Standalone prediction script for the Malaria Incidence model.
Loads best_model.pkl, scaler.pkl, and feature_names.pkl to make
a prediction on a single data point.

Usage:
    python predict.py

Requirements:
    pip install numpy scikit-learn joblib
"""

import numpy as np
import joblib
import os

MODEL_PATH    = 'best_model.pkl'
SCALER_PATH   = 'scaler.pkl'
FEATURES_PATH = 'feature_names.pkl'


def load_artifacts():
    for path in [MODEL_PATH, SCALER_PATH, FEATURES_PATH]:
        if not os.path.exists(path):
            raise FileNotFoundError(f"'{path}' not found. Run multivariate.ipynb first.")
    return (joblib.load(MODEL_PATH),
            joblib.load(SCALER_PATH),
            joblib.load(FEATURES_PATH))


def predict_malaria_incidence(input_dict):
    """
    Predict malaria incidence (per 1,000 population at risk).

    Args:
        input_dict (dict): keys = feature names, values = numeric.
            Missing features default to 0.

    Returns:
        float: Predicted malaria incidence on the original scale.
    """
    model, scaler, features = load_artifacts()
    row      = np.array([input_dict.get(f, 0) for f in features], dtype=float)
    row      = np.log1p(np.clip(row, 0, None))
    scaled   = scaler.transform(row.reshape(1, -1))
    log_pred = model.predict(scaled)[0]
    return float(np.expm1(log_pred))


# Demo
if __name__ == '__main__':

    sample = {
        'Year': 2015,
        'Country': 'Uganda',
        'Use of insecticide-treated bed nets (% of under-5 population)': 42.0,
        'Children with fever receiving antimalarial drugs (%)': 35.0,
        'Hospital beds (per 1,000 people)': 0.5,
        'Physicians (per 1,000 people)': 0.1,
        'Immunization, DPT (% of children ages 12-23 months)': 78.0,
        'Prevalence of HIV, total (% of population ages 15-49)': 6.5,
        'Mortality rate, under-5 (per 1,000 live births)': 90.0,
        'Life expectancy at birth, total (years)': 58.0,
    }

    prediction = predict_malaria_incidence(sample)
    print(f'Predicted malaria incidence: {prediction:.2f} per 1,000 population at risk')
