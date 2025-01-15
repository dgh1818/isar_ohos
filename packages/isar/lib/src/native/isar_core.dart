// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/native/bindings.dart';

const Id isarMinId = -9223372036854775807;

const Id isarMaxId = 9223372036854775807;

const Id isarAutoIncrementId = -9223372036854775808;

typedef IsarAbi = Abi;

const int minByte = 0;
const int maxByte = 255;
const int minInt = -2147483648;
const int maxInt = 2147483647;
const int minLong = -9223372036854775808;
const int maxLong = 9223372036854775807;
const double minDouble = double.nan;
const double maxDouble = double.infinity;

const nullByte = IsarObject_NULL_BYTE;
const nullInt = IsarObject_NULL_INT;
const nullLong = IsarObject_NULL_LONG;
const nullFloat = double.nan;
const nullDouble = double.nan;
final nullDate = DateTime.fromMillisecondsSinceEpoch(0);

const nullBool = IsarObject_NULL_BOOL;
const falseBool = IsarObject_FALSE_BOOL;
const trueBool = IsarObject_TRUE_BOOL;

const String _githubUrl = 'https://gitee.com/du_guang/isar/releases';

bool _isarInitialized = false;

// ignore: non_constant_identifier_names
late final IsarCoreBindings IC;

typedef FinalizerFunction = void Function(Pointer<Void> token);
late final Pointer<NativeFinalizerFunction> isarClose;
late final Pointer<NativeFinalizerFunction> isarQueryFree;


FutureOr<void> initializeCoreBinary({
  Map<Abi, String> libraries = const {Abi.linuxX64: "libisar.so"},
  bool download = false,
}) {
  if (_isarInitialized) {
    return null;
  }

  String? libraryPath = libraries[Abi.linuxX64];


  try {
    _initializePath(libraryPath);
  } catch (e) {
      throw IsarError(
        'Could not initialize IsarCore library for processor architecture '
        '"${libraries[Abi.linuxX64]}". If you create a Flutter app, make sure to add '
        'Could not initialize IsarCore library for processor architecture '
        '"${Abi.current()}". If you create a Flutter app, make sure to add '
        'isar_flutter_libs to your dependencies.\n$e',
      );
  }
}

void _initializePath(String? libraryPath) {
  late DynamicLibrary dylib;
  
  //dylib = defaultOpen();

  dylib = DynamicLibrary.open('libisar.so');

  if(dylib==null){
    throw IsarError(
      'dylib null'
    );
  }

  

  final bindings = IsarCoreBindings(dylib);

  final coreVersion = bindings.isar_version().cast<Utf8>().toDartString();
  if (coreVersion != Isar.version && coreVersion != 'debug') {
    throw IsarError(
      'Incorrect Isar Core version: Required ${Isar.version} found '
      '$coreVersion. Make sure to use the latest isar_flutter_libs. If you '
      'have a Dart only project, make sure that old Isar Core binaries are '
      'deleted.',
    );
  }

  print("binding");
  IC = bindings;
  print("binding ok");
  isarClose = dylib.lookup('isar_instance_close');
  print("lookup");
  isarQueryFree = dylib.lookup('isar_q_free');
  _isarInitialized = true;
}

String _getLibraryDownloadPath(Map<Abi, String> libraries) {
  final providedPath = libraries[Abi.linuxX64];

  return providedPath!;
 
}

Future<void> _downloadIsarCore(String libraryPath) async {
  final libraryFile = File(libraryPath);
  // ignore: avoid_slow_async_io
  if (await libraryFile.exists()) {
    return;
  }
  final remoteName = Abi.current().remoteName;
  final uri = Uri.parse('https://gitee.com/du_guang/isar/releases/download/v3.1.0+1/isar_ohos_arm64.so');
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw IsarError(
      'Could not download IsarCore library: ${response.reasonPhrase}',
    );
  }
  await response.pipe(libraryFile.openWrite());
}

IsarError? isarErrorFromResult(int result) {
  if (result != 0) {
    final error = IC.isar_get_error(result);
    if (error.address == 0) {
      throw IsarError(
        'There was an error but it could not be loaded from IsarCore.',
      );
    }
    try {
      final message = error.cast<Utf8>().toDartString();
      return IsarError(message);
    } finally {
      IC.isar_free_string(error);
    }
  } else {
    return null;
  }
}

@pragma('vm:prefer-inline')
void nCall(int result) {
  final error = isarErrorFromResult(result);
  if (error != null) {
    throw error;
  }
}

Stream<void> wrapIsarPort(ReceivePort port) {
  final portStreamController = StreamController<void>(onCancel: port.close);
  port.listen((event) {
    if (event == 0) {
      portStreamController.add(null);
    } else {
      final error = isarErrorFromResult(event as int);
      portStreamController.addError(error!);
    }
  });
  return portStreamController.stream;
}

extension PointerX on Pointer {
  @pragma('vm:prefer-inline')
  bool get isNull => address == 0;
}



DynamicLibrary defaultOpen() {
 
  
  try {
    return DynamicLibrary.open('libisar.so');
    // ignore: avoid_catching_errors
  } on ArgumentError {
    // On some (especially old) Android devices, we somehow can't dlopen
    // libraries shipped with the apk. We need to find the full path of the
    // library (/data/data/<id>/lib/libsqlite3.so) and open that one.
    // For details, see https://github.com/simolus3/moor/issues/420
    final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();

    // app id ends with the first \0 character in here.
    final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
    final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));

    return DynamicLibrary.open('/data/data/$appId/lib/libisar.so');
  }
}

extension on Abi {
  String get localName {
    switch (Abi.current()) {
      case Abi.androidArm:
      case Abi.androidArm64:
      case Abi.androidIA32:
      case Abi.androidX64:
        return 'libisar.so';
      case Abi.macosArm64:
      case Abi.macosX64:
        return 'libisar.dylib';
      case Abi.linuxX64:
        return 'libisar.so';
      case Abi.windowsArm64:
      case Abi.windowsX64:
        return 'isar.dll';
      default:
        return 'libisar.so';
    }
  }

  String get remoteName {
    switch (Abi.current()) {
      case Abi.macosArm64:
      case Abi.macosX64:
        return 'libisar_macos.dylib';
      case Abi.linuxX64:
        return 'isar_ohos_arm64.so';
      case Abi.windowsArm64:
        return 'isar_windows_arm64.dll';
      case Abi.windowsX64:
        return 'isar_windows_x64.dll';
      default:
        return 'isar_ohos_arm64.so';
    }
    throw UnimplementedError();
  }
}