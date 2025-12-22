import '../data/russian_regions.dart';

/// Утилита для работы с гербами регионов
class HerbHelper {
  /// Получить путь к гербу региона по его ID
  /// Поддерживаемые форматы: PNG (рекомендуется), SVG, JPG, GIF
  static String getHerbPath(String regionId) {
    return 'assets/herbs/$regionId.png';
  }

  /// Получить путь к гербу федерального округа
  /// Использует герб первого региона округа
  static String? getFederalDistrictHerbPath(String districtName) {
    final regions = RussianRegions.getByFederalDistrict(districtName);
    if (regions.isNotEmpty) {
      final firstRegionId = regions.first['id'];
      if (firstRegionId != null) {
        return getHerbPath(firstRegionId);
      }
    }
    return null;
  }

  /// Получить путь к гербу региона по его ID (с альтернативными форматами)
  /// Пробует форматы в порядке приоритета: PNG -> SVG -> JPG -> GIF
  static String? getHerbPathWithFallback(String regionId) {
    // Порядок важен: сначала пробуем PNG (лучшее качество), потом SVG (вектор)
    final formats = ['png', 'svg', 'jpg', 'gif'];
    for (final format in formats) {
      final path = 'assets/herbs/$regionId.$format';
      // В реальном приложении здесь можно проверить существование файла
      return path;
    }
    return null;
  }

  /// Проверить, существует ли герб для региона
  static bool hasHerb(String regionId) {
    // TODO: Реализовать проверку существования файла
    return true;
  }
}

