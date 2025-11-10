import 'package:cloud_firestore/cloud_firestore.dart';

// Novo modelo para representar um Exercício dentro de um Treino Diário
class RoutineExercise {
  final String exerciseId;
  final String name;
  int sets;
  String reps;
  double weight; 
  int restTime;
  bool completed;
  RoutineExercise({
    required this.exerciseId,
    required this.name,
    this.sets = 3,
    this.reps = '10-12',
    this.weight = 0.0, 
    this.restTime = 60, 
    this.completed = false,
  });
  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight, 
      'restTime': restTime, 
      'completed': completed,
    };
  }

  factory RoutineExercise.fromMap(Map<String, dynamic> data) {
    return RoutineExercise(
      exerciseId: data['exerciseId'] ?? '',
      name: data['name'] ?? 'Exercício Desconhecido',
      sets: data['sets'] ?? 3,
      reps: data['reps'] ?? '10-12',
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0, 
      restTime: data['restTime'] ?? 60, 
      completed: data['completed'] ?? false,
    );
  }
}

// Modelo para representar o Treino Diário
class DailyWorkout {
  String name;
  List<RoutineExercise> exercises;
  int restTime;
  String workoutTime;

  DailyWorkout({
    required this.name,
    required this.exercises,
    this.restTime = 60, 
    this.workoutTime = '07:00', 
  });
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'restTime': restTime, 
      'workoutTime': workoutTime, 
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }
  
  factory DailyWorkout.fromMap(Map<String, dynamic> data) {
    return DailyWorkout(
      name: data['name'] ?? 'Treino do Dia',
      restTime: data['restTime'] ?? 60, 
      workoutTime: data['workoutTime'] ?? '07:00', 
      exercises: (data['exercises'] as List? ?? [])
          .map((item) => RoutineExercise.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Modelo principal da Rotina de Treino 
class WorkoutRoutine {
  final String id;
  final String userId;
  final String name;
  final bool isUserDefined;
  final Map<String, DailyWorkout> dailyWorkouts;
  WorkoutRoutine({
    required this.id,
    required this.userId,
    required this.name,
    required this.isUserDefined,
    required this.dailyWorkouts,
  });
  factory WorkoutRoutine.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    Map<String, DailyWorkout> workouts = {};
    (data['dailyWorkouts'] as Map<String, dynamic>? ?? {}).forEach((day, workoutData) {
      if (workoutData != null) {
        workouts[day] = DailyWorkout.fromMap(workoutData as Map<String, dynamic>);
      }
    });
    return WorkoutRoutine(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Rotina Padrão',
      isUserDefined: data['isUserDefined'] ?? false,
      dailyWorkouts: workouts,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'isUserDefined': isUserDefined,
      'dailyWorkouts': dailyWorkouts.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}