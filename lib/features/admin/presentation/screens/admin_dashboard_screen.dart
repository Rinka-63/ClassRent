import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Admin Dashboard',
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _AdminTile(
            icon: Icons.meeting_room_outlined,
            label: 'Room Management',
            onTap: () => context.push(AppRoutes.roomManagement),
          ),
          _AdminTile(
            icon: Icons.fact_check_outlined,
            label: 'Booking Management',
            onTap: () => context.push(AppRoutes.bookingManagement),
          ),
          _AdminTile(
            icon: Icons.support_agent_outlined,
            label: 'Support',
            onTap: () => context.push(AppRoutes.support),
          ),
          _AdminTile(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Create Staff',
            onTap: () => context.push(AppRoutes.createStaff),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
