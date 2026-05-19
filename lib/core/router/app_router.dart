import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_tracker_mobile/features/shared/main_shell.dart';
import 'package:sales_tracker_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:sales_tracker_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:sales_tracker_mobile/features/prospecting/presentation/pages/quick_prospecting_page.dart';
import 'package:sales_tracker_mobile/features/customer/presentation/pages/add_customer_page.dart';
import 'package:sales_tracker_mobile/features/customer/presentation/pages/customer_list_page.dart';
import 'package:sales_tracker_mobile/features/customer/presentation/pages/customer_detail_page.dart';
import 'package:sales_tracker_mobile/features/customer/presentation/pages/customer_tagging_page.dart';
import 'package:sales_tracker_mobile/features/visit/presentation/pages/checkout_page.dart';
import 'package:sales_tracker_mobile/features/orders/presentation/pages/order_review_page.dart';
import 'package:sales_tracker_mobile/features/orders/presentation/pages/order_detail_page.dart';
import 'package:sales_tracker_mobile/features/orders/presentation/pages/product_catalog_page.dart';
import 'package:sales_tracker_mobile/features/orders/presentation/pages/product_order_page.dart';
import 'package:sales_tracker_mobile/features/orders/data/models/product_model.dart';
import 'package:sales_tracker_mobile/features/orders/data/models/cart_item_model.dart';
import 'package:sales_tracker_mobile/features/orders/presentation/pages/order_history_page.dart';
import 'package:sales_tracker_mobile/features/schedule/presentation/pages/route_schedule_page.dart';
import 'package:sales_tracker_mobile/features/activity/presentation/pages/daily_activity_page.dart';
import 'package:sales_tracker_mobile/features/reports/presentation/pages/sales_performance_report_page.dart';
import 'package:sales_tracker_mobile/features/profile/presentation/pages/user_profile_page.dart';
import 'package:sales_tracker_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:sales_tracker_mobile/features/notifications/presentation/pages/notifications_page.dart';

import 'package:sales_tracker_mobile/features/shared/presentation/pages/splash_page.dart';
import 'package:sales_tracker_mobile/features/shared/presentation/pages/permission_request_page.dart';

// Keys for Navigation
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/permission',
      builder: (context, state) => const PermissionRequestPage(),
    ),
    GoRoute(
      path: '/prospecting',
      builder: (context, state) => const QuickProspectingPage(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordPage(),
    ),
    GoRoute(
      path: '/add-customer',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return AddCustomerPage(initialData: data);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CheckoutPage(
          kunjunganId: extra?['kunjunganId'],
          pelangganId: extra?['pelangganId'],
          visitData: extra?['visitData'],
        );
      },
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ProductCatalogPage(
          kunjunganId: extra?['kunjunganId'],
          pelangganId: extra?['pelangganId'],
          pelangganData: extra?['pelangganData'],
          isEdit: extra?['isEdit'] ?? false,
          orderId: extra?['orderId'],
          localRef: extra?['localRef'],
          initialNotes: extra?['initialNotes'],
        );
      },
    ),
    GoRoute(
      path: '/product-order',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final rawPelangganId = extra?['pelangganId'];
        return ProductOrderPage(
          product: extra?['product'] as Product,
          pelangganId: rawPelangganId?.toString(),
          existingCartItem: extra?['existingCartItem'] as CartItem?,
        );
      },
    ),
    GoRoute(
      path: '/order-review',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OrderReviewPage(
          kunjunganId: extra?['kunjunganId'],
          pelangganId: extra?['pelangganId'],
          pelangganData: extra?['pelangganData'],
          isEdit: extra?['isEdit'] ?? false,
          orderId: extra?['orderId'],
          localRef: extra?['localRef'],
          initialNotes: extra?['initialNotes'],
        );
      },
    ),
    // Alias: /catalog → same as /products (for backward compat with OrderReviewPage)
    GoRoute(
      path: '/catalog',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ProductCatalogPage(
          kunjunganId: extra?['kunjunganId'],
          pelangganId: extra?['pelangganId'],
          pelangganData: extra?['pelangganData'],
          isEdit: extra?['isEdit'] ?? false,
          orderId: extra?['orderId'],
          localRef: extra?['localRef'],
          initialNotes: extra?['initialNotes'],
        );
      },
    ),
    GoRoute(
      path: '/orders/detail',
      builder: (context, state) {
        final order = state.extra as Map<String, dynamic>? ?? {};
        return OrderDetailPage(order: order);
      },
    ),
    GoRoute(
      path: '/customers/detail',
      builder: (context, state) {
        final visitData = state.extra as Map<String, dynamic>?;
        return CustomerDetailPage(visitData: visitData);
      },
    ),
    GoRoute(
      path: '/customers/tagging',
      builder: (context, state) {
        final customer = state.extra as Map<String, dynamic>;
        return CustomerTaggingPage(customer: customer);
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerListPage(),
        ),
        GoRoute(
          path: '/schedule',
          builder: (context, state) => const RouteSchedulePage(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: '/activity',
          builder: (context, state) => const DailyActivityPage(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const SalesPerformanceReportPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const UserProfilePage(),
        ),
      ],
    ),
  ],
);
