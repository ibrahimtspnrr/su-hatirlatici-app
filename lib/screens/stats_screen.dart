// lib/screens/stats_screen.dart (Soft mavi uyum + eksik tipler eklendi)

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/water_record_service.dart';
import '../services/preference_service.dart';
import '../models/water_record.dart';

// İstatistik Özeti Modeli
class StatsSummary {
  final int totalIntake;
  final int daysCount;
  final int goalReachedDays;
  final int averageIntake;

  StatsSummary({
    required this.totalIntake,
    required this.daysCount,
    required this.goalReachedDays,
    required this.averageIntake,
  });
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedPeriod = 0; // 0: Son 7, 1: Son 30, 2: Tüm zaman
  int _dailyGoal = 2000;

  @override
  void initState() {
    super.initState();
  }

  List<WaterRecord> _loadAndFilterRecords(int selectedPeriod) {
    _dailyGoal = preferenceService.getDailyGoal();

    DateTime now = DateTime.now();
    DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    DateTime startDate;
    if (selectedPeriod == 0) {
      startDate = dateOnly(now.subtract(const Duration(days: 7)));
    } else if (selectedPeriod == 1) {
      startDate = dateOnly(now.subtract(const Duration(days: 30)));
    } else {
      startDate = dateOnly(DateTime(2023));
    }

    return waterRecordService.getRecordsInPeriod(startDate, dateOnly(now));
  }

  StatsSummary? _calculateSummary(List<WaterRecord> records, int dailyGoal) {
    if (records.isEmpty) return null;

    int totalIntake = 0;
    int goalReachedDays = 0;
    int daysWithIntake = 0;

    for (var record in records) {
      if (record.amountInMl > 0) {
        totalIntake += record.amountInMl;
        daysWithIntake++;
        if (record.amountInMl >= dailyGoal) {
          goalReachedDays++;
        }
      }
    }

    final int totalDaysInPeriod = records.length;
    if (totalDaysInPeriod == 0) return null;

    return StatsSummary(
      totalIntake: totalIntake,
      daysCount: totalDaysInPeriod,
      goalReachedDays: goalReachedDays,
      averageIntake: daysWithIntake > 0 ? (totalIntake / daysWithIntake).round() : 0,
    );
  }

  void _onPeriodChanged(int? newPeriod) {
    if (newPeriod != null) {
      setState(() {
        _selectedPeriod = newPeriod;
      });
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<WaterRecord> records, int dailyGoal) {
    if (records.isEmpty) {
      return const Center(child: Text('Göstermek için yeterli veri yok.'));
    }

    final String chartTitle = _selectedPeriod == 0
        ? 'Haftalık Tüketim Trendi'
        : (_selectedPeriod == 1 ? 'Aylık Tüketim Trendi' : 'Tüm Zamanlar Tüketimi');

    final List<WaterRecord> sortedRecords = List.from(records.reversed);
    final int totalDays = sortedRecords.length;

    final double maxIntake = sortedRecords.map((r) => r.amountInMl.toDouble()).fold(0.0, (a, b) => a > b ? a : b);
    final double maxY = (maxIntake > dailyGoal ? maxIntake : dailyGoal) * 1.2;

    final double barWidth = totalDays <= 7 ? 16 : 6;
    final int intervalX = totalDays <= 7 ? 1 : (totalDays / 5).ceil().clamp(1, totalDays);

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    List<BarChartGroupData> barGroups = sortedRecords.asMap().entries.map((entry) {
      final int x = entry.key;
      final WaterRecord record = entry.value;
      final double barY = record.amountInMl.toDouble();

      return BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: barY,
            color: record.amountInMl >= dailyGoal ? Colors.green.shade400 : primaryColor,
            width: barWidth,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chartTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();
                          if (index % intervalX == 0 && index >= 0 && index < totalDays) {
                            final date = sortedRecords[index].date;

                            String label;
                            if (totalDays <= 7) {
                              final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                              label = dayNames[(date.weekday - 1) % 7];
                            } else {
                              label = '${date.day}/${date.month}';
                            }

                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(label, style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value.toInt() == dailyGoal || value.toInt() == maxY.toInt()) {
                            return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: dailyGoal.toDouble(),
                        color: Colors.orange.shade600,
                        strokeWidth: 1.5,
                        dashArray: [10, 10],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(fontSize: 10, color: Colors.orange),
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          labelResolver: (line) => 'Hedef',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int dailyGoal = preferenceService.getDailyGoal();
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'İstatistikler',
          style: TextStyle(
            color: Colors.white, // yazı beyaz
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary, // 🔹 tema rengi
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
      ),
      body: Column(
        children: [
          // Periyot Seçici
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton(0, 'Son 7 Gün'),
                _buildPeriodButton(1, 'Son 30 Gün'),
                _buildPeriodButton(2, 'Tüm Zamanlar'),
              ],
            ),
          ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: waterRecordService.waterBox,
              builder: (context, box, widget) {
                final List<WaterRecord> records = _loadAndFilterRecords(_selectedPeriod);
                final StatsSummary? summary = _calculateSummary(records, dailyGoal);

                if (summary == null) {
                  return const Center(child: Text('Seçilen dönem için su kaydı bulunamadı.'));
                }

                final int successRate = ((summary.goalReachedDays / summary.daysCount) * 100).round();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildBarChart(records, dailyGoal),

                    // Günlük Hedef Bilgisi Kartı
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Mevcut Günlük Hedefiniz: ${dailyGoal} ml',
                          style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Özet Kartlar Gridi
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _buildStatCard('Toplam Tüketim', '${summary.totalIntake} ml', Icons.water_drop, primaryColor),
                        _buildStatCard('Günlük Ortalama', '${summary.averageIntake} ml', Icons.trending_up, Colors.green),
                        _buildStatCard('Hedefe Ulaşılan Gün', '${summary.goalReachedDays} / ${summary.daysCount} Gün', Icons.check_circle_outline, Colors.orange),
                        _buildStatCard('Başarı Yüzdesi', '$successRate%', Icons.percent, primaryColor),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text('Detaylı Tüketim Geçmişi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Detaylı Kayıt Listesi
                    ...records.map((record) {
                      if (record.amountInMl > 0) {
                        final formattedDate = '${record.date.day.toString().padLeft(2, '0')}.${record.date.month.toString().padLeft(2, '0')}.${record.date.year}';
                        final bool goalReached = record.amountInMl >= dailyGoal;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: Icon(
                              goalReached ? Icons.star : Icons.water_drop,
                              size: 24,
                              color: goalReached ? Colors.amber : primaryColor,
                            ),
                            title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: Text(
                              '${record.amountInMl} ml',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: goalReached ? Colors.green : primaryColor,
                              ),
                            ),
                            tileColor: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Periyot Butonu
  Widget _buildPeriodButton(int index, String label) {
    final bool isSelected = _selectedPeriod == index;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => _onPeriodChanged(index),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? primaryColor : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: isSelected ? 4 : 1,
          ),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
