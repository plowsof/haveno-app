import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:haveno_app/utils/arch_helper.dart';
import 'package:haveno_app/utils/file_utils.dart';
import 'package:haveno_app/versions.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';


Future<void> checkShouldDownloadMonero(String downloadTo) async {
  final applicationSupportDir = await getApplicationSupportDirectory();
  const url = 'https://downloads.getmonero.org/cli/linux64'; // Monero CLI URL
  const requiredBinaries = ['monerod', 'monero-wallet-rpc'];
  const fileName = 'monero-linux.tar.bz2';
  final downloadPath = path.join(applicationSupportDir.path, downloadTo, fileName);

  // Ensure the download directory exists
  final binDir = Directory(path.join(applicationSupportDir.path, downloadTo));
  final versionFilePath = path.join(binDir.path, 'monero_version');
  if (!binDir.existsSync()) {
    binDir.createSync(recursive: true);
  }

  // Check the current version
  String? currentVersion;
  if (File(versionFilePath).existsSync()) {
    currentVersion = File(versionFilePath).readAsStringSync().trim();
    print('Current version: $currentVersion');
    if (currentVersion == 'v${Versions().getVersion("monero")}') {
      return;
    } else {
      // Could deleteSync here but they will get overritten anyway, it might be approprioate to force pkill, and delete anyway because of the wallet.
    }
  }

  // Define the download task
  final task = DownloadTask(
    url: url,
    filename: fileName,
    directory: downloadTo,
    baseDirectory: BaseDirectory.applicationSupport,
    updates: Updates.statusAndProgress,
    requiresWiFi: false,
    retries: 3,
    allowPause: false,
  );

  // Start the download
  print('Downloading Monero CLI...');
  final result = await FileDownloader().download(
    task,
    onProgress: (progress) => print('Download Progress: ${progress * 100}%'),
    onStatus: (status) => print('Download Status: $status'),
  );

  if (result.status != TaskStatus.complete) {
    print('Download failed or was not completed.');
    return;
  }

  print('Download complete. Extracting...');

  // Decompress the .bz2 file
  final compressedData = File(downloadPath).readAsBytesSync();
  final decompressedData = BZip2Decoder().decodeBytes(compressedData);

  // Extract the .tar archive
  final archive = TarDecoder().decodeBytes(decompressedData);

  // Identify the nested folder (e.g., monero-x86_64-linux-gnu-v0.18.3.4)
  String? nestedFolder;
  for (final file in archive.files) {
    if (file.isFile) {
      final parts = path.split(file.name);
      if (parts.length > 1) {
        nestedFolder = parts.first;
        break;
      }
    }
  }

  if (nestedFolder == null) {
    print('Could not identify nested folder in the archive.');
    return;
  }

  print('Nested folder identified: $nestedFolder');

  // Extract required binaries from the nested folder
  for (final file in archive.files) {
    if (file.isFile && requiredBinaries.contains(path.basename(file.name))) {
      final relativePath = path.relative(file.name, from: nestedFolder);
      final outputPath = path.join(binDir.path, relativePath);
      final outputFile = File(outputPath);
      outputFile.createSync(recursive: true);
      outputFile.writeAsBytesSync(file.content as List<int>);
      print('Extracted binary: $outputPath');
    }
  }

  // Save the version extracted from the folder name
  final latestVersion = nestedFolder.split('-').last; // Extract version from folder name
  File(versionFilePath).writeAsStringSync(latestVersion);
  print('Updated monero_version to $latestVersion.');

  // Clean up the downloaded .tar.bz2 file
  File(downloadPath).deleteSync();
  print('Cleaned up temporary files.');

  // Set executable permissions
  setExecutablePermissions(path.join(applicationSupportDir.path, downloadTo, 'monerod'));
  setExecutablePermissions(path.join(applicationSupportDir.path, downloadTo, 'monero-wallet-rpc'));
}


