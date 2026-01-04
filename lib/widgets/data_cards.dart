import 'package:flutter/material.dart';
import '../models/region_data.dart';
import '../models/federal_district_data.dart';
import '../models/settlement.dart';
import '../models/urban_district.dart';
import '../screens/cities_screen.dart';
import '../screens/district_regions_screen.dart';
import '../screens/region_detail_screen.dart';
import '../screens/district_settlements_screen.dart';
import '../screens/city_detail_screen.dart';
import '../models/city_mood.dart';

/// Виджеты карточек с актуальными данными из базы

/// Карточка федерального округа с актуальными данными
class FederalDistrictDataCard extends StatelessWidget {
  final FederalDistrictData district;
  final bool isClickable;

  const FederalDistrictDataCard({
    super.key,
    required this.district,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regionsCount = district.regions.length;
    final settlementsCount = district.regions.fold<int>(
      0,
      (sum, region) => sum + region.totalSettlementsCount,
    );

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Иконка округа
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF0039A6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.map,
                  color: Color(0xFF0039A6),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              // Название округа
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      district.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0039A6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${regionsCount} регионов • ${settlementsCount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} населенных пунктов',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Население
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Население: ${district.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: isClickable
          ? InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DistrictRegionsScreen(districtData: district),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: cardContent,
            )
          : cardContent,
    );
  }
}

/// Карточка региона с актуальными данными
class RegionDataCard extends StatelessWidget {
  final RegionData region;
  final bool isClickable;

  const RegionDataCard({
    super.key,
    required this.region,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final citiesCount = region.cities.length;
    final districtsCount = region.filteredDistricts.length;
    final settlementsCount = region.totalSettlementsCount;

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ID региона
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF0039A6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    region.id,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0039A6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Название региона
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0039A6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$citiesCount городов • $districtsCount районов • $settlementsCount населенных пунктов',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Население
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Население: ${region.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: isClickable
          ? InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegionDetailScreen(regionId: region.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: cardContent,
            )
          : cardContent,
    );
  }
}

/// Карточка населенного пункта с актуальными данными
class SettlementCard extends StatelessWidget {
  final Settlement settlement;
  final String? regionName;
  final bool isClickable;

  const SettlementCard({
    super.key,
    required this.settlement,
    this.regionName,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Иконка типа населенного пункта
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getTypeColor(settlement.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(settlement.type),
              color: _getTypeColor(settlement.type),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Название и информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settlement.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (regionName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    regionName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      settlement.type,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (settlement.population > 0) ...[
                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                      const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        '${settlement.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: isClickable
          ? InkWell(
              onTap: () {
                // TODO: Переход на детальную страницу населенного пункта
              },
              borderRadius: BorderRadius.circular(12),
              child: cardContent,
            )
          : cardContent,
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'город':
        return const Color(0xFF0039A6);
      case 'поселок':
      case 'посёлок':
      case 'пгт':
      case 'рабочий поселок':
        return Colors.orange;
      case 'село':
        return Colors.green;
      case 'деревня':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'город':
        return Icons.location_city;
      case 'поселок':
      case 'посёлок':
      case 'пгт':
      case 'рабочий поселок':
        return Icons.home_work;
      case 'село':
        return Icons.home;
      case 'деревня':
        return Icons.cottage;
      default:
        return Icons.place;
    }
  }
}

/// Карточка района с актуальными данными
class UrbanDistrictCard extends StatelessWidget {
  final UrbanDistrict district;
  final String? regionName;
  final bool isClickable;

  const UrbanDistrictCard({
    super.key,
    required this.district,
    this.regionName,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final citiesCount = district.cities.length;
    final settlementsCount = district.settlements.length;

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Иконка района
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Название района
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      district.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (regionName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        regionName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '$settlementsCount населенных пунктов${citiesCount > 0 ? ' • $citiesCount городов' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (district.population > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Население: ${district.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: isClickable
          ? InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DistrictSettlementsScreen(
                      district: district,
                      regionName: regionName ?? '',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: cardContent,
            )
          : cardContent,
    );
  }
}

