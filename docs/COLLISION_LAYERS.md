# 🎯 SYSTÈME DE COLLISION LAYERS
## HollowRooms - Documentation technique

---

## 📋 LAYERS DÉFINIES (Project Settings → Physics → 2D)

| Layer | Nom | Description | Utilisation |
|-------|-----|-------------|-------------|
| **1** | `World` | Murs, obstacles statiques, tiles | Bloque le mouvement du joueur et des ennemis |
| **2** | `PlayerBody` | CharacterBody2D du joueur | Corps physique de Grim |
| **3** | `EnemyBody` | CharacterBody2D des ennemis | Corps physiques des ennemis (Blob, Skull, etc.) |
| **4** | `PlayerHurtbox` | Area2D du joueur | Zone de dégâts **reçus** par le joueur (contact ennemis) |
| **5** | `EnemyHurtbox` | Area2D des ennemis | Zone de dégâts **reçus** par les ennemis (balles, contact) |
| **6** | `PlayerBullet` | Projectiles du joueur | Balles tirées par Grim |
| **7** | `Items` | Objets ramassables | Pièces, clés, cœurs, power-ups, etc. |

---

## 🔗 MATRICE D'INTERACTIONS

### **Joueur (Grim)**
- **CharacterBody2D** (Layer 2) :
  - ✅ **Collide avec** : World (Layer 1)
  - ❌ **Ne collide PAS avec** : Enemies, Bullets, Items
  
- **Hurtbox** (Layer 4 - Area2D) :
  - 👁️ **Détecte** : EnemyHurtbox (Layer 5) → pour contact avec ennemis
  - ⚙️ **Mask** : Layer 5

### **Ennemis (Blob, Skull, etc.)**
- **CharacterBody2D** (Layer 3) :
  - ✅ **Collide avec** : World (Layer 1)
  - ❌ **Ne collide PAS avec** : Player, autres ennemis, items
  
- **Hurtbox** (Layer 5 - Area2D) :
  - 👁️ **Détecte** : PlayerBullet (Layer 6), PlayerHurtbox (Layer 4)
  - ⚙️ **Mask** : Layers 4 et 6

### **Projectiles du Joueur**
- **Area2D** (Layer 6) :
  - 👁️ **Détecte** : EnemyHurtbox (Layer 5), World (Layer 1) → pour détruire au contact du mur
  - ⚙️ **Mask** : Layers 1 et 5

### **Items**
- **Area2D** (Layer 7) :
  - 👁️ **Détecte** : PlayerHurtbox (Layer 4) → pour être ramassés
  - ⚙️ **Mask** : Layer 4

---

## 💡 BONNES PRATIQUES

### ✅ À FAIRE :
- **Toujours vérifier** les layers lors de la création d'un nouvel ennemi/projectile
- **Utiliser les groupes** en complément (ex: `"player"`, `"enemy"`, `"player_bullet"`)
- **Tester les collisions** après chaque modification

### ❌ À ÉVITER :
- Ne **jamais** mettre PlayerBody et EnemyBody en collision directe (utiliser les Hurtbox)
- Ne **jamais** faire collider les items avec le World (ils doivent traverser les murs)
- Ne **pas** utiliser les mêmes layers pour des rôles différents

---

## 🔧 MODIFICATION DES LAYERS

**Dans Godot** :
1. `Project` → `Project Settings...`
2. Onglet `Physics` → Section `2D`
3. Modifier les noms dans `Layer Names`

**ATTENTION** : Ne jamais changer le numéro d'un layer existant, seulement son nom !

---

## 📝 EXEMPLES DE CONFIGURATION

### **Grim (Player)**
```
CharacterBody2D "Grim":
  ├─ Collision Layer: 2 (PlayerBody)
  └─ Collision Mask: 1 (World)

Area2D "Hurtbox":
  ├─ Collision Layer: 4 (PlayerHurtbox)
  └─ Collision Mask: 5 (EnemyHurtbox)
```

### **EnemyBlob**
```
CharacterBody2D "EnemyBlob":
  ├─ Collision Layer: 3 (EnemyBody)
  └─ Collision Mask: 1 (World)

Area2D "Hurtbox":
  ├─ Collision Layer: 5 (EnemyHurtbox)
  └─ Collision Mask: 4,6 (PlayerHurtbox + PlayerBullet)
```

### **Bullet (Projectile joueur)**
```
Area2D "Bullet":
  ├─ Collision Layer: 6 (PlayerBullet)
  └─ Collision Mask: 1,5 (World + EnemyHurtbox)
```

---

## 🎮 LAYERS FUTURES (à ajouter plus tard)

| Layer | Nom suggéré | Usage |
|-------|-------------|-------|
| **8** | `EnemyBullet` | Projectiles tirés par les ennemis |
| **9** | `Traps` | Pièges (pics, trous, lave) |
| **10** | `Doors` | Portes entre les salles |

---

**Dernière mise à jour** : Octobre 2025  
**Version Godot** : 4.5.1.stable
