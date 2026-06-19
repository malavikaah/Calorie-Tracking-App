import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_account.dart';
import '../models/user_profile.dart';
import '../models/dietitian_profile.dart';
import '../models/food_entry.dart';
import '../models/chat_message.dart';
import '../services/firebase_service.dart';
import '../services/pdf_export_service.dart';

class AppState extends ChangeNotifier {
  final FirebaseService _firebaseService;
  UserAccount? _userAccount;
  UserProfile? _userProfile;
  DietitianProfile? _dietitianProfile;
  List<FoodEntry> _foodLogs = [];
  int _waterIntakeMl = 0;
  int _dailyWaterGoal = 2500;
  int _calocredits = 0;

  List<UserAccount> _allAccounts = [];
  List<ChatMessage> _messages = [];

  int _currentStreak = 0;
  String _lastStreakLoggedDate = "";
  List<String> _purchasedItems = ["default_theme"];
  String _activeTheme = "default_theme";
  List<String> _chatParticipants = [];
  bool _isInitialized = false;

  StreamSubscription? _authSubscription;
  StreamSubscription? _logsSubscription;
  StreamSubscription? _chatParticipantsSubscription;
  String? _currentProcessingUid;

  UserAccount? get userAccount => _userAccount;
  UserProfile? get userProfile => _userProfile;
  DietitianProfile? get dietitianProfile => _dietitianProfile;
  List<FoodEntry> get foodLogs => _foodLogs;
  int get waterIntakeMl => _waterIntakeMl;
  int get dailyWaterGoal => _dailyWaterGoal;
  int get calocredits => _calocredits;
  int get currentStreak => _currentStreak;
  List<String> get purchasedItems => _purchasedItems;
  String get activeTheme => _activeTheme;
  List<ChatMessage> get messages => _messages;
  List<String> get chatParticipants => _chatParticipants;
  bool get isInitialized => _isInitialized;

  bool get isLoggedIn => _userAccount != null;
  bool get hasProfile => _userProfile != null;
  bool get hasDietitianProfile => _dietitianProfile != null;

