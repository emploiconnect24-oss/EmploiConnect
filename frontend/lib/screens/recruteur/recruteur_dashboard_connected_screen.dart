import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/recruteur_provider.dart';
import 'pages/dashboard_overview_page.dart';

class RecruteurDashboardConnectedScreen extends StatelessWidget {
  const RecruteurDashboardConnectedScreen({super.key, this.onShellNavigate});

  final void Function(String route)? onShellNavigate;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruteurProvider>();
    if (provider.isLoading && provider.dashboardData == null && provider.error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.dashboardData == null) {
      return Center(child: Text(provider.error!));
    }
    return DashboardOverviewPage(onShellNavigate: onShellNavigate);
  }
}
