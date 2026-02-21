import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/location_service.dart';
import '../../core/router/navigation_service.dart';
import './profile_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _location;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      provider.fetchProfile();
    });
  }

  Future<void> _captureLocation(ProfileProvider provider) async {
    final locService = Provider.of<LocationService>(context, listen: false);
    final pos = await locService.getCurrentPosition();
    if (pos != null) {
      setState(() => _location = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}');
      await provider.updateLocation(pos.latitude, pos.longitude);
    } else {
      setState(() => _location = 'Unavailable');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navService = Provider.of<NavigationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navService.goBack(),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: provider.name ?? '',
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (v) => provider.updateName(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: provider.email ?? '',
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: (v) => provider.updateEmail(v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: (provider.avgPace ?? 0).toString(),
                          decoration: const InputDecoration(labelText: 'Avg Pace (min/km)'),
                          onChanged: (v) {
                            final pace = double.tryParse(v);
                            if (pace != null) provider.updatePace(pace);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: (provider.preferredDistance ?? 5).toString(),
                          decoration: const InputDecoration(labelText: 'Preferred Dist. (km)'),
                          onChanged: (v) {
                            final distance = int.tryParse(v);
                            if (distance != null) provider.updatePreferredDistance(distance);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    ElevatedButton(
                      onPressed: () => _captureLocation(provider),
                      child: const Text('Capture Location'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_location ?? 'No location captured'),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.saving
                          ? null
                          : () {
                              // Changes are auto-saved via onChange
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile saved')),
                              );
                            },
                      child: provider.saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
