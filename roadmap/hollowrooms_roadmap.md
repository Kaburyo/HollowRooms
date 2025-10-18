# 🗺️ ROADMAP - HollowRooms
## Projet de jeu type "The Binding of Isaac" sur Godot 4.5

---

## 📊 LÉGENDE
- ⏳ **En attente** - Pas encore commencé
- 🔄 **En cours** - Étape actuelle
- ✅ **Terminé** - Validation reçue
- 🔒 **Bloqué** - Nécessite une validation/décision

---

# PHASE 1 : NETTOYAGE & FONDATIONS 🧹

## Objectif
Nettoyer le code existant, supprimer les duplications, et établir une base solide pour le développement futur.

---

### ⏳ ÉTAPE 1.1 : Audit initial
**Objectif** : Vérifier l'état actuel du projet et identifier ce qui est utilisé

**Actions** :
- [ ] Ouvrir `main.tscn` dans Godot
- [ ] Vérifier quel node joueur est instancié (Grim ou Player)
- [ ] Lister tous les fichiers Player.* dans le projet
- [ ] Prendre une capture d'écran de l'arbre de scène de main.tscn

**Questions à valider** :
- Le node joueur s'appelle-t-il "Grim" ?
- Y a-t-il d'autres scènes qui utilisent Player.tscn ?

---

### ⏳ ÉTAPE 1.2 : Supprimer l'ancien système Player
**Objectif** : Éliminer la duplication entre player.gd et grim.gd

**Fichiers à supprimer** :
- `res://actors/player/player.gd`
- `res://actors/player/Player.tscn`
- `res://actors/player/2D.png` (si inutilisé)

**Actions** :
1. Faire un backup du projet (ZIP ou commit Git)
2. Supprimer les fichiers listés ci-dessus
3. Tester que le jeu lance toujours (F5)
4. Vérifier que Grim se déplace et tire correctement

**✅ Validation** : Le jeu fonctionne sans erreurs console

---

### ⏳ ÉTAPE 1.3 : Simplifier Grim (retirer tête séparée)
**Objectif** : Nettoyer le système d'animation de Grim pour utiliser uniquement le Body

**Modifications dans `Grim.tscn`** :
- Supprimer le node `HeadSocket` et ses enfants
- Garder uniquement `Body` (AnimatedSprite2D)

**Modifications dans `grim.gd`** :
- Retirer toutes les références à `head`, `head_socket`, `head_offset`
- Simplifier `set_move_state()` pour gérer uniquement `body`
- Simplifier `update_facing()` pour gérer uniquement `body`

**✅ Validation** : Grim s'anime correctement avec son sprite corps+tête unifié

---

### ⏳ ÉTAPE 1.4 : Supprimer le système de respawn debug
**Objectif** : Retirer le code de respawn qui ne fonctionne pas actuellement

**Fichiers à modifier** :
- `main.gd` : Retirer les variables `@export debug_enemy_*`
- `EnemyBlob.gd` : Retirer le code de respawn debug
- `enemy_skull.gd` : Retirer le code de respawn debug

**Remplacer par** :
- Mort définitive des ennemis (queue_free)
- Note : On pourra réimplémenter proprement plus tard si besoin

**✅ Validation** : Les ennemis meurent et disparaissent proprement

---

### ⏳ ÉTAPE 1.5 : Documenter les Collision Layers
**Objectif** : Clarifier le système de collisions avec des commentaires

**Créer un nouveau fichier** : `res://docs/COLLISION_LAYERS.md`

**Contenu** :
```
Layer 1 : World (murs, obstacles statiques)
Layer 2 : PlayerBody (CharacterBody2D du joueur)
Layer 3 : EnemyBody (CharacterBody2D ennemis)
Layer 4 : PlayerHurtbox (Zone de dégâts DU joueur)
Layer 5 : EnemyHurtbox (Zone de dégâts DES ennemis)
Layer 6 : PlayerBullet (Projectiles du joueur)
Layer 7 : Items (Objets ramassables)
```

**Ajouter des commentaires** dans chaque script concerné

**✅ Validation** : Documentation claire et accessible

---

# PHASE 2 : ARCHITECTURE PROPRE 🏗️

## Objectif
Créer une base de code modulaire, réutilisable et suivant les bonnes pratiques

---

### ⏳ ÉTAPE 2.1 : Créer BaseEnemy.gd
**Objectif** : Factoriser le code commun des ennemis

**Créer le fichier** : `res://actors/enemies/BaseEnemy.gd`

**Contenu** :
- Gestion HP (max_hp, hp, take_damage, die)
- Système de flash visuel lors des dégâts
- Gestion des collisions avec les balles
- Mouvement de base avec rebonds sur murs
- Poursuite du joueur (optionnelle)

**Faire hériter** :
- `EnemyBlob.gd extends BaseEnemy`
- `enemy_skull.gd extends BaseEnemy`

**✅ Validation** : Les ennemis fonctionnent identiquement mais avec moins de code dupliqué

---

### ⏳ ÉTAPE 2.2 : Créer GameConstants.gd (Autoload)
**Objectif** : Centraliser toutes les constantes du jeu

**Créer le fichier** : `res://singletons/GameConstants.gd`

**Contenu** :
```gdscript
extends Node

# === PLAYER ===
const PLAYER_MAX_HEARTS := 12
const PLAYER_HEARTS_PER_ROW := 6
const PLAYER_INVULN_TIME := 0.7
const PLAYER_FIRE_COOLDOWN := 0.60

# === ENEMIES ===
const ENEMY_FLASH_COLOR := Color(1.0, 0.5, 0.5)
const ENEMY_FLASH_DURATION := 0.16

# === PROJECTILES ===
const BULLET_LIFETIME := 1.5
const BULLET_SPEED := 1000.0
const BULLET_GRAVITY := 120.0

# === COLLISION LAYERS ===
const LAYER_WORLD := 1
const LAYER_PLAYER_BODY := 2
const LAYER_ENEMY_BODY := 4
# ... etc
```

