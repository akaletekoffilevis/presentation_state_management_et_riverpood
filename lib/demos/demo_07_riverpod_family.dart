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
// family crée un provider distinct pour chaque ID demandé.
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

// ── StateProvider.autoDispose : la requête de recherche est écartée ────
// quand l'écran n'est plus visible (mémoire libérée automatiquement).
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// ── Track du provider family actif pour l'indicateur ──────────────────
// Map qui surveille quels providers family sont encore en vie
final activeFamilyProviders = Provider<Map<int, bool>>((ref) {
  // Cette map sera mise à jour par les écrans qui utilisent family
  return {};
});

// ── Écran principal ──────────────────────────────────────────────────
class DemoRiverpodFamily extends ConsumerStatefulWidget {
  const DemoRiverpodFamily({super.key});

  @override
  ConsumerState<DemoRiverpodFamily> createState() =>
      _DemoRiverpodFamilyState();
}

class _DemoRiverpodFamilyState extends ConsumerState<DemoRiverpodFamily> {
  final TextEditingController _searchController = TextEditingController();
  // IDs des tâches actuellement consultées (pour l'indicateur)
  final Set<int> _activeTaskIds = {};

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
        actions: [
          // Bouton pour vider le cache de tous les providers family
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Vider le cache',
            onPressed: () {
              // Invalide tous les providers family actifs
              for (final id in _activeTaskIds) {
                ref.invalidate(taskByIdProvider(id));
              }
              setState(() => _activeTaskIds.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache vidé pour tous les providers family'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Indicateur autoDispose actif ───────────────────────────
          if (_activeTaskIds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'autoDispose actif — ${_activeTaskIds.length} provider(s) family en vie',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

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
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // ── Bouton vider le cache (variant détaillée) ─────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _activeTaskIds.isEmpty
                    ? null
                    : () {
                        for (final id in _activeTaskIds) {
                          ref.invalidate(taskByIdProvider(id));
                        }
                        setState(() => _activeTaskIds.clear());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache vidé ! Les providers se rechargeront.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Vider le cache'),
              ),
            ),
          ),
          const SizedBox(height: 8),

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
                      final completed = entry.value['completed'] as bool;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                completed ? Colors.green : Colors.orange,
                            child: Text(
                              '$taskId',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(title),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            // Enregistre l'ID comme actif
                            setState(() => _activeTaskIds.add(taskId));

                            // Navigation vers l'écran de détail
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(
                                  taskId: taskId,
                                  onDispose: () {
                                    setState(() => _activeTaskIds.remove(taskId));
                                  },
                                ),
                              ),
                            );

                            // Quand on revient, si le provider a été invalidé,
                            // il sera rechargé automatiquement
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
class TaskDetailScreen extends ConsumerWidget {
  final int taskId;
  final VoidCallback? onDispose;

  const TaskDetailScreen({super.key, required this.taskId, this.onDispose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // futureProvider.family : on passe taskId → le provider retourne un AsyncValue<Task>
    final taskAsync = ref.watch(taskByIdProvider(taskId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Tâche #$taskId'),
        centerTitle: true,
        actions: [
          // Bouton pour vider le cache de ce provider family spécifique
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Vider le cache de cette tâche',
            onPressed: () {
              ref.invalidate(taskByIdProvider(taskId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cache vidé pour la tâche #$taskId'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
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
