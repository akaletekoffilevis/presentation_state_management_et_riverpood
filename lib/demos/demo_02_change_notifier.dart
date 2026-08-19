// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_immutables

import 'package:flutter/material.dart';

// =============================================================================
// DEMO 02 : ChangeNotifier + ListenableBuilder
// =============================================================================

// Modèle de données qui notifie les abonnés quand l'état change
class TodoModel extends ChangeNotifier {
  final List<String> _tasks = [];
  final List<bool> _completed = [];

  List<String> get tasks => List.unmodifiable(_tasks);
  List<bool> get completed => List.unmodifiable(_completed);
  int get count => _tasks.length;

  void add(String task) {
    if (task.trim().isEmpty) return;
    _tasks.add(task.trim());
    _completed.add(false);
    notifyListeners();
  }

  void remove(int index) {
    if (index < 0 || index >= _tasks.length) return;
    _tasks.removeAt(index);
    _completed.removeAt(index);
    notifyListeners();
  }

  void toggle(int index) {
    if (index < 0 || index >= _tasks.length) return;
    _completed[index] = !_completed[index];
    notifyListeners();
  }
}

class DemoChangeNotifier extends StatefulWidget {
  const DemoChangeNotifier({super.key});

  @override
  State<DemoChangeNotifier> createState() => _DemoChangeNotifierState();
}

class _DemoChangeNotifierState extends State<DemoChangeNotifier> {
  late final TodoModel _todoModel;
  final TextEditingController _controller = TextEditingController();

  int _rebuildCount = 0;
  bool _useListenableBuilder = true;

  @override
  void initState() {
    super.initState();
    _todoModel = TodoModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    _todoModel.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      _todoModel.add(text);
      _controller.clear();
    }
  }

  void _incrementRebuild() {
    setState(() {
      _rebuildCount++;
    });
  }

  // Couleur qui change à chaque rebuild
  Color get _indicatorColor {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return colors[_rebuildCount % colors.length];
  }

  Widget _buildTodoList() {
    if (_todoModel.tasks.isEmpty) {
      return Center(
        child: Text(
          'Aucune tâche pour le moment.\nAjoutez-en une !',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _todoModel.tasks.length,
      itemBuilder: (context, index) {
        final task = _todoModel.tasks[index];
        final isCompleted = _todoModel.completed[index];

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Checkbox(
              value: isCompleted,
              onChanged: (_) {
                _todoModel.toggle(index);
              },
            ),
            title: Text(
              task,
              style: TextStyle(
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: isCompleted ? Colors.grey : null,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _todoModel.remove(index);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demo 02 : ChangeNotifier'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Panneau de contrôle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Compteur de rebuilds
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _indicatorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Rebuilds : $_rebuildCount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Toggle sans ListenableBuilder
                SwitchListTile(
                  title: Text('Sans ListenableBuilder'),
                  subtitle: Text(
                    _useListenableBuilder
                        ? 'ListenableBuilder actif — l\'UI se met à jour'
                        : 'PAS de ListenableBuilder — l\'UI ne bouge pas !',
                    style: TextStyle(
                      color: _useListenableBuilder ? Colors.green : Colors.red,
                    ),
                  ),
                  value: !_useListenableBuilder,
                  onChanged: (value) {
                    setState(() {
                      _useListenableBuilder = !value;
                      _rebuildCount = 0;
                    });
                  },
                ),
                // Bouton reset
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _rebuildCount = 0;
                    });
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Reset compteur'),
                ),
                Divider(),
              ],
            ),
          ),

          // Zone de saisie
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Nouvelle tâche',
                      hintText: 'Entrez une tâche...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addTask,
                  icon: Icon(Icons.add),
                  label: Text('Ajouter'),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Liste des tâches — avec ou sans ListenableBuilder
          Expanded(
            child: _useListenableBuilder
                ? ListenableBuilder(
                    listenable: _todoModel,
                    builder: (context, child) {
                      _incrementRebuild();
                      return _buildTodoList();
                    },
                  )
                : _buildTodoList(),
          ),
        ],
      ),
    );
  }
}
