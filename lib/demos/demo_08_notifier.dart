import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Modèle de données
// ──────────────────────────────────────────────────────────────────────────────

class Task {
  final int id;
  final String title;
  final bool completed;

  const Task({
    required this.id,
    required this.title,
    this.completed = false,
  });

  // Copie avec modification partielle
  Task copyWith({int? id, String? title, bool? completed}) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Notifier — logique métier CRUD
// ──────────────────────────────────────────────────────────────────────────────

// TODO DEMO : Ajoute une méthode 'reorder' au Notifier pour réorganiser les tâches
class TodoNotifier extends Notifier<List<Task>> {
  // Compteur d'auto-incrémentation pour les IDs
  int _nextId = 1;

  @override
  List<Task> build() {
    // État initial : liste vide
    return [];
  }

  // Ajouter une tâche
  void add(String title) {
    state = [
      ...state,
      Task(id: _nextId++, title: title),
    ];
  }

  // Supprimer une tâche par ID
  void remove(int id) {
    state = state.where((task) => task.id != id).toList();
  }

  // Basculer le statut terminé / non terminé
  void toggle(int id) {
    state = [
      for (final task in state)
        if (task.id == id) task.copyWith(completed: !task.completed) else task,
    ];
  }

  // Modifier le titre d'une tâche
  // TODO DEMO : Ajoute un champ 'priority' au Task et modifie le Notifier
  void edit(int id, String newTitle) {
    state = [
      for (final task in state)
        if (task.id == id) task.copyWith(title: newTitle) else task,
    ];
  }

  // Supprimer toutes les tâches terminées
  void clearCompleted() {
    state = state.where((task) => !task.completed).toList();
  }
}

// TODO DEMO : Monte que le Notifier est testable sans contexte Flutter

// Provider global du Notifier
final todoProvider = NotifierProvider<TodoNotifier, List<Task>>(TodoNotifier.new);

// Filtre actif : 'all' | 'active' | 'completed'
final filterProvider = StateProvider<String>((ref) => 'all');

// ──────────────────────────────────────────────────────────────────────────────
// UI — ConsumerWidget
// ──────────────────────────────────────────────────────────────────────────────

class DemoNotifier extends ConsumerWidget {
  const DemoNotifier({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Réactivité via ref.watch
    final tasks = ref.watch(todoProvider);
    final filter = ref.watch(filterProvider);

    // Filtrage des tâches selon le filtre actif
    final filteredTasks = tasks.where((task) {
      switch (filter) {
        case 'active':
          return !task.completed;
        case 'completed':
          return task.completed;
        default:
          return true;
      }
    }).toList();

    // Statistiques
    final activeCount = tasks.where((t) => !t.completed).length;
    final completedCount = tasks.where((t) => t.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NotifierProvider — CRUD complet'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Champ de saisie + bouton Ajouter ──
          _AddTaskRow(
            onAdd: (title) {
              ref.read(todoProvider.notifier).add(title);
            },
          ),

          // ── Filtres ──
          _FilterRow(
            currentFilter: filter,
            onFilterChanged: (value) {
              ref.read(filterProvider.notifier).state = value;
            },
          ),

          // ── Liste des tâches ──
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune tâche',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _TaskTile(
                        task: task,
                        onToggle: () {
                          ref.read(todoProvider.notifier).toggle(task.id);
                        },
                        onDelete: () {
                          ref.read(todoProvider.notifier).remove(task.id);
                        },
                        onEdit: (newTitle) {
                          ref.read(todoProvider.notifier).edit(task.id, newTitle);
                        },
                      );
                    },
                  ),
          ),

          // ── Statistiques ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '$activeCount actives, $completedCount terminées',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          // ── Bouton Supprimer les terminées ──
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: completedCount == 0
                  ? null
                  : () {
                      ref.read(todoProvider.notifier).clearCompleted();
                    },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Supprimer les terminées'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
              ),
            ),
          ),

          // TODO DEMO : Ajoute un 'undo' avec ref.invalidateSelf()
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sous-composants
// ──────────────────────────────────────────────────────────────────────────────

class _AddTaskRow extends StatefulWidget {
  final ValueChanged<String> onAdd;

  const _AddTaskRow({required this.onAdd});

  @override
  State<_AddTaskRow> createState() => _AddTaskRowState();
}

class _AddTaskRowState extends State<_AddTaskRow> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAdd(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Nouvelle tâche…',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const _FilterRow({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FilterChip(
          label: 'All',
          selected: currentFilter == 'all',
          onTap: () => onFilterChanged('all'),
        ),
        _FilterChip(
          label: 'Active',
          selected: currentFilter == 'active',
          onTap: () => onFilterChanged('active'),
        ),
        _FilterChip(
          label: 'Completed',
          selected: currentFilter == 'completed',
          onTap: () => onFilterChanged('completed'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la tâche'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                onEdit(newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          fontSize: 16,
          decoration: task.completed ? TextDecoration.lineThrough : null,
          color: task.completed ? Colors.grey : Colors.black,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: onDelete,
      ),
      onTap: () => _showEditDialog(context),
    );
  }
}
