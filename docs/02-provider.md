# Provider — Concepts et Setup

## Navigation

- ← [Chapitre précédent : Les Fondamentaux](01-fondamentaux.md)
- → [Chapitre suivant : Introduction à Riverpod](03-introduction-riverpod.md)

---

## Chapitre 5 : Provider — Concepts et Setup

### Cours

Imaginez que vous tenez un commerce. Vous avez un **entrepôt central** (vos données) et de nombreux **comptoirs** (vos widgets) qui ont besoin de ces données.

Sans Provider, chaque comptoir devrait envoyer un coursier chercher les données dans l'entrepôt, en passant par tous les comptoirs intermédiaires. C'est long, compliqué, et tout le monde finit par se mélanger les pinceaux.

**Provider, c'est le service de livraison qui envoie directement les données du bon côté, sans que chaque intermédiaire ait besoin de les manipuler.**

C'est un mécanisme qui vous permet de **fournir** (d'où le nom !) une donnée à un arbre de widgets, et de la **consommer** depuis n'importe quel descendant, sans avoir à la faire transiter manuellement par chaque niveau.

---

### 1. Installation

C'est le premier pas, et le plus simple :

```bash
flutter pub add provider
```

Après cette commande, le package `provider` est ajouté à votre `pubspec.yaml` et vous pouvez l'utiliser partout dans votre projet.

---

### 2. Les 3 piliers

Provider repose sur **3 concepts fondamentaux**. Retenez-les bien, tout le reste en découle :

#### a) L'État (Le Modèle)

C'est une classe qui **contient vos données** et la **logique métier** (les règles de votre application). En Flutter, on l'appelle un `ChangeNotifier`.

Pourquoi `ChangeNotifier` ? Parce que cette classe a une particularité très utile : elle possède une méthode `notifyListeners()` qui **notifie** tous les widgets qui l'écoutent qu'il y a eu un changement.

```dart
class CartModel extends ChangeNotifier {
  final List<String> _items = [];

  List<String> get items => _items;

  void add(String item) {
    _items.add(item);
    notifyListeners(); // ← Dites à tous les widgets écoutants : "Mettez-vous à jour !"
  }

  void remove(String item) {
    _items.remove(item);
    notifyListeners();
  }

  int get count => _items.length;
}
```

**En résumé** : `ChangeNotifier` = données + méthodes qui notifient les changements.

---

#### b) Le Fournisseur (Provider)

C'est un **widget** que vous placez **haut dans l'arbre** de widgets. Son rôle est de :

1. **Créer** une instance de votre modèle
2. **La fournir** (la mettre à disposition) de tous ses descendants

Lorsque le widget Provider est supprimé de l'arbre, l'instance du modèle est également supprimée.

---

#### c) Le Consommateur (Consumer)

C'est le widget (ou la méthode) que vous utilisez **plus bas** dans l'arbre pour **lire les données** du modèle et **s'abonner** aux changements. Lorsque le modèle appelle `notifyListeners()`, le Consumer se reconstruit automatiquement avec les nouvelles données.

**Les 3 piliers résumés :**

- **État** → Contient les données et la logique (`ChangeNotifier`)
- **Fournisseur** → Fournit le modèle depuis le haut de l'arbre (`Provider`)
- **Consommateur** → Lit les données et se met à jour automatiquement (`Consumer`, `context.watch`, etc.)

---

### 3. ChangeNotifierProvider — Le Setup de base

Pour connecter un `ChangeNotifier` à l'arbre de widgets, on utilise `ChangeNotifierProvider` :

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: const MyApp(),
    ),
  );
}
```

**Ce qu'il faut retenir :**

- `create` est une **fonction** qui retourne une instance de votre modèle.
- Cette fonction est appelée **UNE SEULE FOIS** : la première fois qu'un widget demande accès au modèle.
- L'instance créée est ensuite **partagée** avec tous les descendants du Provider.
- `child: MyApp()` est le widget qui recevra accès au modèle (ici, toute l'application).

---

### 4. MultiProvider — Quand on a plusieurs modèles

En pratique, une application a souvent **plusieurs modèles**. Par exemple : un panier, un utilisateur connecté, un thème...

Pour éviter de **nicher** les Provider les uns dans les autres (ce qui serait illisible), on utilise `MultiProvider` :

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        ChangeNotifierProvider(create: (_) => UserModel()),
        ChangeNotifierProvider(create: (_) => ThemeModel()),
      ],
      child: const MyApp(),
    ),
  );
}
```

**Avantages :**

- Code **propre et lisible** au lieu d'imbrications multiples.
- Chaque modèle est **indépendant** : ils ont chacun leur cycle de vie.
- On peut facilement **ajouter ou retirer** des modèles.

**Note** : le `_` est simplement un paramètre ignoré. On pourrait écrire `(context) => CartModel()` mais on n'a pas besoin du contexte ici.

---

### ⚠️ Point important

> **Utilisez toujours `create: (context) => MonModele()` et jamais `value:` au niveau racine.**

La méthode `create` crée une nouvelle instance au besoin. La méthode `value` réutilise une instance que vous gérez vous-même — ce qui peut causer des bugs de mémoire si vous ne faites pas attention. Pour les débutants, `create` est toujours le bon choix.

