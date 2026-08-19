import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodoModel extends ChangeNotifier {
  final List<_TodoItem> _items = [];

  List<_TodoItem> get items => List.unmodifiable(_items);

  int get length => _items.length;

  void add(String title) {
    _items.add(_TodoItem(title: title));
    notifyListeners();
  }

  void toggle(int index) {
    _items[index].done = !_items[index].done;
    notifyListeners();
  }

  void remove(int index) {
    _items.removeAt(index);
    notifyListeners();
  }
}

class _TodoItem {
  String title;
  bool done;
  _TodoItem({required this.title, this.done = false});
}

class DemoProvider extends StatefulWidget {
  const DemoProvider({super.key});

  @override
  State<DemoProvider> createState() => _DemoProviderState();
}

class _DemoProviderState extends State<DemoProvider> {
  // Contrôles pour afficher/masquer chaque section
  bool _showWatch = true;
  bool _showRead = true;
  bool _showConsumer = true;
  bool _showSelect = true;

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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Demo Provider'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // === PANNEAU DE CONTRÔLE ===
            _buildControlPanel(),

            const Divider(height: 1),

            // === SAISIE DE TODO ===
            _buildTodoInput(),

            const Divider(height: 1),

            // === LISTE DES TODOS ===
            Expanded(
              child: Consumer<TodoModel>(
                builder: (context, model, _) {
                  if (model.items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune tâche. Ajoutez-en une !',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: model.items.length,
                    itemBuilder: (context, index) {
                      final item = model.items[index];
                      return ListTile(
                        leading: Checkbox(
                          value: item.done,
                          onChanged: (_) => model.toggle(index),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => model.remove(index),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // === SECTIONS D'AFFICHAGE (watch/read/Consumer/select) ===
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      if (_showWatch) _WatchSection(),
                      if (_showRead) _ReadSection(),
                      if (_showConsumer) _ConsumerSection(),
                      if (_showSelect) _SelectSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ToggleButton(
            label: 'watch',
            active: _showWatch,
            onTap: () => setState(() => _showWatch = !_showWatch),
          ),
          _ToggleButton(
            label: 'read',
            active: _showRead,
            onTap: () => setState(() => _showRead = !_showRead),
          ),
          _ToggleButton(
            label: 'Consumer',
            active: _showConsumer,
            onTap: () => setState(() => _showConsumer = !_showConsumer),
          ),
          _ToggleButton(
            label: 'select',
            active: _showSelect,
            onTap: () => setState(() => _showSelect = !_showSelect),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Ajouter une tâche...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _addTodo(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _addTodo,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<TodoModel>().add(text);
      _controller.clear();
    }
  }
}

// === BOUTON TOGGLE ===
class _ToggleButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// === SECTION AVEC context.watch() ===
class _WatchSection extends StatefulWidget {
  @override
  State<_WatchSection> createState() => _WatchSectionState();
}

class _WatchSectionState extends State<_WatchSection> {
  int _rebuildCount = 0;
  late Color _indicatorColor;

  @override
  Widget build(BuildContext context) {
    // context.watch<TodoModel>() : reconstruit à chaque notifyListeners()
    final model = context.watch<TodoModel>();
    _rebuildCount++;
    _indicatorColor = Colors.primaries[_rebuildCount % Colors.primaries.length];

    return _DemoCard(
      title: 'context.watch()',
      subtitle: 'Écoute les changements du modèle',
      rebuildCount: _rebuildCount,
      indicatorColor: _indicatorColor,
      child: Text('Nombre de tâches : ${model.items.length}'),
    );
  }
}

// === SECTION AVEC context.read() ===
class _ReadSection extends StatefulWidget {
  @override
  State<_ReadSection> createState() => _ReadSectionState();
}

class _ReadSectionState extends State<_ReadSection> {
  int _rebuildCount = 0;
  late Color _indicatorColor;

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;
    _indicatorColor = Colors.primaries[_rebuildCount % Colors.primaries.length];

    return _DemoCard(
      title: 'context.read()',
      subtitle: 'Accès unique, sans rebuild',
      rebuildCount: _rebuildCount,
      indicatorColor: _indicatorColor,
      child: ElevatedButton(
        onPressed: () {
          // read() ne déclenche PAS de rebuild du widget parent
          final model = context.read<TodoModel>();
          model.add('Ajouté via read()');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche ajoutée via context.read()'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: const Text('Ajouter via read()'),
      ),
    );
  }
}

// === SECTION AVEC Consumer<TodoModel> ===
class _ConsumerSection extends StatefulWidget {
  @override
  State<_ConsumerSection> createState() => _ConsumerSectionState();
}

class _ConsumerSectionState extends State<_ConsumerSection> {
  int _rebuildCount = 0;
  late Color _indicatorColor;

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoModel>(
      builder: (context, model, child) {
        _rebuildCount++;
        _indicatorColor =
            Colors.primaries[_rebuildCount % Colors.primaries.length];

        return _DemoCard(
          title: 'Consumer<TodoModel>',
          subtitle: 'Reconstruit uniquement son builder',
          rebuildCount: _rebuildCount,
          indicatorColor: _indicatorColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tâches terminées : '
                  '${model.items.where((t) => t.done).length}/${model.items.length}'),
              const SizedBox(height: 4),
              child!, // Le child est la ListView des tâches terminées
            ],
          ),
        );
      },
      child: const Text('Widget static (child) — pas de rebuild ici'),
    );
  }
}

// === SECTION AVEC context.select() ===
class _SelectSection extends StatefulWidget {
  @override
  State<_SelectSection> createState() => _SelectSectionState();
}

class _SelectSectionState extends State<_SelectSection> {
  int _rebuildCount = 0;
  late Color _indicatorColor;

  @override
  Widget build(BuildContext context) {
    // select() ne reconstruit QUE si la valeur sélectionnée change
    final doneCount = context.select<TodoModel, int>(
      (model) => model.items.where((t) => t.done).length,
    );

    _rebuildCount++;
    _indicatorColor = Colors.primaries[_rebuildCount % Colors.primaries.length];

    return _DemoCard(
      title: 'context.select()',
      subtitle: 'Reconstruit si la valeur sélectionnée change',
      rebuildCount: _rebuildCount,
      indicatorColor: _indicatorColor,
      child: Text('Terminées : $doneCount'),
    );
  }
}

// === CARTE DE DÉMONSTRATION ===
class _DemoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int rebuildCount;
  final Color indicatorColor;
  final Widget child;

  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.rebuildCount,
    required this.indicatorColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rebuild #$rebuildCount',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
