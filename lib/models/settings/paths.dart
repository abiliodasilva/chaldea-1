import 'dart:convert';
import 'dart:io';

import 'package:chaldea/utils/basic.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../packages/logger.dart';
import '../../packages/platform/platform.dart';
import '../../utils/constants.dart';
import '../basic.dart';

class PathManager {
  /// [_appPath] root path where app data stored, can be configured by user
  String? _appPath;

  /// persistent data/config store path
  String? _persistentPath;

  // ignore: unused_element
  Future<String?> _debugPath(
      String key, Future<dynamic> Function() getter) async {
    dynamic _path;
    try {
      _path = await getter();
    } catch (e) {
      _path = '$e';
    }
    String result = '';
    if (_path is String) {
      result = _path;
    } else if (_path is Directory) {
      result = _path.path;
    } else if (_path is List<Directory> || _path is List<Directory?>) {
      result = List<Directory?>.of(_path).map((e) => e?.path).join('\n\t\t');
    } else {
      result = _path.toString();
    }
    print('$key\n\t\t$result');
    return result;
  }

  Future<void> initRootPath() async {
    // await _debugPath(
    //     '1-ApplicationDocuments', () => getApplicationDocumentsDirectory());
    // await _debugPath(
    //     '2-ApplicationSupport', () => getApplicationSupportDirectory());
    // await _debugPath('3-Temporary', () => getTemporaryDirectory());
    // await _debugPath('4-Library', () => getLibraryDirectory());
    // await _debugPath('5-Downloads', () => getDownloadsDirectory());
    // await _debugPath('6-ExternalCache', () => getExternalCacheDirectories());
    // await _debugPath('7-ExternalStorage', () => getExternalStorageDirectory());
    // await _debugPath(
    //     '8-ExternalStorages', () => getExternalStorageDirectories());

    if (_appPath != null) return;
    if (PlatformU.isWeb) {
      _persistentPath = _appPath = 'web';
      initiateLoggerPath('');
      return;
    }

    if (PlatformU.isAndroid) {
      // enhancement: startup check, if SD card not exists and set to use external, raise a warning
      _persistentPath = (await getApplicationDocumentsDirectory()).path;
      final sp = await SharedPreferences.getInstance();
      bool useExternal = sp.get('android_use_external') == true;
      List<String> externalPaths = (await getExternalStorageDirectories())!
          .map((e) => e.path)
          .whereType<String>()
          .toList();
      // don't use getApplicationDocumentsDirectory, it is hidden to user.
      // android external storages: [emulated, external SD]
      if (useExternal && externalPaths.length >= 2) {
        _appPath = externalPaths[1];
      } else {
        _appPath = externalPaths[0];
      }
      // _tempPath = (await getTemporaryDirectory())?.path;
    } else if (PlatformU.isIOS) {
      _persistentPath =
          _appPath = (await getApplicationDocumentsDirectory()).path;
      // _tempPath = (await getTemporaryDirectory())?.path;
    } else if (PlatformU.isMacOS) {
      // /Users/<user>/Library/Containers/cc.narumi.chaldea/Data/Documents
      _persistentPath =
          _appPath = (await getApplicationDocumentsDirectory()).path;
      // /Users/<user>/Library/Containers/cc.narumi.chaldea/Data/Library/Caches
      // _tempPath = (await getTemporaryDirectory())?.path;
    } else if (PlatformU.isWindows) {
      // _tempPath = (await getTemporaryDirectory())?.path;
      // set link:
      // in old version windows, it may need admin permission, so it may fail
      String exeFolder = pathlib.dirname(PlatformU.resolvedExecutable);
      _persistentPath = exeFolder;
      _appPath = pathlib.join(exeFolder, 'userdata');
      if (kDebugMode) {
        // C:\Users\<user>\AppData\Roaming\cc.narumi\Chaldea
        _appPath = (await getApplicationSupportDirectory()).path;
      }
    } else if (PlatformU.isLinux) {
      String exeFolder = pathlib.dirname(PlatformU.resolvedExecutable);
      _persistentPath = exeFolder;
      _appPath = pathlib.join(exeFolder, 'userdata');
      if (kDebugMode) {
        // Ubuntu: /home/<user>/.local/share/chaldea
        _appPath = (await getApplicationSupportDirectory()).path;
      }
    } else {
      throw UnimplementedError(
          'Not supported for ${PlatformU.operatingSystem}');
    }
    if (_appPath == null) {
      throw const OSError('Cannot resolve document folder');
    }
    if (runChaldeaNext) {
      _appPath = joinPaths(_appPath!, 'next');
    }
    logger.i('appPath: $_appPath');
    // ensure directory exist
    for (String dir in [
      _persistentPath!,
      userDir,
      gameDir,
      tempDir,
      downloadDir,
      gameIconDir,
      logDir
    ]) {
      Directory(dir).createSync(recursive: true);
    }
    // logger
    initiateLoggerPath(appLog);
    // crash files
    final File crashFile = File(crashLog);
    if (!crashFile.existsSync()) {
      crashFile.writeAsString('chaldea.crash.log\n', flush: true);
    }
    rollLogFiles(crashFile.path, 3, 1 * 1024 * 1024);
  }

  String convertIosPath(String p) {
    return PlatformU.isIOS
        ? p.replaceFirst(appPath, 'S.current.ios_app_path')
        : p;
  }

  String hiveAsciiKey(String s) {
    return Uri.tryParse(s)?.toString() ?? base64Encode(utf8.encode(s));
  }

  String get appPath => _appPath!;

  String get gameDir => pathlib.join(_appPath!, 'data');

  String get userDir => pathlib.join(_appPath!, 'user');

  String get tempDir => pathlib.join(_appPath!, 'temp');

  String get downloadDir => pathlib.join(_appPath!, 'downloads');

  String get configDir => pathlib.join(_appPath!, 'config');

  String get userDataPath => pathlib.join(userDir, kUserDataFilename);

  String get userDataBackupDir => pathlib.join(appPath, 'backup');

  String get gameDataPath => pathlib.join(gameDir, kGameDataFilename);

  String get gameIconDir => pathlib.join(gameDir, 'icons');

  String get logDir => pathlib.join(_appPath!, 'logs');

  String get appLog => pathlib.join(logDir, 'log.log');

  String get crashLog => pathlib.join(logDir, 'crash.log');

  String get datasetVersionFile => pathlib.join(gameDir, 'VERSION');

  // persistent
  @Deprecated('use shared_preference instead')
  String get persistentConfigPath =>
      pathlib.join(_persistentPath!, 'setting.json');
}