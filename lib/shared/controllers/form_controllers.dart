import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FormControllers extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
