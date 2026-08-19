# Les Fondamentaux — Comprendre le State en Flutter

## Navigation

- ← [Retour au sommaire](../README.md)
- → [Chapitre suivant : Provider](02-provider.md)

---

## Chapitre 1 : Comprendre le State en Flutter

### Cours

#### Qu'est-ce que le « State » ?

Imagine une page web classique. Quand tu cliques sur un bouton, la page se charge, et le contenu change. Dans le monde de Flutter, cette « chose qui change » s'appelle le **State** (l'état).

En termes simples : **le State, c'est toutes les données qui définissent à quoi ressemble ton écran à un instant donné.**

Pense à ces exemples du quotidien :

| Situation | Le State correspondant |
|---|---|
| Un interrupteur lumineux | Allumé ou éteint |
| Un panier d'achat | Le nombre d'articles dans le panier |
| Un formulaire de connexion | Les mots de saisie dans les champs |
| Un bouton de like | Le cœur est-il rempli ou vide ? |

Dans chaque cas, **quelque chose change**, et l'écran doit se mettre à jour pour refléter ce changement. C'est exactement ça, le State.

#### Pourquoi le State est important ?

En Flutter, l'interface utilisateur (UI) est **déclarative**. Cela signifie qu'on ne modifie pas directement l'écran. Au lieu de ça, on dit à Flutter :

> « Voici mes données actuelles. Construis-moi l'écran qui correspond. »

Quand les données changent, Flutter **reconstruit** l'écran automatiquement. C'est comme si tu donnais à Flutter une recette mise à jour, et il refait le plat avec les nouveaux ingrédients.

#### Les deux types de State

Il existe deux catégories de State, et les distinguer est la première étape fondamentale :

**1. L'État Éphémère (Local State)**

C'est un état qui vit **dans un seul widget**, et qui n'intéresse personne d'autre.

Exemples :
- L'onglet sélectionné dans un widget de navigation
- La progression d'une animation
- La visibilité du mot de passe (les points ou le texte)
- Le fait qu'un menu soit ouvert ou fermé

Pour gérer cet état, la méthode `setState` suffit. On verra ça au chapitre 2.

**2. L'État de l'App (App State)**

C'est un état qui doit être **partagé entre plusieurs widgets** situés à différents endroits de l'arbre de widgets.

Exemples :
- Le panier d'achat (visible sur la page d'accueil ET sur la page panier)
- Les préférences utilisateur (thème sombre/clair, langue)
- L'état de connexion (connecté ou non)
- L'utilisateur actuellement connecté

Pour gérer cet état, il faut un **State Management** — un mécanisme qui permet de partager et de synchroniser les données entre plusieurs widgets. C'est le sujet de ce cours.

#### Comment retenir ?

Pense à une boîte :
- **État éphémère** = un post-it sur ton bureau personnel. Seul toi le vois.
- **État de l'app** = un tableau blanc dans la salle commune. Tout le monde le voit et le met à jour.

---

### Cas pratique : La réconciliation

Quand le State change, Flutter ne reconstruit pas **tout** l'écran à chaque fois. Il utilise un processus intelligent appelé **réconciliation** (ou *hot reload* interne).

Voici comment ça marche :

1. Le State d'un widget change.
2. Flutter regarde l'**ancien** arbre de widgets et le **nouveau** arbre de widgets.
3. Il compare chaque widget un par un.
4. Il ne met à jour que les widgets qui ont **réellement changé**.

C'est comme un correcteur orthographique intelligent : il ne réécrit pas tout le texte, il ne corrige que les erreurs. C'est ce qui rend Flutter performant.

> **En résumé** : La réconciliation, c'est la capacité de Flutter à comparer l'avant et l'après pour ne modifier que ce qui a changé.

---

### Checklist

- [ ] J'ai compris ce qu'est le State
- [ ] Je sais faire la différence entre état éphémère et état de l'app

---

## Chapitre 2 : setState et ses limites

### Cours

#### Qu'est-ce que setState ?

`setState` est la méthode de base en Flutter pour dire :

> « Quelque chose a changé dans mon widget. Reconstruis-le. »

