import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/profile_update_models.dart';
import '../../data/services/profile_update_service.dart';
import '../../data/services/countries_service.dart';
import '../../../../core/network/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
/// ---------- Gradient Icon ----------
class GradientIcon extends StatelessWidget {
  const GradientIcon(
    this.icon, {
    super.key,
    this.size = 24.0,
    required this.gradient,
  });
  final IconData icon;
  final double size;
  final Gradient gradient;
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}
/// ---------- App Gradients ----------
class AppGradients {
  static const LinearGradient basic = LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient work = LinearGradient(
    colors: [Color(0xFF0A66C2), Color(0xFF084E99)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient location = LinearGradient(
    colors: [Color(0xFF1D976C), Color(0xFF93F9B9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient education = LinearGradient(
    colors: [Color(0xFFD66D75), Color(0xFFE29587)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient social = LinearGradient(
    colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
  static const LinearGradient photos = LinearGradient(
    colors: [Color(0xFFF857A6), Color(0xFFFF5858)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient password = LinearGradient(
    colors: [Color(0xFF47535E), Color(0xFF7A8A99)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient save = basic;
}
/// ---------- Screen ----------
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.profile});
  final UserProfile profile;
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}
class _ProfileEditPageState extends State<ProfileEditPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final ProfileUpdateService _updateService;
  late final CountriesService _countriesService;
  final ImagePicker _imagePicker = ImagePicker();
  // Forms
  final _formBasic = GlobalKey<FormState>();
  final _formWork = GlobalKey<FormState>();
  final _formLoc = GlobalKey<FormState>();
  final _formEdu = GlobalKey<FormState>();
  final _formSocial = GlobalKey<FormState>();
  // Controllers
  late final TextEditingController _firstname;
  late final TextEditingController _lastname;
  late final TextEditingController _bio;
  late final TextEditingController _website;
  late final TextEditingController _workTitle;
  late final TextEditingController _workPlace;
  late final TextEditingController _workUrl;
  late final TextEditingController _city;
  late final TextEditingController _hometown;
  late final TextEditingController _eduMajor;
  late final TextEditingController _eduSchool;
  late final TextEditingController _eduClass;
  late final TextEditingController _facebook;
  late final TextEditingController _twitter;
  late final TextEditingController _youtube;
  late final TextEditingController _instagram;
  late final TextEditingController _linkedin;
  late final TextEditingController _twitch;
  late final TextEditingController _vkontakte;
  // State
  File? _selectedProfileImage;
  File? _selectedCoverImage;
  bool _isLoading = false;
  bool _loadingCountries = false;
  List<CountryData> _countries = [];
  String? _selectedGender; // male/female/other
  DateTime? _selectedBirthDate;
  String? _selectedRelationship;
  String? _selectedCountryId;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
    _updateService = ProfileUpdateService(context.read<ApiClient>());
    _countriesService = CountriesService(context.read<ApiClient>());
    _firstname = TextEditingController(text: widget.profile.firstName);
    _lastname = TextEditingController(text: widget.profile.lastName);
    _bio = TextEditingController(text: widget.profile.about);
    _website = TextEditingController(text: widget.profile.website);
    _workTitle = TextEditingController(text: widget.profile.work.title);
    _workPlace = TextEditingController(text: widget.profile.work.place);
    _workUrl = TextEditingController(text: widget.profile.work.website);
    _city = TextEditingController(text: widget.profile.location.currentCity);
    _hometown = TextEditingController(text: widget.profile.location.hometown);
    _eduMajor = TextEditingController(text: widget.profile.education.major);
    _eduSchool = TextEditingController(text: widget.profile.education.school);
    _eduClass = TextEditingController(text: widget.profile.education.classYear);
    _facebook = TextEditingController(text: widget.profile.socialLinks.facebook ?? '');
    _twitter = TextEditingController(text: widget.profile.socialLinks.x ?? '');
    _youtube = TextEditingController(text: widget.profile.socialLinks.youtube ?? '');
    _instagram = TextEditingController(text: widget.profile.socialLinks.instagram ?? '');
    _linkedin = TextEditingController(text: widget.profile.socialLinks.linkedin ?? '');
    _twitch = TextEditingController(text: widget.profile.socialLinks.twitch ?? '');
    _vkontakte = TextEditingController(text: widget.profile.socialLinks.vkontakte ?? '');
    // gender mapping
    final g = widget.profile.gender;
    if (g == '1') _selectedGender = 'male';
    else if (g == '2') _selectedGender = 'female';
    else if (g == '3') _selectedGender = 'other';
    else if (g.isNotEmpty) {
      final gl = g.toLowerCase();
      if (['male', 'female', 'other'].contains(gl)) _selectedGender = gl;
    }
    if (widget.profile.country?.id != null) {
      _selectedCountryId = widget.profile.country!.id.toString();
    }
    final rel = widget.profile.relationship?.toLowerCase() ?? '';
    if ([
      'single','relationship','married','complicated','separated','divorced','widowed',
    ].contains(rel)) {
      _selectedRelationship = rel;
    }
    if (widget.profile.birthDate?.isNotEmpty == true) {
      try { _selectedBirthDate = DateTime.parse(widget.profile.birthDate!); } catch (_) {}
    }
    _loadCountries();
  }
  @override
  void dispose() {
    _tab.dispose();
    _firstname.dispose();
    _lastname.dispose();
    _bio.dispose();
    _website.dispose();
    _workTitle.dispose();
    _workPlace.dispose();
    _workUrl.dispose();
    _city.dispose();
    _hometown.dispose();
    _eduMajor.dispose();
    _eduSchool.dispose();
    _eduClass.dispose();
    _facebook.dispose();
    _twitter.dispose();
    _youtube.dispose();
    _instagram.dispose();
    _linkedin.dispose();
    _twitch.dispose();
    _vkontakte.dispose();
    super.dispose();
  }
  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    try {
      _countries = await _countriesService.getCountries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading countries: $e')));
    } finally {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }
  // ---------- Save handlers ----------
  Future<void> _saveBasicInfo() async {
    if (!_formBasic.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String? birthYear, birthMonth, birthDay;
      if (_selectedBirthDate != null) {
        birthYear = _selectedBirthDate!.year.toString();
        birthMonth = _selectedBirthDate!.month.toString();
        birthDay = _selectedBirthDate!.day.toString();
      } else if (widget.profile.birthDate?.isNotEmpty == true) {
        final p = widget.profile.birthDate!.split('-');
        if (p.length == 3) { birthYear = p[0]; birthMonth = p[1]; birthDay = p[2]; }
      }
      String? genderValue;
      if (_selectedGender == 'male') genderValue = '1';
      else if (_selectedGender == 'female') genderValue = '2';
      else if (_selectedGender == 'other') genderValue = '3';
      else if (_selectedGender != null) {
        genderValue = widget.profile.gender == 'male' ? '1' : '2';
      }
      final req = BasicInfoUpdateRequest(
        firstname: _firstname.text.trim(),
        lastname: _lastname.text.trim(),
        gender: genderValue,
        birthMonth: birthMonth,
        birthDay: birthDay,
        birthYear: birthYear,
        country: _selectedCountryId,
        relationship: _selectedRelationship,
        biography: _bio.text.trim(),
        website: _website.text.trim(),
      );
      final res = await _updateService.updateBasicInfo(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _saveWorkInfo() async {
    if (!_formWork.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final req = WorkInfoUpdateRequest(
        workTitle: _workTitle.text.trim(),
        workPlace: _workPlace.text.trim(),
        workUrl: _workUrl.text.trim(),
      );
      final res = await _updateService.updateWorkInfo(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _saveLocation() async {
    if (!_formLoc.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final req = LocationUpdateRequest(
        city: _city.text.trim(),
        hometown: _hometown.text.trim(),
      );
      final res = await _updateService.updateLocation(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _saveEducation() async {
    if (!_formEdu.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final req = EducationUpdateRequest(
        eduMajor: _eduMajor.text.trim(),
        eduSchool: _eduSchool.text.trim(),
        eduClass: _eduClass.text.trim(),
      );
      final res = await _updateService.updateEducation(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _saveSocialLinks() async {
    if (!_formSocial.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final req = SocialLinksUpdateRequest(
        facebook: _facebook.text.trim(),
        twitter: _twitter.text.trim(),
        youtube: _youtube.text.trim(),
        instagram: _instagram.text.trim(),
        linkedin: _linkedin.text.trim(),
        twitch: _twitch.text.trim(),
        vkontakte: _vkontakte.text.trim(),
      );
      final res = await _updateService.updateSocialLinks(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ---------- Image picker sheet ----------
  Future<File?> _pickImageSheet({
    required double maxW,
    required double maxH,
  }) async {
    File? picked;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Image', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _pickTile(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    gradient: AppGradients.basic,
                    onTap: () async {
                      final x = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: maxW,
                        maxHeight: maxH,
                        imageQuality: 85,
                      );
                      if (x != null) picked = File(x.path);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  _pickTile(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    gradient: AppGradients.photos,
                    onTap: () async {
                      final x = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: maxW,
                        maxHeight: maxH,
                        imageQuality: 85,
                      );
                      if (x != null) picked = File(x.path);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return picked;
  }
  Widget _pickTile({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: gradient.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gradient.colors.first.withOpacity(0.35), width: 1.5),
            ),
            child: Center(child: GradientIcon(icon, size: 30, gradient: gradient)),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: cs.onSurface)),
        ],
      ),
    );
  }
  // ---------- Uploaders ----------
  Future<void> _uploadProfilePicture() async {
    if (_selectedProfileImage == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await _updateService.uploadProfilePicture(_selectedProfileImage!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _uploadCoverPhoto() async {
    if (_selectedCoverImage == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await _updateService.uploadCoverPhoto(_selectedCoverImage!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading cover photo: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ---------- Password dialog ----------
  void _showPasswordChangeDialog() {
    final current = TextEditingController();
    final newer = TextEditingController();
    final confirm = TextEditingController();
    bool obC = true, obN = true, obK = true;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const GradientIcon(Iconsax.key, gradient: AppGradients.password),
              const SizedBox(width: 8),
              const Text('Change Password'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _pwdField('Current Password', current, obC, () => setS(() => obC = !obC)),
                const SizedBox(height: 12),
                _pwdField('New Password (≥ 6)', newer, obN, () => setS(() => obN = !obN)),
                const SizedBox(height: 12),
                _pwdField('Confirm Password', confirm, obK, () => setS(() => obK = !obK)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: AppGradients.save,
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () async {
                  if (current.text.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Please enter your current password')));
                    return;
                  }
                  if (newer.text.length < 6) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('New password is too short')));
                    return;
                  }
                  if (newer.text != confirm.text) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    final req = PasswordUpdateRequest(
                      currentPassword: current.text,
                      newPassword: newer.text,
                      confirmPassword: confirm.text,
                    );
                    final res = await _updateService.updatePassword(req);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(res.message)));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _pwdField(
    String label,
    TextEditingController controller,
    bool obscured,
    VoidCallback toggle,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscured,
      decoration: _decoration(label, icon: Iconsax.key, gradient: AppGradients.password).copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscured ? Iconsax.eye_slash : Iconsax.eye),
          onPressed: toggle,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: GradientIcon(Iconsax.key, gradient: AppGradients.password, size: 20),
        ),
      ),
    );
  }
  // ---------- Decorations & Fields ----------
  InputDecoration _decoration(
    String label, {
    required IconData icon,
    required LinearGradient gradient,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: GradientIcon(icon, size: 20, gradient: gradient),
      ),
      filled: true,
      fillColor: cs.surfaceContainerHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gradient.colors.first, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _decoration(label, icon: icon, gradient: gradient),
    );
  }
  Widget _socialField(TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      decoration: _decoration(label, icon: icon, gradient: AppGradients.social).copyWith(
        helperText: 'Example: https://${label.replaceAll(' ', '').toLowerCase()}.com/username',
      ),
    );
  }
  Widget _saveButton({required VoidCallback onPressed, required String label}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: AppGradients.save,
        boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: FilledButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Iconsax.save_2, color: Colors.white, size: 20),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
    );
  }
  CountryData? _getCountryById(String? id) {
    if (id == null) return null;
    for (final c in _countries) {
      if (c.countryId.toString() == id) return c;
    }
    return null;
  }
  Widget _countryPicker(ColorScheme cs) {
    final selected = _getCountryById(_selectedCountryId);
    final selectedName = selected?.countryName;
    return InkWell(
      onTap: _loadingCountries ? null : _openCountrySheet,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration('Country', icon: Iconsax.global, gradient: AppGradients.location)
            .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedName ?? (_loadingCountries ? 'Loading…' : 'Select Country'),
                style: TextStyle(
                  fontSize: 16,
                  color: selectedName != null ? cs.onSurface : cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Iconsax.arrow_down_1, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
  Future<void> _openCountrySheet() async {
    String query = '';
    CountryData? selected;
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        List<CountryData> filtered = _countries;
        return StatefulBuilder(
          builder: (context, setS) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16, right: 16, top: 8,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for a country…',
                      prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (t) {
                      query = t.trim().toLowerCase();
                      setS(() {
                        filtered = _countries
                            .where((c) => c.countryName.toLowerCase().contains(query))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: _countries.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              final isSel = c.countryId.toString() == _selectedCountryId;
                              return ListTile(
                                leading: GradientIcon(
                                  isSel ? Iconsax.record_circle : Iconsax.radio,
                                  gradient: AppGradients.location,
                                  size: 20,
                                ),
                                title: Text(c.countryName),
                                onTap: () {
                                  selected = c;
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() => _selectedCountryId = selected!.countryId.toString());
    }
  }
  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3, color: cs.primary),
                    insets: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(icon: GradientIcon(Iconsax.user_edit, gradient: AppGradients.basic), text: 'Basic'),
                    Tab(icon: GradientIcon(Iconsax.briefcase, gradient: AppGradients.work), text: 'Work'),
                    Tab(icon: GradientIcon(Iconsax.location, gradient: AppGradients.location), text: 'Location'),
                    Tab(icon: GradientIcon(Iconsax.book, gradient: AppGradients.education), text: 'Education'),
                    Tab(icon: GradientIcon(Iconsax.global, gradient: AppGradients.social), text: 'Social'),
                    Tab(icon: GradientIcon(Iconsax.gallery, gradient: AppGradients.photos), text: 'Photos'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _tabBasic(cs),
              _tabWork(cs),
              _tabLocation(cs),
              _tabEducation(cs),
              _tabSocial(cs),
              _tabPhotos(cs),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.12),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
  // ---------- Tabs ----------
  Widget _tabBasic(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formBasic,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              controller: _firstname,
              label: 'First Name',
              icon: Iconsax.user_edit,
              gradient: AppGradients.basic,
              validator: (v) => v!.trim().isEmpty ? 'First name is required' : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _lastname,
              label: 'Last Name',
              icon: Iconsax.user_octagon,
              gradient: AppGradients.basic,
              validator: (v) => v!.trim().isEmpty ? 'Last name is required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: _decoration('Gender', icon: Iconsax.woman, gradient: AppGradients.basic),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedBirthDate ?? DateTime(1995, 1, 1),
                  firstDate: DateTime(1905),
                  lastDate: DateTime(2015),
                );
                if (d != null) setState(() => _selectedBirthDate = d);
              },
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _decoration('Birthdate', icon: Iconsax.cake, gradient: AppGradients.basic)
                    .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : 'Select birth date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedBirthDate != null ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(Iconsax.calendar_1, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRelationship,
              decoration: _decoration('Relationship Status', icon: Iconsax.heart, gradient: AppGradients.basic),
              items: const [
                DropdownMenuItem(value: 'single', child: Text('Single')),
                DropdownMenuItem(value: 'relationship', child: Text('In a relationship')),
                DropdownMenuItem(value: 'married', child: Text('Married')),
                DropdownMenuItem(value: 'complicated', child: Text('It\'s complicated')),
                DropdownMenuItem(value: 'separated', child: Text('Separated')),
                DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
              ],
              onChanged: (v) => setState(() => _selectedRelationship = v),
            ),
            const SizedBox(height: 12),
            _countryPicker(cs),
            const SizedBox(height: 12),
            _field(
              controller: _bio,
              label: 'About you',
              icon: Iconsax.note_text,
              gradient: AppGradients.basic,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _website,
              label: 'Website',
              icon: Iconsax.link,
              gradient: AppGradients.basic,
              keyboardType: TextInputType.url,
              validator: (v) {
                final t = v!.trim();
                if (t.isEmpty) return null;
                final uri = Uri.tryParse(t);
                final ok = uri != null && (uri.hasScheme && uri.host.isNotEmpty);
                return ok ? null : 'Invalid URL';
              },
            ),
            const SizedBox(height: 20),
            _saveButton(onPressed: _saveBasicInfo, label: 'Save'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showPasswordChangeDialog,
              icon: const GradientIcon(Iconsax.key, gradient: AppGradients.password, size: 20),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _tabWork(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formWork,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            _field(
              controller: _workTitle,
              label: 'Job Title',
              icon: Iconsax.briefcase,
              gradient: AppGradients.work,
              validator: (v) => v!.trim().isEmpty ? 'Enter job title' : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _workPlace,
              label: 'Company',
              icon: Iconsax.building,
              gradient: AppGradients.work,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _workUrl,
              label: 'Company Website',
              icon: Iconsax.link,
              gradient: AppGradients.work,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            _saveButton(onPressed: _saveWorkInfo, label: 'Save'),
          ],
        ),
      ),
    );
  }
  Widget _tabLocation(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formLoc,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            _field(
              controller: _city,
              label: 'Current City',
              icon: Iconsax.location_tick,
              gradient: AppGradients.location,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _hometown,
              label: 'Hometown',
              icon: Iconsax.home_2,
              gradient: AppGradients.location,
            ),
            const SizedBox(height: 20),
            _saveButton(onPressed: _saveLocation, label: 'Save'),
          ],
        ),
      ),
    );
  }
  Widget _tabEducation(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formEdu,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            _field(
              controller: _eduMajor,
              label: 'Major',
              icon: Iconsax.book_1,
              gradient: AppGradients.education,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _eduSchool,
              label: 'Educational Institution',
              icon: Iconsax.building,
              gradient: AppGradients.education,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _eduClass,
              label: 'Graduation Year',
              icon: Iconsax.calendar_1,
              gradient: AppGradients.education,
            ),
            const SizedBox(height: 20),
            _saveButton(onPressed: _saveEducation, label: 'Save'),
          ],
        ),
      ),
    );
  }
  Widget _tabSocial(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formSocial,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            _socialField(_facebook, 'Facebook', Iconsax.facebook),
            const SizedBox(height: 12),
            _socialField(_twitter, 'Twitter/X', Iconsax.presention_chart),
            const SizedBox(height: 12),
            _socialField(_youtube, 'YouTube', Iconsax.video_play),
            const SizedBox(height: 12),
            _socialField(_instagram, 'Instagram', Iconsax.instagram),
            const SizedBox(height: 12),
            _socialField(_linkedin, 'LinkedIn', Iconsax.briefcase),
            const SizedBox(height: 12),
            _socialField(_twitch, 'Twitch', Iconsax.game),
            const SizedBox(height: 12),
            _socialField(_vkontakte, 'VKontakte', Iconsax.user_square),
            const SizedBox(height: 20),
            _saveButton(onPressed: _saveSocialLinks, label: 'Save'),
          ],
        ),
      ),
    );
  }
  Widget _tabPhotos(ColorScheme cs) {
    final coverFallback = widget.profile.cover;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Profile Picture', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                children: [
                  // Outer gradient ring
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.photos,
                      boxShadow: [
                        BoxShadow(
                          color: AppGradients.photos.colors.first.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                  // Image with inner padding
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: cs.surface,
                      child: CircleAvatar(
                        radius: 56,
                        backgroundImage: _selectedProfileImage != null
                            ? FileImage(_selectedProfileImage!)
                            : CachedNetworkImageProvider(widget.profile.picture) as ImageProvider,
                      ),
                    ),
                  ),
                  // Edit button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickProfileImage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.basic,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: const Icon(Iconsax.camera, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Cover Photo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickCoverImage,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: cs.surfaceContainerHigh,
                  image: _selectedCoverImage != null
                      ? DecorationImage(image: FileImage(_selectedCoverImage!), fit: BoxFit.cover)
                      : (coverFallback != null
                          ? DecorationImage(image: CachedNetworkImageProvider(coverFallback), fit: BoxFit.cover)
                          : null),
                ),
                child: (_selectedCoverImage == null && coverFallback == null)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: DottedBorder(
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GradientIcon(Iconsax.gallery_add, size: 48, gradient: AppGradients.photos),
                                  const SizedBox(height: 12),
                                  Text('Tap to add a cover photo',
                                      style: TextStyle(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.basic,
                              border: Border.all(color: cs.surface, width: 2),
                            ),
                            child: const Icon(Iconsax.edit, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
  Future<void> _pickCoverImage() async {
    final file = await _pickImageSheet(maxW: 1920, maxH: 1080);
    if (file == null) return;
    setState(() => _selectedCoverImage = file);
    await _uploadCoverPhoto();
  }
  Future<void> _pickProfileImage() async {
    final file = await _pickImageSheet(maxW: 1024, maxH: 1024);
    if (file == null) return;
    setState(() => _selectedProfileImage = file);
    await _uploadProfilePicture();
  }
}
/// ---------- LinearGradient helpers ----------
extension LinearGradientOpacity on LinearGradient {
  LinearGradient withOpacity(double opacity) {
    return LinearGradient(
      colors: colors.map((c) => c.withValues(alpha: opacity)).toList(),
      begin: begin,
      end: end,
      stops: stops,
      transform: transform,
      tileMode: tileMode,
    );
  }
}
