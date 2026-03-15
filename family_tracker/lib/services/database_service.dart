import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserLocation(String uid, double lat, double lng) async {
    await _db.collection('users').doc(uid).update({
      'latitude': lat,
      'longitude': lng,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> createGroup(String uid, String groupName) async {
    String code = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    DocumentReference groupRef = await _db.collection('groups').add({
      'name': groupName,
      'code': code,
      'creator': uid,
    });

    await _db.collection('users').doc(uid).update({'groupId': groupRef.id});
    return code;
  }

  Future<bool> joinGroup(String uid, String code) async {
    QuerySnapshot groupQuery = await _db.collection('groups').where('code', isEqualTo: code).limit(1).get();

    if (groupQuery.docs.isNotEmpty) {
      String groupId = groupQuery.docs.first.id;
      await _db.collection('users').doc(uid).update({'groupId': groupId});
      return true;
    }
    return false;
  }

  Stream<UserModel> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) => UserModel.fromFirestore(doc));
  }

  Stream<List<UserModel>> getFamilyMembersStream(String groupId) {
    return _db.collection('users')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }
}