Future<void> checkShouldDownloadHavenoDaemon(String downloadTo) async {
  var applicationSupportDir = await getApplicationSupportDirectory();
  const url = 'https://github.com/KewbitXMR/haveno-app/releases/download/0.1.0%2B4/daemon-all.jar';
  const fileName = 'daemon-all.jar';
  final downloadPath = path.join(applicationSupportDir.path, downloadTo, fileName);

  // Ensure the download directory exists
  final downloadDir = Directory(downloadTo);
  if (!downloadDir.existsSync()) {
    downloadDir.createSync(recursive: true);
  }

  // Check if the file already exists
  if (File(downloadPath).existsSync()) {
    print('Haveno Daemon JAR already exists at $downloadPath. No download needed.');
    return;
  }

  // Define the download task
  final task = DownloadTask(
    url: url,
    filename: fileName,
    directory: downloadTo,
    baseDirectory: BaseDirectory.applicationSupport,
    updates: Updates.statusAndProgress, // Show progress updates
    retries: 3,
    allowPause: false,
    requiresWiFi: false,
  );

  // Start the download
  print('Downloading Haveno Daemon JAR...');
  final result = await FileDownloader().download(
    task,
    onProgress: (progress) => print('Haveno Daemon Download Progress: ${progress * 100}%'),
    onStatus: (status) => print('Haveno Daemon Download Status: $status'),
  );

  // Handle the download result
  switch (result.status) {
    case TaskStatus.complete:
      print('Haveno Daemon JAR downloaded successfully to $downloadPath.');
      break;
    case TaskStatus.canceled:
      print('Haveno Daemon download was canceled.');
      break;
    case TaskStatus.paused:
      print('Haveno Daemon download was paused.');
      break;
    default:
      print('Failed to download Haveno Daemon JAR.');
      break;
  }
}

Future<void> checkShouldDownloadTor(String downloadTo) async {
  
  // Get the application support directory
  final applicationSupportDir = await getApplicationSupportDirectory();
  final downloadFilename = 'tor-expert-bundle.tar.gz';
  final downloadPath = path.join(applicationSupportDir.path, downloadFilename);

  // Get default tor version and make sure it exists

  final version = Versions().getVersion('tor');

  final url = 'https://dist.torproject.org/torbrowser/$version/tor-expert-bundle-linux-x86_64-$version.tar.gz';
  final torDir = path.join(applicationSupportDir.path, downloadTo, version);

  // Ensure the Tor directory exists
  final targetDir = Directory(torDir);
  final targetBin = File(path.join(torDir, 'tor'));
  if (!targetBin.existsSync()) {
    targetDir.createSync(recursive: true);
  } else {
    print('Tor $version is already installed.');
    return;
  }

  // Define the download task
  final task = DownloadTask(
    url: url,
    filename: downloadFilename,
    directory: path.join(downloadTo, version),
    baseDirectory: BaseDirectory.applicationSupport,
    updates: Updates.statusAndProgress,
    requiresWiFi: false,
    retries: 3,
    allowPause: false,
  );

  // Start the download
  print('Downloading Tor Expert Bundle...');
  final result = await FileDownloader().download(
    task,
    onProgress: (progress) => print('Download Progress: ${progress * 100}%'),
    onStatus: (status) => print('Download Status: $status'),
  );

  if (result.status != TaskStatus.complete) {
    print('Download failed or was not completed.');
    return;
  }

  print('Download complete. Extracting from {$torDir}/$downloadFilename...');

  // Read and decompress the .tar.gz file
  final compressedData = File(path.join(torDir, downloadFilename)).readAsBytesSync();
  final tarGzDecoder = GZipDecoder();
  final tarData = tarGzDecoder.decodeBytes(compressedData);

  // Extract the .tar archive
  final archive = TarDecoder().decodeBytes(tarData);
  for (final file in archive.files) {
    final filePath = path.join(torDir, file.name.replaceFirst('tor/', ''));
    final fileName = file.name.replaceFirst('tor/', '');
    if (file.isFile) {
      if (file.name.startsWith('tor/')) {
        final outputFile = File(path.join(torDir, fileName));
        outputFile.createSync(recursive: true);
        outputFile.writeAsBytesSync(file.content as List<int>);
        print('Extracted file to: ${path.join(torDir, fileName)}}');
      } else {
        final outputFile = File(filePath);
        outputFile.createSync(recursive: true);
        outputFile.writeAsBytesSync(file.content as List<int>);
        print('Extracted file to: ${path.join(torDir, fileName)}}');        
      }
    } else {
      Directory(filePath).createSync(recursive: true);
      print('Created directory: $filePath');
    }
  }

  // Clean up the downloaded .tar.gz file
  File(path.join(torDir, downloadFilename)).deleteSync();
  print('Cleaned up temporary files.');

  // Put the config
  if (!File(path.join(torDir, 'torrc')).existsSync()) {
    await extractAssetToFile('assets/config/default/torrc', 'Tor/torrc');
  }

  // Set permissions
  setExecutablePermissions(path.join(torDir));

  return;

}

