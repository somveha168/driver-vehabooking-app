import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Thin wrapper over GetX snackbars with success/error styling.
class AppSnackbar {
  const AppSnackbar._();

  static void success(String message) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      message,
      titleText: const SizedBox.shrink(),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  static void info(String message) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      message,
      titleText: const SizedBox.shrink(),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      backgroundColor: const Color(0xFF0A1F4D),
      colorText: Colors.white,
      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  static void error(String message) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      message,
      titleText: const SizedBox.shrink(),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      backgroundColor: const Color(0xFFDC2626),
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}
