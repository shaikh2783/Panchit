import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/network/api_exception.dart';

class ApiClient {
  ApiClient({required AppConfig config, http.Client? httpClient})
    : _config = config,
      _httpClient = httpClient ?? http.Client();

  final AppConfig _config;
  final http.Client _httpClient;
  String? _authToken;

  void updateAuthToken(String? token) {
    _authToken = token;
  }

  Future<Map<String, dynamic>> post(
    String relativePath, {
    Map<String, dynamic>? body,
    dynamic data, // Added for compatibility with ProfileUpdateService
    Map<String, String>? headers,
    bool asJson = true,
  }) async {
    // Use data if provided, otherwise use body
    final requestBody = data ?? body;

    final uri = _buildUri(relativePath);
    if (requestBody != null) {
      final encoded = jsonEncode(requestBody);
      final preview = encoded.length > 300
          ? '${encoded.substring(0, 300)}...'
          : encoded;
    } else {
    }

    final response = await _httpClient.post(
      uri,
      headers: _buildHeaders(headers, asJson: asJson),
      body: _encodeBody(requestBody, asJson: asJson),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String relativePath, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool asJson = true,
  }) async {
    final uri = _buildUri(relativePath);
    if (body != null) {
      final encoded = jsonEncode(body);
      final preview = encoded.length > 300
          ? '${encoded.substring(0, 300)}...'
          : encoded;
    } else {
    }

    final response = await _httpClient.put(
      uri,
      headers: _buildHeaders(headers, asJson: asJson),
      body: _encodeBody(body, asJson: asJson),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartPost(
    String relativePath, {
    required Map<String, String> body,
    required String filePath,
    required String fileFieldName,
    MediaType? contentType,
    void Function(int sentBytes, int totalBytes)? onProgress,
    String? fileName,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(relativePath))
      ..headers.addAll(_buildHeaders({}, asJson: false))
      ..fields.addAll(body);

    // Prepare streaming upload to report progress
    final file = File(filePath);
    final total = await file.length();

    // Stream transformer to report progress while reading file content
    int sent = 0;
    final progressTransformer =
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            sent += chunk.length;
            if (onProgress != null) {
              onProgress(sent, total);
            }
            sink.add(chunk);
          },
        );

    final stream = http.ByteStream(
      file.openRead().transform(progressTransformer),
    );
    final multipartFile = http.MultipartFile(
      fileFieldName,
      stream,
      total,
      filename: fileName ?? _basename(filePath),
      contentType: contentType,
    );

    request.files.add(multipartFile);

    final response = await _httpClient.send(request);
    return _handleResponse(await http.Response.fromStream(response));
  }

  Future<Map<String, dynamic>> get(
    String relativePath, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.get(
      _buildUri(relativePath, queryParameters: queryParameters),
      headers: _buildHeaders(headers, asJson: true),
    );
    return _handleResponse(response);
  }

  /// GET request without authentication
  Future<Map<String, dynamic>> getPublic(
    String relativePath, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.get(
      _buildUri(relativePath, queryParameters: queryParameters),
      headers: _buildPublicHeaders(headers),
    );
    return _handleResponse(response);
  }

  Map<String, String> _buildPublicHeaders(Map<String, String>? extra) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final hmac = Hmac(sha256, utf8.encode(_config.apiSecret));
    final signature = hmac.convert(utf8.encode(timestamp)).toString();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-key': _config.apiKey,
      'x-timestamp': timestamp,
      'x-signature': signature,
      // No x-auth-token for public endpoints
      if (extra != null) ...extra,
    };
  }

  Map<String, String> _buildHeaders(
    Map<String, String>? extra, {
    required bool asJson,
  }) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final hmac = Hmac(sha256, utf8.encode(_config.apiSecret));
    final signature = hmac.convert(utf8.encode(timestamp)).toString();

    return {
      if (asJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-key': _config.apiKey,
      'x-timestamp': timestamp,
      'x-signature': signature,
      if (_authToken != null && _authToken!.isNotEmpty)
        'x-auth-token': _authToken!,
      if (extra != null) ...extra,
    };
  }

  Uri _buildUri(String relativePath, {Map<String, String>? queryParameters}) {
    final baseUri = _config.endpoint(relativePath);
    if (queryParameters == null || queryParameters.isEmpty) {
      return baseUri;
    }
    final mergedQuery = {...baseUri.queryParameters, ...queryParameters};
    return baseUri.replace(queryParameters: mergedQuery);
  }

  Object? _encodeBody(Map<String, dynamic>? body, {required bool asJson}) {
    if (body == null) {
      return null;
    }
    if (asJson) {
      return jsonEncode(body);
    }
    return body.map(
      (key, value) => MapEntry(key, value == null ? '' : value.toString()),
    );
  }

  Map<String, dynamic> _handleResponse(http.Response response) {


    final decodedBody = _safeDecodeBody(response.body);
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (isSuccess) {
      if (decodedBody == null) {
        return const {};
      }
      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      }
      return {'data': decodedBody};
    }

    final message =
        _extractErrorMessage(decodedBody) ??
        'Unexpected error from API (${response.statusCode})';
    throw ApiException(
      message,
      statusCode: response.statusCode,
      details: decodedBody,
    );
  }

  Object? _safeDecodeBody(String body) {
    if (body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String? _extractErrorMessage(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      final candidates = [
        decoded['message'],
        decoded['error'],
        decoded['status_text'],
        decoded['detail'],
      ];
      return candidates.firstWhere(
            (element) => element is String && element.isNotEmpty,
            orElse: () => null,
          )
          as String?;
    }
    if (decoded is String && decoded.isNotEmpty) {
      return decoded;
    }
    return null;
  }

  void dispose() {
    _httpClient.close();
  }

  String _basename(String path) {
    if (path.isEmpty) return '';
    final idx = path.lastIndexOf('/');
    if (idx == -1) return path;
    return path.substring(idx + 1);
  }
}
