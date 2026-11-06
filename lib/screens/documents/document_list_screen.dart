import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_download_helper.dart';
import '../../core/utils/responsive.dart';
import '../../data/api/document_api_client.dart';
import '../../models/vehicle_document.dart';
import '../../router/app_router.dart';
import '../../widgets/animated/ambient_grid_pattern.dart';
import '../../widgets/animated/animated_counter.dart';
import '../../widgets/animated/spotlight_hover_card.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/confirmation_dialog.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentApiClient _apiClient = DocumentApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<VehicleDocument> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _statusFilter = 'ALL'; // ALL, EXPIRED, EXPIRING_SOON, VALID
  DocumentType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final docs = await _apiClient.getAllDocuments();
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<VehicleDocument> get _filteredDocuments {
    return _documents.where((doc) {
      if (_statusFilter != 'ALL' && doc.expiryStatus != _statusFilter) {
        return false;
      }
      if (_typeFilter != null && doc.documentType != _typeFilter) {
        return false;
      }
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final vNum = doc.vehicleNumber?.toLowerCase() ?? '';
        final docNum = doc.documentNumber?.toLowerCase() ?? '';
        final notes = doc.notes?.toLowerCase() ?? '';
        final fName = doc.fileName?.toLowerCase() ?? '';
        final typeLabel = doc.documentType.label.toLowerCase();
        return vNum.contains(q) ||
            docNum.contains(q) ||
            notes.contains(q) ||
            fName.contains(q) ||
            typeLabel.contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _showDocumentFilePreview(VehicleDocument doc) async {
    VehicleDocument fullDoc = doc;
    if (fullDoc.fileData == null && fullDoc.hasFileData) {
      try {
        fullDoc = await _apiClient.getDocument(doc.vehicleId, doc.id);
      } catch (_) {}
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: fullDoc.statusBadgeBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description, color: fullDoc.statusBadgeTextColor, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullDoc.fileName ?? '${fullDoc.documentType.label} Attachment', style: const TextStyle(fontSize: 16)),
                  Text(
                    '${fullDoc.vehicleNumber ?? "Vehicle #${fullDoc.vehicleId}"} • ${fullDoc.documentType.label}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fullDoc.fileData != null &&
                    (fullDoc.fileType == 'png' || fullDoc.fileType == 'jpg' || fullDoc.fileType == 'jpeg'))
                  Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.space16),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderNeutral),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      base64Decode(fullDoc.fileData!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Unable to render image preview'),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space20),
                    margin: const EdgeInsets.only(bottom: AppTheme.space16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderNeutral),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          fullDoc.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                          size: 48,
                          color: fullDoc.fileType == 'pdf' ? const Color(0xFFDC2626) : AppTheme.primaryBlue,
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          fullDoc.fileName ?? 'Official Document Attachment',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Format: ${(fullDoc.fileType ?? 'document').toUpperCase()} • Status: ${fullDoc.expiryStatusLabel}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle: ${fullDoc.vehicleNumber ?? "#${fullDoc.vehicleId}"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      if (fullDoc.documentNumber != null && fullDoc.documentNumber!.isNotEmpty)
                        Text('Document Number: ${fullDoc.documentNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      if (fullDoc.issueDate != null)
                        Text('Issued: ${fullDoc.issueDate!.toIso8601String().substring(0, 10)}', style: const TextStyle(fontSize: 12)),
                      Text('Expiry: ${fullDoc.expiryDate.toIso8601String().substring(0, 10)} (${fullDoc.expiryStatusLabel})', style: const TextStyle(fontSize: 12)),
                      if (fullDoc.notes != null && fullDoc.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Notes: ${fullDoc.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          if (fullDoc.fileData != null)
            FilledButton.icon(
              onPressed: () {
                triggerBrowserDownload(
                  fullDoc.fileData!,
                  fullDoc.fileName ?? '${fullDoc.documentType.label}.${fullDoc.fileType ?? "pdf"}',
                  fullDoc.fileType,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading ${fullDoc.fileName ?? "document"}...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download File'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteDocument(VehicleDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Document',
      message: 'Are you sure you want to remove this ${doc.documentType.label} for ${doc.vehicleNumber ?? "Vehicle #${doc.vehicleId}"}?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _apiClient.deleteDocument(doc.vehicleId, doc.id);
        await _loadDocuments();
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Document deleted successfully'), backgroundColor: Color(0xFF15803D)),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Failed to delete document: $e'), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return AppShell(
      title: 'Fleet Documents',
      primaryAction: FilledButton.icon(
        onPressed: _loadDocuments,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Refresh Documents'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
      child: _buildBody(isDesktop),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: AppTheme.space16),
              const Text('Failed to load fleet documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppTheme.space8),
              Text(_errorMessage!, style: const TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.space20),
              FilledButton(onPressed: _loadDocuments, child: const Text('Retry Connection')),
            ],
          ),
        ),
      );
    }

    final expiredCount = _documents.where((d) => d.expiryStatus == 'EXPIRED').length;
    final expiringSoonCount = _documents.where((d) => d.expiryStatus == 'EXPIRING_SOON').length;
    final validCount = _documents.where((d) => d.expiryStatus == 'VALID').length;
    final filtered = _filteredDocuments;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? AppTheme.space24 : AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroHeader(isDesktop),
          const SizedBox(height: AppTheme.space20),
          _buildKpiMetrics(expiredCount, expiringSoonCount, validCount),
          const SizedBox(height: AppTheme.space20),
          _buildFiltersCard(isDesktop),
          const SizedBox(height: AppTheme.space20),
          if (filtered.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, i) => _buildDocumentRow(filtered[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderNeutral),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: AmbientGridPattern(
              spacing: 24,
              dotRadius: 1.0,
              dotColor: Color(0xFFE2E8F0),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? AppTheme.space24 : AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueSubtle,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Text(
                        'Statutory Compliance & Telematics Vault',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_documents.length} Total Records Logged',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                const Text(
                  'Fleet Document Explorer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explore, verify, and inspect statutory certifications including Registration, Tax Token, Fitness Certificates, and Comprehensive Insurance policies across all Stark Group vehicles.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(int expired, int expiringSoon, int valid) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTheme.space16,
          mainAxisSpacing: AppTheme.space16,
          childAspectRatio: 2.2,
          children: [
            _buildMetricCard(
              title: 'Total Documents',
              value: _documents.length,
              icon: Icons.folder_shared_rounded,
              color: const Color(0xFF2563EB),
              bg: const Color(0xFFEFF6FF),
              onTap: () => setState(() => _statusFilter = 'ALL'),
              isSelected: _statusFilter == 'ALL',
            ),
            _buildMetricCard(
              title: 'Expired Documents',
              value: expired,
              icon: Icons.cancel_rounded,
              color: const Color(0xFFDC2626),
              bg: const Color(0xFFFEF2F2),
              onTap: () => setState(() => _statusFilter = 'EXPIRED'),
              isSelected: _statusFilter == 'EXPIRED',
            ),
            _buildMetricCard(
              title: 'Expiring Soon (30d)',
              value: expiringSoon,
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
              onTap: () => setState(() => _statusFilter = 'EXPIRING_SOON'),
              isSelected: _statusFilter == 'EXPIRING_SOON',
            ),
            _buildMetricCard(
              title: 'Fully Compliant',
              value: valid,
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF059669),
              bg: const Color(0xFFECFDF5),
              onTap: () => setState(() => _statusFilter = 'VALID'),
              isSelected: _statusFilter == 'VALID',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return SpotlightHoverCard(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
      borderRadius: AppTheme.radiusMd,
      onTap: onTap,
      hasBorderBeam: isSelected,
      beamColor: color,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AnimatedCounter(
                  value: value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(bool isDesktop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by vehicle number, policy/doc #, notes...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<DocumentType?>(
                    initialValue: _typeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Document Type',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Document Types')),
                      ...DocumentType.values.map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _typeFilter = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                const Text('Status Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(width: AppTheme.space8),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildFilterChip('All Statuses', 'ALL'),
                    _buildFilterChip('Expired', 'EXPIRED'),
                    _buildFilterChip('Expiring Soon', 'EXPIRING_SOON'),
                    _buildFilterChip('Valid', 'VALID'),
                  ],
                ),
                const Spacer(),
                if (_searchController.text.isNotEmpty || _statusFilter != 'ALL' || _typeFilter != null)
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _statusFilter = 'ALL';
                        _typeFilter = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Reset Filters', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDocumentRow(VehicleDocument doc) {
    return SpotlightHoverCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      borderRadius: AppTheme.radiusMd,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: doc.statusBadgeBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(Icons.description_rounded, color: doc.statusBadgeTextColor, size: 26),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRouter.vehicleDetailsRoute,
                          arguments: {'id': doc.vehicleId, 'initialTab': 0},
                        ).then((_) => _loadDocuments());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          doc.vehicleNumber ?? 'Vehicle #${doc.vehicleId}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      doc.documentType.label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: doc.statusBadgeBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        doc.expiryStatusLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: doc.statusBadgeTextColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Expiry: ${doc.expiryDate.toIso8601String().substring(0, 10)}${doc.documentNumber != null ? ' • Document #${doc.documentNumber}' : ''}${doc.fileName != null ? ' • File: ${doc.fileName}' : ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(doc.notes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
                ],
              ],
            ),
          ),
          if (doc.hasFileData || doc.fileName != null)
            IconButton(
              tooltip: 'Preview & Download File',
              icon: const Icon(Icons.visibility_outlined, color: Color(0xFF0D9488), size: 20),
              onPressed: () => _showDocumentFilePreview(doc),
            ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.vehicleDetailsRoute,
                arguments: {'id': doc.vehicleId, 'initialTab': 0},
              ).then((_) => _loadDocuments());
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('View Vehicle', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: AppTheme.space8),
          IconButton(
            tooltip: 'Delete Document',
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
            onPressed: () => _handleDeleteDocument(doc),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          children: [
            const Icon(Icons.folder_open_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: AppTheme.space12),
            const Text('No documents matching filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Try adjusting your search criteria or filter options above.', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: AppTheme.space16),
            FilledButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _statusFilter = 'ALL';
                  _typeFilter = null;
                });
              },
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Clear All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
