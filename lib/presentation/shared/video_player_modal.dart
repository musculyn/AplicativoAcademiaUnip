import 'package:flutter/material.dart';
import 'package:gym_app/core/constants/app_colors.dart';
import 'package:gym_app/data/models/exercise.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoFullScreenModal extends StatefulWidget {
  final Exercise exercise;

  const VideoFullScreenModal({super.key, required this.exercise});

  @override
  State<VideoFullScreenModal> createState() => _VideoFullScreenModalState();
}

class _VideoFullScreenModalState extends State<VideoFullScreenModal> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoadingVideo = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.exercise.videoUrl.isEmpty) {
      setState(() {
        _isLoadingVideo = false;
      });
      return;
    }
    // Verifica se a URL é válida
    try {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.exercise.videoUrl));
        await _videoPlayerController.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9, // Ajuste conforme a proporção do seu vídeo
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'Erro ao carregar o vídeo: $errorMessage',
                style: TextStyle(color: AppColors.white),
              ),
            );
          },
        );
    } catch (e) {
        print("Erro ao inicializar o player de vídeo: $e");
        _chewieController = null;
    }
    
    setState(() {
      _isLoadingVideo = false;
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Retorna um Scaffold para ocupar toda a área de visualização do diálogo
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparente para ver o desfoque aplicado pelo showGeneralDialog
      body: Center(
        child: Container(
          // Ocupa a tela inteira, mas com padding e margens para não ficar colado nas bordas
          width: MediaQuery.of(context).size.width * 0.9, 
          
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground, // Fundo do pop-up escuro
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    color: AppColors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Center(
                  child: Text(
                    widget.exercise.name,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                _isLoadingVideo
                    ? Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                    : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
                            child: Chewie(
                              controller: _chewieController!,
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.exercise.videoUrl.isEmpty ? 'Nenhum vídeo disponível.' : 'Erro ao carregar vídeo.',
                              style: TextStyle(color: AppColors.white),
                            ),
                          ),
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
                // Tutorial repetido abaixo do vídeo
                ...widget.exercise.tutorial.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '• $step',
                    style: TextStyle(color: AppColors.white.withOpacity(0.8)),
                  ),
                )).toList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}