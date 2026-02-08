/// Widget test: ILI screen builds and all 4 tabs display when data is loaded.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jarvis_app/models/ili_models.dart';
import 'package:jarvis_app/providers/ili_provider.dart';
import 'package:jarvis_app/screens/ili_screen.dart';

void main() {
  testWidgets('ILI screen shows Run Analysis when idle', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: ChangeNotifierProvider<IliProvider>(
          create: (_) => IliProvider(),
          child: const IliScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Run Analysis'), findsOneWidget);
    expect(find.text('ILI Data Alignment'), findsOneWidget);
    // Flush flutter_animate zero-duration timer so test teardown does not report pending timers
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('ILI screen shows all 4 tabs when loaded with mock data',
      (WidgetTester tester) async {
    final provider = IliProvider();
    provider.setLoadedDataForTest(
      loadResult: IliLoadResult(
        pipelineLengthFt: 1000,
        runs: {
          2007: IliRunSummary(
            year: 2007,
            totalFeatures: 100,
            anomalies: 50,
            metalLoss: 40,
            girthWelds: 30,
            maxDistanceFt: 1000,
          ),
          2022: IliRunSummary(
            year: 2022,
            totalFeatures: 120,
            anomalies: 55,
            metalLoss: 45,
            girthWelds: 32,
            maxDistanceFt: 1000,
          ),
        },
      ),
      alignmentPairs: [
        IliAlignmentPair(
          pair: '2007->2022',
          matched: 30,
          avgOffsetFt: 0.5,
          maxOffsetFt: 2.0,
          stdOffsetFt: 0.3,
        ),
      ],
      matchResults: {
        '2007->2022': IliMatchResult(
          pair: '2007->2022',
          matched: 40,
          newInLaterRun: 5,
          missingFromEarlierRun: 3,
          highConfidence: 30,
          mediumConfidence: 8,
          lowConfidence: 2,
          totalY1: 40,
          totalY2: 45,
        ),
      },
      growthStats: {
        '2007->2022': IliGrowthStats(
          pair: '2007->2022',
          totalMatched: 40,
          avgDepthGrowth: 0.5,
          maxDepthGrowth: 2.0,
          criticalCount: 1,
          highCount: 3,
          moderateCount: 10,
          normalCount: 26,
        ),
      },
      topGrowing: [
        IliGrowthItem(
          depthGrowthPctYr: 2.5,
          severity: 'critical',
          confidence: 'high',
          y1DepthPct: 10,
          y2DepthPct: 47.5,
        ),
      ],
    );

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: ChangeNotifierProvider<IliProvider>.value(
          value: provider,
          child: const IliScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Tab labels visible when loaded
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Alignment'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);
    expect(find.text('Growth'), findsOneWidget);

    // Overview tab content
    expect(find.text('Growth Rate Summary'), findsOneWidget);

    // Alignment tab: switch and verify
    await tester.tap(find.text('Alignment'));
    await tester.pump();
    expect(find.text('Girth Weld Alignment'), findsOneWidget);

    // Matches tab
    await tester.tap(find.text('Matches'));
    await tester.pump();
    expect(find.text('Anomaly Matching Results'), findsOneWidget);

    // Growth tab
    await tester.tap(find.text('Growth'));
    await tester.pump();
    expect(find.text('Top Growing Defects'), findsOneWidget);

    // Allow any animation timers from flutter_animate to complete before test ends
    await tester.pump(const Duration(milliseconds: 500));
  });
}
