import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../order/notifications_screen.dart';
import '../order/order_tracking_screen.dart';
import '../order/assigned_orders_screen.dart';
import '../profile/settings_screen.dart';
import '../../widgets/floating_bottom_nav_bar.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Static flag: survives pushReplacement — welcome notification only fires once per app session
  static bool _welcomeShown = false;

  bool _isOnline = false;
  String _driverName = "Loading...";
  String _truckId = "Fetching...";
  Map<String, dynamic>? _activeOrder;
  bool _isLoading = true;
  double _currentFuel = 0;
  final double _maxFuelCapacity = 100; // Max tank capacity in gallons
  bool _isFuelLoading = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Fetch Profile (including fuel capacity)
      final profile = await Supabase.instance.client
          .from('drivers')
          .select('*, current_fuel_capacity') // Explicitly select the new column
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null && mounted) {
        setState(() {
          _driverName = profile['full_name'] ?? 'Driver';
          
          String vType = (profile['vehicle_type'] ?? '').toString().trim();
          _truckId = vType.isEmpty ? 'Fuel Tanker - 01' : vType;
          
          _isOnline = profile['status'] == 'online';
          _profileImageUrl = profile['avatar_url'];
          
        });

        // ── Dynamic Fuel Calculation ──
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
        
        try {
          final completedOrders = await Supabase.instance.client
              .from('orders')
              .select('id')
              .eq('driver_id', user.id)
              .inFilter('status', ['completed', 'delivered'])
              .gte('completed_at', startOfDay);

          final int completedToday = (completedOrders as List).length;
          double calculatedFuel = _maxFuelCapacity - (completedToday * 10.0);
          
          if (mounted) {
            setState(() {
              _currentFuel = calculatedFuel < 0 ? 0 : calculatedFuel;
              _isFuelLoading = false;
            });
          }
        } catch (e) {
          debugPrint('Error calculating fuel: $e');
          if (mounted) {
            setState(() {
              _currentFuel = _maxFuelCapacity; // Fallback to full
              _isFuelLoading = false;
            });
          }
        }

        // Trigger Welcome Notification ONCE per app session (not on every tab switch)
        if (!_welcomeShown) {
          _welcomeShown = true;
          NotificationService.showImmediateNotification(
            title: 'Welcome back! 👋',
            body: 'Good to see you, $_driverName! Ready to deliver today?',
            type: 'system',
          );
        }
      } else if (mounted) {

        setState(() {
          _driverName = user.email?.split('@')[0] ?? 'Driver Team';
          _truckId = 'Fuel Tanker - 01';
          _isFuelLoading = false;
        });
      }

      // Fetch Active Order only if driver is online
      if (_isOnline) {
        Map<String, dynamic>? order = await Supabase.instance.client
            .from('orders')
            .select()
            .eq('driver_id', user.id)
            .eq('status', 'assigned')
            .limit(1)
            .maybeSingle();

        // Enrich order with customer info from profiles table
        if (order != null) {
          final hasName = order['customer_name'] != null &&
              order['customer_name'].toString().trim().isNotEmpty;
          if (!hasName) {
            final userId = order['user_id']?.toString();
            if (userId != null && userId.isNotEmpty) {
              try {
                final profileData = await Supabase.instance.client
                    .from('profiles')
                    .select('full_name, phone_number, avatar_url')
                    .eq('id', userId)
                    .maybeSingle();
                if (profileData != null) {
                  order = {
                    ...order,
                    'customer_name': profileData['full_name'] ?? order['customer_name'],
                    'customer_phone': profileData['phone_number'] ?? order['customer_phone'],
                    'customer_avatar': profileData['avatar_url'],
                  };
                }
              } catch (e) {
                debugPrint('Error fetching customer profile: $e');
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _activeOrder = order;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeOrder = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error fetching dashboard data: $e");
    }
  }

  Future<void> _triggerEmergency() async {
    if (_activeOrder == null) return;
    
    final orderId = _activeOrder!['id'].toString();
    final customerUserId = _activeOrder!['user_id']?.toString();

    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'emergency'})
          .eq('id', orderId);
          
      if (customerUserId != null && customerUserId.isNotEmpty) {
        NotificationService.notifyUserEmergency(customerUserId, orderId);
      }
          
      if (mounted) {
        setState(() => _activeOrder = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent! Order moved to Emergency queue.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      _fetchDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to trigger emergency: $e')),
        );
      }
    }
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => _isOnline = value);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('drivers')
            .update({'status': value ? 'online' : 'offline'})
            .eq('id', user.id);
      }
      // Re-fetch data when status changes (to show/hide orders)
      _fetchDashboardData();
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() => _isOnline = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status. Please check your connection.')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4D00)),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Header Section
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(
                                  _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? _profileImageUrl!
                                      : 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1974&auto=format&fit=crop', // Dummy fallback portrait
                                ),
                                backgroundColor: const Color(0xFFEEEEEE),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _driverName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _truckId,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF888888),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Notification Icon
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationsScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE8DD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFFFF4D00),
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Online/Offline Switch
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: _isOnline,
                                  onChanged: _toggleStatus,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFFFF4D00),
                                  inactiveTrackColor: const Color(0xFFEEEEEE),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Delivers',
                              _isOnline ? 'Active' : 'Offline',
                              _isOnline ? 'Receiving Orders' : 'Go Online',
                              Icons.directions_car,
                              _isOnline ? 1.0 : 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _isFuelLoading 
                              ? _buildStatCard(
                                  'Fuel Capacity',
                                  '--', // Loading placeholder
                                  'Loading...',
                                  Icons.local_gas_station,
                                  0.0,
                                )
                              : _buildStatCard(
                                  'Fuel Capacity',
                                  _currentFuel > 0 ? '${_currentFuel.toStringAsFixed(0)} Gal' : '0 Gal',
                                  _currentFuel > 0 ? '${((_currentFuel / _maxFuelCapacity) * 100).toStringAsFixed(0)}%' : 'Empty',
                                  Icons.local_gas_station,
                                  (_currentFuel / _maxFuelCapacity).clamp(0.0, 1.0),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      // Show order section ONLY when online
                      if (_isOnline) ...[
                        Text(
                          _activeOrder != null ? 'Active Delivery' : 'Available Status',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Active Delivery / Searching Card
                        if (_activeOrder != null) 
                          _buildActiveOrderCard()
                        else 
                          _buildSearchingOrderCard(),
                      ] else ...[
                        // Offline message
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildOfflineCard(),
                      ],

                      const SizedBox(height: 24),
                      // Emergency Alert
                      GestureDetector(
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Emergency Alert'),
                              content: const Text(
                                'Are you sure you want to trigger an emergency alert? This will notify dispatch immediately.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _triggerEmergency();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  child: const Text('Send Alert', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Emergency Alert',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tap and hold in case of fuel spill,\nfire, or accident.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFFF4D4D),
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFE0E0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_rounded,
                                  color: Color(0xFFFF4D4D),
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: const FloatingBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildActiveOrderCard() {
    final customerPhone = _activeOrder!['customer_phone']?.toString() ?? '';

    // Prefer customer_lat/lng (actual GPS location) over delivery_lat/lng
    double? extractDouble(String key1, String key2) {
      final v = _activeOrder![key1] ?? _activeOrder![key2];
      if (v == null) return null;
      final d = double.tryParse(v.toString());
      return (d == 0.0) ? null : d;
    }

    final deliveryLat = extractDouble('customer_lat', 'delivery_lat');
    final deliveryLng = extractDouble('customer_lng', 'delivery_lng');
    final address = _activeOrder!['delivery_address']?.toString();
    final fuelInfo =
        '${_activeOrder!['fuel_type'] ?? 'Fuel'} • ${_activeOrder!['fuel_quantity'] ?? _activeOrder!['fuel_quantity_gallons'] ?? 'N/A'} Gallons';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D00),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS • ${_activeOrder!['status']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF4D00),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _activeOrder!['delivery_address'] ?? 'Unknown Address',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_activeOrder!['fuel_quantity'] ?? _activeOrder!['fuel_quantity_gallons'] ?? 'N/A'} Gallons of ${_activeOrder!['fuel_type'] ?? 'Fuel'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                      if (deliveryLat != null && deliveryLng != null)
                        FutureBuilder<Position>(
                          future: Geolocator.getCurrentPosition(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final distMeters = LocationService.getDistance(
                                snapshot.data!.latitude,
                                snapshot.data!.longitude,
                                deliveryLat,
                                deliveryLng,
                              );
                              final distText = distMeters > 1000
                                  ? '${(distMeters / 1000).toStringAsFixed(1)} km away'
                                  : '${distMeters.toStringAsFixed(0)} m away';
                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '📍 $distText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          // Navigate + Contact buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(
                          deliveryLat: deliveryLat,
                          deliveryLng: deliveryLng,
                          deliveryAddress: address,
                          fuelInfo: fuelInfo,
                          order: _activeOrder,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.explore_outlined, size: 20),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (customerPhone.isNotEmpty) {
                      _makePhoneCall(customerPhone);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Customer phone number not available'),
                          backgroundColor: Colors.orangeAccent,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  label: const Text('Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          // External Google Maps button
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (deliveryLat != null && deliveryLng != null) {
                  final url = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=$deliveryLat,$deliveryLng',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Could not open Google Maps.')),
                    );
                  }
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                        content:
                            Text('No GPS coordinates for this order yet.')),
                  );
                }
              },
              icon: const Icon(Icons.map_outlined,
                  color: Color(0xFFFF4D00), size: 18),
              label: const Text(
                'Open in Google Maps',
                style: TextStyle(
                    color: Color(0xFFFF4D00), fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF4D00)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingOrderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.radar, 
            size: 48, 
            color: Color(0xFFFF4D00),
          ),
          const SizedBox(height: 16),
          const Text(
            'Searching for nearby orders...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure your vehicle is ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AssignedOrdersScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D00),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View All Orders',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_parking, 
            size: 48, 
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'You are currently offline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toggle your status top-right to start receiving deliveries.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFFFF4D00), size: 22),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF4D00),
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
