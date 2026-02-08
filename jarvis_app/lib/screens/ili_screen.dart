import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/ili_provider.dart';
import '../providers/settings_provider.dart';
import '../models/ili_models.dart';
import '../models/ili_prediction_models.dart';
import '../theme/app_theme.dart';

class IliScreen extends StatefulWidget {
  const IliScreen({super.key});

  @override
  State<IliScreen> createState() => _IliScreenState();
}

class _IliScreenState extends State<IliScreen> {
  int _tabIndex = 0;
  final _tabs = const ['Overview', 'Alignment', 'Matches', 'Growth', 'Predictions'];

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textFg = isDark ? AppTheme.figmaForeground : AppTheme.textDark;
    final mutedFg = isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary;

    return Consumer<IliProvider>(
      builder: (context, ili, _) {
        return CupertinoPageScaffold(
          backgroundColor: Colors.transparent,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: CupertinoColors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ILI Data Alignment',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: textFg,
                              ),
                            ),
                            Text(
                              'Pipeline Inspection & Corrosion Growth',
                              style: TextStyle(fontSize: 13, color: mutedFg),
                            ),
                          ],
                        ),
                      ),
                      if (ili.status != IliStatus.loading)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            final settings = Provider.of<SettingsProvider>(context, listen: false);
                            ili.runFullPipeline(
                              apiKey: settings.apiKey,
                              model: settings.model,
                              baseUrl: settings.featherlessBaseUrl,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: AppTheme.buttonDecoration(isDark),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.play_fill, size: 14, color: CupertinoColors.white),
                                const SizedBox(width: 6),
                                Text(
                                  ili.isLoaded ? 'Re-run' : 'Run Analysis',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0),

                const SizedBox(height: 16),

                // Tab bar
                if (ili.isLoaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        final active = _tabIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onPressed: () => setState(() => _tabIndex = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppTheme.figmaAccent.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: active
                                    ? Border.all(color: AppTheme.figmaAccent.withOpacity(0.4))
                                    : null,
                              ),
                              child: Text(
                                _tabs[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                  color: active ? AppTheme.figmaAccent : mutedFg,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                const SizedBox(height: 8),

                // Content
                Expanded(
                  child: _buildContent(ili, isDark, textFg, mutedFg),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(IliProvider ili, bool isDark, Color textFg, Color mutedFg) {
    if (ili.status == IliStatus.loading) {
      return _buildLoadingState(isDark, mutedFg);
    }

    if (ili.status == IliStatus.error) {
      return _buildErrorState(ili, isDark, textFg, mutedFg);
    }

    if (!ili.isLoaded) {
      return _buildEmptyState(ili, isDark, textFg, mutedFg);
    }

    switch (_tabIndex) {
      case 0:
        return _buildOverview(ili, isDark, textFg, mutedFg);
      case 1:
        return _buildAlignment(ili, isDark, textFg, mutedFg);
      case 2:
        return _buildMatches(ili, isDark, textFg, mutedFg);
      case 3:
        return _buildGrowth(ili, isDark, textFg, mutedFg);
      case 4:
        return _buildPredictions(ili, isDark, textFg, mutedFg);
      default:
        return const SizedBox();
    }
  }

  // ---------- Empty / Loading / Error States ----------

  Widget _buildEmptyState(IliProvider ili, bool isDark, Color textFg, Color mutedFg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: mutedFg.withOpacity(0.3))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.95, end: 1.05, duration: 2000.ms),
          const SizedBox(height: 16),
          Text(
            'ILI Pipeline Analysis',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textFg),
          ),
          const SizedBox(height: 8),
          Text(
            'Run the analysis to align inspection data across\n2007, 2015, and 2022 runs and detect corrosion growth.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: mutedFg),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: () => ili.runFullPipeline(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: AppTheme.buttonDecoration(isDark),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.play_fill, size: 16, color: CupertinoColors.white),
                  SizedBox(width: 8),
                  Text(
                    'Run Full Analysis',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildLoadingState(bool isDark, Color mutedFg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 18),
          const SizedBox(height: 16),
          Text(
            'Running ILI alignment pipeline...',
            style: TextStyle(fontSize: 15, color: mutedFg),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading data, aligning welds, matching anomalies,\ncalculating growth rates',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: mutedFg.withOpacity(0.6)),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildErrorState(IliProvider ili, bool isDark, Color textFg, Color mutedFg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: AppTheme.warning),
          const SizedBox(height: 16),
          Text('Analysis Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textFg)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              ili.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: mutedFg),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ili.error != null && ili.error!.contains('TimeoutException')
                ? 'The analysis is taking longer than expected.\nRetry or run the API with a smaller dataset.'
                : 'Make sure the ILI API is running:\nuvicorn ili_api:app --port 8001',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: mutedFg.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          CupertinoButton(
            onPressed: () => ili.runFullPipeline(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: AppTheme.buttonDecoration(isDark, isPrimary: false),
              child: Text('Retry', style: TextStyle(color: textFg, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Overview Tab ----------

  Widget _buildOverview(IliProvider ili, bool isDark, Color textFg, Color mutedFg) {
    final load = ili.loadResult!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pipeline summary cards
          Row(
            children: [
              _statCard('Pipeline Length', '${(load.pipelineLengthFt / 5280).toStringAsFixed(1)} mi', Icons.straighten, isDark, textFg, mutedFg, delay: 0),
              const SizedBox(width: 12),
              _statCard('ILI Runs', '${load.runs.length}', Icons.repeat, isDark, textFg, mutedFg, delay: 50),
              const SizedBox(width: 12),
              _statCard('Total Features', '${load.runs.values.fold<int>(0, (sum, r) => sum + r.totalFeatures)}', Icons.scatter_plot, isDark, textFg, mutedFg, delay: 100),
            ],
          ),
          const SizedBox(height: 16),

          // Per-run cards
          ...load.runs.entries.map((entry) {
            final r = entry.value;
            final delay = (entry.key - 2007) * 30;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(isDark),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${r.year}',
                        style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _miniStat('Features', '${r.totalFeatures}', textFg, mutedFg),
                          _miniStat('Anomalies', '${r.anomalies}', textFg, mutedFg),
                          _miniStat('Metal Loss', '${r.metalLoss}', textFg, mutedFg),
                          _miniStat('Girth Welds', '${r.girthWelds}', textFg, mutedFg),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
                  .slideX(begin: 0.03, end: 0),
            );
          }),

          const SizedBox(height: 16),

          // Risk Assessment (AI-powered)
          if (ili.riskAssessment != null) ...[
            _buildRiskAssessmentCard(ili.riskAssessment!, isDark, textFg, mutedFg),
            const SizedBox(height: 16),
          ],

          // Growth summary
          if (ili.growthStats.isNotEmpty) ...[
            Text('Growth Rate Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
            const SizedBox(height: 12),
            ...ili.growthStats.entries.map((entry) {
              final g = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textFg)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _severityBadge('Critical', g.criticalCount, AppTheme.figmaAccent),
                          _severityBadge('High', g.highCount, AppTheme.warning),
                          _severityBadge('Moderate', g.moderateCount, AppTheme.figmaSecondary),
                          _severityBadge('Normal', g.normalCount, AppTheme.success),
                        ],
                      ),
                      if (g.avgDepthGrowth != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Avg growth: ', style: TextStyle(fontSize: 12, color: mutedFg)),
                            Text('${g.avgDepthGrowth!.toStringAsFixed(2)} %/yr',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textFg)),
                            const SizedBox(width: 16),
                            Text('Max: ', style: TextStyle(fontSize: 12, color: mutedFg)),
                            Text('${g.maxDepthGrowth?.toStringAsFixed(2)} %/yr',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: (g.maxDepthGrowth ?? 0) > 3 ? AppTheme.figmaAccent : textFg,
                                )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ---------- Alignment Tab ----------

  Widget _buildAlignment(IliProvider ili, bool isDark, Color textFg, Color mutedFg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Girth Weld Alignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
          const SizedBox(height: 4),
          Text(
            'Matching girth welds across runs to correct odometer drift',
            style: TextStyle(fontSize: 13, color: mutedFg),
          ),
          const SizedBox(height: 16),

          ...ili.alignmentPairs.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.figmaSecondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(a.pair, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.figmaSecondary)),
                        ),
                        const Spacer(),
                        Text('${a.matched} welds matched', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textFg)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStat('Avg Offset', '${a.avgOffsetFt.toStringAsFixed(2)} ft', textFg, mutedFg),
                        _miniStat('Max Offset', '${a.maxOffsetFt.toStringAsFixed(2)} ft', textFg, mutedFg),
                        if (a.stdOffsetFt != null)
                          _miniStat('Std Dev', '${a.stdOffsetFt!.toStringAsFixed(2)} ft', textFg, mutedFg),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 80), duration: 300.ms)
                  .slideY(begin: 0.03, end: 0),
            );
          }),
        ],
      ),
    );
  }

  // ---------- Matches Tab ----------

  Widget _buildMatches(IliProvider ili, bool isDark, Color textFg, Color mutedFg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anomaly Matching Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
          const SizedBox(height: 4),
          Text(
            'Metal-loss defects matched across inspection runs',
            style: TextStyle(fontSize: 13, color: mutedFg),
          ),
          const SizedBox(height: 16),

          ...ili.matchResults.entries.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.figmaSecondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(m.pair, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.figmaSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Match stats bar
                    Row(
                      children: [
                        Expanded(
                          flex: m.matched,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                            ),
                          ),
                        ),
                        if (m.newInLaterRun > 0)
                          Expanded(
                            flex: m.newInLaterRun,
                            child: Container(height: 8, color: AppTheme.figmaSecondary),
                          ),
                        if (m.missingFromEarlierRun > 0)
                          Expanded(
                            flex: m.missingFromEarlierRun,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.warning,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _legendDot('Matched: ${m.matched}', AppTheme.success, mutedFg),
                        _legendDot('New: ${m.newInLaterRun}', AppTheme.figmaSecondary, mutedFg),
                        _legendDot('Missing: ${m.missingFromEarlierRun}', AppTheme.warning, mutedFg),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Confidence breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStat('High', '${m.highConfidence}', textFg, mutedFg),
                        _miniStat('Medium', '${m.mediumConfidence}', textFg, mutedFg),
                        _miniStat('Low', '${m.lowConfidence}', textFg, mutedFg),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 100), duration: 300.ms),
            );
          }),
        ],
      ),
    );
  }

  // ---------- Growth Tab ----------

  Widget _buildGrowth(IliProvider ili, bool isDark, Color textFg, Color mutedFg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Growing Defects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
          const SizedBox(height: 4),
          Text(
            'Anomalies with the fastest corrosion growth rates',
            style: TextStyle(fontSize: 13, color: mutedFg),
          ),
          const SizedBox(height: 16),

          // Growth chart
          if (ili.topGrowing.isNotEmpty)
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(isDark),
              child: _buildGrowthChart(ili.topGrowing.take(15).toList(), isDark, textFg, mutedFg),
            ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Top growing list
          ...ili.topGrowing.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppTheme.cardDecoration(isDark),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _severityColor(item.severity).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _severityColor(item.severity)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Joint ${item.joint ?? "?"} @ ${item.y2Dist?.toStringAsFixed(0) ?? "?"} ft',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textFg),
                          ),
                          Text(
                            '${item.y1DepthPct?.toStringAsFixed(1) ?? "?"}% → ${item.y2DepthPct?.toStringAsFixed(1) ?? "?"}%',
                            style: TextStyle(fontSize: 12, color: mutedFg),
                          ),
                        ],
                      ),
                    ),
                    // Growth rate
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.depthGrowthPctYr?.toStringAsFixed(2) ?? "?"} %/yr',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _severityColor(item.severity),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _severityColor(item.severity).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.severity?.toUpperCase() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _severityColor(item.severity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 40), duration: 250.ms)
                  .slideX(begin: 0.02, end: 0),
            );
          }),
        ],
      ),
    );
  }

  // ---------- Growth chart ----------

  Widget _buildGrowthChart(List<IliGrowthItem> items, bool isDark, Color textFg, Color mutedFg) {
    final spots = items.asMap().entries
        .where((e) => e.value.depthGrowthPctYr != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.depthGrowthPctYr!))
        .toList();

    if (spots.isEmpty) return const SizedBox();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2,
        barGroups: spots.map((s) {
          final color = s.y > 3
              ? AppTheme.figmaAccent
              : s.y > 2
                  ? AppTheme.warning
                  : s.y > 1
                      ? AppTheme.figmaSecondary
                      : AppTheme.success;
          return BarChartGroupData(
            x: s.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: s.y,
                color: color,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 10, color: mutedFg),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'J${items[idx].joint ?? "?"}',
                      style: TextStyle(fontSize: 9, color: mutedFg),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // ---------- Predictions Tab ----------

  Widget _buildPredictions(IliProvider ili, bool isDark, Color textFg, Color mutedFg) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Growth Predictions section
          Text('Growth Predictions (ML)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
          const SizedBox(height: 4),
          Text(
            'ML-predicted future depths for fastest-growing anomalies',
            style: TextStyle(fontSize: 13, color: mutedFg),
          ),
          const SizedBox(height: 12),
          
          if (ili.growthPredictions.isEmpty)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                await ili.loadGrowthPredictions(
                  '2015->2022', 5,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: AppTheme.buttonDecoration(isDark, isPrimary: false),
                child: Text('Generate Predictions', style: TextStyle(color: textFg, fontWeight: FontWeight.w500)),
              ),
            )
          else
            ...ili.growthPredictions.map((pred) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Anomaly at ${pred.y2Dist.toStringAsFixed(0)} ft', 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textFg)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _miniStat('Current (2022)', '${pred.y2DepthPct.toStringAsFixed(1)}%', textFg, mutedFg),
                          _miniStat('Growth Rate', '${pred.depthGrowthPctYr.toStringAsFixed(2)}%/yr', textFg, mutedFg),
                          _miniStat('Pred. 2027', '${pred.predicted2027?.toStringAsFixed(1) ?? "?"}%', 
                            pred.predicted2027 != null && pred.predicted2027! > 80 ? AppTheme.figmaAccent : textFg, mutedFg),
                          _miniStat('Pred. 2032', '${pred.predicted2032?.toStringAsFixed(1) ?? "?"}%', 
                            pred.predicted2032 != null && pred.predicted2032! > 80 ? AppTheme.figmaAccent : textFg, mutedFg),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(pred.explanation, style: TextStyle(fontSize: 12, color: mutedFg, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // New Anomaly Predictions
          Text('New Corrosion Locations (ML)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
          const SizedBox(height: 4),
          Text(
            'ML-predicted locations where new corrosion is likely',
            style: TextStyle(fontSize: 13, color: mutedFg),
          ),
          const SizedBox(height: 12),

          if (ili.newAnomalyPredictions.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ili.newAnomalyError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      ili.newAnomalyError!,
                      style: TextStyle(fontSize: 12, color: AppTheme.warning),
                    ),
                  ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    await ili.loadNewAnomalyPredictions(
                      2022, 0, 5000,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: AppTheme.buttonDecoration(isDark, isPrimary: false),
                    child: Text('Generate Predictions', style: TextStyle(color: textFg, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            )
          else
            ...ili.newAnomalyPredictions.map((pred) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(isDark),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.location_on, color: AppTheme.warning, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${pred.predictedDist.toStringAsFixed(0)} ft', 
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textFg)),
                            Text(pred.explanation, style: TextStyle(fontSize: 12, color: mutedFg)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.figmaAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Risk: ${pred.riskScore.toStringAsFixed(1)}', 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.figmaAccent)),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Clusters
          Text('Anomaly Clusters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
          const SizedBox(height: 4),
          Text(
            'Spatial clusters of closely-spaced anomalies',
            style: TextStyle(fontSize: 13, color: mutedFg),
          ),
          const SizedBox(height: 12),

          if (ili.clusters.isEmpty)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                await ili.loadClusters(2022, 50.0, 3);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: AppTheme.buttonDecoration(isDark, isPrimary: false),
                child: Text('Identify Clusters', style: TextStyle(color: textFg, fontWeight: FontWeight.w500)),
              ),
            )
          else
            ...ili.clusters.values.map((cluster) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${cluster.spanStart.toStringAsFixed(0)}-${cluster.spanEnd.toStringAsFixed(0)} ft', 
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textFg)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.figmaSecondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${cluster.memberCount} anomalies', 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.figmaSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _miniStat('Avg Depth', '${cluster.avgDepthPct.toStringAsFixed(1)}%', textFg, mutedFg),
                          _miniStat('Max Depth', '${cluster.maxDepthPct.toStringAsFixed(1)}%', textFg, mutedFg),
                          _miniStat('Risk Score', '${cluster.riskScore.toStringAsFixed(1)}', 
                            cluster.riskScore > 7 ? AppTheme.figmaAccent : textFg, mutedFg),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentCard(IliRiskAssessment risk, bool isDark, Color textFg, Color mutedFg) {
    Color levelColor = AppTheme.success;
    if (risk.riskLevel == 'Critical') levelColor = AppTheme.figmaAccent;
    else if (risk.riskLevel == 'High') levelColor = AppTheme.warning;
    else if (risk.riskLevel == 'Medium') levelColor = AppTheme.figmaSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(isDark).copyWith(
        border: Border.all(color: levelColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: levelColor, size: 24),
              const SizedBox(width: 8),
              Text('AI Risk Assessment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(risk.riskLevel, 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: levelColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(risk.overallRisk, style: TextStyle(fontSize: 13, color: textFg, height: 1.4)),
          if (risk.actionItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Recommended Actions:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textFg)),
            const SizedBox(height: 6),
            ...risk.actionItems.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: mutedFg)),
                  Expanded(child: Text(action, style: TextStyle(fontSize: 12, color: mutedFg))),
                ],
              ),
            )),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03, end: 0);
  }

  // ---------- Helpers ----------

  Widget _statCard(String label, String value, IconData icon, bool isDark, Color textFg, Color mutedFg, {int delay = 0}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppTheme.figmaAccent),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textFg)),
            Text(label, style: TextStyle(fontSize: 12, color: mutedFg)),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
          .scaleXY(begin: 0.95, end: 1.0, duration: 300.ms),
    );
  }

  Widget _miniStat(String label, String value, Color textFg, Color mutedFg) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textFg)),
        Text(label, style: TextStyle(fontSize: 11, color: mutedFg)),
      ],
    );
  }

  Widget _severityBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
      ],
    );
  }

  Widget _legendDot(String label, Color color, Color mutedFg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: mutedFg)),
      ],
    );
  }

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'critical':
        return AppTheme.figmaAccent;
      case 'high':
        return AppTheme.warning;
      case 'moderate':
        return AppTheme.figmaSecondary;
      default:
        return AppTheme.success;
    }
  }
}
