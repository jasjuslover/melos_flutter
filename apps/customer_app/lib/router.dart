import 'package:customer_app/features/auth/auth_controller.dart';
import 'package:customer_app/features/auth/login_page.dart';
import 'package:customer_app/features/auth/register_page.dart';
import 'package:customer_app/features/auth/splash_page.dart';
import 'package:customer_app/features/products/product_form_page.dart';
import 'package:customer_app/features/products/product_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/products',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final onAuthPage = location == '/login' || location == '/register';

      switch (status) {
        case AuthStatus.unknown:
          return location == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return onAuthPage ? null : '/login';
        case AuthStatus.authenticated:
          return (onAuthPage || location == '/splash') ? '/products' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ProductFormPage(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => ProductFormPage(
              productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            ),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });

  return router;
});