  AppState(this._firebaseService) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _firebaseService.userStream.listen((User? user) async {
      final String? thisUid = user?.uid;
      _currentProcessingUid = thisUid;

      if (user != null) {
        // Fetch everything in parallel or sequence before updating state
        var accountData = await _firebaseService.getAccountDetails(user.uid);
        if (_currentProcessingUid != thisUid) return; // Abort if user changed
        
        // Retry loop to handle slight delay in document creation after signup
        int retries = 0;
        while (accountData == null && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (_currentProcessingUid != thisUid) return; // Abort if user changed
          accountData = await _firebaseService.getAccountDetails(user.uid);
          retries++;
        }
        
        UserAccount tempAccount;
        if (accountData != null) {
          tempAccount = UserAccount.fromJson(accountData);
        } else {
          tempAccount = UserAccount(email: user.email ?? '', password: '', role: UserRole.user);
        }

        UserProfile? tempProfile;
        DietitianProfile? tempDietitian;
        
        if (tempAccount.role == UserRole.dietitian) {
          tempDietitian = await _firebaseService.getDietitianProfile(user.uid);
        } else {
          tempProfile = await _firebaseService.getUserProfile(user.uid);
        }
        if (_currentProcessingUid != thisUid) return; // Abort if user changed

        // Load settings for this specific user
        await _loadUserSettings(user.uid);
        if (_currentProcessingUid != thisUid) return; // Abort if user changed

        // Now update state all at once to avoid flickering
        _userAccount = tempAccount;
        _userProfile = tempProfile;
        _dietitianProfile = tempDietitian;

        // Setup subscriptions without notifying yet
        _logsSubscription?.cancel();
        _logsSubscription = _firebaseService.getFoodLogs(user.uid).listen((logs) {
          if (_currentProcessingUid != thisUid) return; // Ignore stale streams
          _foodLogs = logs;
          notifyListeners();
        });

        _chatParticipantsSubscription?.cancel();
        _chatParticipantsSubscription = _firebaseService.getChatParticipantsStream(_userAccount!.email).listen((participants) {
          if (_currentProcessingUid != thisUid) return; // Ignore stale streams
          _chatParticipants = participants;
          notifyListeners();
        });
      } else {
        // User is logged out
        _userAccount = null;
        _userProfile = null;
        _dietitianProfile = null;
        _foodLogs = [];
        _chatParticipants = [];
        _logsSubscription?.cancel();
        _chatParticipantsSubscription?.cancel();

        // Reset in-memory settings to defaults on sign out!
        _waterIntakeMl = 0;
        _calocredits = 0;
        _currentStreak = 0;
        _lastStreakLoggedDate = "";
        _purchasedItems = ["default_theme"];
        _activeTheme = "default_theme";
      }
      
      if (!_isInitialized) {
        // Give enough time to see the splash screen logo only on initial load
        await Future.delayed(const Duration(seconds: 2));
        if (_currentProcessingUid != thisUid) return; // Abort if user changed
        _isInitialized = true;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserSettings(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    _activeTheme = prefs.getString('${uid}_activeTheme') ?? "default_theme";
    _purchasedItems = prefs.getStringList('${uid}_purchasedItems') ?? ["default_theme"];
    _calocredits = prefs.getInt('${uid}_calocredits') ?? 0;
    _currentStreak = prefs.getInt('${uid}_currentStreak') ?? 0;
    _lastStreakLoggedDate = prefs.getString('${uid}_lastStreakLoggedDate') ?? "";
    
    // Load local water (reset if new day)
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedWaterDate = prefs.getString('${uid}_waterDate');
    
    if (savedWaterDate == today) {
      _waterIntakeMl = prefs.getInt('${uid}_waterIntake') ?? 0;
    } else {
      _waterIntakeMl = 0;
      await prefs.setString('${uid}_waterDate', today);
      await prefs.setInt('${uid}_waterIntake', 0);
    }
  }

  // --- Authentication ---
  Future<bool> login(String email, String password) async {
    final cred = await _firebaseService.logIn(email, password);
    return cred != null;
  }

  Future<bool> signup(String email, String password, {UserRole role = UserRole.user}) async {
    final cred = await _firebaseService.signUp(email, password, role);
    return cred != null;
  }

  Future<void> logout() async { 
    await _firebaseService.signOut();
  }
  
  // --- Profile & Data ---
  Future<void> registerUser(UserProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _calculateBmiAndCalories(profile);
      await _firebaseService.saveUserProfile(user.uid, profile);
      _userProfile = profile;
      notifyListeners();
    }
  }

  Future<void> registerDietitian(DietitianProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firebaseService.saveDietitianProfile(user.uid, profile);
      _dietitianProfile = profile;
      notifyListeners();
    }
  }

  void _calculateBmiAndCalories(UserProfile profile) {
    // Calculate BMI = weight(kg) / (height(m))^2
    double heightInMeters = profile.height / 100;
    profile.bmi = profile.weight / (heightInMeters * heightInMeters);

    if (profile.bmi < 18.5) profile.bmiCategory = 'Underweight';
    else if (profile.bmi < 24.9) profile.bmiCategory = 'Normal';
    else if (profile.bmi < 29.9) profile.bmiCategory = 'Overweight';
    else profile.bmiCategory = 'Obese';

    // Calculate BMR (Mifflin-St Jeor Equation)
    double bmr = profile.gender.toLowerCase() == 'male' 
        ? (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age) + 5
        : (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age) - 161;
    
    // Rough TDEE multiplier (Activity factor) - Assume moderate for now
    double tdee = bmr * 1.55;

    // Adjust for goals
    if (profile.goal == 'weight loss') tdee -= 500;
    else if (profile.goal == 'weight gain') tdee += 500;

    profile.dailyCalorieRequirement = tdee.round();
  }

  // --- Chat & Dietitians ---
  Future<List<Map<String, dynamic>>> getDietitians() async {
    final rawList = await _firebaseService.getDietitians();
    List<Map<String, dynamic>> results = [];
    
    for (var data in rawList) {
      final email = await _firebaseService.getEmailByUid(data['uid']);
      if (email != null) {
        results.add({
          'profile': DietitianProfile.fromJson(data),
          'email': email,
        });
      }
    }
    return results;
  }

  // --- Chat ---

  Stream<List<ChatMessage>> getChatMessagesStream(String otherEmail) {
    if (_userAccount == null) return Stream.value([]);
    return _firebaseService.getChatMessages(_userAccount!.email, otherEmail);
  }

  Future<void> sendMessage(String receiverEmail, String text) async {
    if (_userAccount == null) return;
    await _firebaseService.sendMessage(_userAccount!.email, receiverEmail, text);
  }

  Future<void> shareReportWithDietitian(String dietitianEmail) async {
    if (_userAccount == null) return;
    // For now, we send a specialized message. 
    // In a production app, we would upload the PDF to Firebase Storage and send the URL.
    final message = '[HEALTH REPORT] I have shared my nutritional report with you.';
    await sendMessage(dietitianEmail, message);
  }

  // To fix compilation errors for screens that still use the old list-based logic:
  Stream<List<String>> getChatParticipantsStream() {
    if (_userAccount == null) return Stream.value([]);
    return _firebaseService.getChatParticipantsStream(_userAccount!.email);
  }

  List<String> getChatParticipants() {
    return _chatParticipants;
  }

  List<ChatMessage> getMessagesWith(String otherEmail) {
    // Return empty list to satisfy compiler; the real logic will use Streams
    return [];
  }

  Future<void> addFoodLog(FoodEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firebaseService.addFoodEntry(user.uid, entry);
      // Local list is updated via the stream listener in _initAuthListener
      checkRewardTriggers(entry);
    }
  }

