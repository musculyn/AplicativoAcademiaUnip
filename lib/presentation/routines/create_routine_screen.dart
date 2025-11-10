import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/data/models/workout_routine.dart';
import 'package:gym_app/presentation/routines/exercise_list_selection_screen.dart';
import 'package:gym_app/presentation/shared/time_picker_modal.dart';

class CreateRoutineScreen extends StatefulWidget {
  final String initialName;
  final String? routineId;
  final bool isEditing;

  const CreateRoutineScreen({
    super.key,
    required this.initialName,
    this.routineId,
    this.isEditing = false,
  });

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _routineName;
  late Map<String, DailyWorkout> _dailyWorkouts;

  String _selectedDay = 'Segunda';
  late TextEditingController _workoutNameController;
  late TextEditingController _restTimeController;

  final List<String> _daysOfWeek = [
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
  ];
  final List<String> _dayInitials = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _routineName = widget.initialName;

    _dailyWorkouts = {
      for (var day in _daysOfWeek) day: DailyWorkout(
        name: 'Treino de $day',
        exercises: [],
        restTime: 60,
        workoutTime: '07:00',
      ),
    };
    _workoutNameController = TextEditingController(
      text: _dailyWorkouts[_selectedDay]!.name,
    );
    _restTimeController = TextEditingController(
      text: _dailyWorkouts[_selectedDay]!.restTime.toString(),
    );

