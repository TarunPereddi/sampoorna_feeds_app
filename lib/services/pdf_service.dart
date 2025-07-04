import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';

/// PDF Service for handling PDF generation, saving, and sharing across platforms.
/// 
/// This service uses a dynamic path approach with proper Flutter APIs to create a 'sampoornafeeds' 
/// folder in the most appropriate location for each platform:
/// 
/// - Android (with storage permission): Public storage/sampoornafeeds (user accessible)
/// - Android (without permission): App external storage/sampoornafeeds
/// - iOS: App Documents/sampoornafeeds (due to sandboxing - only accessible via Files app share)
/// - Other platforms: App Documents/sampoornafeeds
/// 
/// This approach:
/// - Uses proper Flutter path_provider APIs instead of hardcoded paths
/// - Works on all Android devices regardless of manufacturer or version
/// - Handles iOS sandboxing correctly
/// - Provides proper fallbacks for permission-denied scenarios
/// - Dynamically determines the best storage location
class PdfService {  static Future<bool> generateAndSharePdf({
    required String base64String,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      if (base64String.isEmpty || !isValidPdfBase64(base64String)) {
        return false;
      }

      final bytes = base64Decode(base64String);
      
      // Get sampoornafeeds directory
      final sampoornaFeedsDir = await _getSampoornaFeedsDirectory();
      if (sampoornaFeedsDir == null) {
        _showErrorDialog(context, 'Error', 'Could not access storage directory');
        return false;
      }

      final filePath = '${sampoornaFeedsDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSuccessDialog(context, fileName, 'sampoornafeeds folder');

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
  }  static Future<String?> saveToDownloads({
    required String base64String,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      if (base64String.isEmpty || !isValidPdfBase64(base64String)) {
        return null;
      }

      final bytes = base64Decode(base64String);
      
      // Get sampoornafeeds directory
      final sampoornaFeedsDir = await _getSampoornaFeedsDirectory();
      if (sampoornaFeedsDir == null) {
        _showErrorDialog(context, 'Error', 'Could not access storage directory');
        return null;
      }

      final filePath = '${sampoornaFeedsDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSuccessDialogWithOpen(context, fileName, 'sampoornafeeds folder', filePath);
      return filePath;
    } catch (e) {
      debugPrint('PDF save error: $e');
      _showErrorDialog(context, 'Error', 'Could not save the PDF: ${e.toString()}');
      return null;
    }
  }  // Helper method to get or create sampoornafeeds directory using proper Flutter APIs
  static Future<Directory?> _getSampoornaFeedsDirectory() async {
    try {
      Directory baseDirectory;
      
      if (Platform.isAndroid) {
        // For Android, use proper path_provider APIs
        if (await Permission.storage.request().isGranted) {
          // Try to get external storage directory (user accessible)
          Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Navigate to user-accessible root storage
            // External storage path is like: /storage/emulated/0/Android/data/package/files
            // We want to go back to: /storage/emulated/0/
            List<String> pathSegments = externalDir.path.split('/');
            int androidIndex = pathSegments.indexOf('Android');
            
            if (androidIndex > 0) {
              // Build path back to public storage root
              String publicStoragePath = pathSegments.sublist(0, androidIndex).join('/');
              Directory publicDir = Directory(publicStoragePath);
              
              // Test if we can write to this directory
              try {
                final testFile = File('${publicDir.path}/.test_write');
                await testFile.writeAsString('test');
                await testFile.delete();
                baseDirectory = publicDir;
              } catch (e) {
                debugPrint('Cannot write to public storage: $e');
                // Fallback to external storage directory
                baseDirectory = externalDir;
              }
            } else {
              baseDirectory = externalDir;
            }
          } else {
            // Fallback to app documents directory
            baseDirectory = await getApplicationDocumentsDirectory();
          }
        } else {
          // Permission denied, use app-specific directory
          Directory? externalDir = await getExternalStorageDirectory();
          baseDirectory = externalDir ?? await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use documents directory (this is the standard and only accessible location)
        baseDirectory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms (desktop), use documents directory
        baseDirectory = await getApplicationDocumentsDirectory();
      }

      // Create sampoornafeeds folder in the base directory
      final sampoornaFeedsDir = Directory('${baseDirectory.path}/sampoornafeeds');
      if (!await sampoornaFeedsDir.exists()) {
        await sampoornaFeedsDir.create(recursive: true);
      }

      debugPrint('sampoornafeeds directory created at: ${sampoornaFeedsDir.path}');
      return sampoornaFeedsDir;
    } catch (e) {
      debugPrint('Error creating sampoornafeeds directory: $e');
      return null;
    }
  }// Get the sampoornafeeds directory path
  static Future<String?> getDownloadsDirectoryPath() async {
    try {
      final sampoornaFeedsDir = await _getSampoornaFeedsDirectory();
      return sampoornaFeedsDir?.path;
    } catch (e) {
      debugPrint('Error getting sampoornafeeds directory path: $e');
      return null;
    }  }

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
  static void _showSuccessDialogWithOpen(BuildContext context, String fileName, String filePath, String fullPath) {    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 400;
        final dialogWidth = screenSize.width * (isSmallScreen ? 0.9 : 0.8);
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: dialogWidth > 400 ? 400 : dialogWidth,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  children: [
                    Icon(
                      Icons.check_circle, 
                      color: Colors.green.shade700, 
                      size: isSmallScreen ? 24 : 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PDF Saved Successfully',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your document has been saved:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File Name:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fileName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Location:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            filePath,
                            style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await openFileWithFeedback(
                          filePath: fullPath,
                          context: context,
                        );
                      },
                      icon: Icon(
                        Icons.open_in_new, 
                        size: isSmallScreen ? 16 : 18,
                      ),
                      label: Text(
                        'Open PDF',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C5F2D),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  static void _showSuccessDialog(BuildContext context, String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 400;
        final dialogWidth = screenSize.width * (isSmallScreen ? 0.9 : 0.8);
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: dialogWidth > 400 ? 400 : dialogWidth,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  children: [
                    Icon(
                      Icons.check_circle, 
                      color: Colors.green.shade700, 
                      size: isSmallScreen ? 24 : 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PDF Generated Successfully',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your document has been saved:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File Name:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fileName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Location:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            filePath,
                            style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await openFile('$filePath/$fileName');
                      },
                      icon: Icon(
                        Icons.open_in_new, 
                        size: isSmallScreen ? 16 : 18,
                      ),
                      label: Text(
                        'Open',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C5F2D),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  static String generateUniqueFileName(String type, String customerId, String customerNo) {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd').format(now);
    final time = DateFormat('HHmmss').format(now);
    
    return '${type.capitalize()}_${customerId}_${customerNo}_${date}_${time}.pdf';
  }

  // Enhanced method for cross-platform PDF saving with user-friendly messaging
  static Future<String?> savePdfCrossPlatform({
    required String base64String,
    required String fileName,
    required BuildContext context,
    bool showShareDialog = true,
  }) async {
    try {
      if (base64String.isEmpty || !isValidPdfBase64(base64String)) {
        _showErrorDialog(
          context,
          'Invalid File',
          'The PDF file appears to be corrupted or invalid.',
        );
        return null;
      }      final bytes = base64Decode(base64String);
      
      // Get sampoornafeeds directory
      final sampoornaFeedsDir = await _getSampoornaFeedsDirectory();
      if (sampoornaFeedsDir == null) {
        _showErrorDialog(context, 'Error', 'Could not access storage directory');
        return null;
      }

      final filePath = '${sampoornaFeedsDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      String userMessage = 'PDF saved to sampoornafeeds folder successfully!';

      // Show platform-appropriate success dialog
      if (showShareDialog) {
        _showCrossPlatformSuccessDialog(context, fileName, filePath, userMessage);
      }

      return filePath;
    } catch (e) {
      debugPrint('PDF save error: $e');
      _showErrorDialog(
        context, 
        'Save Failed', 
        'Could not save the PDF file. Please try again or check available storage space.'
      );
      return null;
    }
  }

  // Helper method for Android storage handling  // Cross-platform success dialog with appropriate actions
  static void _showCrossPlatformSuccessDialog(
    BuildContext context, 
    String fileName,
    String filePath, 
    String message
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 400;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: screenSize.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PDF Saved Successfully',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _shareFile(filePath, fileName, context);
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C5F2D),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (Platform.isAndroid || Platform.isIOS)
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await openFileWithFeedback(
                            filePath: filePath,
                            context: context,
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Enhanced file sharing method
  static Future<void> _shareFile(String filePath, String fileName, BuildContext context) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileToShare = XFile(filePath);
        await Share.shareXFiles(
          [fileToShare],
          subject: fileName,
          text: 'Sharing PDF document',
        );
      } else {
        _showErrorDialog(
          context,
          'File Not Found',
          'The file could not be found for sharing.',
        );
      }
    } catch (e) {
      debugPrint('Error sharing file: $e');
      _showErrorDialog(
        context,
        'Share Failed',
        'Could not share the file. Please try again.',
      );
    }
  }

  /// Get platform-specific user guidance for accessing saved PDFs
  static String getPlatformSpecificGuidance() {
    if (Platform.isIOS) {
      return '''
📱 iOS: PDFs are saved to app documents folder.
📂 Access via: Files app → On My iPhone → Sampoorna Feeds → sampoornafeeds
💡 Tip: Use the Share button to save to Files app or send via email/messages.
      ''';
    } else if (Platform.isAndroid) {
      return '''
📱 Android: PDFs are saved to sampoornafeeds folder.
📂 Access via: File Manager → Internal Storage → sampoornafeeds
💡 Tip: You can find all your PDFs in this dedicated folder.
      ''';
    } else {
      return '''
💻 Desktop: PDFs are saved to app documents/sampoornafeeds folder.
📂 You can access them through your file explorer.
      ''';
    }
  }

  /// Enhanced method specifically for iOS that provides better user guidance
  static Future<String?> saveToDocumentsWithIOSGuidance({
    required String base64String,
    required String fileName,
    required BuildContext context,
  }) async {
    if (!Platform.isIOS) {
      // For non-iOS platforms, use the standard method
      return await savePdfCrossPlatform(
        base64String: base64String,
        fileName: fileName,
        context: context,
        showShareDialog: true,
      );
    }

    try {
      if (base64String.isEmpty || !isValidPdfBase64(base64String)) {
        _showErrorDialog(context, 'Invalid File', 'The PDF file appears to be corrupted or invalid.');
        return null;
      }

      final bytes = base64Decode(base64String);
      final sampoornaFeedsDir = await _getSampoornaFeedsDirectory();
      
      if (sampoornaFeedsDir == null) {
        _showErrorDialog(context, 'Error', 'Could not access storage directory');
        return null;
      }

      final filePath = '${sampoornaFeedsDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Show iOS-specific success dialog with guidance
      _showIOSSuccessDialog(context, fileName, filePath);
      return filePath;
    } catch (e) {
      debugPrint('PDF save error: $e');
      _showErrorDialog(context, 'Error', 'Could not save the PDF: ${e.toString()}');
      return null;
    }
  }

  /// iOS-specific success dialog with detailed guidance
  static void _showIOSSuccessDialog(BuildContext context, String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('PDF Saved Successfully!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📄 File: $fileName', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📱 How to access your PDF:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                    SizedBox(height: 8),
                    Text('1. Open Files app on your iPhone'),
                    Text('2. Tap "On My iPhone"'),
                    Text('3. Find "Sampoorna Feeds" folder'),
                    Text('4. Open "sampoornafeeds" folder'),
                    Text('5. Your PDF will be there!'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text('💡 Or use the Share button below to save to other locations or send via email/messages.', 
                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final fileToShare = XFile(filePath);
                await Share.shareXFiles([fileToShare], subject: fileName);
              },
              icon: Icon(Icons.share),
              label: Text('Share PDF'),
            ),
          ],
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
