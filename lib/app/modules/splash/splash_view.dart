import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/veha_logo_draw.dart';
import 'splash_controller.dart';

/// First screen on every launch — the Veha logo draws itself on a clean
/// background, then [SplashController] routes onward.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // White matches the native splash for a seamless handoff.
    final background = isDark ? theme.colorScheme.surface : Colors.white;

    return Scaffold(
      backgroundColor: background,
      body: const Center(
        child: VehaLogoDraw(
          height: 132,
          duration: Duration(milliseconds: 1500),
        ),
      ),
    );
  }
}
