import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO DEMO : Ajoute un nouveau filtre 'Favoris' pour montrer la facilité d'extension
enum TaskFilter { all, completed, pending }

// TODO DEMO : Change le filtre et montre que seul le ListView se reconstruit
final filterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

// Liste des tâches
final tasksProvider = StateProvider<List<String>>((ref) => [
      'Apprendre Flutter',
      'Intégrer Riverpod',
      'Créer une app live',
      'Présenter au meetup',
    ]);

class DemoRiverpodState extends ConsumerWidget {
  const DemoRiverpodState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch rebuild le widget quand le provider change
    final tasks = ref.watch(tasksProvider);
    final filter = ref.watch(filterProvider);

    // TODO DEMO : Monte que ref.read dans build ne déclenche pas de rebuild
    final currentFilter = ref.read(filterProvider);
    debugPrint('Filtre actuel (read) : $currentFilter');

    final filteredTasks = tasks.where((task) {
      switch (filter) {
        case TaskFilter.all:
          return true;
        // TODO DEMO : Ajoute un StateProvider<bool> pour afficher/masquer les terminées
        case TaskFilter.completed:
          return task.startsWith('✓');
        case TaskFilter.pending:
          return !task.startsWith('✓');
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod StateProvider'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Compteur de tâches
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${tasks.length} tâches au total — '
              '${filteredTasks.length} affichées',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          // Filtres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Toutes'),
                  selected: filter == TaskFilter.all,
                  onSelected: (_) {
                    // ref.read() pour déclencher une action (pas de rebuild)
                    ref.read(filterProvider.notifier).state = TaskFilter.all;
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('En cours'),
                  selected: filter == TaskFilter.pending,
                  onSelected: (_) {
                    ref.read(filterProvider.notifier).state = TaskFilter.pending;
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Terminées'),
                  selected: filter == TaskFilter.completed,
                  onSelected: (_) {
                    ref.read(filterProvider.notifier).state =
                        TaskFilter.completed;
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Champ de saisie + bouton d'ajout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _AddTaskRow(
              onAdd: (task) {
                ref.read(tasksProvider.notifier).state = [
                  ...ref.read(tasksProvider),
                  task,
                ];
              },
            ),
          ),

          const Divider(),

          // Liste filtrée
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final isDone = task.startsWith('✓');
                final displayText =
                    isDone ? task.substring(2).trim() : task;

                return ListTile(
                  leading: Checkbox(
                    value: isDone,
                    onChanged: (_) {
                      final current = ref.read(tasksProvider);
                      final updated = List<String>.from(current);
                      final originalIndex = current.indexOf(task);

                      if (isDone) {
                        updated[originalIndex] = displayText;
                      } else {
                        updated[originalIndex] = '✓ $displayText';
                      }

                      ref.read(tasksProvider.notifier).state = updated;
                    },
                  ),
                  title: Text(
                    displayText,
                    style: TextStyle(
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      final current = ref.read(tasksProvider);
                      ref.read(tasksProvider.notifier).state =
                          current.where((t) => t != task).toList();
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

// Widget séparé pour le champ de saisie
class _AddTaskRow extends StatefulWidget {
  final ValueChanged<String> onAdd;

  const _AddTaskRow({required this.onAdd});

  @override
  State<_AddTaskRow> createState() => _AddTaskRowState();
}

class _AddTaskRowState extends State<_AddTaskRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Nouvelle tâche...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => _addTask(value),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _addTask(_controller.text),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  void _addTask(String text) {
    if (text.trim().isNotEmpty) {
      widget.onAdd(text.trim());
      _controller.clear();
    }
  }
}
