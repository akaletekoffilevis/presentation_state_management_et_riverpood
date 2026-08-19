import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO DEMO : Change l'intervalle à 1 seconde pour montrer les mises à jour plus rapides
final Stream<List<String>> _fakeStream = (() {
  final controller = StreamController<List<String>>();
  final messages = <String>[];
  var counter = 0;

  Timer.periodic(const Duration(seconds: 2), (_) {
    counter++;
    messages.add('Message #$counter');
    controller.add(List.from(messages));
  });

  return controller.stream;
})();

final streamProvider = StreamProvider<List<String>>((ref) => _fakeStream);

// TODO DEMO : Ajoute un message d'erreur dans le stream pour montrer l'état error

class DemoRiverpodStream extends ConsumerWidget {
  const DemoRiverpodStream({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(streamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod StreamProvider')),
      body: asyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
        data: (messages) {
          // TODO DEMO : Monte que chaque nouveau message met à jour l'UI automatiquement
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Dernière mise à jour : ${TimeOfDay.now().format(context)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // TODO DEMO : Ajoute un compteur de messages reçus en temps réel
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.message),
                      title: Text(messages[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(streamProvider);
        },
        label: const Text('Simuler un message'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
