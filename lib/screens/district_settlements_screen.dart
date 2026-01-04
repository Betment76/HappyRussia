import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/urban_district.dart';
import '../models/settlement.dart';
import '../providers/mood_provider.dart';
import '../widgets/data_cards.dart';

/// Экран с населенными пунктами района региона
class DistrictSettlementsScreen extends StatefulWidget {
  final UrbanDistrict district;
  final String regionName;

  const DistrictSettlementsScreen({
    super.key,
    required this.district,
    required this.regionName,
  });

  @override
  State<DistrictSettlementsScreen> createState() => _DistrictSettlementsScreenState();
}

class _DistrictSettlementsScreenState extends State<DistrictSettlementsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cities = widget.district.cities;
    final otherSettlements = widget.district.otherSettlements;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.district.name),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Обновление данных при необходимости
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            // Заголовок с информацией о районе
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      const Color(0xFF0039A6),
                      const Color(0xFFD52B1E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                child: Column(
                  children: [
                    Text(
                      widget.district.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${cities.length} городов • ${otherSettlements.length} других населенных пунктов',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    if (widget.district.population > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Население: ${widget.district.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Секция "Города"
            if (cities.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Города района',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0039A6),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return SettlementCard(
                      settlement: cities[index],
                      regionName: widget.regionName,
                      isClickable: true,
                    );
                  },
                  childCount: cities.length,
                ),
              ),
            ],
            
            // Секция "Другие населенные пункты"
            if (otherSettlements.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Другие населенные пункты',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0039A6),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return SettlementCard(
                      settlement: otherSettlements[index],
                      regionName: widget.regionName,
                      isClickable: true,
                    );
                  },
                  childCount: otherSettlements.length,
                ),
              ),
            ],
            
            // Если нет данных
            if (widget.district.settlements.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет данных о населенных пунктах',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

