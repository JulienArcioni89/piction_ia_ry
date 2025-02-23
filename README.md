# Pictionnary - Application Flutter - JULIEN ARCIONI

Une application de jeu Pictionnary où les joueurs peuvent créer des challenges, générer des images via IA et deviner les dessins des autres joueurs.

## 🚀 Installation

### Prérequis
- Flutter (Flutter 3.24.1)
- Dart (Dart SDK version: 3.5.1)
- Un éditeur de code (Testé avec AndroidStudio 2024.2.1 Patch 3)
- **Simulateur iOs (Attention, ce projet n'a pas été testé sous simulateur Android !)**
- Git

## 📝 Notes importantes

- L'application nécessite une connexion internet
- La génération d'images peut prendre quelques secondes
- Le jeu se termine quand tous les challenges ont été devinés
- **Ne pas faire de retour arrière** sous risque de ne pas pouvoir continuer la game !
- **Ne pas remplir ses propres challenges via l'API** mais via l'application afin de pouvoir continuer la game

## Étapes d'installation

1. Clonez le repository :
   ```bash
   git clone
   
2. Accédez au dossier du projet :
   ```bash
   cd pictionnary
   ```
   
3. Lancer main.dart :
   ```bash
   flutter run
   ```

## 📱 Fonctionnalités

### 1. Création de compte et connexion
- Créez un compte avec un nom d'utilisateur et un mot de passe
- Connectez-vous à votre compte existant

### 2. Création d'une partie
- Créez une nouvelle session de jeu
- Invitez d'autres joueurs via un code de session
- Choisissez votre équipe (Rouge ou Bleue)

### 3. Phase de création des challenges
- Chaque joueur crée 3 challenges
- Un challenge est composé de :
  - Une phrase à deviner
  - Des mots interdits

### 4. Phase de dessin
- Recevez des challenges à dessiner
- Générez des images via l'IA en écrivant des prompts
- Possibilité de régénérer l'image
- Envoyez vos dessins aux devineurs

### 5. Phase de devinettes
- Devinez les dessins des autres joueurs
- Proposez des réponses
- Gagnez des points en devinant correctement

## 🎮 Comment jouer

1. **Création de la partie**
   - Un joueur crée une nouvelle partie
   - Les autres joueurs rejoignent avec le code de session
   - Chaque joueur choisit son équipe

2. **Rédaction des challenges**
   - Chaque joueur écrit 3 challenges
   - Utilisez des mots simples mais créatifs
   - Ajoutez des mots interdits pour corser le jeu

3. **Phase de dessin**
   - Recevez des challenges à dessiner
   - Écrivez un prompt précis pour l'IA
   - Générez l'image
   - Validez et envoyez au devineur

4. **Phase de devinettes**
   - Observez l'image générée
   - Proposez votre réponse
   - Validez quand vous pensez avoir trouvé

## 🔧 Architecture technique

- Frontend : Flutter/Dart
- Backend : API REST (https://pictioniary.wevox.cloud)
- Génération d'images : API d'IA
- Stockage local : SharedPreferences pour le JWT