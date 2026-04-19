import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploadService {
  CloudinaryUploadService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String _defaultUploadFolder = 'imports';

  Future<String> uploadExcelBackup({
    required String userId,
    required Uint8List fileBytes,
    required int timestamp,
  }) async {
    final cloudName = _readRequiredConfig('CLOUDINARY_CLOUD_NAME');
    final uploadPreset = _readRequiredConfig('CLOUDINARY_UPLOAD_PRESET');
    final baseFolder = _normalizeFolderPath(
      _readOptionalConfig('CLOUDINARY_UPLOAD_FOLDER') ?? _defaultUploadFolder,
    );
    final normalizedUserId = _normalizeFolderSegment(userId);

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = '$baseFolder/$normalizedUserId'
      ..fields['public_id'] = timestamp.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: '$timestamp.xlsx',
        ),
      );

    final response = await _client.send(request);
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractCloudinaryErrorMessage(body);
      throw Exception(message ?? 'Unable to upload Excel backup file');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unable to upload Excel backup file');
    }

    final secureUrl = decoded['secure_url']?.toString().trim();
    if (secureUrl != null && secureUrl.isNotEmpty) {
      return secureUrl;
    }

    final publicId = decoded['public_id']?.toString().trim();
    if (publicId != null && publicId.isNotEmpty) {
      return publicId;
    }

    throw Exception('Unable to upload Excel backup file');
  }

  String _readRequiredConfig(String key) {
    final value = _readOptionalConfig(key);
    if (value != null && value.isNotEmpty) {
      return value;
    }

    throw Exception('$key is missing. Configure Cloudinary in lib/Assets/.env');
  }

  String? _readOptionalConfig(String key) {
    final fromDotenv = dotenv.env[key]?.trim();
    if (fromDotenv != null && fromDotenv.isNotEmpty) {
      return fromDotenv;
    }

    final fromDefine = _readFromEnvironment(key);
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    return null;
  }

  String _readFromEnvironment(String key) {
    switch (key) {
      case 'CLOUDINARY_CLOUD_NAME':
        return const String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
      case 'CLOUDINARY_UPLOAD_PRESET':
        return const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
      case 'CLOUDINARY_UPLOAD_FOLDER':
        return const String.fromEnvironment('CLOUDINARY_UPLOAD_FOLDER');
      default:
        return '';
    }
  }

  String _normalizeFolderPath(String folder) {
    final cleaned = folder.trim().replaceAll('\\', '/');
    final withoutEdgeSlashes = cleaned.replaceAll(RegExp(r'^/+|/+$'), '');
    if (withoutEdgeSlashes.isEmpty) {
      return _defaultUploadFolder;
    }

    return withoutEdgeSlashes;
  }

  String _normalizeFolderSegment(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (cleaned.isEmpty) {
      return 'unknown_user';
    }

    return cleaned;
  }

  String? _extractCloudinaryErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
