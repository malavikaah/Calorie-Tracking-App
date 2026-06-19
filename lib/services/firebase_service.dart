import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/dietitian_profile.dart';
import '../models/food_entry.dart';
import '../models/user_account.dart';
import '../models/chat_message.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, UserRole> _recentlyRegisteredRoles = {};

  // --- Authentication ---
  
  Stream<User?> get userStream => _auth.authStateChanges();

  Future<UserCredential?> signUp(String email, String password, UserRole role) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        _recentlyRegisteredRoles[cred.user!.uid] = role;
        // Save account role
        await _db.collection('accounts').doc(cred.user!.uid).set({
          'email': email,
          'role': role.toString().split('.').last,
        });
      }
      return cred;
    } catch (e) {
      print('Signup Error: $e');
      return null;
    }
  }

  Future<UserCredential?> logIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- User Profiles ---

  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    await _db.collection('users').doc(uid).set(profile.toJson());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    }
    return null;
  }

  // --- Dietitian Profiles ---

  Future<void> saveDietitianProfile(String uid, DietitianProfile profile) async {
    await _db.collection('dietitians').doc(uid).set(profile.toJson());
    // Also update the account role just in case
    await _db.collection('accounts').doc(uid).update({'role': 'dietitian'});
  }

  Future<DietitianProfile?> getDietitianProfile(String uid) async {
    final doc = await _db.collection('dietitians').doc(uid).get();
    if (doc.exists) {
      return DietitianProfile.fromJson(doc.data()!);
    }
    return null;
  }

  // --- Account Details ---

  Future<Map<String, dynamic>?> getAccountDetails(String uid) async {
    final doc = await _db.collection('accounts').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    // Fallback to in-memory recently registered roles cache if Firestore is not written yet
    if (_recentlyRegisteredRoles.containsKey(uid)) {
      return {
        'email': _auth.currentUser?.email ?? '',
        'role': _recentlyRegisteredRoles[uid]!.toString().split('.').last,
      };
    }
    return null;
  }

  // --- Food Logs ---

  Future<void> addFoodEntry(String uid, FoodEntry entry) async {
    await _db.collection('users').doc(uid).collection('food_logs').add(entry.toJson());
  }

  Stream<List<FoodEntry>> getFoodLogs(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('food_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodEntry.fromJson(doc.data()))
            .toList());
  }

  // --- Dietitians ---

  Future<List<Map<String, dynamic>>> getDietitians() async {
    final snapshot = await _db.collection('dietitians').get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id; // Include the UID for querying their account email
      return data;
    }).toList();
  }

  Future<String?> getEmailByUid(String uid) async {
    final doc = await _db.collection('accounts').doc(uid).get();
    return doc.data()?['email'];
  }

  // --- Chat ---

  Future<void> sendMessage(String senderEmail, String receiverEmail, String text) async {
    final messageData = {
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
      'participants': [senderEmail, receiverEmail],
    };
    
    await _db.collection('messages').add(messageData);
  }

  Stream<List<ChatMessage>> getChatMessages(String userEmail, String otherEmail) {
    return _db
        .collection('messages')
        .where('participants', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          senderEmail: data['senderEmail'] ?? '',
          receiverEmail: data['receiverEmail'] ?? '',
          message: data['message'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).where((msg) =>
          (msg.senderEmail == userEmail && msg.receiverEmail == otherEmail) ||
          (msg.senderEmail == otherEmail && msg.receiverEmail == userEmail))
      .toList();

      // Sort locally to avoid needing a composite Firestore index
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }
  Stream<List<String>> getChatParticipantsStream(String userEmail) {
    return _db
        .collection('messages')
        .where('participants', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) {
      final Set<String> participants = {};
      for (var doc in snapshot.docs) {
        final List<dynamic> p = doc.data()['participants'] ?? [];
        for (var email in p) {
          if (email != userEmail) {
            participants.add(email as String);
          }
        }
      }
      return participants.toList();
    });
  }

  Future<Map<String, dynamic>> getUserDataByEmail(String email) async {
    try {
      final trimmedEmail = email.trim();
      final lowercaseEmail = trimmedEmail.toLowerCase();
      String? uid;
      
      // Try to find UID from accounts
      var accountQuery = await _db.collection('accounts').where('email', isEqualTo: trimmedEmail).get();
      if (accountQuery.docs.isEmpty && trimmedEmail != lowercaseEmail) {
        accountQuery = await _db.collection('accounts').where('email', isEqualTo: lowercaseEmail).get();
      }
      
      if (accountQuery.docs.isNotEmpty) {
        uid = accountQuery.docs.first.id;
      } else {
        // Fallback: search in users collection for a document with this email
        var userQuery = await _db.collection('users').where('email', isEqualTo: trimmedEmail).get();
        if (userQuery.docs.isEmpty && trimmedEmail != lowercaseEmail) {
          userQuery = await _db.collection('users').where('email', isEqualTo: lowercaseEmail).get();
        }
        if (userQuery.docs.isNotEmpty) {
          uid = userQuery.docs.first.id;
        }
      }

      if (uid != null) {
        final userDoc = await _db.collection('users').doc(uid).get();
        final logsSnapshot = await _db.collection('users').doc(uid).collection('food_logs').get();
        
        final profile = userDoc.exists ? UserProfile.fromJson(userDoc.data()!) : null;
        final logs = logsSnapshot.docs.map((doc) => FoodEntry.fromJson(doc.data())).toList();
        
        print('Successfully fetched ${logs.length} logs for $email');
        return {'profile': profile, 'logs': logs};
      }
      print('No user found with email: $email');
    } catch (e) {
      print('Error getting user data by email: $e');
    }
    return {'profile': null, 'logs': <FoodEntry>[]};
  }

  Future<String> getUserNameByEmail(String email) async {
    try {
      final searchEmail = email.trim();
      final lowercaseEmail = searchEmail.toLowerCase();
      
      // 1. Direct search in users collection
      var userQuery = await _db.collection('users').where('email', isEqualTo: searchEmail).get();
      if (userQuery.docs.isEmpty && searchEmail != lowercaseEmail) {
        userQuery = await _db.collection('users').where('email', isEqualTo: lowercaseEmail).get();
      }
      if (userQuery.docs.isNotEmpty) {
        final name = userQuery.docs.first.data()['name'];
        if (name != null) return name;
      }

      // 2. Fallback: Check accounts collection
      var accountQuery = await _db.collection('accounts').where('email', isEqualTo: searchEmail).get();
      if (accountQuery.docs.isEmpty && searchEmail != lowercaseEmail) {
        accountQuery = await _db.collection('accounts').where('email', isEqualTo: lowercaseEmail).get();
      }
      if (accountQuery.docs.isNotEmpty) {
        final uid = accountQuery.docs.first.id;
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data()?['name'] != null) {
          return userDoc.data()!['name'];
        }
        final dietDoc = await _db.collection('dietitians').doc(uid).get();
        if (dietDoc.exists && dietDoc.data()?['name'] != null) {
          return dietDoc.data()!['name'];
        }
      }
    } catch (e) {
      print('Error getting name by email: $e');
    }
    return email;
  }
}
