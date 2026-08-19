# Riverpod Avancé — Types de Providers, Ref, Modificateurs

## Navigation
- ← [Chapitre précédent : Introduction à Riverpod](03-introduction-riverpod.md)
- → [Chapitre suivant : Riverpod Expert](05-riverpod-expert.md)

---

## Chapitre 9 : Les Types de Providers (Riverpod 2.x)

### Cours

Riverpod propose différentes « boîtes » pour stocker des données. Le type de provider que tu choisis dépend de la complexité de ton état. Voici les principaux.

---

### 1. Provider — Valeur constante / Injection de dépendances

`Provider` sert à injecter un service ou une valeur qui ne change jamais pendant l'exécution de l'application. C'est l'outil idéal pour un client HTTP, un repository ou une configuration.

```dart
final apiClientProvider = Provider((ref) => ApiClient(baseUrl: 'https://api.example.com'));

final repositoryProvider = Provider((ref) => UserRepository(ref.watch(apiClientProvider)));
```

> **Analogie :** « C'est comme un réfrigérateur — on y range une chose et elle ne change pas. »

---

### 2. StateProvider — Valeur simple mutable

`StateProvider` est adapté pour un état simple (int, bool, String, Enum). Parfait pour un compteur, un filtre de recherche, ou un onglet sélectionné.

```dart
final counterProvider = StateProvider<int>((ref) => 0);
final filterProvider = StateProvider<String>((ref) => 'Tout');

// Modifier depuis l'interface :
ref.read(counterProvider.notifier).state++;
ref.read(filterProvider.notifier).state = 'Actif';
```

> **Analogie :** « C'est comme un interrupteur — on peut l'allumer ou l'éteindre. »

---

### 3. FutureProvider — Opération asynchrone

`FutureProvider` est conçu pour gérer un Future (appel API, lecture en base de données). Il expose automatiquement un `AsyncValue` contenant trois états possibles : **Loading**, **Data** et **Error**.

```dart
final userProvider = FutureProvider<User>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.fetchCurrentUser();
});

// Dans l'interface :
final userAsync = ref.watch(userProvider);
return userAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => Text('Erreur: $err'),
  data: (user) => Text('Bonjour, ${user.name}!'),
);
```

**`AsyncValue.when()`** agit comme un « switch » qui gère les 3 états possibles de l'opération asynchrone.

---

### 4. StreamProvider — Flux de données en temps réel

`StreamProvider` est conçu pour les données en continu : Firebase, WebSockets, ou tout autre flux.

```dart
final messagesProvider = StreamProvider<List<Message>>((ref) {
  return FirebaseFirestore.instance.collection('messages').snapshots()
    .map((snap) => snap.docs.map((d) => Message.fromFirestore(d)).toList());
});
```

---

### 5. NotifierProvider — Logique métier complexe

C'est le standard de Riverpod 2.x pour la logique métier avec plusieurs méthodes de mutation.

```dart
class CartNotifier extends Notifier<List<Item>> {
  @override
  List<Item> build() => [];

  void add(Item item) => state = [...state, item];
  void remove(Item item) => state = state.where((i) => i != item).toList();
  void clear() => state = [];
}

final cartProvider = NotifierProvider<CartNotifier, List<Item>>(CartNotifier.new);
```

---

### Guide de décision rapide

| Besoin | Provider à utiliser |
|--------|---------------------|
| Services / dépendances | `Provider` |
| Valeurs simples (int, bool, String) | `StateProvider` |
| Données asynchrones (API) | `FutureProvider` |
| Logique complexe avec plusieurs mutations | `NotifierProvider` |

### Checklist
- [ ] Je sais quand utiliser Provider vs StateProvider
- [ ] Je comprends FutureProvider et AsyncValue
- [ ] Je sais ce qu'est un StreamProvider
- [ ] Je comprends NotifierProvider

---

## Chapitre 10 : Ref — watch, read, listen, invalidate

### Cours

`Ref` est le « télécommande » qui permet d'interagir avec les providers depuis tes widgets.

---

### 1. ref.watch() — Observer les changements (dans build)

