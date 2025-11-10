import 'package:flutter/material.dart';
import 'package:gym_app/core/constants/app_colors.dart';

class TimePickerModal extends StatefulWidget {
  final String initialTime;

  const TimePickerModal({
    super.key,
    required this.initialTime,
  });

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  late int _selectedHour;
  late int _selectedMinute;

  // Listas para os dropdowns
  final List<int> _hours = List.generate(24, (index) => index);
  final List<int> _minutes = List.generate(60, (index) => index);

  @override
  void initState() {
    super.initState();
    
    // Parse do horário inicial (formato "HH:MM")
    final timeParts = widget.initialTime.split(':');
    _selectedHour = int.tryParse(timeParts[0]) ?? 7;
    _selectedMinute = int.tryParse(timeParts[1]) ?? 0;
  }

  String _getFormattedTime() {
    return '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              'Definir Horário do Treino',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Display do horário atual
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryAccent),
              ),
              child: Text(
                _getFormattedTime(),
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Seletores de Hora e Minuto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Dropdown de Hora
                Column(
                  children: [
                    Text(
                      'Hora',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _selectedHour,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.primaryBackground,
                        style: const TextStyle(color: AppColors.white, fontSize: 16),
                        items: _hours.map((int hour) {
                          return DropdownMenuItem<int>(
                            value: hour,
                            child: Text(
                              hour.toString().padLeft(2, '0'),
                              style: const TextStyle(color: AppColors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newHour) {
                          if (newHour != null) {
                            setState(() {
                              _selectedHour = newHour;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                // Separador
                Text(
                  ':',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Dropdown de Minuto
                Column(
                  children: [
                    Text(
                      'Minuto',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _selectedMinute,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.primaryBackground,
                        style: const TextStyle(color: AppColors.white, fontSize: 16),
                        items: _minutes.map((int minute) {
                          return DropdownMenuItem<int>(
                            value: minute,
                            child: Text(
                              minute.toString().padLeft(2, '0'),
                              style: const TextStyle(color: AppColors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newMinute) {
                          if (newMinute != null) {
                            setState(() {
                              _selectedMinute = newMinute;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cancela
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.placeholderGrey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_getFormattedTime()); // Retorna o horário
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirmar',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}