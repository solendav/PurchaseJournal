import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/core/error/error_message_mapper.dart';
import 'package:purchase_journal/core/widgets/user_avatar.dart';
import 'package:purchase_journal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:purchase_journal/features/profile/data/member_remote_datasource.dart';
import 'package:purchase_journal/features/profile/presentation/widgets/profile_settings_widgets.dart';
import 'package:purchase_journal/injection_container.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  bool _loggingOut = false;

  bool _membersLoading = false;
  List<MemberModel> _members = [];
  String? _membersError;

  AuthSession get _auth => sl<AuthSession>();
  AuthRemoteDataSource get _authDataSource => sl<AuthRemoteDataSource>();
  bool _membersRequested = false;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    _syncFromUser();
    _scheduleMembersLoad();
  }

  void _onAuthChanged() {
    _syncFromUser();
    _scheduleMembersLoad();
  }

  void _scheduleMembersLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _requestMembersOnce();
    });
  }

  void _syncFromUser() {
    final user = _auth.user;
    if (user == null) return;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
  }

  Future<void> _loadMembersIfOwner() async {
    final user = _auth.user;
    if (user == null || !user.isOwner) return;
    if (_membersLoading) return;

    setState(() {
      _membersLoading = true;
      _membersError = null;
    });

    try {
      final members = await sl<MemberRemoteDataSource>()
          .list()
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() => _members = members);
    } catch (e) {
      if (!mounted) return;
      setState(() => _membersError = ErrorMessageMapper.message(e));
    } finally {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  void _retryLoadMembers() {
    _membersError = null;
    _loadMembersIfOwner();
  }

  void _requestMembersOnce() {
    if (_membersRequested) return;
    final user = _auth.user;
    if (user == null || !user.isOwner) return;
    _membersRequested = true;
    _loadMembersIfOwner();
  }

  Future<void> _addMember() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final firstName = TextEditingController();
    final lastName = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First name')),
              const SizedBox(height: 10),
              TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last name')),
              const SizedBox(height: 10),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Temporary password (min 8 chars)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );

    final emailText = email.text.trim();
    final passText = password.text;
    final firstText = firstName.text.trim();
    final lastText = lastName.text.trim();
    email.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();

    if (created != true) return;

    try {
      await sl<MemberRemoteDataSource>().create(
        email: emailText,
        password: passText,
        firstName: firstText,
        lastName: lastText,
      );
      await _loadMembersIfOwner();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _removeMember(MemberModel member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove member'),
        content: Text('Remove ${member.email}? They will lose access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await sl<MemberRemoteDataSource>().remove(member.id);
      await _loadMembersIfOwner();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _authDataSource.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      await _auth.refreshUser();
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await _auth.logout();
      if (mounted) context.go(RouteNames.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final user = _auth.user;
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final textTheme = Theme.of(context).textTheme;
        final fullName = '${user.firstName} ${user.lastName}'.trim();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: UserAvatar(name: user.displayName, radius: 44),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'PURCHASE JOURNAL',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const ProfileSectionTitle('Account'),
              ProfileSettingsCard(
                children: [
                  if (_editing) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'First name'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Last name'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _saving
                                      ? null
                                      : () {
                                          _syncFromUser();
                                          setState(() => _editing = false);
                                        },
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _saving ? null : _save,
                                  child: _saving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ProfileSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Name',
                      subtitle: fullName.isEmpty ? '—' : fullName,
                    ),
                    ProfileSettingsTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: user.email,
                    ),
                    ProfileSettingsTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit profile',
                      subtitle: 'Update your name',
                      onTap: () => setState(() => _editing = true),
                      showChevron: true,
                    ),
                  ],
                ],
              ),
              if (user.isOwner) ...[
                const SizedBox(height: 24),
                ProfileSectionTitle('Members'),
                ProfileSettingsCard(
                  children: [
                    ProfileSettingsTile(
                      icon: Icons.group_add_outlined,
                      title: 'Add member',
                      subtitle: 'Let someone add purchases and payments',
                      onTap: _membersLoading ? null : _addMember,
                      showChevron: true,
                    ),
                    if (_membersLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Loading members...', style: TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      )
                    else if (_membersError != null)
                      ProfileSettingsTile(
                        icon: Icons.wifi_off_rounded,
                        title: 'Could not load members',
                        subtitle: 'Tap to retry',
                        onTap: _retryLoadMembers,
                        showChevron: true,
                      )
                    else if (_members.isEmpty)
                      const ProfileSettingsTile(
                        icon: Icons.people_outline,
                        title: 'No members yet',
                        subtitle: 'Add a member to help record purchases.',
                      )
                    else
                      ..._members.map(
                        (m) => ProfileSettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: m.displayName,
                          subtitle: m.email,
                          onTap: () => _removeMember(m),
                          showChevron: true,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const ProfileSectionTitle('About'),
              const ProfileSettingsCard(
                children: [
                  ProfileSettingsTile(
                    icon: Icons.menu_book_outlined,
                    title: 'Purchase Journal',
                    subtitle: 'Track purchases, suppliers, and debt',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _loggingOut ? null : _logout,
                  icon: _loggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout_rounded, color: AppColors.danger),
                  label: Text(
                    _loggingOut ? 'Signing out...' : 'Sign out',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
