class ApiConstants {
  // Toggle this for Production vs Development
  static const bool isProduction = true;

  // Official Momento Backend (Production)
  static const String prodServerUrl = "https://momento-api-20.onrender.com";

  // Local Machine IP (Development) - Using the IP from your logs
  static const String devServerUrl = "http://192.168.31.240:5000";

  static String get serverUrl => isProduction ? prodServerUrl : devServerUrl;
  static String get baseUrl => "$serverUrl/api";

  // Auth
  static String get register => "$baseUrl/auth/register";
  static String get login => "$baseUrl/auth/login";

  // Profile / Users
  static String get me => "$baseUrl/users/me";
  static String get users => "$baseUrl/users";
  static String get searchUsers => "$baseUrl/users/search";

  // Posts / Social
  static String get posts => "$baseUrl/posts";
  static String get likes => "$baseUrl/likes";
  static String get follows => "$baseUrl/follows";
  static String get comments => "$baseUrl/posts";

  // Media
  static String get stories => "$baseUrl/stories";
  static String get reels => "$baseUrl/reels";
  static String get songs => "$baseUrl/songs";

  // Messaging / Notifs
  static String get messages => "$baseUrl/messages";
  static String get notifications => "$baseUrl/notifications";

  static String get health => "$serverUrl/health";

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty || path == "null") return "";

    // If it's already a full URL (like Gravatar or external links)
    if (path.startsWith("http")) return path;

    // Ensure path starts with a single slash
    String cleanPath = path.startsWith("/") ? path : "/$path";

    // Construct final URL
    final fullUrl = "$serverUrl$cleanPath";

    // Detect media type for better logging
    final isVideo =
        path.toLowerCase().endsWith('.mp4') ||
        path.toLowerCase().endsWith('.mov') ||
        path.toLowerCase().endsWith('.avi');

    print("ApiService: Requesting ${isVideo ? 'Video' : 'Image'} -> $fullUrl");

    return fullUrl;
  }

  // Mock data completely disabled
  static const bool useMockData = false;
  //jamendo clientid
  static const String clientid = "8a108e0f";
}
