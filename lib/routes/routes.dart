import 'package:flutter/material.dart';
import 'package:smart_carts/screens/screens.dart';
import 'package:smart_carts/screens/summary_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String register = '/register';
  static const String confirmRegistration = '/confirm_registration';
  static const String login = '/login';
  static const String customerMenu = '/customer_menu';
  static const String shoppingCart = '/shopping_cart';
  static const String summary = '/summary';
  static const String payment = '/payment';
  static const String error = '/error';
  static const String confirmPayment = '/confirm_payment';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    register: (context) => const RegisterScreen(),
    confirmRegistration: (context) => const PaymentConfirmationScreen(),
    login: (context) => const LoginScreen(),
    customerMenu: (context) => const CustomerMenuScreen(),
    shoppingCart: (context) => const ShoppingCartScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case error:
        final args = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (context) =>
              ErrorScreen(errorMessage: args ?? 'An error occurred'),
        );
      case summary:
        final args = settings.arguments as String?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (context) => const ErrorScreen(
                errorMessage: 'No order ID provided for summary'),
          );
        }
        return MaterialPageRoute(
          builder: (context) => SummaryScreen(orderId: args),
        );

      default:
        final builder = routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder);
        }
        return MaterialPageRoute(
          builder: (context) =>
              const ErrorScreen(errorMessage: 'Page not found'),
        );
    }
  }
}
