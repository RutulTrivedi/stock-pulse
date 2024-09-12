import 'package:flutter/material.dart';
import 'package:stock_pulse/pages/sp_home.dart';
import 'package:stock_pulse/pages/sp_profile.dart';
import 'package:stock_pulse/pages/sp_watchlist.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {

  int _selectedIndex = 1;

  final List<Widget> _pages = [
    WatchListPage(),
    HomePage(),
    ProfilePage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).focusColor,
              width: 1,
            ),
          ),
        ),
        child: ConvexAppBar(
          style: TabStyle.react,
          items: const [
            TabItem(icon: Icons.list, title: 'Watchlist'),
            TabItem(icon: Icons.home, title: 'Home'),
            TabItem(icon: Icons.person, title: 'Profile'),
          ],
          initialActiveIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Theme.of(context).canvasColor,
          activeColor: Theme.of(context).focusColor,
          shadowColor: Theme.of(context).focusColor,
          color: Colors.white,
        ),
      ),
    );
  }
}
