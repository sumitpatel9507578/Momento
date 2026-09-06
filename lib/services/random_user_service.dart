import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class RandomUserService {
  static const String _url = 'https://randomuser.me/api/?results=20';

  Future<List<UserModel>> fetchUsers() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load users');
    }

    final data = jsonDecode(response.body);

    final List users = data['results'];

    return users
        .map<UserModel>((user) => UserModel.fromRandomUserJson(user))
        .toList();
  }
}
