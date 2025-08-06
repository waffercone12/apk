// File: lib/services/user_profile_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assistant_personality.dart';

class UserProfileService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfile? _currentProfile;
  bool _isLoading = false;

  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _currentProfile?.onboardingCompleted ?? false;

  // Check if user exists and has completed onboarding
  Future<bool> checkUserOnboardingStatus() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('user_profiles').doc(user.uid).get();
      
      if (doc.exists) {
        _currentProfile = UserProfile.fromMap(doc.data()!);
        _isLoading = false;
        notifyListeners();
        return _currentProfile!.onboardingCompleted;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create new user profile after onboarding
  Future<void> createUserProfile({
    required String name,
    required String assistantName,
    required AssistantPersonality personality,
    required String primaryChallenge,
    required int readinessLevel,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      _isLoading = true;
      notifyListeners();

      final profile = UserProfile(
        uid: user.uid,
        name: name,
        email: user.email ?? '',
        assistantName: assistantName,
        personality: personality,
        primaryChallenge: primaryChallenge,
        readinessLevel: readinessLevel,
        onboardingCompleted: true,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        profileImageUrl: user.photoURL,
      );

      await _firestore.collection('user_profiles').doc(user.uid).set(profile.toMap());
      _currentProfile = profile;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null || _currentProfile == null) return;

    try {
      updates['lastActive'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('user_profiles').doc(user.uid).update(updates);
      
      // Update local profile
      _currentProfile = _currentProfile!.copyWith(updates);
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  // Update assistant settings
  Future<void> updateAssistantSettings({
    String? assistantName,
    AssistantPersonality? personality,
  }) async {
    final updates = <String, dynamic>{};
    
    if (assistantName != null) updates['assistantName'] = assistantName;
    if (personality != null) updates['personality'] = personality.name;
    
    if (updates.isNotEmpty) {
      await updateProfile(updates);
    }
  }

  // Track user progress
  Future<void> trackProgress({
    required String metric,
    required dynamic value,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final progressEntry = {
        'metric': metric,
        'value': value,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      };

      await _firestore
          .collection('user_profiles')
          .doc(user.uid)
          .collection('progress')
          .add(progressEntry);

    } catch (e) {
      print('Error tracking progress: $e');
    }
  }

  // Get user's progress data
  Future<List<ProgressEntry>> getProgress({
    String? metric,
    DateTime? since,
    int limit = 50,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      Query query = _firestore
          .collection('user_profiles')
          .doc(user.uid)
          .collection('progress')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (metric != null) {
        query = query.where('metric', isEqualTo: metric);
      }

      if (since != null) {
        query = query.where('timestamp', isGreaterThan: since);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => ProgressEntry.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
          
    } catch (e) {
      print('Error getting progress: $e');
      return [];
    }
  }

  // Update last active timestamp
  Future<void> updateLastActive() async {
    await updateProfile({'lastActive': FieldValue.serverTimestamp()});
  }

  // Delete user profile
  Future<void> deleteProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Delete progress subcollection
      final progressQuery = await _firestore
          .collection('user_profiles')
          .doc(user.uid)
          .collection('progress')
          .get();

      for (final doc in progressQuery.docs) {
        await doc.reference.delete();
      }

      // Delete main profile
      await _firestore.collection('user_profiles').doc(user.uid).delete();
      
      _currentProfile = null;
      notifyListeners();
      
    } catch (e) {
      print('Error deleting profile: $e');
    }
  }

  // Clear local data (for sign out)
  void clearProfile() {
    _currentProfile = null;
    notifyListeners();
  }
}

// Data Models
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String assistantName;
  final AssistantPersonality personality;
  final String primaryChallenge;
  final int readinessLevel;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime lastActive;
  final String? profileImageUrl;
  final Map<String, dynamic>? preferences;
  final int streak;
  final int totalSessions;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.assistantName,
    required this.personality,
    required this.primaryChallenge,
    required this.readinessLevel,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.lastActive,
    this.profileImageUrl,
    this.preferences,
    this.streak = 0,
    this.totalSessions = 0,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      assistantName: map['assistantName'] ?? '',
      personality: AssistantPersonality.values.firstWhere(
        (p) => p.name == map['personality'],
        orElse: () => AssistantPersonality.supportiveFriend,
      ),
      primaryChallenge: map['primaryChallenge'] ?? '',
      readinessLevel: map['readinessLevel'] ?? 5,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: map['profileImageUrl'],
      preferences: map['preferences'],
      streak: map['streak'] ?? 0,
      totalSessions: map['totalSessions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'assistantName': assistantName,
      'personality': personality.name,
      'primaryChallenge': primaryChallenge,
      'readinessLevel': readinessLevel,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'profileImageUrl': profileImageUrl,
      'preferences': preferences,
      'streak': streak,
      'totalSessions': totalSessions,
    };
  }

  UserProfile copyWith(Map<String, dynamic> updates) {
    return UserProfile(
      uid: updates['uid'] ?? uid,
      name: updates['name'] ?? name,
      email: updates['email'] ?? email,
      assistantName: updates['assistantName'] ?? assistantName,
      personality: updates['personality'] != null 
          ? AssistantPersonality.values.firstWhere((p) => p.name == updates['personality'])
          : personality,
      primaryChallenge: updates['primaryChallenge'] ?? primaryChallenge,
      readinessLevel: updates['readinessLevel'] ?? readinessLevel,
      onboardingCompleted: updates['onboardingCompleted'] ?? onboardingCompleted,
      createdAt: updates['createdAt'] ?? createdAt,
      lastActive: updates['lastActive'] ?? lastActive,
      profileImageUrl: updates['profileImageUrl'] ?? profileImageUrl,
      preferences: updates['preferences'] ?? preferences,
      streak: updates['streak'] ?? streak,
      totalSessions: updates['totalSessions'] ?? totalSessions,
    );
  }
}

class ProgressEntry {
  final String id;
  final String metric;
  final dynamic value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ProgressEntry({
    required this.id,
    required this.metric,
    required this.value,
    required this.timestamp,
    required this.metadata,
  });

  factory ProgressEntry.fromMap(String id, Map<String, dynamic> map) {
    return ProgressEntry(
      id: id,
      metric: map['metric'] ?? '',
      value: map['value'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'metric': metric,
      'value': value,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}