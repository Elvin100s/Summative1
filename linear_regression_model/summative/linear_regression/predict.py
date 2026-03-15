"""
predict.py
──────────
Standalone prediction script for the Malaria Incidence model.
Uses the saved best_model.pkl and scaler.pkl to make a prediction
on a single data point (one row from the test dataset).

Usage:
    python predict.py

Requirements:
    pip install numpy scikit-learn joblib
"""

import numpy as np
import joblib
import os

# ── Load saved model and scaler ────────────────────────────────────────────
MODEL_PATH  = 'best_model.pkl'
SCALER_PATH = 'scaler.pkl'
FEATURES_PATH = 'feature_names.pkl'

def load_artifacts():
    """Load model, scaler, and feature names from disk."""
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(
            f"'{MODEL_PATH}' not found. Run multivariate.ipynb first to train and save the model.")
    if not os.path.exists(SCALER_PATH):
        raise FileNotFoundError(
            f"'{SCALER_PATH}' not found. Run multivariate.ipynb first.")

    model    = joblib.load(MODEL_PATH)
    scaler   = joblib.load(SCALER_PATH)
    features = joblib.load(FEATURES_PATH) if os.path.exists(FEATURES_PATH) else None
    return model, scaler, features


def predict_malaria_incidence(raw_feature_array):
    """
    Predict malaria incidence (per 1,000 population at risk)
    from one row of feature values.

    Args:
        raw_feature_array (array-like):
            1-D array of feature values in the same order as feature_names.pkl.
            Values should be post log-transform (as done in the notebook)
            but PRE-standardisation (the scaler handles that here).

    Returns:
        float: Predicted malaria incidence on the original scale.
    """
    model, scaler, _ = load_artifacts()

    sample   = np.array(raw_feature_array).reshape(1, -1)
    scaled   = scaler.transform(sample)
    log_pred = model.predict(scaled)[0]

    # Reverse the log1p transform applied during preprocessing
    return float(np.expm1(log_pred))


# ── Demo: run a prediction on a hardcoded sample row ──────────────────────
if __name__ == '__main__':

    model, scaler, features = load_artifacts()

    print('━' * 62)
    print('🔮  MALARIA INCIDENCE PREDICTION SCRIPT')
    print('━' * 62)

    if features:
        print(f'\nExpected features ({len(features)}):')
        for i, f in enumerate(features, 1):
            print(f'  {i:2}. {f}')

    # ── Sample input: one row of realistic feature values ──────────────────
    # Replace these values with any actual row from your test dataset.
    # The values below are example medians typical of the dataset.
    # Order must match features listed above (feature_names.pkl).
    sample_input = np.zeros(scaler.n_features_in_)   # zeros as placeholder

    print(f'\nSample input (replace with real test row):')
    print(f'  {np.round(sample_input, 4)}')

    prediction = predict_malaria_incidence(sample_input)

    print(f'\n✅ Predicted malaria incidence : {prediction:.2f} per 1,000 pop at risk')
    print('━' * 62)
    print('\nTo use with your own data:')
    print('  from predict import predict_malaria_incidence')
    print('  result = predict_malaria_incidence([val1, val2, ...])')
    print('  print(result)')
