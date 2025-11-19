import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/core/widgets/loading_widget.dart';
import 'package:invoice/core/widgets/error_widget.dart';
import 'package:invoice/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:invoice/features/auth/presentation/bloc/auth_event.dart';
import 'package:invoice/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/monthly_chart.dart';
import '../widgets/recent_invoices_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();

    // Load data after first frame if auth is already ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;

      if (authState is Authenticated && !_hasLoadedData) {

        _loadDashboardData(authState.user.id);
      }
    });
  }

  void _loadDashboardData(String userId) {
    if (_hasLoadedData) return;

    context.read<DashboardBloc>().add(LoadDashboardData(userId));
    _hasLoadedData = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {

        if (authState is Authenticated && !_hasLoadedData) {

          _loadDashboardData(authState.user.id);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is Authenticated) {
                return Text('داشبورد - خوش آمدید ${authState.user.fullName}');
              }
              return const Text('داشبورد');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  _hasLoadedData = false;
                  _loadDashboardData(authState.user.id);
                }
              },
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            debugPrint('🔍 Dashboard State: ${state.runtimeType}');
            
            if (state is DashboardInitial || state is DashboardLoading) {
              return const LoadingWidget(message: 'در حال بارگزاری داشبورد...');
            } else if (state is DashboardError) {
              return ErrorDisplayWidget(
                message: state.message,
                onRetry: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is Authenticated) {
                    _hasLoadedData = false;
                    _loadDashboardData(authState.user.id);
                  }
                },
              );
            } else if (state is DashboardLoaded) {
              return _buildDashboardContent(state.dashboardData);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'مدیریت فاکتور',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'سیستم مدیریت فاکتور و مشتریان',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('داشبورد'),
            selected: true,
            onTap: () {
              Navigator.of(context).pop(); // بستن drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('مدیریت کاربران'),
            onTap: () {
              Navigator.of(context).pop(); // بستن drawer
              Navigator.of(context).pushNamed('/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('مدیریت مشتریان'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/customers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('مدیریت فاکتورها'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/documents');
            },
          ),
          ListTile(
            leading: const Icon(Icons.approval),
            title: const Text('کارتابل تأیید'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/approvals');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('آمار و گزارشات'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to statistics
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('تنظیمات'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('خروج'),
            onTap: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const LogoutRequested());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(dynamic dashboardData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // کارت‌های آمار
          Row(
            children: [
              Expanded(
                child: DashboardStatsCard(
                  title: 'کل فاکتورها',
                  value: dashboardData.totalInvoices.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DashboardStatsCard(
                  title: 'مجموع درآمد',
                  value: '${dashboardData.totalRevenue.toStringAsFixed(0)} تومان',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DashboardStatsCard(
                  title: 'کل مشتریان',
                  value: dashboardData.totalCustomers.toString(),
                  icon: Icons.people,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DashboardStatsCard(
                  title: 'فاکتورهای معلق',
                  value: dashboardData.pendingInvoices.toString(),
                  icon: Icons.pending,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // نمودار ماهانه
          const Text(
            'آمار ماهانه',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          MonthlyChart(monthlyData: dashboardData.monthlyData),

          const SizedBox(height: 24),

          // فاکتورهای اخیر
          const Text(
            'فاکتورهای اخیر',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          RecentInvoicesList(invoices: dashboardData.recentInvoices),
        ],
      ),
    );
  }
}
