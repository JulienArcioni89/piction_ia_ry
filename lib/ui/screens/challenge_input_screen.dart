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
            'forbidden_words': _forbiddenWordsController.text.split(',').map((word) => word.trim()).toList(),
          });
          _loading = false;
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
        title: const Text('Ajouter un challenge'),
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
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _firstChoice = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Premier choix (un/une)'),
              ),
              TextFormField(
                controller: _firstWordController,
                decoration: const InputDecoration(labelText: 'Premier mot'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le premier mot';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _secondChoice,
                items: ['sur', 'dans'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _secondChoice = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Troisième choix (sur/dans)'),
              ),
              DropdownButtonFormField<String>(
                value: _thirdChoice,
                items: ['un', 'une'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _thirdChoice = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Quatrième choix (un/une)'),
              ),
              TextFormField(
                controller: _secondWordController,
                decoration: const InputDecoration(labelText: 'Deuxième mot'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le deuxième mot';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _forbiddenWordsController,
                decoration: const InputDecoration(labelText: 'Mots interdits (séparés par des virgules)'),
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
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
          Navigator.pushReplacementNamed(context, '/game_screen');
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
      appBar: AppBar(
        title: const Text('Saisie des challenges'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showChallengeModal,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_challenges.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Challenges créés: ${_challenges.length}/3', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._challenges.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> challenge = entry.value;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${challenge['first_word']} ${challenge['second_word']} ${challenge['third_word']} ${challenge['fourth_word']} ${challenge['fifth_word']}',
                              style: const TextStyle(fontSize: 16),
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
                    );
                  }),
                ],
              ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_challenges.length == 3)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/loading_screen');
                    _checkGameStatus();
                  },
                  child: const Text('Envoyer'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
