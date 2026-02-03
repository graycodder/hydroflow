import 'dart:async';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

abstract class AuthRepository {
  /// Stream of the current authenticated user ID (null if not logged in)
  Stream<String?> get onAuthStateChanged;

  /// Stream of the current salesman profile
  Stream<Salesman> getSalesmanStream(String uid);

  Future<void> signIn({required String username, required String password});

  Future<void> signOut();

  Future<void> restoreSession();
}
