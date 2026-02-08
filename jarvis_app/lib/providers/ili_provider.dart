import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ili_models.dart';
import '../models/ili_prediction_models.dart';

enum IliStatus { idle, loading, loaded, error }

class IliProvider extends ChangeNotifier {
  String _apiBaseUrl = 'http://127.0.0.1:8001';
  IliStatus _status = IliStatus.idle;
  String? _error;

  // Data
  IliLoadResult? _loadResult;
  List<IliAlignmentPair> _alignmentPairs = [];
  Map<String, IliMatchResult> _matchResults = {};
  Map<String, IliGrowthStats> _growthStats = {};
  List<IliGrowthItem> _topGrowing = [];
  List<IliProfilePoint> _profileData = [];
  int _selectedProfileYear = 2022;
  
  // AI/ML predictions
  List<IliGrowthPrediction> _growthPredictions = [];
  List<IliNewAnomalyPrediction> _newAnomalyPredictions = [];
  String? _newAnomalyError;
  Map<String, IliCluster> _clusters = {};
  IliRiskAssessment? _riskAssessment;

  // Getters
  IliStatus get status => _status;
  String? get error => _error;
  IliLoadResult? get loadResult => _loadResult;
  List<IliAlignmentPair> get alignmentPairs => _alignmentPairs;
  Map<String, IliMatchResult> get matchResults => _matchResults;
  Map<String, IliGrowthStats> get growthStats => _growthStats;
  List<IliGrowthItem> get topGrowing => _topGrowing;
  List<IliProfilePoint> get profileData => _profileData;
  int get selectedProfileYear => _selectedProfileYear;
  bool get isLoaded => _status == IliStatus.loaded;
  List<IliGrowthPrediction> get growthPredictions => _growthPredictions;
  List<IliNewAnomalyPrediction> get newAnomalyPredictions => _newAnomalyPredictions;
  String? get newAnomalyError => _newAnomalyError;
  Map<String, IliCluster> get clusters => _clusters;
  IliRiskAssessment? get riskAssessment => _riskAssessment;

  void setApiBaseUrl(String url) {
    _apiBaseUrl = url.trim().isEmpty ? 'http://127.0.0.1:8001' : url.trim();
  }

  /// Injects loaded data for testing (widget tests). No-op in production.
  void setLoadedDataForTest({
    required IliLoadResult loadResult,
    required List<IliAlignmentPair> alignmentPairs,
    required Map<String, IliMatchResult> matchResults,
    required Map<String, IliGrowthStats> growthStats,
    required List<IliGrowthItem> topGrowing,
  }) {
    _loadResult = loadResult;
    _alignmentPairs = alignmentPairs;
    _matchResults = matchResults;
    _growthStats = growthStats;
    _topGrowing = topGrowing;
    _status = IliStatus.loaded;
    _error = null;
    notifyListeners();
  }

  Future<void> runFullPipeline({String apiKey = '', String model = '', String baseUrl = ''}) async {
    _status = IliStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Full pipeline (load + align + match + growth) can take several minutes on large datasets
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/ili/run-all'),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) {
        throw Exception('ILI API returned ${response.statusCode}: ${response.body}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Parse load result
      if (data['load'] != null) {
        _loadResult = IliLoadResult.fromJson(data['load']);
      }

      // Parse alignment
      if (data['alignment'] != null) {
        final alignList = data['alignment']['weld_alignment'] as List? ?? [];
        _alignmentPairs = alignList
            .map((e) => IliAlignmentPair.fromJson(e))
            .toList();
      }

      // Parse matching
      if (data['matching'] != null) {
        _matchResults = {};
        for (final entry in (data['matching'] as Map<String, dynamic>).entries) {
          _matchResults[entry.key] = IliMatchResult.fromJson(entry.key, entry.value);
        }
      }

      // Parse growth
      if (data['growth'] != null) {
        _growthStats = {};
        for (final entry in (data['growth'] as Map<String, dynamic>).entries) {
          _growthStats[entry.key] = IliGrowthStats.fromJson(entry.key, entry.value);
        }
      }

      // Parse top growing
      if (data['top_growing'] != null) {
        _topGrowing = (data['top_growing'] as List)
            .map((e) => IliGrowthItem.fromJson(e))
            .toList();
      }

      _status = IliStatus.loaded;
      notifyListeners();
      
      // Auto-load risk assessment if API key provided
      if (apiKey.isNotEmpty && model.isNotEmpty && baseUrl.isNotEmpty) {
        await loadRiskAssessment(apiKey, model, baseUrl);
      }
    } catch (e) {
      _status = IliStatus.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProfile(int year) async {
    _selectedProfileYear = year;
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/ili/profile/$year'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _profileData = data
            .map((e) => IliProfilePoint.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<List<IliGrowthItem>> getMatchDetails(String pair, {int limit = 100, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/ili/matches/$pair?limit=$limit&offset=$offset'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => IliGrowthItem.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load match details: $e');
    }
    return [];
  }

  // AI/ML Methods

  Future<void> loadGrowthPredictions(String pair, int topN) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/ili/predict-growth')
          .replace(queryParameters: {
        'pair': pair,
        'top_n': topN.toString(),
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _growthPredictions = data.map((e) => IliGrowthPrediction.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load growth predictions: $e');
    }
  }

  Future<void> loadNewAnomalyPredictions(int year, double startDist, double endDist, {int topN = 5}) async {
    _newAnomalyError = null;
    try {
      final uri = Uri.parse('$_apiBaseUrl/ili/predict-new-anomalies')
          .replace(queryParameters: {
        'year': year.toString(),
        'start_dist': startDist.toString(),
        'end_dist': endDist.toString(),
        'top_n': topN.toString(),
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          _newAnomalyPredictions = (decoded as List)
              .map((e) => IliNewAnomalyPrediction.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (_newAnomalyPredictions.isEmpty) {
            _newAnomalyError = 'No predictions could be generated. Run Analysis first, then try again.';
          }
        } else if (decoded is Map && decoded['error'] != null) {
          _newAnomalyError = decoded['error'].toString();
          _newAnomalyPredictions = [];
        }
        notifyListeners();
      } else {
        _newAnomalyError = 'API error: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _newAnomalyError = e.toString();
      debugPrint('Failed to load new anomaly predictions: $e');
      notifyListeners();
    }
  }

  Future<void> loadClusters(int year, double epsilon, int minSamples) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/ili/clusters')
          .replace(queryParameters: {
        'year': year.toString(),
        'epsilon': epsilon.toString(),
        'min_samples': minSamples.toString(),
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _clusters = {};
        for (final entry in data.entries) {
          _clusters[entry.key] = IliCluster.fromJson(entry.key, entry.value);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load clusters: $e');
    }
  }

  Future<void> loadRiskAssessment(String apiKey, String model, String baseUrl) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/ili/risk-assessment')
          .replace(queryParameters: {
        'api_key': apiKey,
        'model': model,
        'base_url': baseUrl,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _riskAssessment = IliRiskAssessment.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load risk assessment: $e');
    }
  }
}
