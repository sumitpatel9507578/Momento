import 'dart:io';
import 'package:flutter/material.dart';
import 'deep_ar_controller.dart';

/// Displays live preview with desired effects.
class DeepArPreview extends StatelessWidget {
  DeepArPreview(this.deepArController, {Key? key, this.onViewCreated})
      : super(key: key);
  final DeepArController deepArController;
  final Function? onViewCreated;
  final ValueNotifier<int> _reloadNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: (1 / deepArController.aspectRatio),
        child: ValueListenableBuilder<int>(
          valueListenable: _reloadNotifier,
          builder: (context, _, __) {
            return Platform.isAndroid ? _androidView() : _iOSView();
          },
        ),
      ),
    );
  }

  Widget _iOSView() {
    return deepArController.buildPreview(oniOSViewCreated: () {
      onViewCreated?.call();
      _reloadNotifier.value++;
    });
  }

  Widget _androidView() {
    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => onViewCreated?.call());
    return deepArController.isInitialized
        ? deepArController.buildPreview()
        : const SizedBox.shrink();
  }
}
