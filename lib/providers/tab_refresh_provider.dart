import 'package:flutter/material.dart';

/// Provider to manage tab refresh state for the main navigation tabs
/// This provider triggers refresh on tab switches for specific screens:
/// Home (index 0), Orders (index 1), Customers (index 2), Profile (index 3)
class TabRefreshProvider extends ChangeNotifier {
  // Track which tabs need to be refreshed
  final Map<int, bool> _tabRefreshStates = {
    0: false, // Home
    1: false, // Orders
    2: false, // Customers
    3: false, // Profile
  };

  // Track the current tab index
  int _currentTabIndex = 0;

  // Get refresh state for a specific tab
  bool getRefreshState(int tabIndex) {
    return _tabRefreshStates[tabIndex] ?? false;
  }

  // Get current tab index
  int get currentTabIndex => _currentTabIndex;

  // Mark a tab for refresh
  void markTabForRefresh(int tabIndex) {
    if (_tabRefreshStates.containsKey(tabIndex)) {
      _tabRefreshStates[tabIndex] = true;
      notifyListeners();
    }
  }

  // Clear refresh state for a tab (called after the tab refreshes)
  void clearRefreshState(int tabIndex) {
    if (_tabRefreshStates.containsKey(tabIndex)) {
      _tabRefreshStates[tabIndex] = false;
      notifyListeners();
    }
  }

  // Called when switching tabs
  void onTabChanged(int newTabIndex) {
    // Only process if it's actually a different tab
    if (_currentTabIndex != newTabIndex) {
      int previousTab = _currentTabIndex;
      _currentTabIndex = newTabIndex;
      
      // Mark the new tab for refresh (it will refresh when it becomes visible)
      markTabForRefresh(newTabIndex);
      
      debugPrint('Tab changed from $previousTab to $newTabIndex - marked for refresh');
    }
  }

  // Reset all refresh states (useful for logout or app restart)
  void resetAllRefreshStates() {
    for (int key in _tabRefreshStates.keys) {
      _tabRefreshStates[key] = false;
    }
    _currentTabIndex = 0;
    notifyListeners();
  }

  // Check if a tab is one of the refreshable tabs
  bool isRefreshableTab(int tabIndex) {
    return _tabRefreshStates.containsKey(tabIndex);
  }

  // Trigger refresh for current tab (useful for pull-to-refresh actions)
  void refreshCurrentTab() {
    markTabForRefresh(_currentTabIndex);
  }
}