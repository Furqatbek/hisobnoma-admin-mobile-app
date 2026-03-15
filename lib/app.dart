import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/core/theme/app_theme.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/blocs/reports/reports_cubit.dart';
import 'package:hisobnoma/presentation/blocs/settings/settings_cubit.dart';
import 'package:hisobnoma/presentation/blocs/alerts/alerts_cubit.dart';

/// Root application widget
class HisobnomaApp extends StatelessWidget {
  const HisobnomaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()..checkAuth()),
        BlocProvider(create: (_) => getIt<DashboardCubit>()),
        BlocProvider(create: (_) => getIt<TransactionsCubit>()),
        BlocProvider(create: (_) => getIt<ReportsCubit>()),
        BlocProvider(create: (_) => getIt<SettingsCubit>()..loadSettings()),
        BlocProvider(create: (_) => getIt<AlertsCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsState.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
