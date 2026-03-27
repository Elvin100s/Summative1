# Malaria Incidence Prediction in Africa

## Mission
Combating infectious diseases in East and Central Africa by predicting malaria incidence rates using machine learning to guide health resource allocation and reduce preventable deaths.

**Dataset:** Malaria in Africa (lydia70, Kaggle / World Bank Open Data) — 54 African countries, 2007–2017
**Dataset size:** 594 rows × 27 features — epidemiological, demographic, and health intervention variables (bed net usage, fever treatment rates, antenatal care, reported cases, sanitation, water access, and more) across 54 countries over 10 years.
**Source:** https://www.kaggle.com/datasets/lydia70/malaria-in-africa
**Target:** `Incidence of malaria (per 1,000 population at risk)`

## Models
Three regression models are trained and compared:
- **Linear Regression** (scikit-learn + manual batch gradient descent)
- **Decision Tree Regressor**
- **Random Forest Regressor** ← best model (R² ≈ 0.98)

## Results

| Model | MSE | MAE | R² |
|---|---|---|---|
| Linear Regression | 0.6887 | 0.6589 | 0.8372 |
| Decision Tree | 0.3443 | 0.3809 | 0.9186 |
| Random Forest | 0.0895 | 0.2025 | 0.9788 |

## Repository Structure

```
linear_regression_model/
│
├── README.md
├── requirements.txt
├── .gitignore
└── summative/
    ├── linear_regression/
    │   ├── multivariate.ipynb   ← full pipeline: EDA, preprocessing, training, evaluation
    │   └── predict.py           ← standalone prediction script
    ├── API/
    └── FlutterApp/
```

## API

- **Public API endpoint:** https://malaria-predictor-api.onrender.com/predict
- **Swagger UI:** https://malaria-predictor-api.onrender.com/docs

## Flutter App — How to Run

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Connect your Android phone via USB with USB Debugging enabled
3. Run:
```bash
cd linear_regression_model/summative/FlutterApp/malaria_predictor
flutter pub get
flutter run
```

## Demo Video

https://www.youtube.com/watch?v=piQf1J3AkhI

## Setup

```bash
pip install -r requirements.txt
```

Run the notebook to train models and save artifacts (`best_model.pkl`, `scaler.pkl`, `feature_names.pkl`), then run the prediction script:

```bash
cd summative/linear_regression
jupyter notebook multivariate.ipynb
python predict.py
```
