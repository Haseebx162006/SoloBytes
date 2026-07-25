# CashPilot

CashPilot is a Flutter-based financial management app for small businesses. It combines authentication, business profile setup, transaction tracking, ledger management, Excel import, and AI-powered insights in a clean mobile-first dashboard.

## Overview

The app starts with a splash screen, then routes through an authentication wrapper that sends users to sign in, business setup, or the main dashboard depending on their account state. The dashboard is organized into five tabs: Overview, Transactions, Ledger, Import, and Profile.

CashPilot uses Firebase for authentication and data storage, Riverpod for state management, and a custom UI built around the Poppins font family.

## Features

- Email/password sign in and account creation
- Google sign in support
- Business profile setup after registration
- Dashboard overview with net balance, income, expenses, ledger metrics, and recent activity
- Transactions and ledger views for cash flow tracking
- Excel import for financial records with preview and validation
- AI-generated financial insights from cash summary data
- PDF generation and printing for transaction reports
- English and Urdu UI support

## Tech Stack

- Flutter
- Firebase Auth, Firebase Core, Cloud Firestore, Firebase Storage
- Riverpod
- file_picker, excel, fl_chart, pdf, printing
- flutter_dotenv
- Groq API for AI insights
- Cloudinary for file backup uploads

## Project Structure

- `lib/main.dart` initializes Firebase, dotenv, and the app theme
- `lib/AuthWrapper.dart` decides whether to show login, signup, or dashboard
- `lib/UI/` contains the screens and dashboard tabs
- `lib/Providers/` contains Riverpod state
- `lib/data/` contains repositories, services, models, and Excel/PDF helpers
- `lib/domain/` contains entities and use cases
- `lib/theme/` contains colors, typography, and theme setup

## Prerequisites

- Flutter SDK 3.11 or newer
- A configured Firebase project for Android and iOS
- A Groq API key for AI insights
- A Cloudinary account for Excel backup uploads

## Setup

1. Install dependencies.

```bash
flutter pub get
```

2. Make sure Firebase is configured for the app and that `lib/firebase_options.dart` matches your project.

3. Create `lib/Assets/.env` with the required environment variables.

```env
GROQ_API_KEY=your_groq_api_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_upload_preset
CLOUDINARY_UPLOAD_FOLDER=imports
```

4. Confirm the bundled assets and fonts exist in `lib/Assets/`.

## Run

```bash
flutter run
```

## Build And Test

```bash
flutter test
flutter build apk
flutter build ios
```

## Notes

- The app loads Firebase before rendering the UI, so missing Firebase configuration will stop startup.
- The import screen accepts `.xlsx` and `.xls` files and shows a preview before processing.
- The profile tab includes a language toggle for English and Urdu.

## License

No license has been specified yet.
