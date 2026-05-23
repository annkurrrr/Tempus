# Tempus – AI-Assisted Productivity

Tempus is a sleek, modern productivity app built with Flutter that helps you structure your time around meaningful goals. It rejects the idea of optimizing every single minute, and instead focuses on intentionality—allowing you to track deep work sessions, set weekly goals, and use AI to create realistic schedules.

## 🌟 Key Features

### ⏳ Smart Session Tracking
- **Foreground Timer:** Track your sessions smoothly even when the app is in the background or screen is off (using `flutter_foreground_task`).
- **Productivity Levels:** Sessions are visualized in a grid (similar to GitHub contributions), color-coded by duration (from less than 30 mins to 8+ hours).
- **Streak Counter:** Automatically calculates and tracks your daily working streaks.

### 🎯 Weekly Goals
- Set a clear, actionable goal for the week.
- Unresolved goals from previous weeks are automatically flagged so you can review and mark them as Completed, In Progress, or Incomplete.

### 🤖 AI Scheduling (Powered by Gemini)
- Integrate your **Google Gemini API Key** securely on the device.
- The AI generates dynamic, realistic daily schedules based on your current weekly goal and the day of the week.

### ☁️ Cloud Sync (Supabase)
- **Authentication:** Secure Sign Up / Sign In via Supabase Auth.
- **Real-Time Sync:** Sessions are saved locally for offline access and synced to the cloud via Supabase PostgreSQL Database with Row Level Security (RLS).

### 📱 Native Android Home Widgets
- **Quick Timer Widget:** View your running timer, current session number, and active streak directly on your home screen.
- **Weekly Progress Widget:** See your total hours, week-over-week changes, and a 7-day bar chart of your productivity.

## 🛠 Tech Stack

- **Framework:** Flutter / Dart
- **Backend / Auth / Database:** Supabase
- **AI Integration:** Google Gemini API (via HTTP)
- **Local Storage:** SharedPreferences
- **Native Integration:** `home_widget` (Android widgets), `flutter_foreground_task` (background timers)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.11.5 or newer)
- A Supabase Project
- Google Gemini API Key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/annkurrrr/Tempus.git
   cd Tempus/tempus
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Supabase Setup:**
   - The app comes pre-configured with a Supabase URL and Anon Key in `lib/services/supabase_service.dart`.
   - To use your own backend, replace the `_supabaseUrl` and `_supabaseAnonKey` with your own credentials.
   - Make sure to create the `users` and `sessions` tables with the appropriate Row Level Security (RLS) policies.

4. **Run the app:**
   ```bash
   flutter run
   ```

### Gemini API Key Configuration
1. Go to [Google AI Studio](https://aistudio.google.com/) to get a free API key.
2. Open Tempus, navigate to the **Schedule** tab, and enter the key when prompted.
3. The key is securely stored locally on your device.

## 🤝 Contributing
Contributions, issues, and feature requests are welcome!

## ✍️ Author
- [Annkurrrr](https://github.com/annkurrrr)
