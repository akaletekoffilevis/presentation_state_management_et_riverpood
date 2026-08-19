import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// DEMO 09 : Architecture 3 couches avec Riverpod
// =============================================================================
// TODO DEMO : Monte que chaque couche est indépendante et testable séparément
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

  // TODO DEMO : Monte la couche Data en montrant le FakeApiClient

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

// --- Client API factice ---

class FakeApiClient {
  int _nextId = 4;
  final List<Task> _tasks = [
    Task(id: 1, title: 'Apprendre Riverpod', completed: true),
    Task(id: 2, title: 'Préparer la démo', completed: false),
    Task(id: 3, title: 'Présenter l\'architecture', completed: false),
  ];

  Future<List<Task>> fetchTasks() async {
    // TODO DEMO : Ajoute un delay plus long pour montrer le loading
    await Future.delayed(const Duration(seconds: 1));
    return List.from(_tasks);
  }

  Future<Task> createTask(String title) async {
    // TODO DEMO : Fais planter l'API pour montrer l'erreur et le retry
    await Future.delayed(const Duration(milliseconds: 500));
    final task = Task(id: _nextId++, title: title);
    _tasks.add(task);
    return task;
  }

  Future<bool> deleteTask(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.removeWhere((t) => t.id == id);
    return true;
  }

  Future<Task> toggleTask(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw Exception('Tâche non trouvée');
    _tasks[index] = _tasks[index].copyWith(
      completed: !_tasks[index].completed,
    );
    return _tasks[index];
  }
}

// --- Repository ---

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

class TodoListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final repository = ref.watch(repositoryProvider);
    return repository.getTasks();
  }

  Future<void> addTask(String title) async {
    final repository = ref.watch(repositoryProvider);
    // État de chargement optimiste
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.addTask(title);
      return repository.getTasks();
    });
  }

  Future<void> deleteTask(int id) async {
    final repository = ref.watch(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.removeTask(id);
      return repository.getTasks();
    });
  }

  Future<void> toggleTask(int id) async {
    final repository = ref.watch(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.toggleTask(id);
      return repository.getTasks();
    });
  }

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

class DemoArchitecture extends ConsumerWidget {
  const DemoArchitecture({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todoListProvider);
    final controller = TextEditingController();

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
          // --- Zone d'ajout de tâche ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle tâche',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        ref.read(todoListProvider.notifier).addTask(
                              value.trim(),
                            );
                        controller.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      ref.read(todoListProvider.notifier).addTask(
                            controller.text.trim(),
                          );
                      controller.clear();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // --- Liste des tâches avec gestion AsyncValue ---
          Expanded(
            child: tasksAsync.when(
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
              error: (error, stack) => Center(
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
                    // TODO DEMO : Monte le ref.invalidate pour le retry
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(todoListProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
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

// =============================================================================
// TEST : Comment tester le Notifier
// =============================================================================
//
// TODO DEMO : Ajoute un test unitaire en bas du fichier pour montrer la testabilité
//
// import 'package:flutter_test/flutter_test.dart';
//
// void main() {
//   group('TodoListNotifier', () {
//     test('build charge les tâches initiales', () async {
//       final container = ProviderContainer(
//         overrides: [
//           apiClientProvider.overrideWithValue(FakeApiClient()),
//         ],
//       );
//
//       final tasks = await container.read(todoListProvider.future);
//
//       expect(tasks.length, 3);
//       expect(tasks[0].title, 'Apprendre Riverpod');
//       expect(tasks[0].completed, true);
//
//       container.dispose();
//     });
//
//     test('addTask ajoute une tâche et rafraîchit la liste', () async {
//       final container = ProviderContainer(
//         overrides: [
//           apiClientProvider.overrideWithValue(FakeApiClient()),
//         ],
//       );
//
//       // Attendre le chargement initial
//       await container.read(todoListProvider.future);
//
//       // Ajouter une tâche
//       await container.read(todoListProvider.notifier).addTask('Nouvelle tâche');
//
//       final tasks = container.read(todoListProvider).value;
//       expect(tasks!.length, 4);
//       expect(tasks.last.title, 'Nouvelle tâche');
//
//       container.dispose();
//     });
//
//     test('deleteTask supprime une tâche', () async {
//       final container = ProviderContainer(
//         overrides: [
//           apiClientProvider.overrideWithValue(FakeApiClient()),
//         ],
//       );
//
//       await container.read(todoListProvider.future);
//       await container.read(todoListProvider.notifier).deleteTask(1);
//
//       final tasks = container.read(todoListProvider).value;
//       expect(tasks!.length, 2);
//       expect(tasks.any((t) => t.id == 1), false);
//
//       container.dispose();
//     });
//
//     test('toggleTask inverse le statut completed', () async {
//       final container = ProviderContainer(
//         overrides: [
//           apiClientProvider.overrideWithValue(FakeApiClient()),
//         ],
//       );
//
//       await container.read(todoListProvider.future);
//       await container.read(todoListProvider.notifier).toggleTask(2);
//
//       final tasks = container.read(todoListProvider).value;
//       final toggled = tasks!.firstWhere((t) => t.id == 2);
//       expect(toggled.completed, true);
//
//       container.dispose();
//     });
//   });
// }