Pense à un thermostat intelligent. Tu changes la température, et le thermostat met à jour l'affichage. `setState`, c'est exactement ça : tu dis à Flutter « hey, l'état a changé, mets à jour l'écran ».

#### Un exemple concret : le compteur

Voici un widget simple qui affiche un compteur et un bouton pour l'incrémenter :

```dart
// Exemple : un compteur avec état éphémère
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0; // L'état éphémère, local à ce widget

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Compteur: $_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Incrémenter'),
        ),
      ],
    );
  }
}
```

**Explication ligne par ligne :**

- `class CounterWidget extends StatefulWidget` : On crée un widget « vivant » — un widget qui peut avoir un état qui change. `StatefulWidget` est le type de widget qui possède un état.

- `const CounterWidget({super.key})` : Le constructeur. `super.key` permet à Flutter d'identifier ce widget de façon unique dans l'arbre.

- `State<CounterWidget> createState()` : Cette méthode dit à Flutter : « Quand tu as besoin de l'état de ce widget, crée une instance de `_CounterWidgetState` ». C'est le lien entre le widget et son état.

- `class _CounterWidgetState extends State<CounterWidget>` : La classe qui contient **l'état** du widget. C'est ici qu'on stocke les données qui changent.

- `int _count = 0` : La variable d'état. Le underscore `_` signifie que c'est une variable **privée** — uniquement accessible à l'intérieur de cette classe.

- `Widget build(BuildContext context)` : La méthode qui construit l'interface. Elle est rappelée à chaque fois que `setState` est appelé.

- `Text('Compteur: $_count')` : Un widget Text qui affiche la valeur actuelle du compteur. `$_count` insère la valeur de la variable dans le texte.

- `ElevatedButton(...)` : Un bouton cliquable.

- `onPressed: () => setState(() => _count++)` : Quand on clique, on appelle `setState` avec une fonction qui incrémente `_count`. Le `++` ajoute 1 à la valeur.

- `child: const Text('Incrémenter')` : Le texte affiché sur le bouton.

#### Les 3 règles de setState

Ces règles sont **essentielles** à retenir :

**Règle 1 : La fonction doit être synchrone**

La fonction passée à `setState` doit s'exécuter immédiatement, sans attendre.

```dart
// ✅ CORRECT : synchrone
onPressed: () => setState(() {
  _count++;
}),

// ❌ INCORRECT : asynchrone — ne fonctionne pas correctement
onPressed: () => setState(() async {
  await Future.delayed(Duration(seconds: 1));
  _count++; // Flutter ne sait pas quand reconstruire l'UI
}),
```

**Règle 2 : Ne jamais mettre `async` dans `setState`**

`setState` doit terminer immédiatement. Si tu as besoin d'opérations asynchrones (appels réseau, lecture de base de données), fais-les **avant** d'appeler `setState`.

```dart
// ❌ INCORRECT : async dans setState
onPressed: () => setState(() async {
  final data = await fetchData(); // Mauvaise pratique !
  _data = data;
}),

// ✅ CORRECT : async avant setState
onPressed: () async {
  final data = await fetchData();
  setState(() {
    _data = data;
  });
},
```

**Règle 3 : Modifie uniquement ce qui a changé**

Ne recrée pas des objets entiers si seulement une partie a changé.

```dart
// ❌ INCORRECT : recrée tout l'objet
setState(() {
  _user = User(name: 'Nouveau nom', age: _user.age);
}),

// ✅ CORRECT : modifie uniquement ce qui change
setState(() {
  _user.name = 'Nouveau nom';
}),
```

#### Les problèmes de setState

`setState` est parfait pour les cas simples, mais il montre rapidement ses limites.

**Problème 1 : Le Prop Drilling (perçage de props)**

Imagine que tu as un panier d'achat. L'état du panier doit être accessible à :
- L'icône du panier dans la barre de navigation
- La page du panier
- La page de produit (pour le bouton « Ajouter au panier »)
- La page de confirmation

Avec `setState`, tu dois :
1. Stocker l'état dans un widget parent très haut dans l'arbre
2. Passer des fonctions de callback à chaque widget enfant, couche après couche

C'est ce qu'on appelle le **Prop Drilling** : on « fore » à travers les couches de widgets pour transmettre des données et des fonctions.

