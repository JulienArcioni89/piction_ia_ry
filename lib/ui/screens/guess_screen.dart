import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pictionnary/ui/screens/end_game_screen.dart';

class GuessScreen extends StatefulWidget {
  final String sessionId;

  const GuessScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  _GuessScreenState createState() => _GuessScreenState();
}

class _GuessScreenState extends State<GuessScreen> {
  List<dynamic> _challengesToGuess = [];
  int _currentChallengeIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchChallengesToGuess();
  }

  Future<void> _fetchChallengesToGuess() async {
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

    try {
      final url = Uri.parse(
        'https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}/myChallengesToGuess',
      );
      
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _challengesToGuess = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la récupération des challenges (${response.statusCode})';
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

  Future<void> _submitAnswer(bool isResolved) async {
    if (_currentChallenge == null) return;

    setState(() {
      _isLoading = true;
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
      final challengeId = _currentChallenge!['id'];
      final url = Uri.parse(
        'https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}/challenges/$challengeId/answer',
      );
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'answer': _answerController.text,
          'is_resolved': isResolved,
        }),
      );

      if (response.statusCode == 200) {
        if (_currentChallengeIndex < _challengesToGuess.length - 1) {
          setState(() {
            _currentChallengeIndex++;
            _answerController.clear();
            _isLoading = false;
          });
        } else {
          // Tous les challenges ont été devinés
          //Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const EndGameScreen(),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de l\'envoi de la réponse (${response.statusCode})';
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

  Map<String, dynamic>? get _currentChallenge {
    if (_challengesToGuess.isEmpty) return null;
    if (_currentChallengeIndex >= _challengesToGuess.length) return null;
    return _challengesToGuess[_currentChallengeIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Devinez les dessins',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _currentChallenge == null
                    ? const Center(
                        child: Text(
                          'Aucun challenge à deviner',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Challenge ${_currentChallengeIndex + 1}/${_challengesToGuess.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_currentChallenge!['image_path'] != null)
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _currentChallenge!['image_path'],
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text(
                                          'Erreur de chargement de l\'image',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _answerController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Votre réponse',
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.white54),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
/*                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _submitAnswer(false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Essayer'),
                                  ),
                                ),*/
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _submitAnswer(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Valider'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
