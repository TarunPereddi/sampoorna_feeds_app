import 'package:flutter/material.dart';
import '../screens/sales/sales_shell.dart';

/// A service for handling navigation across the app.
/// This helps avoid duplication of bottom navigation bars.
class NavigationService {
  /// Navigates to a specific tab in SalesShell.
  /// If already in SalesShell, switches tabs instead of creating a new instance.
  static void navigateToTab(BuildContext context, int tabIndex, {Map<String, dynamic>? arguments}) {
    // Check if we're already in a SalesShell
    bool inSalesShell = false;
    
    // Walk up the widget tree to find any SalesShell ancestor
    context.visitAncestorElements((element) {
      if (element.widget is SalesShell) {
        inSalesShell = true;
        return false; // Stop traversing
      }
      return true; // Continue traversing
    });    if (inSalesShell) {
      // If already in SalesShell, use the static tab switching method
      SalesShell.switchTab(context, tabIndex, arguments: arguments);
    } else {
      // If not in SalesShell, navigate to a new SalesShell with the target tab
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => SalesShell(initialTabIndex: tabIndex),
          settings: RouteSettings(arguments: arguments),
        ),
        (route) => false,
      );
    }
  }
}
