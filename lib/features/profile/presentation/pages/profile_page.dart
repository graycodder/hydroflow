import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String uid = '';

    final salesman = (authState is AuthAuthenticated) ? authState.salesman : null;
    if (salesman != null) {
      uid = salesman.id;
    }

    final prefs = sl<SharedPreferences>();
    final isAgencyViewPref = (prefs.getBool('dashboard_is_agency_view') ?? false) &&
        (salesman?.role == 'owner');

    return BlocProvider(
      create: (context) {
        final bloc = sl<ProfileBloc>();
        if (isAgencyViewPref && salesman != null) {
          bloc.add(LoadAgencyProfile(uid, salesman.agencyId));
        } else {
          bloc.add(LoadProfile(uid));
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (salesman != null && salesman.role == 'owner') {
              if (state.isAgencyView != isAgencyViewPref) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (isAgencyViewPref) {
                    context.read<ProfileBloc>().add(LoadAgencyProfile(uid, salesman.agencyId));
                  } else {
                    context.read<ProfileBloc>().add(LoadProfile(uid));
                  }
                });
                return Center(
                    child: HydroFlowLoader(message: 'Switching View...', isOverlay: false));
              }
            }

            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProfileError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is ProfileLoaded) {
              final profile = state.profile;
              final isAgency = state.isAgencyView;
              final agency = state.agency;

              final displayName = isAgency ? (agency?.name ?? 'Agency Name') : profile.name;
              final roleDisplay = profile.role.isNotEmpty
                  ? profile.role[0].toUpperCase() + profile.role.substring(1)
                  : '';
              final zoneDisplay = profile.zone.isNotEmpty
                  ? ' • ${profile.zone[0].toUpperCase() + profile.zone.substring(1)}'
                  : '';
              final displayRole = isAgency ? 'Agency Profile' : '$roleDisplay$zoneDisplay';

              final agencyPhone = agency?.contactPhone ?? '';
              final displayPhone =
                  (isAgency && agencyPhone.isNotEmpty) ? agencyPhone : profile.phone;

              final agencyAddress = agency?.address ?? '';
              final displayAddress =
                  (isAgency && agencyAddress.isNotEmpty) ? agencyAddress : profile.address;

              return CustomScrollView(
                slivers: [
                  // ── Gradient App Bar ──
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor:
                        isAgency ? const Color(0xFFE65100) : const Color(0xFF1565C0),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _ProfileHeader(
                        displayName: displayName,
                        displayRole: displayRole,
                        displayPhone: displayPhone,
                        displayAddress: displayAddress,
                        isAgency: isAgency,
                        onClose: () => context.pop(),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Agency-only sections ──
                          if (isAgency && profile.role == 'owner') ...[
                            // ── Subscription Section ──
                            _buildSectionLabel('Subscription'),
                            _DrawerMenuCard(
                              children: [
                                _DrawerTile(
                                  icon: Icons.workspace_premium_outlined,
                                  iconColor: const Color(0xFF7B1FA2),
                                  iconBg: const Color(0xFFF3E5F5),
                                  title: 'Current Plan',
                                  subtitle: _currentPlanLabel(state.subscriptionHistory),
                                  onTap: () => _showCurrentPlanSheet(
                                      context, state.subscriptionHistory),
                                ),
                                _DrawerDivider(),
                                _DrawerTile(
                                  icon: Icons.history_outlined,
                                  iconColor: const Color(0xFF0288D1),
                                  iconBg: const Color(0xFFE1F5FE),
                                  title: 'Subscription History',
                                  subtitle:
                                      '${profile.totalSubscriptions} plan${profile.totalSubscriptions == 1 ? '' : 's'} • ₹${profile.totalAmountPaid.toStringAsFixed(0)} total',
                                  onTap: () => _showSubscriptionSheet(
                                      context, state.subscriptionHistory, profile),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Staff Section ──
                            _buildSectionLabel('Team'),
                            _DrawerMenuCard(
                              children: [
                                _DrawerTile(
                                  icon: Icons.people_outline,
                                  iconColor: const Color(0xFF00897B),
                                  iconBg: const Color(0xFFE0F2F1),
                                  title: 'Manage Staff & Devices',
                                  subtitle: 'View and manage your sales team',
                                  trailing: const Icon(Icons.chevron_right_rounded,
                                      color: Colors.grey),
                                  onTap: () => context.push('/agency_employees'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Business Settings Section ──
                            _buildSectionLabel('Business Settings'),
                            if (agency != null)
                              _DrawerMenuCard(
                                children: [
                                  _DrawerTile(
                                    icon: Icons.monetization_on_outlined,
                                    iconColor: const Color(0xFFE65100),
                                    iconBg: const Color(0xFFFFF3E0),
                                    title: 'Default Bottle Price',
                                    subtitle: 'Price per bottle for all deliveries',
                                    trailing: Text(
                                      '₹${agency.defaultBottlePrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                    onTap: () =>
                                        _showPriceEditDialog(context, agency),
                                  ),
                                  _DrawerDivider(),
                                  _EnforceFixedPriceTile(
                                    agency: agency,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                          ],

                          // ── Account Section ──
                          _buildSectionLabel('Account'),
                          _DrawerMenuCard(
                            children: [
                              _DrawerTile(
                                icon: Icons.phone_outlined,
                                iconColor: const Color(0xFF388E3C),
                                iconBg: const Color(0xFFE8F5E9),
                                title: 'Phone',
                                subtitle: displayPhone.isNotEmpty ? displayPhone : '—',
                              ),
                              _DrawerDivider(),
                              _DrawerTile(
                                icon: Icons.location_on_outlined,
                                iconColor: const Color(0xFFEF6C00),
                                iconBg: const Color(0xFFFFF3E0),
                                title: 'Address',
                                subtitle: displayAddress.isNotEmpty ? displayAddress : '—',
                              ),
                              if (isAgency) ...[
                                _DrawerDivider(),
                                _DrawerTile(
                                  icon: Icons.calendar_today_outlined,
                                  iconColor: const Color(0xFF5C6BC0),
                                  iconBg: const Color(0xFFE8EAF6),
                                  title: 'Member Since',
                                  subtitle: DateFormat('MMMM yyyy')
                                      .format(profile.membershipDate),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Legal Section ──
                          _buildSectionLabel('Legal'),
                          _DrawerMenuCard(
                            children: [
                              _DrawerTile(
                                icon: Icons.description_outlined,
                                iconColor: const Color(0xFF546E7A),
                                iconBg: const Color(0xFFECEFF1),
                                title: 'Terms of Service',
                                trailing: const Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey),
                                onTap: () => context.push('/terms'),
                              ),
                              _DrawerDivider(),
                              _DrawerTile(
                                icon: Icons.privacy_tip_outlined,
                                iconColor: const Color(0xFF546E7A),
                                iconBg: const Color(0xFFECEFF1),
                                title: 'Privacy Policy',
                                trailing: const Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey),
                                onTap: () => context.push('/privacy'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const Center(child: Text('Initializing...'));
          },
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _currentPlanLabel(List<SubscriptionRecord> history) {
    if (history.isEmpty) return 'No active plan';
    try {
      final activePlans = history.where((s) => s.isActive);
      final active = activePlans.isNotEmpty ? activePlans.first : history.first;
      return '${active.planName} • ${active.status} • Expires ${DateFormat('dd MMM yyyy').format(active.expiryDate)}';
    } catch (_) {
      return 'View plan details';
    }
  }

  void _showCurrentPlanSheet(
      BuildContext context, List<SubscriptionRecord> history) {
    SubscriptionRecord? currentPlan;
    if (history.isNotEmpty) {
      final activePlans = history.where((s) => s.isActive);
      currentPlan = activePlans.isNotEmpty ? activePlans.first : history.first;
    }
    final displayList = currentPlan != null ? [currentPlan] : <SubscriptionRecord>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, controller) => _buildSheetContainer(
            context, displayList, 'Current Plan', Icons.workspace_premium, controller),
      ),
    );
  }

  void _showSubscriptionSheet(
      BuildContext context, List<SubscriptionRecord> history, dynamic profile) {
    
    final sortedHistory = List<SubscriptionRecord>.from(history);
    sortedHistory.sort((a, b) {
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;
      return b.expiryDate.compareTo(a.expiryDate);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, controller) => _buildSheetContainer(
            context, sortedHistory, 'Subscription Details', Icons.history, controller,
            showCount: true),
      ),
    );
  }

  Widget _buildSheetContainer(
      BuildContext context, List<SubscriptionRecord> items, String title,
      IconData icon, ScrollController controller,
      {bool showCount = false}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF7B1FA2)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (showCount) ...[
                  const Spacer(),
                  Text(
                    '${items.length} plan${items.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                ] else
                  const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No plans found.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) => _SubscriptionCard(record: items[i]),
              ),
            ),
        ],
      ),
    );
  }

  void _showPriceEditDialog(BuildContext context, Agency agency) {
    final controller =
        TextEditingController(text: agency.defaultBottlePrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Default Price'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price Per Bottle (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null) {
                context.read<ProfileBloc>().add(UpdateAgencySettings(
                      agency.id,
                      {'defaultBottlePrice': price},
                    ));
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String displayRole;
  final String displayPhone;
  final String displayAddress;
  final bool isAgency;
  final VoidCallback onClose;

  const _ProfileHeader({
    required this.displayName,
    required this.displayRole,
    required this.displayPhone,
    required this.displayAddress,
    required this.isAgency,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = isAgency ? const Color(0xFFE65100) : const Color(0xFF1565C0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerColor, headerColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: Icon(
              isAgency ? Icons.business_rounded : Icons.person_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayRole,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (displayPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        displayPhone,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// App Drawer Card
// ─────────────────────────────────────────────
class _DrawerMenuCard extends StatelessWidget {
  final List<Widget> children;
  const _DrawerMenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 68, endIndent: 0, thickness: 0.8);
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _DrawerTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Enforce Fixed Price Toggle Tile (needs BLoC)
// ─────────────────────────────────────────────
class _EnforceFixedPriceTile extends StatelessWidget {
  final Agency agency;
  const _EnforceFixedPriceTile({required this.agency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFFE65100), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Enforce Fixed Price',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Salesmen cannot change price during delivery',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: agency.enforceFixedPrice,
            activeColor: const Color(0xFFE65100),
            onChanged: (value) {
              context.read<ProfileBloc>().add(UpdateAgencySettings(
                    agency.id,
                    {'enforceFixedPrice': value},
                  ));
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Subscription Card (uses real SubscriptionRecord)
// ─────────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final SubscriptionRecord record;
  const _SubscriptionCard({required this.record});

  double _progress() {
    if (!record.isActive) return 1.0;
    final total = record.expiryDate.difference(record.startDate).inSeconds;
    final elapsed = DateTime.now().difference(record.startDate).inSeconds;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = record.isActive;
    final isPending = record.status.toLowerCase() == 'pending';
    final activeColor = const Color(0xFF7B1FA2);
    final pendingColor = const Color(0xFFF57C00);
    
    final mainStatusColor = isActive ? activeColor : (isPending ? pendingColor : Colors.grey.shade500);
    final badgeBgColor = isActive ? activeColor : (isPending ? pendingColor : Colors.grey.shade300);
    final badgeTextColor = isActive || isPending ? Colors.white : Colors.black54;

    final bgColor = isActive ? const Color(0xFFF3E5F5) : const Color(0xFFFAFAFA);
    final borderColor = isActive ? activeColor : (isPending ? pendingColor.withOpacity(0.5) : Colors.grey.shade200);
    final daysRemaining =
        record.expiryDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + plan name + status badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mainStatusColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.verified_rounded : (isPending ? Icons.hourglass_empty_rounded : Icons.history_rounded),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.planName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isActive ? activeColor : (isPending ? pendingColor : Colors.black87),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            record.status[0].toUpperCase()+record.status.substring(1),
                            style: TextStyle(
                              color: badgeTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Txn: ${record.transactionId}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Detail grid ──
          Row(
            children: [
              _DetailCol('Payment Date',
                  DateFormat('dd MMM yyyy').format(record.paymentDate)),
              _DetailCol('Amount',
                  '₹${record.amount.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF2E7D32), bold: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _DetailCol('Start Date',
                  DateFormat('dd MMM yyyy').format(record.startDate)),
              _DetailCol('Expiry Date',
                  DateFormat('dd MMM yyyy').format(record.expiryDate)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // ── Duration + Progress ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration: ${record.duration}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              if (isActive)
                Text(
                  '$daysRemaining day${daysRemaining == 1 ? '' : 's'} left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: daysRemaining < 7
                        ? const Color(0xFFE65100)
                        : activeColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress(),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(mainStatusColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _DetailCol(this.label, this.value,
      {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
