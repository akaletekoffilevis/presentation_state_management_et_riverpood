import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Gestionnaire du stream - simule des données temps réel (type Firebase)
class _StreamManager {
  final StreamController<List<String>> _controller =
      StreamController<List<String>>();
  final List<String> _messages = [];
  Timer? _timer;
  var _counter = 0;

  Stream<List<String>> get stream => _controller.stream;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _counter++;
      _messages.add('Message #$_counter');
      _controller.add(List.from(_messages));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void addMessage(String message) {
    _messages.add(message);
    _controller.add(List.from(_messages));
  }

  void simulateError() {
    _controller.addError(Exception('Erreur simulée depuis le serveur !'));
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

// Provider du gestionnaire - nettoyé automatiquement
final _streamManagerProvider = Provider<_StreamManager>((ref) {
  final manager = _StreamManager();
  ref.onDispose(manager.dispose);
  return manager;
});

// StreamProvider qui expose le stream de données
final streamProvider = StreamProvider<List<String>>((ref) {
  final manager = ref.watch(_streamManagerProvider);
  return manager.stream;
});

// Widget principal de la démo
class DemoRiverpodStream extends ConsumerStatefulWidget {
  const DemoRiverpodStream({super.key});

  @override
  ConsumerState<DemoRiverpodStream> createState() =>
      _DemoRiverpodStreamState();
}

class _DemoRiverpodStreamState extends ConsumerState<DemoRiverpodStream> {
  var _isRunning = false;

  @override
  void initState() {
    super.initState();
    // Démarrage automatique du stream après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_streamManagerProvider).start();
      setState(() => _isRunning = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(streamProvider);
    final manager = ref.read(_streamManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod StreamProvider')),
      body: asyncValue.when(
        // État de chargement initial
        loading: () => const Center(child: CircularProgressIndicator()),
        // État d'erreur
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Erreur : $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => manager.start(),
                  icon: const Icon(Icons.replay),
                  label: const Text('Relancer le stream'),
                ),
              ],
            ),
          ),
        ),
        // État avec données
        data: (messages) => Column(
          children: [
            // En-tête avec compteur de messages reçus
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Text(
                'Messages reçus en temps réel : ${messages.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            // Dernière mise à jour
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dernière mise à jour : ${TimeOfDay.now().format(context)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
            const Divider(height: 1),
            // Liste des messages avec mise à jour automatique
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('En attente de données...'))
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final isNew = index == messages.length - 1;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isNew ? Colors.blue : Colors.grey.shade300,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isNew ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          title: Text(messages[index]),
                          trailing: isNew
                              ? const Icon(Icons.fiber_new, color: Colors.blue)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // Trois boutons d'action empilés
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'error',
            onPressed: () => manager.simulateError(),
            label: const Text('Simuler erreur'),
            icon: const Icon(Icons.error_outline),
            backgroundColor: Colors.red,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () {
              manager.addMessage('Message ajouté manuellement');
            },
            label: const Text('Ajouter message'),
            icon: const Icon(Icons.add_circle_outline),
            backgroundColor: Colors.green,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'toggle',
            onPressed: () {
              if (_isRunning) {
                manager.stop();
              } else {
                manager.start();
              }
              setState(() => _isRunning = !_isRunning);
            },
            label: Text(_isRunning ? 'Arrêter' : 'Démarrer'),
            icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            backgroundColor: _isRunning ? Colors.orange : Colors.blue,
          ),
        ],
      ),
    );
  }
}
