import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth get auth => Firebase.apps.any((app) => app.name == 'inclass13')
    ? FirebaseAuth.instanceFor(app: Firebase.app('inclass13'))
    : FirebaseAuth.instance;

Future<UserCredential> register(String email, String password) =>
    auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

Future<UserCredential> signIn(String email, String password) =>
    auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

Future<void> logOut() => auth.signOut();
