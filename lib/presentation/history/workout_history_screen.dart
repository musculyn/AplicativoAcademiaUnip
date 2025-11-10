import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/data/datasources/history_service.dart';
import 'package:gym_app/presentation/history/widgets/history_detail_modal.dart';
import 'package:gym_app/presentation/history/widgets/history_list_item.dart';
class WorkoutHistoryScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const WorkoutHistoryScreen({super.key, this.selectedDate});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;
  bool _hasError = false;
  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
  }

  Future<void> _loadWorkoutHistory() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      QuerySnapshot historySnapshot;
      if (widget.selectedDate != null) {
        historySnapshot = await _historyService.getWorkoutHistoryByDate(
          _currentUserId, 
          widget.selectedDate!
        );
      } else {
        historySnapshot = await _historyService.getUserWorkoutHistory(_currentUserId);
      }

      final List<Map<String, dynamic>> enrichedHistory = [];
      for (final doc in historySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final routineId = data['routineId'] as String?;
        
        final routineDoc = await _historyService.getRoutineById(routineId);
        final routineData = routineDoc?.data() as Map<String, dynamic>?;
        final enrichedData = Map<String, dynamic>.from(data);
        enrichedData['routineData'] = routineData;
        enrichedData['documentId'] = doc.id;
        
        enrichedHistory.add(enrichedData);
      }

      setState(() {
        _historyList = enrichedHistory;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _deleteWorkoutHistory(String historyId, String workoutName) async {
    final bool?
    confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.white, width: 1),
          ),
          title: 
          Text(
            'Excluir Histórico',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Tem certeza que deseja excluir o histórico do treino "$workoutName"?\n\nEsta ação não pode ser desfeita.',
            style: TextStyle(color: AppColors.white),
          
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: AppColors.placeholderGrey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Excluir', style: TextStyle(color: 
                Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _historyService.deleteWorkoutHistory(historyId);
        setState(() {
          _historyList.removeWhere((item) => item['documentId'] == historyId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Histórico excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir histórico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleWorkoutCompletion(String historyId, bool completed, String workoutName) async {
    try {
      await _historyService.updateWorkoutCompletion(historyId, completed);
      setState(() {
        final index = _historyList.indexWhere((item) => item['documentId'] == historyId);
        if (index != -1) {
          _historyList[index]['completed'] = completed;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Treino ${completed ? 'marcado como completo' : 'marcado como não completo'}!'),
          backgroundColor: completed ? Colors.green : AppColors.primaryAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar treino: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHistoryDetails(Map<String, dynamic> historyData, String documentId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return HistoryDetailModal(
          historyData: historyData,
          documentId: documentId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.selectedDate != null ? 'Histórico do Dia' : 'Histórico de Treinos',
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBackground,
        iconTheme: const IconThemeData(color: AppColors.white),
  
        actions: [
          if (_historyList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWorkoutHistory,
              tooltip: 'Recarregar',
            ),
        ],
    
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
           
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                   
                        color: AppColors.placeholderGrey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Erro ao carregar histórico',
                        style: TextStyle(color: AppColors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
  
                        onPressed: _loadWorkoutHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                        ),
 
                        child: const Text(
                          'Tentar Novamente',
                          style: TextStyle(color: AppColors.black),
                    
                        ),
                      ),
                    ],
                  ),
                )
              : _historyList.isEmpty
     
              ?
                Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
 
                            Icons.history,
                            size: 80,
                            color: AppColors.placeholderGrey.withOpacity(0.5),
               
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.selectedDate != null 
    
                                ? 'Nenhum treino registrado nesta data'
                                : 'Nenhum histórico de treinos',
                            style: TextStyle(
  
                                color: AppColors.placeholderGrey,
                              fontSize: 16,
                            ),
            
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
   
                            widget.selectedDate != null
                                ?
                                'Os treinos completados aparecerão aqui'
                                : 'Complete alguns treinos para ver seu histórico',
                            style: TextStyle(
                            
                                color: AppColors.placeholderGrey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
         
                          ),
                        ],
                      ),
                    )
                 
                : RefreshIndicator(
                      onRefresh: _loadWorkoutHistory,
                      color: AppColors.primaryAccent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
   
                        itemCount: _historyList.length,
                        itemBuilder: (context, index) {
                          final historyData = _historyList[index];
                      
                          final documentId = historyData['documentId'] as String;
                          final workoutName = historyData['workoutName'] ?? 'Treino Sem Nome';
                          return HistoryListItem(
                            historyData: historyData,
                            documentId: documentId,
                            onTap: () => _showHistoryDetails(historyData, documentId),
         
                            onDelete: () => _deleteWorkoutHistory(documentId, workoutName),
                            onCompletionToggle: (completed) => 
                                _toggleWorkoutCompletion(documentId, completed, workoutName),
            
                          );
                        },
                      ),
                    ),
    );
  }
}