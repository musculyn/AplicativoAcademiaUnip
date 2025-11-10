import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

@override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _gender = '';
  String _customGender = '';
  bool _isLoading = true;
  bool _isSaving = false;
  final List<String> _genderOptions = [
    'Homem',
    'Mulher', 
    'Não Binário',
    'Outro',
    'Prefiro não dizer'
  ];

@override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _heightController.text = data['height']?.toString() ?? '';
            _weightController.text = data['weight']?.toString() ?? '';
            
            final savedGender = data['gender'] ?? '';
            // Verifica se o gênero salvo é uma das opções 
            if (_genderOptions.contains(savedGender)) {
              _gender = savedGender;
            } else {
              _gender = 'Outro';
              _customGender = savedGender;
            }
          });
        }
      } catch (e) {
        // print('Erro ao carregar dados do usuário: $e'); // LINHA REMOVIDA
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || 
        _heightController.text.isEmpty || 
        _weightController.text.isEmpty || 
        _gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Prepara os dados para salvar
        final userData = {
          'name': _nameController.text.trim(),
          'height': int.tryParse(_heightController.text) ??
          0,
          'weight': double.tryParse(_weightController.text.replaceAll(',', '.')) ??
          0.0,
          'gender': _gender == 'Outro' ?
          _customGender : _gender,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        // Salva no Firestore
        await _firestore.collection('users').doc(user.uid).update(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Volta para a tela de perfil
        Navigator.pop(context);
      }
    } catch (e) {
      // print('Erro ao salvar perfil: $e'); // LINHA REMOVIDA
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
  
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
     
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
        ],
      ),
     
      body: _isLoading
          ?
          Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // NOME
                  _buildTextFieldSection(
  
                    'Nome',
                    'Como você gostaria de ser chamado?',
                    _nameController,
                  ),
                  
 
                  const SizedBox(height: 25),
                  
                  // ALTURA
                  _buildTextFieldSection(
                    'Altura (cm)',
     
                    'Sua altura em centímetros',
                    _heightController,
                    keyboardType: TextInputType.number,
                  ),
                  
     
                  const SizedBox(height: 25),
                  
                  // PESO
                  _buildTextFieldSection(
                    'Peso (kg)',
         
                    'Seu peso em quilogramas',
                    _weightController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  
        
                  const SizedBox(height: 25),
                  
                  // GÊNERO
                  _buildGenderSection(),
                  
               
                  const SizedBox(height: 40),
                  
                  // BOTÃO SALVAR
                  _buildSaveButton(),
                  
                  const SizedBox(height: 20),
 
                ],
              ),
            ),
    );
  }

  Widget _buildTextFieldSection(
    String title, 
    String subtitle, 
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.white,
        
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.secondaryText,
            
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: title,
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
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gênero',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
         
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Como você se identifica?',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
        ),
     
        const SizedBox(height: 15),
        
        // OPÇÕES DE GÊNERO
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
              return AppColors.primaryAccent;
            }
            return AppColors.white;
          }),
        )).toList(),
        
        // CAMPO PERSONALIZADO PARA "OUTRO"
        if (_gender == 'Outro') ...[
          const SizedBox(height: 15),
          TextField(
            controller: TextEditingController(text: _customGender),
          
            onChanged: (value) => setState(() => _customGender = value),
            decoration: InputDecoration(
              hintText: 'Especifique seu gênero',
              hintStyle: TextStyle(color: AppColors.secondaryText),
              filled: true,
              fillColor: AppColors.white,
              border: 
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: TextStyle(color: AppColors.primaryBackground),
       
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
       
            ),
          elevation: 2,
        ),
        child: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
     
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                'Salvar Alterações',
       
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
   
          ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}