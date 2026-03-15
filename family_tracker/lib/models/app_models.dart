import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;
  final String? groupId;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.latitude,
    this.longitude,
    this.lastSeen,
    this.groupId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      lastSeen: data['lastSeen'] != null ? (data['lastSeen'] as Timestamp).toDate() : null,
      groupId: data['groupId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'groupId': groupId,
    };
  }
}

class GroupModel {
  final String id;
  final String code;
  final String name;

  GroupModel({
    required this.id,
    required this.code,
    required this.name,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
    };
  }
}
