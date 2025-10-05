import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileController extends GetxController {
  late final AuthController _authController;
  late final FormControllers _formControllers;
  late final ValidationController _validationController;
  late final Rx<Country> _selectedCountry;

  final RxBool isLoading = false.obs;
  final RxnString email = RxnString();

  Country _defaultCountry() {
    return CountryParser.parseCountryCode('CM');
  }

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    _formControllers = Get.find<FormControllers>();
    _validationController = Get.find<ValidationController>();
    _selectedCountry = Rx<Country>(_defaultCountry());
    _validationController.clearProfileValidation();
    _loadProfile();
  }

  FormControllers get formControllers => _formControllers;
  ValidationController get validationController => _validationController;
  AuthController get authController => _authController;
  Country get selectedCountry => _selectedCountry.value;

  void updateSelectedCountry(Country country) {
    _selectedCountry.value = country;
    _validationController.validatePhoneNumber(
      '+${country.phoneCode}',
      _formControllers.phoneNumberController.text.trim(),
    );
  }

  Future<void> _loadProfile() async {
    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final profileData = await _authController.fetchCurrentUserProfile();
      final userModel = _authController.currentUserModel.value;

      email.value =
          user?.email ?? profileData?['email'] as String? ?? userModel?.email;

      _formControllers.firstNameController.text =
          userModel?.firstName ??
          profileData?['firstName']?.toString().trim() ??
          '';
      _formControllers.lastNameController.text =
          userModel?.lastName ??
          profileData?['lastName']?.toString().trim() ??
          '';
      final countryCodeStored = profileData?['countryCode']?.toString();
      Country? storedCountry;
      if (countryCodeStored != null && countryCodeStored.trim().isNotEmpty) {
        storedCountry = CountryParser.tryParseCountryCode(
          countryCodeStored.trim(),
        );
      }

      final phoneRaw =
          userModel?.phoneNumber ??
          profileData?['phoneNumber']?.toString().trim() ??
          '';
      if (phoneRaw.isNotEmpty) {
        final parsed = _parsePhoneNumber(phoneRaw, storedCountry);
        _selectedCountry.value = storedCountry ?? parsed.country;
        _formControllers.phoneNumberController.text = parsed.nationalNumber;
      } else {
        _selectedCountry.value = storedCountry ?? _defaultCountry();
        _formControllers.phoneNumberController.clear();
      }
      _formControllers.cityController.text =
          userModel?.city ?? profileData?['city']?.toString().trim() ?? '';
    } catch (e) {
      debugPrint('EditProfileController load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  _ParsedPhoneNumber _parsePhoneNumber(String raw, Country? hintCountry) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return _ParsedPhoneNumber(
        country: hintCountry ?? _defaultCountry(),
        nationalNumber: '',
      );
    }

    if (hintCountry != null) {
      final stripped = _stripDialCode(trimmed, hintCountry.phoneCode);
      if (stripped != trimmed) {
        return _ParsedPhoneNumber(
          country: hintCountry,
          nationalNumber: stripped.trim(),
        );
      }
    }

    var digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digitsOnly.startsWith('+')) {
      digitsOnly = digitsOnly.substring(1);
    }
    if (digitsOnly.startsWith('00')) {
      digitsOnly = digitsOnly.substring(2);
    }

    Country? detectedCountry;
    int dialLength = 0;
    final maxCandidateLength = digitsOnly.length > 4 ? 4 : digitsOnly.length;
    for (var len = maxCandidateLength; len >= 1; len--) {
      final candidate = digitsOnly.substring(0, len);
      final country = CountryParser.tryParsePhoneCode(candidate);
      if (country != null) {
        detectedCountry = country;
        dialLength = len;
        break;
      }
    }

    String strippedNational = trimmed;
    if (dialLength > 0) {
      final dialDigits = digitsOnly.substring(0, dialLength);
      strippedNational = _stripDialCode(trimmed, dialDigits);
    }

    if (strippedNational.trim().isEmpty && dialLength > 0) {
      strippedNational = digitsOnly.substring(dialLength);
    }

    if (strippedNational == trimmed && dialLength > 0) {
      strippedNational = digitsOnly.substring(dialLength);
    }

    final nationalNumber =
        strippedNational.trim().isNotEmpty ? strippedNational.trim() : trimmed;

    return _ParsedPhoneNumber(
      country: detectedCountry ?? hintCountry ?? _defaultCountry(),
      nationalNumber: nationalNumber,
    );
  }

  String _stripDialCode(String raw, String dialCode) {
    if (dialCode.isEmpty) {
      return raw;
    }

    final pattern = RegExp(
      '^\\s*(?:\\+|00)?\\s*(?:\\(\\s*)?${RegExp.escape(dialCode)}(?:\\s*\\))?[\\s.-]*',
    );
    final stripped = raw.replaceFirst(pattern, '');
    return stripped.trimLeft();
  }

  Future<bool> submitChanges() async {
    final firstName = _formControllers.firstNameController.text.trim();
    final lastName = _formControllers.lastNameController.text.trim();
    final phone = _formControllers.phoneNumberController.text.trim();
    final city = _formControllers.cityController.text.trim();

    _validationController.validateFirstName(firstName);
    _validationController.validateLastName(lastName);
    _validationController.validatePhoneNumber(
      '+${_selectedCountry.value.phoneCode}',
      phone,
    );
    _validationController.validateCity(city);

    if (!_validationController.isProfileFormValid) {
      return false;
    }

    final updatedModel = await _authController.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: '+${_selectedCountry.value.phoneCode} $phone',
      countryCode: _selectedCountry.value.countryCode,
      city: city,
    );

    return updatedModel != null;
  }
}

class _ParsedPhoneNumber {
  final Country country;
  final String nationalNumber;

  _ParsedPhoneNumber({required this.country, required this.nationalNumber});
}
