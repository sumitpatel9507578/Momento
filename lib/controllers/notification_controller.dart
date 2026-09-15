import 'dart:convert';
import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';

class NotificationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  
  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await _apiService.get(ApiConstants.notifications);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List notifsJson = data['data'] ?? [];
        notifications.assignAll(notifsJson.map((j) => NotificationModel.fromJson(j)).toList());
      } else {
        errorMessage.value = 'Failed to load notifications';
      }
    } catch (e) {
      print("Notifications Error: $e");
      errorMessage.value = 'Something went wrong';
    } finally {
      isLoading.value = false;
    }
  }
}
