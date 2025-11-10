import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/presentation/exercise_list/exercise_list_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _currentStep = 0;
  String _name = '';
  String _height = '';
  String _weight = '';
  String _gender = '';
  String _customGender = '';
  bool _isLoading = false;

  final List<String> _genderOptions = [
    'Homem',
    'Mulher', 
    'Não Binário',
    'Outro',
    'Prefiro não dizer'
  ];

  Future<void> _saveProfile() async {
    if (_name.isEmpty || _height.isEmpty || _weight.isEmpty || _gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Prepara os dados para salvar
        final userData = {
          'name': _name,
          'height': int.tryParse(_height) ?? 0,
          'weight': double.tryParse(_weight.replaceAll(',', '.')) ?? 0.0,
          'gender': _gender == 'Outro' ? _customGender : _gender,
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Salva no Firestore
        await _firestore.collection('users').doc(user.uid).update(userData);

        // Navega para a tela principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ExerciseListScreen()),
        );
      }
    } catch (e) {
      print('Erro ao salvar perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0: // Nome
        return _name.isNotEmpty;
      case 1: // Altura e Peso
        return _height.isNotEmpty && _weight.isNotEmpty;
      case 2: // Gênero
        return _gender.isNotEmpty && (_gender != 'Outro' || _customGender.isNotEmpty);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: _currentStep > 0 
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          'Complete seu Perfil',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryAccent, // #00B4D8 para os steps
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: _previousStep,
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          controlsBuilder: (context, details) {
            // No último passo, mostra apenas o botão Voltar
            if (_currentStep == 2) {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white.withOpacity(0.4),
                          side: BorderSide(color: AppColors.white.withOpacity(0.4), width: 1.0),
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Voltar'),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white.withOpacity(0.4),
                          side: BorderSide(color: AppColors.white.withOpacity(0.4), width: 1.0),
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Voltar'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isStepValid(_currentStep) ? details.onStepContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isStepValid(_currentStep) 
                            ? AppColors.primaryAccent 
                            : AppColors.primaryAccent.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _isStepValid(_currentStep) 
                                ? AppColors.primaryAccent 
                                : AppColors.white.withOpacity(0.3), // Borda
                            width: 2,
                          ),
                        ),
                        elevation: 3,
                        shadowColor: AppColors.primaryAccent.withOpacity(0.5),
                      ),
                      child: Text(
                        'Continuar',
                        style: TextStyle(
                          color: _isStepValid(_currentStep) 
                              ? AppColors.white 
                              : AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            // PASSO 1: NOME
            Step(
              title: Text('Nome', style: TextStyle(color: AppColors.white)),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como você gostaria de ser chamado?',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (value) => setState(() => _name = value),
                    decoration: InputDecoration(
                      hintText: 'Digite seu nome',
                      hintStyle: TextStyle(color: AppColors.secondaryText),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: TextStyle(color: AppColors.primaryBackground),
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),

            // PASSO 2: ALTURA E PESO
            Step(
              title: Text('Medidas', style: TextStyle(color: AppColors.white)),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informe sua altura e peso para acompanhar seu progresso',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // ALTURA
                  Text(
                    'Altura (cm)',
                    style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => setState(() => _height = value),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 175',
                      hintStyle: TextStyle(color: AppColors.secondaryText),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: TextStyle(color: AppColors.primaryBackground),
                  ),
                  const SizedBox(height: 20),
                  // PESO
                  Text(
                    'Peso (kg)',
                    style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => setState(() => _weight = value),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Ex: 70.5',
                      hintStyle: TextStyle(color: AppColors.secondaryText),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: TextStyle(color: AppColors.primaryBackground),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),

            // PASSO 3: GÊNERO
            Step(
              title: Text('Gênero', style: TextStyle(color: AppColors.white)),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como você se identifica?',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  ..._genderOptions.map((gender) => RadioListTile<String>(
                    title: Text(gender, style: TextStyle(color: AppColors.white)),
                    value: gender,
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                    activeColor: AppColors.primaryAccent,
                    fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                       return AppColors.primaryAccent; // Selecionado - #00B4D8
                    }
                        return AppColors.white; // Não selecionado - Branco
                    }),
                  )).toList(),
                  
                  // CAMPO PERSONALIZADO PARA "OUTRO"
                  if (_gender == 'Outro') ...[
                    const SizedBox(height: 15),
                    TextField(
                      onChanged: (value) => setState(() => _customGender = value),
                      decoration: InputDecoration(
                        hintText: 'Especifique seu gênero',
                        hintStyle: TextStyle(color: AppColors.secondaryText),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: TextStyle(color: AppColors.primaryBackground),
                    ),
                  ],
                ],
              ),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
            ),
          ],
        ),
      ),

      // BOTÃO FINALIZAR NO ÚLTIMO PASSO
      bottomNavigationBar: _currentStep == 2 ? Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
            : ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Finalizar Cadastro',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ) : null,
    );
  }
}