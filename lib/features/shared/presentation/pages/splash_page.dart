import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_tracker_mobile/core/auth/user_provider.dart';
import 'package:sales_tracker_mobile/core/permission/permission_service.dart';
import 'package:sales_tracker_mobile/core/services/token_storage.dart';
import 'package:sales_tracker_mobile/core/services/preload_service.dart';
import 'package:sales_tracker_mobile/core/theme/app_colors.dart';
import 'package:sales_tracker_mobile/core/theme/app_spacing.dart';
import 'package:sales_tracker_mobile/core/theme/app_text_styles.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    try {
      debugPrint('Startup: Beginning splash delay...');
      // Small delay for branding visibility
      await Future.delayed(const Duration(seconds: 1));

      debugPrint('Startup: Checking permissions...');
      // 1. Check Permissions with a timeout to prevent hanging
      final hasPermissions = await PermissionService.checkAllPermissions()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Startup: Permission check timed out!');
              return false;
            },
          );
      debugPrint('Startup: Permissions status: $hasPermissions');

      if (!hasPermissions) {
        if (mounted) context.go('/permission');
        return;
      }

      debugPrint('Startup: Checking auth status...');
      final prefs = await SharedPreferences.getInstance();
      final hasToken = await ref.read(tokenStorageProvider).hasToken();
      final cachedUserStr = prefs.getString('user_data') ?? '';
      final hasCachedUser = cachedUserStr.isNotEmpty;
      final user = ref.read(userProvider);
      final isAuthenticated = hasToken || hasCachedUser || user != null;
      debugPrint(
        'Startup: Auth state token=$hasToken cachedUser=$hasCachedUser providerUser=${user != null}',
      );

      if (mounted) {
        if (isAuthenticated) {
          if (user == null && hasCachedUser) {
            try {
              final decoded = jsonDecode(cachedUserStr) as Map<String, dynamic>;
              ref.read(userProvider.notifier).setUser(decoded);
            } catch (e) {
              debugPrint('Startup: Failed to hydrate userProvider from cache: $e');
            }
          }

          debugPrint('Startup: Starting PreloadService...');
          // Preload all data to Drift before going to home
          // This ensures data is available immediately on dashboard
          unawaited(ref.read(preloadServiceProvider).runIfStale());

          debugPrint('Startup: Navigating to Home');
          context.go('/home');
        } else {
          debugPrint('Startup: Navigating to Login');
          context.go('/login');
        }
      }
    } catch (e) {
      debugPrint('Startup Error: $e');
      // Fallback to login if something goes wrong to avoid getting stuck
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                child: Image.asset(
                  'assets/images/logo-app.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Sales Tracker',
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.textOnPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
