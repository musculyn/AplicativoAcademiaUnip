import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/core/widgets/bottom_nav_bar.dart';
import 'package:gym_app/data/models/workout_routine.dart';
import 'package:gym_app/presentation/history/workout_history_screen.dart';
import 'package:gym_app/presentation/routines/create_routine_screen.dart';

const int routinesScreenIndex = 2;

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  DateTime _focusedDay = DateTime.now();
  String? _selectedRoutineId;
  
  final Map<DateTime, String> _dayStatus = {};

  final List<String> _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  
  late final List<int> _years;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _years = List.generate(currentYear + 2 - 2025, (index) => 2025 + index);
    _loadUserActiveRoutine();
    _loadWorkoutHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWorkoutHistory();
  }

  Future<void> _loadUserActiveRoutine() async {
    if (_currentUserId == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final activeRoutineId = userDoc.data()?['activeRoutineId'] as String?;
      
      setState(() {
        _selectedRoutineId = activeRoutineId;
      });
    } catch (e) {
      print('Erro ao carregar rotina ativa: $e');
    }
  }

  Future<void> _loadWorkoutHistory() async {
    if (_currentUserId == null) return;

    try {
      final historyQuery = await _firestore
          .collection('workout_history')
          .where('userId', isEqualTo: _currentUserId)
          .get();
    
      final newDayStatus = <DateTime, String>{};
      
      for (final doc in historyQuery.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateBrazil = date.toLocal();
        final completed = data['completed'] as bool? ?? false;
        final dateOnly = DateTime(dateBrazil.year, dateBrazil.month, dateBrazil.day);
        newDayStatus[dateOnly] = completed ? 'completed' : 'incomplete';
      }
      
      setState(() {
        _dayStatus.clear();
        _dayStatus.addAll(newDayStatus);
      });
      
    } catch (e) {
      print('Erro ao carregar histórico: $e');
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserActiveRoutine(),
      _loadWorkoutHistory(),
    ]);
  }

  Future<void> _updateActiveRoutine(String? routineId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'activeRoutineId': routineId ?? '',
      });

      setState(() {
        _selectedRoutineId = routineId;
      });

      if (routineId != null && routineId.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rotina ativada!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma rotina ativa selecionada.'),
            backgroundColor: AppColors.secondaryText,
          ),
        );
      }
    } catch (e) {
      print('Erro ao atualizar rotina ativa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar rotina: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleRoutineSelection(String routineId) {
    setState(() {
      if (_selectedRoutineId == routineId) {
        _selectedRoutineId = null;
        _updateActiveRoutine(null);
      } else {
        _selectedRoutineId = routineId;
        _updateActiveRoutine(routineId);
      }
    });
  }

  void _navigateToEditRoutine(String routineId, String routineName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRoutineScreen(
          initialName: routineName,
          routineId: routineId,
          isEditing: true,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _deleteRoutine(String routineId, String routineName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryBackground,
          title: Text(
            'Excluir Rotina',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Tem certeza que deseja excluir a rotina "$routineName"?\n\nEsta ação não pode ser desfeita.',
            style: TextStyle(color: AppColors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Excluir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestore.collection('user_routines').doc(routineId).delete();
        
        if (_selectedRoutineId == routineId) {
          await _updateActiveRoutine(null);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rotina "$routineName" excluída com sucesso!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Erro ao excluir rotina: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir rotina: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeMonth(int month) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, month + 1, _focusedDay.day);
    });
  }

  void _changeYear(int year) {
    setState(() {
      _focusedDay = DateTime(year, _focusedDay.month, _focusedDay.day);
    });
  }

  Future<void> _showNameModalAndNavigate() async {
    final TextEditingController nameController = TextEditingController();
    
    final bool? shouldNavigate = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryBackground,
          title: Text('Nome da Nova Rotina', style: TextStyle(color: AppColors.white)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ex: Treino Hipertrofia A-B-C',
              hintStyle: TextStyle(color: AppColors.secondaryText),
              filled: true,
              fillColor: AppColors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(color: AppColors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Criar', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome da rotina não pode ser vazio.'), backgroundColor: Colors.red),
                  );
                } else {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        );
      },
    );

    if (shouldNavigate == true && nameController.text.trim().isNotEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateRoutineScreen(initialName: nameController.text.trim()),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == routinesScreenIndex) return;
    
    final List<String> routes = ['/workouts', '/exercises', '/routines', '/profile'];
    
    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Center(child: Text('Erro: Usuário não logado.', style: TextStyle(color: AppColors.white)));
    }
    
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Rotinas',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryBackground,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: () => _refreshIndicatorKey.currentState?.show(),
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshData,
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.primaryBackground,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildCalendarHeader(),
              
              _buildCalendarGrid(),
              
              const SizedBox(height: 16),
              
              _buildRoutinesSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: routinesScreenIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
  
  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<int>(
              value: _focusedDay.month - 1,
              onChanged: (int? newValue) {
                if (newValue != null) {
                  _changeMonth(newValue);
                }
              },
              items: _months.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              dropdownColor: AppColors.primaryBackground,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.white),
              isExpanded: false,
              style: TextStyle(color: AppColors.white),
              elevation: 4,
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<int>(
              value: _focusedDay.year,
              onChanged: (int? newValue) {
                if (newValue != null) {
                  _changeYear(newValue);
                }
              },
              items: _years.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              dropdownColor: AppColors.primaryBackground,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.white),
              isExpanded: false,
              style: TextStyle(color: AppColors.white),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    const daysOfWeek = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final startDay = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));

    final List<DateTime> calendarDays = List.generate(42, (index) => startDay.add(Duration(days: index)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek.map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 5),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.5,
              mainAxisSpacing: 1.0,
              crossAxisSpacing: 1.0,
            ),
            itemBuilder: (context, index) {
              final day = calendarDays[index];
              final isCurrentMonth = day.month == _focusedDay.month;
              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
              
              final color = isCurrentMonth ? AppColors.white : AppColors.placeholderGrey.withOpacity(0.5);
              
              final dayForComparison = DateTime(day.year, day.month, day.day);
              final dayStatus = _dayStatus[dayForComparison];
              
              Color? statusColor;
              if (dayStatus == 'completed') {
                statusColor = AppColors.successGreen;
              } else if (dayStatus == 'incomplete') {
                statusColor = Colors.red;
              }
              
              return GestureDetector(
                onTap: () {
                  if (dayStatus != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutHistoryScreen(selectedDate: dayForComparison),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: statusColor != null
                      ? BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        )
                      : (isToday
                          ? BoxDecoration(
                              color: AppColors.primaryAccent,
                              shape: BoxShape.circle,
                            )
                          : null),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: (statusColor != null || isToday) ? AppColors.white : color,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoutinesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Minhas Rotinas',
              style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),

        _buildRoutineList(),

        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showNameModalAndNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Criar Nova Rotina',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('user_routines')
          .where('userId', isEqualTo: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar rotinas: ${snapshot.error}', style: TextStyle(color: AppColors.white)));
        }

        final documents = snapshot.data?.docs ?? [];
        final routines = documents.map((doc) => WorkoutRoutine.fromFirestore(doc)).toList();

        if (routines.isEmpty) {
          return Container(
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, color: AppColors.secondaryText, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma rotina criada',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];
            final isSelected = _selectedRoutineId == routine.id;

            return _buildRoutineCard(
              routine: routine,
              isSelected: isSelected,
              onToggle: _toggleRoutineSelection,
              onEdit: () => _navigateToEditRoutine(routine.id, routine.name),
              onDelete: () => _deleteRoutine(routine.id, routine.name),
            );
          },
        );
      },
    );
  }

  Widget _buildRoutineCard({
    required WorkoutRoutine routine,
    required bool isSelected,
    required Function(String) onToggle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryAccent : AppColors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primaryAccent : AppColors.secondaryText,
              width: 2,
            ),
          ),
          child: isSelected 
              ? Icon(Icons.check, color: AppColors.white, size: 14)
              : null,
        ),
        title: Text(
          routine.name,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.primaryAccent, size: 18),
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.withOpacity(0.7), size: 18),
              onPressed: onDelete,
              tooltip: 'Excluir',
            ),
          ],
        ),
        onTap: () => onToggle(routine.id),
      ),
    );
  }
}