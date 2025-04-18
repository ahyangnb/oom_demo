import 'package:dio/dio.dart';
import 'dart:async';

typedef NetErrorCallback = Function(String code, String msg);
typedef NetDownloadCompletionCallback = Function(Response data);

class VapDioUtils {
  factory VapDioUtils() => _singleton;

  static VapDioUtils get instance => VapDioUtils();
  static late Dio _dio;

  Dio get dio => _dio;

  VapDioUtils._() {
    _dio = Dio();
  }

  static final VapDioUtils _singleton = VapDioUtils._();

  Future<Response> downloadGeneral(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    required NetDownloadCompletionCallback? onCompletion,
    NetErrorCallback? onError,
  }) {
    Future<Response> response = _dio.download(
      url,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
    response.then((value) {
      onCompletion?.call(value);
    }).onError((error, stackTrace) {
      onError?.call("-1", error.toString());
    });
    return response;
  }
}
