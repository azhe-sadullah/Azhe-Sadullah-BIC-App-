library;
import 'package:dio/dio.dart';

class ApiService {
  late Dio _dio;
  
  final String baseUrl = "http://10.0.2.2:8000/api";

  ApiService() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        return status! < 500;
      }
    );
    _dio = Dio(options);
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Dio get client => _dio;
}
