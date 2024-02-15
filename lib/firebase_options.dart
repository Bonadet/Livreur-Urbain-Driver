// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB6LCcUkcB-vGqIOxRiC0O3orWxHBs8MpE',
    appId: '1:79093478358:web:ea127ca0366286f200ea77',
    messagingSenderId: '79093478358',
    projectId: 'livreur-urbain',
    authDomain: 'livreur-urbain.firebaseapp.com',
    databaseURL: 'https://livreur-urbain-default-rtdb.firebaseio.com',
    storageBucket: 'livreur-urbain.appspot.com',
    measurementId: 'G-CR2HBVGCEE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCcMjiaqL_dxhOWzJbZOfzcqDx3_99mu1I',
    appId: '1:79093478358:android:9ce187f399f2571600ea77',
    messagingSenderId: '79093478358',
    projectId: 'livreur-urbain',
    databaseURL: 'https://livreur-urbain-default-rtdb.firebaseio.com',
    storageBucket: 'livreur-urbain.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAyYhW9Db-VKjCJqRHJozqzIyBlXKT64BA',
    appId: '1:79093478358:ios:3a2b822da84c0c4e00ea77',
    messagingSenderId: '79093478358',
    projectId: 'livreur-urbain',
    databaseURL: 'https://livreur-urbain-default-rtdb.firebaseio.com',
    storageBucket: 'livreur-urbain.appspot.com',
    androidClientId: '79093478358-4nc2fq28oeduff7u5q4mk9t4k4per4c8.apps.googleusercontent.com',
    iosClientId: '79093478358-4a0dgu5ok3fviokumek81hsrn417n4iu.apps.googleusercontent.com',
    iosBundleId: 'bundle.id',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAyYhW9Db-VKjCJqRHJozqzIyBlXKT64BA',
    appId: '1:79093478358:ios:7fba15e84270edc100ea77',
    messagingSenderId: '79093478358',
    projectId: 'livreur-urbain',
    databaseURL: 'https://livreur-urbain-default-rtdb.firebaseio.com',
    storageBucket: 'livreur-urbain.appspot.com',
    androidClientId: '79093478358-4nc2fq28oeduff7u5q4mk9t4k4per4c8.apps.googleusercontent.com',
    iosClientId: '79093478358-uv3uqdkife2mddh9j8oij6lm2ke5l51f.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterDriver.RunnerTests',
  );
}
