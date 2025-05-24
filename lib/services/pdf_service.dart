import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfService {
  static Future<bool> generateAndSharePdf({
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
      
      Directory directory;      if (Platform.isAndroid) {
        if (await Permission.storage.request().isGranted) {
          // Try to use the Download directory first, fallback to app's documents directory
          try {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } catch (e) {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          // If permission not granted, use app's documents directory
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
      
      // Create a temporary share result variable
      XFile fileToShare = XFile(filePath);
      
      // Share the file
      final shareResult = await Share.shareXFiles(
        [fileToShare],
        subject: fileName,
        text: 'Sharing PDF file',
      );
      
      // Check if the file was successfully shared
      if (shareResult.status == ShareResultStatus.success || 
          shareResult.status == ShareResultStatus.dismissed) {
        return true;
      } else {
        return false;
      }    } catch (e) {
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
}
