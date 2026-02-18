import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pending_validation_screen.dart';
import 'theme/colors.dart';

class DocumentUploadScreen extends StatefulWidget {
  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  bool _isLoading = false;

  // Track upload status for each document
  final Map<String, _DocStatus> _docs = {
    'id_front': _DocStatus(category: 'identity', label: "Carte d'identité (recto)", icon: '🪪', required: true),
    'id_back': _DocStatus(category: 'identity', label: "Carte d'identité (verso)", icon: '🪪', required: true),
    'passport': _DocStatus(category: 'identity', label: 'Passeport', icon: '📘', required: false),
    'selfie_doc': _DocStatus(category: 'identity', label: 'Selfie avec document', icon: '🤳', required: true),
    'drivers_license': _DocStatus(category: 'vehicle', label: 'Permis de conduire', icon: '🚗', required: true),
    'registration': _DocStatus(category: 'vehicle', label: 'Carte grise', icon: '📋', required: true),
    'insurance': _DocStatus(category: 'vehicle', label: 'Assurance', icon: '🛡️', required: true),
    'technical': _DocStatus(category: 'vehicle', label: 'Contrôle technique', icon: '🔧', required: true),
  };

  int get _uploadedRequired => _docs.entries.where((e) => e.value.required && e.value.uploaded).length;
  int get _totalRequired => _docs.values.where((d) => d.required).length;

  void _tapDoc(String key) async {
    // Simulate file picker
    await Future.delayed(Duration(milliseconds: 300));
    setState(() => _docs[key]!.uploaded = !_docs[key]!.uploaded);
  }

  Future<void> _submit() async {
    if (_uploadedRequired < _totalRequired) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veuillez uploader tous les documents obligatoires (*)'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(Duration(milliseconds: 2000)); // simulate upload
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('documents_uploaded', true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => PendingValidationScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
        title: Text('Documents requis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, Color(0xFFFF9A9A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file, color: Colors.white, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_uploadedRequired / $_totalRequired documents obligatoires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _uploadedRequired / _totalRequired,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("🪪 Documents d'identité"),
                  SizedBox(height: 12),
                  ..._docs.entries.where((e) => e.value.category == 'identity').map((e) => _docCard(e.key, e.value)),
                  SizedBox(height: 24),
                  _sectionTitle('🚗 Documents véhicule'),
                  SizedBox(height: 12),
                  ..._docs.entries.where((e) => e.value.category == 'vehicle').map((e) => _docCard(e.key, e.value)),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _uploadedRequired >= _totalRequired ? AppColors.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                        SizedBox(width: 12),
                        Text('Envoi en cours...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Text('Envoyer pour vérification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D3436)));

  Widget _docCard(String key, _DocStatus doc) {
    return GestureDetector(
      onTap: () => _tapDoc(key),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: doc.uploaded ? Colors.green.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: doc.uploaded ? Colors.green.withOpacity(0.5) : Colors.grey.shade200, width: doc.uploaded ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: doc.uploaded ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(doc.icon, style: TextStyle(fontSize: 22))),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(doc.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2D3436)))),
                      if (doc.required) ...[
                        SizedBox(width: 4),
                        Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    doc.uploaded ? '✅ Uploadé' : !doc.required ? 'Optionnel — Appuyez pour ajouter' : 'Appuyez pour sélectionner',
                    style: TextStyle(fontSize: 12, color: doc.uploaded ? Colors.green : Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              doc.uploaded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
              color: doc.uploaded ? Colors.green : Colors.grey.shade400,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocStatus {
  final String category, label, icon;
  final bool required;
  bool uploaded;

  _DocStatus({required this.category, required this.label, required this.icon, required this.required, this.uploaded = false});
}
