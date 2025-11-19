/// اطلاعات تماس فعال
class CallInfo {
  final String callId;
  final String callerNumber;
  final String? callerName;
  final DateTime startTime;
  final CallDirection direction;
  final CallStatus status;

  const CallInfo({
    required this.callId,
    required this.callerNumber,
    this.callerName,
    required this.startTime,
    required this.direction,
    required this.status,
  });

  CallInfo copyWith({
    String? callId,
    String? callerNumber,
    String? callerName,
    DateTime? startTime,
    CallDirection? direction,
    CallStatus? status,
  }) {
    return CallInfo(
      callId: callId ?? this.callId,
      callerNumber: callerNumber ?? this.callerNumber,
      callerName: callerName ?? this.callerName,
      startTime: startTime ?? this.startTime,
      direction: direction ?? this.direction,
      status: status ?? this.status,
    );
  }

  // محاسبه مدت زمان تماس
  Duration get duration => DateTime.now().difference(startTime);
}

enum CallDirection {
  incoming,  // تماس ورودی
  outgoing,  // تماس خروجی
}

enum CallStatus {
  ringing,    // در حال زنگ خوردن
  connecting, // در حال اتصال
  connected,  // متصل شده
  ended,      // قطع شده
  failed,     // ناموفق
}
