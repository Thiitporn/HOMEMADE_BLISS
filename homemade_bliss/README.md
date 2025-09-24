# Homemade Bliss - Micro-Commerce Bakery

Welcome to the Homemade Bliss project! This Flutter application is designed for a micro-commerce bakery, allowing users to browse products, manage their cart, and place orders seamlessly. The app is integrated with Firebase for authentication and data management.

## Features

- User authentication (signup, login, and profile management)
- Product listing with details
- Shopping cart functionality
- Order management and history
- Responsive design with a user-friendly interface

## Getting Started

To get started with the Homemade Bliss application, follow these steps:

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd homemade_bliss
   ```

2. **Install dependencies:**
   Make sure you have Flutter installed on your machine. Run the following command to install the necessary packages:
   ```
   flutter pub get
   ```

3. **Set up Firebase:**
   - Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/).
   - Add your Flutter app to the Firebase project and follow the instructions to download the `google-services.json` file.
   - Place the `google-services.json` file in the `android/app` directory.

4. **Run the application:**
   Use the following command to run the app on your device or emulator:
   ```
   flutter run
   ```

## Folder Structure

The project follows a feature-based folder structure for better organization and maintainability:

```
lib
├── main.dart
├── app.dart
├── core
│   ├── constants
│   │   └── strings.dart
│   ├── services
│   │   └── firebase_service.dart
│   └── utils
│       └── validators.dart
├── features
│   ├── auth
│   │   ├── data
│   │   │   └── auth_repository.dart
│   │   ├── provider
│   │   │   └── auth_provider.dart
│   │   └── ui
│   │       └── login_screen.dart
│   ├── products
│   │   ├── data
│   │   │   └── product_repository.dart
│   │   ├── provider
│   │   │   └── product_provider.dart
│   │   └── ui
│   │       └── product_list_screen.dart
│   ├── cart
│   │   ├── provider
│   │   │   └── cart_provider.dart
│   │   └── ui
│   │       └── cart_screen.dart
│   └── orders
│       ├── provider
│       │   └── order_provider.dart
│       └── ui
│           └── order_screen.dart
└── shared
    ├── widgets
    │   └── custom_button.dart
    └── themes
        └── app_theme.dart
```

## Contributing

Contributions are welcome! If you have suggestions for improvements or new features, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.