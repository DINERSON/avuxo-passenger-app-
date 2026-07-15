import 'package:flutter/material.dart';

import 'home_map_screen.dart';

class HomeShell extends StatefulWidget {
  static const routeName = '/home';

  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  Widget build(BuildContext context) {
    return const HomeMapScreen();
  }
}