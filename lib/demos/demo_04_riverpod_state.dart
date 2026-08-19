import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum pour les filtres de tâches
enum TaskFilter { all, completed, pending }

// Filtre actif — chaque changement déclenche un rebuild du widget qui watch
final filterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

// Liste des tâches — état partagé via Riverpod
final tasksProvider = StateProvider<List<String>>((ref) => [
      'Apprendre Flutter',
      'Intégrer Riverpod',
      'Créer une app live',
      'Présenter au meetup',
    ]);

// ConsumerStatefulWidget pour compter les vrais rebuilds du widget
class DemoRiverpodState extends ConsumerStatefulWidget {
  const DemoRiverpodState({super.key});

  @override
  ConsumerState<DemoRiverpodState> createState() => _DemoRiverpodStateState();
}

class _DemoRiverpodStateState extends ConsumerState<DemoRiverpodState> {
  // Compteur de rebuilds — incrémenté à chaque appel de build()
  int _rebuildCount = 0;

  // Couleurs qui tournent à chaque rebuild pour montrer visuellement le rebuild
  static const _indicatorColors = [
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.indigo,
    Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context) {
    // Chaque appel de build = un vrai rebuild Riverpod
    _rebuildCount++;

    // ref.watch — ce widget se reconstruit quand tasks ou filter change
    final tasks = ref.watch(tasksProvider);
    final filter = ref.watch(filterProvider);

    // Filtrage selon le filtre actif
    final filteredTasks = tasks.where((task) {
      switch (filter) {
        case TaskFilter.all:
          return true;
        case TaskFilter.completed:
          return task.startsWith('✓');
        case TaskFilter.pending:
          return !task.startsWith('✓');
      }
    }).toList();

    // Couleur de l'indicateur basée sur le nombre de rebuilds
    final indicatorColor = _indicatorColors[_rebuildCount % _indicatorColors.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod StateProvider'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Indicateur de rebuild + compteur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: indicatorColor.withValues(alpha: 0.15),
            child: Row(
              children: [
                // Pastille colorée qui change à chaque rebuild
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rebuild #$_rebuildCount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: indicatorColor,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // Stats : total et affichées
                Text(
                  '${
                    tasks.length
                  } total, ${filteredTasks.length} affichées',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),

          // Filtres — FilterChip pour choisir le filtre actif
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Toutes'),
                  selected: filter == TaskFilter.all,
                  onSelected: (_) {
                    // ref.read() pour déclencher une mutation (pas de rebuild ici)
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
                    ref.read(filterProvider.notifier).state = TaskFilter.completed;
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Champ de saisie + bouton Ajouter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _AddTaskRow(
              onAdd: (task) {
                // Mutation du state via le notifier
                ref.read(tasksProvider.notifier).state = [
                  ...ref.read(tasksProvider),
                  task,
                ];
              },
            ),
          ),

          const Divider(height: 1),

          // Liste filtrée des tâches
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune tâche dans cette catégorie',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
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
                            // Toggle terminé/pas terminé
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
                            // Suppression d'une tâche
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

// Widget séparé pour le champ de saisie + bouton Ajouter
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
