import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Сервис для работы с Яндекс рекламой
class YandexAdsService {
  static final YandexAdsService _instance = YandexAdsService._internal();
  factory YandexAdsService() => _instance;
  YandexAdsService._internal();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  String? _currentAdUnitId;

  /// Инициализация Яндекс Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.initialize();
      _isInitialized = true;
      if (kDebugMode) {
        print('Яндекс Mobile Ads SDK инициализирован');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации Яндекс Mobile Ads SDK: $e');
      }
      _isInitialized = false;
    }
  }

  /// Создание адаптивного sticky-баннера согласно официальной документации
  /// https://ads.yandex.com/helpcenter/ru/dev/flutter/adaptive-sticky-banner
  Widget buildBannerAd({
    required String adUnitId,
    required BuildContext context,
    double? height,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('SDK не инициализирован, возвращаем пустой контейнер');
      }
      return Container(
        height: height,
        margin: margin,
      );
    }

    // Создаем баннер если еще не создан или изменился adUnitId
    if (_bannerAd == null || _currentAdUnitId != adUnitId) {
      _bannerAd?.destroy();
      
      // Получаем ширину экрана для адаптивного размера
      final screenWidth = MediaQuery.of(context).size.width.round();
      final adSize = BannerAdSize.sticky(width: screenWidth);
      
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        adSize: adSize,
        adRequest: const AdRequest(),
        onAdLoaded: () {
          if (kDebugMode) {
            print('Баннер Яндекс рекламы успешно загружен');
          }
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('Ошибка загрузки баннера Яндекс рекламы: $error');
          }
        },
        onAdClicked: () {
          if (kDebugMode) {
            print('Клик по баннеру Яндекс рекламы');
          }
        },
      );
      
      _currentAdUnitId = adUnitId;
      _bannerAd!.loadAd(adRequest: const AdRequest());
    }

    return Container(
      height: height,
      margin: margin,
      child: AdWidget(bannerAd: _bannerAd!),
    );
  }

  /// Освобождение ресурсов рекламы
  void dispose() {
    _bannerAd?.destroy();
    _bannerAd = null;
    _currentAdUnitId = null;
  }
}

