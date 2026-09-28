class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String imageUrl;
  final String audioUrl;
  final int duration;
  final String licenseUrl;
  final bool downloadAllowed;
  final String shareUrl;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    required this.licenseUrl,
    required this.downloadAllowed,
    required this.shareUrl,
  });

  // Backward compatibility getter for thumbnailUrl
  String get thumbnailUrl => imageUrl;

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final audio =
        json['audiodownload'] ??
        json['audio'] ??
        json['audioUrl'] ??
        json['url'] ??
        '';

    return SongModel(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? json['title'] ?? '',
      artist: json['artist_name'] ?? json['artist'] ?? '',
      album: json['album_name'] ?? json['album'] ?? '',
      imageUrl:
          json['image'] ?? json['album_image'] ?? json['thumbnailUrl'] ?? '',
      audioUrl: audio.toString(),
      duration: json['duration'] is int
          ? json['duration']
          : int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      licenseUrl: json['license_ccurl'] ?? '',
      downloadAllowed: json['audiodownload_allowed'] ?? false,
      shareUrl: json['shareurl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      'licenseUrl': licenseUrl,
      'downloadAllowed': downloadAllowed,
      'shareUrl': shareUrl,
    };
  }
}
