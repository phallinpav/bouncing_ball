import 'dart:io';

import 'package:bouncing_ball/game_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        initialRoute: '/',
        routes: {
          '/game': (context) => const GamePage(),
        },
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          appBar: AppBar(
            title: const Center(child: Text('Bouncing Ball')),
          ),
          body: const Center(child: Menu()),
        ),
        debugShowCheckedModeBanner: false);
  }
}

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/game');
            },
            child: const Text('Start')),
        ElevatedButton(
            onPressed: () {
              exit(0);
            },
            child: const Text('Exit'))
      ],
    );
  }
}
