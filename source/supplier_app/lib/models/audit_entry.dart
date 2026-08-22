/// One row of the local business-configuration audit trail
/// (Requirements/DISCUSSION_Business_Field_Editing.md §7).
///
/// Deliberately no "old value" field - only the new value, timestamp,
/// property/event name, and the app version that made the change. The
/// previous value for any given [propertyName] is simply whatever the
/// prior row for that same name recorded.
class AuditEntry {
  final int? id;
  final String businessId;
  final DateTime timestamp;
  final String propertyName;
  final String? newValue;
  final String appVersion;

  const AuditEntry({
    this.id,
    required this.businessId,
    required this.timestamp,
    required this.propertyName,
    this.newValue,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'business_id': businessId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'property_name': propertyName,
        'new_value': newValue,
        'app_version': appVersion,
      };

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: json['id'] as int?,
        businessId: json['business_id'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        propertyName: json['property_name'] as String,
        newValue: json['new_value'] as String?,
        appVersion: json['app_version'] as String,
      );
}

/// Canonical `propertyName` values, so every call site logs the same
/// string for the same kind of change - avoids the drift that comes from
/// each caller hand-typing its own label.
class AuditProperty {
  AuditProperty._();

  static const String businessName = 'Business Name';
  static const String icon = 'Icon';
  static const String brandColor = 'Brand Color';
  static const String stampsRequired = 'Stamps Required';
  static const String operationMode = 'Operation Mode';
  static const String scanCooldown = 'Scan Cooldown';

  static const String recoveryBackupCreated = 'Recovery Backup Created';
  static const String cloneQrGenerated = 'Clone QR Generated';
  static const String restoredFromBackup = 'Restored from Backup';
  static const String configuredViaClone = 'Configured via Clone';

  /// The set of fields logged as a batch of "initial value" rows, both at
  /// genuine fresh setup and at restore/clone-receive time (§7.1 - a
  /// restore/clone-receive is just a new starting point, same shape as
  /// initial setup).
  static const List<String> profileFields = [
    businessName,
    icon,
    brandColor,
    stampsRequired,
    operationMode,
    scanCooldown,
  ];
}
