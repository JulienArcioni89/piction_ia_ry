import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final String sessionId;

  const LoadingScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On récupère l'argument 'sessionId' si besoin
    final sessionId = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Beau dégradé sombre en fond
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            color: Colors.black54, // Légère transparence
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 8, // Pour un léger effet d'ombre
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône de chargement
                  const CircularProgressIndicator(
                    color: Colors.white, // Couleur du loader
                  ),
                  const SizedBox(height: 20),
                  // Texte d'attente
                  Text(
                    'En attente des autres joueurs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Affichage conditionnel du sessionId si besoin
                  if (sessionId != null) ...[
                    Text(
                      'Session ID : $sessionId',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}