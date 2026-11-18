import 'package:flutter/foundation.dart';

const String kDefaultProductImage = 'assets/images/imagelist1.jpg';

/// Host that reaches the Laravel server from the current platform.
String get _apiHost {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2:8000'; // Android emulator -> Mac
  }
  return '127.0.0.1:8000'; // iOS simulator, macOS, web
}

/// Turns whatever the API stored in `image_url` into something the app can load.
///  - 'uploads/abc.png'                  -> http://<host>/uploads/abc.png
///  - 'http://10.0.2.2:8000/uploads/x'   -> http://<host>/uploads/x   (fixes old Android URLs on iOS)
///  - 'http://127.0.0.1:8000/uploads/x'  -> http://<host>/uploads/x
///  - 'assets/...'                       -> unchanged (bundled asset)
///  - empty / null                       -> default image
String resolveImageUrl(dynamic raw) {
  var s = (raw ?? '').toString().trim();
  if (s.isEmpty || s == 'null') return kDefaultProductImage;

  if (s.startsWith('http://') || s.startsWith('https://')) {
    final uri = Uri.tryParse(Uri.encodeFull(Uri.decodeFull(s)));
    if (uri != null &&
        (uri.host == '10.0.2.2' ||
            uri.host == '127.0.0.1' ||
            uri.host == 'localhost')) {
      return 'http://$_apiHost${uri.path}';
    }
    return Uri.encodeFull(Uri.decodeFull(s));
  }

  if (s.startsWith('/uploads/')) s = s.substring(1);
  if (s.startsWith('uploads/') || s.startsWith('storage/')) {
    return Uri.encodeFull('http://$_apiHost/$s');
  }

  if (s.startsWith('assets/')) return s;
  return kDefaultProductImage;
}