Future<void> checkShouldDownloadJava(downloadTo) async {

  // First check if java bin file exists for the version specified
  // Get the application support directory
  final applicationSupportDir = await getApplicationSupportDirectory();
  final javaDir = path.join(applicationSupportDir.path, 'Java', '21.0.4+7');
  const fileName = 'java.tar.gz';
  final downloadPath = path.join(javaDir, fileName);
  File javaExecutableFile = File(path.join(javaDir, 'bin', 'java'));

  if (javaExecutableFile.existsSync()) {
    print('The correct version of java is already installed...');
      return;
  } else {
    // Since we will now continue to install a different version of Java that will be used we'll clear the Java folder completely
    Directory(javaDir).deleteSync();
    print("Deleted old Java version as there is a new version required");
  }

  Architecture arch = getArchitecture();
  String? url;
  if (arch == Architecture.x86_64) {
    url = 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jre_x64_linux_hotspot_21.0.4_7.tar.gz';
  } else if (arch == Architecture.arm64) {
    url = 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jre_aarch64_linux_hotspot_21.0.4_7.tar.gz';
  } else {
    url = null;
    throw Exception("Unsupported operating system architecture");
  }

  // Ensure the Java directory exists
  final targetDir = Directory(javaDir);
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  var finalExtractionPath = path.join(downloadTo, '21.0.4+7');

  // Define the download task
  final task = DownloadTask(
    url: url,
    filename: fileName,
    directory: finalExtractionPath,
    baseDirectory: BaseDirectory.applicationSupport,
    updates: Updates.statusAndProgress,
    requiresWiFi: false,
    retries: 3,
    allowPause: false,
  );

  // Start the download
  print('Downloading Java...');
  final result = await FileDownloader().download(
    task,
    onProgress: (progress) => print('Download Progress: ${progress * 100}%'),
    onStatus: (status) => print('Download Status: $status'),
  );

  if (result.status != TaskStatus.complete) {
    print('Download failed or was not completed.');
    return;
  }

  print('Download complete. Extracting from {$javaDir}/$fileName...');

  // Read and decompress the .tar.gz file
  final compressedData = File(downloadPath).readAsBytesSync();
  final tarGzDecoder = GZipDecoder();
  final tarData = tarGzDecoder.decodeBytes(compressedData);

  // Extract the .tar archive
  final archive = TarDecoder().decodeBytes(tarData);

  // Identify the first nested directory if it exists
  String? firstNestedDir;
  for (final file in archive.files) {
    if (file.isFile) {
      // Check for the first directory in the archive and store its path
      if (firstNestedDir == null) {
        final parts = path.split(file.name);
        if (parts.length > 1) {
          firstNestedDir = parts.first;
        }
      }
    }
  }

  // Extract files, skipping the first nested directory
  for (final file in archive.files) {
    String filePath;
    if (firstNestedDir != null && file.name.startsWith(firstNestedDir)) {
      // Remove the first nested directory from the file's path
      final relativePath = file.name.substring(firstNestedDir.length + 1); // Skip the first nested directory
      filePath = path.join(javaDir, relativePath); // Extract directly into javaDir
    } else {
      filePath = path.join(javaDir, file.name);
    }

    if (file.isFile) {
      final outputFile = File(filePath);
      outputFile.createSync(recursive: true);
      outputFile.writeAsBytesSync(file.content as List<int>);
      print('Extracted file to: $filePath');
    } else {
      Directory(filePath).createSync(recursive: true);
      print('Created directory: $filePath');
    }
  }

  // Clean up the downloaded .tar.gz file
  File(path.join(javaDir, fileName)).deleteSync();

  print('Cleaned up temporary files.');

  // Optionally set executable permissions if needed (for example, for binaries)
  setExecutablePermissions(path.join(applicationSupportDir.path, finalExtractionPath, 'bin'));

  return; 
}
