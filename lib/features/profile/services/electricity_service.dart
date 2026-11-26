import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_logger.dart';
import '../models/electricity_model.dart';
import 'campus_card_service.dart';

/// 宿舍配置变更通知：保存/清除宿舍后自增，供「我」页刷新余额。
final ValueNotifier<int> electricityRevision = ValueNotifier<int>(0);

/// 宿舍电费服务。
///
/// 接口与牛×5 完全一致：共用校园卡的 fin-serv 会话与 DKYW 加密 POST。
class ElectricityService {
  ElectricityService._();

  static final ElectricityService instance = ElectricityService._();

  final _logger = AppLogger.instance;

  static const String _finServBase = 'https://fin-serv.hunau.edu.cn';
  static const String _factoryCode = 'E013';

  static String _roomKey(int slot) =>
      slot == 0 ? 'saved_electricity_room' : 'saved_electricity_room_${slot + 1}';

  static String _balanceKey(int slot) => slot == 0
      ? 'saved_electricity_balance_info'
      : 'saved_electricity_balance_info_${slot + 1}';

  Future<List<ElectricityArea>> getAreas() async {
    final data = await CampusCardService.instance.postEncrypted(
      '$_finServBase/channel/getXiaoQuList',
      {'factorycode': _factoryCode},
    );
    return _extractList(data, const ['schoolList', 'schoollist'])
        .map((e) => ElectricityArea.fromJson(e))
        .toList();
  }

  Future<List<ElectricityBuilding>> getBuildings(String areaName) async {
    final data = await CampusCardService.instance.postEncrypted(
      '$_finServBase/channel/queryBuildingList',
      {'factorycode': _factoryCode, 'schoolid': areaName},
    );
    return _extractList(data, const ['buildingList', 'buildinglist'])
        .map((e) => ElectricityBuilding.fromJson(e))
        .toList();
  }

  Future<List<ElectricityRoom>> getRooms(
    String areaName,
    String buildingName,
  ) async {
    final data = await CampusCardService.instance.postEncrypted(
      '$_finServBase/channel/queryRoomList',
      {
        'factorycode': _factoryCode,
        'schoolid': areaName,
        'buildingid': buildingName,
      },
    );
    return _extractList(data, const ['roomList', 'roomlist'])
        .map((e) => ElectricityRoom.fromJson(e))
        .toList();
  }

  /// 查询宿舍电费余额。
  Future<ElectricityBalanceInfo> getBalance(
    SavedElectricityRoom room, {
    int slot = 0,
  }) async {
    await _warmElePay();

    final data = await CampusCardService.instance.postEncrypted(
      '$_finServBase/channel/queryEleAccDetail',
      {
        'schoolid': room.areaName,
        'buildingid': room.buildingName,
        'roomid': room.roomId,
        'mertype': room.mertype,
        'factorycode': _factoryCode,
      },
    );

    if (data is Map && data['success'] == false) {
      throw Exception((data['message'] ?? data['msg'] ?? '获取电费余额失败').toString());
    }

    final Map<String, dynamic> result;
    if (data is Map && data['resultData'] is Map) {
      result = Map<String, dynamic>.from(data['resultData'] as Map);
    } else if (data is Map) {
      result = Map<String, dynamic>.from(data);
    } else {
      throw Exception('电费余额返回格式异常');
    }

    final info = ElectricityBalanceInfo.fromJson(result);
    await _saveBalance(room, info, slot: slot);
    return info;
  }

  /// 使用校园卡支付宿舍电费，逻辑与牛×5 一致。
  Future<bool> recharge({
    required SavedElectricityRoom room,
    required double amount,
  }) async {
    var info = CampusCardService.instance.cached;
    info ??= await CampusCardService.instance.refresh();
    final openid = CampusCardService.instance.openid;
    if (openid == null || openid.isEmpty) {
      throw Exception('授权已失效，请重新打开校园卡');
    }

    // 记录最后使用的房间
    await CampusCardService.instance.postEncrypted(
      '$_finServBase/myaccount/userlastbind',
      {
        'payinfo': {'elepayWay': '2'},
        'eleinfo': {
          'schoolid': room.areaName,
          'buildingid': room.buildingName,
          'roomid': room.roomId,
          'factorycode': _factoryCode,
        },
        'idserial': info.idserial,
      },
    );

    // 发起预交易
    final data = await CampusCardService.instance.postEncrypted(
      '$_finServBase/elepay/createPreThirdTrade',
      {
        'payamt': amount.toStringAsFixed(0),
        'openid': openid,
        'idserial': info.idserial,
        'factorycode': _factoryCode,
        'buildingid': room.buildingName,
        'roomid': room.roomId,
        'schoolid': room.areaName,
        'payWay': '2',
        'mertype': room.mertype,
      },
    );

    _logger.i('⚡ electricity recharge response: $data');
    if (data is Map) {
      return data['success'] == true ||
          data['success'] == 'true' ||
          data['code'] == '0' ||
          data['code'] == 0 ||
          (data.containsKey('resultData') && data['resultData'] != null);
    }
    return false;
  }

  /// 打开电费页建立会话，与牛×5 一致。
  Future<void> _warmElePay() async {
    try {
      await CampusCardService.instance.getFinServ(
        '/elepay/openElePay',
        query: {'displayflag': '1', 'id': '30'},
      );
    } catch (e) {
      _logger.w('Ele pay warmup failed: $e');
    }
  }

  Future<SavedElectricityRoom?> loadSavedRoom({int slot = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_roomKey(slot));
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      if (data is Map) {
        return SavedElectricityRoom.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (e) {
      _logger.w('Failed to load saved dorm room: $e');
    }
    return null;
  }

  Future<ElectricityBalanceInfo?> loadCachedBalance({int slot = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_balanceKey(slot));
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      if (data is Map) {
        return ElectricityBalanceInfo.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (e) {
      _logger.w('Failed to load cached electricity balance: $e');
    }
    return null;
  }

  Future<void> saveRoom(SavedElectricityRoom room, {int slot = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roomKey(slot), jsonEncode(room.toJson()));
    await prefs.remove(_balanceKey(slot));
    electricityRevision.value++;
  }

  Future<void> clearRoom({int slot = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roomKey(slot));
    await prefs.remove(_balanceKey(slot));
    electricityRevision.value++;
  }

  /// 退出登录时清除所有宿舍配置与余额缓存。
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (var slot = 0; slot < 2; slot++) {
      await prefs.remove(_roomKey(slot));
      await prefs.remove(_balanceKey(slot));
    }
    electricityRevision.value++;
  }

  Future<void> _saveBalance(
    SavedElectricityRoom room,
    ElectricityBalanceInfo info, {
    int slot = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _balanceKey(slot),
        jsonEncode({'roomId': room.roomId, ...info.toJson()}),
      );
    } catch (_) {
      // 缓存失败不影响展示
    }
  }

  List<Map<String, dynamic>> _extractList(
    dynamic data,
    List<String> keys,
  ) {
    List? list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final result = data['resultData'];
      if (result is List) {
        list = result;
      } else if (result is Map) {
        for (final key in keys) {
          final value = result[key];
          if (value is List) {
            list = value;
            break;
          }
        }
      }
      list ??= data['data'] is List ? data['data'] as List : null;
    }
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
