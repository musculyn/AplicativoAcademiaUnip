import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id;
  final String name;
  final String category;
  final String equipment; 
  final String imageUrl;
  final String videoUrl;
  final List<String> tutorial; // passoAPasso
  final String primaryMuscle; // Músculo Principal
  final String secondaryMuscles; // Músculos Secundários
  final String hypertrophyReps; 
  final String strengthReps; 

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.equipment = '', 
    required this.imageUrl,
    required this.videoUrl,
    required this.tutorial,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.hypertrophyReps,
    required this.strengthReps,
  });

  // Mapeamento do Firestore. Os nomes das chaves devem ser EXATAMENTE IGUAIS aos do seu DB.
  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? 'Nome do Exercício',
      category: data['category'] ?? 'Geral',
      equipment: data['equipment'] ?? '',
      imageUrl: data['image'] ?? 'https://via.placeholder.com/150', // CHAVE: 'image'
      videoUrl: data['video'] ?? '', // CHAVE: 'video'
      tutorial: List<String>.from(data['tutorial'] ?? []), // CHAVE: 'tutorial'
      primaryMuscle: data['primaryMuscle'] ?? 'Não especificado', // CHAVE: 'primaryMuscle'
      secondaryMuscles: data['secondaryMuscles'] ?? 'Não especificado', // CHAVE: 'secondaryMuscles'
      hypertrophyReps: data['hypertrophyReps'] ?? 'N/A', 
      strengthReps: data['strengthReps'] ?? 'N/A', 
    );
  }
}