import 'package:flutter/material.dart';
import 'package:gym_app/core/constants/app_colors.dart';

class ImageFullScreenModal extends StatelessWidget {
  final String imageUrl;
  final String heroTag; // Usaremos Hero Animation para uma transição suave

  const ImageFullScreenModal({super.key, required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fundo transparente para o desfoque
      body: Stack( // Usamos Stack para o botão de fechar ficar por cima
        children: [
          Center(
            child: Hero( // Hero animation para a transição
              tag: heroTag, // Deve ser único
              child: InteractiveViewer( // Permite zoom e pan na imagem
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain, // Garante que a imagem inteira seja visível
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        'Não foi possível carregar a imagem.',
                        style: TextStyle(color: AppColors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned( 
            top: 40, 
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: AppColors.white,
              iconSize: 30,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}