import 'dart:convert';

class UserModel {
  String? uid;
  String? name;
  String? email;
  String? image;
  String? createdAt;
  int? playerRating;

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.image,
    this.createdAt,
    this.playerRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'image': image,
      'createdAt': createdAt,
      'playerRating': playerRating
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      image: map['image'],
      createdAt: map['createdAt'],
      playerRating: map['playerRating'],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
