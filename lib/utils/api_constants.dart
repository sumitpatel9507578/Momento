class ApiConstants {
  // Toggle this for Production vs Development
  static const bool isProduction = true;

  // Official Momento Backend (Production)
  static const String prodServerUrl = "https://momento-api-7-pycp.onrender.com";

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
  static String get reposts => "$baseUrl/reposts";

  // Media
  static String get stories => "$baseUrl/stories";
  static String get reels => "$baseUrl/reels";
  static String get songs => "$baseUrl/songs";

  // Messaging / Notifs
  static String get messages => "$baseUrl/messages";
  static String get savedItems => "$baseUrl/saved-items";
  static String get notifications => "$baseUrl/notifications";

  static String get health => "$serverUrl/health";

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty || path == "null") return "";

    if (path.startsWith("file://") ||
        path.startsWith("content://") ||
        (path.startsWith("/") && !path.startsWith("/api/"))) {
      return path;
    }

    String normalizedPath = path.replaceAll('\\', '/');

    // Handle legacy or dev local server URLs stored in DB
    if (normalizedPath.contains("localhost:") ||
        normalizedPath.contains("192.168.") ||
        normalizedPath.contains(":5000") ||
        (normalizedPath.startsWith("http://") &&
            !normalizedPath.contains("https://"))) {
      try {
        final uri = Uri.parse(normalizedPath);
        normalizedPath = uri.path;
      } catch (_) {}
    }

    // If it's already a full URL (like Gravatar or external HTTPS links)
    if (normalizedPath.startsWith("http")) return normalizedPath;

    // Ensure path starts with a single slash
    String cleanPath = normalizedPath.startsWith("/")
        ? normalizedPath
        : "/$normalizedPath";

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
  //jamendo clientId
  static const String clientId = "8a108e0f";
}
