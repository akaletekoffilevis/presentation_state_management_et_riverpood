import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// DEMO 09 : Architecture 3 couches avec Riverpod
// =============================================================================

// =============================================================================
// === COUCHE DATA ============================================================
// =============================================================================

// --- Modèle de données ---

class Task {
  final int id;
  final String title;
  final bool completed;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// --- Client API factice avec delays simulés ---

class FakeApiClient {
  int _nextId = 4;
  final List<Task> _tasks = [
    Task(id: 1, title: 'Apprendre Riverpod', completed: true),
    Task(id: 2, title: 'Préparer la démo', completed: false),
    Task(id: 3, title: 'Présenter l\'architecture', completed: false),
  ];

  // Booléen pour simuler des erreurs API depuis l'UI
  bool simulateError = false;

  Future<List<Task>> fetchTasks() async {
    await Future.delayed(const Duration(seconds: 1));
    if (simulateError) {
      throw Exception('Erreur simulée : impossible de charger les tâches');
    }
    return List.from(_tasks);
  }

  Future<Task> createTask(String title) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (simulateError) {
      throw Exception('Erreur simulée : impossible de créer la tâche');
    }
    final task = Task(id: _nextId++, title: title);
    _tasks.add(task);
    return task;
  }

  Future<bool> deleteTask(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (simulateError) {
      throw Exception('Erreur simulée : impossible de supprimer la tâche');
    }
    _tasks.removeWhere((t) => t.id == id);
    return true;
  }

  Future<Task> toggleTask(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (simulateError) {
      throw Exception('Erreur simulée : impossible de modifier la tâche');
    }
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw Exception('Tâche non trouvée');
    _tasks[index] = _tasks[index].copyWith(
      completed: !_tasks[index].completed,
    );
    return _tasks[index];
  }
}

// --- Repository : abstraction au-dessus du client API ---

class TaskRepository {
  final FakeApiClient _apiClient;

  TaskRepository(this._apiClient);

  Future<List<Task>> getTasks() => _apiClient.fetchTasks();

  Future<Task> addTask(String title) => _apiClient.createTask(title);

  Future<bool> removeTask(int id) => _apiClient.deleteTask(id);

  Future<Task> toggleTask(int id) => _apiClient.toggleTask(id);
}

// --- Providers de la couche Data ---

final apiClientProvider = Provider<FakeApiClient>((ref) {
  return FakeApiClient();
});

final repositoryProvider = Provider<TaskRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TaskRepository(apiClient);
});

// =============================================================================
// === COUCHE DOMAIN / APPLICATION ============================================
// =============================================================================

// Notifier gérant l'état asynchrone de la liste de tâches
class TodoListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final repository = ref.watch(repositoryProvider);
    return repository.getTasks();
  }

  // Ajoute une tâche puis recharge la liste
  Future<void> addTask(String title) async {
    final repository = ref.watch(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.addTask(title);
      return repository.getTasks();
    });
  }

  // Supprime une tâche puis recharge la liste
  Future<void> deleteTask(int id) async {
    final repository = ref.watch(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.removeTask(id);
      return repository.getTasks();
    });
  }

  // Inverse l'état completed d'une tâche puis recharge la liste
  Future<void> toggleTask(int id) async {
    final repository = ref.watch(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.toggleTask(id);
      return repository.getTasks();
    });
  }

  // Force le rechargement via invalidation
  void refresh() {
    ref.invalidateSelf();
  }
}

final todoListProvider =
    AsyncNotifierProvider<TodoListNotifier, List<Task>>(
  TodoListNotifier.new,
);

// =============================================================================
// === COUCHE PRÉSENTATION ====================================================
// =============================================================================

class DemoArchitecture extends ConsumerStatefulWidget {
  const DemoArchitecture({super.key});

  @override
  ConsumerState<DemoArchitecture> createState() => _DemoArchitectureState();
}

class _DemoArchitectureState extends ConsumerState<DemoArchitecture> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Envoie une tâche via le notifier
  void _submitTask() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(todoListProvider.notifier).addTask(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Accès au client API pour le bouton simulation d'erreur
    final apiClient = ref.watch(apiClientProvider);
    final tasksAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Architecture 3 couches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(todoListProvider),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Indicateur couche Data ---
          Container(
            width: double.infinity,
            color: Colors.blue.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              'COUCHE DATA — FakeApiClient, TaskRepository, Providers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 12,
              ),
            ),
          ),
          // --- Indicateur couche Domain ---
          Container(
            width: double.infinity,
            color: Colors.green.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              'COUCHE DOMAIN — TodoListNotifier (AsyncNotifier)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 12,
              ),
            ),
          ),
          // --- Indicateur couche Presentation ---
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              'COUCHE PRÉSENTATION — ConsumerWidget, AsyncValue.when',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
                fontSize: 12,
              ),
            ),
          ),

          const Divider(height: 1),

          // --- Boutons d'action ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle tâche',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submitTask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _submitTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          // Boutons de simulation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Active/désactive la simulation d'erreur côté API
                      apiClient.simulateError = !apiClient.simulateError;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            apiClient.simulateError
                                ? 'Mode erreur activé — les prochaines requêtes vont échouer'
                                : 'Mode erreur désactivé — les requêtes fonctionnent normalement',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      apiClient.simulateError
                          ? Icons.error
                          : Icons.check_circle,
                      color: apiClient.simulateError ? Colors.red : Colors.green,
                    ),
                    label: Text(
                      apiClient.simulateError
                          ? 'Désactiver erreur'
                          : 'Simuler erreur API',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.invalidate(todoListProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rafraîchir'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),

          // --- Liste des tâches avec gestion AsyncValue ---
          Expanded(
            child: tasksAsync.when(
              // Affichage pendant le chargement
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des tâches...'),
                  ],
                ),
              ),
              // Affichage en cas d'erreur
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur : $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(todoListProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              // Affichage de la liste de tâches
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune tâche. Ajoutez-en une !',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      leading: Checkbox(
                        value: task.completed,
                        onChanged: (_) {
                          ref.read(todoListProvider.notifier).toggleTask(
                                task.id,
                              );
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completed ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${task.id} • Créée le ${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          ref.read(todoListProvider.notifier).deleteTask(
                                task.id,
                              );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
