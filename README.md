<div align="center">

# 🥗🤖 AI BiBite

### AI-Powered Personalized Nutrition Assistant

A smart mobile nutrition assistant that combines artificial intelligence, food recognition, and personalized nutrition tracking to help users understand their meals, monitor daily goals, and build healthier eating habits.

<br>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![AI](https://img.shields.io/badge/AI-Powered-8A2BE2?style=for-the-badge)

</div>

---

## 📖 About

AI BiBite is an AI-powered personalized nutrition assistant designed to make daily nutrition tracking smarter, easier, and more personalized.

The application creates a personalized nutrition experience using information such as the user's age, height, weight, activity level, allergies, and personal goals.

Users can add meals by taking a photo or selecting an image from the gallery. Artificial intelligence analyzes the food image to identify the meal and provide nutritional information such as estimated calories and macronutrient values.

AI BiBite also enables users to track daily meals, monitor water intake, review nutrition history, follow progress toward personal goals, and receive allergen warnings based on profile information.

The main goal of AI BiBite is to combine artificial intelligence with everyday nutrition tracking and provide users with a simple, intelligent, and personalized digital nutrition assistant.

---

## 🚀 Key Features

- 📸 **AI Food Recognition** – Analyze food images captured with the camera or selected from the gallery
- 🧠 **AI Nutrition Analysis** – Estimate calories and macronutrient values of meals
- 👤 **Personalized User Profile** – Store information such as age, height, weight, activity level, allergies, and personal goals
- 🎯 **Personalized Nutrition Goals** – Monitor daily targets according to the user's profile and selected goal
- 🍽️ **Meal Tracking** – Organize meals as breakfast, lunch, dinner, and snacks
- 📊 **Daily Nutrition Overview** – Monitor calorie and macronutrient progress throughout the day
- 💧 **Water Intake Tracking** – Record daily water consumption and monitor progress toward the daily goal
- ⚠️ **Allergen Warnings** – Warn users about potential allergens based on profile information
- 📅 **Meal History** – Review previously recorded meals and nutrition data
- 🤖 **AI-Based Suggestions** – Provide personalized nutrition suggestions based on user profile and tracking data
- 🔐 **Secure Authentication** – Manage user authentication and personal data securely
- 📱 **Cross-Platform Support** – Designed for Android and iOS devices

---

## ⚙️ How It Works

AI BiBite follows a simple and personalized nutrition tracking process:

1. The user creates an account and signs in securely.
2. The user completes a personal profile with information such as age, height, weight, activity level, allergies, and nutrition goals.
3. The application determines personalized daily tracking goals.
4. The user adds a meal by taking a photo or selecting an image from the gallery.
5. Artificial intelligence analyzes the food image.
6. The detected food and estimated nutritional values are presented to the user.
7. The meal is saved to the appropriate meal category.
8. Daily calorie, macronutrient, and water progress is updated.
9. Users can review previous meals and monitor their nutrition history.
10. AI-based suggestions support users in managing their daily eating habits.

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform mobile application development |
| **Dart** | Main programming language |
| **Supabase Auth** | User authentication and account management |
| **Supabase Database** | Cloud-based data storage and management |
| **SQL** | Database schema, relationships, and security policies |
| **AI / ML Services** | Food recognition and nutritional analysis |

---

## 🏗️ System Architecture

AI BiBite uses a modern mobile application architecture consisting of three main layers:

### 📱 Mobile Application

The user interface is developed with Flutter and Dart. It manages user interaction, profile setup, meal tracking, water tracking, nutrition history, and AI analysis results.

### ☁️ Backend and Database

Supabase is used for authentication, user management, and cloud database operations. User profiles, nutrition goals, meals, meal items, analysis results, and other application data are stored and managed through the backend.

### 🤖 Artificial Intelligence Layer

The AI layer analyzes food images and provides food recognition and nutritional information. The analysis results are integrated into the meal tracking process and used to support personalized nutrition tracking.

---

## 🗄️ Database Structure

The application database is designed around the following main entities:

- **Users** – Stores account and profile information
- **Goals** – Stores personal nutrition, weight, calorie, and water goals
- **Meals** – Stores daily meals and meal categories
- **Meal Items** – Stores foods and their nutritional values
- **Photos** – Stores meal image information and AI analysis results
- **Suggestions** – Stores personalized AI-based recommendations

The database structure connects user profiles with personal goals, meals, nutritional values, and AI-generated results.

---

## 📱 Application Flow

The main application flow is:

**Authentication → Profile Setup → Home Dashboard → Add Meal → AI Analysis → Nutrition Results → Daily Tracking → History**

After authentication, new users complete their profile information and define their personal goals.

The home dashboard displays daily nutrition progress, meal records, water consumption, and remaining goals. Users can add new meals through the camera or gallery and review the AI analysis before saving the meal.

---

## 🔒 Security and Authentication

AI BiBite uses Supabase authentication services for secure account management.

User-specific data is associated with authenticated accounts, allowing each user to access and manage their own profile, meals, goals, and tracking information.

Database access policies are designed to protect personal application data and separate user records.

---

## 🎯 Project Purpose

The purpose of AI BiBite is to demonstrate how artificial intelligence can be integrated into a modern mobile application to create a practical and personalized nutrition tracking experience.

The project combines artificial intelligence, food image analysis, personalized user profiles, nutrition tracking, water intake monitoring, allergen awareness, cloud-based data management, and cross-platform mobile development in a single application.

---

## 🔮 Future Improvements

- More advanced food recognition models
- Improved portion size estimation
- More detailed vitamin and mineral analysis
- Personalized weekly nutrition reports
- Advanced progress charts and statistics
- Smarter AI-based meal recommendations
- Barcode scanning for packaged foods
- Integration with wearable devices
- Expanded allergen detection
- Multi-language support

---

## 🔧 Getting Started

The Firebase config file is not stored in the repository. Download `google-services.json` for the `com.betul.aibibite` Android app from the Firebase Console (Project settings → Your apps) and place it at `android/app/google-services.json`.

The Gemini API key is not stored in the repository. Provide it at build time:

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_api_key
```

---

## 👩‍💻 Developer

**Betül Altunyuva**

Software Engineering Student

Interested in mobile application development, artificial intelligence, computer vision, and modern software technologies.

---

<div align="center">

### 🥗 Eat Smarter. Track Better. Live Healthier.

**AI BiBite – Your Personalized AI Nutrition Assistant**

</div>
