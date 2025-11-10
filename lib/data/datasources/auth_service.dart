import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para registrar um novo usuário
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // Se o usuário foi criado com sucesso, adiciona um documento na coleção 'users'
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': email.split('@')[0], // Nome de exibição inicial
          'activeRoutineId': '', // Sem rotina ativa inicialmente
          // Outros campos iniciais que você queira adicionar
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Erro ao registrar: ${e.message}');
      // Relança a exceção para ser tratada na UI
      rethrow;
    }
  }

  // Método para fazer login com e-mail e senha
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Erro ao fazer login: ${e.message}');
      // Trate o erro de forma mais amigável no UI
      return null;
    }
  }

  // Método para resetar senha
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Sucesso, nenhum erro
    } on FirebaseAuthException catch (e) {
      print('Erro ao enviar e-mail de recuperação: ${e.message}');
      return e.message; // Retorna a mensagem de erro
    }
  }

  // Método para logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Stream para observar o estado de autenticação (usuário logado/deslogado)
  Stream<User?> get user => _auth.authStateChanges();
}