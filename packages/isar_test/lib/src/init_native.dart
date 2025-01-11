import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;

Future<void> init() async {
  
  final rootDir = path.dirname(path.dirname(Directory.current.path));
  final binaryName = 'libisar.so';
        
    try {
      await Isar.initializeIsarCore();
    } catch (e) {
      await Isar.initializeIsarCore(
        libraries: {
          path.join(
            rootDir,
            'target',
            'aarch64-unknown-linux-ohos',
            'release',
            binaryName,
          ),
        },
      );
    }
}
