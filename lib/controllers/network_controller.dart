import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();

    checkConnection();

    Connectivity().onConnectivityChanged.listen((result) {
      isConnected.value =
          result.isNotEmpty &&
              !result.contains(ConnectivityResult.none);
    });
  }

  Future<void> checkConnection() async {
    final result = await Connectivity().checkConnectivity();

    isConnected.value =
        result.isNotEmpty &&
            !result.contains(ConnectivityResult.none);
  }
}