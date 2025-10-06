import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class ApiService {
  final String base = 'https://api.dev.kpi-drive.ru';// base link
  final String token; // token
// Declare the client  for unit test
  final http.Client _client;

  //  constructor to inject the client
  // here I added  client for unit test
  ApiService({required this.token, http.Client? client})
      : _client = client ?? http.Client();
  /// Получение всех задач
  Future<List<TaskModel>> fetchTasks({
    required String periodStart,
    required String periodEnd,
    required String periodKey,
    required int requestedMoId,
    required int authUserId,
  }) async {
    //URL API для извлечения задач
    final url = Uri.parse('$base/_api/indicators/get_mo_indicators');

    final resp = await _client.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'period_start': periodStart,
        'period_end': periodEnd,
        'period_key': periodKey,
        'requested_mo_id': requestedMoId.toString(),
        'behaviour_key': 'task,kpi_task',
        'with_result': 'false',
        'response_fields': 'name,indicator_to_mo_id,parent_id,order',
        'auth_user_id': authUserId.toString(),
      },
    );
    //
    if (resp.statusCode != 200) {
      throw Exception('fetch Tasks failed: ${resp.statusCode} ${resp.body}');
    }

    final decoded = json.decode(resp.body);

    List<dynamic> listData = [];
    //
    if (decoded is Map) {
      final data = decoded['DATA'];
      if (data is Map && data['rows'] is List) {
        listData = data['rows'];
      } else if (data is List) {
        listData = data;
      } else if (decoded['rows'] is List) {
        listData = decoded['rows'];
      }
    }

    if (listData.isEmpty) {
      return [];
    }

    // data maping
    return listData.map((item) {
      return TaskModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }


  /// Сохранение изменений.
  Future<bool> saveTaskUpdate({
    required String periodStart,
    required String periodEnd,
    required String periodKey,
    required int indicatorToMoId,
    required int newParentId,
    required int newOrder,
    required int authUserId,

  }) async {


    final url = Uri.parse('$base/_api/indicators/save_indicator_instance_field');

    developer.log(
      'API called with: '
          'period_start: $periodStart, '
          'period_end: $periodEnd, '
          'period_key: $periodKey, '
          'indicator_to_mo_id: $indicatorToMoId, '
          'toParentId: $newParentId, '
          'auth_user_id: $authUserId, '
          'toIndex: $newOrder',
      name: 'KanbanProvider',
    );

    try {
      final req = http.MultipartRequest('POST', url);
      req.headers['Authorization'] = 'Bearer $token';

      final List<http.MultipartFile> files = [
        // Single-entry fields
        http.MultipartFile.fromString('period_start', periodStart),
        http.MultipartFile.fromString('period_end', periodEnd),
        http.MultipartFile.fromString('period_key', periodKey),
        http.MultipartFile.fromString('indicator_to_mo_id', indicatorToMoId.toString()),
        http.MultipartFile.fromString('auth_user_id', authUserId.toString()),

        // Повторяющиеся поля: обновление parent_id
        http.MultipartFile.fromString('field_name', 'parent_id'),
        http.MultipartFile.fromString('field_value', newParentId.toString()),

        // Повторяющиеся поля: обновление заказа
        http.MultipartFile.fromString('field_name', 'order'),
        http.MultipartFile.fromString('field_value', newOrder.toString()),
      ];

      // Добавить все поля формы в список файлов запроса
      req.files.addAll(files);

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        developer.log('saveTaskUpdate successful.', name: 'saveTaskUpdate');
        return true;
      } else {
        developer.log('saveTaskUpdate FAILED: ${streamed.statusCode} -> $body', name: 'saveTaskUpdate', error: true);
        throw Exception('saveTaskUpdate failed: ${streamed.statusCode} -> $body');
      }
    } catch (e) {
      developer.log('saveTaskUpdate EXCEPTION: $e', name: 'saveTaskUpdate', error: true);
      // rethrow as boolean failure
      return false;
    }
  }

}
