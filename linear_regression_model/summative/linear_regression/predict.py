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

    # Rwanda 2015 — matches the Flutter app preset
    sample = {
        'Country Name':                                                                          40,
        'Year':                                                                                2015,
        'Country Code':                                                                          40,
        'Malaria cases reported':                                                           3500000,
        'Use of insecticide-treated bed nets (% of under-5 population)':                      53.0,
        'Children with fever receiving antimalarial drugs (% of children under age 5 with fever)': 38.0,
        'Intermittent preventive treatment (IPT) of malaria in pregnancy (% of pregnant women)': 31.0,
        'People using safely managed drinking water services (% of population)':              14.0,
        'People using safely managed drinking water services, rural (% of rural population)':  8.0,
        'People using safely managed drinking water services, urban (% of urban population)': 42.0,
        'People using safely managed sanitation services (% of population)':                   6.0,
        'People using safely managed sanitation services, rural (% of rural population)':      4.0,
        'People using safely managed sanitation services, urban  (% of urban population)':    20.0,
        'Rural population (% of total population)':                                           83.0,
        'Rural population growth (annual %)':                                                  2.1,
        'Urban population (% of total population)':                                           17.0,
        'Urban population growth (annual %)':                                                  6.5,
        'People using at least basic drinking water services (% of population)':              76.0,
        'People using at least basic drinking water services, rural (% of rural population)': 70.0,
        'People using at least basic drinking water services, urban (% of urban population)': 93.0,
        'People using at least basic sanitation services (% of population)':                  49.0,
        'People using at least basic sanitation services, rural (% of rural population)':     44.0,
        'People using at least basic sanitation services, urban  (% of urban population)':    72.0,
        'latitude':                                                                            -1.94,
        'longitude':                                                                           29.87,
        'geometry':                                                                              40,
    }

    prediction = predict_malaria_incidence(sample)
    print(f'Rwanda 2015 — Predicted malaria incidence: {prediction:.2f} per 1,000 population at risk')
