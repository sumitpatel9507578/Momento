import 'package:get/get.dart';

import '../models/user_model.dart';
import '../services/random_user_service.dart';

class ProfileController extends GetxController {
  final RandomUserService _service = RandomUserService();

  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Current profile ke liye fake user.
  final currentUser = Rxn<UserModel>();

  final selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.fetchUsers();

      users.assignAll(result);

      if (result.isNotEmpty) {
        currentUser.value = result.first;
      }
    } catch (e) {
      errorMessage.value = 'Unable to load users.';
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  List<UserModel> get followers {
    if (users.length <= 1) return users;
    return users.sublist(0, users.length > 10 ? 10 : users.length);
  }

  List<UserModel> get following {
    if (users.length <= 1) return users;
    return users.reversed.take(users.length > 10 ? 10 : users.length).toList();
  }

  Future<void> refreshUsers() async {
    await loadUsers();
  }

  final selectedProfileTab = 0.obs;

  void changeProfileTab(int index) {
    selectedProfileTab.value = index;
  }

  List<String> get fakePostImages {
    return users
        .map((user) => user.profileImage)
        .where((image) => image.isNotEmpty)
        .toList();
  }

  List<String> get currentTabImages {
    switch (selectedProfileTab.value) {
      case 1: // Reels
        return fakeReelImages;

      case 2: // Saved
        return fakeSavedImages;

      case 3: // Tagged
        return fakeTaggedImages;

      case 0: // Posts
      default:
        return fakePostImages;
    }
  }

  List<String> get fakeReelImages {
    return users
        .skip(2)
        .map((user) => user.profileImage)
        .where((image) => image.isNotEmpty)
        .toList();
  }

  List<String> get fakeSavedImages {
    return users
        .skip(4)
        .map((user) => user.profileImage)
        .where((image) => image.isNotEmpty)
        .toList();
  }

  List<String> get fakeTaggedImages {
    return users
        .skip(6)
        .map((user) => user.profileImage)
        .where((image) => image.isNotEmpty)
        .toList();
  }

  final followedUsers = <String>{}.obs;

  bool isFollowing(String uid) {
    return followedUsers.contains(uid);
  }

  void toggleFollow(String uid) {
    if (followedUsers.contains(uid)) {
      followedUsers.remove(uid);
    } else {
      followedUsers.add(uid);
    }
  }
}
