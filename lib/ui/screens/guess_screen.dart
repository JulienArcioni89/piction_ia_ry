import 'package:flutter/material.dart';

class GuessScreen extends StatelessWidget {
  final String sessionId;
  
  const GuessScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Chrono 232'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Scores des équipes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Equipe bleue: 89', style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(width: 20),
                Text('Equipe rouge: 93', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            // Image affichée
            Image.network('https://picsum.photos/200/300', height: 200),
            const SizedBox(height: 20),
            // Question posée au joueur
            Text(
              'Qu\'as dessiné votre équipier ?',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            // Suggestions
            Wrap(
              spacing: 8.0,
              children: const [
                Chip(
                  label: Text('Une'),
                  backgroundColor: Colors.grey,
                ),
                Chip(
                  label: Text('mot 1'),
                  backgroundColor: Colors.green,
                ),
                Chip(
                  label: Text('sur un'),
                  backgroundColor: Colors.green,
                ),
                Chip(
                  label: Text('mot 2'),
                  backgroundColor: Colors.grey,
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Action pour abandonner
              },
              child: const Text('Abandonner et devenir dessinateur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Bouton rouge
              ),
            ),
          ],
        ),
      ),
    );
  }
}
