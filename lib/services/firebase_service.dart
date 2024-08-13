import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to the authentication state changes
  Stream<UserModel?> userStream() {
    return _auth.authStateChanges().map((User? user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        UserModel newUser = UserModel.fromFirebaseUser(user);
        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toMap(), SetOptions(merge: true));
        return newUser;
      }
      return null;
    } catch (e) {
      print('Error during Google sign-in: $e');
      return null;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        UserModel newUser = UserModel.fromFirebaseUser(user);
        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toMap(), SetOptions(merge: true));
        return newUser;
      }
      return null;
    } catch (e) {
      print('Error during email registration: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        return UserModel.fromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      print('Error during email sign-in: $e');
      return null;
    }
  }

  // Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error during sign-out: $e');
    }
  }
}

// Check the platform if also developing for IOS.
FirebaseOptions firebaseOptions = const FirebaseOptions(
  apiKey: 'AIzaSyBDtqLWpsnAJBkmnOgsY2WJzWzu1j1Pd2A',
  appId: '1:890110941957:android:b322f2f7aee440deb7756c',
  messagingSenderId: '890110941957',
  projectId: 'chessmaster-e0dbb',
  storageBucket: 'chessmaster-e0dbb.appspot.com',
);
