import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart'; 
import 'theme/colors.dart';
import 'home_passenger.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  const RideTrackingScreen({Key? key, required this.rideId}) : super(key: key);

  @override
  _RideTrackingScreenState createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  late IO.Socket socket;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // ÉTAT DE LA COURSE
  String status = "SEARCHING"; 
  String titleText = "Recherche d'un chauffeur...";
  double finalPrice = 0.0;
  
  // INFOS CHAUFFEUR & VOITURE (Celles qu'on récupère du backend)
  String driverName = "Chauffeur";
  String vehicleInfo = "Récupération infos..."; // Ex: Toyota Corolla • Noir
  String licensePlate = "---";                  // Ex: TG-1234
  String driverPhone = "";
  String driverImage = ""; // URL avatar

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    // ⚠️ TON IP (ex: 192.168.1.73 pour mobile, localhost pour simulateur web)
    socket = IO.io('http://192.168.1.73:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      // PERSISTANCE : Si l'appli redémarre, on récupère l'état
      socket.emit('get_ride_status', {'rideId': widget.rideId});
    });

    // 🔔 ÉCOUTE DES MISES À JOUR (Le cœur du système)
    socket.on('ride_status_${widget.rideId}', (data) {
      if (!mounted) return;
      
      setState(() {
        status = data['status'];
        
        // Mise à jour des textes d'étape
        if (status == 'ACCEPTED') titleText = "Chauffeur en route (2 min)";
        if (status == 'ARRIVED') titleText = "Votre chauffeur est là !";
        if (status == 'IN_PROGRESS') titleText = "En route vers destination";
        if (status == 'COMPLETED') titleText = "Course terminée";

        // Mise à jour des Infos Profil (Venant de Prisma)
        if (data['driverName'] != null) driverName = data['driverName'];
        if (data['vehicleInfo'] != null) vehicleInfo = data['vehicleInfo'];
        if (data['licensePlate'] != null) licensePlate = data['licensePlate'];
        if (data['driverPhone'] != null) driverPhone = data['driverPhone'];
        if (data['finalPrice'] != null) finalPrice = (data['finalPrice'] as num).toDouble();
      });
    });

    // Tracking GPS
    socket.on('driver_location_${widget.rideId}', (data) {
      double lat = (data['lat'] as num).toDouble();
      double lng = (data['lng'] as num).toDouble();
      _updateMarker(lat, lng, (data['rotation'] ?? 0).toDouble());
    });
  }
  
  void _updateMarker(double lat, double lng, double rotation) {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId('driver'),
          position: LatLng(lat, lng),
          rotation: rotation,
          // Utilise une icône voiture personnalisée si tu en as une dans assets
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), 
          infoWindow: InfoWindow(title: driverName, snippet: vehicleInfo),
        )
      };
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  void _callDriver() async {
    if (driverPhone.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: driverPhone);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. CARTE (Fond)
          GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(6.1375, 1.2125), zoom: 15),
            onMapCreated: (c) => _mapController = c,
            markers: _markers,
            zoomControlsEnabled: false,
            // Laisse de la place en bas pour le panneau
            padding: EdgeInsets.only(bottom: status == 'SEARCHING' ? 200 : 320), 
          ),
          
          // Bouton Retour (en haut à gauche)
          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: BackButton(color: Colors.black, onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePassenger()))),
            ),
          ),

          // 2. INTERFACE DYNAMIQUE (Bas de l'écran)
          if (status == 'SEARCHING') 
            _buildSearchingPanel()
          else if (status == 'COMPLETED')
            _buildPaymentPanel() // Affichage simple du prix
          else 
            _buildDriverProfilePanel(), // LE DASHBOARD PROFIL CHAUFFEUR
        ],
      ),
    );
  }

  // PANNEAU RECHERCHE
  Widget _buildSearchingPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20),
            Text("Recherche d'un chauffeur...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Nous contactons les chauffeurs à proximité.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // PANNEAU PAIEMENT (Simple)
  Widget _buildPaymentPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Course Terminée", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Divider(),
            Text("Montant à payer", style: TextStyle(color: Colors.grey)),
            Text("$finalPrice FCFA", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: AppColors.primary)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePassenger())), 
              child: Text("OK, C'EST PAYÉ"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 50))
            )
          ],
        ),
      ),
    );
  }

  // 🔥 LE DASHBOARD CHAUFFEUR (Inspiré de ta maquette)
  Widget _buildDriverProfilePanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Petite barre "tiroir"
            Center(child: Container(margin: EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            
            Padding(
              padding: EdgeInsets.fromLTRB(25, 20, 25, 30),
              child: Column(
                children: [
                  // 1. TITRE DE L'ÉTAPE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(titleText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      if(status == 'ARRIVED') 
                        Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)), child: Text("ARRIVÉ", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 10))),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // 2. CARTE PROFIL CHAUFFEUR
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0,2))]
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 55, height: 55,
                          decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                          child: Icon(Icons.person, size: 30, color: Colors.grey[500]),
                        ),
                        SizedBox(width: 15),
                        // Info Texte
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(driverName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              // Affiche la voiture ici (ex: Toyota Corolla • Noir)
                              Text(vehicleInfo, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                              SizedBox(height: 4),
                              // Plaque d'immatriculation
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                                child: Text(licensePlate, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              )
                            ],
                          ),
                        ),
                        // Boutons Actions (Appel / Message)
                        Row(
                          children: [
                            _actionBtn(Icons.message, Colors.blue),
                            SizedBox(width: 10),
                            _actionBtn(Icons.call, Colors.green, onTap: _callDriver),
                          ],
                        )
                      ],
                    ),
                  ),

                  // 3. BARRE DE CHARGEMENT (Si en attente)
                  if(status == 'ACCEPTED') ...[
                    SizedBox(height: 20),
                    LinearProgressIndicator(backgroundColor: Colors.grey[100], color: AppColors.primary),
                    SizedBox(height: 5),
                    Text("Le chauffeur termine sa course précédente...", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}