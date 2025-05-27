import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfService {  static Future<bool> generateAndSharePdf({
    required String base64String,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      // Check if base64String is empty or invalid
      if (base64String.isEmpty || !isValidPdfBase64(base64String)) {
        return false;
      }
      
      final bytes = base64Decode(base64String);
      
      // First save the file to a stable location (Downloads or Documents)
      Directory directory;
      if (Platform.isAndroid) {
        // Try to use the Download directory first, fallback to app's documents directory
        try {
          if (await Permission.storage.request().isGranted || 
              await Permission.manageExternalStorage.request().isGranted) {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use the documents directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms
        directory = await getApplicationDocumentsDirectory();
      }
      
      // Create the file
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      // Show success message with file path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${directory.path}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openFile(filePath),
          ),
        ),
      );
        // Create a temporary share result variable
      XFile fileToShare = XFile(filePath);
      
      // Share the file
      await Share.shareXFiles(
        [fileToShare],
        subject: fileName,
        text: 'Sharing PDF file',
      );
      
      return true;} catch (e) {
      debugPrint('PDF generation or sharing error: $e');
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
      String filePath;
      
      if (Platform.isAndroid) {
        // Request storage permission first
        final storagePermission = await Permission.storage.request();
        final manageStoragePermission = await Permission.manageExternalStorage.request();
        
        if (storagePermission.isGranted || manageStoragePermission.isGranted) {
          // Try Downloads folder first
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = Directory('/storage/emulated/0/Downloads');
          }
          
          // Fallback to app documents if Downloads not accessible
          if (!await directory.exists()) {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          // Show permission denied dialog
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Permission Required'),
                  content: const Text('Storage permission is required to save PDF files. Please grant permission in settings.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Open Settings'),
                    ),
                  ],
                );
              },
            );
          }
          return false;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      // Show success dialog with open option
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('PDF Generated'),
              content: Text('File saved successfully to:\n${directory.path}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _openFile(filePath);
                  },
                  child: const Text('Open'),
                ),
              ],
            );
          },
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('PDF save error: $e');
      return false;
    }
  }  static Future<void> _openFile(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // Request necessary permissions
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
      
      debugPrint('Attempting to open file: $filePath');
      
      if (await canLaunchUrl(fileUri)) {
        final result = await launchUrl(
          fileUri, 
          mode: LaunchMode.externalApplication,
        );
        
        debugPrint('Launch result: $result');
      } else {
        debugPrint('Could not launch file: $filePath (canLaunchUrl returned false)');
        
        // Fallback for Android using package:open_filex if available
        try {
          if (Platform.isAndroid) {
            // This is a hypothetical call - would need the open_filex package
            // await OpenFilex.open(filePath);
            debugPrint('Attempted to use fallback method to open file');
          }
        } catch (fallbackError) {
          debugPrint('Fallback file opening method failed: $fallbackError');
        }
      }
    } catch (e) {
      debugPrint('Could not open file: $e');
    }
  }
}
