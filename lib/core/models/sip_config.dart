/// پیکربندی اتصال SIP
class SipConfig {
  final String sipServer;      // مثال: '192.168.1.100'
  final String sipPort;        // مثال: '8089'
  final String extension;      // مثال: '1008'
  final String password;       // رمز عبور داخلی
  final String? displayName;   // نام نمایشی (اختیاری)
  final bool autoAnswer;       // پاسخ خودکار (پیش‌فرض false)

  const SipConfig({
    required this.sipServer,
    required this.sipPort,
    required this.extension,
    required this.password,
    this.displayName,
    this.autoAnswer = false,
  });

  // برای ذخیره در SharedPreferences
  Map<String, dynamic> toJson() => {
    'sipServer': sipServer,
    'sipPort': sipPort,
    'extension': extension,
    'password': password,
    'displayName': displayName,
    'autoAnswer': autoAnswer,
  };

  factory SipConfig.fromJson(Map<String, dynamic> json) => SipConfig(
    sipServer: json['sipServer'] as String,
    sipPort: json['sipPort'] as String,
    extension: json['extension'] as String,
    password: json['password'] as String,
    displayName: json['displayName'] as String?,
    autoAnswer: json['autoAnswer'] as bool? ?? false,
  );

  SipConfig copyWith({
    String? sipServer,
    String? sipPort,
    String? extension,
    String? password,
    String? displayName,
    bool? autoAnswer,
  }) {
    return SipConfig(
      sipServer: sipServer ?? this.sipServer,
      sipPort: sipPort ?? this.sipPort,
      extension: extension ?? this.extension,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      autoAnswer: autoAnswer ?? this.autoAnswer,
    );
  }
}
