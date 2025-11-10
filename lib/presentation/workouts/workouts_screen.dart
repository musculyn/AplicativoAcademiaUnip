import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/core/widgets/bottom_nav_bar.dart';
import 'package:gym_app/data/datasources/workout_service.dart';
import 'package:gym_app/data/models/workout_routine.dart';
import 'package:gym_app/presentation/workouts/widgets/workout_exercise_card.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkoutService _workoutService = WorkoutService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  String _selectedDay = 'Segunda';
  WorkoutRoutine? _activeRoutine;
  bool _isLoading = true;
  
  final Map<String, Map<String, bool>> _completedExercises = {};

  final List<String> _daysOfWeek = [
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
  ];

  final List<String> _dayInitials = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _setCurrentDay();
    _loadActiveRoutine();
  }

  void _setCurrentDay() {
    final now = DateTime.now().toLocal();
    final currentWeekday = now.weekday;

    final dayMap = {
      1: 'Segunda', 2: 'Terça', 3: 'Quarta', 4: 'Quinta', 
      5: 'Sexta', 6: 'Sábado', 7: 'Domingo',
    };

    setState(() {
      _selectedDay = dayMap[currentWeekday] ?? 'Segunda';
    });
  }

  bool _isDayPassed(String day) {
    final now = DateTime.now().toLocal();
    final currentWeekday = now.weekday;

    final dayIndexMap = {
      'Segunda': 1, 'Terça': 2, 'Quarta': 3, 'Quinta': 4,
      'Sexta': 5, 'Sábado': 6, 'Domingo': 7,
    };

    final selectedDayIndex = dayIndexMap[day] ?? 1;
    return selectedDayIndex < currentWeekday;
  }

  bool _isCurrentDay(String day) {
    final now = DateTime.now().toLocal();
    final currentWeekday = now.weekday;

    final dayIndexMap = {
      'Segunda': 1, 'Terça': 2, 'Quarta': 3, 'Quinta': 4,
      'Sexta': 5, 'Sábado': 6, 'Domingo': 7,
    };

    final selectedDayIndex = dayIndexMap[day] ?? 1;
    return selectedDayIndex == currentWeekday;
  }

  bool _isFutureDay(String day) {
    final now = DateTime.now().toLocal();
    final currentWeekday = now.weekday;

    final dayIndexMap = {
      'Segunda': 1, 'Terça': 2, 'Quarta': 3, 'Quinta': 4,
      'Sexta': 5, 'Sábado': 6, 'Domingo': 7,
    };

    final selectedDayIndex = dayIndexMap[day] ?? 1;
    return selectedDayIndex > currentWeekday;
  }

  Future<void> _loadActiveRoutine() async {
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final String activeRoutineId = userDoc.data()?['activeRoutineId'] ?? '';

      if (activeRoutineId.isNotEmpty) {
        final routineDoc = await _firestore.collection('user_routines').doc(activeRoutineId).get();
        if (routineDoc.exists) {
          final routine = WorkoutRoutine.fromFirestore(routineDoc);
          
          setState(() {
            _activeRoutine = routine;
          });

          await _loadCompletedExercisesForAllDays(routine);
          await _workoutService.saveIncompleteWorkouts(
            userId: _currentUserId,
            activeRoutine: routine,
          );
        }
      }
    } catch (e) {
    } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
    }
  }

  Future<void> _loadCompletedExercisesForAllDays(WorkoutRoutine routine) async {
    for (final day in _daysOfWeek) {
      final completedExercises = await _workoutService.loadCompletedExercises(
        routineId: routine.id,
        day: day,
      );
      if (mounted) {
        setState(() {
          _completedExercises[day] = completedExercises;
        });
      } 
    }
  }

  void _selectDay(String day) {
    setState(() {
      _selectedDay = day;
    });
  }

  Future<void> _onExerciseComplete(RoutineExercise exercise) async {
    if (_currentUserId == null || _activeRoutine == null) return;

    if (!_isCurrentDay(_selectedDay)) {
      String message = '';
      if (_isDayPassed(_selectedDay)) {
        message = 'Não é possível completar exercícios de dias que já passaram ($_selectedDay).';
      } else if (_isFutureDay(_selectedDay)) {
        message = 'Não é possível completar exercícios de dias futuros ($_selectedDay).';
      } else {
        message = 'Só é permitido completar exercícios do dia atual.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      setState(() {
        if (_completedExercises[_selectedDay] == null) {
          _completedExercises[_selectedDay] = {};
        }
        _completedExercises[_selectedDay]![exercise.exerciseId] = true;
      });

      await _workoutService.saveExerciseCompletion(
        routineId: _activeRoutine!.id,
        day: _selectedDay,
        exerciseId: exercise.exerciseId,
        completed: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exercise.name} completado! ✓'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      await _checkAndSaveDailyWorkoutCompletion();
      
    } catch (e) {
      print('Erro ao completar exercício: $e');
      setState(() {
        _completedExercises[_selectedDay]![exercise.exerciseId] = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkAndSaveDailyWorkoutCompletion() async {
    final dailyWorkout = _activeRoutine!.dailyWorkouts[_selectedDay];
    if (dailyWorkout == null || dailyWorkout.exercises.isEmpty) return;

    final allExercisesCompleted = dailyWorkout.exercises.every((exercise) {
      return _completedExercises[_selectedDay]?[exercise.exerciseId] == true;
    });

    if (allExercisesCompleted) {
      final now = DateTime.now().toLocal();
      final alreadyExists = await _workoutService.hasWorkoutHistoryForDay(_currentUserId!, now);

      if (!alreadyExists) {
        await _workoutService.saveWorkoutHistory(
          userId: _currentUserId,
          routineId: _activeRoutine!.id,
          day: _selectedDay,
          workoutName: dailyWorkout.name,
          exercises: dailyWorkout.exercises,
          completed: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Parabéns! Todos os exercícios de $_selectedDay foram completados!'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) return;
    final List<String> routes = ['/workouts', '/exercises', '/routines', '/profile'];
    
    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  void dispose() {
    _isLoading = false; 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Treinos do Dia',
          style: TextStyle(
            color: AppColors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
    
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                    ),
                  )
                : _activeRoutine == null
                    ? _buildNoActiveRoutine()
                    : _buildWorkoutContentWithStream(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.primaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _daysOfWeek.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final isSelected = day == _selectedDay;
          final isCurrentDay = _isCurrentDay(day);
          final isPassedDay = _isDayPassed(day);
          final isFutureDay = _isFutureDay(day);

          Color circleColor;
          Color textColor;

          if (isPassedDay) {
            circleColor = AppColors.secondaryText.withOpacity(0.3);
            textColor = AppColors.secondaryText.withOpacity(0.5);
          } else if (isSelected) {
            circleColor = AppColors.primaryAccent;
            textColor = AppColors.white;
          } else if (isFutureDay) {
            circleColor = AppColors.primaryAccent.withOpacity(0.3);
            textColor = AppColors.secondaryText;
          } else {
            circleColor = AppColors.cardColor;
            textColor = AppColors.secondaryText;
          }

          return GestureDetector(
            onTap: () => _selectDay(day),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _dayInitials[index],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isCurrentDay)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 6),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoActiveRoutine() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma rotina ativa',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Vá para "Rotinas" e selecione uma rotina para começar',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _onItemTapped(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ir para Rotinas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutContentWithStream() {
    if (_activeRoutine == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('user_routines').doc(_activeRoutine!.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryAccent,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro: ${snapshot.error}',
              style: const TextStyle(color: AppColors.white)
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Rotina não encontrada',
              style: const TextStyle(color: AppColors.white)
            ),
          );
        }

        final updatedRoutine = WorkoutRoutine.fromFirestore(snapshot.data!);
        final dailyWorkout = updatedRoutine.dailyWorkouts[_selectedDay];
        final isPassedDay = _isDayPassed(_selectedDay);
        
        if (dailyWorkout == null || dailyWorkout.exercises.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_gymnastics,
                  size: 60,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum treino para $_selectedDay',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  dailyWorkout.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Exercícios',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 16),
              
              ...dailyWorkout.exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                
                final isCompleted = _completedExercises[_selectedDay]?[exercise.exerciseId] == true;
                
                return WorkoutExerciseCard(
                  exercise: exercise,
                  order: index + 1,
                  isDisabled: isPassedDay,
                  isCompleted: isCompleted,
                  onComplete: _onExerciseComplete,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}