# 🎒 PackPal: Your Smart Packing Assistant

PackPal is an intelligent iOS app that helps travelers pack smarter, faster, and stress-free. Using on-device AI, it generates personalized packing lists based on trip details, activities, and weather, all while keeping your data private.

## ✨ Features

- **AI-Powered Packing Lists**: Personalized based on trip duration, destination, and activities.
- **Smart Context Awareness**: Automatically adjusts for weather and conditions.
- **On-Device Privacy**: Built with Core ML to keep all data local.
- **Natural Language Input**: Type phrases like "4-day ski trip in Alberta" and PackPal knows what to include.
- **Modern Design**: Clean, intuitive UIKit interface with consistent color themes.

## 🛠️ Built With

| Category | Technologies |
|----------|-------------|
| Language | Swift |
| Frameworks | UIKit, Core ML |
| AI Model | MobileBERT (on-device embeddings) |
| Platform | iOS |
| Tools | Xcode, Core ML Tools |

## 🧩 Tech Architecture

PackPal follows an MVC architecture with a modular service layer for AI and data handling. UIKit manages all interface components, while Core ML powers the AI logic for generating packing recommendations. The design system maintains consistent color, layout, and typography across the app.

## 🚀 Getting Started

### Prerequisites

- macOS with Xcode 15 or later
- iOS 17+ simulator or physical device

### Steps to Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Somebody239/PackPal.git
   cd PackPal
   ```

2. **Download the AI model:**
   ```bash
   ./download_model.sh
   ```
   
   or manually download from [Apple Core ML Models](https://ml-assets.apple.com/coreml/models/Text/QuestionAnswering/BERT_SQUAD/BERTSQUADFP16.mlmodel), rename it `MobileBERT.mlmodel`, and place it in `PackPal3/AI/`.

3. **Add your API keys:**
   - In `AI/HuggingFaceService.swift`: Replace `"YOUR_HUGGING_FACE_API_TOKEN_HERE"`.
   - In `Utilities/WeatherService.swift`: Replace `"YOUR_OPENWEATHER_API_KEY_HERE"`.
   - Get a free key from [OpenWeather](https://openweathermap.org/api).

4. **Open the project in Xcode:**
   ```bash
   open PackPal3.xcodeproj
   ```

5. **Build and run on a simulator or device with ⌘ + R.**

## 📁 Project Structure

```
PackPal3/
├── AI/                    # AI and ML integration
│   ├── BERTTokenizer.swift
│   ├── EmbeddingAIService.swift
│   ├── HuggingFaceService.swift
│   ├── MobileBERT.mlmodel
│   └── vocab.txt
├── Models/                # Data models for trips and geocoding
│   ├── Trip.swift
│   └── TripGeocoder.swift
├── ViewControllers/       # Main view controllers
│   ├── HomeContentViewController.swift
│   ├── TripCreationViewController.swift
│   ├── TripDetailsViewController.swift
│   ├── PackingListGeneratorViewController.swift
│   └── ...
├── UI/                    # Custom UI components and design system
│   ├── DesignSystem.swift
│   ├── GlassBottomBarView.swift
│   ├── GlassCapsuleButton.swift
│   └── ...
├── Settings/              # Settings management
│   ├── SettingsManager.swift
│   └── SettingsViewController.swift
├── Utilities/             # Helper utilities
│   ├── DocumentPicker.swift
│   ├── Haptics.swift
│   └── WeatherService.swift
└── Assets.xcassets/       # App icons and color sets
```

## 📘 Try It Out

If you don't have Xcode installed, you can still browse the code and interface layouts on GitHub.
For a full experience, open the project in Xcode and press Run (⌘ + R) to launch it instantly.

## 📈 Future Improvements

- Multi-trip management and user profiles
- Cross-device syncing with iCloud
- Expanded AI model for improved packing suggestions
- Apple Watch companion app

## 💡 Inspiration

PackPal was inspired by the stress of last-minute travel packing. That "Did I forget something?" feeling can ruin the start of a trip. PackPal was built to make sure travelers can leave with peace of mind, every time.

## 🌍 Impact

PackPal helps travelers pack efficiently and avoid forgetting essentials, reducing overpacking and waste. By encouraging smarter travel habits, it supports more sustainable and organized travel experiences.

## 👤 Team

Developed by Kishan Joshi for the LUMA Startathon 2025.

## 📄 License

This project is licensed under the MIT License.

---

### ✅ Optional note for Devpost:

"If you'd like to try PackPal yourself, simply clone the repository and open it in Xcode. The app runs locally and requires no additional setup."