import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/login_page.dart';
import 'package:venered_social/screens/home_feed_screen.dart';
import 'package:venered_social/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeFeedScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Venered",
          style: Theme.of(context).textTheme.titleLarge, // Use theme's titleLarge
        ),
        centerTitle: false, // Align title to left like Instagram
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded), // Use rounded logout icon
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          )
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar( // Replaced BottomNavigationBar with NavigationBar
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), // Outlined icon for unselected
              selectedIcon: Icon(Icons.home), // Filled icon for selected
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), // Outlined icon for unselected
              selectedIcon: Icon(Icons.person), // Filled icon for selected
              label: 'Profile'),
        ],
      ),
    );
  }
}
