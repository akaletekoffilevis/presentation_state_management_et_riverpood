// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_immutables

import 'package:flutter/material.dart';

// =============================================================================
// DEMO 02 : ChangeNotifier + ListenableBuilder
// =============================================================================
// On utilise ChangeNotifier pour gérer l'état de notre liste de tâches
// et ListenableBuilder pour reconstruire l'UI quand l'état change.
// Pas de Provider ici — on écoute directement le ChangeNotifier.
// =============================================================================

// -----------------------------------------------------------------------------
// Modèle : TodoModel
// -----------------------------------------------------------------------------
// Le modèle étend ChangeNotifier pour notifier les abonnés quand l'état change.
// -----------------------------------------------------------------------------


// TODO DEMO : Ajoute une propriété 'priority' au modèle pour montrer l'extension
// (par exemple : int priority = 0; puis modifie add() pour l'accepter en paramètre)

class TodoModel extends ChangeNotifier {
  // Liste interne des tâches (mutable en interne)
  final List<String> _tasks = [];

  // Liste interne pour tracker les tâches complétées
  final List<bool> _completed = [];

  // Getter non modifiable — empêche la modification directe depuis l'extérieur
  List<String> get tasks => List.unmodifiable(_tasks);
  List<bool> get completed => List.unmodifiable(_completed);

  // Nombre total de tâches
  int get count => _tasks.length;

  // Ajouter une tâche
  void add(String task) {
    if (task.trim().isEmpty) return;
    _tasks.add(task.trim());
    _completed.add(false); // Nouvelle tâche = pas encore complétée

    // TODO DEMO : Modifie notifyListeners() pour montrer que l'UI se met à jour
    // Essaie de commenter la ligne suivante et observe que l'UI ne se met plus à jour
    notifyListeners();
  }

  // Supprimer une tâche par son index
  void remove(int index) {
    if (index < 0 || index >= _tasks.length) return;
    _tasks.removeAt(index);
    _completed.removeAt(index);
    notifyListeners();
  }

  // Inverser l'état complété d'une tâche
  void toggle(int index) {
    if (index < 0 || index >= _tasks.length) return;
    _completed[index] = !_completed[index];
    notifyListeners();
  }
}

// -----------------------------------------------------------------------------
// Widget principal : DemoChangeNotifier
// -----------------------------------------------------------------------------
class DemoChangeNotifier extends StatefulWidget {
  const DemoChangeNotifier({super.key});

  @override
  State<DemoChangeNotifier> createState() => _DemoChangeNotifierState();
}

// -----------------------------------------------------------------------------
// State : _DemoChangeNotifierState
// -----------------------------------------------------------------------------
// On crée le TodoModel dans initState et on le dispose proprement.
// On utilise ListenableBuilder pour écouter les changements du modèle.
// -----------------------------------------------------------------------------


// TODO DEMO : Montre que sans ListenableBuilder, l'UI ne se met pas à jour
// (remplace ListenableBuilder par un simple Column et montre que rien ne bouge)

class _DemoChangeNotifierState extends State<DemoChangeNotifier> {
  late final TodoModel _todoModel;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _todoModel = TodoModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    _todoModel.dispose(); // Important : libère les ressources du ChangeNotifier
    super.dispose();
  }

  void _addTask() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      _todoModel.add(text);
      _controller.clear();
    }
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
          // ---- Compteur en haut ----
          // TODO DEMO : Ajoute un troisième état "en cours de traitement"
          // pour montrer comment le compteur peut refléter plus d'informations
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListenableBuilder(
              listenable: _todoModel,
              builder: (context, child) {
                return Text(
                  'Nombre de tâches : ${_todoModel.count}',
                  style: Theme.of(context).textTheme.headlineSmall,
                );
              },
            ),
          ),

          // ---- Zone de saisie ----
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

          // ---- Liste des tâches ----
          Expanded(
            child: ListenableBuilder(
              listenable: _todoModel,
              builder: (context, child) {
                // Si la liste est vide, afficher un message
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

                // Sinon, afficher la liste avec ListView.builder
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _todoModel.tasks.length,
                  itemBuilder: (context, index) {
                    final task = _todoModel.tasks[index];
                    final isCompleted = _todoModel.completed[index];

                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        // Checkbox pour marquer comme complété
                        leading: Checkbox(
                          value: isCompleted,
                          onChanged: (_) {
                            _todoModel.toggle(index);
                          },
                        ),
                        // Texte de la tâche
                        title: Text(
                          task,
                          style: TextStyle(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isCompleted ? Colors.grey : null,
                          ),
                        ),
                        // Bouton de suppression
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
