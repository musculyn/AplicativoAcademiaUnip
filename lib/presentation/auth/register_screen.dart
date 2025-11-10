import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/data/datasources/auth_service.dart';
import 'package:gym_app/presentation/auth/complete_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _register() async {
  if (_passwordController.text != _confirmPasswordController.text) {
    _showErrorSnackBar('As senhas não coincidem.');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    User? user = await _authService.registerWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
      );
    }
  } on FirebaseAuthException catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    // Tratamento específico para cada tipo de erro
    switch (e.code) {
      case 'email-already-in-use':
        _showErrorSnackBar('Este e-mail já está cadastrado. Tente fazer login.');
        break;
      case 'weak-password':
        _showErrorSnackBar('A senha é muito fraca. Use pelo menos 6 caracteres.');
        break;
      case 'invalid-email':
        _showErrorSnackBar('O e-mail digitado é inválido.');
        break;
      case 'operation-not-allowed':
        _showErrorSnackBar('Operação não permitida. Contate o suporte.');
        break;
      default:
        _showErrorSnackBar('Erro ao criar conta: ${e.message}');
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    _showErrorSnackBar('Erro inesperado. Tente novamente.');
  }
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
              height: 170,
              width: 200,
              fit: BoxFit.contain,
            ),
   
            const SizedBox(height: 0),
            Text(
              'Criar Conta',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28,
             
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha os dados para se cadastrar',
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
                      fontWeight: 
                        FontWeight.w500,
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
  
                    'Criar Senha',
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
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
           
                      Text(
                    'Confirmar Senha',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
     
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
      
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      hintText: 'Confirme sua Senha',
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
            const SizedBox(height: 30),

          
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: _isLoading
                  ?
                    Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                      ),
                    )
          
                    : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                    
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                 
                        elevation: 2,
                      ),
                      child: Text(
                        'Criar Conta',
                      
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Já tem uma conta? ',
                    style: TextStyle(
                  
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
         
                        text: 'Fazer login',
                        style: TextStyle(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w600,
    
                        ),
                      ),
                    ],
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
    _confirmPasswordController.dispose();
    super.dispose();
  }
}