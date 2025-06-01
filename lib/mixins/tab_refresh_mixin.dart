import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tab_refresh_provider.dart';

/// Mixin that provides automatic refresh functionality for tab screens
/// Screens that use this mixin will automatically refresh when:
/// 1. They become visible after a tab change
/// 2. The refresh state is set to true
mixin TabRefreshMixin<T extends StatefulWidget> on State<T> {
  // The tab index this screen represents
  int get tabIndex;
  
  // Method that subclasses must implement to perform the refresh
  Future<void> performRefresh();
  
  // Whether this screen has been refreshed for the current session
  bool _hasRefreshed = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndRefresh();
      }
    });
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndRefresh();
      }
    });
  }

  void _checkAndRefresh() {
    try {
      final tabRefreshProvider = Provider.of<TabRefreshProvider>(context, listen: false);
      
      // Check if this tab needs to be refreshed
      if (tabRefreshProvider.getRefreshState(tabIndex) && 
          tabRefreshProvider.currentTabIndex == tabIndex) {
        
        debugPrint('Refreshing tab $tabIndex');
        
        // Clear the refresh state immediately to prevent multiple refreshes
        tabRefreshProvider.clearRefreshState(tabIndex);
        
        // Perform the refresh
        performRefresh();
        _hasRefreshed = true;
      }
    } catch (e) {
      debugPrint('Error in TabRefreshMixin._checkAndRefresh for tab $tabIndex: $e');
    }
  }

  // Helper method to manually trigger refresh for this tab
  void triggerRefresh() {
    final tabRefreshProvider = Provider.of<TabRefreshProvider>(context, listen: false);
    tabRefreshProvider.markTabForRefresh(tabIndex);
    _checkAndRefresh();
  }

  // Helper method to check if this tab has been refreshed
  bool get hasRefreshed => _hasRefreshed;

  // Reset the refresh state (useful for manual refresh operations)
  void resetRefreshState() {
    _hasRefreshed = false;
  }
}
