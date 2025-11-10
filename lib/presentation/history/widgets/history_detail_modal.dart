import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class HistoryDetailModal extends StatelessWidget {
  final Map<String, dynamic> historyData;
  final String documentId;

  const HistoryDetailModal({
    super.key,
    required this.historyData,
    required this.documentId,
  });

  String _formatDate(DateTime date) {
    return DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(date);
  }

  String _getRoutineName(Map<String, dynamic>? routineData) {
    if (routineData == null) return 'Rotina Excluída';
    return routineData['name'] ?? 'Rotina Desconhecida';
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = historyData['date'] as Timestamp;
    final date = timestamp.toDate();
    
    final workoutName = historyData['workoutName'] ?? 'Treino Sem Nome';
    final dayOfWeek = historyData['dayOfWeek'] ?? 'Dia não especificado';
    final completed = historyData['completed'] as bool? ?? false;
    final exercises = historyData['exercises'] as List<dynamic>? ?? [];
    final routineData = historyData['routineData'] as Map<String, dynamic>?;
    final routineName = _getRoutineName(routineData);

    return Dialog(
      backgroundColor: AppColors.primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header fixo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: completed
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: completed ? Colors.green : AppColors.primaryAccent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      completed ? Icons.check : Icons.fitness_center,
                      color: completed ? Colors.green : AppColors.primaryAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workoutName,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          routineName,
                          style: TextStyle(
                            color: AppColors.placeholderGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Informações do treino
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        completed ? Icons.check_circle : Icons.schedule,
                        color: completed ? Colors.green : AppColors.primaryAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        completed ? 'Treino Completo' : 'Treino Não Completo',
                        style: TextStyle(
                          color: completed ? Colors.green : AppColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.placeholderGrey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(date),
                        style: TextStyle(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: AppColors.placeholderGrey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dayOfWeek,
                        style: TextStyle(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divisor
            Container(
              height: 1,
              color: AppColors.primaryBackground,
            ),

            // Lista de exercícios com scroll
            Expanded(
              child: exercises.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Nenhum exercício registrado neste treino',
                          style: TextStyle(
                            color: AppColors.placeholderGrey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exercícios (${exercises.length})',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: exercises.length,
                              itemBuilder: (context, index) {
                                final exercise = exercises[index] as Map<String, dynamic>;
                                final exerciseName = exercise['name'] ?? 'Exercício Desconhecido';
                                final sets = exercise['sets'] ?? 0;
                                final reps = exercise['reps'] ?? 'N/A';
                                final weight = exercise['weight'] ?? 0.0;
                                final restTime = exercise['restTime'] ?? 0;
                                final exerciseCompleted = exercise['completed'] as bool? ?? false;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: exerciseCompleted
                                          ? Colors.green.withOpacity(0.3)
                                          : AppColors.placeholderGrey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        exerciseCompleted
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: exerciseCompleted
                                            ? Colors.green
                                            : AppColors.placeholderGrey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${index + 1}. $exerciseName',
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$sets séries × $reps reps',
                                              style: TextStyle(
                                                color: AppColors.placeholderGrey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (weight > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Carga: ${weight}kg | Descanso: ${restTime}s',
                                                style: TextStyle(
                                                  color: AppColors.placeholderGrey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Botão Fechar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
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