import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<bool> generateAndSharePdf({
    required String base64String,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      if (base64String.isEmpty || !isValidPdfBase64(base64String)) {
        return false;
      }

      final bytes = base64Decode(base64String);
      Directory directory;

      if (Platform.isAndroid) {
        if (await Permission.storage.request().isGranted || 
            await Permission.manageExternalStorage.request().isGranted) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSuccessDialog(context, fileName, directory.path);

      final fileToShare = XFile(filePath);
      await Share.shareXFiles(
        [fileToShare],
        subject: fileName,
        text: 'Sharing PDF file',
      );

      return true;
    } catch (e) {
      debugPrint('PDF generation or sharing error: $e');
      _showErrorDialog(context, 'Error', 'Could not generate or share the PDF: ${e.toString()}');
      return false;
    }
  }

  static Future<bool> saveToDownloads({
    required String base64String,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      if (base64String.isEmpty || !isValidPdfBase64(base64String)) {
        return false;
      }

      final bytes = base64Decode(base64String);
      Directory directory;

      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        final manageStoragePermission = await Permission.manageExternalStorage.request();

        if (storagePermission.isGranted || manageStoragePermission.isGranted) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = Directory('/storage/emulated/0/Downloads');
          }
          if (!await directory.exists()) {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          _showErrorDialog(
            context,
            'Permission Required',
            'Storage permission is required to save PDF files. Please grant permission in settings.',
          );
          return false;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSuccessDialog(context, fileName, directory.path);
      return true;
    } catch (e) {
      debugPrint('PDF save error: $e');
      _showErrorDialog(context, 'Error', 'Could not save the PDF: ${e.toString()}');
      return false;
    }
  }

  static bool isValidPdfBase64(String base64String) {
    try {
      if (base64String.isEmpty) return false;
      final bytes = base64Decode(base64String);
      if (bytes.length > 4) {
        final header = String.fromCharCodes(bytes.take(4));
        return header == '%PDF';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static void _showSuccessDialog(BuildContext context, String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 8),
              const Text('PDF Generated Successfully'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your document has been saved:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'File Name:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Location:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      filePath,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _openFile('$filePath/$fileName');
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F2D),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openFile(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      final Uri fileUri = Uri.file(filePath);
      final File file = File(filePath);

      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return;
      }

      if (await canLaunchUrl(fileUri)) {
        final result = await launchUrl(
          fileUri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('Launch result: $result');
      } else {
        debugPrint('Could not launch file: $filePath');
        try {
          if (Platform.isAndroid) {
            final Uri contentUri = Uri.parse(
              'content://com.android.externalstorage.documents/document/primary:Download/${file.uri.pathSegments.last}'
            );
            if (await canLaunchUrl(contentUri)) {
              await launchUrl(contentUri, mode: LaunchMode.externalApplication);
            }
          }
        } catch (fallbackError) {
          debugPrint('Fallback file opening method failed: $fallbackError');
        }
      }
    } catch (e) {
      debugPrint('Could not open file: $e');
    }
  }

  static String generateUniqueFileName(String type, String customerName, String customerNo) {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd').format(now);
    final time = DateFormat('HHmmss').format(now);
    final safeCustomerName = customerName.replaceAll(' ', '_');
    
    return '${type.capitalize()}_${safeCustomerName}_${customerNo}_${date}_${time}.pdf';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
