import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/core/widgets/bottom_nav_bar.dart';
import 'package:gym_app/data/models/exercise.dart';
import 'package:gym_app/presentation/exercise_list/widgets/exercise_card.dart';

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'Todos', 'Abdomen', 'Antebraco', 'Costas', 'Costas Inferior', 'Costas Superior', 'Coxa Posterior', 'Coxa Frontal', 'Gluteo', 'Obliquos', 'Ombro', 'Panturrilha', 'Peito', 'Triceps'
  ];

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    final List<String> routes = ['/workouts', '/exercises', '/routines', '/profile'];

    if (index >= 0 && index < routes.length) {
       Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        automaticallyImplyLeading: false, // Remove a seta de voltar
        title: Text(
          'Exercícios',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Campo de pesquisa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por Exercícios',
                hintStyle: TextStyle(color: AppColors.secondaryText),
                prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              style: TextStyle(color: AppColors.white),
            ),
          ),
          
          // Categorias
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category || (category == 'Todos' && _selectedCategory == null);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                    checkmarkColor: AppColors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryAccent : AppColors.secondaryText.withOpacity(0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Lista de exercícios
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('global_exercises').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar exercícios: ${snapshot.error}', style: TextStyle(color: AppColors.white)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Nenhum exercício encontrado.', style: TextStyle(color: AppColors.white)));
                }

                List<Exercise> allExercises = snapshot.data!.docs.map((doc) => Exercise.fromFirestore(doc)).toList();

                // Filtrar por categoria
                if (_selectedCategory != null && _selectedCategory != 'Todos') {
                  allExercises = allExercises.where((ex) => ex.category == _selectedCategory).toList();
                }

                // Filtrar por pesquisa
                if (_searchQuery.isNotEmpty) {
                  allExercises = allExercises.where((ex) {
                    final queryLower = _searchQuery.toLowerCase();
                    return ex.name.toLowerCase().contains(queryLower) ||
                           ex.category.toLowerCase().contains(queryLower);
                  }).toList();
                }

                if (allExercises.isEmpty) {
                  return Center(child: Text('Nenhum exercício corresponde à sua busca/filtro.', style: TextStyle(color: AppColors.white)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: allExercises.length,
                  itemBuilder: (context, index) {
                    return ExerciseCard(exercise: allExercises[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}