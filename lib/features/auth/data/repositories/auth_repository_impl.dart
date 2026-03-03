import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

      _authStateController.add(uid);
    } else {

      _authStateController.add(null);
    }
  }

  @override
  Future<void> signIn({required String username, required String password}) async {


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

        if (storedPassword == password) {
          final uid = userNode.key!;
          final agencyId = userData['agencyId'] as String? ?? '';
          final role = userData['role'] as String? ?? 'salesman';
          final storedDeviceId = userData['deviceId'] as String?;

          // Get Current Device ID
          String? currentDeviceId;
          try {
            currentDeviceId = await getCurrentDeviceId();
          } catch (e) {
            print('Error getting device ID: $e');
            // Fail open or closed? 
            // For security, maybe fail closed, but for usability/web, maybe open.
            // Let's assume mobile app primarily.
          }

          if (currentDeviceId != null) {
            // 1. Check if ANY OTHER user (salesman OR owner) is using this device
            final deviceQuery = await ref
                .orderByChild('deviceId')
                .equalTo(currentDeviceId)
                .get();

            if (deviceQuery.exists) {
              final matchNode = deviceQuery.children.first;
              // If the device matches someone ELSE — block regardless of role
              if (matchNode.key != uid) {
                throw Exception('This device is already in use by another account.');
              }
            }

            // 2. Enforce personal device binding for ALL roles
            if (storedDeviceId == null || storedDeviceId.isEmpty) {
              // First login: Bind this device to the user
              await ref.child(uid).update({'deviceId': currentDeviceId});
            } else if (storedDeviceId != currentDeviceId) {
              // Device mismatch: Block login
              throw Exception('Unauthorized Device: You are already registered on another mobile. Please contact Admin.');
            }
          }

          await _prefs.setString(_userKey, uid);
          await _prefs.setString('agencyId', agencyId);
          await _prefs.setString('role', role);

          _authStateController.add(uid);
        } else {
          throw Exception('Invalid username or password');
        }
      } else {
        throw Exception('Invalid username or password');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> getCurrentDeviceId() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.fingerprint; // Unique per-device build fingerprint
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // Unique ID on iOS
      }
    } catch (e) {
      print('Failed to get device ID: $e');
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_userKey);
    _authStateController.add(null);
  }

  @override
  Future<Map<String, dynamic>?> checkVersionUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      
      final snapshot = await _database.ref().child('app_config').child('force_update').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        final minVersion = data['min_version']?.toString() ?? '1.0.0';
        final updateUrl = data['update_url']?.toString() ?? '';
        
        final isLower = _isVersionLower(currentVersion, minVersion);

        if (isLower) {
           return {
             'update_required': true, 
             'update_url': updateUrl,
             'current_version': currentVersion,
             'min_version': minVersion,
           };
        }
      } else {
        print('FORCE_UPDATE_DEBUG: No force_update config found in Firebase at app_config/force_update');
      }
    } catch (e) {
      print('FORCE_UPDATE_DEBUG: Error during version check: $e');
    }
    return null;
  }

  bool _isVersionLower(String current, String target) {
    final currentParts = current.split('.').map(int.parse).toList();
    final targetParts = target.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      final currentVal = i < currentParts.length ? currentParts[i] : 0;
      final targetVal = i < targetParts.length ? targetParts[i] : 0;
      
      if (currentVal < targetVal) return true;
      if (currentVal > targetVal) return false;
    }
    return false;
  }
}
