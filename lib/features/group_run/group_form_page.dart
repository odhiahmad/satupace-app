import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/location_service.dart';
import './group_run_provider.dart';

/// Page form untuk buat / edit grup lari.
/// Jadwal menggunakan recurring schedule: day_of_week (0-6) + start_time ("HH:MM")
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
  late final TextEditingController _meetingPointCtrl;

  bool _isWomenOnly = false;
  String _status = 'open';
  double? _lat;
  double? _lng;
  bool _locLoading = false;
  String? _locLabel;
  DateTime? _scheduledAt;

  // Schedules management
  // Existing schedules dari BE (edit mode) – memiliki 'id'
  final List<Map<String, dynamic>> _existingSchedules = [];
  // Schedule baru yang ditambahkan user – belum ada 'id'
  final List<Map<String, dynamic>> _pendingSchedules = [];
  // ID schedule existing yang akan dihapus (edit mode)
  final List<String> _schedulesToDelete = [];
  bool _schedulesLoading = false;

  // 0=Minggu, 1=Senin, 2=Selasa, 3=Rabu, 4=Kamis, 5=Jumat, 6=Sabtu
  static const _dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  // Urutan tampil: Senin..Sabtu..Minggu
  static const _displayOrder = [1, 2, 3, 4, 5, 6, 0];

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
    _meetingPointCtrl = TextEditingController(
        text: g?['meeting_point']?.toString() ?? '');

    final scheduledAtStr = g?['scheduled_at']?.toString();
    if (scheduledAtStr != null) {
      _scheduledAt = DateTime.tryParse(scheduledAtStr);
    }

    _isWomenOnly = g?['is_women_only'] == true;
    _status = (g?['status'] ?? 'open').toString();

    final lat = g?['latitude'] as num?;
    final lng = g?['longitude'] as num?;
    if (lat != null && lat != 0) _lat = lat.toDouble();
    if (lng != null && lng != 0) _lng = lng.toDouble();
    if (_lat != null) {
      _locLabel = '${_lat!.toStringAsFixed(4)}, ${_lng?.toStringAsFixed(4)}';
    }

    if (!_isEdit && _lat == null) _fetchLocation();

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingSchedules();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minPaceCtrl.dispose();
    _maxPaceCtrl.dispose();
    _distCtrl.dispose();
    _maxMemberCtrl.dispose();
    _meetingPointCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSchedules() async {
    if (!mounted) return;
    final groupId = widget.group?['id']?.toString();
    if (groupId == null || groupId.isEmpty) return;

    setState(() => _schedulesLoading = true);
    try {
      final provider = Provider.of<GroupRunProvider>(context, listen: false);
      await provider.fetchSchedules(groupId);
      if (mounted) {
        setState(() {
          _existingSchedules.clear();
          _existingSchedules.addAll(provider.schedules);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _schedulesLoading = false);
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _locLoading = true);
    try {
      final pos = await LocationService().getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _locLabel =
              '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}';
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  /// Dialog untuk menambah jadwal rutin (day_of_week + start_time)
  Future<void> _showAddScheduleDialog() async {
    int selectedDay = 1; // default Senin
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 0);

    final added = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Tambah Jadwal Rutin'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hari',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _displayOrder.map((day) {
                    final isSelected = selectedDay == day;
                    return ChoiceChip(
                      label: Text(_dayNames[day],
                          style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppTheme.neonLime.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.neonLime : Colors.grey[400],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      onSelected: (v) {
                        if (v) setDialogState(() => selectedDay = day);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Waktu Mulai',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (t != null) setDialogState(() => selectedTime = t);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.clock,
                            size: 14, color: AppTheme.neonLime),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:'
                          '${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final startTime =
                      '${selectedTime.hour.toString().padLeft(2, '0')}:'
                      '${selectedTime.minute.toString().padLeft(2, '0')}';
                  Navigator.pop(ctx, {
                    'day_of_week': selectedDay,
                    'start_time': startTime,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonLime,
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Tambah'),
              ),
            ],
          );
        },
      ),
    );

    if (added != null && mounted) {
      setState(() => _pendingSchedules.add(added));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_scheduledAt == null && !_isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal & waktu lari'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'is_women_only': _isWomenOnly,
      'meeting_point': _meetingPointCtrl.text.trim(),
    };

    if (_scheduledAt != null) {
      data['scheduled_at'] = _scheduledAt!.toUtc().toIso8601String();
    }

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

    if (_isEdit) data['status'] = _status;

    final provider = Provider.of<GroupRunProvider>(context, listen: false);
    bool ok;

    if (_isEdit && widget.group?['id'] != null) {
      ok = await provider.updateGroup(widget.group!['id'], data);
      if (ok) {
        final groupId = widget.group!['id'].toString();
        // Hapus schedule yang ditandai
        for (final id in _schedulesToDelete) {
          await provider.deleteSchedule(groupId, id);
        }
        // Buat schedule baru
        for (final sch in _pendingSchedules) {
          await provider.createSchedule(
            groupId,
            sch['day_of_week'] as int,
            sch['start_time'] as String,
          );
        }
      }
    } else {
      ok = await provider.createGroup(data, schedules: _pendingSchedules);
      print(data);
    }

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isEdit ? 'Grup berhasil diperbarui' : 'Grup berhasil dibuat'),
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

  // ── Widgets ────────────────────────────────────────

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.calendarDays,
                size: 14, color: AppTheme.neonLime),
            const SizedBox(width: 8),
            const Text('Jadwal Rutin',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAddScheduleDialog,
              icon: const FaIcon(FontAwesomeIcons.plus,
                  size: 11, color: AppTheme.neonLime),
              label: const Text('Tambah',
                  style:
                      TextStyle(fontSize: 12, color: AppTheme.neonLime)),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_schedulesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                  height: 20,
                  width: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (_existingSchedules.isEmpty && _pendingSchedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Belum ada jadwal rutin',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Existing schedules (edit mode) – tersimpan di BE
                ..._existingSchedules.map((sch) {
                  final day =
                      (sch['day_of_week'] as num?)?.toInt() ?? 0;
                  final time = sch['start_time']?.toString() ?? '';
                  final id = sch['id']?.toString() ?? '';
                  final markedDelete =
                      _schedulesToDelete.contains(id);
                  return Chip(
                    avatar: FaIcon(
                      FontAwesomeIcons.calendarCheck,
                      size: 11,
                      color: markedDelete
                          ? Colors.grey
                          : AppTheme.neonLime,
                    ),
                    label: Text(
                      '${_dayNames[day]} • $time',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: markedDelete
                            ? TextDecoration.lineThrough
                            : null,
                        color: markedDelete ? Colors.grey : null,
                      ),
                    ),
                    backgroundColor: markedDelete
                        ? Colors.grey.withValues(alpha: 0.1)
                        : AppTheme.neonLime.withValues(alpha: 0.12),
                    deleteIcon: Icon(
                      markedDelete ? Icons.undo : Icons.close,
                      size: 14,
                      color: markedDelete
                          ? Colors.grey
                          : Colors.redAccent,
                    ),
                    onDeleted: () {
                      setState(() {
                        if (markedDelete) {
                          _schedulesToDelete.remove(id);
                        } else {
                          _schedulesToDelete.add(id);
                        }
                      });
                    },
                  );
                }),
                // Pending schedules – akan dibuat setelah submit
                ..._pendingSchedules.asMap().entries.map((e) {
                  final idx = e.key;
                  final sch = e.value;
                  final day =
                      (sch['day_of_week'] as num?)?.toInt() ?? 0;
                  final time = sch['start_time']?.toString() ?? '';
                  return Chip(
                    avatar: const FaIcon(
                      FontAwesomeIcons.plus,
                      size: 10,
                      color: Colors.blueAccent,
                    ),
                    label: Text(
                      '${_dayNames[day]} • $time',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor:
                        Colors.blueAccent.withValues(alpha: 0.12),
                    deleteIcon: const Icon(Icons.close,
                        size: 14, color: Colors.redAccent),
                    onDeleted: () =>
                        setState(() => _pendingSchedules.removeAt(idx)),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(
          _isEdit
              ? 'Jadwal tersimpan (hijau) dapat dihapus. Jadwal baru (biru) akan dibuat setelah disimpan.'
              : 'Tambahkan hari & jam lari rutin grup ini.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
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
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

            // ── Meeting Point ────────────────────
            TextFormField(
              controller: _meetingPointCtrl,
              decoration: InputDecoration(
                labelText: 'Titik Kumpul',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: FaIcon(FontAwesomeIcons.mapPin, size: 16),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Titik kumpul wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // ── Tanggal & Waktu Lari ─────────────
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: _scheduledAt ?? now,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (date == null || !mounted) return;
                final initTime = _scheduledAt != null
                    ? TimeOfDay.fromDateTime(_scheduledAt!)
                    : const TimeOfDay(hour: 6, minute: 0);
                // ignore: use_build_context_synchronously
                final time = await showTimePicker(context: context, initialTime: initTime);
                if (time == null || !mounted) return;
                setState(() {
                  _scheduledAt = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _scheduledAt == null
                          ? Colors.grey.withValues(alpha: 0.4)
                          : AppTheme.neonLime.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.calendarDay,
                        size: 16,
                        color: _scheduledAt != null
                            ? AppTheme.neonLime
                            : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tanggal & Waktu Lari',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                          const SizedBox(height: 2),
                          Text(
                            _scheduledAt != null
                                ? '${_scheduledAt!.day.toString().padLeft(2, '0')}/'
                                  '${_scheduledAt!.month.toString().padLeft(2, '0')}/'
                                  '${_scheduledAt!.year}  '
                                  '${_scheduledAt!.hour.toString().padLeft(2, '0')}:'
                                  '${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                                : 'Pilih tanggal & waktu',
                            style: TextStyle(
                              fontSize: 14,
                              color: _scheduledAt != null
                                  ? null
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                  ],
                ),
              ),
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

            // ── Jadwal Rutin ─────────────────────
            _buildScheduleSection(),
            const SizedBox(height: 16),

            // ── Lokasi (auto GPS) ───────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.locationDot,
                      size: 16,
                      color:
                          _lat != null ? AppTheme.neonLime : Colors.grey),
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
                  _buildStatusChip(
                      'completed', 'Completed', Colors.grey),
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
                    Text('Khusus Wanita',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
                value: _isWomenOnly,
                activeThumbColor: AppTheme.neonLime,
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
                                strokeWidth: 2,
                                color: Colors.black54))
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
}
