import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/mood_provider.dart';
import '../models/mood_level.dart';
import '../models/check_in.dart';
import '../services/location_service.dart';
import '../data/russian_regions.dart';

/// Экран для ежедневного чек-ина настроения
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with SingleTickerProviderStateMixin {
  MoodLevel? _selectedMood;
  String? _selectedRegionId;
  String? _selectedRegionName;
  bool _isLoading = false;
  bool _isSubmitting = false;
  final LocationService _locationService = LocationService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _detectRegion();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Определить регион автоматически
  Future<void> _detectRegion() async {
    setState(() => _isLoading = true);

    try {
      final regionName = await _locationService.getUserRegion();
      if (regionName != null) {
        final region = RussianRegions.findByName(regionName);
        if (region != null) {
          setState(() {
            _selectedRegionId = region['id'];
            _selectedRegionName = region['name'];
          });
        }
      }
    } catch (e) {
      // Игнорируем ошибки геолокации
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Отправить чек-ин
  Future<void> _submitCheckIn() async {
    if (_selectedMood == null) {
      _showError('Выберите ваше настроение');
      return;
    }

    if (_selectedRegionId == null) {
      _showError('Выберите регион');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final checkIn = CheckIn(
        id: const Uuid().v4(),
        regionId: _selectedRegionId!,
        regionName: _selectedRegionName!,
        mood: _selectedMood!,
        date: DateTime.now(),
      );

      await context.read<MoodProvider>().submitCheckIn(checkIn);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Чек-ин успешно отправлен!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка отправки: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Как ваше настроение?'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Text(
              'Выберите ваше настроение:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Смайлики
            _buildMoodSelector(theme),

            const SizedBox(height: 20),

            // Выбор региона
            Text(
              'Выберите регион:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildRegionSelector(theme),

            const SizedBox(height: 20),

            // Кнопка отправки
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCheckIn,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Отправить',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет выбора настроения
  Widget _buildMoodSelector(ThemeData theme) {
    return Column(
      children: MoodLevel.values.map((mood) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildMoodButton(mood, theme),
        );
      }).toList(),
    );
  }

  Widget _buildMoodButton(MoodLevel mood, ThemeData theme) {
    final isSelected = _selectedMood == mood;
    final color = _getMoodColor(mood);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
        _animationController.forward(from: 0.0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                mood.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryHappy:
        return Colors.green;
      case MoodLevel.happy:
        return Colors.lightGreen;
      case MoodLevel.neutral:
        return Colors.lightBlue;
      case MoodLevel.sad:
        return Colors.orange;
      case MoodLevel.verySad:
        return Colors.red;
    }
  }

  /// Виджет выбора региона
  Widget _buildRegionSelector(ThemeData theme) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRegionId,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelText: 'Регион',
          prefixIcon: const Icon(Icons.location_on),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
        items: RussianRegions.getAll().map((region) {
          return DropdownMenuItem<String>(
            value: region['id'],
            child: Text(
              region['name']!,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            final region = RussianRegions.getAll().firstWhere(
              (r) => r['id'] == value,
            );
            setState(() {
              _selectedRegionId = value;
              _selectedRegionName = region['name'];
            });
          }
        },
      ),
    );
  }
}
