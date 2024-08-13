import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var leaderboard = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchLeaderboard();
  }

  void fetchLeaderboard() {
    _firestore
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .snapshots()
        .listen((snapshot) {
      leaderboard.value = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
