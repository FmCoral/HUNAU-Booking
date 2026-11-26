/// 通知消息数据模型（与牛×5 一致）
class MessageModel {
  final String idCode;
  final String title;
  final String content;
  final String createrName;
  final String sendTime;
  final bool isRead;
  final bool hasRedDot;
  final String uuid;

  const MessageModel({
    required this.idCode,
    required this.title,
    required this.content,
    required this.createrName,
    required this.sendTime,
    required this.isRead,
    required this.hasRedDot,
    this.uuid = '',
  });

  factory MessageModel.fromChaoxingJson(Map<String, dynamic> json) {
    final insertTime = json['insertTime'] as int? ?? 0;
    final dateTime = insertTime > 0
        ? DateTime.fromMillisecondsSinceEpoch(insertTime)
        : DateTime.now();
    final sendTimeStr =
        '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    final isReadValue = json['isread'] as int? ?? 0;

    return MessageModel(
      idCode: json['idCode'] as String? ?? '',
      title: _extractTitle(json),
      content: json['content'] as String? ?? '',
      createrName: json['createrName'] as String? ?? '',
      sendTime: sendTimeStr,
      isRead: isReadValue == 1,
      hasRedDot: isReadValue == 0,
      uuid: json['uuid'] as String? ?? '',
    );
  }

  static String _extractTitle(Map<String, dynamic> json) {
    final attachment = json['attachment'] as String?;
    if (attachment != null && attachment.isNotEmpty) {
      final match = RegExp(r'"title"\s*:\s*"([^"]+)"').firstMatch(attachment);
      if (match?.group(1) != null) return match!.group(1)!;
    }

    final content = json['content'] as String? ?? '';
    if (content.isNotEmpty) {
      final lines = content.split('\r\n');
      if (lines.isNotEmpty && lines[0].isNotEmpty) {
        final firstLine = lines[0];
        return firstLine.length > 50
            ? '${firstLine.substring(0, 50)}...'
            : firstLine;
      }
    }
    return '无标题';
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}

/// 通知列表请求结果（支持分页）
class NoticeResult {
  final List<MessageModel> messages;
  final String? nextLastValue;
  final bool hasMore;

  NoticeResult({
    required this.messages,
    this.nextLastValue,
    this.hasMore = true,
  });
}
