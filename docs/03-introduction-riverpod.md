# Introduction à Riverpod

## Navigation
- ← [Chapitre précédent : Provider](02-provider.md)
- → [Chapitre suivant : Riverpod Avancé](04-riverpod-avance.md)

---

## Chapitre 7 : Pourquoi Riverpod ?

### Cours

Riverpod a été créé par **Remi Rousselet** — la **même personne** qui a créé Provider. Il l'a créé spécifiquement pour corriger les limitations de Provider.

**C'est comme si Provider était une voiture qui fonctionne bien, mais Riverpod c'est la même voiture avec ABS, airbags et GPS intégré.**

#### Les limites de Provider

1. **Dépendance au BuildContext**
   - Pour lire des données avec Provider, il faut impérativement le `BuildContext`.
   - Résultat : il est **impossible** d'accéder aux données en dehors de l'UI (dans un service, un use case, etc.).

2. **ProviderNotFoundException au runtime**
   - Si vous oubliez d'injecter le Provider parent, l'application **plante pendant l'exécution** (pas à la compilation).
   - Vous ne découvrez le bug qu'en utilisant l'application.

3. **Un seul type par Provider**
   - Provider ne peut pas fournir deux valeurs de types différents.
   - Par exemple, on ne peut pas avoir deux providers de type `String` au même endroit — le second écrase le premier.

#### Les avantages de Riverpod

1. **Compile-safe**
   - Toutes les erreurs sont détectées **à la compilation**.
   - ProviderNotFoundException n'existe plus.

2. **Pas de BuildContext requis**
   - Les providers sont déclarés globalement et accessibles de n'importe où via `Ref` — même dans un service.

3. **Support asynchrone natif**
   - `AsyncValue` gère automatiquement les états **Loading**, **Data** et **Error**.

4. **Testabilité maximale**
   - Chaque provider peut être overridé dans les tests sans contexte Flutter.

### Checklist
- [ ] Je comprends pourquoi Riverpod existe
- [ ] Je connais les 3 limites de Provider
- [ ] Je connais les 4 avantages de Riverpod

---

## Chapitre 8 : Installation et ProviderScope

### Cours

#### 1. Installation

```bash
flutter pub add flutter_riverpod
```

Il existe **3 versions** de Riverpod selon votre besoin :

| Package | Usage |
|---------|-------|
| `flutter_riverpod` | Pour les applications Flutter (celui qu'on utilise) |
| `riverpod` | Pour du Dart pur (backend, CLI, etc.) |
| `hooks_riverpod` | Pour combiner Riverpod et `flutter_hooks` |

#### 2. Le ProviderScope

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello Riverpod'))),
    );
  }
}
```

Le `ProviderScope` est **obligatoire**. Il stocke l'état de tous les providers. Pensez-y comme un **entrepôt central** que Riverpod utilise en interne pour gérer les données.

> ⚠️ Sans `ProviderScope`, aucun provider ne fonctionnera. Il doit être à la racine de votre application.

#### 3. ConsumerWidget et ConsumerStatefulWidget

En Flutter classique, on utilise `StatelessWidget` et `StatefulWidget`. Avec Riverpod, on les remplace par :

**ConsumerWidget** (remplace StatelessWidget) :

```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref est disponible ici !
    return Container();
  }
}
```

**ConsumerStatefulWidget** (remplace StatefulWidget) :

```dart
class MyStatefulWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends ConsumerState<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    // ref est disponible via this.ref
    return Container();
  }
}
```

**La différence :**
- `ConsumerWidget` donne `ref` directement dans la méthode `build()`.
- `ConsumerStatefulWidget` donne `ref` via `this.ref` — utile quand vous avez aussi besoin de `setState` pour de l'état local.

### démo live
> Voir `lib/demos/demo_04_riverpod_state.dart` pour la première démonstration avec Riverpod.

### Checklist
- [ ] J'ai installé flutter_riverpod
- [ ] J'ai ajouté ProviderScope à la racine de mon app
- [ ] Je sais créer un ConsumerWidget
- [ ] Je sais créer un ConsumerStatefulWidget

---

## Récapitulatif

| Concept | Provider | Riverpod |
|---------|----------|----------|
| Injection | ChangeNotifierProvider widget | ProviderScope global |
| Accès | context.read/watch | ref.read/watch |
| Erreurs | Runtime (crash) | Compilation (erreur visible) |
| Hors UI | Impossible | Possible via ref |

---

← [Chapitre précédent : Provider](02-provider.md) | [Chapitre suivant : Riverpod Avancé](04-riverpod-avance.md) →
