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
      
      if (Platform.isAndroid) {
        // Request storage permission first
        if (await Permission.storage.request().isGranted || 
            await Permission.manageExternalStorage.request().isGranted) {
          
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
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
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
      
      return true;
    } catch (e) {
      debugPrint('PDF save error: $e');
      return false;
    }
  }

  static Future<void> _openFile(String filePath) async {
    try {
      final Uri fileUri = Uri.file(filePath);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not open file: $e');
    }
  }
}
