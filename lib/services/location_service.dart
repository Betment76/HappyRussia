import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Сервис для работы с геолокацией
class LocationService {
  /// Проверить разрешения на геолокацию
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Получить текущую позицию
  Future<Position> getCurrentPosition() async {
    bool hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('Нет разрешения на геолокацию');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  /// Получить регион по координатам
  Future<String?> getRegionFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        // В России административный район обычно в administrativeArea
        return placemarks.first.administrativeArea;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить регион пользователя
  Future<String?> getUserRegion() async {
    try {
      final position = await getCurrentPosition();
      return await getRegionFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      return null;
    }
  }
}

