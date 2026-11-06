import 'package:commons/commons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:service/api/enum.dart';
import 'package:service/api/http_service_exception_model.dart';
import 'package:service/api/service_exception.dart';

class DioProvider {
  final Dio _dio = Dio();
  final Set<CancelToken> _activeCancelTokens = {};
  final Map<String, dynamic> bytes = {};
  final ApiCore _apiCore;
  final Map<String, String> _header;

  final String _url;

  DioProvider.of(this._apiCore)
    : _header = Header.getHeader(_apiCore.headerType),
      _url = (kReleaseMode ? _apiCore.prd : _apiCore.des) + _apiCore.endpoint;

  Future<Result<dynamic>> request({
    required Verb verb,
    Object? pathParam,
    Object? queryParam,
    Map<String, dynamic>? body,
    int timeout = 30,
  }) async {
    if (timeout <= 0) {
      throw ArgumentError.value(timeout, 'timeout', 'deveSerMaiorQueZero');
    }

    final stopWatch = Stopwatch()..start();
    final cancelToken = CancelToken();
    _activeCancelTokens.add(cancelToken);
    bytes.clear();
    var status = 500;

    try {
      if (verb == Verb.put && body == null) {
        return Result.error(
          HttpServiceException(exception: Exception('oCorpoDaRequisitacaoObrig'), message: 'oCorpoDaRequisitacaoObrig'),
        );
      }

      final duration = Duration(seconds: timeout);
      final options = Options(
        method: verb.name,
        headers: _header,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        followRedirects: false,
        connectTimeout: duration,
        sendTimeout: duration,
        receiveDataWhenStatusError: true,
        receiveTimeout: duration,
      );
      final uri = _buildUri(pathParam, queryParam);
      final response = await _dio.requestUri<dynamic>(
        uri,
        cancelToken: cancelToken,
        options: options,
        data: verb == Verb.post || verb == Verb.put ? _withoutNullValues(body) : null,
        onReceiveProgress: _receiveProgress,
        onSendProgress: _sendProgress,
      );
      status = response.statusCode ?? 500;
      return Result.ok(response.data);
    } on DioException catch (e) {
      Log.print(e, name: kApi);
      final response = e.response;
      status = response?.statusCode ?? 500;
      final responseData = response?.data;
      final responseModel = responseData is Map
          ? HttpServiceExceptionModel.fromJson(Map<String, dynamic>.from(responseData))
          : null;

      return Result.error(
        HttpServiceException(
          code: response?.statusCode,
          exception: e,
          message: responseModel?.message ?? _messageForException(e.type),
          debugMessage: responseData == null
              ? null
              : responseData is Map
              ? Map<String, dynamic>.from(responseData)
              : {'response': responseData},
        ),
      );
    } finally {
      _activeCancelTokens.remove(cancelToken);
      stopWatch.stop();
      Log.print(
        '${_apiCore.endpoint}, s: ${stopWatch.elapsed.inSeconds}, '
        'ms: ${stopWatch.elapsed.inMilliseconds}',
        title: 'Provider ${verb.name.toUpperCase()} $status',
        name: kApi,
      );
    }
  }

  void cancel() {
    for (final cancelToken in _activeCancelTokens.toList()) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel();
      }
    }
  }

  Uri _buildUri(Object? pathParam, Object? queryParam) {
    final baseUri = Uri.parse(_url);
    final path = pathParam == null ? baseUri.path : '${baseUri.path}/$pathParam';
    if (queryParam == null) {
      return baseUri.replace(path: path);
    }

    if (queryParam is Map) {
      final queryParameters = <String, String>{};
      for (final entry in queryParam.entries) {
        final key = entry.key;
        if (key is! String) {
          throw ArgumentError.value(queryParam, 'queryParam', 'queryParamStrings');
        }
        if (entry.value != null) {
          queryParameters[key] = entry.value.toString();
        }
      }
      return baseUri.replace(path: path, queryParameters: queryParameters);
    }

    if (queryParam is String) {
      final query = queryParam.startsWith('?') ? queryParam.substring(1) : queryParam;
      return baseUri.replace(path: path, query: query);
    }

    throw ArgumentError.value(queryParam, 'queryParam', 'queryParamStringsMap');
  }

  void _receiveProgress(int count, int total) {
    bytes['download'] = {'count': count, 'total': total};
  }

  void _sendProgress(int count, int total) {
    bytes['upload'] = {'count': count, 'total': total};
  }

  Map<String, dynamic>? _withoutNullValues(Map<String, dynamic>? body) {
    if (body == null) {
      return null;
    }
    return Map<String, dynamic>.fromEntries(body.entries.where((entry) => entry.value != null));
  }

  String _messageForException(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout => 'connectionTimeout',
      DioExceptionType.sendTimeout => 'sendTimeout',
      DioExceptionType.receiveTimeout => 'receiveTimeout',
      DioExceptionType.transformTimeout => 'transformTimeout',
      DioExceptionType.badCertificate => 'badCertificate',
      DioExceptionType.badResponse => 'badResponse',
      DioExceptionType.connectionError => 'connectionError',
      DioExceptionType.unknown => 'unknown',
      DioExceptionType.cancel => 'cancel',
    };
  }
}
