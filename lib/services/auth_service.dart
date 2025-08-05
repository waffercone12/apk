import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  User? get currentUser => _auth.currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required int age,
    File? profileImage,
  }) async {
    try {
      setLoading(true);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        String? profileImageUrl;

        if (profileImage != null) {
          profileImageUrl = await _uploadProfileImage(user.uid, profileImage);
        }

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber,
          'age': age,
          'profileImageUrl': profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'signInMethod': 'email',
        });

        await user.updateDisplayName(username);
        if (profileImageUrl != null) {
          await user.updatePhotoURL(profileImageUrl);
        }
      }

      setLoading(false);
      return result;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      throw _handleAuthException(e);
    } catch (_) {
      setLoading(false);
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      setLoading(true);
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _updateUserLastLogin(result.user!.uid);
      }

      setLoading(false);
      return result;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      throw _handleAuthException(e);
    } catch (_) {
      setLoading(false);
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      setLoading(true);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setLoading(false);
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'username': user.displayName ?? googleUser.displayName ?? 'User',
            'email': user.email ?? googleUser.email,
            'phoneNumber': user.phoneNumber ?? '',
            'age': 0,
            'profileImageUrl': user.photoURL ?? googleUser.photoUrl ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'signInMethod': 'google',
          });
        } else {
          await _updateUserLastLogin(user.uid);
        }
      }

      setLoading(false);
      return result;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      throw _handleAuthException(e);
    } catch (e) {
      setLoading(false);
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      setLoading(true);
      await _googleSignIn.signOut(); // Optional for Google accounts
      await _auth.signOut();
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw 'Sign out failed: ${e.toString()}';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      setLoading(true);
      await _auth.sendPasswordResetEmail(email: email);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw 'Failed to send password reset email: ${e.toString()}';
    }
  }

  // Upload profile image
  Future<String> _uploadProfileImage(String userId, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('profile_images').child('$userId.jpg');
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  // Update last login time
  Future<void> _updateUserLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // Handle Firebase exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'user-not-found':
        return 'User not found.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account is disabled.';
      default:
        return e.message ?? 'An error occurred.';
    }
  }

  // Additional helpers
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      setLoading(true);
      await reauthenticateWithPassword(currentPassword);
      await _auth.currentUser?.updatePassword(newPassword);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw 'Failed to change password: ${e.toString()}';
    }
  }
}
