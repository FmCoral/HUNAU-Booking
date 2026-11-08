/// Web 端不支持应用内下载安装，调用方会回退到浏览器。
class UnsupportedPlatformException implements Exception {
  const UnsupportedPlatformException();

  @override
  String toString() => '当前平台不支持应用内下载安装';
}

Future<String> prepareApkFilePath(String fileName) async {
  throw const UnsupportedPlatformException();
}

Future<void> installApkFile(String path) async {
  throw const UnsupportedPlatformException();
}

Future<void> cleanOldApks({String? excludePath}) async {}
