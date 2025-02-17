import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameScreen extends StatefulWidget {
  //const GameScreen({Key? key}) : super(key: key);

  final String sessionId;

  const GameScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? sessionId;
  List<dynamic> challenges = [];
  bool isLoading = true;
  String? errorMessage;


  Future<void> _fetchChallenges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwt = prefs.getString('jwt');

    if (jwt == null) {
      setState(() {
        errorMessage = 'Error: User not authenticated';
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/$sessionId/myChallenges');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        challenges = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Error fetching challenges';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Chrono 200'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your challenge:', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: challenges.map<Widget>((challenge) {
                        return Chip(
                          label: Text(challenge['word']),
                          backgroundColor: Colors.red,
                          labelStyle: const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Image.network('https://picsum.photos/200/300', height: 200),
            const SizedBox(height: 20),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate image (-50pts)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                  label: const Text('Send to guesser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'The bird ingredient of KFC menus on stacked bricks',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Additional action'),
            ),
          ],
        ),
      ),
    );
  }
}