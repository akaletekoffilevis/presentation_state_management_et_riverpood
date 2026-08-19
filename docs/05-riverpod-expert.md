# Riverpod Expert — NotifierProvider, Architecture, Tests

## Navigation
- ← [Chapitre précédent : Riverpod Avancé](04-riverpod-avance.md)
- → [Retour au sommaire](../README.md)

---

## Chapitre 12 : NotifierProvider — Logique Complexe

### Cours

Avec **Riverpod 2.x**, le `StateNotifierProvider` a été remplacé par `NotifierProvider`. L'avantage principal : **`ref` est accessible PARTOUT dans la classe**, dans toutes les méthodes, pas uniquement dans le constructeur.

#### Notifier\<State\> — Syntaxe moderne

```dart
class AuthNotifier extends Notifier<User?> {
  @override
  User? build() => null; // null = déconnecté par défaut

  Future<void> login(String email, String password) async {
    state = null; // Réinitialisation pendant le chargement
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email, password);
      state = user; // Mise à jour du state = rebuild de l'UI
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  void logout() {
    state = null;
    ref.invalidate(cartProvider); // Nettoyage d'autres providers
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
```

**Explication :** La méthode `build()` initialise l'état initial. `ref` est accessible **PARTOUT** dans la classe — dans `login()`, `logout()`, et toute autre méthode. C'est ça la grande nouveauté par rapport à l'ancien `StateNotifier`.

#### AsyncNotifier\<State\> pour les états asynchrones

Quand vos données viennent d'une API ou d'une base de données, vous utilisez `AsyncNotifier` qui gère automatiquement les états `loading`, `data` et `error` via `AsyncValue` :

```dart
class UsersNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    final repo = ref.watch(userRepositoryProvider);
    return repo.fetchUsers();
  }

  Future<void> addUser(User newUser) async {
    await ref.read(userRepositoryProvider).createUser(newUser);
    ref.invalidateSelf(); // Force la ré-exécution de build()
  }
}

final usersProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(UsersNotifier.new);
```

**Explication de `AsyncValue` :**
- `AsyncLoading` : les données sont en cours de chargement
- `AsyncData` : les données sont disponibles
- `AsyncError` : une erreur s'est produite

La méthode `ref.invalidateSelf()` force le rebuild complet du provider — c'est très utile après une création ou une suppression pour rafraîchir la liste.

> **Note :** Si vous voyez du code avec `StateNotifier` et `StateNotifierProvider`, c'est de l'ancien code (Riverpod 1.x). Migrez vers `Notifier` et `NotifierProvider` !

### Checklist
- [ ] Je sais créer un Notifier
- [ ] Je comprends la différence entre Notifier et AsyncNotifier
- [ ] Je sais utiliser `ref.invalidateSelf()`

---

## Chapitre 13 : Architecture avec Riverpod (3 couches)

### Cours

Riverpod n'est pas seulement un outil de State Management — c'est aussi un excellent **moteur d'injection de dépendances**. La recommandation officielle est de structurer votre code en **3 couches** séparées.

#### Couche 1 : Data (Repository)

Cette couche gère les appels API ou les accès base de données. **Pas d'état mutable ici** — on utilise de simples `Provider`.

```dart
// data/repositories/product_repository.dart
class ProductRepository {
  final ApiClient client;
  ProductRepository(this.client);

  Future<List<Product>> fetchProducts() async {
    final response = await client.get('/products');
    return (response.data as List).map((j) => Product.fromJson(j)).toList();
  }
}

// providers/repository_providers.dart
final apiClientProvider = Provider((ref) => ApiClient());
final productRepositoryProvider = Provider(
  (ref) => ProductRepository(ref.watch(apiClientProvider))
);
```

**Explication :** Le `ProductRepository` est un simple Dart class. Le `productRepositoryProvider` le crée et le fournit. Tout le reste du code accède à ces données via ce provider.

#### Couche 2 : Domain / Application (Le Notifier)

Cette couche orchestre la logique métier. Elle lit le Repository via `ref` et expose l'état à l'UI.

```dart
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    final repo = ref.watch(productRepositoryProvider);
    return repo.fetchProducts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).fetchProducts(),
    );
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);
```

**Explication :** `AsyncValue.guard()` capture automatiquement les erreurs et les place dans l'état `AsyncError`. Pas besoin de try/catch manuel !

#### Couche 3 : Présentation (L'UI)

