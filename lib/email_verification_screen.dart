import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String role;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.name,
    required this.role,
  }) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      _showError('Ingrese el código completo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/auth/email/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        _showSuccess('¡Email verificado!');
        
        // Navigation selon le rôle
        await Future.delayed(Duration(seconds: 1));
        
        if (widget.role == 'PASSENGER') {
          // Passager → Accueil direct
          Navigator.pushReplacementNamed(context, '/home-passenger');
        } else {
          // Chauffeur → Vérification faciale
          Navigator.pushReplacementNamed(context, '/face-verification');
        }
      } else {
        _showError(data['message'] ?? 'Código incorrecto');
      }
    } catch (e) {
      _showError('Error de conexión');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/auth/email/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        _showSuccess('Código reenviado');
        setState(() {
          _countdown = 60;
          _startCountdown();
        });
      } else {
        _showError(data['message']);
      }
    } catch (e) {
      _showError('Error al reenviar');
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B6B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    size: 40,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              // Titre
              Text(
                'Verificación de email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Description
              Text(
                'Ingrese el código de 6 dígitos enviado a',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: 4),
              
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              
              SizedBox(height: 40),
              
              // Champs code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFF6B6B),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (index == 5 && value.isNotEmpty) {
                          _verifyCode();
                        }
                      },
                      onTap: () {
                        _controllers[index].selection = TextSelection.fromPosition(
                          TextPosition(offset: _controllers[index].text.length),
                        );
                      },
                    ),
                  );
                }),
              ),
              
              SizedBox(height: 32),
              
              // Bouton vérifier
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF6B6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Verificar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Renvoyer code
              Center(
                child: TextButton(
                  onPressed: _countdown == 0 && !_isResending ? _resendCode : null,
                  child: _isResending
                      ? CircularProgressIndicator()
                      : Text(
                          _countdown > 0
                              ? 'Reenviar código en $_countdown s'
                              : 'Reenviar código',
                          style: TextStyle(
                            color: _countdown == 0
                                ? Color(0xFFFF6B6B)
                                : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              Spacer(),
              
              // Info
              Center(
                child: Text(
                  'No recibió el código? Revise su carpeta de spam',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
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