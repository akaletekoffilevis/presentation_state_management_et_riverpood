import 'package:flutter/material.dart';

// =============================================================================
// DEMO 01 : setState — Todo List
// =============================================================================
// Objectif : Montrer que setState déclenche un rebuild de l'arbre widget.
// =============================================================================
// TODO DEMO : Modifie la couleur du Container en rouge pour montrer le rebuild
// TODO DEMO : Ajoute une tâche pour montrer setState en action
// TODO DEMO : Supprime le setState et montre que l'UI ne se met pas à jour
// =============================================================================

class DemoSetState extends StatefulWidget {
  const DemoSetState({super.key});

  @override
  State<DemoSetState> createState() => _DemoSetState();
}

class _DemoSetState extends State<DemoSetState> {
  // ---------------------------------------------------------------------------
  // ÉTAT : La seule source de vérité — tout est dans cette liste.
  // ---------------------------------------------------------------------------
  final List<String> _tasks = [];
  final List<bool> _done = [];
  final TextEditingController _controller = TextEditingController();

  // ---------------------------------------------------------------------------
  // AJOUTER UNE TÂCHE
  // ---------------------------------------------------------------------------
  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      // TODO DEMO : Monte que sans setState, l'UI ne se met PAS à jour
      _tasks.add(text);
      _done.add(false);
    });

    _controller.clear();
  }

  // ---------------------------------------------------------------------------
  // SUPPRIMER UNE TÂCHE
  // ---------------------------------------------------------------------------
  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      _done.removeAt(index);
    });
  }

  // ---------------------------------------------------------------------------
  // COCHER / DÉCOCHER UNE TÂCHE
  // ---------------------------------------------------------------------------
  void _toggleTask(int index) {
    setState(() {
      _done[index] = !_done[index];
    });
  }

  // ---------------------------------------------------------------------------
  // CONSTRUCTION DE L'INTERFACE
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // TODO DEMO : Change la couleur du Container en rouge pour montrer le rebuild
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Demo setState'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- CHAMP DE SAISIE + BOUTON AJOUTER --------------------------------
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nouvelle tâche...',
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Ajouter'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- COMPTEUR DE TÂCHES ------------------------------------------------
            // TODO DEMO : Ajoute une tâche pour montrer le compteur qui se met à jour
            Text(
              '${_tasks.length} tâche(s)',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            // --- LISTE DE TÂCHES ---------------------------------------------------
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(child: Text('Aucune tâche'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Checkbox(
                            value: _done[index],
                            onChanged: (_) => _toggleTask(index),
                          ),
                          title: Text(
                            _tasks[index],
                            style: TextStyle(
                              decoration: _done[index]
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeTask(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
