import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'storage_service.dart';

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleDriveService {
  GoogleDriveService._();
  static final GoogleDriveService instance = GoogleDriveService._();

  drive.DriveApi? _driveApi;
  bool _initialized = false;

  static const List<String> _scopes = <String>[
    drive.DriveApi.driveFileScope,
  ];

  Future<void> _ensureAuthenticated() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    }

    final headers = await _obtainAuthHeaders();
    final authClient = _GoogleAuthClient(headers);
    _driveApi = drive.DriveApi(authClient);
  }

  Future<Map<String, String>> _obtainAuthHeaders() async {
    final directClient = GoogleSignIn.instance.authorizationClient;
    final existingHeaders = await directClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: false,
    );
    if (existingHeaders != null) {
      return existingHeaders;
    }

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Interactive Google authentication is not supported.');
    }

    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: _scopes,
    );

    final authorizationClient = account.authorizationClient;
    final headers = await authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: true,
    );

    if (headers == null) {
      throw Exception('Unable to authorize Google Drive access');
    }

    return headers;
  }

  Future<String> backupAlarms(List<Map<String, dynamic>> alarms) async {
    await _ensureAuthenticated();

    if (_driveApi == null) {
      throw Exception('Drive API not initialized');
    }

    final file = drive.File()
      ..name = 'alarm_backup_${DateTime.now().toIso8601String()}.json'
      ..mimeType = 'application/json';

    final data = utf8.encode(jsonEncode(alarms));
    final media = drive.Media(
      Stream<List<int>>.fromIterable(<List<int>>[data]),
      data.length,
    );

    final uploaded = await _driveApi!.files.create(
      file,
      uploadMedia: media,
    );

    final fileId = uploaded.id;
    if (fileId != null) {
      await StorageService.setLastBackupFileId(fileId);
      await StorageService.setLastBackupTime(DateTime.now());
    }

    return fileId ?? '';
  }

  Future<List<Map<String, dynamic>>> restoreLatestBackup() async {
    await _ensureAuthenticated();

    if (_driveApi == null) {
      throw Exception('Drive API not initialized');
    }

    String? fileId = StorageService.lastBackupFileId;

    if (fileId == null) {
      final files = await _driveApi!.files.list(
        q: "mimeType='application/json' and name contains 'alarm_backup_'",
        orderBy: 'createdTime desc',
        pageSize: 1,
        spaces: 'drive',
      );

      final latest = files.files?.firstWhere(
        (_) => true,
        orElse: () => drive.File(),
      );

      fileId = latest?.id;
    }
    if (fileId == null) {
      throw Exception('No backup found in Drive');
    }

    final media = await _driveApi!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = await media.stream.fold<List<int>>(
      <int>[],
      (previous, element) => previous..addAll(element),
    );

    final jsonData = jsonDecode(utf8.decode(bytes));

    if (jsonData is List) {
      return jsonData.cast<Map<String, dynamic>>();
    }

    throw Exception('Invalid backup format');
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();
}

