import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'document_upload_screen.dart';
import 'theme/colors.dart';
import 'dart:math';

class FaceVerificationScreen extends StatefulWidget {
  @override
  _FaceVerificationScreenState createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> with TickerProviderStateMixin {
  final List<_Instruction> _instructions = [
    _Instruction('👈', 'Regardez à gauche', 'Tournez lentement la tête vers la gauche'),
    _Instruction('👉', 'Regardez à droite', 'Tournez lentement la tête vers la droite'),
    _Instruction('👆', 'Regardez en haut', 'Levez doucement la tête vers le haut'),
    _Instruction('👇', 'Regardez en bas', 'Baissez doucement la tête vers le bas'),
  ];

  int _step = -1; // -1 = pré-scan, 4 = terminé
  bool _isCameraActive = false;
  bool _isLoading = false;
  bool _stepSuccess = false;

  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1200))..repeat(reverse: true);
    _progressCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() { _isCameraActive = true; _step = 0; });
    _runNextStep();
  }

  void _runNextStep() async {
    if (_step >= _instructions.length) {
      _completeVerification();
      return;
    }
    setState(() => _stepSuccess = false);
    // Simulate liveness detection (2 seconds per step)
    await Future.delayed(Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _stepSuccess = true);
    await Future.delayed(Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _step++);
    _runNextStep();
  }

  void _completeVerification() async {
    setState(() => _isLoading = true);
    // Simulate API call for face save
    await Future.delayed(Duration(milliseconds: 1500));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('face_verified', true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => DocumentUploadScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = _step >= _instructions.length;
    final currentInstruction = (!isDone && _step >= 0) ? _instructions[_step] : null;
    final double progress = _step < 0 ? 0 : min(1.0, _step / _instructions.length);

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  if (!_isCameraActive)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  Spacer(),
                  if (_step >= 0 && !isDone)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text('${_step + 1} / ${_instructions.length}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              SizedBox(height: 16),

              // Title
              Text(
                isDone ? '✅ Vérification réussie !' : '📸 Vérification faciale',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                isDone
                  ? 'Votre identité a été confirmée'
                  : _step < 0
                    ? 'Positionnez votre visage dans le cadre'
                    : 'Suivez les instructions ci-dessous',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14),
              ),
              SizedBox(height: 30),

              // Camera view simulation
              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 280,
                      height: 340,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(140),
                        border: Border.all(
                          color: isDone ? Colors.green : (_stepSuccess ? Colors.green : AppColors.primary),
                          width: 3,
                        ),
                        color: Colors.black.withOpacity(0.4),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Simulated face area
                          if (!_isCameraActive)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face, color: Colors.white.withOpacity(0.3), size: 80),
                                SizedBox(height: 12),
                                Text('Appuyez sur Démarrer', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                              ],
                            )
                          else if (isDone)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 80),
                                SizedBox(height: 12),
                                Text('Visage vérifié !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Animated face icon
                                Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  child: Icon(Icons.face, color: Colors.white.withOpacity(0.8), size: 60),
                                ),
                                SizedBox(height: 16),
                                if (_stepSuccess)
                                  Icon(Icons.check_circle, color: Colors.green, size: 30)
                                else
                                  SizedBox(
                                    width: 30, height: 30,
                                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                                  ),
                              ],
                            ),
                          // Corner brackets
                          Positioned(top: 20, left: 20, child: _corner(isTop: true, isLeft: true)),
                          Positioned(top: 20, right: 20, child: _corner(isTop: true, isLeft: false)),
                          Positioned(bottom: 20, left: 20, child: _corner(isTop: false, isLeft: true)),
                          Positioned(bottom: 20, right: 20, child: _corner(isTop: false, isLeft: false)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Progress bar
              if (_step >= 0 && !isDone) ...[
                SizedBox(height: 20),
                Column(
                  children: List.generate(_instructions.length, (i) {
                    final isDoneStep = i < _step;
                    final isCurrent = i == _step;
                    final inst = _instructions[i];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDoneStep ? Colors.green.withOpacity(0.15) : isCurrent ? AppColors.primary.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDoneStep ? Colors.green.withOpacity(0.5) : isCurrent ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(inst.emoji, style: TextStyle(fontSize: 22)),
                          SizedBox(width: 12),
                          Expanded(child: Text(inst.label, style: TextStyle(color: Colors.white.withOpacity(isDoneStep ? 0.6 : 1.0), fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 15))),
                          if (isDoneStep) Icon(Icons.check_circle, color: Colors.green, size: 20)
                          else if (isCurrent && !_stepSuccess) SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          else if (isCurrent && _stepSuccess) Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ],
                      ),
                    );
                  }),
                ),
              ],

              // Single instruction display (pre-scan)
              if (_step < 0) ...[
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white.withOpacity(0.6), size: 24),
                      SizedBox(height: 10),
                      Text('Instructions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Assurez-vous d\'être dans un endroit bien éclairé. Suivez les instructions pour valider votre identité.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.5)),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _startScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Démarrer la vérification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              if (_isLoading) ...[
                SizedBox(height: 24),
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 12),
                Text('Validation en cours...', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              ],

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corner({required bool isTop, required bool isLeft}) {
    return SizedBox(
      width: 24, height: 24,
      child: CustomPaint(painter: _CornerPainter(isTop: isTop, isLeft: isLeft)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop, isLeft;
  _CornerPainter({required this.isTop, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final dx = isLeft ? 20.0 : -20.0;
    final dy = isTop ? 20.0 : -20.0;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Instruction {
  final String emoji, label, description;
  const _Instruction(this.emoji, this.label, this.description);
}
