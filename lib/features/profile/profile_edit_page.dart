import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/router/navigation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/components/location_capture_card.dart';
import '../../shared/components/choice_chip_selector.dart';
import './profile_provider.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  File? _pickedImage;
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

    if (_capturedLatitude != null && _capturedLongitude != null) {
      updates['latitude'] = _capturedLatitude;
      updates['longitude'] = _capturedLongitude;
    }

    // Capture context-dependents before async gap
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final ok = await provider.updateProfile(updates);
    if (!mounted) return;

    if (ok) {
      if (name.isNotEmpty) await auth.updateName(name);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Color(0xFF2D5A3D),
        ),
      );
      nav.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan profil'),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> _pickImage(ProfileProvider provider) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    setState(() => _pickedImage = file);

    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.uploadProfileImage(file);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Foto profil berhasil diperbarui' : (provider.error ?? 'Gagal upload foto')),
      backgroundColor: ok ? const Color(0xFF2D5A3D) : Colors.red,
    ));
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
                  _buildAvatarSection(provider),
                  const SizedBox(height: 24),
                  _buildPersonalSection(context, provider),
                  const SizedBox(height: 24),
                  _buildRunDataSection(context, provider),
                  const SizedBox(height: 24),
                  _buildPreferredTimeSection(context),
                  const SizedBox(height: 24),
                  _buildWomenOnlySection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(provider),
                  const SizedBox(height: 32),
                  _buildSaveButton(provider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(ProfileProvider provider) {
    final existingUrl = provider.image;
    final hasLocal = _pickedImage != null;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppTheme.neonLime.withValues(alpha: 0.2),
            backgroundImage: hasLocal
                ? FileImage(_pickedImage!) as ImageProvider
                : (existingUrl != null && existingUrl.isNotEmpty
                    ? NetworkImage(existingUrl)
                    : null),
            child: (!hasLocal && (existingUrl == null || existingUrl.isEmpty))
                ? const FaIcon(FontAwesomeIcons.user,
                    size: 40, color: AppTheme.neonLime)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: provider.saving ? null : () => _pickImage(provider),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonLime,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2),
                ),
                child: provider.saving
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black87),
                      )
                    : const Icon(Icons.camera_alt,
                        size: 18, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection(BuildContext context, ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Pribadi',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Nama Lengkap',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: FaIcon(FontAwesomeIcons.user, size: 18),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Text('Jenis Kelamin',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        ChoiceChipSelector(
          options: _genderOptions,
          selected: _gender,
          onChanged: (v) => setState(() => _gender = v),
        ),
      ],
    );
  }

  Widget _buildRunDataSection(BuildContext context, ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Data Lari',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
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
                    child: FaIcon(FontAwesomeIcons.gaugeHigh, size: 18),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
      ],
    );
  }

  Widget _buildPreferredTimeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waktu Preferensi',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ChoiceChipSelector(
          options: _timeOptions,
          selected: _preferredTime,
          onChanged: (v) => setState(() => _preferredTime = v),
        ),
      ],
    );
  }

  Widget _buildWomenOnlySection() {
    return Container(
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
            color: _womenOnlyMode ? const Color(0xFFB8FF00) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mode Wanita Saja',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Hanya ditemukan oleh pengguna wanita lainnya',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Switch(
            value: _womenOnlyMode,
            onChanged: (v) => setState(() => _womenOnlyMode = v),
            activeTrackColor:
                const Color(0xFFB8FF00).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFFB8FF00),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LocationCaptureCard(
          locationText: _locationText,
          onCapture: () => _captureLocation(provider),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ProfileProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: provider.saving ? null : () => _saveProfile(provider),
        icon: provider.saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const FaIcon(FontAwesomeIcons.floppyDisk, size: 18),
        label: Text(provider.saving ? 'Menyimpan...' : 'Simpan Profil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB8FF00),
          foregroundColor: Colors.black87,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
