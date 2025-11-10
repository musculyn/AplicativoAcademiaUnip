import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/data/models/workout_routine.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveWorkoutHistory({
    required String userId,
    required String routineId,
    required String day,
    required String workoutName,
    required List<RoutineExercise> exercises,
    required bool completed,
    DateTime? specificDate,
  }) async {
    try {
      final dateToSave = specificDate ?? DateTime.now().toLocal();
      final uniqueDateKey = DateTime(dateToSave.year, dateToSave.month, dateToSave.day);
      
      final exercisesHistory = exercises.map((exercise) {
        return {
          'exerciseId': exercise.exerciseId,
          'name': exercise.name,
          'category': '',
          'order': exercises.indexOf(exercise) + 1,
          'completed': completed,
          'sets': exercise.sets,
          'reps': exercise.reps,
          'weight': exercise.weight,
          'restTime': exercise.restTime,
        };
      }).toList();
      
      final workoutData = {
        'date': uniqueDateKey,
        'dayOfWeek': day,
        'workoutName': workoutName,
        'routineId': routineId,
        'userId': userId,
        'exercises': exercisesHistory,
        'completed': completed,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('workout_history').add(workoutData);
    } catch (e) {
      print('Erro ao salvar histórico: $e');
      throw e;
    }
  }

  Future<bool> wasWorkoutCompletedToday(String userId, String routineId, String day) async {
    try {
      final now = DateTime.now().toLocal();
      final today = DateTime(now.year, now.month, now.day);
      
      final query = await _firestore
          .collection('workout_history')
          .where('userId', isEqualTo: userId)
          .where('routineId', isEqualTo: routineId)
          .where('dayOfWeek', isEqualTo: day)
          .where('date', isEqualTo: today)
          .where('completed', isEqualTo: true)
          .limit(1)
          .get();
          
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar conclusão do treino hoje: $e');
      return false;
    }
  }

  Future<bool> hasWorkoutHistoryForDay(String userId, DateTime date) async {
    try {
      final searchDateKey = DateTime(date.year, date.month, date.day);
      final query = await _firestore
          .collection('workout_history')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: searchDateKey)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar histórico: $e');
      return false;
    }
  }

  Future<void> saveIncompleteWorkouts({
    required String userId,
    required WorkoutRoutine? activeRoutine,
  }) async {
    if (userId.isEmpty || activeRoutine == null) return;
    
    final now = DateTime.now().toLocal();
    final currentWeekday = now.weekday;
    
    final dayIndexMap = {
      'Segunda': 1, 'Terça': 2, 'Quarta': 3, 'Quinta': 4,
      'Sexta': 5, 'Sábado': 6, 'Domingo': 7,
    };
    
    final daysOfWeek = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    
    for (final day in daysOfWeek) {
      final dayIndex = dayIndexMap[day] ?? 1;
      if (dayIndex < currentWeekday) {
        final dailyWorkout = activeRoutine.dailyWorkouts[day];
        if (dailyWorkout != null && dailyWorkout.exercises.isNotEmpty) {
          final daysDifference = currentWeekday - dayIndex;
          final dayToSave = now.subtract(Duration(days: daysDifference));
          
          final dateForHistoryCheck = DateTime(dayToSave.year, dayToSave.month, dayToSave.day);
          
          final alreadyExists = await hasWorkoutHistoryForDay(userId, dateForHistoryCheck);
          if (!alreadyExists) {
            await saveWorkoutHistory(
              userId: userId,
              routineId: activeRoutine.id,
              day: day,
              workoutName: dailyWorkout.name,
              exercises: dailyWorkout.exercises,
              completed: false,
              specificDate: dateForHistoryCheck,
            );
          }
        }
      }
    }
  }

  Future<void> saveExerciseCompletion({
    required String routineId,
    required String day,
    required String exerciseId,
    required bool completed,
  }) async {
    try {
      final routineDoc = await _firestore.collection('user_routines').doc(routineId).get();
      if (routineDoc.exists) {
        final data = routineDoc.data() as Map<String, dynamic>;
        final dailyWorkouts = data['dailyWorkouts'] as Map<String, dynamic>? ?? {};
        
        if (dailyWorkouts.containsKey(day)) {
          final dayData = dailyWorkouts[day] as Map<String, dynamic>;
          final exercises = dayData['exercises'] as List<dynamic>? ?? [];
          
          for (int i = 0; i < exercises.length; i++) {
            final exercise = exercises[i] as Map<String, dynamic>;
            if (exercise['exerciseId'] == exerciseId) {
              exercises[i] = {
                ...exercise,
                'completed': completed,
              };
              break;
            }
          }
          
          await _firestore.collection('user_routines').doc(routineId).update({
            'dailyWorkouts.$day.exercises': exercises,
          });
        }
      }
    } catch (e) {
      print('Erro ao salvar completado do exercício: $e');
      throw e;
    }
  }

  Future<Map<String, bool>> loadCompletedExercises({
    required String routineId,
    required String day,
  }) async {
    try {
      final routineDoc = await _firestore.collection('user_routines').doc(routineId).get();
      final completedExercises = <String, bool>{};
      
      if (routineDoc.exists) {
        final data = routineDoc.data() as Map<String, dynamic>;
        final dailyWorkouts = data['dailyWorkouts'] as Map<String, dynamic>? ?? {};
        
        if (dailyWorkouts.containsKey(day)) {
          final dayData = dailyWorkouts[day] as Map<String, dynamic>;
          final exercises = dayData['exercises'] as List<dynamic>? ?? [];
          
          for (final exercise in exercises) {
            final exerciseMap = exercise as Map<String, dynamic>;
            final exerciseId = exerciseMap['exerciseId'] as String? ?? '';
            final completed = exerciseMap['completed'] as bool? ?? false;
            if (exerciseId.isNotEmpty) {
              completedExercises[exerciseId] = completed;
            }
          }
        }
      }
      
      return completedExercises;
    } catch (e) {
      print('Erro ao carregar exercícios completados: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> getUserExerciseProgress({
    required String userId,
  }) async {
    try {
      final historyQuery = await _firestore
          .collection('workout_history')
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .orderBy('date', descending: false)
          .get();
      
      final Map<String, Map<String, dynamic>> exerciseProgress = {};

      for (final doc in historyQuery.docs) {
        final data = doc.data();
        final exercises = data['exercises'] as List<dynamic>? ?? [];
        final workoutDate = (data['date'] as Timestamp).toDate();

        for (final exerciseData in exercises) {
          final exercise = exerciseData as Map<String, dynamic>;
          final exerciseId = exercise['exerciseId'] as String? ?? '';
          final exerciseName = exercise['name'] as String? ?? '';
          final weight = (exercise['weight'] as num?)?.toDouble() ?? 0.0;
          final completed = exercise['completed'] as bool? ?? false;

          if (exerciseId.isNotEmpty && weight > 0 && completed) {
            if (!exerciseProgress.containsKey(exerciseId)) {
              exerciseProgress[exerciseId] = {
                'name': exerciseName,
                'firstWeight': weight,
                'lastWeight': weight,
                'firstDate': workoutDate,
                'lastDate': workoutDate,
                'progress': 0.0,
                'history': <Map<String, dynamic>>[],
              };
            }
            
            final progressData = exerciseProgress[exerciseId]!;
            final existingHistory = progressData['history'] as List<Map<String, dynamic>>;
            
            final existingRecordIndex = existingHistory.indexWhere((record) => 
              _isSameDay(record['date'] as DateTime, workoutDate)
            );
            
            if (existingRecordIndex >= 0) {
              existingHistory[existingRecordIndex] = {
                'date': workoutDate,
                'weight': weight,
                'workoutName': data['workoutName'] ?? '',
                'dayOfWeek': data['dayOfWeek'] ?? '',
              };
            } else {
              existingHistory.add({
                'date': workoutDate,
                'weight': weight,
                'workoutName': data['workoutName'] ?? '',
                'dayOfWeek': data['dayOfWeek'] ?? '',
              });
            }
            
            existingHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
            
            if (existingHistory.isNotEmpty) {
              progressData['firstWeight'] = existingHistory.first['weight'] as double;
              progressData['lastWeight'] = existingHistory.last['weight'] as double;
              progressData['firstDate'] = existingHistory.first['date'] as DateTime;
              progressData['lastDate'] = existingHistory.last['date'] as DateTime;
              progressData['progress'] = progressData['lastWeight'] - progressData['firstWeight'];
            }
          }
        }
      }

      return exerciseProgress;
    } catch (e) {
      print('Erro ao buscar progresso dos exercícios: $e');
      return {};
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}