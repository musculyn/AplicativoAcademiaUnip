import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Busca todo o histórico do usuário
  Future<QuerySnapshot> getUserWorkoutHistory(String userId) async {
    return await _firestore
        .collection('workout_history')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
  }

  // Busca dados da rotina pelo ID
  Future<DocumentSnapshot?> getRoutineById(String? routineId) async {
    if (routineId == null || routineId.isEmpty) return null;
    
    try {
      return await _firestore.collection('user_routines').doc(routineId).get();
    } catch (e) {
      print('Erro ao buscar rotina: $e');
      return null;
    }
  }

  // Deleta um registro do histórico
  Future<void> deleteWorkoutHistory(String historyId) async {
    await _firestore.collection('workout_history').doc(historyId).delete();
  }

  // Atualiza o status de completed do treino
  Future<void> updateWorkoutCompletion(String historyId, bool completed) async {
    await _firestore.collection('workout_history').doc(historyId).update({
      'completed': completed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Busca histórico por data específica (para o calendário)
  Future<QuerySnapshot> getWorkoutHistoryByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return await _firestore
        .collection('workout_history')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .orderBy('date', descending: true)
        .get();
  }
}