import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart' hide Card;
import '../../models/audit_entry.dart';
import '../../services/audit_trail_repository.dart';
import '../../services/audit_trail_pdf_service.dart';

/// Shows the local business-configuration audit trail as a readable table,
/// with Print/Share actions to export it as a PDF - for support purposes
/// (Requirements/DISCUSSION_Business_Field_Editing.md §7.4). Local to this
/// device only.
class AuditTrailScreen extends StatefulWidget {
  final Business business;

  const AuditTrailScreen({super.key, required this.business});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  final AuditTrailRepository _repo = AuditTrailRepository();
  List<AuditEntry> _entries = [];
  bool _isLoading = true;
  // Same double-tap guard pattern as RecoveryBackupScreen (CRASH-001) -
  // Printing.layoutPdf/Share.shareXFiles are real async native calls.
  bool _isPrinting = false;
  bool _isSharing = false;

  @visibleForTesting
  bool get isPrintingForTesting => _isPrinting;
  @visibleForTesting
  bool get isSharingForTesting => _isSharing;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await _repo.getEntries(widget.business.id);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _print() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    final result = await AuditTrailPdfService.printAuditTrail(widget.business, _entries);
    if (!mounted) return;
    setState(() => _isPrinting = false);
    if (!result.isSuccess && result.failureReason != BackupFailureReason.userCancelled) {
      AppFeedback.error(context, result.getUserMessage());
    }
  }

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    final result = await AuditTrailPdfService.shareAuditTrail(widget.business, _entries);
    if (!mounted) return;
    setState(() => _isSharing = false);
    if (!result.isSuccess && result.failureReason != BackupFailureReason.userCancelled) {
      AppFeedback.error(context, result.getUserMessage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'A local record of changes to this business, kept only on this device. '
                    'Useful to have to hand if you contact support.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('No audit trail entries yet.'))
                      : ListView.separated(
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return ListTile(
                              title: Text(entry.propertyName),
                              subtitle: Text(entry.newValue ?? '—'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(dateFormat.format(entry.timestamp), style: const TextStyle(fontSize: 12)),
                                  Text(
                                    entry.appVersion,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPrinting ? null : _print,
                          icon: const Icon(Icons.print),
                          label: Text(_isPrinting ? 'Printing...' : 'Print'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSharing ? null : _share,
                          icon: const Icon(Icons.share),
                          label: Text(_isSharing ? 'Sharing...' : 'Share'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
