import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chat_screen.dart';
import 'confirm_protocol_screen.dart';

class SafetyChecklistStartingScreen extends StatefulWidget {
  final Map<String, dynamic>? order;

  const SafetyChecklistStartingScreen({
    super.key,
    this.order,
  });

  @override
  State<SafetyChecklistStartingScreen> createState() =>
      _SafetyChecklistStartingScreenState();
}

class _SafetyChecklistStartingScreenState
    extends State<SafetyChecklistStartingScreen> {
  // Delivery position computed from order data
  CameraPosition get _deliveryPosition {
    final lat = double.tryParse(
            widget.order?['delivery_lat']?.toString() ?? '') ??
        double.tryParse(
            widget.order?['latitude']?.toString() ?? '') ??
        24.8607; // Karachi fallback
    final lng = double.tryParse(
            widget.order?['delivery_lng']?.toString() ?? '') ??
        double.tryParse(
            widget.order?['longitude']?.toString() ?? '') ??
        67.0011;
    return CameraPosition(target: LatLng(lat, lng), zoom: 15.0);
  }

  String _customerName = 'Loading...';
  String? _customerPhone;
  String _vehicleInfo = 'Loading...';
  String _arrivalTime = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _customerPhone = widget.order?['customer_phone']?.toString();
    _resolveCustomerName();
    _resolveVehicleInfo();
    _computeArrivalTime();
  }

  void _computeArrivalTime() {
    // Use accepted_at timestamp as arrival confirmation time
    final acceptedAt = widget.order?['arrived_at']?.toString() ??
        widget.order?['accepted_at']?.toString() ??
        widget.order?['created_at']?.toString();

    if (acceptedAt != null) {
      try {
        final dt = DateTime.parse(acceptedAt).toLocal();
        final hour = dt.hour;
        final min = dt.minute;
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final timeStr =
            '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $ampm';

        // Calculate minutes since order was accepted
        final now = DateTime.now();
        final diff = now.difference(dt);
        final minAgo = diff.inMinutes;

        if (minAgo < 1) {
          if (mounted) setState(() => _arrivalTime = 'Just arrived ($timeStr)');
        } else if (minAgo < 60) {
          if (mounted) {
            setState(() => _arrivalTime = 'Arrived $minAgo min ago ($timeStr)');
          }
        } else {
          if (mounted) setState(() => _arrivalTime = 'Arrived at $timeStr');
        }
        return;
      } catch (_) {}
    }

    if (mounted) setState(() => _arrivalTime = 'N/A');
  }

  Future<void> _resolveVehicleInfo() async {
    // 1. Use embedded vehicle_info if present
    final embedded = widget.order?['vehicle_info']?.toString().trim();
    if (embedded != null && embedded.isNotEmpty) {
      if (mounted) setState(() => _vehicleInfo = embedded);
      return;
    }

    // 2. Fetch from vehicles table using vehicle_id
    final vehicleId = widget.order?['vehicle_id']?.toString();
    if (vehicleId != null && vehicleId.isNotEmpty) {
      try {
        final v = await Supabase.instance.client
            .from('vehicles')
            .select('make, model, year, color, license_plate')
            .eq('id', vehicleId)
            .maybeSingle();
        if (v != null && mounted) {
          final parts = [
            if (v['color'] != null) v['color'].toString(),
            if (v['make'] != null) v['make'].toString(),
            if (v['model'] != null) v['model'].toString(),
            if (v['year'] != null) '(${v['year']})',
          ];
          final plate = v['license_plate']?.toString() ?? '';
          setState(() {
            _vehicleInfo = parts.isNotEmpty
                ? '${parts.join(' ')}${plate.isNotEmpty ? ' · $plate' : ''}'
                : 'Unknown Vehicle';
          });
          return;
        }
      } catch (e) {
        debugPrint('[SafetyChecklist] vehicle fetch error: $e');
      }
    }

    if (mounted) setState(() => _vehicleInfo = 'N/A');
  }

  Future<void> _resolveCustomerName() async {
    // 1. Use embedded customer_name if already enriched (from dashboard fetch)
    final embeddedName = widget.order?['customer_name']?.toString().trim();
    if (embeddedName != null && embeddedName.isNotEmpty) {
      if (mounted) setState(() => _customerName = embeddedName);
      return;
    }

    // 2. Fetch from profiles table using user_id
    final userId = widget.order?['user_id']?.toString();
    if (userId != null && userId.isNotEmpty) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, phone_number, avatar_url')
            .eq('id', userId)
            .maybeSingle();
        if (profile != null && mounted) {
          final name = profile['full_name']?.toString().trim();
          final phone = profile['phone_number']?.toString().trim();
          setState(() {
            if (name != null && name.isNotEmpty) _customerName = name;
            if (phone != null && phone.isNotEmpty) _customerPhone = phone;
          });
          return;
        }
      } catch (e) {
        debugPrint('[SafetyChecklist] profiles fetch error: $e');
      }
    }

    // 3. Fallback
    if (mounted) setState(() => _customerName = 'Customer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1F1F1F),
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Safety Checklist',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Status Badge
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FADF), // Light green
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF039855), // Dark green
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ARRIVED',
                          style: TextStyle(
                            color: Color(0xFF039855),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Location verified by GPS',
                    style: TextStyle(
                      color: Color(0xFFFF4D00),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Information Section
                  const Text(
                    'CUSTOMER INFORMATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF888888),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEEEEEE),
                            image: widget.order?['customer_avatar'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      widget.order!['customer_avatar'].toString(),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: widget.order?['customer_avatar'] == null
                              ? const Icon(Icons.person, color: Colors.grey, size: 26)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F1F1F),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                widget.order?['vehicle_info'] != null
                                    ? widget.order!['vehicle_info'].toString()
                                    : _vehicleInfo,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildInfoActionIcon(Icons.chat_bubble_rounded, () {
                              final userId = widget.order?['user_id']?.toString();
                              if (_customerName != 'Loading...' && _customerName != 'Customer' && userId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => ChatScreen(
                                      customerName: _customerName,
                                      customerId: userId,
                                      orderId: widget.order?['id']?.toString() ?? '',
                                    ),
                                  ),
                                );
                              }
                            }),
                            const SizedBox(width: 12),
                            _buildInfoActionIcon(Icons.phone_rounded, _callCustomer),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Map Preview Card
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                           Positioned.fill(
                            child: GoogleMap(
                              mapType: MapType.normal,
                              initialCameraPosition: _deliveryPosition,
                              markers: {
                                Marker(
                                  markerId: const MarkerId('delivery'),
                                  position: _deliveryPosition.target,
                                  infoWindow: InfoWindow(
                                    title: widget.order?['delivery_address'] ?? 'Delivery Location',
                                  ),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              scrollGesturesEnabled: true,
                              zoomGesturesEnabled: true,
                            ),
                          ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.ios_share_rounded,
                              size: 18,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  widget.order?['delivery_address'] ?? 'Delivery Location',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 24),

                  // Drop-off Instructions Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.chat_bubble_rounded,
                              color: Color(0xFFFF4D00),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Drop-off Instructions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            // Check all notes fields — same priority as rest of app
                            final instructions = (
                              widget.order?['drop_off_instructions'] ??
                              widget.order?['delivery_instructions'] ??
                              widget.order?['customer_notes'] ??
                              widget.order?['special_instructions'] ??
                              widget.order?['notes']
                            )?.toString().trim() ?? '';

                            final hasInstructions = instructions.isNotEmpty;
                            return Text(
                              hasInstructions
                                  ? instructions
                                  : 'No special instructions provided.',
                              style: TextStyle(
                                fontSize: 13,
                                color: hasInstructions
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFAAAAAA),
                                height: 1.5,
                                fontWeight: hasInstructions
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontStyle: hasInstructions
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Fuel Type', widget.order?['fuel_type'] ?? 'Unknown Fuel Type'),
                        const Divider(height: 24, color: Color(0xFFF2F2F2)),
                        _buildRow('Estimated Amount', '${widget.order?['fuel_quantity_gallons'] ?? 0} Gallons'),
                        const Divider(height: 24, color: Color(0xFFF2F2F2)),
                        _buildRow('Arrival Time', _arrivalTime),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFB800),
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Safety checklist required',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ConfirmProtocolScreen(order: widget.order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Start Safety Checklist',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callCustomer() async {
    final phone = _customerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    }
  }

  Widget _buildInfoActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFFF4D00),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }
}
