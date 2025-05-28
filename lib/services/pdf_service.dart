import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
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
  static Future<String?> saveToDownloads({
    required String base64String,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      if (base64String.isEmpty || !isValidPdfBase64(base64String)) {
        return null;
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
          return null;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSuccessDialogWithOpen(context, fileName, directory.path, filePath);
      return filePath;
    } catch (e) {
      debugPrint('PDF save error: $e');
      _showErrorDialog(context, 'Error', 'Could not save the PDF: ${e.toString()}');
      return null;
    }
  }

  // Get the Downloads directory path
  static Future<String?> getDownloadsDirectoryPath() async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        final manageStoragePermission = await Permission.manageExternalStorage.request();

        if (storagePermission.isGranted || manageStoragePermission.isGranted) {
          Directory directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = Directory('/storage/emulated/0/Downloads');
          }
          if (await directory.exists()) {
            return directory.path;
          }
        }
        // Fallback to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        return appDir.path;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        return appDir.path;
      }
    } catch (e) {
      debugPrint('Error getting downloads directory: $e');
      return null;
    }
  }

  // Save PDF and optionally open it immediately
  static Future<String?> savePdfAndOpen({
    required String base64String,
    required String fileName,
    required BuildContext context,
    bool openAfterSave = false,
  }) async {
    try {
      final savedPath = await saveToDownloads(
        base64String: base64String,
        fileName: fileName,
        context: context,
      );

      if (savedPath != null && openAfterSave) {
        // Small delay to ensure file is fully written
        await Future.delayed(const Duration(milliseconds: 500));
        await openFile(savedPath);
      }

      return savedPath;
    } catch (e) {
      debugPrint('Error in savePdfAndOpen: $e');
      return null;
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
  static void _showSuccessDialogWithOpen(BuildContext context, String fileName, String filePath, String fullPath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 8),
              const Text('PDF Saved Successfully'),
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
            ),            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await openFileWithFeedback(
                  filePath: fullPath,
                  context: context,
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
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
            ),            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await openFile('$filePath/$fileName');
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
  }  // Public method to open a file
  static Future<bool> openFile(String filePath) async {
    try {
      final File file = File(filePath);

      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return false;
      }

      // Use open_filex to open the file
      final result = await OpenFilex.open(filePath);
      
      debugPrint('OpenFilex result: ${result.type}');
      debugPrint('OpenFilex message: ${result.message}');

      // Check if the operation was successful
      if (result.type == ResultType.done) {
        debugPrint('File opened successfully');
        return true;
      } else if (result.type == ResultType.fileNotFound) {
        debugPrint('File not found: $filePath');
        return false;
      } else if (result.type == ResultType.noAppToOpen) {
        debugPrint('No app available to open this file type');
        return false;
      } else if (result.type == ResultType.permissionDenied) {
        debugPrint('Permission denied to open file');
        // Request permissions if needed
        if (Platform.isAndroid) {
          await Permission.storage.request();
          await Permission.manageExternalStorage.request();
        }
        return false;
      } else if (result.type == ResultType.error) {
        debugPrint('Error opening file: ${result.message}');
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Could not open file: $e');
      return false;
    }
  }

  // Enhanced method to open file with user-friendly error messages
  static Future<bool> openFileWithFeedback({
    required String filePath,
    required BuildContext context,
  }) async {
    try {
      final File file = File(filePath);

      if (!await file.exists()) {
        _showErrorDialog(
          context,
          'File Not Found',
          'The requested file could not be found. It may have been moved or deleted.',
        );
        return false;
      }

      // Use open_filex to open the file
      final result = await OpenFilex.open(filePath);
      
      debugPrint('OpenFilex result: ${result.type}');
      debugPrint('OpenFilex message: ${result.message}');

      // Check if the operation was successful
      if (result.type == ResultType.done) {
        debugPrint('File opened successfully');
        return true;
      } else if (result.type == ResultType.fileNotFound) {
        _showErrorDialog(
          context,
          'File Not Found',
          'The file could not be found on your device.',
        );
        return false;
      } else if (result.type == ResultType.noAppToOpen) {
        _showErrorDialog(
          context,
          'No PDF Reader Found',
          'No application is available to open PDF files. Please install a PDF reader from the Play Store.',
        );
        return false;
      } else if (result.type == ResultType.permissionDenied) {
        _showErrorDialog(
          context,
          'Permission Required',
          'Permission is required to open files. Please grant storage permission in app settings.',
        );
        // Request permissions if needed
        if (Platform.isAndroid) {
          await Permission.storage.request();
          await Permission.manageExternalStorage.request();
        }
        return false;
      } else if (result.type == ResultType.error) {        _showErrorDialog(
          context,
          'Error Opening File',
          'An error occurred while trying to open the file: ${result.message}',
        );
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Could not open file: $e');
      _showErrorDialog(
        context,
        'Error',
        'An unexpected error occurred while trying to open the file.',
      );
      return false;
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
