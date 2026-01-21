import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ascoa_app/shared/services/snackbar_service.dart';

/// Mixin that provides snackbar listening capability for GetX widgets.
///
/// Use this mixin on GetView or StatefulWidget controllers to automatically
/// listen for snackbar messages and display them when the Overlay is available.
///
/// Example usage with GetView:
/// ```dart
/// class LoginPage extends GetView<AuthController> with SnackbarListenerMixin {
///   @override
///   Rxn<SnackbarMessage>? get snackbarMessage => controller.snackbarMessage;
///
///   @override
///   Widget build(BuildContext context) {
///     listenForSnackbars(); // Call this early in build
///     return Scaffold(...);
///   }
/// }
/// ```
mixin SnackbarListenerMixin {
  /// Override this to provide the reactive snackbar message to listen to
  Rxn<SnackbarMessage>? get snackbarMessage;

  /// Internal worker reference to prevent duplicate subscriptions
  Worker? _snackbarWorker;

  /// Call this method once when the widget is ready (e.g., in build or initState)
  /// to start listening for snackbar messages.
  void listenForSnackbars() {
    final message = snackbarMessage;
    if (message == null) return;

    // Prevent duplicate subscriptions
    if (_snackbarWorker != null) return;

    _snackbarWorker = ever<SnackbarMessage?>(message, (msg) {
      if (msg != null) {
        SnackbarService.show(msg);
        message.value = null; // Clear after showing
      }
    });
  }

  /// Call this when disposing to clean up the worker
  void disposeSnackbarListener() {
    _snackbarWorker?.dispose();
    _snackbarWorker = null;
  }
}

/// A widget wrapper that listens for snackbar messages from AuthController
/// and displays them. Use this as a parent widget in screens that need
/// to show auth-related snackbars.
///
/// Example:
/// ```dart
/// AuthSnackbarListener(
///   child: Scaffold(...),
/// )
/// ```
class AuthSnackbarListener extends StatefulWidget {
  final Widget child;

  const AuthSnackbarListener({super.key, required this.child});

  @override
  State<AuthSnackbarListener> createState() => _AuthSnackbarListenerState();
}

class _AuthSnackbarListenerState extends State<AuthSnackbarListener> {
  Worker? _snackbarWorker;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure Overlay is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListener();
    });
  }

  void _setupListener() {
    // Dynamically check if AuthController is registered
    if (!Get.isRegistered<dynamic>(tag: 'AuthController')) {
      // Try to get the controller without tag
      try {
        final controller = Get.find<dynamic>();
        if (controller != null &&
            controller.runtimeType.toString() == 'AuthController') {
          _listenToController(controller);
        }
      } catch (_) {
        // Controller not available yet, that's okay
      }
    }
  }

  void _listenToController(dynamic controller) {
    // Access snackbarMessage if it exists
    try {
      final snackbarMessage =
          controller.snackbarMessage as Rxn<SnackbarMessage>?;
      if (snackbarMessage != null) {
        _snackbarWorker = ever<SnackbarMessage?>(snackbarMessage, (msg) {
          if (msg != null) {
            SnackbarService.show(msg);
            snackbarMessage.value = null;
          }
        });
      }
    } catch (_) {
      // snackbarMessage property doesn't exist
    }
  }

  @override
  void dispose() {
    _snackbarWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A simple wrapper widget that sets up snackbar listening for any
/// [Rxn] of [SnackbarMessage] observable. This is the recommended approach.
///
/// Example:
/// ```dart
/// SnackbarListener(
///   snackbarMessage: authController.snackbarMessage,
///   child: Scaffold(...),
/// )
/// ```
class SnackbarListener extends StatefulWidget {
  final Widget child;
  final Rxn<SnackbarMessage> snackbarMessage;

  const SnackbarListener({
    super.key,
    required this.child,
    required this.snackbarMessage,
  });

  @override
  State<SnackbarListener> createState() => _SnackbarListenerState();
}

class _SnackbarListenerState extends State<SnackbarListener> {
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure Overlay is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _worker = ever<SnackbarMessage?>(widget.snackbarMessage, (msg) {
        if (msg != null) {
          SnackbarService.show(msg);
          widget.snackbarMessage.value = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
