import 'package:shared/shared.dart';
import '../models/audit_entry.dart';
import 'supplier_database_helper.dart';

/// Repository for the local business-configuration audit trail
/// (Requirements/DISCUSSION_Business_Field_Editing.md §7). Local to this
/// device only - never synced, never included in a backup/clone payload.
class AuditTrailRepository {
  final SupplierDatabaseHelper _dbHelper = SupplierDatabaseHelper();

  /// Log a single event/field change. [newValue] is nullable - an event
  /// marker (e.g. [AuditProperty.recoveryBackupCreated]) may not have a
  /// meaningful "value" of its own.
  Future<void> logEntry({
    required String businessId,
    required String propertyName,
    String? newValue,
  }) async {
    final db = await _dbHelper.database;
    final entry = AuditEntry(
      businessId: businessId,
      timestamp: DateTime.now(),
      propertyName: propertyName,
      newValue: newValue,
      appVersion: appVersion,
    );
    await db.insert('audit_trail', entry.toJson());
  }

  /// Logs one row per tracked profile field - used both at genuine fresh
  /// setup and at restore/clone-receive time, which are the same shape
  /// from the audit trail's perspective (§7.1: a restore/clone-receive is
  /// just a new starting point).
  Future<void> logProfileSnapshot({
    required String businessId,
    required String name,
    required int logoIndex,
    required String brandColor,
    required int stampsRequired,
    required OperationMode mode,
    required int scanIntervalMs,
  }) async {
    await logEntry(businessId: businessId, propertyName: AuditProperty.businessName, newValue: name);
    await logEntry(businessId: businessId, propertyName: AuditProperty.icon, newValue: BusinessIcons.getIconName(logoIndex));
    await logEntry(businessId: businessId, propertyName: AuditProperty.brandColor, newValue: brandColor);
    await logEntry(businessId: businessId, propertyName: AuditProperty.stampsRequired, newValue: '$stampsRequired');
    await logEntry(businessId: businessId, propertyName: AuditProperty.operationMode, newValue: mode.displayName);
    if (mode == OperationMode.simple) {
      await logEntry(
        businessId: businessId,
        propertyName: AuditProperty.scanCooldown,
        newValue: '${scanIntervalMs ~/ 1000}s',
      );
    }
  }

  /// All entries for this business, oldest first - the trail reads as a
  /// chronological story starting from the initial-values baseline.
  Future<List<AuditEntry>> getEntries(String businessId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'audit_trail',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'timestamp ASC, id ASC',
    );
    return maps.map(AuditEntry.fromJson).toList();
  }
}
