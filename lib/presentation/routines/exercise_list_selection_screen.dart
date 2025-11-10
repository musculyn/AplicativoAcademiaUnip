import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/data/models/exercise.dart';
import 'package:gym_app/data/models/workout_routine.dart';
import 'package:gym_app/presentation/routines/widgets/exercise_selection_card.dart';

const String selectionScreenTitle = 'Selecionar Exercício';

class ExerciseListSelectionScreen extends StatefulWidget {
  final List<RoutineExercise> currentDayExercises;

  const ExerciseListSelectionScreen({
    super.key, 
    required this.currentDayExercises
  });

  @override
  State<ExerciseListSelectionScreen> createState() => _ExerciseListSelectionScreenState();
}

class _ExerciseListSelectionScreenState extends State<ExerciseListSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  
  final List<String> _categories = [
    'Todos', 'Abdomen', 'Antebraco', 'Costas', 'Costas Inferior', 'Costas Superior', 'Coxa Posterior', 'Coxa Frontal', 'Gluteo', 'Obliquos', 'Ombro', 'Panturrilha', 'Peito', 'Triceps'
  ];

  List<RoutineExercise> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  bool _isExerciseAlreadyInWorkout(Exercise exercise) {
    return widget.currentDayExercises
        .any((e) => e.exerciseId == exercise.id);
  }

  void _toggleSelection(Exercise exercise) {
    if (_isExerciseAlreadyInWorkout(exercise)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${exercise.name}" já foi adicionado ao treino deste dia.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      final existingIndex = _selectedExercises.indexWhere((e) => e.exerciseId == exercise.id);
      
      if (existingIndex != -1) {
        _selectedExercises.removeAt(existingIndex);
      } else {
        _selectedExercises.add(RoutineExercise(
          exerciseId: exercise.id,
          name: exercise.name,
          sets: 3,
          reps: '10-12',
          weight: 0.0,
        ));
      }
    });
  }

  void _confirmSelection() {
    if (_selectedExercises.isNotEmpty) {
      Navigator.of(context).pop(_selectedExercises);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um exercício para adicionar à rotina.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isExerciseSelected(Exercise exercise) {
    return _selectedExercises.any((e) => e.exerciseId == exercise.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(selectionScreenTitle, style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBackground,
        iconTheme: const IconThemeData(color: AppColors.white),
        automaticallyImplyLeading: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por Exercícios',
                hintStyle: TextStyle(color: AppColors.secondaryText),
                prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
              ),
              style: const TextStyle(color: AppColors.white),
            ),
          ),
          
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category || (category == 'Todos' && _selectedCategory == null);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (category == 'Todos') {
                          _selectedCategory = null;
                        } else {
                          _selectedCategory = selected ? category : null;
                        }
                      });
                    },
                    selectedColor: AppColors.primaryAccent,
                    backgroundColor: AppColors.primaryBackground,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryAccent : AppColors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_selectedExercises.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              color: AppColors.primaryAccent.withOpacity(0.2),
              child: Text(
                '${_selectedExercises.length} exercício(s) selecionado(s)',
                style: const TextStyle(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('global_exercises').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro de Conexão: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }
                
                final List<DocumentSnapshot> documents = snapshot.data?.docs ?? [];
                
                if (documents.isEmpty) {
                   return Center(child: Text('Nenhum exercício encontrado.', style: TextStyle(color: AppColors.secondaryText)));
                }

                List<Exercise> allExercises = documents.map((doc) => Exercise.fromFirestore(doc)).toList();
                
                if (_selectedCategory != null && _selectedCategory != 'Todos') {
                  allExercises = allExercises.where((ex) => ex.category == _selectedCategory).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  final queryLower = _searchQuery.toLowerCase();
                  allExercises = allExercises.where((ex) {
                    return ex.name.toLowerCase().contains(queryLower) ||
                           ex.category.toLowerCase().contains(queryLower);
                  }).toList();
                }

                if (allExercises.isEmpty) {
                  return Center(child: Text('Nenhum exercício corresponde à sua busca/filtro.', style: TextStyle(color: AppColors.white)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: allExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = allExercises[index];
                    final isSelected = _isExerciseSelected(exercise);
                    final alreadyInWorkout = _isExerciseAlreadyInWorkout(exercise);

                    return ExerciseSelectionCard(
                      exercise: exercise,
                      isSelected: isSelected,
                      isAlreadyInWorkout: alreadyInWorkout,
                      onSelect: () => _toggleSelection(exercise),
                    );
                  },
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmSelection,
                icon: const Icon(Icons.add, color: AppColors.white),
                label: Text(
                  'Adicionar ${_selectedExercises.length > 0 ? '(${_selectedExercises.length})' : ''} Treino(s) na Rotina',
                  style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedExercises.isNotEmpty 
                      ? AppColors.primaryAccent 
                      : AppColors.secondaryText,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}