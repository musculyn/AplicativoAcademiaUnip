import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class HistoryListItem extends StatelessWidget {
  final Map<String, dynamic> historyData;
  final String documentId;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(bool) onCompletionToggle;

  const HistoryListItem({
    super.key,
    required this.historyData,
    required this.documentId,
    required this.onTap,
    required this.onDelete,
    required this.onCompletionToggle,
  });

  String _getRoutineName(Map<String, dynamic>? routineData) {
    if (routineData == null) return 'Rotina Excluída';
    return routineData['name'] ?? 'Rotina Desconhecida';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatDayOfWeek(DateTime date) {
    return DateFormat('EEEE', 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = historyData['date'] as Timestamp;
    final date = timestamp.toDate();
    
    final workoutName = historyData['workoutName'] ?? 'Treino Sem Nome';
    final dayOfWeek = historyData['dayOfWeek'] ?? _formatDayOfWeek(date);
    final completed = historyData['completed'] as bool? ?? false;
    final routineData = historyData['routineData'] as Map<String, dynamic>?;
    final routineName = _getRoutineName(routineData);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      color: AppColors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.white, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: completed ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
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
        title: Text(
          workoutName,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              routineName,
              style: TextStyle(
                color: AppColors.placeholderGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$dayOfWeek • ${_formatDate(date)}',
              style: TextStyle(
                color: AppColors.placeholderGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: completed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: completed ? Colors.green : AppColors.primaryAccent,
                  width: 1,
                ),
              ),
              child: Text(
                completed ? 'COMPLETADO' : 'NÃO COMPLETADO',
                style: TextStyle(
                  color: completed ? Colors.green : AppColors.primaryAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.placeholderGrey),
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            } else if (value == 'toggle') {
              onCompletionToggle(!completed);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    completed ? Icons.close : Icons.check,
                    color: completed ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    completed ? 'Marcar como Não Completo' : 'Marcar como Completo',
                    style: TextStyle(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Excluir Histórico',
                    style: TextStyle(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          color: AppColors.primaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.white, width: 1),
          ),
        ),
      ),
    );
  }
}