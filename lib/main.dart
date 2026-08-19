import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import des 9 écrans de démo
import 'demos/demo_01_setstate.dart';
import 'demos/demo_02_change_notifier.dart';
import 'demos/demo_03_provider.dart';
import 'demos/demo_04_riverpod_state.dart';
import 'demos/demo_05_riverpod_future.dart';
import 'demos/demo_06_riverpod_stream.dart';
import 'demos/demo_07_riverpod_family.dart';
import 'demos/demo_08_notifier.dart';
import 'demos/demo_09_architecture.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'State Management Démos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Écran d'accueil : menu des 9 démos
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <_DemoEntry>[
      _DemoEntry('setState', 'Le compteur classique', Icons.numbers, const DemoSetState()),
      _DemoEntry('ChangeNotifier', 'Notifier les auditeurs', Icons.notifications_active, const DemoChangeNotifier()),
      _DemoEntry('Provider', 'Consumer, read, watch', Icons.account_tree, const DemoProvider()),
      _DemoEntry('Riverpod StateProvider', 'Filtres et valeurs simples', Icons.filter_list, const DemoRiverpodState()),
      _DemoEntry('Riverpod FutureProvider', 'Chargement asynchrone', Icons.cloud_download, const DemoRiverpodFuture()),
      _DemoEntry('Riverpod StreamProvider', 'Données en temps réel', Icons.wifi, const DemoRiverpodStream()),
      _DemoEntry('Riverpod family', 'Paramètres et autoDispose', Icons.family_restroom, const DemoRiverpodFamily()),
      _DemoEntry('NotifierProvider', 'Logique CRUD complète', Icons.edit_note, const DemoNotifier()),
      _DemoEntry('Architecture', '3 couches Riverpod', Icons.architecture, const DemoArchitecture()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('State Management — Démos Live'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: demos.length,
        itemBuilder: (context, index) {
          final demo = demos[index];
          return _DemoTile(demo: demo, index: index);
        },
      ),
    );
  }
}

/// Modèle pour une entrée de démo
class _DemoEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  const _DemoEntry(this.title, this.subtitle, this.icon, this.screen);
}

/// Tuile cliquable représentant une démo
class _DemoTile extends StatelessWidget {
  final _DemoEntry demo;
  final int index;

  const _DemoTile({required this.demo, required this.index});

  @override
  Widget build(BuildContext context) {
    final number = (index + 1).toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(number),
        ),
        title: Text(demo.title),
        subtitle: Text(demo.subtitle),
        trailing: Icon(demo.icon),
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (ctx, a, b) => demo.screen,
              transitionsBuilder: (ctx, animation, child2, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
