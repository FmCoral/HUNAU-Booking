/// 电费（宿舍）相关数据模型，与牛×5 保持一致。
class ElectricityArea {
  const ElectricityArea({required this.id, required this.name});

  final String id;
  final String name;

  factory ElectricityArea.fromJson(Map<String, dynamic> json) {
    final name =
        (json['xiaoqu'] ?? json['schoolname'] ?? json['schoolid'] ?? '')
            .toString();
    return ElectricityArea(id: name, name: name);
  }
}

class ElectricityBuilding {
  const ElectricityBuilding({required this.id, required this.name});

  final String id;
  final String name;

  factory ElectricityBuilding.fromJson(Map<String, dynamic> json) {
    final name = (json['buildingname'] ??
            json['buildname'] ??
            json['buildingid'] ??
            json['buildid'] ??
            '')
        .toString();
    final id = (json['buildingid'] ?? json['buildid'] ?? name).toString();
    return ElectricityBuilding(id: id, name: name);
  }
}

class ElectricityRoom {
  const ElectricityRoom({
    required this.id,
    required this.name,
    required this.mertype,
  });

  final String id;
  final String name;
  final String mertype;

  factory ElectricityRoom.fromJson(Map<String, dynamic> json) {
    final name = (json['roomname'] ?? json['roomid'] ?? '').toString();
    final id = (json['roomid'] ?? name).toString();
    final mertype = (json['mertype'] ?? 'yk').toString();
    return ElectricityRoom(id: id, name: name, mertype: mertype);
  }
}

class ElectricityBalanceInfo {
  const ElectricityBalanceInfo({
    required this.balance,
    this.detail,
    this.accname,
    this.elestatus,
  });

  final String balance;
  final String? detail;
  final String? accname;
  final int? elestatus;

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'detail': detail,
        'accname': accname,
        'elestatus': elestatus,
      };

  factory ElectricityBalanceInfo.fromJson(Map<String, dynamic> json) {
    final balanceVal = json['eledetail'] ??
        json['balance'] ??
        json['elebalance'] ??
        json['syje'] ??
        json['ye'] ??
        json['remainElec'] ??
        json['remainelec'] ??
        json['restmoney'] ??
        json['elec_balance'] ??
        '0.00';
    final accnameVal =
        (json['accname'] ?? json['roomname'] ?? json['roomdesc'])?.toString();
    final detailVal =
        (json['eleaccdetail'] ?? json['detail'] ?? accnameVal)?.toString();
    final statusVal = json['elestatus'] is int
        ? json['elestatus'] as int
        : int.tryParse(json['elestatus']?.toString() ?? '');

    return ElectricityBalanceInfo(
      balance: balanceVal.toString(),
      detail: detailVal,
      accname: accnameVal,
      elestatus: statusVal,
    );
  }
}

/// 已选择的宿舍（电费房间）。
class SavedElectricityRoom {
  const SavedElectricityRoom({
    required this.areaName,
    required this.buildingName,
    required this.roomId,
    required this.roomName,
    required this.mertype,
  });

  final String areaName;
  final String buildingName;
  final String roomId;
  final String roomName;
  final String mertype;

  Map<String, dynamic> toJson() => {
        'areaName': areaName,
        'buildingName': buildingName,
        'roomId': roomId,
        'roomName': roomName,
        'mertype': mertype,
      };

  factory SavedElectricityRoom.fromJson(Map<String, dynamic> json) =>
      SavedElectricityRoom(
        areaName: (json['areaName'] ?? '').toString(),
        buildingName: (json['buildingName'] ?? '').toString(),
        roomId: (json['roomId'] ?? '').toString(),
        roomName: (json['roomName'] ?? json['roomId'] ?? '').toString(),
        mertype: (json['mertype'] ?? 'yk').toString(),
      );
}
