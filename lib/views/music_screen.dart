import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/music_controller.dart';
import '../models/song_model.dart';
import '../routes/app_routes.dart';

class MusicScreen extends StatelessWidget {
  final bool isSelectionMode;
  final Function(SongModel)? onSongSelected;
  final MusicController _musicController = Get.put(MusicController());

  MusicScreen({super.key, this.isSelectionMode = false, this.onSongSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Custom gradient background inspired by Spotify/Apple Music
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withAlpha(240),
            theme.colorScheme.surface.withAlpha(220),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildSearchBar(context),
              _buildFilterChips(context),
              Expanded(
                child: Obx(() {
                  if (_musicController.isLoading.value) {
                    return _buildLoadingState(context);
                  }

                  if (_musicController.errorMessage.value.isNotEmpty) {
                    return _buildErrorState(context);
                  }

                  if (_musicController.isSearching.value) {
                    return _buildSearchResults(context);
                  }

                  return _buildTrendingSection(context);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 24,
                ),
              if (isSelectionMode) const SizedBox(width: 16),
              Text(
                isSelectionMode ? 'Add Music' : 'Music',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {}, // Profile/Settings
              tooltip: 'Your Library',
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha(150),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => _musicController.searchQuery.value = value,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search songs, artists, albums...',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha(150),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            suffixIcon: Obx(
              () => _musicController.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _musicController.searchQuery.value = '';
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 38,
        child: Obx(() {
          final currentLang = _musicController.selectedLanguage.value;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: MusicController.availableLanguages.length,
            itemBuilder: (context, index) {
              final lang = MusicController.availableLanguages[index];
              final isSelected =
                  currentLang.toLowerCase() == lang.toLowerCase();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    debugPrint('Language filter tapped: $lang');
                    _musicController.changeLanguage(lang);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Theme.of(context).dividerColor.withAlpha(50),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            lang,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Discovering music...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Oops!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _musicController.errorMessage.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _musicController.loadTrendingSongs(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(BuildContext context) {
    final trending = _musicController.trendingSongs;
    final carouselSongs = trending.take(5).toList();
    final listSongs = trending.length > 5
        ? trending.skip(5).toList()
        : <SongModel>[];

    return CustomScrollView(
      slivers: [
        if (carouselSongs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Text(
                'Trending Now',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: carouselSongs.length,
                itemBuilder: (context, index) {
                  return _buildCarouselCard(context, carouselSongs[index]);
                },
              ),
            ),
          ),
        ],

        if (listSongs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Top Tracks',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildSongTile(context, listSongs[index], index + 6),
              childCount: listSongs.length,
            ),
          ),
        ],

        if (trending.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No trending songs available',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),

        // Bottom padding for mini player in MainScreen
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final searchResults = _musicController.songs;

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or language',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for mini player
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return _buildSongTile(context, searchResults[index], index + 1);
      },
    );
  }

  Widget _buildCarouselCard(BuildContext context, SongModel song) {
    return GestureDetector(
      onTap: () => _handleSongTap(
        song,
        context,
        true,
        _musicController.trendingSongs.indexOf(song),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      song.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.music_note, size: 40),
                      ),
                    ),
                    Obx(() {
                      final isPlaying =
                          _musicController.playingSongIdVal == song.id &&
                          _musicController.isPlaying.value;
                      if (!isPlaying) return const SizedBox.shrink();
                      return Container(
                        color: Colors.black.withAlpha(100),
                        child: const Center(
                          child: Icon(
                            Icons.pause,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _effectiveSelectionMode {
    if (isSelectionMode) return true;
    final args = Get.arguments;
    if (args is Map && args['isSelectionMode'] == true) return true;
    if (args == true ||
        Get.currentRoute == AppRoutes.musicPicker ||
        Get.currentRoute == '/music' ||
        Get.currentRoute == '/music-picker') {
      return true;
    }
    return true; // Default to selection mode enabled when opened
  }

  Widget _buildSongTile(BuildContext context, SongModel song, int index) {
    return Obx(() {
      final playingId = _musicController.playingSongIdVal;
      final playing = _musicController.isPlaying.value;
      final isPlaying = playingId == song.id && playing;
      final isCurrent = playingId == song.id;

      return InkWell(
        onTap: () => _handleSongTap(song, context, false, index - 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Center(
                  child: isPlaying
                      ? Icon(
                          Icons.bar_chart,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        )
                      : Text(
                          index.toString(),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withAlpha(150),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: song.imageUrl.isNotEmpty
                      ? Image.network(
                          song.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.music_note),
                          ),
                        )
                      : Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.music_note),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_effectiveSelectionMode)
                ElevatedButton(
                  onPressed: () =>
                      _handleSongTap(song, context, false, index - 1),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Select'),
                )
              else
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
        ),
      );
    });
  }

  void _handleSongTap(
    SongModel song,
    BuildContext context,
    bool isTrending,
    int index,
  ) {
    if (_effectiveSelectionMode) {
      _musicController.selectSongForMedia(song);
      if (onSongSelected != null) {
        onSongSelected!(song);
      }
      Get.back(result: song);
    } else {
      final queueList = isTrending
          ? _musicController.trendingSongs
          : _musicController.songs;
      _musicController.playSong(song, newQueue: queueList, index: index);
    }
  }
}
