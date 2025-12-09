import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:tasks_project/pages/property/model/property_model.dart';

class PropertyProvider extends ChangeNotifier {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://147.182.207.192:8003",
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  List<Property> propertyList = [];
  bool isLoading = false;
  bool isMoreLoading = false;
  bool hasMore = true;

  int currentPage = 1;
  int pageSize = 20;

  Map<String, dynamic> _currentFilters = {};
  String? _currentSearchQuery;

  // Getters
  Map<String, dynamic> get currentFilters => _currentFilters;
  String? get currentSearchQuery => _currentSearchQuery;

  // Set Filters
  void setFilters(Map<String, dynamic> filters) {
    _currentFilters = filters;
    propertyList.clear();
    currentPage = 1;
    hasMore = true;
    fetchProperties();
  }

  // Set Search Query
  void setSearchQuery(String? query) {
    _currentSearchQuery = query;
    propertyList.clear();
    currentPage = 1;
    hasMore = true;
    fetchProperties();
  }

  // Clear Filters
  void clearFilters() {
    _currentFilters.clear();
    _currentSearchQuery = null;
    propertyList.clear();
    currentPage = 1;
    hasMore = true;
    fetchProperties();
  }

  // Fetch Properties using Dio
  Future<void> fetchProperties({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore || isMoreLoading) return;
      isMoreLoading = true;
      currentPage++;
    } else {
      if (isLoading) return;
      isLoading = true;
      currentPage = 1;
    }

    notifyListeners();

    try {
      // Build Query Params
      Map<String, dynamic> queryParams = {
        "page": currentPage,
        "page_size": pageSize,
      };

      if (_currentFilters.isNotEmpty) {
        queryParams.addAll(_currentFilters);
      }

      if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
        queryParams["search"] = _currentSearchQuery!;
      }

      // API Call
      final response = await _dio.get(
        "/properties",
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        List<Property> newProperties = (data["properties"] as List)
            .map((json) => Property.fromJson(json))
            .toList();

        if (loadMore) {
          propertyList.addAll(newProperties);
        } else {
          propertyList = newProperties;
        }

        hasMore = newProperties.length >= pageSize;
      }
    } catch (e) {
      print("❌ Dio Fetch Error: $e");
    } finally {
      isLoading = false;
      isMoreLoading = false;
      notifyListeners();
    }
  }
}
