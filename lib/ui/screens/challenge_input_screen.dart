import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pictionnary/ui/screens/game_screen.dart';
import 'package:pictionnary/ui/screens/loading_screen.dart';

class ChallengeInputScreen extends StatefulWidget {
  final String sessionId;

  const ChallengeInputScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  _ChallengeInputScreenState createState() => _ChallengeInputScreenState();
}

class _ChallengeInputScreenState extends State<ChallengeInputScreen> {
  final List<Map<String, dynamic>> _challenges = [];
  bool _loading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _firstWordController = TextEditingController();
  final _secondWordController = TextEditingController();
  final _forbiddenWordsController = TextEditingController();

  String _firstChoice = 'un';
  String _secondChoice = 'sur';
  String _thirdChoice = 'un';

  Future<void> _submitChallenge() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwt = prefs.getString('jwt');

      if (jwt == null) {
        setState(() {
          _errorMessage = 'Erreur : Utilisateur non authentifié';
          _loading = false;
        });
        return;
      }

      final url = Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}/challenges');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: json.encode({
          'first_word': _firstChoice,
          'second_word': _firstWordController.text,
          'third_word': _secondChoice,
          'fourth_word': _thirdChoice,
          'fifth_word': _secondWordController.text,
          'forbidden_words': _forbiddenWordsController.text.split(',').map((word) => word.trim()).toList(),
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _challenges.add({
            'first_word': _firstChoice,
            'second_word': _firstWordController.text,
            'third_word': _secondChoice,
            'fourth_word': _thirdChoice,
            'fifth_word': _secondWordController.text,
            'forbidden_words': _forbiddenWordsController.text
                .split(',')
                .map((word) => word.trim())
                .toList(),
          });
          _loading = false;
          print("Session ID challenge : ${widget.sessionId}");
        });

        if (_challenges.length == 3) {
          Navigator.pop(context);
        } else {
          _clearForm();
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de l\'envoi du challenge (${response.body})';
          _loading = false;
        });
      }
    }
  }

  void _clearForm() {
    _firstWordController.clear();
    _secondWordController.clear();
    _forbiddenWordsController.clear();
  }

  void _showChallengeModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Ajouter un challenge',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _firstChoice,
                items: ['un', 'une'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                dropdownColor: Colors.black87,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _firstChoice = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Premier choix (un/une)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _firstWordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Premier mot',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le premier mot';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _secondChoice,
                items: ['sur', 'dans'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                dropdownColor: Colors.black87,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _secondChoice = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Troisième choix (sur/dans)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _thirdChoice,
                items: ['un', 'une'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                dropdownColor: Colors.black87,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _thirdChoice = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Quatrième choix (un/une)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _secondWordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Deuxième mot',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le deuxième mot';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _forbiddenWordsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '3 Mots interdits (mot1,mot2,mot3)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer les mots interdits';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFB39DDB),
            ),
            onPressed: _submitChallenge,
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkGameStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwt = prefs.getString('jwt');

    if (jwt == null) {
      setState(() {
        _errorMessage = 'Erreur : Utilisateur non authentifié';
      });
      return;
    }

    final url = Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}');
    while (true) {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        final gameData = json.decode(response.body);
        if (gameData['status'] == 'drawing') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(sessionId: widget.sessionId),
            ),
          );
          break;
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la vérification du statut de la partie';
        });
        break;
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Saisie des challenges'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showChallengeModal,
        backgroundColor: Color(0xFFB39DDB),
        child: const Icon(Icons.add),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_challenges.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challenges créés: ${_challenges.length}/3',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._challenges.asMap().entries.map((entry) {
                        final index = entry.key;
                        final challenge = entry.value;

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Card(
                            color: Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Challenge ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${challenge['first_word']} ${challenge['second_word']} '
                                        '${challenge['third_word']} ${challenge['fourth_word']} '
                                        '${challenge['fifth_word']}',
                                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: (challenge['forbidden_words'] as List<String>).map((word) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          word,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                if (_loading) const CircularProgressIndicator(color: Colors.white),
                if (_challenges.length == 3)
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFB39DDB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/loading_screen',
                          arguments: widget.sessionId,
                        );
                        _checkGameStatus();
                      },
                      child: const Text('Envoyer'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}