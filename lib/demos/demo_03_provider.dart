import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ============================================================
// Demo 03 - Provider : Todo List avec Provider
// ============================================================
// Ce fichier démontre les différentes façons de Consommer un Provider :
//   - context.watch()  → rebuild à chaque changement
//   - context.read()   → accès ponctuel SANS rebuild
//   - Consumer<T>      → rebuild ciblé d'un sous-arbre
//   - context.select() → écouter un seul champ de l'état
// ============================================================

// --- Model & ChangeNotifier ---
class TodoModel extends ChangeNotifier {
  final List<String> _todos = [];

  List<String> get todos => List.unmodifiable(_todos);
  int get count => _todos.length;

  void add(String todo) {
    if (todo.trim().isEmpty) return;
    _todos.add(todo.trim());
    notifyListeners();
  }

  void remove(int index) {
    if (index < 0 || index >= _todos.length) return;
    _todos.removeAt(index);
    notifyListeners();
  }

  void toggle(int index) {
    _todos[index] =
        _todos[index].startsWith('✅ ') ? _todos[index].substring(2) : '✅ ${_todos[index]}';
    notifyListeners();
  }
}

// --- Page principale avec Provider ---
class DemoProvider extends StatefulWidget {
  const DemoProvider({super.key});

  @override
  State<DemoProvider> createState() => _DemoProviderState();
}

class _DemoProviderState extends State<DemoProvider> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoModel(),
      child: _DemoProviderView(controller: _controller),
    );
  }
}

class _DemoProviderView extends StatelessWidget {
  final TextEditingController controller;

  const _DemoProviderView({required this.controller});

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // context.watch<T>() : Rebuild CE widget à chaque notifyListeners()
    // ============================================================
    final count = context.watch<TodoModel>().count;

    return Scaffold(
      appBar: AppBar(
        title: Text('Provider - Todo ($count)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ============================================================
          // Section Counter : démonstration context.watch()
          // ============================================================
          Container(
            width: double.infinity,
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'context.watch<TodoModel>().count',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Ce widget rebuild à chaque changement du count',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Divider(),
                // ============================================================
                // Section select : n'écouter qu'UN SEUL champ
                // ============================================================
                _SelectCountWidget(),
              ],
            ),
          ),

          // ============================================================
          // Section Ajout : démonstration context.read()
          // ============================================================
          Container(
            width: double.infinity,
            color: Colors.green.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'context.read<TodoModel>() - Pas de rebuild',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Ajouter une tâche...',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              // TODO DEMO : Change context.read en context.watch
                              // pour montrer la différence
                              controller.clear();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO DEMO : Ajoute un Consumer autour du TextField
                        // pour montrer le rebuild inutile
                        final todoText = controller.text;
                        if (todoText.isNotEmpty) {
                          // context.read() : accès direct SANS s'abonner aux changements
                          context.read<TodoModel>().add(todoText);
                          controller.clear();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ============================================================
          // Section Liste : Consumer<TodoModel> pour rebuild ciblé
          // ============================================================
          Container(
            width: double.infinity,
            color: Colors.orange.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Consumer<TodoModel> - Rebuild ciblé du ListView uniquement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),

          // Consumer<TodoModel> : rebuild UNIQUEMENT ce sous-arbre
          Expanded(
            child: Consumer<TodoModel>(
              builder: (context, model, child) {
                // TODO DEMO : Retire le Consumer et utilise context.watch
                // pour montrer que tout se reconstruit
                if (model.todos.isEmpty) {
                  return child!;
                }

                return ListView.builder(
                  itemCount: model.todos.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(model.todos[index]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => model.toggle(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => model.remove(index),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucune tâche pour le moment',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    Text(
                      'Ajoutez-en une ci-dessus !',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // Footer : Résumé read vs watch vs Consumer vs select
          // ============================================================
          Container(
            width: double.infinity,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(12),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résumé des méthodes :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text('• context.watch()   → rebuild widget entier', style: TextStyle(fontSize: 11)),
                Text('• context.read()    → accès direct, pas de rebuild', style: TextStyle(fontSize: 11)),
                Text('• Consumer<T>       → rebuild ciblé d\'un sous-arbre', style: TextStyle(fontSize: 11)),
                Text('• context.select()  → rebuild si champ spécifique change', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Widget démontrant context.select()
// ============================================================
class _SelectCountWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // select() prend une fonction qui extrait la valeur voulue
    // rebuild QUE si cette valeur spécifique change
    final count = context.select<TodoModel, int>((model) => model.count);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.indigo, size: 20),
          const SizedBox(width: 8),
          Text(
            'context.select() → count = $count',
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