```dart
// Exemple de Prop Drilling — À ÉVITER
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _cartItems = [];

  void _addToCart(String item) {
    setState(() {
      _cartItems.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // On passe _addToCart au ProductPage
        ProductPage(onAddToCart: _addToCart),
        // On passe _cartItems au CartIcon
        CartIcon(items: _cartItems),
      ],
    );
  }
}

class ProductPage extends StatelessWidget {
  final Function(String) onAddToCart;

  const ProductPage({required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Mon Produit'),
        // On passe encore _addToCart au ProductButton
        ProductButton(onAddToCart: onAddToCart),
      ],
    );
  }
}

class ProductButton extends StatelessWidget {
  final Function(String) onAddToCart;

  const ProductButton({required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onAddToCart('Produit A'), // Enfin !
      child: const Text('Ajouter au panier'),
    );
  }
}
```

Vois le problème : `_addToCart` passe de `HomePage` → `ProductPage` → `ProductButton`. Et si tu avais 5 niveaux de widgets ? Les callbacks s'accumulent et le code devient illisible.

**Problème 2 : Les performances**

Quand tu appelles `setState`, **tous les enfants** du widget sont reconstruits, même ceux qui n'ont pas changé.

```dart
// setState reconstruit TOUT le Column et ses enfants
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      const Text('Titre non modifié'),    // Reconstruit pour rien !
      const Text('Sous-titre identique'), // Reconstruit pour rien !
      Text('Compteur: $_count'),           // Celui-ci change
    ],
  );
}
```

Pour un petit widget, ce n'est pas grave. Mais dans une application avec des dizaines ou des centaines de widgets, ces reconstructions inutiles impactent les performances.

#### La solution temporaire : le State Lifting (remonter l'état)

Le State Lifting, c'est la technique qu'on a utilisée dans l'exemple du panier : on déplace l'état **vers le haut** dans l'arbre de widgets, dans un parent commun, pour que plusieurs widgets puissent y accéder.

C'est une solution pragmatique pour les petits cas, mais elle ne résout pas le Prop Drilling ni les problèmes de performance. Pour aller plus loin, il faut d'autres outils : c'est l'objet des chapitres suivants.

---

### démo live

Voir `lib/demos/demo_01_setstate.dart` pour la démonstration interactive

---

### Checklist

- [ ] Je sais utiliser setState
- [ ] Je comprends les 3 règles de setState
- [ ] Je vois le problème du Prop Drilling
- [ ] Je comprends le problème de performance

---

## Chapitre 3 : InheritedWidget — La fondation

### Cours

#### L'arme secrète de Flutter

Flutter possède déjà un outil intégré pour résoudre le Prop Drilling : c'est l'`InheritedWidget`. C'est la **fondation** sur laquelle sont construits Provider et Riverpod.

Pense à un **tableau d'affichage** dans une entreprise. N'importe quel employé peut passer le lire sans avoir besoin qu'on le lui transmette de personne en personne. C'est exactement le principe de l'`InheritedWidget` : c'est un widget qu'on place **haut** dans l'arbre, et n'importe quel widget **enfant** peut y accéder directement, sans avoir besoin de le recevoir en paramètre.

#### Le code

Voici un exemple concret : un widget qui fournit la couleur primaire du thème.

```dart
class AppTheme extends InheritedWidget {
  final Color primaryColor;

  const AppTheme({
    super.key,
    required this.primaryColor,
    required super.child,
  });

  static AppTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTheme>()!;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return primaryColor != oldWidget.primaryColor;
  }
}
```

**Explication ligne par ligne :**

- `class AppTheme extends InheritedWidget` : On crée un widget qui hérite d'`InheritedWidget`. C'est ce qui lui donne son super-pouvoir : la capacité d'être trouvé par n'importe quel enfant.

- `final Color primaryColor` : La donnée qu'on veut partager. Ici, la couleur du thème.

- `const AppTheme({super.key, required this.primaryColor, required super.child})` : Le constructeur. `super.child` est **obligatoire** : c'est le widget enfant qui sera affiché sous ce provider.

