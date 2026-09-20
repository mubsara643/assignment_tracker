import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> signup(
      String name, String email, String password, String role,
      {String classId = ''}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'classId': classId,
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('savedEmail', email);
      await prefs.setString('savedPassword', password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool savedLogin = prefs.getBool('isLoggedIn') ?? false;
    return savedLogin && _auth.currentUser != null;
  }

  Future<Map<String, String>> getSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('savedEmail') ?? '',
      'password': prefs.getString('savedPassword') ?? '',
    };
  }

  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return (doc.data() as Map<String, dynamic>)['role'];
  }

  Future<String?> getUserClassId() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return (doc.data() as Map<String, dynamic>)['classId'];
  }

  Future<void> logout() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}
