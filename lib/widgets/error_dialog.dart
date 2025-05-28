import 'package:flutter/material.dart';

class ErrorDialog {
  static void showGenericError(
    BuildContext context, {
    String? message,
    String? title,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Error'),
          content: Text(message ?? 'An unexpected error occurred. Please try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showCustomError(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Network Error'),
          content: const Text('Please check your internet connection and try again.'),
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel();
                },
                child: const Text('Cancel'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry?.call();
              },
              child: Text(onRetry != null ? 'Retry' : 'OK'),
            ),
          ],
        );
      },
    );
  }
}