/// Data models for ILI (In-Line Inspection) pipeline alignment.

class IliRunSummary {
  final int year;
  final int totalFeatures;
  final int anomalies;
  final int metalLoss;
  final int girthWelds;
  final double maxDistanceFt;

  IliRunSummary({
    required this.year,
    required this.totalFeatures,
    required this.anomalies,
    required this.metalLoss,
    required this.girthWelds,
    required this.maxDistanceFt,
  });

  factory IliRunSummary.fromJson(int year, Map<String, dynamic> json) {
    return IliRunSummary(
      year: year,
      totalFeatures: json['total_features'] ?? 0,
      anomalies: json['anomalies'] ?? 0,
      metalLoss: json['metal_loss'] ?? 0,
      girthWelds: json['girth_welds'] ?? 0,
      maxDistanceFt: (json['max_distance_ft'] ?? 0).toDouble(),
    );
  }
}

class IliLoadResult {
  final double pipelineLengthFt;
  final Map<int, IliRunSummary> runs;

  IliLoadResult({required this.pipelineLengthFt, required this.runs});

  factory IliLoadResult.fromJson(Map<String, dynamic> json) {
    final runsMap = <int, IliRunSummary>{};
    final runsJson = json['runs'] as Map<String, dynamic>? ?? {};
    for (final entry in runsJson.entries) {
      final year = int.tryParse(entry.key);
      if (year != null) {
        runsMap[year] = IliRunSummary.fromJson(year, entry.value);
      }
    }
    return IliLoadResult(
      pipelineLengthFt: (json['pipeline_length_ft'] ?? 0).toDouble(),
      runs: runsMap,
    );
  }
}

class IliAlignmentPair {
  final String pair;
  final int matched;
  final double avgOffsetFt;
  final double maxOffsetFt;
  final double? stdOffsetFt;

  IliAlignmentPair({
    required this.pair,
    required this.matched,
    required this.avgOffsetFt,
    required this.maxOffsetFt,
    this.stdOffsetFt,
  });

  factory IliAlignmentPair.fromJson(Map<String, dynamic> json) {
    return IliAlignmentPair(
      pair: json['pair'] ?? '',
      matched: json['matched'] ?? 0,
      avgOffsetFt: (json['avg_offset_ft'] ?? 0).toDouble(),
      maxOffsetFt: (json['max_offset_ft'] ?? 0).toDouble(),
      stdOffsetFt: json['std_offset_ft']?.toDouble(),
    );
  }
}

class IliMatchResult {
  final String pair;
  final int matched;
  final int newInLaterRun;
  final int missingFromEarlierRun;
  final int highConfidence;
  final int mediumConfidence;
  final int lowConfidence;
  final int totalY1;
  final int totalY2;

  IliMatchResult({
    required this.pair,
    required this.matched,
    required this.newInLaterRun,
    required this.missingFromEarlierRun,
    required this.highConfidence,
    required this.mediumConfidence,
    required this.lowConfidence,
    required this.totalY1,
    required this.totalY2,
  });

  factory IliMatchResult.fromJson(String pair, Map<String, dynamic> json) {
    return IliMatchResult(
      pair: pair,
      matched: json['matched'] ?? 0,
      newInLaterRun: json['new_in_later_run'] ?? 0,
      missingFromEarlierRun: json['missing_from_earlier_run'] ?? 0,
      highConfidence: json['high_confidence'] ?? 0,
      mediumConfidence: json['medium_confidence'] ?? 0,
      lowConfidence: json['low_confidence'] ?? 0,
      totalY1: json['total_y1_metal_loss'] ?? 0,
      totalY2: json['total_y2_metal_loss'] ?? 0,
    );
  }
}

class IliGrowthStats {
  final String pair;
  final int totalMatched;
  final double? avgDepthGrowth;
  final double? maxDepthGrowth;
  final int criticalCount;
  final int highCount;
  final int moderateCount;
  final int normalCount;

  IliGrowthStats({
    required this.pair,
    required this.totalMatched,
    this.avgDepthGrowth,
    this.maxDepthGrowth,
    required this.criticalCount,
    required this.highCount,
    required this.moderateCount,
    required this.normalCount,
  });

  factory IliGrowthStats.fromJson(String pair, Map<String, dynamic> json) {
    return IliGrowthStats(
      pair: pair,
      totalMatched: json['total_matched'] ?? 0,
      avgDepthGrowth: json['avg_depth_growth_pct_yr']?.toDouble(),
      maxDepthGrowth: json['max_depth_growth_pct_yr']?.toDouble(),
      criticalCount: json['critical_count'] ?? 0,
      highCount: json['high_count'] ?? 0,
      moderateCount: json['moderate_count'] ?? 0,
      normalCount: json['normal_count'] ?? 0,
    );
  }
}

class IliGrowthItem {
  final double? y1Dist;
  final double? y2Dist;
  final double? y1DepthPct;
  final double? y2DepthPct;
  final double? y1LengthIn;
  final double? y2LengthIn;
  final double? y1Clock;
  final double? y2Clock;
  final double? depthGrowthPctYr;
  final double? lengthGrowthInYr;
  final String? severity;
  final String? confidence;
  final double? score;
  final int? joint;

  IliGrowthItem({
    this.y1Dist,
    this.y2Dist,
    this.y1DepthPct,
    this.y2DepthPct,
    this.y1LengthIn,
    this.y2LengthIn,
    this.y1Clock,
    this.y2Clock,
    this.depthGrowthPctYr,
    this.lengthGrowthInYr,
    this.severity,
    this.confidence,
    this.score,
    this.joint,
  });

  factory IliGrowthItem.fromJson(Map<String, dynamic> json) {
    return IliGrowthItem(
      y1Dist: json['y1_dist']?.toDouble(),
      y2Dist: json['y2_dist']?.toDouble(),
      y1DepthPct: json['y1_depth_pct']?.toDouble(),
      y2DepthPct: json['y2_depth_pct']?.toDouble(),
      y1LengthIn: json['y1_length_in']?.toDouble(),
      y2LengthIn: json['y2_length_in']?.toDouble(),
      y1Clock: json['y1_clock']?.toDouble(),
      y2Clock: json['y2_clock']?.toDouble(),
      depthGrowthPctYr: json['depth_growth_pct_yr']?.toDouble(),
      lengthGrowthInYr: json['length_growth_in_yr']?.toDouble(),
      severity: json['severity'],
      confidence: json['confidence'],
      score: json['score']?.toDouble(),
      joint: json['y2_joint']?.toInt() ?? json['y1_joint']?.toInt(),
    );
  }
}

class IliProfilePoint {
  final double logDistFt;
  final double? depthPct;
  final double? oclock;
  final int? joint;

  IliProfilePoint({
    required this.logDistFt,
    this.depthPct,
    this.oclock,
    this.joint,
  });

  factory IliProfilePoint.fromJson(Map<String, dynamic> json) {
    return IliProfilePoint(
      logDistFt: (json['log_dist_ft'] ?? 0).toDouble(),
      depthPct: json['depth_pct']?.toDouble(),
      oclock: json['oclock']?.toDouble(),
      joint: json['joint']?.toInt(),
    );
  }
}
