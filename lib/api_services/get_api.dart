import 'package:dio/dio.dart';
import 'package:tasks_project/pages/property/model/property_model.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://147.182.207.192:8003",
      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 20),
    ),
  );

  Future<PropertyResponseModel> getProperties({
    required int page,
    int pageSize = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _dio.get(
        "/properties",
        queryParameters: {
          "page": page,
          "page_size": pageSize,
          ...?filters, // 🔥 Supports filters
        },
      );

      return PropertyResponseModel.fromJson(response.data);
    } catch (e) {
      print("❌ API ERROR: $e");
      rethrow;
    }
  }
}
