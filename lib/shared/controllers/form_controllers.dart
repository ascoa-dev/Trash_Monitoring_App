import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FormControllers extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final cityController = TextEditingController();

  void resetAuthFields() {
    emailController.clear();
    passwordController.clear();
  }

  void resetProfileFields() {
    firstNameController.clear();
    lastNameController.clear();
    phoneNumberController.clear();
    cityController.clear();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    cityController.dispose();
    super.onClose();
  }
}
