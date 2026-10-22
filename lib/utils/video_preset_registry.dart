import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';

class VideoPresetItem {
  final String id;
  final String name;
  final String category;
  final GPUFilterConfiguration Function() createConfiguration;

  const VideoPresetItem({
    required this.id,
    required this.name,
    required this.category,
    required this.createConfiguration,
  });
}

class VideoPresetRegistry {
  static List<VideoPresetItem>? _cachedPresets;

  static List<VideoPresetItem> get presets {
    if (_cachedPresets != null) return _cachedPresets!;
    final list = <VideoPresetItem>[];

    for (int i = 1; i <= 30; i++) {
      final val = -0.9 + (i * 0.06);
      list.add(VideoPresetItem(
        id: 'brightness_$i',
        name: 'Brightness $i',
        category: 'Brightness',
        createConfiguration: () {
          final config = GPUBrightnessConfiguration();
          config.brightness = val;
          return config;
        },
      ));
    }

    for (int i = 1; i <= 30; i++) {
      final val = 0.5 + (i * 0.1);
      list.add(VideoPresetItem(
        id: 'contrast_$i',
        name: 'Contrast $i',
        category: 'Contrast',
        createConfiguration: () {
          final config = GPUContrastConfiguration();
          config.contrast = val;
          return config;
        },
      ));
    }

    for (int i = 1; i <= 30; i++) {
      final val = 0.1 + (i * 0.06);
      list.add(VideoPresetItem(
        id: 'saturation_$i',
        name: 'Saturation $i',
        category: 'Saturation',
        createConfiguration: () {
          final config = GPUSaturationConfiguration();
          config.saturation = val;
          return config;
        },
      ));
    }

    for (int i = 1; i <= 25; i++) {
      final val = i * 0.04;
      list.add(VideoPresetItem(
        id: 'sepia_$i',
        name: 'Sepia Vintage $i',
        category: 'Sepia',
        createConfiguration: () {
          final config = GPUSepiaToneConfiguration();
          config.intensity = val;
          return config;
        },
      ));
    }

    for (int i = 1; i <= 25; i++) {
      list.add(VideoPresetItem(
        id: 'hue_$i',
        name: 'Hue Shift $i',
        category: 'Hue',
        createConfiguration: () => GPUHueConfiguration(),
      ));
    }

    for (int i = 1; i <= 25; i++) {
      list.add(VideoPresetItem(
        id: 'vignette_$i',
        name: 'Vignette Cinematic $i',
        category: 'Vignette',
        createConfiguration: () => GPUVignetteConfiguration(),
      ));
    }

    for (int i = 1; i <= 20; i++) {
      list.add(VideoPresetItem(
        id: 'bulge_$i',
        name: 'Bulge Effect $i',
        category: 'Distortion',
        createConfiguration: () => GPUBulgeDistortionConfiguration(),
      ));
    }

    for (int i = 1; i <= 20; i++) {
      list.add(VideoPresetItem(
        id: 'swirl_$i',
        name: 'Swirl Vortex $i',
        category: 'Distortion',
        createConfiguration: () => GPUSwirlConfiguration(),
      ));
    }

    for (int i = 1; i <= 15; i++) {
      list.add(VideoPresetItem(
        id: 'sphere_$i',
        name: 'Sphere Refract $i',
        category: 'Distortion',
        createConfiguration: () => GPUSphereRefractionConfiguration(),
      ));
    }

    for (int i = 1; i <= 15; i++) {
      list.add(VideoPresetItem(
        id: 'sharpen_$i',
        name: 'Sharpen Edge $i',
        category: 'Sharpen',
        createConfiguration: () => GPUSharpenConfiguration(),
      ));
    }

    for (int i = 1; i <= 15; i++) {
      list.add(VideoPresetItem(
        id: 'rgb_$i',
        name: 'RGB Balance $i',
        category: 'Color',
        createConfiguration: () => GPURGBConfiguration(),
      ));
    }

    while (list.length < 250) {
      final idx = list.length + 1;
      list.add(VideoPresetItem(
        id: 'extra_effect_$idx',
        name: 'Pro Filter $idx',
        category: 'Special',
        createConfiguration: () => idx % 2 == 0 ? GPUGrayScaleConfiguration() : GPUInvertConfiguration(),
      ));
    }

    _cachedPresets = list;
    return _cachedPresets!;
  }
}
