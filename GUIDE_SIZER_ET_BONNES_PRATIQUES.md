# 📱 Guide Sizer et Bonnes Pratiques Flutter Layout

## 🎯 Introduction

Le package **Sizer** peut aider à éviter certaines erreurs de layout, mais il ne remplace pas les bonnes pratiques Flutter. Voici un guide complet pour comprendre quand et comment l'utiliser.

---

## ✅ Ce que Sizer RÉSOUT

### 1. **Code plus propre et lisible**
```dart
// ❌ AVANT (sans Sizer)
Container(
  width: MediaQuery.of(context).size.width * 0.9,
  height: MediaQuery.of(context).size.height * 0.5,
  padding: EdgeInsets.all(16),
)

// ✅ APRÈS (avec Sizer)
Container(
  width: 90.w,  // 90% de la largeur
  height: 50.h, // 50% de la hauteur
  padding: EdgeInsets.all(2.h), // Padding responsive
)
```

### 2. **Responsive design simplifié**
- `10.w` = 10% de la largeur de l'écran
- `10.h` = 10% de la hauteur de l'écran
- `10.sp` = 10 scaled pixels (pour les textes)

### 3. **Cohérence entre différentes tailles d'écrans**
```dart
// Texte adaptatif
Text(
  'Titre',
  style: TextStyle(fontSize: 16.sp), // S'adapte à l'écran
)

// Spacing adaptatif
SizedBox(height: 2.h), // 2% de hauteur
SizedBox(width: 5.w),  // 5% de largeur
```

---

## ❌ Ce que Sizer NE RÉSOUT PAS

### 1. **Modals/Dialogs/BottomSheets dynamiques**
```dart
// ❌ ERREUR : Sizer dans showModalBottomSheet
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    height: 90.h, // ⚠️ RenderBox was not laid out error!
    child: ...,
  ),
);

// ✅ SOLUTION : Utiliser MediaQuery
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    height: MediaQuery.of(context).size.height * 0.9, // ✅ Fonctionne
    child: ...,
  ),
);
```
**Pourquoi ?** Sizer essaie d'accéder aux dimensions avant que le modal soit complètement rendu.

### 2. **Conflits de contraintes BoxConstraints**
```dart
// ❌ ERREUR : Sizer n'aide PAS ici
Column(
  mainAxisSize: MainAxisSize.min, // ⚠️ Prend le minimum d'espace
  children: [
    Expanded(child: ...), // ⚠️ Veut prendre tout l'espace
  ],
)

// ✅ SOLUTION : Retirer mainAxisSize.min
Column(
  children: [
    Expanded(child: ...),
  ],
)
```

### 3. **Widgets mal imbriqués**
```dart
// ❌ ERREUR : Structure incorrecte
Row(
  children: [
    Container(width: double.infinity), // ⚠️ Largeur infinie dans Row
  ],
)

// ✅ SOLUTION : Utiliser Expanded ou Flexible
Row(
  children: [
    Expanded(
      child: Container(),
    ),
  ],
)
```

### 4. **Problèmes de scroll**
```dart
// ❌ ERREUR : SingleChildScrollView dans Expanded mal utilisé
Expanded(
  child: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min, // ⚠️ Conflit
      children: [...],
    ),
  ),
)

// ✅ SOLUTION
Expanded(
  child: SingleChildScrollView(
    child: Column(
      children: [...], // Pas de mainAxisSize.min
    ),
  ),
)
```

---

## 🛠️ Bonnes Pratiques Combinées (Sizer + Flutter)

### 1. **Dialogs et Bottom Sheets**

