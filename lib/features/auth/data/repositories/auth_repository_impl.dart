import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydroflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/data/models/salesman_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseDatabase _database;
  final SharedPreferences _prefs;
  final _authStateController = StreamController<String?>.broadcast();
  static const String _userKey = 'salesman_uid';

  AuthRepositoryImpl({
    FirebaseDatabase? database,
    required SharedPreferences sharedPreferences,
  })  : _database = database ?? FirebaseDatabase.instance,
        _prefs = sharedPreferences;

  @override
  Stream<String?> get onAuthStateChanged => _authStateController.stream;

  @override
  Stream<Salesman> getSalesmanStream(String uid) {
    return _database
        .ref()
        .child('Salesmen')
        .child(uid)
        .onValue
        .map((event) {
          if (event.snapshot.value != null) {
            return SalesmanModel.fromSnapshot(event.snapshot);
          } else {
             // Handle case where user might be deleted but session persists
             throw Exception('Salesman data not found');
          }
        });
  }

  @override
  Future<void> restoreSession() async {
    final uid = _prefs.getString(_userKey);
    if (uid != null) {
      print('AuthRepo: Restored session for UID: $uid');
      _authStateController.add(uid);
    } else {
      print('AuthRepo: No session found.');
      _authStateController.add(null);
    }
  }

  @override
  Future<void> signIn({required String username, required String password}) async {
    print('AuthRepo: Attempting sign in for "$username" (RTDB)');

    // Query Salesmen node ordering by 'username'
    final ref = _database.ref().child('Salesmen');
    
    try {
      final snapshot = await ref
          .orderByChild('username')
          .equalTo(username)
          .limitToFirst(1)
          .get();

      if (snapshot.exists) {
        // snapshot.children maps to the found nodes.
        // Since we limited to 1, we take the first.
        final userNode = snapshot.children.first;
        final userData = userNode.value as Map; // safely cast

        final storedPassword = userData['password'];
        
        print('AuthRepo: Found user. Verifying password...');
        
        if (storedPassword == password) {
             final uid = userNode.key!;
             print('AuthRepo: Login success. UID: $uid');
             await _prefs.setString(_userKey, uid);
             _authStateController.add(uid);
        } else {
             print('AuthRepo: Password mismatch.');
             throw Exception('Invalid username or password');
        }
      } else {
        print('AuthRepo: User not found.');
        throw Exception('Invalid username or password');
      }
    } catch (e) {
      print('AuthRepo: Error during sign in: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_userKey);
    _authStateController.add(null);
  }
}
