import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class AnalyticsEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
}

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const String _storageKey = 'property_analytics';
  List<AnalyticsEvent> _events = [];
  Map<String, DateTime> _pageStartTimes = {};
  Map<String, Stopwatch> _propertyViewTimers = {};

  Future<void> init() async {
    await _loadEvents();
    print('[Analytics] Initialized with ${_events.length} events');
  }

  // ==============================
  // TRACK PAGE VIEWS
  // ==============================
  void trackPageView(String pageName, {String? propertyId}) {
    _pageStartTimes[pageName] = DateTime.now();

    _addEvent(
      AnalyticsEvent(
        type: 'page_view_start',
        data: {
          'page': pageName,
          'propertyId': propertyId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      ),
    );
  }

  void trackPageEnd(String pageName) {
    final startTime = _pageStartTimes[pageName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);

      _addEvent(
        AnalyticsEvent(
          type: 'page_view_end',
          data: {
            'page': pageName,
            'duration_ms': duration.inMilliseconds,
            'timestamp': DateTime.now().toIso8601String(),
          },
          timestamp: DateTime.now(),
        ),
      );

      _pageStartTimes.remove(pageName);
    }
  }

  // ==============================
  // TRACK PROPERTY VIEWS
  // ==============================
  void trackPropertyView(String propertyId, String propertyTitle) {
    _propertyViewTimers[propertyId] = Stopwatch()..start();

    _addEvent(
      AnalyticsEvent(
        type: 'property_view_start',
        data: {
          'propertyId': propertyId,
          'propertyTitle': propertyTitle,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      ),
    );

    print('[Analytics] View started for: $propertyTitle');
  }

  void trackPropertyViewEnd(String propertyId) {
    final timer = _propertyViewTimers[propertyId];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;

      _addEvent(
        AnalyticsEvent(
          type: 'property_view_end',
          data: {
            'propertyId': propertyId,
            'duration_ms': duration,
            'timestamp': DateTime.now().toIso8601String(),
          },
          timestamp: DateTime.now(),
        ),
      );

      _propertyViewTimers.remove(propertyId);
      print('[Analytics] View ended for property: $propertyId (${duration}ms)');
    }
  }

  // ==============================
  // TRACK INTERACTIONS
  // ==============================
  void trackInteraction({
    required String interactionType,
    String? propertyId,
    String? element,
    Map<String, dynamic>? extraData,
  }) {
    final data = {
      'interactionType': interactionType,
      'propertyId': propertyId,
      'element': element,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (extraData != null) {
      data.addAll(extraData.map((key, value) => MapEntry(key, value?.toString())));
    }

    _addEvent(
      AnalyticsEvent(
        type: 'interaction',
        data: data,
        timestamp: DateTime.now(),
      ),
    );

    print('[Analytics] Interaction: $interactionType - $element');
  }

  // ==============================
  // TRACK SEARCH & FILTERS
  // ==============================
  void trackSearch(String query, int resultCount) {
    _addEvent(
      AnalyticsEvent(
        type: 'search',
        data: {
          'query': query,
          'resultCount': resultCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      ),
    );

    print('[Analytics] Search: "$query" found $resultCount results');
  }

  void trackFilter(Map<String, dynamic> filters) {
    _addEvent(
      AnalyticsEvent(
        type: 'filter',
        data: {
          'filters': filters,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      ),
    );

    print('[Analytics] Filter applied: $filters');
  }

  // ==============================
  // GET ANALYTICS REPORTS
  // ==============================
  Future<Map<String, dynamic>> getMostViewedProperties({int limit = 10}) async {
    final propertyViews = <String, Map<String, dynamic>>{};

    for (final event in _events) {
      if (event.type == 'property_view_start') {
        final propertyId = event.data['propertyId'];
        final propertyTitle = event.data['propertyTitle'];

        if (propertyId != null) {
          if (!propertyViews.containsKey(propertyId)) {
            propertyViews[propertyId] = {
              'propertyId': propertyId,
              'propertyTitle': propertyTitle ?? 'Unknown',
              'viewCount': 0,
              'totalDuration': 0,
              'lastViewed': '',
            };
          }

          final property = propertyViews[propertyId]!;
          property['viewCount'] = (property['viewCount'] as int) + 1;
          property['lastViewed'] = event.data['timestamp'];
        }
      } else if (event.type == 'property_view_end') {
        final propertyId = event.data['propertyId'];
        final duration = event.data['duration_ms'];

        if (propertyId != null &&
            duration != null &&
            propertyViews.containsKey(propertyId)) {
          propertyViews[propertyId]!['totalDuration'] =
              (propertyViews[propertyId]!['totalDuration'] as int) + duration;
        }
      }
    }

    // Calculate average duration
    for (final property in propertyViews.values) {
      final viewCount = property['viewCount'] as int;
      final totalDuration = property['totalDuration'] as int;
      property['avgDuration'] = viewCount > 0 ? totalDuration ~/ viewCount : 0;
      property['avgDurationFormatted'] = _formatDuration(
        property['avgDuration'] as int,
      );
    }

    // Sort by view count
    final sortedProperties = propertyViews.values.toList()
      ..sort(
        (a, b) => (b['viewCount'] as int).compareTo(a['viewCount'] as int),
      );

    final topProperties = sortedProperties.take(limit).toList();

    return {
      'topProperties': topProperties,
      'totalProperties': propertyViews.length,
      'totalViews': _events
          .where((e) => e.type == 'property_view_start')
          .length,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> getPageAnalytics() async {
    final pageStats = <String, Map<String, dynamic>>{};

    for (final event in _events) {
      if (event.type == 'page_view_end') {
        final page = event.data['page'];
        final duration = event.data['duration_ms'];

        if (page != null && duration != null) {
          if (!pageStats.containsKey(page)) {
            pageStats[page] = {
              'pageName': page,
              'count': 0,
              'totalDuration': 0,
              'lastVisit': '',
            };
          }

          final stats = pageStats[page]!;
          stats['count'] = (stats['count'] as int) + 1;
          stats['totalDuration'] = (stats['totalDuration'] as int) + duration;
          stats['lastVisit'] = event.data['timestamp'];
        }
      }
    }

    // Calculate averages
    for (final stats in pageStats.values) {
      final count = stats['count'] as int;
      final totalDuration = stats['totalDuration'] as int;
      stats['avgDuration'] = count > 0 ? totalDuration ~/ count : 0;
      stats['avgDurationFormatted'] = _formatDuration(
        stats['avgDuration'] as int,
      );
    }

    // Sort by count
    final sortedPages = pageStats.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return {
      'pageStats': sortedPages,
      'totalPages': pageStats.length,
      'totalPageViews': _events.where((e) => e.type == 'page_view_end').length,
    };
  }

  Future<Map<String, dynamic>> getInteractionAnalytics() async {
    final interactions = <String, Map<String, dynamic>>{};

    for (final event in _events) {
      if (event.type == 'interaction') {
        final interactionType = event.data['interactionType'];
        final element = event.data['element'];
        final key = '$interactionType-$element';

        if (!interactions.containsKey(key)) {
          interactions[key] = {
            'type': interactionType,
            'element': element,
            'count': 0,
            'lastInteraction': '',
          };
        }

        final stats = interactions[key]!;
        stats['count'] = (stats['count'] as int) + 1;
        stats['lastInteraction'] = event.data['timestamp'];
      }
    }

    // Sort by count
    final sortedInteractions = interactions.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return {
      'interactions': sortedInteractions,
      'totalInteractions': _events.where((e) => e.type == 'interaction').length,
    };
  }

  // ==============================
  // DATA MANAGEMENT
  // ==============================
  void _addEvent(AnalyticsEvent event) {
    _events.add(event);
    _saveEvents();

    // Keep only last 1000 events to prevent overflow
    if (_events.length > 1000) {
      _events = _events.sublist(_events.length - 1000);
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _events.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving analytics: $e');
    }
  }

  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _events = jsonList.map((json) {
          return AnalyticsEvent(
            type: json['type'],
            data: Map<String, dynamic>.from(json['data']),
            timestamp: DateTime.parse(json['timestamp']),
          );
        }).toList();
      }
    } catch (e) {
      print('Error loading analytics: $e');
      _events = [];
    }
  }

  // ==============================
  // UTILITY METHODS
  // ==============================
  String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) return '${milliseconds}ms';

    final seconds = milliseconds ~/ 1000;
    if (seconds < 60) return '${seconds}s';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  Future<void> clearAnalytics() async {
    _events.clear();
    _propertyViewTimers.clear();
    _pageStartTimes.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    print('[Analytics] Cleared all analytics data');
  }

  Future<void> exportAnalytics() async {
    final report = {
      'mostViewedProperties': await getMostViewedProperties(),
      'pageAnalytics': await getPageAnalytics(),
      'interactionAnalytics': await getInteractionAnalytics(),
      'totalEvents': _events.length,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    // Print to console
    print('=' * 50);
    print('ANALYTICS REPORT');
    print('=' * 50);
    print(json.encode(report));
    print('=' * 50);

    // Also save to local storage for web download
    if (kIsWeb) {
      _downloadJson(report);
    }
  }

  void _downloadJson(Map<String, dynamic> data) {
    // For web, create a downloadable JSON file
    final jsonStr = json.encode(
      data,
      toEncodable: (object) => object.toString(),
    );
    final bytes = utf8.encode(jsonStr);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download =
          'analytics_report_${DateTime.now().millisecondsSinceEpoch}.json'
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void dispose() {
    _propertyViewTimers.clear();
    _pageStartTimes.clear();
  }
}
