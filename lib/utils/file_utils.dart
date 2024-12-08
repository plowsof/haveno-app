import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

Future<String> extractAssetToTemp(String assetPath) async {
  // Load the asset using rootBundle
  final byteData = await rootBundle.load(assetPath);

  // Get the temporary directory
  final tempDir = await getTemporaryDirectory();

  // Create a file in the temporary directory
  final file = File('${tempDir.path}/temp_asset_file');

  // Write the asset's byte data to the file
  await file.writeAsBytes(byteData.buffer.asUint8List());

  // Return the file path
  return file.path;
}

Future<void> extractAssetToFile(String assetPath, String filename) async {
  // Step 1: Load the asset as a byte array
  ByteData data = await rootBundle.load(assetPath);
  
  // Step 2: Convert the byte data to a list of bytes
  List<int> bytes = data.buffer.asUint8List();

  // Step 3: Get the application's document directory or specific directory
  Directory appDocDir = await getApplicationSupportDirectory();
  String filePath = '${appDocDir.path}/$filename';

  // Step 4: Create a file in the desired location
  File file = File(filePath);

  // Step 5: Write the bytes to the file
  await file.writeAsBytes(bytes);

  print("Asset saved to $filePath");
}


bool hasExecutablePermissions(String filePath) {
  try {
    File file = File(filePath);
    FileStat stats = file.statSync();
    
    return stats.mode & 0x1 == 0x1;
  } catch (e) {
    throw Exception('Error checking permissions: $e');
  }
}

void setExecutablePermissions(String filePath) {
  if (Platform.isLinux || Platform.isMacOS) {
    try {
      final file = File(filePath);
      final directory = Directory(filePath);

      if (file.existsSync()) {
        // If it's a file, set executable permission for the file itself
        var result = Process.runSync('chmod', ['+x', filePath]);
        if (result.exitCode == 0) {
          print('Executable permission set for file: $filePath');
        } else {
          print('Failed to set executable permission for file: ${result.stderr}');
        }
      } else if (directory.existsSync()) {
        // If it's a directory, set executable permission for all files inside the directory
        directory.listSync(recursive: true).forEach((entity) {
          if (entity is File) {
            // Set executable permissions for each file inside the directory
            var result = Process.runSync('chmod', ['+x', entity.path]);
            if (result.exitCode == 0) {
              print('Executable permission set for file: ${entity.path}');
            } else {
              print('Failed to set executable permission for file: ${result.stderr}');
            }
          }
        });
      } else {
        print('File or directory does not exist: $filePath');
      }
    } catch (e) {
      print('Error setting permissions: $e');
    }
  } else {
    print('Setting executable permissions is not supported on this platform.');
  }
}
