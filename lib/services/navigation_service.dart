import 'package:flutter/material.dart';
import '../screens/sales/sales_shell.dart';
import '../screens/team/team_shell.dart';
import '../screens/customer/customer_shell.dart';
import '../services/persona_state.dart';

/// A service for handling navigation across the app.
/// This helps avoid duplication of bottom navigation bars.
class NavigationService {
  /// Navigates to a specific tab in SalesShell, TeamShell, or CustomerShell based on the current persona.
  /// If already in the appropriate Shell, switches tabs instead of creating a new instance.
  static void navigateToTab(BuildContext context, int tabIndex, {Map<String, dynamic>? arguments}) {
    // Get the current persona
    final String currentPersona = PersonaState.getPersona();
    
    if (currentPersona == 'team') {
      // Check if we're already in a TeamShell
      bool inTeamShell = false;
      
      // Walk up the widget tree to find any TeamShell ancestor
      context.visitAncestorElements((element) {
        if (element.widget is TeamShell) {
          inTeamShell = true;
          return false; // Stop traversing
        }
        return true; // Continue traversing
      });
      
      if (inTeamShell) {
        // If already in TeamShell, use the static tab switching method
        TeamShell.switchTab(context, tabIndex, arguments: arguments);
      } else {
        // If not in TeamShell, navigate to a new TeamShell with the target tab
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TeamShell(initialTabIndex: tabIndex),
            settings: RouteSettings(arguments: arguments),
          ),
          (route) => false,
        );
      }
    } else if (currentPersona == 'customer') {
      // Check if we're already in a CustomerShell
      bool inCustomerShell = false;
      
      // Walk up the widget tree to find any CustomerShell ancestor
      context.visitAncestorElements((element) {
        if (element.widget is CustomerShell) {
          inCustomerShell = true;
          return false; // Stop traversing
        }
        return true; // Continue traversing
      });
      
      if (inCustomerShell) {
        // If already in CustomerShell, use the static tab switching method
        CustomerShell.switchTab(context, tabIndex, arguments: arguments);
      } else {
        // If not in CustomerShell, navigate to a new CustomerShell with the target tab
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerShell(initialTabIndex: tabIndex),
            settings: RouteSettings(arguments: arguments),
          ),
          (route) => false,
        );
      }
    } else {
      // Default to SalesShell for 'sales' persona
      // Check if we're already in a SalesShell
      bool inSalesShell = false;
      
      // Walk up the widget tree to find any SalesShell ancestor
      context.visitAncestorElements((element) {
        if (element.widget is SalesShell) {
          inSalesShell = true;
          return false; // Stop traversing
        }
        return true; // Continue traversing
      });
      
      if (inSalesShell) {
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
}
