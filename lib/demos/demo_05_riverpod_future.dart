import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Variable globale pour simuler une erreur
bool _simulerErreur = false;

// Fonction asynchrone fictive : retourne une liste de tâches après un délai
Future<List<String>> chargerTaches(int delai) async {
  await Future.delayed(Duration(seconds: delai));
  if (_simulerErreur) {
    throw Exception('Erreur de chargement des tâches !');
  }
  return [
    'Apprendre Riverpod',
    'Créer un FutureProvider',
    'Gérer les états loading / error / data',
    'Invalider le cache avec ref.invalidate()',
    'Présenter devant 10 000 codeurs',
  ];
}

// FutureProvider autoDispose qui dépend d'un délai configurable
final tachesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final delai = ref.watch(delaiProvider);
  return chargerTaches(delai);
});

// Provider pour le délai (1 = rapide, 4 = lent)
final delaiProvider = StateProvider<int>((ref) => 1);

class DemoRiverpodFuture extends ConsumerWidget {
  const DemoRiverpodFuture({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delaiSecondes = ref.watch(delaiProvider);
    final delaiRapide = delaiSecondes == 1;
    final tachesAsync = ref.watch(tachesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FutureProvider - Gestion async'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle pour changer le délai
            SwitchListTile(
              title: Text(
                delaiRapide ? 'Mode rapide (1s)' : 'Mode lent (4s)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Durée du chargement simulé'),
              value: delaiRapide,
              onChanged: (value) {
                ref.read(delaiProvider.notifier).state = value ? 1 : 4;
              },
              activeThumbColor: Colors.deepPurple,
            ),
            const Divider(),

            // Boutons d'action
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _simulerErreur = false;
                    ref.invalidate(tachesProvider);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Charger'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _simulerErreur = true;
                    ref.invalidate(tachesProvider);
                  },
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Simuler erreur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _simulerErreur = false;
                    ref.invalidate(tachesProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rafraîchir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Affichage selon l'état du FutureProvider
            Expanded(
              child: tachesAsync.when(
                // État de chargement
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      SizedBox(height: 16),
                      Text('Chargement des tâches...'),
                    ],
                  ),
                ),
                // État d'erreur avec bouton réessayer
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur : $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _simulerErreur = false;
                          ref.invalidate(tachesProvider);
                        },
                        icon: const Icon(Icons.replay),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                // État de données : affichage de la liste
                data: (taches) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${taches.length} tâches chargées :',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: taches.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(taches[index]),
                              trailing: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
