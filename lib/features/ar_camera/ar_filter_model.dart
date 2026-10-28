import 'package:flutter/material.dart';

enum ArFilterCategory { funny, romantic, serious }

enum ArFilterType { effect, mask, filter }

extension ArFilterCategoryX on ArFilterCategory {
  String get displayName {
    switch (this) {
      case ArFilterCategory.funny:
        return 'Funny';
      case ArFilterCategory.romantic:
        return 'Romantic';
      case ArFilterCategory.serious:
        return 'Serious';
    }
  }
}

class ArFilterModel {
  final String id;
  final String name;
  final ArFilterCategory category;
  final ArFilterType filterType;
  final String assetPath;
  final IconData iconData;

  const ArFilterModel({
    required this.id,
    required this.name,
    required this.category,
    required this.filterType,
    required this.assetPath,
    this.iconData = Icons.face_retouching_natural_rounded,
  });

  static const List<ArFilterModel> allFilters = [
    // --- FUNNY CATEGORY ---
    ArFilterModel(
      id: 'devil_horns',
      name: 'Neon Horns',
      category: ArFilterCategory.funny,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Devil Neon Horns/Neon_Devil_Horns.deepar',
      iconData: Icons.sentiment_very_satisfied_rounded,
    ),
    ArFilterModel(
      id: 'elephant_trunk',
      name: 'Elephant',
      category: ArFilterCategory.funny,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Elephant Trunk/Elephant_Trunk.deepar',
      iconData: Icons.pets_rounded,
    ),
    ArFilterModel(
      id: 'emotion_meter',
      name: 'Emotion Meter',
      category: ArFilterCategory.funny,
      filterType: ArFilterType.filter,
      assetPath: 'assets/filters/Emotion Meter/Emotion_Meter.deepar',
      iconData: Icons.speed_rounded,
    ),
    ArFilterModel(
      id: 'emotions_exaggerator',
      name: 'Exaggerator',
      category: ArFilterCategory.funny,
      filterType: ArFilterType.mask,
      assetPath:
          'assets/filters/Emotions Exaggerator/Emotions_Exaggerator.deepar',
      iconData: Icons.add_reaction_rounded,
    ),
    ArFilterModel(
      id: 'humanoid',
      name: 'Humanoid',
      category: ArFilterCategory.funny,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Humanoid/Humanoid.deepar',
      iconData: Icons.smart_toy_rounded,
    ),
    ArFilterModel(
      id: 'ping_pong',
      name: 'Ping Pong',
      category: ArFilterCategory.funny,
      filterType: ArFilterType.effect,
      assetPath: 'assets/filters/Ping Pong Minigame/Ping_Pong.deepar',
      iconData: Icons.sports_tennis_rounded,
    ),
    ArFilterModel(
      id: 'snail',
      name: 'Snail Face',
      category: ArFilterCategory.funny,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Snail/Snail.deepar',
      iconData: Icons.bug_report_rounded,
    ),

    // --- ROMANTIC CATEGORY ---
    ArFilterModel(
      id: 'flower_face',
      name: 'Flower Crown',
      category: ArFilterCategory.romantic,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Flower Face/flower_face.deepar',
      iconData: Icons.local_florist_rounded,
    ),
    ArFilterModel(
      id: 'galaxy_bg',
      name: 'Galaxy',
      category: ArFilterCategory.romantic,
      filterType: ArFilterType.effect,
      assetPath: 'assets/filters/Galaxy Background/galaxy_background.deepar',
      iconData: Icons.auto_awesome_rounded,
    ),
    ArFilterModel(
      id: 'hope',
      name: 'Hope Glow',
      category: ArFilterCategory.romantic,
      filterType: ArFilterType.effect,
      assetPath: 'assets/filters/Hope/Hope.deepar',
      iconData: Icons.wb_sunny_rounded,
    ),
    ArFilterModel(
      id: 'makeup_simple',
      name: 'Soft Makeup',
      category: ArFilterCategory.romantic,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Makeup Look Simple/MakeupLook.deepar',
      iconData: Icons.face_retouching_natural_rounded,
    ),
    ArFilterModel(
      id: 'split_view_makeup',
      name: 'Split Glam',
      category: ArFilterCategory.romantic,
      filterType: ArFilterType.filter,
      assetPath:
          'assets/filters/Makeup Look w_ Slipt Screen Effect/Split_View_Look.deepar',
      iconData: Icons.splitscreen_rounded,
    ),
    ArFilterModel(
      id: 'pixel_hearts',
      name: '8-Bit Hearts',
      category: ArFilterCategory.romantic,
      filterType: ArFilterType.effect,
      assetPath: 'assets/filters/Pixel Heart Particles/8bitHearts.deepar',
      iconData: Icons.favorite_rounded,
    ),

    // --- SERIOUS CATEGORY ---
    ArFilterModel(
      id: 'burning_effect',
      name: 'Burning Fire',
      category: ArFilterCategory.serious,
      filterType: ArFilterType.effect,
      assetPath: 'assets/filters/Burning Effect/burning_effect.deepar',
      iconData: Icons.local_fire_department_rounded,
    ),
    ArFilterModel(
      id: 'fire_effect',
      name: 'Inferno',
      category: ArFilterCategory.serious,
      filterType: ArFilterType.effect,
      assetPath: 'assets/filters/Fire Effect/Fire_Effect.deepar',
      iconData: Icons.whatshot_rounded,
    ),
    ArFilterModel(
      id: 'stallone',
      name: 'Stallone',
      category: ArFilterCategory.serious,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Stallone/Stallone.deepar',
      iconData: Icons.fitness_center_rounded,
    ),
    ArFilterModel(
      id: 'vendetta_mask',
      name: 'Vendetta',
      category: ArFilterCategory.serious,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Vendetta Mask/Vendetta_Mask.deepar',
      iconData: Icons.masks_rounded,
    ),
    ArFilterModel(
      id: 'viking_helmet',
      name: 'Viking',
      category: ArFilterCategory.serious,
      filterType: ArFilterType.mask,
      assetPath: 'assets/filters/Viking Helmet PBR/viking_helmet.deepar',
      iconData: Icons.shield_rounded,
    ),
  ];

  static List<ArFilterModel> getByCategory(ArFilterCategory cat) {
    return allFilters.where((f) => f.category == cat).toList();
  }
}