**Ajouter comme Autoload** dans Project Settings

**✅ Validation** : Constantes accessibles partout via `GameConstants.PLAYER_MAX_HEARTS`

---

### ⏳ ÉTAPE 2.3 : Réorganiser la structure des dossiers
**Objectif** : Organisation logique et professionnelle

**Structure proposée** :
```
res://
├── actors/
│   ├── player/
│   │   └── Grim/
│   │       ├── grim.gd
│   │       ├── Grim.tscn
│   │       ├── PlayerHealth.gd
│   │       └── sprites/
│   ├── enemies/
│   │   ├── BaseEnemy.gd
│   │   ├── EnemyBlob/
│   │   └── EnemySkull/
│   └── projectiles/
├── items/
│   ├── money/
│   └── pickups/
├── rooms/
│   └── level1/
├── ui/
├── audio/
├── singletons/
│   ├── GameEvents.gd
│   ├── GameConstants.gd
│   └── GameManager.gd (à créer)
└── docs/
```

**✅ Validation** : Fichiers bien organisés, faciles à retrouver

---

### ⏳ ÉTAPE 2.4 : Standardiser le système de santé
**Objectif** : Utiliser le même pattern pour joueur ET ennemis

**Modifications** :
- Les ennemis devraient aussi avoir un node `Health` séparé
- Créer `res://components/Health.gd` (script générique)
- `PlayerHealth.gd` et `EnemyHealth.gd` héritent de `Health.gd`

**Avantages** :
- Code plus lisible
- Plus facile à débugger
- Système unifié

**✅ Validation** : Santé gérée de manière cohérente partout

---

# PHASE 3 : SYSTÈME CENTRAL 🎮

## Objectif
Créer un système de gestion centralisé pour faciliter les modifications futures

---

### ⏳ ÉTAPE 3.1 : Créer GameManager (Autoload)
**Objectif** : Chef d'orchestre du jeu

**Créer le fichier** : `res://singletons/GameManager.gd`

**Responsabilités** :
- Gérer l'état du jeu (menu, gameplay, pause, game over)
- Stocker les statistiques de run (kills, temps, etc.)
- Gérer la progression (level actuel, salles visitées)
- Centraliser les références importantes (player, camera)

**Exemple de structure** :
```gdscript
extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
var current_state: GameState = GameState.MENU

var player: CharacterBody2D
var current_room: Node2D
var kills_this_run: int = 0
var coins_collected: int = 0
```

**✅ Validation** : GameManager accessible et fonctionnel

---

### ⏳ ÉTAPE 3.2 : Améliorer main.gd comme scène bootstrap
**Objectif** : main.gd devient le point d'entrée qui initialise tout

**Restructurer main.gd** :
```gdscript
extends Node2D

func _ready():
    _initialize_game()
    _setup_audio()
    _setup_camera()
    _start_game()

func _initialize_game():
    # Enregistre les références importantes
    GameManager.player = $Grim
    GameManager.current_room = $Room_01
    # etc.
```

**✅ Validation** : main.gd est clair et organisé

---

### ⏳ ÉTAPE 3.3 : Système de configuration centralisé
**Objectif** : Permettre de modifier facilement les paramètres du jeu

**Créer** : `res://singletons/GameConfig.gd`

**Utilité** :
- Charger/sauvegarder les settings (volume, résolution, etc.)
- Difficulté du jeu
- Paramètres de debug (vitesse du jeu, god mode, etc.)

**✅ Validation** : Système de config fonctionnel

---

### ⏳ ÉTAPE 3.4 : Créer un système d'events robuste
**Objectif** : Améliorer GameEvents.gd pour qu'il soit plus complet

**Ajouter plus de signaux** :
- `enemy_killed(enemy: Node)`
- `player_took_damage(amount: float)`
- `room_cleared()`
- `item_collected(item: Node)`
- etc.

**Avantages** :
- Découplage entre systèmes
- Plus facile d'ajouter des effets/réactions

**✅ Validation** : Système d'events complet et utilisé partout

---

# PHASE 4 : FEATURES DE GAMEPLAY 🎯

## Objectif
Ajouter les mécaniques core du jeu (cette phase sera détaillée plus tard)

---

### ⏳ ÉTAPE 4.1 : Système de salles procédural
- Génération de layout
- Transitions entre salles
- Portes avec conditions (clés, ennemis, etc.)

---

### ⏳ ÉTAPE 4.2 : Système d'items et power-ups
- Items passifs
- Items actifs
- Synergies

---

### ⏳ ÉTAPE 4.3 : Plus de variété d'ennemis
- Nouveaux types
- Patterns d'attaque différents
- Boss

---

### ⏳ ÉTAPE 4.4 : UI complète
- Affichage des pièces
- Mini-map
- Menu pause

---

# 📝 NOTES & DÉCISIONS

## Décisions validées
- ✅ Utiliser `grim.gd` comme script joueur principal
- ✅ Supprimer le système de respawn debug non fonctionnel
- ✅ Simplifier les animations de Grim (pas de tête séparée pour l'instant)
- ✅ Système de pièces en basse priorité

## Questions en suspens
- Aucune pour le moment

## Idées futures
- Système de respawn propre à réimplémenter
- Retour à la tête/corps séparés pour armes CàC
- Affichage UI des pièces

---

**Dernière mise à jour** : 19 octobre 2025
**Version Godot** : 4.5.1.stable
**Étape actuelle** : Audit initial (1.1)