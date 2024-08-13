import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String uid;
  String email;
  String displayName;
  String photoURL;

  UserModel(
      {required this.uid,
      required this.email,
      required this.displayName,
      required this.photoURL});

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email!,
      displayName: user.displayName!,
      photoURL: user.photoURL!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }
}
