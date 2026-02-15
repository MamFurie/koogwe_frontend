import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';

class SearchingDriverScreen extends StatefulWidget {
  final String rideId;
  final String destination;
  final double price;

  const SearchingDriverScreen({
    Key? key,
    required this.rideId,
    required this.destination,
    required this.price,
  }) : super(key: key);

  @override
  _SearchingDriverScreenState createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timeoutTimer;
  int _remainingSeconds = 60; // 60 secondes = 1 minute
  bool _driverFound = false;
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startSearch();
    _connectSocket();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  void _startSearch() {
    // Timer qui décrémente chaque seconde
    _timeoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      // Timeout atteint
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _showNoDriverDialog();
      }
    });
  }

  void _connectSocket() {
    try {
      _socket = IO.io(kSocketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket!.connect();

      // Rejoindre la room de la course
      _socket!.emit('join_ride', {'rideId': widget.rideId});

      // Écouter si un chauffeur accepte
      _socket!.on('ride_status_${widget.rideId}', (data) {
        if (data['status'] == 'ACCEPTED') {
          setState(() => _driverFound = true);
          _timeoutTimer?.cancel();
          _showDriverFoundDialog(data);
        }
      });
    } catch (e) {
      print('❌ Erreur Socket: $e');
    }
  }

  void _showNoDriverDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Aucun chauffeur disponible'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Désolé, aucun chauffeur n\'est disponible pour le moment.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Suggestions :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Réessayez dans quelques minutes'),
            Text('• Vérifiez votre position de départ'),
            Text('• Contactez le support si le problème persiste'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Retour à l'accueil
            },
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              // Relancer la recherche
              setState(() {
                _remainingSeconds = 60;
                _startSearch();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _showDriverFoundDialog(Map<String, dynamic> driverData) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Chauffeur trouvé !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFFF6B6B).withOpacity(0.1),
              child: Icon(Icons.person, size: 40, color: Color(0xFFFF6B6B)),
            ),
            SizedBox(height: 16),
            Text(
              driverData['driverName'] ?? 'Chauffeur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              driverData['driverPhone'] ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Véhicule:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        driverData['vehicleInfo'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Immatriculation:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        driverData['licensePlate'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer dialog
              Navigator.pop(context); // Retour accueil
              // TODO: Naviguer vers l'écran de suivi de course
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Suivre ma course', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timeoutTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Bouton retour
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Spacer(),

              // Animation de recherche
              Stack(
                alignment: Alignment.center,
                children: [
                  // Cercles animés
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Container(
                          width: 120 + (index * 40.0) * _animationController.value,
                          height: 120 + (index * 40.0) * _animationController.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFFFF6B6B).withOpacity(
                                0.3 - (index * 0.1) - (_animationController.value * 0.3),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  // Icône centrale
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40),

              // Texte principal
              Text(
                'Recherche d\'un chauffeur...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16),

              // Timer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _remainingSeconds <= 10
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Temps restant: ${_remainingSeconds}s',
                  style: TextStyle(
                    fontSize: 16,
                    color: _remainingSeconds <= 10 ? Colors.red : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Info destination
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFFFF6B6B)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.destination,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Prix',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          '${widget.price.toInt()} FCFA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4ECDC4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Spacer(),

              // Bouton annuler
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    _timeoutTimer?.cancel();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Annuler la recherche',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}