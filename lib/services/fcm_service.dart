import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isInitializing = false;

  /// Request notification permission and initialize FCM token.
  /// Guarded to prevent concurrent calls from overlapping.
  Future<void> initToken() async {
    if (_isInitializing) return; // Already running, skip duplicate call
    _isInitializing = true;

    try {
      // Request permission (required for iOS, no-op on Android 12 and below)
      try {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        // Permission request may fail if already running (e.g. after hot reload).
        // Continue to getToken anyway — permission may already be granted.
        print('FCM permission request skipped: $e');
      }

      // Get the current FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      } else {
        print('FCM token was null');
      }
    } catch (e) {
      print('Error initializing FCM token: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Listen for token refresh events and update Firestore automatically.
  void listenForTokenRefresh() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen((newToken) async {
      await _saveTokenToFirestore(newToken);
    });
  }

  /// Clear the FCM token from Firestore on logout.
  Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'crm_app_fcm_token': '',
          'crm_app_fcm_token_updated_on': FieldValue.serverTimestamp(),
        });
        print('FCM token cleared from Firestore');
      }
    } catch (e) {
      print('Error clearing FCM token: $e');
    }

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  /// Save the FCM token to the current user's document in Firestore.
  Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'crm_app_fcm_token': token,
          'crm_app_fcm_token_updated_on': FieldValue.serverTimestamp(),
        });
        print('FCM token saved to Firestore: $token');
      } else {
        print('No user document found for uid: $uid');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}
