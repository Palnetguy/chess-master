import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Widget buildGameType({
//   required String lable,
//   String? gameTime,
//   IconData? icon,
//   required Function() onTap,
// }) {
//   return InkWell(
//     onTap: onTap,
//     child: Card(
//       child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//         icon != null
//             ? Icon(icon)
//             : gameTime! == '60+0'
//                 ? const SizedBox.shrink()
//                 : Text(gameTime),
//         const SizedBox(
//           height: 10,
//         ),
//         Text(
//           lable,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         )
//       ]),
//     ),
//   );
// }

// String getTimerToDisplay({
//   required GameProvider gameProvider,
//   required bool isUser,
// }) {
//   String timer = '';
//   // check if is user
//   if (isUser) {
//     if (gameProvider.player == Squares.white) {
//       timer = gameProvider.whitesTime.toString().substring(2, 7);
//     }
//     if (gameProvider.player == Squares.black) {
//       timer = gameProvider.blacksTime.toString().substring(2, 7);
//     }
//   } else {
//     // if its not user do the opposite
//     if (gameProvider.player == Squares.white) {
//       timer = gameProvider.blacksTime.toString().substring(2, 7);
//     }
//     if (gameProvider.player == Squares.black) {
//       timer = gameProvider.whitesTime.toString().substring(2, 7);
//     }
//   }

//   return timer;
// }

// method to display the correct time below the board, if user is white then display white time
// if user is black then display black time

final List<String> gameTimes = [
  'Bullet 1+0',
  'Bullet 2+1',
  'Bullet 3+0',
  'Bullet 3+2',
  'Bullet 5+0',
  'Bullet 5+3',
  'Rapid 10+0',
  'Rapid 10+5',
  'Rapid 15+10',
  'Classical 30+0',
  'Classical 30+20',
  'Custom 60+0',
];

var textFormDecoration = InputDecoration(
  labelText: 'enter your password',
  hintText: 'enter your password',
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Color(0xFF8D6E63), width: 1),
    borderRadius: BorderRadius.circular(8),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.orangeAccent, width: 1),
    borderRadius: BorderRadius.circular(8),
  ),
);

// pick an image
Future<File?> pickImage({
  required bool fromCamera,
  required Function(String) onFail,
}) async {
  File? fileImage;
  if (fromCamera) {
    try {
      final takenPhoto =
          await ImagePicker().pickImage(source: ImageSource.camera);

      if (takenPhoto != null) {
        fileImage = File(takenPhoto.path);
      }
    } catch (e) {
      onFail(e.toString());
    }
  } else {
    try {
      final choosenImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (choosenImage != null) {
        fileImage = File(choosenImage.path);
      }
    } catch (e) {
      onFail(e.toString());
    }
  }

  return fileImage;
}

// validate email method
bool validateEmail(String email) {
  // Trim the email to remove leading and trailing whitespace
  email = email.trim();

  // Regular expression for email validation
  final emailRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  return emailRegExp.hasMatch(email);
}

// You can also create a reusable validator function
String? validateEmailField(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  } else if (!validateEmail(value)) {
    return 'Please enter a valid email';
  }
  return null;
}
