import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:ascoa_app/app/controllers/auth_controller.dart';
import 'package:ascoa_app/app/routes/app_routes.dart';
import 'package:ascoa_app/modules/auth/views/forgot_password_screen.dart';
import 'package:ascoa_app/shared/controllers/form_controllers.dart';
import 'package:ascoa_app/shared/controllers/validation_controller.dart';
import 'package:ascoa_app/shared/constants/app_strings.dart';
import 'package:ascoa_app/shared/widgets/floating_label_input_field.dart';
import 'package:ascoa_app/shared/widgets/primary_button.dart';

class _TestAssetBundle extends CachingAssetBundle {
  final ByteData imageBytes;
  _TestAssetBundle(this.imageBytes);

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData) parser,
  ) async {
    if (key == 'AssetManifest.bin') {
      final data =
          const StandardMessageCodec().encodeMessage(<String, Object?>{})!;
      return parser(data);
    }
    return super.loadStructuredBinaryData(key, parser);
  }

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final ByteData? data = const StandardMessageCodec().encodeMessage(
        <String, Object?>{},
      );
      return data ?? ByteData(0);
    }
    if (key == 'AssetManifest.json') {
      final bytes = utf8.encode('{}');
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    if (key == 'FontManifest.json') {
      final bytes = utf8.encode('[]');
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    if (key.toLowerCase().endsWith('.png')) {
      return imageBytes;
    }
    return ByteData(0);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    // Minimal manifests
    return '{}';
  }
}

/// Simple controllable AuthController avoiding Firebase and using isLoadingForgotPassword
class TestAuthController extends AuthController {
  String result = 'success';
  int calls = 0;
  Completer<String>? completer;

  @override
  // ignore: must_call_super
  void onInit() {
    // Do not bind to Firebase in tests
  }

  @override
  Future<String> forgotPassword(String email) async {
    calls++;
    isLoadingForgotPassword.value = true;
    if (completer != null) {
      final r = await completer!.future;
      isLoadingForgotPassword.value = false;
      return r;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    isLoadingForgotPassword.value = false;
    return result;
  }
}

Future<void> _pumpForgotScreen(
  WidgetTester tester, {
  Locale? locale,
  required TestAuthController auth,
  required FormControllers form,
  required ValidationController validation,
}) async {
  // 1x1 transparent PNG
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFvwJ/6W7r3wAAAABJRU5ErkJggg==',
  );
  final byteData = ByteData.view(Uint8List.fromList(bytes).buffer);

  Get.testMode = true;
  if (locale != null) Get.updateLocale(locale);

  // Inject controllers
  if (!Get.isRegistered<AuthController>()) Get.put<AuthController>(auth);
  if (!Get.isRegistered<FormControllers>()) Get.put<FormControllers>(form);
  if (!Get.isRegistered<ValidationController>()) {
    Get.put<ValidationController>(validation);
  }

  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _TestAssetBundle(byteData),
      child: GetMaterialApp(
        home: const ForgotPasswordScreen(),
        getPages: [
          GetPage(name: AppRoutes.login, page: () => const Placeholder()),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {});

  group('ForgotPasswordScreen', () {
    late TestAuthController auth;
    late FormControllers form;
    late ValidationController validation;

    setUp(() {
      auth = TestAuthController();
      form = FormControllers();
      validation = ValidationController();
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('renders title, email field and submit button', (tester) async {
      await _pumpForgotScreen(
        tester,
        auth: auth,
        form: form,
        validation: validation,
      );

      expect(find.text(AppStrings.forgotPasswordTitle), findsOneWidget);
      expect(find.byType(FloatingLabelInputField), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('init sanitizes invalid carried email', (tester) async {
      form.emailController.text = 'invalid-email';
      validation.emailError.value = 'Some error';

      await _pumpForgotScreen(
        tester,
        auth: auth,
        form: form,
        validation: validation,
      );

      expect(form.emailController.text, isEmpty);
      expect(validation.emailError.value, isNull);
    });

    testWidgets('validates email and shows helper error', (tester) async {
      await _pumpForgotScreen(
        tester,
        auth: auth,
        form: form,
        validation: validation,
      );

      // Enter invalid email
      await tester.enterText(find.byType(FloatingLabelInputField), 'invalid');
      await tester.pump();

      expect(validation.emailError.value, isNotNull);
      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Now correct it
      await tester.enterText(
        find.byType(FloatingLabelInputField),
        'valid@example.com',
      );
      await tester.pump();
      expect(validation.emailError.value, isNull);
    });

    testWidgets('does not call controller when email invalid', (tester) async {
      await _pumpForgotScreen(
        tester,
        auth: auth,
        form: form,
        validation: validation,
      );

      await tester.enterText(find.byType(FloatingLabelInputField), 'invalid');
      await tester.pump();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(auth.calls, 0);
    });

    testWidgets(
      'shows loading label then success dialog and navigates to login',
      (tester) async {
        // Delay completion to observe loading state
        auth.completer = Completer<String>();

        await _pumpForgotScreen(
          tester,
          auth: auth,
          form: form,
          validation: validation,
        );

        await tester.enterText(
          find.byType(FloatingLabelInputField),
          'valid@example.com',
        );
        await tester.pump();

        await tester.tap(find.byType(PrimaryButton));
        await tester.pump();

        // Loading label
        expect(find.text(AppStrings.sendingResetLink), findsOneWidget);

        // Complete with success
        auth.completer!.complete('success');
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text(AppStrings.forgotDialogTitle), findsOneWidget);

        // Tap dialog primary action -> navigates to login
        await tester.tap(find.text(AppStrings.forgotDialogButton));
        await tester.pumpAndSettle();

        expect(Get.currentRoute, AppRoutes.login);
      },
    );

    testWidgets('shows API error snackbars for known error codes', (
      tester,
    ) async {
      await _pumpForgotScreen(
        tester,
        auth: auth,
        form: form,
        validation: validation,
      );

      Future<void> submitWith(String result) async {
        auth.result = result;
        await tester.enterText(
          find.byType(FloatingLabelInputField),
          'user@example.com',
        );
        await tester.pump();
        await tester.tap(find.byType(PrimaryButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        // Allow snackbar animation to start
        await tester.pump(const Duration(milliseconds: 200));
      }

      await submitWith('user-not-found');
      expect(Get.isSnackbarOpen, isTrue);
      Get.closeAllSnackbars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await submitWith('invalid-email');
      expect(Get.isSnackbarOpen, isTrue);
      Get.closeAllSnackbars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await submitWith('too-many-requests');
      expect(Get.isSnackbarOpen, isTrue);
      Get.closeAllSnackbars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await submitWith('error');
      expect(Get.isSnackbarOpen, isTrue);
      Get.closeAllSnackbars();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      // Make sure any pending snackbar timers are drained
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('French locale surfaces translated title and dialog button', (
      tester,
    ) async {
      await _pumpForgotScreen(
        tester,
        locale: const Locale('fr'),
        auth: auth,
        form: form,
        validation: validation,
      );

      expect(find.text(AppStrings.forgotPasswordTitleFrench), findsOneWidget);

      // Trigger success to show dialog
      await tester.enterText(
        find.byType(FloatingLabelInputField),
        'valid@example.com',
      );
      await tester.pump();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.forgotDialogButtonFrench), findsOneWidget);
    });
  });
}
