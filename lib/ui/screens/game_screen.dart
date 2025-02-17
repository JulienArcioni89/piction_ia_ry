import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameScreen extends StatefulWidget {
  final String sessionId;

  const GameScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<dynamic> _challenges = [];
  int _currentChallengeIndex = 0;

  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _promptController = TextEditingController();
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchChallenges();
  }

  /// Requête API pour récupérer mes challenges à dessiner
  Future<void> _fetchChallenges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentImageUrl = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) {
      setState(() {
        _errorMessage = 'Error: User not authenticated';
        _isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}/myChallenges');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $jwt'});

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);

        if (rawData is List) {
          // On normalise la forme de forbidden_words ici
          final processed = rawData.map((challenge) {
            final raw = challenge['forbidden_words'];
            challenge['forbidden_words'] = _normalizeForbiddenWords(raw);
            return challenge;
          }).toList();

          setState(() {
            _challenges = processed;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Le serveur n’a pas renvoyé de liste de challenges.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error fetching challenges (status ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Exception: $e';
        _isLoading = false;
      });
    }
  }

  /// Transforme 'forbidden_words' en List<String> (si possible)
  List<String> _normalizeForbiddenWords(dynamic raw) {
    // Déjà une liste
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    // Chaîne encodée JSON => on décode
    if (raw is String) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Pas du JSON valide => on la met telle quelle
        return raw.isNotEmpty ? [raw] : [];
      }
      return raw.isNotEmpty ? [raw] : [];
    }
    // Sinon (null, etc.)
    return [];
  }

  /// Challenge en cours
  Map<String, dynamic>? get _currentChallenge {
    if (_challenges.isEmpty) return null;
    if (_currentChallengeIndex < 0 || _currentChallengeIndex >= _challenges.length) return null;
    return _challenges[_currentChallengeIndex];
  }

  /// Construit la phrase type "un chien sur une moto"
  String _buildChallengePhrase(Map<String, dynamic> c) {
    final list = [
      if (c['first_word'] != null) c['first_word'],
      if (c['second_word'] != null) c['second_word'],
      if (c['third_word'] != null) c['third_word'],
      if (c['fourth_word'] != null) c['fourth_word'],
      if (c['fifth_word'] != null) c['fifth_word'],
    ];
    final phrase = list.join(' ');
    return phrase.isEmpty ? 'Aucun mot' : phrase;
  }

  /// Génération d’image via POST /draw
  Future<void> _generateImage() async {
    final challenge = _currentChallenge;
    if (challenge == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt == null) {
      setState(() {
        _errorMessage = 'Error: User not authenticated';
        _isLoading = false;
      });
      return;
    }

    final challengeId = challenge['id'];
    final prompt = _promptController.text;

    try {
      final url = Uri.parse(
        'https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}/challenges/$challengeId/draw',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: json.encode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final updatedChallenge = json.decode(response.body);
        final imageUrl = updatedChallenge['image_path'];
        setState(() {
          _currentImageUrl = imageUrl;
          _isLoading = false;
        });
      } else {
        print('Error: ${response.body}');
        setState(() {
          _errorMessage = 'Erreur de génération (${response.body})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Exception: $e';
        _isLoading = false;
      });
    }
  }

  /// Envoyer au devineur => challenge suivant ou fin
  void _sendToGuesser() {
    if (_currentChallengeIndex < _challenges.length - 1) {
      setState(() {
        _currentChallengeIndex++;
        _promptController.clear();
        _currentImageUrl = null;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DrawingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _currentChallenge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes challenges à relever'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.white),
        )
            : (challenge == null || _errorMessage != null)
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage ?? 'Aucun challenge disponible',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        )
            : SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Carte du challenge
                Card(
                  color: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Challenge ${_currentChallengeIndex + 1}/${_challenges.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _buildChallengePhrase(challenge),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        // Affichage normal des mots interdits
                        Text(
                          'Mots interdits : ${_buildForbiddenString(challenge['forbidden_words'])}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Prompt (champ de saisie)
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    labelText: 'Décris ton image (prompt)',
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  autofocus: true, // Force l’apparition du clavier
                ),
                const SizedBox(height: 10),

                // Image générée
                if (_currentImageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _currentImageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Text('Erreur de chargement'));
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: 300,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black12,
                    ),
                    child: const Center(
                      child: Text(
                        'Aucune image générée',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _generateImage,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Générer / Régénérer (-50pts)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _sendToGuesser,
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer au devineur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Transforme la liste de mots interdits en une chaîne lisible
  String _buildForbiddenString(dynamic val) {
    if (val is List<String>) {
      return val.join(', ');
    }
    if (val is List) {
      return val.map((e) => e.toString()).join(', ');
    }
    return val?.toString() ?? '';
  }
}

/// Écran final après tout
class DrawingScreen extends StatelessWidget {
  const DrawingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All done !'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Il n\'y a plus de challenges à dessiner !',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}