# 📱 Gestion des Dépenses Personnelles

Application mobile **Android** développée avec **Flutter** et **Firebase**, permettant aux utilisateurs de gérer efficacement leurs dépenses personnelles, leur salaire mensuel et leurs primes, tout en visualisant leur situation financière en temps réel.

---

## 🧾 Description du projet

Ce projet a pour objectif de proposer une solution mobile simple, intuitive et sécurisée pour le suivi des finances personnelles.  
L’utilisateur peut :
- définir son salaire mensuel,
- ajouter des primes,
- enregistrer ses dépenses quotidiennes,
- consulter un tableau de bord mensuel avec le reste disponible,
- accéder à l’historique de ses dépenses.

Les données sont stockées de manière sécurisée grâce à **Firebase**.

---

## 🎯 Objectifs du projet

- Faciliter la gestion des dépenses personnelles
- Offrir une vision claire du budget mensuel
- Automatiser le calcul du reste disponible
- Garantir la sécurité et la persistance des données
- Proposer une application mobile moderne et performante

---

## ⚙️ Fonctionnalités principales

- 🔐 Authentification sécurisée (Inscription / Connexion)
- 👤 Gestion du profil utilisateur
- 💰 Définition du salaire mensuel de base
- 🎁 Ajout de primes mensuelles
- 🧾 Ajout et gestion des dépenses (montant, catégorie, date)
- 📊 Tableau de bord mensuel (salaire, dépenses, reste)
- 📅 Consultation des dépenses par mois
- 🚪 Déconnexion sécurisée

---

## 🛠️ Technologies utilisées

### 📱 Mobile
- **Flutter**
- **Dart**

### ☁️ Backend / Cloud
- **Firebase Authentication**
- **Cloud Firestore**
- **Firebase Storage** (optionnel)

### 🧑‍💻 Outils de développement
- **Android Studio** (SDK Android, émulateur)
- **Visual Studio Code**
- **Git & GitHub**

---

## 🗂️ Structure du projet

lib/
├── main.dart
├── firebase_options.dart
├── pages/
│ ├── login_page.dart
│ ├── register_page.dart
│ ├── home_page.dart
│ ├── profile_page.dart
│ ├── add_expense_page.dart
│ └── monthly_expenses_page.dart
├── utils/
│ └── animated_route.dart
assets/
├── icon/
└── splash/

---

## 🔐 Sécurité des données

- Accès aux données limité à l’utilisateur authentifié
- Chaque utilisateur ne peut consulter que ses propres informations
- Règles Firestore basées sur `request.auth.uid`

---

## ▶️ Lancer le projet en local

### Prérequis
- Flutter installé
- Android Studio ou VS Code
- Un téléphone Android ou un émulateur
- Un projet Firebase configuré

### Étapes
```bash
flutter pub get
flutter run
