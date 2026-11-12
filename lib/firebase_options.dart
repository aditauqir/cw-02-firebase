import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Uses the course Firebase project 'mad-inclass11' from In-Class Activity 14.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAHis7hFZm770zjY-F56C2n-OkTySfnMwc',
    appId: '1:705627349691:web:879608ebc33ab0b290e083',
    messagingSenderId: '705627349691',
    projectId: 'mad-inclass11',
    authDomain: 'mad-inclass11.firebaseapp.com',
    storageBucket: 'mad-inclass11.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0-eqHT4sLqGb4jRkOgBEyyoeYp4CYxXY',
    appId: '1:705627349691:android:7e8d2d01df837328453f9e',
    messagingSenderId: '705627349691',
    projectId: 'mad-inclass11',
    storageBucket: 'mad-inclass11.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0-eqHT4sLqGb4jRkOgBEyyoeYp4CYxXY',
    appId: '1:705627349691:ios:7e8d2d01df837328453f9e',
    messagingSenderId: '705627349691',
    projectId: 'mad-inclass11',
    storageBucket: 'mad-inclass11.firebasestorage.app',
  );

  static const FirebaseOptions inclass13 = FirebaseOptions(
    apiKey: 'AIzaSyAgjcahQVnk_vCNz33KasXCYaTaYKwrfkE',
    appId: '1:15229532858:android:f825157e580b74e690e083',
    messagingSenderId: '15229532858',
    projectId: 'inclass-13-dfe78',
    storageBucket: 'inclass-13-dfe78.firebasestorage.app',
  );
}
