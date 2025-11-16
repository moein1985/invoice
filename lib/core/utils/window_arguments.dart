import 'dart:convert';

/// Types of secondary windows used inside the desktop application.
enum AppWindowType { main, preview }

/// Encapsulates the payload we pass to secondary Flutter windows.
class AppWindowArguments {
  final AppWindowType type;
  final String? documentId;
  final Map<String, dynamic>? documentData;
  final Map<String, dynamic>? customerData;

  const AppWindowArguments._(this.type, {this.documentId, this.documentData, this.customerData});

  const AppWindowArguments.main() : this._(AppWindowType.main);

  const AppWindowArguments.preview({
    required String documentId,
    required Map<String, dynamic> documentData,
    Map<String, dynamic>? customerData,
  }) : this._(AppWindowType.preview, documentId: documentId, documentData: documentData, customerData: customerData);

  bool get isPreview => type == AppWindowType.preview && documentId?.isNotEmpty == true;

  /// Serializes this object to the string that gets passed to new windows.
  String encode() {
    return jsonEncode({
      'type': type.name,
      if (documentId != null) 'documentId': documentId,
      if (documentData != null) 'documentData': documentData,
      if (customerData != null) 'customerData': customerData,
    });
  }

  /// Parses the raw string provided by [WindowController.arguments].
  factory AppWindowArguments.decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const AppWindowArguments.main();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final typeValue = map['type'] as String?;
      if (typeValue == AppWindowType.preview.name) {
        final docId = map['documentId'] as String?;
        final docData = map['documentData'] as Map<String, dynamic>?;
        if (docId != null && docId.isNotEmpty && docData != null) {
          return AppWindowArguments.preview(
            documentId: docId,
            documentData: docData,
            customerData: map['customerData'] as Map<String, dynamic>?,
          );
        }
      }
    } catch (_) {
      // Ignore malformed arguments and fall back to main window behaviour.
    }
    return const AppWindowArguments.main();
  }
}