    _workoutNameController.addListener(_updateCurrentWorkoutName);
    _restTimeController.addListener(_updateCurrentRestTime);
    if (widget.isEditing && widget.routineId != null) {
      _loadRoutineData();
    }
  }

  Future<void> _loadRoutineData() async {
    try {
      final routineDoc = await _firestore.collection('user_routines').doc(widget.routineId).get();
      if (routineDoc.exists) {
        final routine = WorkoutRoutine.fromFirestore(routineDoc);
        setState(() {
          _routineName = routine.name;
          _dailyWorkouts = routine.dailyWorkouts;
          _workoutNameController.text = _dailyWorkouts[_selectedDay]?.name ?? 'Treino de $_selectedDay';
          _restTimeController.text = _dailyWorkouts[_selectedDay]?.restTime.toString() ?? '60';
        });
      }
    } catch (e) {
      print('Erro ao carregar rotina para edição: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar rotina: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateCurrentWorkoutName() {
    if (_dailyWorkouts[_selectedDay] != null) {
      _dailyWorkouts[_selectedDay]!.name = _workoutNameController.text;
    }
  }

  void _updateCurrentRestTime() {
    if (_dailyWorkouts[_selectedDay] != null) {
      final restTime = int.tryParse(_restTimeController.text) ?? 60;
      _dailyWorkouts[_selectedDay]!.restTime = restTime;
    }
  }

  Future<void> _showTimePicker() async {
    final currentWorkout = _dailyWorkouts[_selectedDay]!;
    final String? selectedTime = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return TimePickerModal(initialTime: currentWorkout.workoutTime);
      },
    );
    if (selectedTime != null && selectedTime.isNotEmpty) {
      _updateCurrentWorkoutTime(selectedTime);
    }
  }

  void _updateCurrentWorkoutTime(String newTime) {
    if (_dailyWorkouts[_selectedDay] != null) {
      setState(() {
        _dailyWorkouts[_selectedDay]!.workoutTime = newTime;
      });
    }
  }

  void _applyTimeToAllDays(String time) {
    setState(() {
      for (var day in _daysOfWeek) {
        if (_dailyWorkouts[day] != null) {
          _dailyWorkouts[day]!.workoutTime = time;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Horário $time aplicado para todos os dias'),
        backgroundColor: AppColors.primaryAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  void _selectDay(String day) {
    setState(() {
      _dailyWorkouts[_selectedDay]!.name = _workoutNameController.text;
      _dailyWorkouts[_selectedDay]!.restTime = int.tryParse(_restTimeController.text) ?? 60;

      _selectedDay = day;

      _workoutNameController.text = _dailyWorkouts[_selectedDay]!.name;
      _restTimeController.text = _dailyWorkouts[_selectedDay]!.restTime.toString();
    });
  }

  Future<void> _addExercise() async {
    final List<RoutineExercise>?
    result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseListSelectionScreen(
          currentDayExercises: _dailyWorkouts[_selectedDay]!.exercises,
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        for (final exercise in result) {
          _dailyWorkouts[_selectedDay]!.exercises.add(RoutineExercise(
            exerciseId: exercise.exerciseId,
            name: exercise.name,
            sets: 3,
            reps: '10-12',

            weight: 0.0,
            restTime: _dailyWorkouts[_selectedDay]!.restTime,
          ));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.length} exercício(s) adicionado(s) ao treino!'),
          backgroundColor: AppColors.primaryAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeExercise(RoutineExercise exercise) {
    setState(() {
      _dailyWorkouts[_selectedDay]!.exercises.remove(exercise);
    });
  }

  Future<void> _editExerciseDetails(RoutineExercise exercise) async {
    final TextEditingController setsController = TextEditingController(text: exercise.sets.toString());
    final TextEditingController repsController = TextEditingController(text: exercise.reps);
    final TextEditingController weightController = TextEditingController(text: exercise.weight > 0 ? exercise.weight.toString() : '');
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryBackground,
          title: Text('Detalhes do Exercício: ${exercise.name}', style: const TextStyle(color: AppColors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: <Widget>[
                _buildNumberField(
                  controller: setsController,
                  label: 'Número de Séries (Ex: 3)',
                ),

                const SizedBox(height: 15),
                _buildTextField(
                  controller: repsController,
                  label: 'Repetições (Ex: 10-12)',
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Carga (kg) *',

                    labelStyle: TextStyle(color: AppColors.secondaryText),
                    hintText: 'Ex: 20.5',
                    hintStyle: TextStyle(color: AppColors.secondaryText.withOpacity(0.7)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    errorText: weightController.text.isNotEmpty && (double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0) <= 0
                        ?
                        'Carga deve ser maior que 0'
                        : null,
                  ),
                  style: const TextStyle(color: AppColors.white),
                  onChanged: (value) {

                    if (context.mounted) {
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  '* Campo obrigatório',

                  style: TextStyle(
                    color: AppColors.primaryAccent,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),

                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
              onPressed: () {

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salvar', style: TextStyle(color: AppColors.primaryAccent)),
              onPressed: () {

                final weight = double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0.0;

                if (weight <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(

                      content: Text('A carga é obrigatória e deve ser maior que 0!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  exercise.sets = int.tryParse(setsController.text) ?? 3;
                  exercise.reps = repsController.text.trim().isNotEmpty ? repsController.text : 'N/A';
                  exercise.weight = weight;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.secondaryText),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: const TextStyle(color: AppColors.white),

    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    bool isDecimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.secondaryText),
        filled: true,
        fillColor: const Color(0xFF1E293B),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: const TextStyle(color: AppColors.white),
    );
  }

  Future<void> _saveRoutine() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não logado.'), backgroundColor: Colors.red),
      );
      return;
    }

    _dailyWorkouts[_selectedDay]!.name = _workoutNameController.text;
    _dailyWorkouts[_selectedDay]!.restTime = int.tryParse(_restTimeController.text) ?? 60;
    bool hasAnyExercises = false;
    bool allExercisesHaveWeight = true;
    List<String> daysWithoutWeight = [];
    for (final day in _daysOfWeek) {
      final dailyWorkout = _dailyWorkouts[day]!;
      if (dailyWorkout.exercises.isNotEmpty) {
        hasAnyExercises = true;
        for (final exercise in dailyWorkout.exercises) {
          if (exercise.weight <= 0) {
            allExercisesHaveWeight = false;
            if (!daysWithoutWeight.contains(day)) {
              daysWithoutWeight.add(day);
            }
          }
        }
      }
    }

    if (!hasAnyExercises) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um exercício em algum dia da semana!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!allExercisesHaveWeight) {
      String daysMessage = daysWithoutWeight.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Defina a carga para todos os exercícios nos dias: $daysMessage'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final routine = WorkoutRoutine(
      id: widget.routineId ?? '',
      userId: _currentUserId,
      name: _routineName,
      isUserDefined: true,
      dailyWorkouts: _dailyWorkouts,
    );
    try {
      if (widget.isEditing && widget.routineId != null) {
        await _firestore.collection('user_routines').doc(widget.routineId).update(routine.toFirestore());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rotina "$_routineName" atualizada com sucesso!'), backgroundColor: AppColors.primaryAccent),
          );
          Navigator.pop(context);
        }
      } else {
        await _firestore.collection('user_routines').add(routine.toFirestore());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rotina "$_routineName" criada com sucesso!'), backgroundColor: AppColors.primaryAccent),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar rotina: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkout = _dailyWorkouts[_selectedDay]!;
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar Rotina' : 'Criar Rotina',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,

          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBackground,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDaySelector(),


          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Nome do Treino
                  Text(
                    'Nome do Treino',
                    style: TextStyle(
                      color: AppColors.white,

                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _workoutNameController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Peito e Tríceps',

                      hintStyle: TextStyle(color: AppColors.secondaryText.withOpacity(0.7)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),

                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                  ),

                  const SizedBox(height: 16),

                  // Horário e Descanso
                  Row(

                    children: [
                      // Horário do Treino
                      Expanded(
                        flex: 2,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(

                              'Horário',
                              style: TextStyle(
                                color: AppColors.secondaryText,

                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 4),
                            Row(
                              children: [

                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showTimePicker,

                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(

                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(8),

                                        border: Border.all(color: AppColors.secondaryText.withOpacity(0.3)),
                                      ),
                                      child: Row(

                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [

                                          Text(
                                            currentWorkout.workoutTime,

                                            style: const TextStyle(
                                              color: AppColors.white,

                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),

                                          ),
                                          Icon(

                                            Icons.arrow_drop_down,
                                            color: AppColors.secondaryText,

                                            size: 20,
                                          ),
                                        ],

                                      ),
                                    ),

                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(

                                  message: 'Aplicar este horário para todos os dias',
                                  child: GestureDetector(

                                    onTap: () {
                                      _applyTimeToAllDays(currentWorkout.workoutTime);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),

                                      decoration: BoxDecoration(
                                        color: AppColors.primaryAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),

                                        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.5)),
                                      ),

                                      child: Icon(
                                        Icons.schedule,
                                        color: AppColors.primaryAccent,

                                        size: 18,
                                      ),

                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ],
                        ),

                      ),

                      const SizedBox(width: 12),

                      // Descanso entre séries
                      Expanded(

                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              'Descanso (séries)',
                              style: TextStyle(

                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 4),
                            TextField(
                              controller: _restTimeController,

                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(

                                hintText: '60',
                                hintStyle: TextStyle(color: AppColors.secondaryText.withOpacity(0.7)),
                                filled: true,

                                fillColor: const Color(0xFF1E293B),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),

                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                                suffix: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(

                                    's',
                                    style: TextStyle(

                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                    ),

                                  ),
                                ),
                              ),

                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),


                  // Exercícios do Treino
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        'Exercícios do Treino',
                        style: TextStyle(
                          color: AppColors.white,

                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        icon: Icon(Icons.add_circle, color: AppColors.primaryAccent, size: 28),
                        onPressed: _addExercise,
                      ),

                    ],
                  ),
                  const SizedBox(height: 8),

                  currentWorkout.exercises.isEmpty
                      ?
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(

                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              Icon(
                                Icons.fitness_center,
                                color: AppColors.secondaryText.withOpacity(0.5),

                                size: 48,
                              ),
                              const SizedBox(height: 12),

                              Text(
                                'Clique no "+" para adicionar exercícios',
                                style: TextStyle(

                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                ),

                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const
                          NeverScrollableScrollPhysics(),
                          itemCount: currentWorkout.exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = currentWorkout.exercises[index];
                            return _buildRoutineExerciseCard(exercise, index);
                          },
                        ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),


          // Botão de ação
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(

                onPressed: _saveRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),

                child: Text(
                  widget.isEditing ? 'SALVAR ALTERAÇÕES' : 'CONCLUIR ROTINA',
                  style: const TextStyle(
                    color: AppColors.white,

                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // Seletor de dias
  Widget _buildDaySelector() {
    return Container(
      height: 70,
      color: AppColors.primaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _daysOfWeek.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;

          final isSelected = day == _selectedDay;
          final dailyWorkout = _dailyWorkouts[day]!;
          final hasExercises = dailyWorkout.exercises.isNotEmpty;

          final hasExercisesWithoutWeight = hasExercises &&
              dailyWorkout.exercises.any((exercise) => exercise.weight <= 0);


          Color circleColor = isSelected ? AppColors.primaryAccent : AppColors.secondaryText.withOpacity(0.2);
          if (hasExercises && !isSelected) {
             circleColor = AppColors.primaryAccent.withOpacity(0.3);
          } else if (hasExercises && isSelected) {
             circleColor = AppColors.primaryAccent;
          }

          return GestureDetector(
            onTap: () => _selectDay(day),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(

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

                            color: isSelected ? AppColors.white : AppColors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,

                          ),
                        ),
                      ),
                    ),
                    if (hasExercisesWithoutWeight)

                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(

                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(

                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryBackground, width: 1),
                          ),

                          child: const Icon(
                            Icons.warning,
                            color: Colors.white,

                            size: 8,
                          ),
                        ),
                      ),

                  ],
                ),
                const SizedBox(height: 6),
                if (isSelected)
                  Container(
                    height: 3,

                    width: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      borderRadius: BorderRadius.circular(1),

                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoutineExerciseCard(RoutineExercise exercise, int index) {
    final hasWeight = exercise.weight > 0;
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        onTap: () => _editExerciseDetails(exercise),
        leading: Container(
          width: 24,
          height: 24,

          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(

                color: AppColors.primaryAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        title: Text(
          exercise.name,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${exercise.sets} séries × ${exercise.reps} reps',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,

              ),
            ),
            if (!hasWeight)
              Text(
                'Carga não definida',
                style: TextStyle(

                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(

          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.secondaryText, size: 18),
              onPressed: () => _editExerciseDetails(exercise),
            ),
            IconButton(

              icon: Icon(Icons.delete, color: Colors.red.withOpacity(0.7), size: 18),
              onPressed: () => _removeExercise(exercise),
            ),
          ],
        ),
      ),
    );
  }
}