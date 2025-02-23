import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'loading_screen.dart';
import 'drawing_screen.dart';
import 'guess_screen.dart';

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
    _checkGameStatusGuessing();
  }

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
            _errorMessage = 'Le serveur na pas renvoyé de liste de challenges.';
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

  List<String> _normalizeForbiddenWords(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return raw.isNotEmpty ? [raw] : [];
      }
      return raw.isNotEmpty ? [raw] : [];
    }
    return [];
  }

  Map<String, dynamic>? get _currentChallenge {
    if (_challenges.isEmpty) return null;
    if (_currentChallengeIndex < 0 || _currentChallengeIndex >= _challenges.length) return null;
    return _challenges[_currentChallengeIndex];
  }

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

  void _sendToGuesser() {
    if (_currentChallengeIndex < _challenges.length - 1) {
      setState(() {
        _currentChallengeIndex++;
        _promptController.clear();
        _currentImageUrl = null;
      });
    }
  }

  void _finishAndSend() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(sessionId: widget.sessionId),
      ),
    );
    _checkGameStatusGuessing();
  }

  Future<void> _checkGameStatusGuessing() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwt = prefs.getString('jwt');

    if (jwt == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: User not authenticated';
        });
      }
      return;
    }

    final url = Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}');
    final timeout = Duration(minutes: 10);
    final interval = Duration(seconds: 5);
    print("Début de la vérification du statut pour la session : ${widget.sessionId}");

    try {
      await Future.doWhile(() async {
        try {
          final response = await http.get(
            url,
            headers: {
              'Authorization': 'Bearer $jwt',
            },
          );

          if (response.statusCode == 200) {
            final gameData = json.decode(response.body);
            print("Statut actuel : ${gameData['status']}");
            
            if (gameData['status'] == 'guessing') {
              //if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GuessScreen(sessionId: widget.sessionId),
                  ),
                );
              //}
              return false; // On arrête la boucle uniquement si on est en mode guessing
            }
            return true; // On continue la boucle si le statut n'est pas 'guessing'
          }
          
          print("Erreur ${response.statusCode} : ${response.body}");
          return true; // On continue la boucle même en cas d'erreur 
          
        } catch (e) {
          print("Erreur lors de la vérification : $e");
          return true; // On continue la boucle même en cas d'erreur
        }

        await Future.delayed(interval);
        return mounted;
      }).timeout(timeout);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final challenge = _currentChallenge;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Saisie des challenges',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
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
                Card(
                  color: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 8,
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _buildChallengePhrase(challenge),
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mots interdits : ${_buildForbiddenString(challenge['forbidden_words'])}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: 'Décris ton image (prompt)',
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                          return const Center(
                              child: Text('Erreur de chargement', style: TextStyle(color: Colors.white)));
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
                          backgroundColor: Color(0xFFB39DDB),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _generateImage,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Générer / Régénérer (-50pts)', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_currentChallengeIndex < _challenges.length - 1)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFB39DDB),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _sendToGuesser,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('Envoyer au devineur', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFB39DDB),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _finishAndSend,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('Terminer et envoyer', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

class DrawingScreen extends StatelessWidget {
  const DrawingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vous avez fini !'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            'Il n\'y a plus de challenges à dessiner !',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}