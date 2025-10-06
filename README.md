# 🎒 PackPal — Your Smart Packing Assistant

PackPal is an intelligent iOS app that helps travelers pack smarter, faster, and stress-free.
Using on-device AI, PackPal generates personalized packing lists based on trip details, activities, and weather — all while keeping your data private.

## ✨ Features

- 🧳 **AI-Powered Packing Lists**: Personalized based on your trip duration, destination, and activities.
- 🌤️ **Smart Context Awareness**: Automatically adjusts for weather conditions.
- 🔒 **On-Device Privacy**: Built with Core ML — no cloud or account required.
- 🧠 **Natural Language Input**: Type "4-day ski trip in Alberta" and PackPal knows exactly what to include.
- 📱 **Modern Design**: Clean, intuitive UIKit interface with consistent color themes.

## 🛠️ Built With

| Category | Technologies |
|----------|-------------|
| Language | Swift |
| Frameworks | UIKit, Core ML |
| AI Model | MobileBERT (on-device embeddings) |
| Platform | iOS |
| Tools | Xcode, Core ML Tools |

## 🚀 Getting Started

### Prerequisites

- macOS with Xcode 15 or later
- iOS 17+ Simulator or Device

### Steps to Run

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/PackPal.git
   cd PackPal
   ```

2. Open the project in Xcode
   ```bash
   open PackPal3.xcodeproj
   ```

3. Build and run on a simulator or a connected device (⌘ + R)

That's it! You can test the full app experience directly from Xcode.

## 🧩 Project Structure

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

If you don't have Xcode installed, you can still view the code or UI layout on GitHub.
For a full run, open it in Xcode and press Run (⌘ + R) — no additional setup required.

## 📈 Future Improvements

- Multi-trip support and user profiles
- Cross-device syncing via iCloud
- Expanded AI model for packing optimization
- Companion Apple Watch app

## 💡 Inspiration

PackPal was built for travelers who want peace of mind before every trip.
We all know that "Did I forget something?" moment — PackPal ensures you never have to feel it again.

## 👥 Team

Created by Kishan Joshi as part of PackPal3 development.

## 📄 License

This project is licensed under the MIT License.

---

### ✅ Optional Note for Devpost:

"If you'd like to try PackPal yourself, simply clone the repository and open it in Xcode. The app runs locally and does not require any external setup."
