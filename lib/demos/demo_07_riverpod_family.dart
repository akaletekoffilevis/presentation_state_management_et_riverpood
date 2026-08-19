import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Modèle de données ────────────────────────────────────────────────
class Task {
  final int id;
  final String title;
  final String description;
  final bool completed;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
  });
}

// ── Source de données factice (simulation d'un backend) ───────────────
final fakeTaskDataSource = <int, Map<String, dynamic>>{
  1: {
    'id': 1,
    'title': 'Configurer le projet Flutter',
    'description':
        'Initialiser le projet, ajouter les dépendances et configurer Riverpod.',
    'completed': true,
  },
  2: {
    'id': 2,
    'title': 'Implémenter l\'authentification',
    'description':
        'Créer les écrans de connexion et d\'inscription avec validation.',
    'completed': false,
  },
  3: {
    'id': 3,
    'title': 'Créer le thème de l\'application',
    'description':
        'Définir les couleurs, la typographie et les styles globaux.',
    'completed': true,
  },
  4: {
    'id': 4,
    'title': 'Développer l\'écran des paramètres',
    'description':
        'Permettre à l\'utilisateur de modifier ses préférences et son profil.',
    'completed': false,
  },
  5: {
    'id': 5,
    'title': 'Ajouter les notifications push',
    'description':
        'Intégrer Firebase Cloud Messaging pour les notifications en temps réel.',
    'completed': false,
  },
  6: {
    'id': 6,
    'title': 'Écrire les tests unitaires',
    'description':
        'Couvrir les providers et les utilitaires avec des tests unitaires.',
    'completed': false,
  },
};

// ── FutureProvider.family : récupère une tâche par son ID ─────────────
// Le provider prend un entier (l'ID) et retourne un Future<Task>.
// family crée un provider distinct pour chaque ID demandé.
// TODO DEMO : Ouvre 2 tâches différentes et montre que family crée 2 providers séparés
final taskByIdProvider = FutureProvider.family<Task, int>((ref, taskId) async {
  // Simulation d'un délai réseau
  await Future.delayed(const Duration(milliseconds: 800));

  final data = fakeTaskDataSource[taskId];
  if (data == null) {
    throw Exception('Tâche #$taskId introuvable');
  }

  return Task(
    id: data['id'] as int,
    title: data['title'] as String,
    description: data['description'] as String,
    completed: data['completed'] as bool,
  );
});

// TODO DEMO : Modifie autoDispose et montre que le cache est vidé en quittant l'écran
// StateProvider avec autoDispose : la requête de recherche est écartée
// quand l'écran n'est plus visible (mémoire libérée automatiquement).
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// ── Écran principal ──────────────────────────────────────────────────
class DemoRiverpodFamily extends ConsumerStatefulWidget {
  const DemoRiverpodFamily({super.key});

  @override
  ConsumerState<DemoRiverpodFamily> createState() => _DemoRiverpodFamilyState();
}

class _DemoRiverpodFamilyState extends ConsumerState<DemoRiverpodFamily> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écoute la requête de recherche depuis le StateProvider autoDispose
    final searchQuery = ref.watch(searchQueryProvider);

    // Filtre les tâches en fonction de la recherche
    final filteredTasks = fakeTaskDataSource.entries
        .where(
          (entry) =>
              (entry.value['title'] as String)
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()),
        )
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod family + autoDispose'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Champ de recherche ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une tâche…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // Bouton pour effacer le texte
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // Met à jour le StateProvider autoDispose
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // ── Liste des tâches filtrées ─────────────────────────────
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune tâche trouvée',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final entry = filteredTasks[index];
                      final taskId = entry.key;
                      final title = entry.value['title'] as String;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('$taskId'),
                          ),
                          title: Text(title),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navigation vers l'écran de détail
                            // La family provider créera un provider dédié
                            // pour cet ID précis
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskDetailScreen(taskId: taskId),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Écran de détail d'une tâche ──────────────────────────────────────
// Utilise FutureProvider.family<Task, int> avec l'ID de la tâche.
// Chaque tâche ouverte reçoit son propre provider (grâce à family).
// TODO DEMO : Ajoute keepAlive pour garder les données en cache 30 secondes
class TaskDetailScreen extends ConsumerWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // futureProvider.family : on passe taskId → le provider retourne un AsyncValue<Task>
    // TODO DEMO : Modifie le paramètre de family et montre le rechargement
    final taskAsync = ref.watch(taskByIdProvider(taskId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Tâche #$taskId'),
        centerTitle: true,
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Erreur : $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (task) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Titre ────────────────────────────────────────────
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              // ── Badge d'état ─────────────────────────────────────
              Chip(
                label: Text(
                  task.completed ? 'Terminée' : 'En cours',
                  style: TextStyle(
                    color: task.completed ? Colors.white : Colors.black87,
                  ),
                ),
                backgroundColor:
                    task.completed ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 20),

              // ── Description ──────────────────────────────────────
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const Spacer(),

              // ── Bouton de bascule ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Simulation : inverse le statut dans la source factice
                    fakeTaskDataSource[taskId]!['completed'] =
                        !(fakeTaskDataSource[taskId]!['completed'] as bool);

                    // Invalide le provider family pour forcer le rechargement
                    ref.invalidate(taskByIdProvider(taskId));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Statut de la tâche #$taskId mis à jour',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(
                    task.completed
                        ? Icons.replay
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    task.completed ? 'Marquer en cours' : 'Marquer terminée',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
