import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/router/navigation_service.dart';
import '../../core/theme/app_theme.dart';
import '../strava/strava_provider.dart';
import './profile_provider.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  String? _locationText;
  double? _capturedLatitude;
  double? _capturedLongitude;
  bool _controllersInitialized = false;

  final _nameCtrl = TextEditingController();
  final _paceCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  String _preferredTime = 'morning';
  String _gender = 'male';
  bool _womenOnlyMode = false;

  static const _timeOptions = [
    {'value': 'morning', 'label': 'Pagi'},
    {'value': 'afternoon', 'label': 'Siang'},
    {'value': 'evening', 'label': 'Sore'},
    {'value': 'night', 'label': 'Malam'},
  ];

  static const _genderOptions = [
    {'value': 'male', 'label': 'Laki-laki'},
    {'value': 'female', 'label': 'Perempuan'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      if (provider.profile == null) {
        await provider.fetchProfile();
      }
      if (!mounted) return;
      _populateControllers(provider);

      // Load Strava data so auto-fill pace is available
      final strava = Provider.of<StravaProvider>(context, listen: false);
      if (!strava.isConnected) {
        strava.loadAll();
      }
    });
  }

  void _populateControllers(ProfileProvider provider) {
    if (_controllersInitialized) return;
    _nameCtrl.text = provider.name ?? '';
    _paceCtrl.text =
        provider.avgPace != null ? provider.avgPace!.toStringAsFixed(1) : '';
    _distanceCtrl.text = provider.preferredDistance?.toString() ?? '';
    _preferredTime = provider.preferredTime ?? 'morning';
    _gender = provider.gender ?? 'male';
    _womenOnlyMode = provider.womenOnlyMode;
    if (provider.latitude != null && provider.longitude != null) {
      _capturedLatitude = provider.latitude;
      _capturedLongitude = provider.longitude;
      _locationText =
          '${provider.latitude!.toStringAsFixed(6)}, ${provider.longitude!.toStringAsFixed(6)}';
    }
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _paceCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(ProfileProvider provider) async {
    final updates = <String, dynamic>{};

    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) updates['name'] = name;

    updates['gender'] = _gender;

    final pace = double.tryParse(_paceCtrl.text.trim());
    if (pace != null) updates['avg_pace'] = pace;

    final dist = int.tryParse(_distanceCtrl.text.trim());
    if (dist != null) updates['preferred_distance'] = dist;

    updates['preferred_time'] = _preferredTime;
    updates['women_only_mode'] = _womenOnlyMode;

    // Include captured location if available
    if (_capturedLatitude != null && _capturedLongitude != null) {
      updates['latitude'] = _capturedLatitude;
      updates['longitude'] = _capturedLongitude;
    }

    final ok = await provider.updateProfile(updates);
    if (mounted) {
      if (ok) {
        // Sync updated name to AuthProvider so home screen refreshes immediately
        if (name.isNotEmpty) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          await auth.updateName(name);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan'),
            backgroundColor: Color(0xFF2D5A3D),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Gagal menyimpan profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureLocation(ProfileProvider provider) async {
    final locService = Provider.of<LocationService>(context, listen: false);

    final issue = await locService.diagnose();
    if (issue != null && mounted) {
      setState(() => _locationText = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(issue), backgroundColor: Colors.red),
      );
      return;
    }

    final pos = await locService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _capturedLatitude = pos.latitude;
        _capturedLongitude = pos.longitude;
        _locationText =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi ditangkap. Klik Simpan Profil untuk menyimpan.'),
          backgroundColor: Color(0xFF2D5A3D),
        ),
      );
    } else if (mounted) {
      setState(() => _locationText = 'Tidak tersedia');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa mendapatkan lokasi. Periksa GPS.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => navService.goBack(),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_controllersInitialized) {
            _populateControllers(provider);
            // Schedule rebuild so _preferredTime and _womenOnlyMode are reflected
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Personal Info ---
                  Text('Informasi Pribadi',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: FaIcon(FontAwesomeIcons.user, size: 18),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Jenis Kelamin',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genderOptions.map((opt) {
                      final isSelected = _gender == opt['value'];
                      return ChoiceChip(
                        label: Text(opt['label']!),
                        selected: isSelected,
                        selectedColor:
                            const Color(0xFFB8FF00).withValues(alpha: 0.3),
                        onSelected: (_) =>
                            setState(() => _gender = opt['value']!),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFB8FF00)
                              : null,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFB8FF00)
                              : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // --- Pace & Distance ---
                  Row(
                    children: [
                      Text('Data Lari',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Consumer<StravaProvider>(
                        builder: (context, strava, _) {
                          final pace = strava.avgPace;
                          if (pace == null) return const SizedBox.shrink();
                          return TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _paceCtrl.text = pace.toStringAsFixed(2);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Pace diisi otomatis: ${pace.toStringAsFixed(2)} min/km'),
                                  backgroundColor:
                                      const Color(0xFF2D5A3D),
                                ),
                              );
                            },
                            icon: const FaIcon(
                                FontAwesomeIcons.strava,
                                size: 14),
                            label: const Text('Dari Strava',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.neonLime,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _paceCtrl,
                          decoration: InputDecoration(
                            labelText: 'Avg Pace (min/km)',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: FaIcon(FontAwesomeIcons.gaugeHigh,
                                  size: 18),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _distanceCtrl,
                          decoration: InputDecoration(
                            labelText: 'Jarak Preferensi (km)',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: FaIcon(FontAwesomeIcons.route, size: 18),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Preferred Time ---
                  Text('Waktu Preferensi',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeOptions.map((opt) {
                      final isSelected = _preferredTime == opt['value'];
                      return ChoiceChip(
                        label: Text(opt['label']!),
                        selected: isSelected,
                        selectedColor:
                            const Color(0xFFB8FF00).withValues(alpha: 0.3),
                        onSelected: (_) =>
                            setState(() => _preferredTime = opt['value']!),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFB8FF00)
                              : null,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFB8FF00)
                              : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // --- Women Only Mode ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _womenOnlyMode
                            ? const Color(0xFFB8FF00).withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.personDress,
                          size: 20,
                          color: _womenOnlyMode
                              ? const Color(0xFFB8FF00)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mode Wanita Saja',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                'Hanya ditemukan oleh pengguna wanita lainnya',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _womenOnlyMode,
                          onChanged: (v) =>
                              setState(() => _womenOnlyMode = v),
                          activeTrackColor: const Color(0xFFB8FF00).withValues(alpha: 0.5),
                          activeThumbColor: const Color(0xFFB8FF00),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Location ---
                  Text('Lokasi',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFB8FF00).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFB8FF00)
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.locationDot,
                            color: Color(0xFFB8FF00), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lokasi Saat Ini',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                _locationText ?? 'Belum ditetapkan',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _captureLocation(provider),
                          icon: const FaIcon(FontAwesomeIcons.mapPin,
                              size: 16),
                          label: const Text('Tangkap'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            backgroundColor: const Color(0xFFB8FF00),
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Save Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: provider.saving
                          ? null
                          : () => _saveProfile(provider),
                      icon: provider.saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const FaIcon(FontAwesomeIcons.floppyDisk,
                              size: 18),
                      label: Text(
                          provider.saving ? 'Menyimpan...' : 'Simpan Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8FF00),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