À utiliser **uniquement** à l'intérieur de `build()`. Le widget se redessine automatiquement quand la valeur du provider change.

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Compteur: $count');
  }
}
```

---

### 2. ref.read() — Lire une seule fois (dans les callbacks)

À utiliser **uniquement** dans les callbacks (onPressed, initState). Lit la valeur à un instant donné, ne déclenche jamais de rebuild. **Ne JAMAIS l'utiliser dans build().**

```dart
ElevatedButton(
  onPressed: () {
    ref.read(counterProvider.notifier).state++;
    ref.read(cartProvider.notifier).add(selectedItem);
  },
  child: const Text('Ajouter'),
)
```

---

### 3. ref.listen() — Réagir aux changements (side-effects)

Pour afficher un SnackBar, naviguer ou déclencher une animation quand l'état change — sans redessiner toute l'interface.

```dart
class MyPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.go('/home');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });
    return const LoginForm();
  }
}
```

---

### 4. ref.invalidate() — Forcer le rafraîchissement

Force un provider à recalculer sa valeur. Idéal pour le pull-to-refresh ou après une mutation de données.

```dart
onPressed: () async {
  await ref.read(userRepositoryProvider).createUser(newUser);
  ref.invalidate(usersListProvider); // Force le rechargement
}
```

---

### Règle d'or
| Méthode | Où l'utiliser |
|---------|---------------|
| `ref.watch()` | Dans `build()` |
| `ref.read()` | Dans les callbacks |
| `ref.listen()` | Pour les side-effects |
| `ref.invalidate()` | Pour forcer le rafraîchissement |

### Checklist
- [ ] Je sais utiliser ref.watch()
- [ ] Je sais utiliser ref.read()
- [ ] Je sais utiliser ref.listen()
- [ ] Je sais utiliser ref.invalidate()

---

## Chapitre 11 : Modificateurs — autoDispose, family, keepAlive

### Cours

Les modificateurs sont des extensions que tu ajoutes à la fin d'un provider pour modifier son comportement. Les trois principaux sont `autoDispose`, `family` et `keepAlive`.

---

### 1. autoDispose — Libérer la mémoire automatiquement

Par défaut, un provider reste en vie aussi longtemps que l'application est ouverte. Avec `.autoDispose`, Riverpod détruit l'état quand plus aucun widget ne l'écoute.

```dart
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final productDetailProvider = FutureProvider.autoDispose.family<Product, String>(
  (ref, productId) async {
    final repo = ref.watch(productRepositoryProvider);
    return repo.getProduct(productId);
  },
);
```

---

### 2. family — Passer des paramètres

Pour obtenir un produit par son identifiant, utilise `.family`. Le deuxième type générique est le type du paramètre.

```dart
final productProvider = FutureProvider.family<Product, int>(
  (ref, productId) async {
    return fetchProductFromApi(productId);
  },
);

// Dans l'interface :
class ProductPage extends ConsumerWidget {
  final int productId;
  const ProductPage({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    return productAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Erreur: $e'),
      data: (product) => Text(product.name),
    );
  }
}
```

---

### 3. keepAlive — Garder l'état en mémoire

`keepAlive` permet de conserver l'état d'un provider même si aucun widget ne l'écoute. Utile pour mettre en cache des données pendant un certain temps.

```dart
final cachedUserProvider = FutureProvider.autoDispose<User>((ref) async {
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);
  return fetchUser();
});
```

---

### Patron combiné le plus courant

`FutureProvider.autoDispose.family` est le pattern le plus utilisé pour les pages de détail avec des données chargées par identifiant.

### démo live
> Voir `lib/demos/demo_07_riverpod_family.dart` pour la démonstration avec family et autoDispose

### Checklist
- [ ] Je comprends autoDispose
- [ ] Je sais utiliser family pour passer des paramètres
- [ ] Je comprends keepAlive
- [ ] Je sais combiner autoDispose + family

---

## Récapitulatif

| Type | Usage | Exemple |
|------|-------|---------|
| Provider | Valeur constante | Injection de dépendances |
| StateProvider | Valeur simple mutable | Compteur, filtre |
| FutureProvider | Opération async | Appel API |
| StreamProvider | Flux temps réel | Firebase, WebSocket |
| NotifierProvider | Logique complexe | CRUD, business logic |

---
← [Chapitre précédent : Introduction à Riverpod](03-introduction-riverpod.md) | [Chapitre suivant : Riverpod Expert](05-riverpod-expert.md) →
