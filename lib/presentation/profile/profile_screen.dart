import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/core/widgets/bottom_nav_bar.dart';
import 'package:gym_app/data/datasources/workout_service.dart';
import 'package:gym_app/presentation/auth/login_screen.dart';
import 'package:gym_app/presentation/history/workout_history_screen.dart';
import 'package:gym_app/presentation/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _workoutStats;
  Map<String, Map<String, dynamic>> _exerciseProgress = {};
  bool _isLoading = true;
  int _weeklyGoal = 3;

  final WorkoutService _workoutService = WorkoutService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAllData();
    }
  }

  Future<void> _loadAllData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    await _loadUserData();
    await _loadWorkoutStats();
    await _loadExerciseProgress();
    await _loadWeeklyGoal();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            _userData = userDoc.data()!;
          });
        }
      } catch (e) {
        print('Erro ao carregar dados do usuário: $e');
      }
    }
  }

  Future<void> _loadWorkoutStats() async {
  final user = _auth.currentUser;
  if (user != null) {
    try {
      final historyQuery = await _firestore
          .collection('workout_history')
          .where('userId', isEqualTo: user.uid)
          .where('completed', isEqualTo: true)
          .get();
      final totalWorkouts = historyQuery.docs.length;
      
      final now = DateTime.now().toLocal();
      final today = DateTime(now.year, now.month, now.day);
      int consecutiveDays = 0;

      final currentWeekday = now.weekday;
      
      for (int i = 0; i < currentWeekday; i++) {
        final day = today.subtract(Duration(days: i));
        
        final hasWorkout = historyQuery.docs.any((doc) {
          final workoutDate = (doc.data()['date'] as Timestamp).toDate().toLocal();
          final workoutDay = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);
          return workoutDay.isAtSameMomentAs(day);
        });

        if (hasWorkout) {
          consecutiveDays++;
        } else {
          break;
        }
      }

      if (mounted) {
        setState(() {
          _workoutStats = {
            'totalWorkouts': totalWorkouts,
            'consecutiveDays': consecutiveDays,
          };
        });
      }
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }
}

  Future<void> _loadExerciseProgress() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final progress = await _workoutService.getUserExerciseProgress(userId: user.uid);
        if (mounted) {
          setState(() {
            _exerciseProgress = progress;
          });
        }
      } catch (e) {
        print('Erro ao carregar progresso dos exercícios: $e');
      }
    }
  }

  Future<void> _loadWeeklyGoal() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final goal = userDoc.data()?['weeklyGoal'] as int?;
        if (mounted) {
          setState(() {
            _weeklyGoal = goal ?? 3;
          });
        }
      } catch (e) {
        print('Erro ao carregar meta semanal: $e');
      }
    }
  }

  Future<void> _updateWeeklyGoal(int newGoal) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'weeklyGoal': newGoal,
        });
        if (mounted) {
          setState(() {
            _weeklyGoal = newGoal;
          });
        }
      } catch (e) {
        print('Erro ao atualizar meta semanal: $e');
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Erro ao fazer logout: $e');
    }
  }

  void _showEditProfileDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    ).then((_) {
      _loadAllData();
    });
  }

  void _showWeeklyGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempGoal = _weeklyGoal;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardColor,
              title: const Text(
                'Meta Semanal',
                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quantos dias na semana você quer treinar?',
                    style: TextStyle(color: AppColors.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            tempGoal = day;
                          });
                        },
                        child: Container(
                          width: 55, 
                          height: 55, 
                          decoration: BoxDecoration(
                            color: tempGoal == day ? AppColors.primaryAccent : AppColors.primaryBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tempGoal == day ? AppColors.primaryAccent : AppColors.secondaryText.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: tempGoal == day ? AppColors.white : AppColors.secondaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Meta selecionada: $tempGoal dias',
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.secondaryText)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateWeeklyGoal(tempGoal);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                  ),
                  child: const Text('Salvar', style: TextStyle(color: AppColors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
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
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.primaryBackground,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 20),
                    
                    _buildWorkoutStatsSection(),
                    const SizedBox(height: 20),
                    
                    _buildExerciseProgressSection(),
                    const SizedBox(height: 20),
                    
                    _buildActionsSection(),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/workouts');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/exercises');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/routines');
          }
        },
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?['name'] ?? 'Usuário',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _auth.currentUser?.email ?? '',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showEditProfileDialog,
                icon: Icon(Icons.edit, color: AppColors.primaryAccent),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(color: AppColors.secondaryText, height: 1),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileDataItem('Altura', '${_userData?['height'] ?? '--'} cm'),
              _buildProfileDataItem('Peso', '${_userData?['weight'] ?? '--'} kg'),
              _buildProfileDataItem('Gênero', _userData?['gender'] ?? '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDataItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutStatsSection() {
    final stats = _workoutStats ?? {};
    final completedDays = stats['consecutiveDays'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas de Treino',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🏋️', 'Treinos', '${stats['totalWorkouts'] ?? 0}'),
              _buildStatItem('🔥', 'Dias Consec.', '$completedDays'),
              _buildStatItem('🎯', 'Meta Semanal', '$_weeklyGoal dias', onTap: _showWeeklyGoalDialog),
            ],
          ),
          
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso Semanal',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$completedDays/$_weeklyGoal',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBackground,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: completedDays / _weeklyGoal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: completedDays >= _weeklyGoal ? AppColors.successGreen : AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseProgressSection() {
    final progressEntries = _exerciseProgress.entries.toList();
    progressEntries.sort((a, b) => (b.value['progress'] as double).compareTo(a.value['progress'] as double));
    
    final topExercises = progressEntries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Evolução de Carga',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (progressEntries.isNotEmpty)
                Text(
                  '${progressEntries.length} exercícios',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          
          if (progressEntries.isEmpty)
            _buildEmptyProgressState()
          else
            Column(
              children: [
                ...topExercises.map((entry) => _buildExerciseProgressCard(entry)),
                
                if (progressEntries.length > 3)
                  Column(
                    children: [
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showAllExercisesProgress(progressEntries),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBackground,
                            foregroundColor: AppColors.primaryAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: AppColors.primaryAccent),
                            ),
                          ),
                          child: const Text(
                            'Ver Todos os Exercícios',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseProgressCard(MapEntry<String, Map<String, dynamic>> entry) {
  final exerciseData = entry.value;
  final progress = exerciseData['progress'] as double;
  final firstWeight = exerciseData['firstWeight'] as double;
  final lastWeight = exerciseData['lastWeight'] as double;
  
  Color progressColor = progress > 0 ? AppColors.successGreen : progress < 0 ? Colors.red : AppColors.secondaryText;
  IconData progressIcon = progress > 0 ? Icons.trending_up : progress < 0 ? Icons.trending_down : Icons.trending_flat;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(progressIcon, color: progressColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                exerciseData['name'] as String? ?? 'Exercício',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${progress > 0 ? '+' : ''}${progress.toStringAsFixed(1)} kg',
              style: TextStyle(
                color: progressColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Início: ${firstWeight.toStringAsFixed(1)} kg → Atual: ${lastWeight.toStringAsFixed(1)} kg',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showExerciseDetails(exerciseData),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text(
              'Ver Detalhes',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyProgressState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 40,
            color: AppColors.secondaryText.withOpacity(0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete alguns treinos para ver sua evolução',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAllExercisesProgress(List<MapEntry<String, Map<String, dynamic>>> progressEntries) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Todos os Exercícios (${progressEntries.length})',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: progressEntries.length,
                  itemBuilder: (context, index) {
                    return _buildExerciseProgressCard(progressEntries[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExerciseDetails(Map<String, dynamic> exerciseData) {
    final history = exerciseData['history'] as List<Map<String, dynamic>>;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: Text(
            exerciseData['name'] as String? ?? 'Exercício',
            style: const TextStyle(color: AppColors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailedProgressChart(history),
                const SizedBox(height: 15),
                ...history.reversed.take(5).map((record) => _buildHistoryRecord(record)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(color: AppColors.primaryAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedProgressChart(List<Map<String, dynamic>> history) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: history.length > 1 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProgressIndicator('Início', history.first['weight'] as double),
                    _buildProgressIndicator('Máximo', _getMaxWeight(history)),
                    _buildProgressIndicator('Atual', history.last['weight'] as double),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Progresso total: ${_calculateTotalProgress(history)} kg',
                  style: TextStyle(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                'Complete mais treinos para ver estatísticas',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
    );
  }

  Widget _buildProgressIndicator(String label, double weight) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${weight.toStringAsFixed(1)} kg',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _getMaxWeight(List<Map<String, dynamic>> history) {
    return history.map((h) => h['weight'] as double).reduce((a, b) => a > b ? a : b);
  }

  String _calculateTotalProgress(List<Map<String, dynamic>> history) {
    final progress = (history.last['weight'] as double) - (history.first['weight'] as double);
    return '${progress > 0 ? '+' : ''}${progress.toStringAsFixed(1)}';
  }

  Widget _buildHistoryRecord(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record['weight']} kg',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                record['workoutName'] ?? '',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            _formatDate(record['date'] as DateTime),
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildActionButton(
            'Histórico de Treinos',
            Icons.history,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Sair da Conta',
            Icons.logout,
            _signOut,
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap, {bool isLogout = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : AppColors.primaryAccent,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isLogout ? Colors.red : AppColors.secondaryText,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}