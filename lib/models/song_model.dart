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
  final String language;
  final bool isLiked;

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
    this.language = '',
    this.isLiked = false,
  });

  // Backward compatibility getter for thumbnailUrl
  String get thumbnailUrl => imageUrl;

  factory SongModel.fromJson(Map<String, dynamic> json) {
    // 1. Audio URL Parsing
    String audioUrl = '';
    if (json['downloadUrl'] is List &&
        (json['downloadUrl'] as List).isNotEmpty) {
      final list = json['downloadUrl'] as List;
      final highest = list.firstWhere(
        (item) => item is Map && item['quality'] == '320kbps',
        orElse: () => list.firstWhere(
          (item) => item is Map && item['quality'] == '160kbps',
          orElse: () => list.first,
        ),
      );
      if (highest is Map) {
        audioUrl = (highest['url'] ?? highest['link'] ?? '').toString();
      } else {
        audioUrl = highest.toString();
      }
    } else if (json['url'] is List && (json['url'] as List).isNotEmpty) {
      audioUrl = (json['url'] as List).last.toString();
    } else {
      audioUrl =
          (json['audiodownload'] ??
                  json['audio'] ??
                  json['audioUrl'] ??
                  json['download_url'] ??
                  json['url'] ??
                  '')
              .toString();
    }

    // 2. Image URL Parsing
    String imageUrl = '';
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      final list = json['image'] as List;
      final highest = list.firstWhere(
        (item) =>
            item is Map &&
            (item['quality'] == '500x500' || item['quality'] == '500x500_jpg'),
        orElse: () => list.last,
      );
      if (highest is Map) {
        imageUrl = (highest['url'] ?? highest['link'] ?? '').toString();
      } else {
        imageUrl = highest.toString();
      }
    } else {
      imageUrl =
          (json['image'] ??
                  json['album_image'] ??
                  json['thumbnailUrl'] ??
                  json['artwork'] ??
                  '')
              .toString();
    }

    // 3. Artist Parsing
    String artist = '';
    if (json['artists'] is Map) {
      final primary = json['artists']['primary'];
      if (primary is List) {
        artist = primary.map((a) => a['name'] ?? a.toString()).join(', ');
      }
    } else if (json['primaryArtists'] != null) {
      artist = json['primaryArtists'].toString();
    } else if (json['artist'] is Map) {
      artist = (json['artist']['name'] ?? json['artist']['title'] ?? '')
          .toString();
    } else {
      artist =
          (json['artist_name'] ??
                  json['artist'] ??
                  json['singers'] ??
                  json['primary_artists'] ??
                  'Unknown Artist')
              .toString();
    }

    // 4. Album Parsing
    String album = '';
    if (json['album'] is Map) {
      album = (json['album']['name'] ?? json['album']['title'] ?? '')
          .toString();
    } else {
      album = (json['album_name'] ?? json['album'] ?? '').toString();
    }

    return SongModel(
      id: (json['id'] ?? json['song_id'] ?? json['_id'] ?? '').toString(),
      title: (json['name'] ?? json['title'] ?? json['song'] ?? 'Untitled Track')
          .toString(),
      artist: artist.isNotEmpty ? artist : 'Unknown Artist',
      album: album.isNotEmpty ? album : 'Single',
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      duration: json['duration'] is int
          ? json['duration']
          : int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      licenseUrl: (json['license_ccurl'] ?? json['license'] ?? '').toString(),
      downloadAllowed:
          json['audiodownload_allowed'] == true || json['hasDownload'] == true,
      shareUrl: (json['shareurl'] ?? json['perma_url'] ?? '').toString(),
      language: (json['language'] ?? json['lang'] ?? '').toString(),
      isLiked: json['isLiked'] == true || json['is_liked'] == true,
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
      'language': language,
      'isLiked': isLiked,
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? imageUrl,
    String? audioUrl,
    int? duration,
    String? licenseUrl,
    bool? downloadAllowed,
    String? shareUrl,
    String? language,
    bool? isLiked,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      downloadAllowed: downloadAllowed ?? this.downloadAllowed,
      shareUrl: shareUrl ?? this.shareUrl,
      language: language ?? this.language,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
