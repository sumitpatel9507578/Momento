import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<void> createUserProfile(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<bool> userExists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }
}
