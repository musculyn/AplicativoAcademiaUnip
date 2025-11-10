import 'package:flutter/material.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/data/models/workout_routine.dart';

class WorkoutExerciseCard extends StatefulWidget {
  final RoutineExercise exercise;
  final int order;
  final bool isDisabled;
  final bool isCompleted;
  final Function(RoutineExercise) onComplete;

  const WorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.order,
    required this.isDisabled,
    required this.isCompleted,
    required this.onComplete,
  });

  @override
  State<WorkoutExerciseCard> createState() => _WorkoutExerciseCardState();
}

class _WorkoutExerciseCardState extends State<WorkoutExerciseCard> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
  }

  void _handleComplete() {
    if (!widget.isDisabled && !_isCompleted) {
      setState(() {
        _isCompleted = true;
      });
      widget.onComplete(widget.exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isDisabled;
    final isCompleted = _isCompleted;

    return Card(
      color: AppColors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted 
              ? AppColors.successGreen 
              : AppColors.cardColor,
          width: isCompleted ? 2 : 0,
        ),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Número/Ícone
                if (isCompleted)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen, 
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.order}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: TextStyle(
                      color: isCompleted 
                          ? AppColors.successGreen 
                          : (isDisabled ? AppColors.secondaryText : AppColors.white),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Informações do exercício
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Séries: ${widget.exercise.sets} | Repetições: ${widget.exercise.reps}',
                  style: TextStyle(
                    color: isCompleted 
                        ? AppColors.successGreen.withOpacity(0.8)
                        : (isDisabled ? AppColors.secondaryText.withOpacity(0.7) : AppColors.secondaryText),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Carga: ${widget.exercise.weight} kg | Descanso: ${widget.exercise.restTime}s',
                  style: TextStyle(
                    color: isCompleted 
                        ? AppColors.successGreen.withOpacity(0.8)
                        : (isDisabled ? AppColors.secondaryText.withOpacity(0.7) : AppColors.secondaryText),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botão de Completar Treino
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isDisabled || isCompleted ? null : _handleComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted 
                      ? AppColors.successGreen
                      : (isDisabled 
                          ? AppColors.secondaryText.withOpacity(0.3)
                          : AppColors.primaryAccent),
                  
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCompleted 
                      ? 'Treino Completo ✓'
                      : (isDisabled ? 'Dia Passado' : 'Completar Treino'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    
                    color: isCompleted 
                        ? AppColors.successGreen 
                        : (isDisabled ? AppColors.secondaryText.withOpacity(0.3) : AppColors.white ), 
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}