# ChessMaster

ChessMaster is a feature-rich Flutter-based chess game application that offers both online and offline play options. Whether you want to test your skills against an AI engine or challenge players around the world, ChessMaster has you covered.

 Features

- Authentication: Secure login and registration system using Firebase Authentication.
  
- Offline Mode: Play against a powerful chess engine without an internet connection. Perfect for honing your skills.

- Online Multiplayer: Challenge friends or play against random opponents online with real-time game synchronization using Firebase Firestore.

- Time Controls: Choose from various time controls (e.g., 1 min, 3 min, 5 min, etc.) to make the game more challenging and fast-paced.

- Leaderboard: Track your progress and compare your ranking with other players in the global leaderboard.

- Dark Mode: Toggle between light and dark themes to suit your preference.

- Notifications: Receive notifications when you receive game invitations or when it's your turn to play.

- GetX for State Management: Efficient and reactive state management across the app using GetX.

 Project Structure

```bash
lib/
│
├── controllers/           # GetX controllers for handling logic and state management
│   ├── auth_controller.dart
│   ├── chess_controller.dart
│   ├── leaderboard_controller.dart
│   └── notification_controller.dart
│
├── models/                # Models representing the data structures used in the app
│   └── chess_game.dart
│
├── services/              # Services for Firebase, notifications, etc.
│   ├── firebase_service.dart
│   ├── notification_service.dart
│   └── chess_engine_service.dart
│
├── views/                 # UI screens for different features
│   ├── auth_view.dart
│   ├── chess_view.dart
│   ├── leaderboard_view.dart
│   ├── profile_view.dart
│   └── time_selection_view.dart
│
├── widgets/               # Reusable UI components like chess board, timers, etc.
│   └── chess_board.dart
│
└── main.dart              # Entry point of the application
```

 Getting Started

# Prerequisites

- Flutter SDK: Make sure you have Flutter installed on your machine. You can follow the instructions [here](https://flutter.dev/docs/get-started/install).
- Firebase Account: Set up a Firebase project and enable Firestore, Authentication, and Firebase Cloud Messaging.

# Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Palnetguy/chess-master.git
   cd ChessMaster
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Firebase:

   - Add your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) to the respective folders.
   - Ensure your Firebase project is correctly set up with Firestore, Authentication, and Firebase Cloud Messaging enabled.

4. Run the app:

   flutter run

 Usage

- Login/Register: Start by creating an account or logging in with an existing one.
- Choose a Game Mode: Select between playing offline against the engine or online against other players.
- Set Time Control: Choose your preferred time control before starting a match.
- Enjoy the Game: Play chess, improve your skills, and climb the leaderboard!

 Contribution

Feel free to fork the repository and submit pull requests for improvements, bug fixes, or new features.


This project is licensed under the MIT License. 

For any inquiries or suggestions, feel free to contact me at [tusingwiremartinrhinetreviz@gmail.com](mailto:tusingwiremartinrhinetreviz@gmail.com).
