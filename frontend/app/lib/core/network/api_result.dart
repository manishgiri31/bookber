import 'package:dio/dio.dart';

import 'api_exception.dart';

sealed class ApiResult<T> {
  const ApiResult();

  static Future<ApiResult<T>> guard<T>(Future<T> Function() fn) async {
    try {
      final data = await fn();
      return ApiSuccess(data);
    } on ApiException catch (error) {
      return ApiError(error.message, code: error.code);
    } on DioException catch (error) {
      final apiException = ApiException.fromDioException(error);
      return ApiError(apiException.message, code: apiException.code);
    } catch (error) {
      return ApiError(error.toString(), code: 'UNKNOWN_ERROR');
    }
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;
}

class ApiError<T> extends ApiResult<T> {
  const ApiError(this.message, {this.code});

  final String message;
  final String? code;
}

class ApiFailure<T> extends ApiError<T> {
  const ApiFailure(super.message, {super.code});
}
