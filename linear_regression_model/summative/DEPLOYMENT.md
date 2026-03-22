# Malaria Predictor Deployment Guide

## Overview
This project consists of two main components:
1. **FastAPI Backend** - Machine learning prediction service
2. **Flutter Mobile App** - Cross-platform mobile interface

## Backend Deployment (Render)

### Prerequisites
- Render account
- GitHub repository connected

### Steps
1. Push code to GitHub
2. Create new Web Service on Render
3. Configure:
   - Build Command: `pip install -r linear_regression_model/summative/API/requirements.txt`
   - Start Command: `uvicorn linear_regression_model.summative.API.prediction:app --host 0.0.0.0 --port $PORT`
4. Add environment variables if needed
5. Deploy

### API Endpoints
- `GET /` - Health check
- `POST /predict` - Predict malaria incidence
- `POST /retrain` - Retrain model with new data

## Mobile App Deployment

### Android
```bash
cd linear_regression_model/summative/FlutterApp/malaria_predictor
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Configuration
Update API URL in `lib/main.dart`:
```dart
static const String _apiUrl = 'YOUR_RENDER_URL/predict';
```

## Testing
- Backend: `uvicorn prediction:app --reload`
- Mobile: `flutter run`
