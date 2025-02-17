import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pictionnary/ui/screens/challenge_input_screen.dart';

class TeamCompositionScreen extends StatefulWidget {
  final String sessionId;

  const TeamCompositionScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  _TeamCompositionScreenState createState() => _TeamCompositionScreenState();
}

class _TeamCompositionScreenState extends State<TeamCompositionScreen> {
  String? jwt;
  String? creatorId;
  String? userId;
  List<String> blueTeam = [];
  List<String> redTeam = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadJwtAndShowTeamSelectionModal();
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchTeamComposition();
      _checkGameStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadJwtAndShowTeamSelectionModal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');

    if (jwt != null) {
      final jwtDecoded = json.decode(
        utf8.decode(base64.decode(base64.normalize(jwt!.split(".")[1]))),
      );
      userId = jwtDecoded['id'].toString();
      await _fetchTeamComposition();
      _showTeamSelectionModal();
    } else {
      _showMessage("Impossible de récupérer le JWT.");
    }
  }

  Future<void> _fetchTeamComposition() async {
    final response = await http.get(
      Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      final gameSession = json.decode(response.body);
      List<dynamic> blueTeamIds = gameSession['blue_team'] ?? [];
      List<dynamic> redTeamIds = gameSession['red_team'] ?? [];
      creatorId = gameSession['player_id'].toString(); // ID of the session creator

      List<String> blueTeamNames = await Future.wait(blueTeamIds.map((id) => _fetchPlayerName(id)));
      List<String> redTeamNames = await Future.wait(redTeamIds.map((id) => _fetchPlayerName(id)));

      setState(() {
        blueTeam = blueTeamNames;
        redTeam = redTeamNames;
      });
    } else {
      _showMessage("Impossible de récupérer les détails de la session.");
    }
  }

  Future<String> _fetchPlayerName(int playerId) async {
    final response = await http.get(
      Uri.parse('https://pictioniary.wevox.cloud/api/players/$playerId'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      final playerData = json.decode(response.body);
      return playerData['name'] ?? 'Inconnu';
    } else {
      return 'Inconnu';
    }
  }

  Future<void> _showTeamSelectionModal() async {
    final response = await http.get(
      Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      final gameSession = json.decode(response.body);
      final currentBlueTeam = gameSession['blue_team'] ?? [];
      final currentRedTeam = gameSession['red_team'] ?? [];

      bool canJoinRed = currentRedTeam.length < 2;
      bool canJoinBlue = currentBlueTeam.length < 2;

      if (canJoinRed || canJoinBlue) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Choisissez une équipe'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canJoinBlue)
                    ElevatedButton(
                      onPressed: () {
                        _joinTeam("blue");
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                      ),
                      child: const Text('Rejoindre l\'équipe Bleue'),
                    ),
                  if (canJoinRed)
                    ElevatedButton(
                      onPressed: () {
                        _joinTeam("red");
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                      ),
                      child: const Text('Rejoindre l\'équipe Rouge'),
                    ),
                ],
              ),
            );
          },
        );
      } else {
        _showMessage("Aucune place disponible dans les équipes.");
      }
    } else {
      _showMessage("Impossible de récupérer les détails de la session.");
    }
  }

  Future<void> _joinTeam(String color) async {
    try {
      final joinResponse = await http.post(
        Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}/join'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: json.encode({'color': color}),
      );

      if (joinResponse.statusCode == 200) {
        _showMessage("Rejoint avec succès l'équipe $color !");
        await _fetchTeamComposition();
      } else {
        _showMessage("Échec de la jonction de l'équipe. Veuillez réessayer.");
      }
    } catch (error) {
      _showMessage("Une erreur s'est produite : $error");
    }
  }

  Future<void> _startGame() async {
    final response = await http.post(
      Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}/start'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      _showMessage("La partie a commencé !");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeInputScreen(sessionId: widget.sessionId),
        ),
      );
    } else {
      _showMessage("Erreur lors du démarrage de la partie.");
    }
  }

  Future<void> _checkGameStatus() async {
    final response = await http.get(
      Uri.parse('https://pictioniary.wevox.cloud/api/game_sessions/${widget.sessionId}'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      final gameSession = json.decode(response.body);
      if (gameSession['status'] == 'challenge') {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeInputScreen(sessionId: widget.sessionId),
          ),
        );
      }
    } else {
      _showMessage("Erreur lors de la vérification du statut de la partie.");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    bool isCreator = userId == creatorId;
    bool canStartGame = blueTeam.length == 2 && redTeam.length == 2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Composition des équipes',
          style: TextStyle(
            color: Colors.pinkAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Equipe Bleue',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              _buildTeamTile(context, color: Colors.pinkAccent, players: blueTeam),
              const SizedBox(height: 40),
              Text(
                'Equipe Rouge',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              _buildTeamTile(context, color: Colors.pinkAccent, players: redTeam),
              const Spacer(),
              if (isCreator && canStartGame)
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Lancer la partie', style: TextStyle(color: Colors.white)),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _showQRCodeDialog(context, widget.sessionId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code, color: Colors.white),
                label: const Text('Inviter des amis', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Text(
                'La partie sera lancée par l\'hôte une fois les joueurs au complet',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamTile(BuildContext context, {required Color color, required List<String> players}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: players.isNotEmpty
            ? players.map((player) => Text(player, style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white))).toList()
            : [
          Text(
            '<en attente>',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '<en attente>',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Invitez vos amis en partageant ce QR code !',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: sessionId,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                  ),
                  child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }}