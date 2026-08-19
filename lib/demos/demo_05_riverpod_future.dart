import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO DEMO : Modifie le délai de Future.delayed pour montrer le loading plus longtemps
// Simule un appel API asynchrone avec un délai de 2 secondes
Future<List<String>> fetchFakeTasks() async {
  await Future.delayed(const Duration(seconds: 2));
  return [
    'Acheter du pain',
    'Prparer la prsentation',
    'Appeler le dentiste',
    'Finir le chapitre 5',
    'Rdiger le rapport',
  ];
}

// TODO DEMO : Fais planter la fonction fake (throw Exception) pour montrer l'tat error
// FutureProvider autoDispose : les donnes sont libres quand plus personne n'coute
final futureProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return fetchFakeTasks();
});

class DemoRiverpodFuture extends ConsumerWidget {
  const DemoRiverpodFuture({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO DEMO : Retire autoDispose et montre que les donnes restent en cache
    final tasksAsync = ref.watch(futureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod FutureProvider'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: tasksAsync.when(
        // tat : chargement
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement...'),
            ],
          ),
        ),
        // tat : erreur
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur : $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              // TODO DEMO : Ajoute un bouton qui appelle ref.invalidate() pour recharger
              ElevatedButton(
                onPressed: () => ref.invalidate(futureProvider),
                child: const Text('Ressayer'),
              ),
            ],
          ),
        ),
        // tat : donnes chargées
        data: (tasks) => Column(
          children: [
            // Compteur du nombre total de tches
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Total des tches : ${tasks.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Liste des tches
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(tasks[index]),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Bouton pour rafraichir les donnes via ref.invalidate()
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.invalidate(futureProvider),
        tooltip: 'Rafraichir',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
