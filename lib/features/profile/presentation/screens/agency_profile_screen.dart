import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../admin/presentation/providers/super_admin_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class AgencyProfileScreen extends ConsumerStatefulWidget {
  const AgencyProfileScreen({super.key});

  @override
  ConsumerState<AgencyProfileScreen> createState() =>
      _AgencyProfileScreenState();
}

class _AgencyProfileScreenState extends ConsumerState<AgencyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgencyData();
    });
  }

  Future<void> _loadAgencyData() async {
    final user = ref.read(currentUserProvider);
    if (user?.agencyId == null) return;

    setState(() => _isLoading = true);
    try {
      final agencyResult = await ref
          .read(superAdminRepositoryProvider)
          .getAgencyDetail(user!.agencyId!);

      agencyResult.fold(
        (l) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.message)),
            );
          }
        },
        (agency) {
          _nameController.text = agency.name;
          _phoneController.text = agency.phone ?? '';
          _emailController.text = agency.email ?? '';
          _addressController.text = agency.address ?? '';
          _cityController.text = agency.city ?? '';
          _descriptionController.text = agency.description ?? '';
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final strings = AppStrings.of(context);
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user?.agencyId == null) return;

    setState(() => _isLoading = true);
    try {
      final updates = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      final result = await ref
          .read(superAdminRepositoryProvider)
          .updateAgency(user!.agencyId!, updates);

      if (mounted) {
        result.fold(
          (l) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.message)),
          ),
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  strings.tr(
                    'Profil agensi berhasil diperbarui.',
                    'Agency profile updated successfully.',
                  ),
                ),
              ),
            );
            invalidateSuperAdminData(ref);
            ref.invalidate(agencyDetailProvider(user.agencyId!));
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AppScaffold(
      title: strings.tr('Profil Agensi', 'Agency Profile'),
      body: _isLoading
          ? LoadingView(
              message: strings.tr(
                'Memuat profil agensi...',
                'Loading agency profile...',
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AgencyHeroCard(),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: strings.tr('Identitas Agensi', 'Agency Identity'),
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: strings.tr('Nama Agensi', 'Agency Name'),
                            prefixIcon: const Icon(Icons.business),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? strings.tr(
                                  'Nama agensi wajib diisi',
                                  'Agency name is required',
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: strings.tr('Deskripsi', 'Description'),
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 50),
                              child: Icon(Icons.description_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: strings.tr('Kontak & Lokasi', 'Contact & Location'),
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: strings.tr('Email', 'Email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: strings.profilePhone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: strings.address,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: strings.city,
                            prefixIcon: const Icon(Icons.location_city_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _saveProfile,
                      child: Text(strings.tr('Simpan Perubahan', 'Save Changes')),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AgencyHeroCard extends StatelessWidget {
  const _AgencyHeroCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xff153f9f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.business_center_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.tr('Identitas Agensi', 'Agency Identity'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.tr(
                    'Lengkapi informasi agar profil agensi terlihat tepercaya di ClassRent.',
                    'Complete the information so your agency profile looks trustworthy on ClassRent.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.35,
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

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