#### ✅ Bonne approche (MediaQuery pour la hauteur, Sizer pour le reste)
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => Container(
    height: MediaQuery.of(context).size.height * 0.9, // ✅ MediaQuery pour éviter les erreurs
    padding: const EdgeInsets.all(20), // ✅ Padding fixe ou responsive selon besoin
    child: Column(
      children: [
        // Header fixe
        Text('Titre', style: TextStyle(fontSize: 18.sp)),
        SizedBox(height: 2.h),
        
        // Contenu scrollable
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [...], // ✅ Pas de mainAxisSize.min
            ),
          ),
        ),
        
        // Footer fixe
        ElevatedButton(...),
      ],
    ),
  ),
);
```

### 2. **Responsive Cards**
```dart
Container(
  width: 90.w, // ✅ 90% de la largeur
  padding: EdgeInsets.symmetric(
    horizontal: 4.w,
    vertical: 2.h,
  ),
  margin: EdgeInsets.all(2.h),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(2.w),
  ),
  child: Column(
    children: [
      Text(
        'Titre',
        style: TextStyle(fontSize: 16.sp), // ✅ Texte responsive
      ),
    ],
  ),
)
```

### 3. **Forms avec Sizer**
```dart
TextField(
  decoration: InputDecoration(
    contentPadding: EdgeInsets.symmetric(
      horizontal: 4.w,
      vertical: 2.h,
    ),
    prefixIcon: Icon(Icons.person, size: 6.w),
  ),
  style: TextStyle(fontSize: 14.sp),
)
```

---

## 📋 Checklist pour Éviter les Erreurs de Layout

### ✅ Avant d'utiliser Sizer
1. [ ] Vérifier la structure des widgets (Column, Row, Expanded)
2. [ ] Éviter `mainAxisSize: MainAxisSize.min` avec `Expanded`
3. [ ] Ne pas mettre `double.infinity` dans un Row/Column sans Expanded
4. [ ] Utiliser `Flexible` ou `Expanded` pour partager l'espace

### ✅ Avec Sizer
1. [ ] Utiliser `X.h` pour les hauteurs (% de hauteur écran)
2. [ ] Utiliser `X.w` pour les largeurs (% de largeur écran)
3. [ ] Utiliser `X.sp` pour les tailles de texte
4. [ ] Utiliser Sizer pour les espacements (padding, margin)

---

## 🎨 Exemples Pratiques

### Exemple 1 : Card Responsive
```dart
Widget buildResponsiveCard() {
  return Container(
    width: 90.w, // 90% de largeur
    margin: EdgeInsets.symmetric(
      horizontal: 5.w,
      vertical: 2.h,
    ),
    padding: EdgeInsets.all(3.h),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(2.w),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 2.h),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Titre',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Description',
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    ),
  );
}
```

### Exemple 2 : Bottom Sheet Stable
```dart
void showAddItemSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9, // ✅ MediaQuery pour la stabilité
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Ajouter un article',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Scrollable content
          Expanded( // ✅ Prend l'espace restant
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Vos champs ici
                ],
              ),
            ),
          ),
          
          // Footer buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Ajouter', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## 🚨 Erreurs Courantes et Solutions

### Erreur 1 : BoxConstraints forces infinite width
```dart
// ❌ PROBLÈME
Row(
  children: [
    Container(width: double.infinity), // Erreur
  ],
)

// ✅ SOLUTION avec Sizer
Row(
  children: [
    Expanded(
      child: Container(width: 100.w), // OU
    ),
  ],
)
```

### Erreur 2 : RenderBox was not laid out
```dart
// ❌ PROBLÈME
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Expanded(child: ListView(...)), // Conflit
  ],
)

// ✅ SOLUTION
Column(
  children: [
    Expanded(child: ListView(...)),
  ],
)
```

### Erreur 3 : Bottom overflowed by X pixels
```dart
// ❌ PROBLÈME
Column(
  children: [
    Container(height: 500), // Trop grand
    Container(height: 500),
  ],
)

// ✅ SOLUTION avec Sizer
Column(
  children: [
    Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 50.h),
            Container(height: 50.h),
          ],
        ),
      ),
    ),
  ],
)
```

---

## ⚡ Règle d'Or : Quand utiliser Sizer vs MediaQuery

### 📱 Utilisez **Sizer** pour :
- Les écrans statiques normaux (pages principales)
- Cards, containers, spacing dans des pages fixes
- Textes et icônes
- Padding et margin dans des layouts statiques

### 🚫 N'utilisez **PAS Sizer** pour :
- `showModalBottomSheet` - Utilisez `MediaQuery` pour la hauteur
- `showDialog` - Utilisez `MediaQuery` pour les dimensions
- Widgets dynamiques qui apparaissent/disparaissent
- Animations complexes

### 💡 Exemple parfait (Mixte) :
```dart
// ✅ Page normale avec Sizer
Widget buildScreen() {
  return Scaffold(
    body: Padding(
      padding: EdgeInsets.all(2.h), // ✅ Sizer OK
      child: Column(
        children: [
          Container(
            width: 90.w, // ✅ Sizer OK
            height: 30.h, // ✅ Sizer OK
            child: Text(
              'Titre',
              style: TextStyle(fontSize: 18.sp), // ✅ Sizer OK
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        // ❌ Modal : PAS Sizer pour la hauteur
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9, // ✅ MediaQuery
            padding: const EdgeInsets.all(20), // ✅ Fixe ou Sizer selon besoin
            child: ...,
          ),
        );
      },
    ),
  );
}
```

---

## 📝 Résumé

### Utilisez Sizer pour :
✅ Tailles responsives (width, height)  
✅ Padding et margin adaptatifs  
✅ Tailles de texte responsives  
✅ Espacements cohérents  

### Utilisez les bonnes pratiques Flutter pour :
✅ Structure correcte des widgets  
✅ Gestion des contraintes  
✅ Expanded/Flexible appropriés  
✅ Éviter les conflits Column/Row  

### Combinaison gagnante :
🎯 **Sizer** pour la simplicité + **Bonnes pratiques** pour la stabilité = **Code robuste et responsive**

---

## 🔗 Ressources

- [Sizer Package](https://pub.dev/packages/sizer)
- [Flutter Layout Cheat Sheet](https://medium.com/flutter-community/flutter-layout-cheat-sheet-5363348d037e)
- [Understanding Constraints](https://docs.flutter.dev/ui/layout/constraints)

---

**N'oubliez pas** : Sizer est un outil, pas une solution magique. Les bonnes pratiques Flutter sont essentielles pour éviter les erreurs de layout ! 🚀
