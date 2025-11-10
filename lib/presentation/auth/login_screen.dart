import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/data/datasources/auth_service.dart';
import 'package:gym_app/presentation/auth/register_screen.dart';
import 'package:gym_app/presentation/exercise_list/exercise_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  void _showSnackBar(String message, {bool isError = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    User? user = await _authService.signInWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
    );
    setState(() {
      _isLoading = false;
    });
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ExerciseListScreen()),
      );
    } else {
      _showSnackBar('Credenciais inválidas. Verifique seu e-mail e senha.');
    }
  }

  Future<void> _resetPassword() async {
    // Verifica se o campo de email está preenchido
    if (_emailController.text.isEmpty) {
      _showSnackBar('Por favor, digite seu e-mail para recuperar a senha.');
      return;
    }

    // Valida o formato do email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(_emailController.text)) {
      _showSnackBar('Por favor, digite um e-mail válido.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? error = await _authService.resetPassword(_emailController.text);

      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        _showSnackBar(
          'E-mail de recuperação enviado para ${_emailController.text}. Verifique sua caixa de entrada.',
          isError: false,
        );
      } else {
        _showSnackBar('Erro ao enviar e-mail: $error');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erro inesperado. Tente novamente.');
    }
  }

  Future<void> _showResetPasswordDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Recuperar Senha',
            style: TextStyle(
              color: AppColors.primaryBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            _emailController.text.isEmpty
                ? 'Deseja enviar instruções de recuperação para o e-mail digitado?'
                : 'Deseja enviar instruções de recuperação para ${_emailController.text}?',
            style: TextStyle(color: AppColors.primaryBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetPassword();
              },
              child: Text(
                'Enviar',
                style: TextStyle(color: AppColors.primaryAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 0),
            
 
            Image.network(
              'https://res.cloudinary.com/dogc5cxsu/image/upload/v1762663257/Gemini_Generated_Image_lzwwo1lzwwo1lzww-removebg-preview_1_vqyism.png',
              height: 180,
              width: 200,
              fit: BoxFit.contain,
            ),
   
            const SizedBox(height: 00),
            Text(
              'Borá Treinar?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28,
             
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login para continuar',
              style: TextStyle(
            
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            Container(
           
                width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
            
                    'E-mail',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
  
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
     
                    decoration: InputDecoration(
                      hintText: 'Digite seu E-mail',
                      hintStyle: TextStyle(color: AppColors.secondaryText),
                      filled: true,
            
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: TextStyle(color: AppColors.primaryBackground),
                    keyboardType: TextInputType.emailAddress,
    
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
   
                width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
    
                    'Senha',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                  
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua Senha',
                      hintStyle: TextStyle(color: AppColors.secondaryText),
                      filled: true,
    
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
        
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: TextStyle(color: AppColors.primaryBackground),
                 
                    obscureText: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              alignment: Alignment.centerRight,
              child: TextButton(
                       onPressed: _isLoading ? null : _showResetPasswordDialog,
                       child: Text(
                         'Esqueci minha senha',
                         style: TextStyle(
                           color: AppColors.primaryAccent,
                           fontSize: 14,
                         ),
                       ),
                     ),
            ),
            const SizedBox(height: 30),

            Container(
  
                width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
             
                        color: AppColors.primaryAccent,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _login,
    
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
    
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
      
                      child: Text(
                        'Acessar',
                        style: TextStyle(
                          color: AppColors.white,
       
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
       
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
   
                child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
        
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: BorderSide(color: AppColors.white.withOpacity(0.3), width: 1.0),
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
  
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
           
                    'Criar conta',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
          
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}