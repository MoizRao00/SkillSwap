import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';
import '../activity/activity_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../exchange/exchange_request_list_screen.dart';
import '../profile/profile_screen.dart';
import '../search/screen_search.dart';
import '../settings/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _fs = FirestoreService();
  UserModel? _currentUser; // <-- Store the full UserModel
  int _selectedIndex = 0;
  int _unreadNotifications = 0;

  // Define _screens as a getter, so it can use _currentUser
  List<Widget> get _screens {
    return [
      const DashboardScreen(),
      const ExchangeRequestsListScreen(),
      ActivityScreen(),
      const SearchScreen(),
      // Pass the _currentUser to ProfileScreen here
      // Handle the case where _currentUser might still be null during loading
      _currentUser != null
          ? ProfileScreen(currentUser: _currentUser!)
          : const Center(child: CircularProgressIndicator()), // Or a Text('Loading Profile...')
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // <-- Changed from _loadUserName
    _setupNotificationListener();
  }

  // --- MODIFIED: Load the full UserModel ---
  Future<void> _loadCurrentUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists && mounted) { // Check if document exists
          setState(() {
            _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
          });
        } else {
          print('User document does not exist for UID: $uid');
          // Handle case where user might not have a profile yet (e.g., new signup)
          // You might want to navigate them to an "onboarding" or "create profile" screen
          // or initialize a basic UserModel for _currentUser.
        }
      } else {
        print('No current Firebase user found.');
        // Handle no logged-in user (e.g., navigate to login screen)
      }
    } catch (e) {
      print('❌ Error loading current user data: $e');
      // Optionally show a SnackBar or error state
    }
  }

  void _setupNotificationListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _fs.getUserNotifications(uid).listen((notifications) {
        if (mounted) {
          setState(() {
            _unreadNotifications = notifications
                .where((notification) => !notification.isRead)
                .length;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SkillSwap',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shadowColor: Colors.black.withOpacity(0.5),

        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // --- If SettingsScreen also needs currentUser, pass it here ---
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => SettingsScreen(currentUser: _currentUser),
              //   ),
              // );
              // For now, assuming SettingsScreen doesn't need it or gets it internally
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      // --- Display the selected screen ---
      // If _currentUser is null (still loading), it will show the CircularProgressIndicator
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          // If the profile tab is selected and user data is still loading,
          // you might want to prevent selection or show a temporary message.
          // For now, it will just show the CircularProgressIndicator from _screens getter.
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Exchanges',
          ),
          NavigationDestination(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        _unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Activities',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}