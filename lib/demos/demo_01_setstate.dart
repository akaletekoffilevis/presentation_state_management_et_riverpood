import 'package:flutter/material.dart';

class DemoSetState extends StatefulWidget {
  const DemoSetState({super.key});

  @override
  State<DemoSetState> createState() => _DemoSetState();
}

class _DemoSetState extends State<DemoSetState> {
  final List<String> _tasks = [];
  final List<bool> _done = [];
  final TextEditingController _controller = TextEditingController();

  int _rebuildCount = 0;
  bool _heavyMode = false;
  bool _colorToggle = false;

  // Couleurs alternées pour l'indicateur de rebuild
  static const Color _colorA = Colors.blue;
  static const Color _colorB = Colors.orange;

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _applySetState(() {
      _tasks.add(text);
      _done.add(false);
    });
    _controller.clear();
  }

  void _removeTask(int index) {
    _applySetState(() {
      _tasks.removeAt(index);
      _done.removeAt(index);
    });
  }

  void _toggleTask(int index) {
    _applySetState(() {
      _done[index] = !_done[index];
    });
  }

  // Applique setState — avec ou sans délai selon le mode
  void _applySetState(VoidCallback fn) {
    if (_heavyMode) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  void _resetCounter() {
    setState(() {
      _rebuildCount = 0;
      _colorToggle = false;
    });
  }

  void _toggleHeavyMode() {
    setState(() {
      _heavyMode = !_heavyMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Demo setState'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Indicateur de rebuild : compteur + couleur ---
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _colorToggle ? _colorB : _colorA,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rebuilds : $_rebuildCount',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: _resetCounter,
                  child: const Text('Reset counter'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // --- Toggle mode lourd (simule un état lourd) ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simuler un état lourd'),
              subtitle: const Text('100ms délai sur setState'),
              value: _heavyMode,
              onChanged: (_) => _toggleHeavyMode(),
            ),

            const Divider(),

            // --- Champ de saisie + bouton Ajouter ---
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

            const SizedBox(height: 8),

            // --- Compteur de tâches ---
            Text(
              '${_tasks.length} tâche(s)',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            // --- Liste de tâches ---
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
