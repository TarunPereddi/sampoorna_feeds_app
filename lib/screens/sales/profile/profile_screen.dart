import 'package:flutter/material.dart';
import '../../../widgets/common_app_bar.dart';
import '../../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data
  final Map<String, dynamic> _userData = {
    'name': 'Rajesh Kumar',
    'email': 'rajesh.kumar@sampoorna.com',
    'phone': '+91 9876543210',
    'employeeId': 'SE-12345',
    'role': 'Sales Executive',
    'region': 'North India',
    'joinDate': '10 Jan 2023',
    'lastLogin': '15 Apr 2025, 08:30 AM',
    'performance': {
      'targets': {
        'mtd': {
          'achieved': 850000,
          'target': 1000000,
          'percentage': 85,
        },
        'qtd': {
          'achieved': 2500000,
          'target': 3000000,
          'percentage': 83,
        },
      },
      'customers': {
        'total': 45,
        'active': 38,
        'new': 5,
      },
      'orders': {
        'total': 120,
        'pending': 12,
        'completed': 108,
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // Show edit profile dialog
              _showEditProfileDialog(context);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Avatar and Basic Info
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF008000),
                            child: Text(
                              _userData['name'].substring(0, 1),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Basic Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userData['name'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userData['role'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${_userData['employeeId']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Contact Information
                      const Divider(),
                      const SizedBox(height: 16),

                      // Email
                      _buildContactInfoItem(
                        icon: Icons.email,
                        label: 'Email',
                        value: _userData['email'],
                      ),

                      const SizedBox(height: 16),

                      // Phone
                      _buildContactInfoItem(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: _userData['phone'],
                      ),

                      const SizedBox(height: 16),

                      // Region
                      _buildContactInfoItem(
                        icon: Icons.location_on,
                        label: 'Region',
                        value: _userData['region'],
                      ),

                      const SizedBox(height: 16),

                      // Join Date
                      _buildContactInfoItem(
                        icon: Icons.calendar_today,
                        label: 'Join Date',
                        value: _userData['joinDate'],
                      ),

                      const SizedBox(height: 16),

                      // Last Login
                      _buildContactInfoItem(
                        icon: Icons.access_time,
                        label: 'Last Login',
                        value: _userData['lastLogin'],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Performance Summary
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sales Targets
                      _buildPerformanceSection(
                        title: 'Sales Targets',
                        children: [
                          _buildProgressIndicator(
                            label: 'Month to Date',
                            achievedValue: '₹${_formatAmount(_userData['performance']['targets']['mtd']['achieved'])}',
                            targetValue: '₹${_formatAmount(_userData['performance']['targets']['mtd']['target'])}',
                            percentage: _userData['performance']['targets']['mtd']['percentage'],
                          ),
                          const SizedBox(height: 16),
                          _buildProgressIndicator(
                            label: 'Quarter to Date',
                            achievedValue: '₹${_formatAmount(_userData['performance']['targets']['qtd']['achieved'])}',
                            targetValue: '₹${_formatAmount(_userData['performance']['targets']['qtd']['target'])}',
                            percentage: _userData['performance']['targets']['qtd']['percentage'],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Customer Stats
                      _buildPerformanceSection(
                        title: 'Customer Statistics',
                        children: [
                          Row(
                            children: [
                              _buildStatCard(
                                label: 'Total Customers',
                                value: _userData['performance']['customers']['total'].toString(),
                                icon: Icons.people,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                label: 'Active Customers',
                                value: _userData['performance']['customers']['active'].toString(),
                                icon: Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                label: 'New Customers',
                                value: _userData['performance']['customers']['new'].toString(),
                                icon: Icons.person_add,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Order Stats
                      _buildPerformanceSection(
                        title: 'Order Statistics',
                        children: [
                          Row(
                            children: [
                              _buildStatCard(
                                label: 'Total Orders',
                                value: _userData['performance']['orders']['total'].toString(),
                                icon: Icons.shopping_cart,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                label: 'Pending',
                                value: _userData['performance']['orders']['pending'].toString(),
                                icon: Icons.pending_actions,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                label: 'Completed',
                                value: _userData['performance']['orders']['completed'].toString(),
                                icon: Icons.task_alt,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF008000).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF008000),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildProgressIndicator({
    required String label,
    required String achievedValue,
    required String targetValue,
    required int percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$percentage%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 90
                ? Colors.green
                : percentage >= 70
                ? Colors.orange
                : Colors.red,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              achievedValue,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Target: $targetValue',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toString();
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    // In a real app, this would be a form to edit profile details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: const Text('Profile editing functionality will be available in the next update.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008000),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}