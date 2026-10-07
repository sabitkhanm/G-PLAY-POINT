import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/models.dart';

class AppController extends ChangeNotifier {
  final db = AppDatabase.instance;
  ThemeMode themeMode = ThemeMode.system;
  bool bangla = true;
  int tabIndex = 0;
  DashboardSummary? summary;

  Future<void> refreshSummary() async {
    summary = await db.getSummary();
    notifyListeners();
  }

  void setTheme(ThemeMode mode) { themeMode = mode; notifyListeners(); }
  void toggleLanguage() { bangla = !bangla; notifyListeners(); }
  void setTab(int index) { tabIndex = index; notifyListeners(); }
}

class AppStrings {
  final bool bn;
  const AppStrings(this.bn);
  String get appName => 'G-PLAY POINT';
  String get dashboard => bn ? 'ড্যাশবোর্ড' : 'Dashboard';
  String get players => bn ? 'প্লেয়ার' : 'Players';
  String get ledger => bn ? 'পয়েন্ট লেজার' : 'Point Ledger';
  String get payments => bn ? 'পেমেন্ট' : 'Payments';
  String get expenses => bn ? 'খরচ' : 'Expenses';
  String get settings => bn ? 'সেটিংস' : 'Settings';
  String get totalPlayers => bn ? 'মোট প্লেয়ার' : 'Total Players';
  String get totalPoints => bn ? 'মোট পয়েন্ট' : 'Total Points';
  String get todayPayments => bn ? 'আজকের পেমেন্ট' : 'Today Payments';
  String get todayExpenses => bn ? 'আজকের খরচ' : 'Today Expenses';
  String get addPlayer => bn ? 'প্লেয়ার যোগ করুন' : 'Add Player';
  String get search => bn ? 'নাম, ফোন বা Gmail দিয়ে খুঁজুন' : 'Search name, phone or Gmail';
  String get name => bn ? 'নাম' : 'Name';
  String get phone => bn ? 'ফোন' : 'Phone';
  String get email => bn ? 'Gmail / Email' : 'Gmail / Email';
  String get notes => bn ? 'নোট' : 'Notes';
  String get save => bn ? 'সেভ করুন' : 'Save';
  String get cancel => bn ? 'বাতিল' : 'Cancel';
  String get addPoints => bn ? 'পয়েন্ট যোগ' : 'Add Points';
  String get spendPoints => bn ? 'পয়েন্ট খরচ' : 'Spend Points';
  String get refundPoints => bn ? 'পয়েন্ট ফেরত' : 'Refund Points';
  String get history => bn ? 'হিস্ট্রি' : 'History';
  String get noData => bn ? 'এখনও কোনো তথ্য নেই' : 'No data yet';
  String get amount => bn ? 'পরিমাণ' : 'Amount';
  String get method => bn ? 'মাধ্যম' : 'Method';
  String get reference => bn ? 'রেফারেন্স' : 'Reference';
  String get category => bn ? 'ক্যাটাগরি' : 'Category';
  String get language => bn ? 'ভাষা' : 'Language';
  String get theme => bn ? 'থিম' : 'Theme';
  String get light => bn ? 'লাইট' : 'Light';
  String get dark => bn ? 'ডার্ক' : 'Dark';
  String get system => bn ? 'সিস্টেম' : 'System';
  String get createdBy => bn ? 'Created by SA SABIT KHAN' : 'Created by SA SABIT KHAN';
}
