import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twitter_login/twitter_login.dart';

import '../constants.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final RxBool _isLoading = false.obs;
  final RxBool _isSignedIn = false.obs;
  final Rxn<String> _uid = Rxn<String>();
  final Rxn<UserModel> _userModel = Rxn<UserModel>();

  bool get isLoading => _isLoading.value;
  bool get isSignIn => _isSignedIn.value;
  UserModel? get userModel => _userModel.value;
  String? get uid => _uid.value;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  void setIsLoading(bool value) => _isLoading.value = value;

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading.value = true;
    UserCredential userCredential = await _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);
    _uid.value = userCredential.user!.uid;
    return userCredential;
  }

  Future<UserCredential?> signInUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading.value = true;
    UserCredential userCredential = await _firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password);
    _uid.value = userCredential.user!.uid;
    return userCredential;
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        if (userCredential.additionalUserInfo!.isNewUser) {
          await _createUserInFirestore(user);
        }
      }

      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);
        UserCredential userCredential =
            await _firebaseAuth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          if (userCredential.additionalUserInfo!.isNewUser) {
            await _createUserInFirestore(user);
          }
        }

        return user;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<User?> signInWithTwitter() async {
    try {
      final twitterLogin = TwitterLogin(
        apiKey: 'YOUR_TWITTER_API_KEY',
        apiSecretKey: 'YOUR_TWITTER_API_SECRET_KEY',
        redirectURI: 'YOUR_TWITTER_REDIRECT_URI',
      );
      final authResult = await twitterLogin.login();
      if (authResult.status == TwitterLoginStatus.loggedIn) {
        final OAuthCredential twitterAuthCredential =
            TwitterAuthProvider.credential(
          accessToken: authResult.authToken!,
          secret: authResult.authTokenSecret!,
        );
        UserCredential userCredential =
            await _firebaseAuth.signInWithCredential(twitterAuthCredential);
        User? user = userCredential.user;

        if (user != null) {
          if (userCredential.additionalUserInfo!.isNewUser) {
            await _createUserInFirestore(user);
          }
        }

        return user;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> _createUserInFirestore(User user) async {
    UserModel newUser = UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      image: user.photoURL ?? '',
      createdAt: DateTime.now().toString(),
      playerRating: 0,
    );

    await _firebaseFirestore
        .collection(Constants.users)
        .doc(user.uid)
        .set(newUser.toMap());
  }

  Future<bool> checkUserExist() async {
    DocumentSnapshot documentSnapshot =
        await _firebaseFirestore.collection(Constants.users).doc(uid).get();
    return documentSnapshot.exists;
  }

  Future<void> getUserDataFromFireStore() async {
    await _firebaseFirestore
        .collection(Constants.users)
        .doc(_firebaseAuth.currentUser!.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      _userModel.value =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      _uid.value = _userModel.value!.uid;
    });
  }

  Future<void> saveUserDataToSharedPref() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        Constants.userModel, jsonEncode(_userModel.value!.toMap()));
  }

  Future<void> getUserDataToSharedPref() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String data = sharedPreferences.getString(Constants.userModel) ?? '';
    _userModel.value = UserModel.fromMap(jsonDecode(data));
    _uid.value = _userModel.value!.uid;
  }

  Future<void> setSignedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setBool(Constants.isSignedIn, true);
    _isSignedIn.value = true;
  }

  Future<bool> checkIsSignedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    _isSignedIn.value =
        sharedPreferences.getBool(Constants.isSignedIn) ?? false;
    return _isSignedIn.value;
  }

  Future<void> saveUserDataToFireStore({
    required UserModel currentUser,
    required File? fileImage,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    try {
      if (fileImage != null) {
        String imageUrl = await storeFileImageToStorage(
          ref: '$Constants.userImages/$uid.jpg',
          file: fileImage,
        );
        currentUser.image = imageUrl;
      }

      currentUser.createdAt = DateTime.now().microsecondsSinceEpoch.toString();
      _userModel.value = currentUser;

      await _firebaseFirestore
          .collection(Constants.users)
          .doc(uid)
          .set(currentUser.toMap());

      onSuccess();
      _isLoading.value = false;
    } on FirebaseException catch (e) {
      _isLoading.value = false;
      onFail(e.toString());
    }
  }

  Future<String> storeFileImageToStorage({
    required String ref,
    required File file,
  }) async {
    UploadTask uploadTask = _firebaseStorage.ref().child(ref).putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> signOutUser() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await _firebaseAuth.signOut();
    _isSignedIn.value = false;
    sharedPreferences.clear();
    Get.offAllNamed(Constants.loginScreen);
  }
}
