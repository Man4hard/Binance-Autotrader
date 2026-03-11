import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/entities/candle.dart';
import '../../domain/usecases/calculate_indicators.dart';
import '../theme/app_theme.dart';

class PriceWithIndicatorChart extends StatelessWidget {
  final List<Candle> candles;
  final int ema1Period;
  final int ema2Period;
  final int ema3Period;
  final int bbPeriod;
  final double bbStdDev;

  const PriceWithIndicatorChart({
    super.key,
    required this.candles,
    this.ema1Period = 9,
    this.ema2Period = 21,
    this.ema3Period = 50,
    this.bbPeriod = 20,
    this.bbStdDev = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: kTextSecondary)),
      );
    }

    final closes = candles.map((c) => c.close).toList();
    final ema1 = calculateEma(closes, ema1Period);
    final ema2 = calculateEma(closes, ema2Period);
    final ema3 = calculateEma(closes, ema3Period);
    final bb = calculateBollingerBands(closes, bbPeriod, bbStdDev);

    final displayCount = candles.length > 60 ? 60 : candles.length;
    final startIdx = candles.length - displayCount;

    List<FlSpot> toSpots(List<double> values) {
      final spots = <FlSpot>[];
      for (int i = startIdx; i < candles.length; i++) {
        if (!values[i].isNaN) {
          spots.add(FlSpot((i - startIdx).toDouble(), values[i]));
        }
      }
      return spots;
    }

    final priceSpots = toSpots(closes);
    final ema1Spots = toSpots(ema1);
    final ema2Spots = toSpots(ema2);
    final ema3Spots = toSpots(ema3);
    final bbUpperSpots = toSpots(bb.upper);
    final bbLowerSpots = toSpots(bb.lower);
    final bbMidSpots = toSpots(bb.middle);

    double minY = double.infinity;
    double maxY = -double.infinity;
    for (int i = startIdx; i < candles.length; i++) {
      if (candles[i].low < minY) minY = candles[i].low;
      if (candles[i].high > maxY) maxY = candles[i].high;
    }
    final padding = (maxY - minY) * 0.05;
    minY -= padding;
    maxY += padding;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: (displayCount - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: kDividerColor,
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (_) => const FlLine(
            color: kDividerColor,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: kDividerColor),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(color: kTextSecondary, fontSize: 9),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: priceSpots,
            isCurved: false,
            color: kTextPrimary,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: ema1Spots,
            isCurved: true,
            color: kProfitColor,
            barWidth: 1,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: ema2Spots,
            isCurved: true,
            color: kWarningColor,
            barWidth: 1,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: ema3Spots,
            isCurved: true,
            color: kDangerColor,
            barWidth: 1,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: bbUpperSpots,
            isCurved: false,
            color: kBlueAccent.withValues(alpha: 0.5),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [4, 4],
          ),
          LineChartBarData(
            spots: bbLowerSpots,
            isCurved: false,
            color: kBlueAccent.withValues(alpha: 0.5),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [4, 4],
          ),
          LineChartBarData(
            spots: bbMidSpots,
            isCurved: false,
            color: kBlueAccent.withValues(alpha: 0.3),
            barWidth: 1,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

class RsiChart extends StatelessWidget {
  final List<Candle> candles;
  final int period;

  const RsiChart({super.key, required this.candles, this.period = 14});

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox.shrink();

    final closes = candles.map((c) => c.close).toList();
    final rsiValues = calculateRsi(closes, period);
    final displayCount = candles.length > 60 ? 60 : candles.length;
    final startIdx = candles.length - displayCount;

    final spots = <FlSpot>[];
    for (int i = startIdx; i < candles.length; i++) {
      if (!rsiValues[i].isNaN) {
        spots.add(FlSpot((i - startIdx).toDouble(), rsiValues[i]));
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) =>
              value == 30 || value == 50 || value == 70,
          getDrawingHorizontalLine: (value) => FlLine(
            color: value == 50
                ? kTextSecondary.withValues(alpha: 0.3)
                : value == 70
                    ? kDangerColor.withValues(alpha: 0.4)
                    : kProfitColor.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => const FlLine(
            color: kDividerColor,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: kDividerColor),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 20,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: kTextSecondary, fontSize: 9),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: kAccentColor,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

class MacdChart extends StatelessWidget {
  final List<Candle> candles;

  const MacdChart({super.key, required this.candles});

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox.shrink();

    final closes = candles.map((c) => c.close).toList();
    final macdResult = calculateMacd(closes);
    final displayCount = candles.length > 60 ? 60 : candles.length;
    final startIdx = candles.length - displayCount;

    final barGroups = <BarChartGroupData>[];
    for (int i = startIdx; i < candles.length; i++) {
      final histo = macdResult.histogram[i];
      if (!histo.isNaN) {
        barGroups.add(
          BarChartGroupData(
            x: i - startIdx,
            barRods: [
              BarChartRodData(
                toY: histo,
                color: histo >= 0 ? kProfitColor : kDangerColor,
                width: 4,
                borderRadius: BorderRadius.circular(1),
              ),
            ],
          ),
        );
      }
    }

    if (barGroups.isEmpty) return const SizedBox.shrink();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) => value == 0,
          getDrawingHorizontalLine: (_) => FlLine(
            color: kTextSecondary.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => const FlLine(
            color: kDividerColor,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: kDividerColor),
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }
}