  int _lastWaterAmount = 0;

  Future<void> addWater(int amountMl) async {
    _lastWaterAmount = amountMl;
    _waterIntakeMl += amountMl;
    if (_waterIntakeMl > _dailyWaterGoal) _waterIntakeMl = _dailyWaterGoal;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await prefs.setString('${user.uid}_waterDate', today);
      await prefs.setInt('${user.uid}_waterIntake', _waterIntakeMl);
    }
    checkRewardTriggers(null);
    notifyListeners();
  }

  Future<void> undoWater() async {
    if (_lastWaterAmount > 0) {
      _waterIntakeMl -= _lastWaterAmount;
      if (_waterIntakeMl < 0) _waterIntakeMl = 0;
      _lastWaterAmount = 0; // Only allow undoing once per click
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await prefs.setInt('${user.uid}_waterIntake', _waterIntakeMl);
      }
      notifyListeners();
    }
  }

  bool get canUndoWater => _lastWaterAmount > 0;

  int get totalCaloriesConsumed {
    // Filter by today
    final today = DateTime.now();
    return _foodLogs
        .where((log) => 
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .fold(0, (sum, item) => sum + item.calories);
  }

  int get remainingCalories {
    if (_userProfile == null) return 0;
    int remaining = _userProfile!.dailyCalorieRequirement - totalCaloriesConsumed;
    return remaining > 0 ? remaining : 0;
  }

  // --- CaloCredits 2.0 Logic ---
  Future<void> earnCalocredits(int amount) async {
    _calocredits += amount;
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await prefs.setInt('${user.uid}_calocredits', _calocredits);
    }
    notifyListeners();
  }

  Future<bool> spendCalocredits(int amount, String itemId) async {
    if (_calocredits >= amount) {
      _calocredits -= amount;
      _purchasedItems.add(itemId);
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await prefs.setInt('${user.uid}_calocredits', _calocredits);
        await prefs.setStringList('${user.uid}_purchasedItems', _purchasedItems);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setTheme(String themeId) async {
    if (_purchasedItems.contains(themeId)) {
      _activeTheme = themeId;
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await prefs.setString('${user.uid}_activeTheme', _activeTheme);
      }
      notifyListeners();
    }
  }

  Future<String> getNameByEmail(String email) {
    return _firebaseService.getUserNameByEmail(email);
  }

  Future<void> checkRewardTriggers(FoodEntry? newEntry) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // 1. Water & Calorie Daily Goals (Existing)
    final lastWaterReward = prefs.getString('${uid}_lastWaterRewardDate');
    if (_waterIntakeMl >= _dailyWaterGoal && lastWaterReward != todayStr) {
      await earnCalocredits(10);
      await prefs.setString('${uid}_lastWaterRewardDate', todayStr);
    }

    final lastCalorieRewardDate = prefs.getString('${uid}_lastCalorieRewardDate');
    if (_userProfile != null && totalCaloriesConsumed >= _userProfile!.dailyCalorieRequirement && lastCalorieRewardDate != todayStr) {
        await earnCalocredits(12);
        await prefs.setString('${uid}_lastCalorieRewardDate', todayStr);
    }

    // 2. Consistency Streaks
    if (newEntry != null && _lastStreakLoggedDate != todayStr) {
      final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      if (_lastStreakLoggedDate == yesterdayStr) {
        _currentStreak += 1;
      } else {
        _currentStreak = 1;
      }
      _lastStreakLoggedDate = todayStr;
      await earnCalocredits(5 + (_currentStreak > 5 ? 10 : 0)); // Bonus for long streaks
      await prefs.setInt('${uid}_currentStreak', _currentStreak);
      await prefs.setString('${uid}_lastStreakLoggedDate', _lastStreakLoggedDate);
    }

    // 3. Golden Hour (Log before 8 PM)
    if (newEntry != null && now.hour < 20) {
       final lastGoldenHour = prefs.getString('${uid}_lastGoldenHourDate');
       if(lastGoldenHour != todayStr) {
          await earnCalocredits(5);
          await prefs.setString('${uid}_lastGoldenHourDate', todayStr);
       }
    }

    // 4. Diet Diversity (3+ distinct items today)
    final todaysFoods = _foodLogs.where((l) => l.timestamp.toIso8601String().substring(0, 10) == todayStr).map((l) => l.name).toSet();
    if (todaysFoods.length >= 3) {
      final lastDiversityReward = prefs.getString('${uid}_lastDiversityRewardDate');
      if (lastDiversityReward != todayStr) {
        await earnCalocredits(15);
        await prefs.setString('${uid}_lastDiversityRewardDate', todayStr);
      }
    }
  }


  // --- Clinical Data for Nutri Insights ---
  Map<String, dynamic> get nutriInsightsSummary => calculateInsights(_userProfile, _foodLogs);

  static Map<String, dynamic> calculateInsights(UserProfile? profile, List<FoodEntry> logs) {
    if (profile == null) return {};

    // Calculate real stability
    String stability = "Not Enough Data";
    final now = DateTime.now();
    final Map<String, int> dailyTotals = {};
    
    for (var log in logs) {
      if (now.difference(log.timestamp).inDays <= 7) {
        final dateKey = log.timestamp.toIso8601String().substring(0, 10);
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + log.calories;
      }
    }

    if (dailyTotals.isNotEmpty) {
      final totals = dailyTotals.values.toList();
      double mean = totals.reduce((a, b) => a + b) / totals.length;
      double variance = totals.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / totals.length;
      if (variance < 40000) {
        stability = "Highly Stable";
      } else if (variance < 250000) {
        stability = "Stable";
      } else {
        stability = "Fluctuating";
      }
    }

    int totalCals = 0;
    if (dailyTotals.isNotEmpty) {
       totalCals = dailyTotals.values.reduce((a, b) => a + b) ~/ dailyTotals.length;
    }

    return {
      'avgDailyCalories': totalCals,
      'bmiTrend': profile.bmiCategory,
      'healthAlertsActive': profile.healthCondition != 'none',
      'lastSevenDaysStability': stability,
    };
  }

  Future<void> viewPatientReport(String email) async {
    final data = await _firebaseService.getUserDataByEmail(email);
    final profile = data['profile'] as UserProfile?;
    final logs = data['logs'] as List<FoodEntry>;
    final insights = calculateInsights(profile, logs);
    await PdfExportService.generateAndPrintReport(profile, insights);
  }
}
