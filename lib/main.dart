import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gym_app/core/constants/firebase_options.dart';
import 'package:gym_app/presentation/exercise_list/exercise_list_screen.dart';
import 'package:gym_app/presentation/profile/profile_screen.dart';
import 'package:gym_app/presentation/routines/routines_screen.dart';
import 'package:gym_app/presentation/splash_screen.dart';
import 'package:gym_app/presentation/workouts/workouts_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Treino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
        '/workouts': (context) => const WorkoutsScreen(),
      
        '/exercises': (context) => const ExerciseListScreen(),
        
        '/routines': (context) => const RoutinesScreen(),

        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}