L'interface lit le provider et réagit aux trois états d'`AsyncValue` :

```dart
class ProductListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, i) => ProductTile(product: products[i]),
        ),
      ),
    );
  }
}
```

**Explication :** La méthode `.when()` de `AsyncValue` force à gérer les trois cas possibles. L'UI ne peut pas ignorer le chargement ou les erreurs — c'est la sécurité offerte par `AsyncValue`.

> **Analogie :** C'est comme un restaurant — la **Data** c'est la cuisine, le **Domain** c'est le chef qui organise, la **Présentation** c'est le serveur qui livre au client.

### démo live
> Référence : Voir `lib/demos/demo_09_architecture.dart` pour la démonstration de l'architecture complète

### Checklist
- [ ] Je comprends la couche Data (Repository)
- [ ] Je comprends la couche Domain (Notifier)
- [ ] Je comprends la couche Présentation (UI)
- [ ] Je sais séparer les responsabilités

---

## Chapitre 14 : Tests Unitaires avec Riverpod

### Cours

Un grand avantage de Riverpod : les providers sont déclarés **en dehors de l'arbre de widgets**, ce qui les rend **faciles à tester en isolation** via `ProviderContainer`.

#### Créer un conteneur de test

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Le compteur commence à 0 et s\'incrémente', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(counterProvider), 0);

    container.read(counterProvider.notifier).state++;

    expect(container.read(counterProvider), 1);
  });
}
```

**Explication :**
- `ProviderContainer()` crée un conteneur isolé pour vos tests
- `addTearDown(container.dispose)` nettoie le conteneur après chaque test
- `container.read()` lit la valeur actuelle du provider
- `.notifier` accède à l'objet Notifier pour modifier l'état

#### Tester un AsyncNotifier

```dart
test('UsersNotifier charge les utilisateurs', () async {
  final container = ProviderContainer(
    overrides: [
      userRepositoryProvider.overrideWithValue(FakeUserRepository()),
    ],
  );
  addTearDown(container.dispose);

  final users = await container.read(usersProvider.future);
  expect(users.length, greaterThan(0));
});
```

**Explication :** On utilise `overrides` pour remplacer le vrai repository par un `FakeRepository`. Comme ça, le test ne dépend pas d'aucune API externe. On lit `.future` pour attendre la résolution de l'`AsyncNotifier`.

#### Mocking avec overrides

```dart
class FakeProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    return [Product(id: '1', name: 'Test Product')];
  }
}

final container = ProviderContainer(
  overrides: [
    productRepositoryProvider.overrideWithValue(FakeProductRepository()),
  ],
);
```

**Explication :** Tous les providers qui dépendent de `productRepositoryProvider` recevront automatiquement le `FakeProductRepository` ! C'est la magie de l'injection de dépendances de Riverpod — vous ne remplaciez qu'UN provider, et tout le reste s'adapte.

### Checklist
- [ ] Je sais créer un `ProviderContainer` de test
- [ ] Je sais tester un provider simple
- [ ] Je sais mocker des dépendances avec `overrides`
- [ ] Je sais tester un AsyncNotifier

---

## Récapitulatif Final

Voici un résumé de **tous les 14 chapitres** du cours :

| # | Chapitre | Concept Clé |
|---|----------|-------------|
| 1 | Le State | Éphémère vs App State |
| 2 | setState | 3 règles, Prop Drilling |
| 3 | InheritedWidget | Fondation native |
| 4 | ValueNotifier/ChangeNotifier | Pattern Observer |
| 5 | Provider Setup | 3 piliers, MultiProvider |
| 6 | Consumer/read/watch/select | Accès aux données |
| 7 | Pourquoi Riverpod | Limites de Provider |
| 8 | ProviderScope | Installation, ConsumerWidget |
| 9 | Types de providers | 5 types pour différents cas |
| 10 | Ref | watch, read, listen, invalidate |
| 11 | autoDispose/family | Mémoire et paramètres |
| 12 | NotifierProvider | Logique complexe |
| 13 | Architecture | 3 couches (Data/Domain/UI) |
| 14 | Tests | ProviderContainer, overrides |

> **Félicitations !** Vous maîtrisez maintenant le State Management en Flutter. La clé est la pratique — refaites les démos, modifiez le code, expérimentez !

---
← [Chapitre précédent : Riverpod Avancé](04-riverpod-avance.md) | [Retour au sommaire](../README.md) →
