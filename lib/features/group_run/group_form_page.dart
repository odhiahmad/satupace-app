import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/location_service.dart';
import './group_run_provider.dart';

/// Page form untuk buat / edit grup lari.
/// Minimalis — lat/lng diambil otomatis dari GPS, tidak ditampilkan.
class GroupFormPage extends StatefulWidget {
  final Map<String, dynamic>? group; // null = buat baru

  const GroupFormPage({super.key, this.group});

  @override
  State<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends State<GroupFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _minPaceCtrl;
  late final TextEditingController _maxPaceCtrl;
  late final TextEditingController _distCtrl;
  late final TextEditingController _maxMemberCtrl;

  bool _isWomenOnly = false;
  String _status = 'open';
  DateTime? _scheduledAt;
  double? _lat;
  double? _lng;
  bool _locLoading = false;
  String? _locLabel;

  bool get _isEdit => widget.group != null;

  @override
  void initState() {
    super.initState();
    final g = widget.group;

    _nameCtrl = TextEditingController(text: g?['name'] ?? '');
    _minPaceCtrl = TextEditingController(
        text: (g?['min_pace'] as num?)?.toStringAsFixed(1) ??
            (g?['avg_pace'] as num?)?.toStringAsFixed(1) ??
            '');
    _maxPaceCtrl = TextEditingController(
        text: (g?['max_pace'] as num?)?.toStringAsFixed(1) ?? '');
    _distCtrl = TextEditingController(
        text: g?['preferred_distance']?.toString() ?? '');
    _maxMemberCtrl = TextEditingController(
        text: g?['max_member']?.toString() ?? '10');

    _isWomenOnly = g?['is_women_only'] == true;
    _status = (g?['status'] ?? 'open').toString();

    // Parse existing location
    final lat = g?['latitude'] as num?;
    final lng = g?['longitude'] as num?;
    if (lat != null && lat != 0) _lat = lat.toDouble();
    if (lng != null && lng != 0) _lng = lng.toDouble();
    if (_lat != null) _locLabel = '${_lat!.toStringAsFixed(4)}, ${_lng?.toStringAsFixed(4)}';

    // Parse existing schedule
    final sch = g?['scheduled_at']?.toString();
    if (sch != null && sch.isNotEmpty) {
      try { _scheduledAt = DateTime.parse(sch); } catch (_) {}
    }

    // Auto-detect location for new groups
    if (!_isEdit && _lat == null) _fetchLocation();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minPaceCtrl.dispose();
    _maxPaceCtrl.dispose();
    _distCtrl.dispose();
    _maxMemberCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locLoading = true);
    try {
      final pos = await LocationService().getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _locLabel = '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}';
          _locLoading = false;
        });
      } else {
        if (mounted) setState(() => _locLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledAt != null
          ? TimeOfDay.fromDateTime(_scheduledAt!)
          : const TimeOfDay(hour: 6, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'is_women_only': _isWomenOnly,
    };

    final minP = double.tryParse(_minPaceCtrl.text.trim());
    final maxP = double.tryParse(_maxPaceCtrl.text.trim());
    if (minP != null) data['min_pace'] = minP;
    if (maxP != null) data['max_pace'] = maxP;

    final dist = int.tryParse(_distCtrl.text.trim());
    if (dist != null) data['preferred_distance'] = dist;

    final mm = int.tryParse(_maxMemberCtrl.text.trim());
    if (mm != null) data['max_member'] = mm;

    if (_lat != null) data['latitude'] = _lat;
    if (_lng != null) data['longitude'] = _lng;

    if (_scheduledAt != null) {
      data['scheduled_at'] = _scheduledAt!.toUtc().toIso8601String();
    }

    if (_isEdit) data['status'] = _status;

    final provider = Provider.of<GroupRunProvider>(context, listen: false);
    bool ok;
    if (_isEdit && widget.group?['id'] != null) {
      ok = await provider.updateGroup(widget.group!['id'], data);
    } else {
      ok = await provider.createGroup(data);
    }

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Grup berhasil diperbarui' : 'Grup berhasil dibuat'),
          backgroundColor: const Color(0xFF2D5A3D),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan grup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Grup' : 'Buat Grup Baru'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // ── Nama ────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Grup',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: FaIcon(FontAwesomeIcons.users, size: 16),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // ── Pace Range ──────────────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPaceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Min Pace',
                      suffixText: 'min/km',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxPaceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Max Pace',
                      suffixText: 'min/km',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Jarak & Maks Member ─────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _distCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jarak',
                      suffixText: 'km',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxMemberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Maks Member',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Jadwal ──────────────────────────
            InkWell(
              onTap: _pickSchedule,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Jadwal',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: FaIcon(FontAwesomeIcons.calendarDays, size: 16),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _scheduledAt != null
                      ? _formatDateTime(_scheduledAt!)
                      : 'Pilih tanggal & waktu',
                  style: TextStyle(
                    color: _scheduledAt != null ? null : Colors.grey[500],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Lokasi (auto GPS) ───────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.locationDot,
                      size: 16,
                      color: _lat != null ? AppTheme.neonLime : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lokasi',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(height: 2),
                        _locLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Text(
                                _locLabel ?? 'Belum terdeteksi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _lat != null
                                      ? null
                                      : Colors.grey[500],
                                ),
                              ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _locLoading ? null : _fetchLocation,
                    icon: const FaIcon(FontAwesomeIcons.locationCrosshairs,
                        size: 13, color: AppTheme.neonLime),
                    label: const Text('Refresh',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.neonLime)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Status (edit only) ──────────────
            if (_isEdit) ...[
              const Text('Status',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildStatusChip('open', 'Open', AppTheme.neonLime),
                  _buildStatusChip('full', 'Full', Colors.orange),
                  _buildStatusChip('completed', 'Completed', Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Khusus Wanita ───────────────────
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.venus,
                        size: 14, color: Colors.pink),
                    SizedBox(width: 8),
                    Text('Khusus Wanita', style: TextStyle(fontSize: 14)),
                  ],
                ),
                value: _isWomenOnly,
                activeColor: AppTheme.neonLime,
                onChanged: (v) => setState(() => _isWomenOnly = v),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 28),

            // ── Submit ──────────────────────────
            Consumer<GroupRunProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: provider.saving ? null : _submit,
                    icon: provider.saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black54))
                        : FaIcon(
                            _isEdit
                                ? FontAwesomeIcons.floppyDisk
                                : FontAwesomeIcons.plus,
                            size: 16,
                            color: Colors.black87),
                    label: Text(
                      _isEdit ? 'Simpan Perubahan' : 'Buat Grup',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonLime,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, Color color) {
    final selected = _status == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: selected ? color : Colors.grey[400],
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (v) {
        if (v) setState(() => _status = value);
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
