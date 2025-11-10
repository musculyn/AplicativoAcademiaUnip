import 'package:flutter/material.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/data/models/exercise.dart';
import 'package:gym_app/presentation/shared/image_full_screen_modal.dart';
import 'dart:ui';
import 'package:gym_app/presentation/shared/video_player_modal.dart';

class ExerciseSelectionCard extends StatefulWidget {
  final Exercise exercise;
  final bool isSelected;
  final bool isAlreadyInWorkout;
  final VoidCallback onSelect;

  const ExerciseSelectionCard({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.isAlreadyInWorkout,
    required this.onSelect,
  });

  @override
  State<ExerciseSelectionCard> createState() => _ExerciseSelectionCardState();
}

class _ExerciseSelectionCardState extends State<ExerciseSelectionCard> {
  bool _isExpanded = false;

  void _showVideoModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      barrierLabel: 'Video Modal',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: VideoFullScreenModal(exercise: widget.exercise),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: child,
        );
      },
    );
  }

  void _showImageModal(BuildContext context) {
    final String heroTag = 'exercise_image_${widget.exercise.id}';

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      barrierLabel: 'Image Modal',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ImageFullScreenModal(
            imageUrl: widget.exercise.imageUrl,
            heroTag: heroTag,
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String heroTag = 'exercise_image_${widget.exercise.id}';

    return Card(
      color: widget.isAlreadyInWorkout 
          ? AppColors.primaryBackground.withOpacity(0.5)
          : (widget.isSelected ? AppColors.primaryAccent.withOpacity(0.2) : AppColors.primaryBackground),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: widget.isAlreadyInWorkout 
              ? Colors.green
              : (widget.isSelected ? AppColors.primaryAccent : Colors.transparent),
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.name,
                        style: TextStyle(
                          color: widget.isAlreadyInWorkout ? AppColors.secondaryText : AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.exercise.category,
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (!widget.isAlreadyInWorkout)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onSelect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isSelected 
                                  ? AppColors.successGreen 
                                  : AppColors.primaryAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              widget.isSelected ? 'Selecionado ✓' : 'Selecionar Treino',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      
                      if (widget.isAlreadyInWorkout)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 10),
                              Text(
                                'JÁ ADICIONADO AO TREINO',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showImageModal(context),
                      child: Hero(
                        tag: heroTag,
                        child: Container(
                          width: 105,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(widget.exercise.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _isExpanded ? '' : 'Mais',
                          style: TextStyle(color: AppColors.primaryAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 20),
              Text(
                'Como Fazer:',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.exercise.tutorial.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '• $step',
                  style: TextStyle(color: AppColors.white.withOpacity(0.8)),
                ),
              )).toList(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _showVideoModal(context); 
                    },
                    icon: const Icon(Icons.play_arrow, color: AppColors.white),
                    label: Text(
                      'Assista como fazer',
                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = false;
                      });
                    },
                    child: Text(
                      'Menos',
                      style: TextStyle(color: AppColors.primaryAccent),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}