- `static AppTheme of(BuildContext context)` : Une méthode **statique** (accessible sans créer d'instance). C'est le « moteur de recherche » : quand un widget veut accéder à `AppTheme`, il appelle `AppTheme.of(context)`.

- `context.dependOnInheritedWidgetOfExactType<AppTheme>()!` : C'est la magie. Cette ligne dit à Flutter : « Remonte dans l'arbre de widgets et trouve-moi le premier `AppTheme` parent ». Le `!` signifie qu'on est sûr qu'il existe (on fait confiance au développeur pour l'avoir placé plus haut).

- `updateShouldNotify(AppTheme oldWidget)` : Cette méthode dit à Flutter : « Si la couleur a changé,通知 (notifie) tous les widgets enfants pour qu'ils se reconstruisent ». Retourner `true` déclenche la reconstruction des enfants.

#### Utilisation

```dart
// En haut de l'arbre, on fournit la couleur
AppTheme(
  primaryColor: Colors.blue,
  child: MyApp(),
)

// N'importe quel widget enfant peut y accéder
class MyDeepWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(color: theme.primaryColor);
  }
}
```

`MyDeepWidget` peut être à 10 niveaux de profondeur dans l'arbre, il peut toujours accéder à `primaryColor` sans qu'aucune props ne soit passée. C'est comme lire le tableau d'affichage : il est là, tout le monde le voit.

#### Pourquoi on ne l'utilise pas directement ?

Bien que l'`InheritedWidget` soit puissant, il présente deux inconvénients majeurs pour une utilisation en production :

1. **Beaucoup de boilerplate** (code répétitif et verbeux) : Pour chaque donnée à partager, il faut créer une classe complète avec le constructeur, la méthode `of`, et `updateShouldNotify`.

2. **Lecture seule par les enfants** : Les widgets enfants peuvent **lire** la donnée, mais pas la **modifier** directement. Il faut ajouter des callbacks supplémentaires, ce qui complique le code.

C'est pourquoi des solutions comme **Provider** et **Riverpod** ont été créées : elles encapsulent la complexité de l'`InheritedWidget` et ajoutent des fonctionnalités pratiques. Mais comprendre `InheritedWidget`, c'est comprendre la base de tout.

---

### Checklist

- [ ] Je comprends le concept d'InheritedWidget
- [ ] Je sais que Provider et Riverpod sont basés dessus

---

## Chapitre 4 : ValueNotifier et ChangeNotifier

### Cours

#### Le pattern Observer (d'observation)

Avant de voir ces deux classes, comprends un concept clé : le **pattern Observer**.

Imagine un journaliste dans une conférence de presse. Il ne retourne pas au bureau toutes les 5 minutes pour demander « y a-t-il du nouveau ? ». Au lieu de ça, il reste sur place. Quand le porte-parole fait une annonce, il la reçoit **autom ValueNotifier et ChangeNotifier

### Cours

#### Le pattern Observer (le principe de l'observation)

Avant de voir ces deux classes, il faut comprendre un concept fondamental : le **pattern Observer**.

Imagine un journaliste en direct. Il ne pose pas la même question 100 fois par seconde. Au lieu de ça, il dit à la personne qu'il interview :

> « Quand il y a du nouveau, préviens-moi. »

C'est exactement le principe de l'**Observer** (l'observateur) :
- Un objet **survit** (change de valeur)
- Les **observateurs** sont notifiés automatiquement
- Ils réagissent au changement

En Flutter, les deux classes qui utilisent ce principe sont `ValueNotifier` et `ChangeNotifier`.

---

#### ValueNotifier (pour une seule valeur)

`ValueNotifier` est le plus simple. Il contient **une seule valeur** et notifie ses auditeurs quand cette valeur change.

```dart
// Créer un ValueNotifier
final ValueNotifier<int> counter = ValueNotifier<int>(0);

// Dans l'UI — écouter les changements
ValueListenableBuilder<int>(
  valueListenable: counter,
  builder: (context, value, child) {
    return Text('Compteur: $value');
  },
)

// Modifier la valeur
counter.value++;
```

**Explication :**

- `final ValueNotifier<int> counter = ValueNotifier<int>(0)` : On crée un compteur qui contient un entier, initialisé à 0. La notation `<int>` indique le type de valeur.

- `ValueListenableBuilder<int>(valueListenable: counter, ...)` : Un widget « intelligent » qui **écoute** le `counter`. Quand la valeur change, il reconstruit automatiquement le widget.

- `builder: (context, value, child)` : La fonction qui construit l'UI. `value` est la valeur actuelle du compteur. `child` est un widget optimisé (on peut l'ignorer pour l'instant).

- `counter.value++` : Pour modifier la valeur, on accède à `.value`. Cette modification déclenche automatiquement la notification des auditeurs.

**Quand utiliser ValueNotifier ?**

Quand tu as **une seule donnée simple** qui change :
- Un compteur
- Un booléen (toggle on/off)
- Une chaîne de caractères

---

#### ChangeNotifier (pour un objet complexe)

`ChangeNotifier` est plus puissant. Il est conçu pour des **objets avec plusieurs données et des méthodes**.

```dart
class CartModel extends ChangeNotifier {
  final List<String> _items = [];

  List<String> get items => List.unmodifiable(_items);
  int get count => _items.length;

  void add(String item) {
    _items.add(item);
    notifyListeners(); // Notifie tous les auditeurs
  }

  void remove(String item) {
    _items.remove(item);
    notifyListeners();
  }
}
```

**Explication ligne par ligne :**

- `class CartModel extends ChangeNotifier` : On crée un modèle de données qui hérite de `ChangeNotifier`. Cette classe nous donne la capacité de « notifier » les auditeurs.

- `final List<String> _items = []` : Une liste privée d'articles. Le `_` signifie que les widgets ne peuvent pas modifier directement la liste — ils doivent passer par les méthodes `add` et `remove`.

- `List<String> get items => List.unmodifiable(_items)` : Un **getter** qui retourne une version non modifiable de la liste. C'est une bonne pratique de sécurité : on évite les modifications accidentelles.

- `int get count => _items.length` : Un getter qui retourne le nombre d'articles.

- `void add(String item)` : Une méthode qui ajoute un article et appelle `notifyListeners()`.

- `notifyListeners()` : **C'est la ligne la plus importante.** Cette méthode dit à tous les widgets qui observent ce `CartModel` : « J'ai changé, mettez-vous à jour ! ».

**Quand utiliser ChangeNotifier ?**

Quand tu as un **objet avec plusieurs données et des logiques métier** :
- Un panier d'achat (ajouter, supprimer, calculer le total)
- Un profil utilisateur (nom, email, photo, préférences)
- Un état de connexion (statut, données utilisateur, token)

---

#### Le lien avec Provider

`ChangeNotifier` est la classe utilisée en interne par Provider. Quand tu utilises Provider dans le chapitre suivant, tu créeras souvent un `ChangeNotifier` et Provider s'occupera de le :
1. **Créer** (et de le garder en mémoire)
2. **Fournir** aux widgets qui en ont besoin
3. **Détruire** quand il n'est plus nécessaire

> **Retiens bien** : Comprendre `ChangeNotifier` et ses méthodes, c'est comprendre **80% du fonctionnement de Provider**.

---

### démo live

Voir `lib/demos/demo_02_change_notifier.dart` pour la démonstration interactive

---

### Checklist

- [ ] Je sais créer un ValueNotifier
- [ ] Je sais créer un ChangeNotifier
- [ ] Je comprends notifyListeners()

---

## Récapitulatif

| Concept | Usage | Limite |
|---------|-------|--------|
| **setState** | État local simple | Prop Drilling, Performance |
| **InheritedWidget** | Partager sans Prop Drilling | Boilerplate, lecture seule |
| **ValueNotifier** | Une seule valeur | Pas de logique métier |
| **ChangeNotifier** | Objet complexe | Besoin d'un mécanisme de distribution |

**Ce qu'on a appris :**
- Le **State** est les données qui définissent l'aspect de l'écran
- **setState** est simple mais a des limites de performance et de partage
- **InheritedWidget** résout le partage mais est verbeux
- **ValueNotifier** et **ChangeNotifier** offrent le pattern Observer intégré
- Tout cela prépare le terrain pour **Provider** et **Riverpod**, qui combinent les meilleurs aspects de ces outils

---

← [Retour au sommaire](../README.md) | [Chapitre suivant : Provider](02-provider.md) →
