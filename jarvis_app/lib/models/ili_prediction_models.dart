/// Data models for AI/ML predictions in ILI analysis.

class IliGrowthPrediction {
  final double y2Dist;
  final double y2DepthPct;
  final double depthGrowthPctYr;
  final double? predicted2027;
  final double? predicted2032;
  final String explanation;

  IliGrowthPrediction({
    required this.y2Dist,
    required this.y2DepthPct,
    required this.depthGrowthPctYr,
    this.predicted2027,
    this.predicted2032,
    required this.explanation,
  });

  factory IliGrowthPrediction.fromJson(Map<String, dynamic> json) {
    return IliGrowthPrediction(
      y2Dist: (json['y2_dist'] ?? 0).toDouble(),
      y2DepthPct: (json['y2_depth_pct'] ?? 0).toDouble(),
      depthGrowthPctYr: (json['depth_growth_pct_yr'] ?? 0).toDouble(),
      predicted2027: json['predicted_2027']?.toDouble(),
      predicted2032: json['predicted_2032']?.toDouble(),
      explanation: json['explanation'] ?? '',
    );
  }
}

class IliNewAnomalyPrediction {
  final double predictedDist;
  final double riskScore;
  final String explanation;

  IliNewAnomalyPrediction({
    required this.predictedDist,
    required this.riskScore,
    required this.explanation,
  });

  factory IliNewAnomalyPrediction.fromJson(Map<String, dynamic> json) {
    return IliNewAnomalyPrediction(
      predictedDist: (json['predicted_dist'] ?? 0).toDouble(),
      riskScore: (json['risk_score'] ?? 5).toDouble(),
      explanation: json['explanation'] ?? '',
    );
  }
}

class IliCluster {
  final String id;
  final double centerDist;
  final double spanStart;
  final double spanEnd;
  final int memberCount;
  final double avgDepthPct;
  final double maxDepthPct;
  final double totalLengthIn;
  final double riskScore;
  final List<double> memberDistances;

  IliCluster({
    required this.id,
    required this.centerDist,
    required this.spanStart,
    required this.spanEnd,
    required this.memberCount,
    required this.avgDepthPct,
    required this.maxDepthPct,
    required this.totalLengthIn,
    required this.riskScore,
    required this.memberDistances,
  });

  factory IliCluster.fromJson(String id, Map<String, dynamic> json) {
    return IliCluster(
      id: id,
      centerDist: (json['center_dist'] ?? 0).toDouble(),
      spanStart: (json['span_start'] ?? 0).toDouble(),
      spanEnd: (json['span_end'] ?? 0).toDouble(),
      memberCount: json['member_count'] ?? 0,
      avgDepthPct: (json['avg_depth_pct'] ?? 0).toDouble(),
      maxDepthPct: (json['max_depth_pct'] ?? 0).toDouble(),
      totalLengthIn: (json['total_length_in'] ?? 0).toDouble(),
      riskScore: (json['risk_score'] ?? 0).toDouble(),
      memberDistances: (json['member_distances'] as List? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class IliRiskAssessment {
  final String overallRisk;
  final String riskLevel;
  final List<String> actionItems;

  IliRiskAssessment({
    required this.overallRisk,
    required this.riskLevel,
    required this.actionItems,
  });

  factory IliRiskAssessment.fromJson(Map<String, dynamic> json) {
    return IliRiskAssessment(
      overallRisk: json['overall_risk'] ?? '',
      riskLevel: json['risk_level'] ?? 'Medium',
      actionItems: (json['action_items'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