---

### ✅ Checklist — Chapitre 5

- [ ] J'ai installé Provider
- [ ] Je comprends les 3 piliers (État, Fournisseur, Consommateur)
- [ ] Je sais créer un ChangeNotifierProvider
- [ ] Je sais utiliser MultiProvider

---

## Chapitre 6 : Consumer, context.read, watch et select

### Cours

Maintenant que votre donnée est fournie au sommet de l'arbre, il faut **l'accesser** depuis les widgets en dessous. Il existe plusieurs façons de le faire, et chacune a un **cas d'usage précis**.

Le choix entre ces méthodes dépend d'une question simple : **avez-vous besoin d'écouter les changements ou non ?**

---

### 1. context.read() — Pour les actions (sans écouter)

```dart
ElevatedButton(
  onPressed: () {
    context.read<CartModel>().add('Pomme');
  },
  child: const Text('Ajouter au panier'),
)
```

**Explication :**

On appelle une **méthode** du modèle **sans écouter** les changements. Le widget qui appelle `context.read` **ne se reconstruira pas** quand le modèle change.

**Utilisez UNIQUEMENT dans les callbacks** (`onPressed`, `onTap`, etc.) — jamais dans le `build()`.

**Pourquoi ?** Parce que `read` ne crée pas d'abonnement. Si vous l'utilisez dans `build()`, le widget ne se mettra jamais à jour même si les données changent.

---

### 2. context.watch() — Pour les données réactives

```dart
@override
Widget build(BuildContext context) {
  final cart = context.watch<CartModel>();
  return Text('${cart.count} article(s)');
}
```

**Explication :**

Le widget **écoute** le modèle. Dès que `notifyListeners()` est appelé dans le modèle, ce widget est **reconstruit automatiquement** avec les nouvelles données.

**Utilisez dans `build()`** quand vous avez besoin d'afficher des données qui changent.

---

### 3. Consumer\<T\> — Pour des reconstructions ciblées

```dart
Scaffold(
  appBar: AppBar(title: const Text('Mon Panier')),
  body: Consumer<CartModel>(
    builder: (context, cart, child) {
      return Text('${cart.count} article(s)');
    },
  ),
)
```

**Explication :**

`Consumer` est un widget qui prend un `builder`. **Seule la partie à l'intérieur du builder** se reconstruit quand le modèle change. Le reste du widget parent (comme l'`AppBar` ici) ne bouge pas.

**Quand l'utiliser ?** Quand vous voulez **isoler** la reconstruction à une petite partie de l'arbre pour des raisons de performance.

---

### 4. context.select() — L'optimisation extrême

```dart
final itemCount = context.select<CartModel, int>((cart) => cart.count);
return Text('$itemCount article(s)');
```

**Explication :**

`select` extrait **une seule valeur** du modèle. Le widget ne se reconstruit **QUE si cette valeur précise change**. Si vous appelez `notifyListeners()` mais que `cart.count` n'a pas bougé, le widget ne se reconstruit pas.

**Quand l'utiliser ?** Quand vous avez un modèle gros et que vous ne voulez être notifié que d'un changement très spécifique.

---

### 🎯 Règle d'or

| Méthode            | Où l'utiliser ?                                  | Reconstruit le widget ?            |
| ------------------ | ------------------------------------------------ | ---------------------------------- |
| `context.read()`   | Dans les **callbacks** (`onPressed`, `onTap`...) | **Non**                            |
| `context.watch()`  | Dans **`build()`**                               | **Oui** (à chaque changement)      |
| `Consumer<T>`      | Dans **`build()`** — rebuild ciblé               | **Oui** (partiellement)            |
| `context.select()` | **Optimisation fine** dans `build()`             | **Oui** (si la valeur change)      |

**En résumé :**

- **Vous voulez appeler une méthode ?** → `context.read()` dans un callback.
- **Vous voulez afficher une donnée qui change ?** → `context.watch()` ou `Consumer` dans `build()`.
- **Vous voulez optimiser au maximum ?** → `context.select()`.

---

### démo live

> Voir `lib/demos/demo_03_provider.dart` pour la démonstration interactive

---

### ✅ Checklist — Chapitre 6

- [ ] Je sais utiliser `context.read()`
- [ ] Je sais utiliser `context.watch()`
- [ ] Je sais créer un `Consumer`
- [ ] Je comprends quand utiliser read vs watch vs select

---

## Récapitulatif

| Méthode            | Quand l'utiliser                        | Reconstruit le widget ?            |
| ------------------ | --------------------------------------- | ---------------------------------- |
| `context.read()`   | Dans les callbacks                      | Non                                |
| `context.watch()`  | Dans build()                            | Oui                                |
| `Consumer`         | Build ciblé                             | Oui (partiellement)                |
| `context.select()` | Optimisation fine                       | Oui (si la valeur change)          |

---

← [Chapitre précédent : Les Fondamentaux](01-fondamentaux.md) | [Chapitre suivant : Introduction à Riverpod](03-introduction-riverpod.md) →
