// File generated from android/app/google-services.json
// Project: fueldirect-462cc
// DO NOT EDIT manually — regenerate with: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDY1I20EHTfnY3ahp2AQRxABd03TJOmiFI',
    appId: '1:989388396775:android:3742ab408e38b6b508ea42',
    messagingSenderId: '989388396775',
    projectId: 'fueldirect-462cc',
    storageBucket: 'fueldirect-462cc.firebasestorage.app',
  );

  // iOS placeholder — update when iOS is configured in Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDY1I20EHTfnY3ahp2AQRxABd03TJOmiFI',
    appId: '1:989388396775:ios:000000000000000000000000',
    messagingSenderId: '989388396775',
    projectId: 'fueldirect-462cc',
    storageBucket: 'fueldirect-462cc.firebasestorage.app',
    iosBundleId: 'com.fueldirect.fueldirectApp',
  );
}
