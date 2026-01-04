import 'package:flutter/material.dart';
import '../services/yandex_ads_service.dart';

/// Виджет рекламного баннера Яндекс.Директ
class YandexBannerAd extends StatelessWidget {
  final String adUnitId;
  final double? height;

  const YandexBannerAd({
    super.key,
    required this.adUnitId,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return YandexAdsService().buildBannerAd(
      adUnitId: adUnitId,
      context: context,
      height: height ?? 50,
    );
  }
}

