import 'package:flutter/material.dart';
import '../../../screens/login/login_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  // Mock vendor profile data
  final Map<String, dynamic> _vendorData = {
    'name': 'Agrotech Supplies Pvt Ltd',
    'code': 'VEN00123',
    'email': 'contact@agrotechsupplies.com',
    'phone': '+91 9876543210',
    'gst': 'GST29384756HSD873',
    'pan': 'ABCDE1234F',
    'address': {
      'street': '42, Industrial Area, Phase 2',
      'city': 'Bangalore',
      'state': 'Karnataka',
      'pincode': '560058',
    },
    'bankDetails': {
      'accountName': 'Agrotech Supplies Pvt Ltd',
      'accountNumber': 'XXXX XXXX 5678',
      'ifsc': 'HDFC0001234',
      'branch': 'Bangalore Main Branch',
    },
    'joinedDate': '10 Jan 2022',
    'status': 'Active',
    'rating': 4.5,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF008000),
        title: Row(
          children: [
            Image.asset(
              'assets/app_logo.png',
              height: 30,
              width: 30,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              _showEditProfileDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(),

            // Main content with cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Information
                  _buildSectionTitle('Business Information'),
                  _buildInfoCard([
                    _buildInfoItem('Business Name', _vendorData['name']),
                    _buildInfoItem('Vendor Code', _vendorData['code']),
                    _buildInfoItem('GSTIN', _vendorData['gst']),
                    _buildInfoItem('PAN', _vendorData['pan']),
                    _buildInfoItem('Joined On', _vendorData['joinedDate']),
                  ]),

                  const SizedBox(height: 24),

                  // Contact Information
                  _buildSectionTitle('Contact Information'),
                  _buildInfoCard([
                    _buildInfoItem('Email', _vendorData['email']),
                    _buildInfoItem('Phone', _vendorData['phone']),
                    _buildInfoItem('Address',
                        '${_vendorData['address']['street']}, ${_vendorData['address']['city']}, '
                            '${_vendorData['address']['state']} - ${_vendorData['address']['pincode']}'),
                  ]),

                  const SizedBox(height: 24),

                  // Bank Details
                  _buildSectionTitle('Bank Details'),
                  _buildInfoCard([
                    _buildInfoItem('Account Name', _vendorData['bankDetails']['accountName']),
                    _buildInfoItem('Account Number', _vendorData['bankDetails']['accountNumber']),
                    _buildInfoItem('IFSC Code', _vendorData['bankDetails']['ifsc']),
                    _buildInfoItem('Branch', _vendorData['bankDetails']['branch']),
                  ]),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: Column(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              _vendorData['name'].substring(0, 1),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Business Name
          Text(
            _vendorData['name'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Vendor Code
          Text(
            'Vendor ID: ${_vendorData['code']}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _vendorData['status'] == 'Active' ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _vendorData['status'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Vendor Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${_vendorData['rating']} / 5.0',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Vendor Rating',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing functionality will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}