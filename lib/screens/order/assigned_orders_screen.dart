import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../../services/notification_service.dart';
import '../../services/driver_database_service.dart';
import '../../services/service_area_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'order_details_screen.dart';

class AssignedOrdersScreen extends StatefulWidget {
  const AssignedOrdersScreen({super.key});

  @override
  State<AssignedOrdersScreen> createState() => _AssignedOrdersScreenState();
}

class _AssignedOrdersScreenState extends State<AssignedOrdersScreen> {
  static StreamSubscription<Position>? _backgroundLocationStream;
  int _activeFilterIndex = 0;
  final List<String> _filters = [
    'Available',
    'Assigned',
    'Scheduled',
    'Emergency',
    'Delivered',
  ];

  // ── Local order state (replaces stream() for realtime reliability) ──
  List<Map<String, dynamic>> _orders = [];
  bool _isLoadingOrders = true;
  String? _ordersError;
  RealtimeChannel? _ordersChannel;

  // ── Driver location (for proximity filtering) ──────────────────────
  // _serviceAreas is loaded once on init; falls back to 25 km driver-relative radius when empty.
  List<ServiceArea> _serviceAreas = [];
  Position? _driverPosition;
  StreamSubscription<Position>? _locationFilterStream;

  // ── Driver online status ──
  StreamSubscription<List<Map<String, dynamic>>>? _driverStatusSubscription;
  bool? _isOnline;

  // ── Accept-in-progress guard (order ID that is currently being accepted) ──
  String? _acceptingOrderId;

  @override
  void initState() {
    super.initState();
    _loadServiceAreas();
    _listenToDriverStatus();
    _fetchOrders();
    _subscribeToOrderChanges();
    _startLocationFilter();
  }

  /// Loads active global service areas from Supabase.
  Future<void> _loadServiceAreas() async {
    final areas = await ServiceAreaService.fetchActiveAreas();
    if (mounted) setState(() => _serviceAreas = areas);
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    _driverStatusSubscription?.cancel();
    _locationFilterStream?.cancel();
    super.dispose();
  }

  // ── Location stream for proximity filtering ────────────────────────
  Future<void> _startLocationFilter() async {
    // Check permission without blocking the screen
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      // Grab current position immediately for the first filter pass
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) setState(() => _driverPosition = initial);

      // Then keep updating whenever the driver moves ≥ 200 m
      _locationFilterStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 200, // metres — matches _locationUpdateFilterM
        ),
      ).listen((pos) {
        debugPrint('[Proximity] Driver moved → ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
        if (mounted) setState(() => _driverPosition = pos);
      }, onError: (e) {
        debugPrint('[Proximity] Location stream error: $e');
      });
    } catch (e) {
      debugPrint('[Proximity] Could not start location stream: $e');
    }
  }

  // ── Haversine distance (km) — kept for the distance label on order cards ──
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  /// Returns formatted distance string for a given order, or null if
  /// the order has no coordinates or driver location is unknown.
  String? _orderDistanceLabel(Map<String, dynamic> order) {
    final dPos = _driverPosition;
    if (dPos == null) return null;
    final lat = double.tryParse((order['delivery_lat'] ?? order['latitude'] ?? order['customer_lat'])?.toString() ?? '');
    final lng = double.tryParse((order['delivery_lng'] ?? order['longitude'] ?? order['customer_lng'])?.toString() ?? '');
    if (lat == null || lng == null) return null;
    final km = _distanceKm(dPos.latitude, dPos.longitude, lat, lng);
    return km < 1 ? '${(km * 1000).round()} m away' : '${km.toStringAsFixed(1)} km away';
  }

  // ── Initial fetch ──────────────────────────────────────────────────

  Future<void> _fetchOrders() async {
    try {
      if (mounted) setState(() { _isLoadingOrders = true; _ordersError = null; });
      final data = await Supabase.instance.client
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      debugPrint('[Orders] Initial fetch: ${data.length} orders');
      if (mounted) setState(() { _orders = List<Map<String, dynamic>>.from(data); _isLoadingOrders = false; });
    } catch (e) {
      debugPrint('[Orders] Fetch error: $e');
      if (mounted) setState(() { _isLoadingOrders = false; _ordersError = e.toString(); });
    }
  }

  // ── Realtime channel (INSERT / UPDATE / DELETE) ────────────────────

  void _subscribeToOrderChanges() {
    // Unsubscribe any existing channel first
    _ordersChannel?.unsubscribe();

    _ordersChannel = Supabase.instance.client
        .channel('public:orders:driver_view')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            debugPrint('[Realtime] ORDER INSERT id=${payload.newRecord['id']} status=${payload.newRecord['status']}');
            if (!mounted) return;
            setState(() {
              // Prepend new order — it goes to top of Available tab
              _orders.insert(0, Map<String, dynamic>.from(payload.newRecord));
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final updated = Map<String, dynamic>.from(payload.newRecord);
            debugPrint('[Realtime] ORDER UPDATE id=${updated['id']} status=${updated['status']} driver=${updated['driver_id']}');
            if (!mounted) return;

            final myId = Supabase.instance.client.auth.currentUser?.id;
            final updatedDriverId = updated['driver_id']?.toString();
            final updatedStatus  = updated['status']?.toString().toLowerCase();

            setState(() {
              final idx = _orders.indexWhere((o) => o['id'] == updated['id']);

              // If this order was just assigned to ANOTHER driver, remove it
              // from our local list so it instantly vanishes from Available tab.
              if (updatedDriverId != null &&
                  updatedDriverId.isNotEmpty &&
                  updatedDriverId != myId &&
                  (updatedStatus == 'assigned' || updatedStatus == 'accepted')) {
                if (idx != -1) _orders.removeAt(idx);
                return;
              }

              if (idx != -1) {
                _orders[idx] = updated; // In-place update → tab filter reacts instantly
              } else {
                _orders.insert(0, updated); // New row we didn't have yet
              }
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final deletedId = payload.oldRecord['id'];
            debugPrint('[Realtime] ORDER DELETE id=$deletedId');
            if (!mounted) return;
            setState(() => _orders.removeWhere((o) => o['id'] == deletedId));
          },
        )
        .subscribe((status, error) {
          debugPrint('[Realtime] Channel status: $status${error != null ? ' | error: $error' : ''}');
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('[Realtime] ✓ Subscribed to orders changes');
          } else if (status == RealtimeSubscribeStatus.channelError ||
                     status == RealtimeSubscribeStatus.timedOut) {
            debugPrint('[Realtime] ✗ Subscription failed — retrying in 3s');
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _subscribeToOrderChanges();
            });
          }
        });
  }

  void _listenToDriverStatus() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _driverStatusSubscription = Supabase.instance.client
          .from('drivers')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .listen((data) {
        if (!mounted) return;
        // Only update when we have actual data — empty list means a
        // transient reconnect/poll with no rows yet; ignore it so we
        // don't flash the offline screen while the driver is online.
        if (data.isEmpty) return;
        final statusVal = data.first['status']?.toString().toLowerCase();
        final newStatus = statusVal == 'online';
        if (_isOnline != newStatus) {
          setState(() => _isOnline = newStatus);
        }
      }, onError: (err) {
        debugPrint("Error listening to driver status: $err");
        // Do NOT override _isOnline on transient errors — keep the last
        // known state so the screen doesn't flash offline incorrectly.
      });
    } else {
      if (mounted) setState(() => _isOnline = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Not logged in");

      // Verify availability — also fetch user_id to notify the customer
      final orderRes = await Supabase.instance.client
          .from('orders')
          .select('status, user_id')
          .eq('id', orderId)
          .maybeSingle();

      const pendingStatuses = ['available', 'pending', 'PENDING'];
      if (orderRes == null || !pendingStatuses.contains(orderRes['status'])) {
        throw Exception("Order is no longer available.");
      }

      // Fetch driver details for tracking
      final profile = await Supabase.instance.client
          .from('drivers')
          .select('full_name, avatar_url, vehicle_type, phone')
          .eq('id', user.id)
          .maybeSingle();

      final driverName = profile?['full_name'] ?? 'Driver';
      final driverPhoto = profile?['avatar_url'] ?? '';
      final driverVehicle = profile?['vehicle_type'] ?? 'Fuel Truck';
      final driverPhone = profile?['phone'] ?? '';

      final nowTs = DateTime.now().toUtc();

      // Get current GPS position (best effort — don't block accept if it fails)
      Position? currentPos;
      try {
        currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {}

      final updatePayload = <String, dynamic>{
        'status': 'assigned',
        'driver_id': user.id,
        'assigned_at': nowTs.toIso8601String(),
        'driver_name': driverName,
        'driver_photo': driverPhoto,
        'driver_vehicle': driverVehicle,
        'driver_phone': driverPhone,
      };

      if (currentPos != null) {
        updatePayload['driver_latitude'] = currentPos.latitude;
        updatePayload['driver_longitude'] = currentPos.longitude;
      }

      // ── Conditional DB update (race-safe) ─────────────────────────────────
      // Reason: SQL inFilter is case-sensitive and driver_id IS NULL fails on empty strings.
      // We perform a direct update and then verify if we won the race.
      await Supabase.instance.client
          .from('orders')
          .update(updatePayload)
          .eq('id', orderId);

      // Verify update won the race — read back current row
      final verifyRow = await Supabase.instance.client
          .from('orders')
          .select('id, driver_id')
          .eq('id', orderId)
          .maybeSingle();

      final actualDriverId = verifyRow?['driver_id']?.toString() ?? '';

      // ── Race condition detected ────────────────────────────────────────────
      if (actualDriverId != user.id) {
        debugPrint('[Orders] Race condition: order $orderId was accepted by another driver');
        // Refresh from DB to get the real current state
        await _fetchOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sorry, this order was just accepted by another driver.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(20),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return; // ← stop here; do NOT navigate
      }

      // DB write succeeded → now safely update local state and switch tab
      int targetTab = 1; // Default: Assigned
      if (mounted) {
        setState(() {
          final idx = _orders.indexWhere((o) => o['id'] == orderId);
          if (idx != -1) {
            final order = _orders[idx];
            final sTime = order['scheduled_time'];
            if (sTime != null && sTime.toString().trim().isNotEmpty) {
              try {
                final scheduledDate = DateTime.parse(sTime.toString()).toUtc();
                if (scheduledDate.difference(nowTs).inMinutes > 60) {
                  targetTab = 2; // Scheduled tab
                }
              } catch (_) {}
            }
            _orders[idx] = Map<String, dynamic>.from(order)
              ..['status'] = 'assigned'
              ..['driver_id'] = user.id
              ..['assigned_at'] = nowTs.toIso8601String()
              ..['driver_name'] = driverName
              ..['driver_photo'] = driverPhoto
              ..['driver_vehicle'] = driverVehicle;
          }
          _activeFilterIndex = targetTab;
        });
      }

      // Log the acceptance event
      await DriverDatabaseService.instance.logDriverAction(
        action: 'ORDER_ACCEPTED',
        details: {
          'order_id': orderId,
          'assigned_at': nowTs.toIso8601String(),
          'driver_name': driverName,
        },
      );

      // Start background location stream
      _backgroundLocationStream?.cancel();
      _backgroundLocationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) async {
        try {
          await Supabase.instance.client.from('orders').update({
            'driver_latitude': pos.latitude,
            'driver_longitude': pos.longitude,
          }).eq('id', orderId);
          
          await Supabase.instance.client.from('driver_locations').upsert({
            'driver_id': user.id,
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'heading': pos.heading,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'driver_id');
        } catch (_) {}
      });

      // Notify the customer (fire-and-forget)
      final userId = orderRes['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        NotificationService.notifyUserOrderAccepted(userId, orderId);
      }

      if (!mounted) return;

      // Accept ho gaya — switch to the appropriate tab
      setState(() => _activeFilterIndex = targetTab);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order accepted! Tap it to start delivery.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );
    } catch (e) {
      // Roll back optimistic update on failure
      debugPrint('[Orders] Accept failed — rolling back optimistic update: $e');
      await _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("Failed: $e")),
        );
      }
    }
  }

  /// Safely parse an ISO timestamp string for sorting. Returns epoch on failure.
  DateTime _parseTs(dynamic raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      return DateTime.parse(raw.toString()).toUtc();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
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
                color: Colors.black,
                size: 18,
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  // If arrived via Bottom Nav Bar (pushReplacement), go back to Dashboard
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }
              },
            ),
          ),
        ),
        title: const Text(
          'Assigned Orders',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Filter Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                bool isActive = _activeFilterIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _activeFilterIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFF4D00)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF888888),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _isOnline == null
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D00)))
                : _isLoadingOrders
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D00)))
                    : _ordersError != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('Failed to load orders',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () { _fetchOrders(); _subscribeToOrderChanges(); },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4D00),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildOrderList(),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildOrderList() {
    final currentUser = Supabase.instance.client.auth.currentUser;

    // Show offline message only on the Available tab
    if (_activeFilterIndex == 0 && _isOnline == false) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'You are currently Offline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go online from the Dashboard to see available orders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final cutoff24h = now.subtract(const Duration(hours: 24));

    final filteredOrders = _orders.where((o) {
      final status = o['status']?.toString().toLowerCase().trim() ?? '';
      final driverId = o['driver_id'];
      final myId = currentUser?.id;

      // Treat null, empty string, and literal "null" as unclaimed
      bool isUnclaimed() {
        if (driverId == null) return true;
        final s = driverId.toString().trim();
        return s.isEmpty || s == 'null';
      }

      bool isAvailableStatus() =>
          (status == 'available' || status == 'pending') && isUnclaimed();

      if (_activeFilterIndex == 0) {
        if (!isAvailableStatus()) return false;
        // ── Service-area proximity filter ──────────────────────────────────
        final lat = double.tryParse(
            (o['delivery_lat'] ?? o['latitude'] ?? o['customer_lat'])?.toString() ?? '');
        final lng = double.tryParse(
            (o['delivery_lng'] ?? o['longitude'] ?? o['customer_lng'])?.toString() ?? '');
        return ServiceAreaService.isOrderInServiceAreas(
          areas: _serviceAreas,
          driverLat: _driverPosition?.latitude,
          driverLng: _driverPosition?.longitude,
          orderLat: lat,
          orderLng: lng,
          orderId: o['id']?.toString(),
        );
      }
      
      if (_activeFilterIndex == 1) {
        // Assigned: Active orders (accepted/assigned/in_progress) 
        // AND (Immediate OR Scheduled within 1 hour)
        if (driverId != myId) return false;
        if (status == 'delivered' || status == 'completed' || status == 'cancelled' || status == 'emergency') return false;
        
        final sTime = o['scheduled_time'];
        if (sTime == null || sTime.toString().trim().isEmpty) return true; // Immediate
        
        try {
          final scheduledDate = DateTime.parse(sTime.toString()).toUtc();
          final diff = scheduledDate.difference(now);
          // Show in Assigned if it's within 1 hour OR in the past (already due)
          return diff.inMinutes <= 60; 
        } catch (_) {
          return true; // Fallback to immediate
        }
      }

      if (_activeFilterIndex == 2) {
        // Scheduled: Future orders (> 1 hour away)
        if (driverId != myId) return false;
        if (status == 'delivered' || status == 'completed' || status == 'cancelled') return false;

        final sTime = o['scheduled_time'];
        if (sTime == null) return false;

        try {
          final scheduledDate = DateTime.parse(sTime.toString()).toUtc();
          final diff = scheduledDate.difference(now);
          return diff.inMinutes > 60;
        } catch (_) {
          return false;
        }
      }

      if (_activeFilterIndex == 3) {
        // Emergency: Orders manually flagged or categorized as emergency
        if (driverId != myId) return false;
        return status == 'emergency';
      }

      if (_activeFilterIndex == 4) {
        // Delivered: Completed orders from last 24h
        if (driverId != myId) return false;
        if (!(status == 'delivered' || status == 'completed')) return false;
        
        final rawTs = o['delivered_at'] ?? o['completed_at'];
        if (rawTs == null) return true;
        try {
          final ts = DateTime.parse(rawTs.toString()).toUtc();
          return ts.isAfter(cutoff24h);
        } catch (_) {
          return true;
        }
      }
      return false;
    }).toList();

    // Sort Delivered tab by delivered_at DESC so the latest completed order is on top.
    if (_activeFilterIndex == 4) {
      filteredOrders.sort((a, b) {
        DateTime tsA = _parseTs(a['delivered_at'] ?? a['completed_at'] ?? a['created_at']);
        DateTime tsB = _parseTs(b['delivered_at'] ?? b['completed_at'] ?? b['created_at']);
        return tsB.compareTo(tsA); // descending: newest first
      });
    }

    // Sort Scheduled tab by scheduled_time ASC so the soonest appointment is on top.
    if (_activeFilterIndex == 2) {
      filteredOrders.sort((a, b) {
        DateTime tsA = _parseTs(a['scheduled_time']);
        DateTime tsB = _parseTs(b['scheduled_time']);
        return tsA.compareTo(tsB); // ascending: soonest first
      });
    }

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeFilterIndex == 0
                  ? Icons.location_searching_rounded
                  : Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _activeFilterIndex == 0
                  ? 'No nearby orders found'
                  : 'No ${_filters[_activeFilterIndex].toLowerCase()} orders yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_activeFilterIndex == 0) ...
              [
                const SizedBox(height: 8),
                Text(
                  _driverPosition == null
                      ? 'Waiting for GPS location…'
                      : _serviceAreas.isEmpty
                          ? 'Showing orders within 25 km of your location (fallback).'
                          : 'Showing orders within ${_serviceAreas.length} configured service area(s).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final statusLow = order['status']?.toString().toLowerCase() ?? '';
        final isEmergencyOrder = statusLow == 'emergency';
        // Treat null, empty string, and literal "null" as unclaimed
        final rawDriver = order['driver_id'];
        final driverIsNull = rawDriver == null ||
            rawDriver.toString().trim().isEmpty ||
            rawDriver.toString().trim() == 'null';
        final isAvailable =
            (statusLow == 'available' || statusLow == 'pending') && driverIsNull;

        String formattedTime = '--:--';
        final schTime = order['scheduled_time'];
        final hasValidSchedule = schTime != null && schTime.toString().trim().isNotEmpty;

        if (hasValidSchedule && !isAvailable) {
          try {
            final parsedTime = DateTime.parse(schTime.toString()).toLocal();
            final int hour = parsedTime.hour;
            final int min = parsedTime.minute;
            final String ampm = hour >= 12 ? 'PM' : 'AM';
            final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            formattedTime = 'SCHED: ${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $ampm';
          } catch (_) {
            formattedTime = 'SCHED';
          }
        } else if (isAvailable) {
          if (hasValidSchedule) {
             try {
                final parsedTime = DateTime.parse(schTime.toString()).toLocal();
                final int hour = parsedTime.hour;
                final int min = parsedTime.minute;
                final String ampm = hour >= 12 ? 'PM' : 'AM';
                final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                formattedTime = 'SCHED: ${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $ampm';
              } catch (_) {
                formattedTime = 'NEW';
              }
          } else {
            formattedTime = 'NEW';
          }
        } else {
          // For delivered orders, prefer delivered_at; otherwise use assigned/accepted/created
          final statusLowForTime = order['status']?.toString().toLowerCase() ?? '';
          final isDelivered = statusLowForTime == 'delivered' || statusLowForTime == 'completed';
          final timeSource = isDelivered
              ? (order['delivered_at'] ?? order['completed_at'] ?? order['assigned_at'] ?? order['accepted_at'] ?? order['created_at'])
              : (order['assigned_at'] ?? order['accepted_at'] ?? order['created_at']);
          if (timeSource != null) {
            try {
              final parsedTime = DateTime.parse(timeSource.toString()).toLocal();
              final int hour = parsedTime.hour;
              final int min = parsedTime.minute;
              final String ampm = hour >= 12 ? 'PM' : 'AM';
              final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
              formattedTime = '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $ampm';
            } catch (_) {}
          }
        }

        // Compute real distance label for the card
        final distLabel = _orderDistanceLabel(order) ?? 'Unknown Location';

        return _buildOrderCard(
          id: order['id'],
          time: formattedTime,
          address: order['delivery_address'] ?? 'Unknown Location',
          distance: distLabel,
          fuelType: '${order['fuel_quantity'] ?? order['fuel_quantity_gallons'] ?? '0'} Gal ${order['fuel_type'] ?? 'Fuel'}',
          tag: isAvailable ? 'AVAILABLE' : (isEmergencyOrder ? 'EMERGENCY' : order['status']?.toString().toUpperCase() ?? 'N/A'),
          tagColor: isAvailable ? const Color(0xFFE8F5E9) : (isEmergencyOrder ? const Color(0xFFFFE8DD) : const Color(0xFFF3F3F3)),
          isEmergency: isEmergencyOrder,
          isAvailable: isAvailable,
          fullDataMap: order,
        );
      },
    );
  }

  Widget _buildOrderCard({
    required String id,
    required String time,
    required String address,
    required String distance,
    required String fuelType,
    required String tag,
    required Color tagColor,
    required bool isEmergency,
    bool isAvailable = false,
    required Map<String, dynamic> fullDataMap,
  }) {
    // Generate a short ID string like "#ORD-A8B2"
    final shortId = '#ORD-${id.substring(0, 4).toUpperCase()}';
    
    return GestureDetector(
      // Available orders: card tap disabled — driver must use the Accept button.
      // Assigned/Emergency orders: tap opens order details.
      onTap: isAvailable
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(order: fullDataMap),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F2F2)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 16,
              bottom: 16,
              child: Container(width: 3, color: const Color(0xFFFF4D00)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              shortId,
                              style: const TextStyle(
                                color: Color(0xFFFF4D00),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: isEmergency || tag == 'AVAILABLE'
                                        ? const Color(0xFFFF4D00)
                                        : const Color(0xFF888888),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Color(0xFFFF4D00),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          distance,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // ── Customer Notes (show only if present) ─────────────
                  Builder(builder: (_) {
                    final notes = fullDataMap['notes']?.toString().trim() ?? '';
                    if (notes.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2_outlined,
                              color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notes,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF78350F),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF2F2F2)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8DD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_gas_station,
                          color: Color(0xFFFF4D00),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fuel Type',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              fuelType,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F1F1F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isEmergency) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          width: 80,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailsScreen(order: fullDataMap),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4D00),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.explore, size: 18),
                                SizedBox(width: 4),
                                Text('GO',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ] else if (!isAvailable) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          width: 100,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailsScreen(order: fullDataMap),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFDDDDDD)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Details',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // ── Green Accept Order button (available orders only) ──
                  if (isAvailable) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _acceptingOrderId == id
                            ? null
                            : _acceptingOrderId != null
                                ? null
                                : () async {
                                    setState(
                                        () => _acceptingOrderId = id);
                                    await _acceptOrder(id);
                                    if (mounted) {
                                      setState(
                                          () => _acceptingOrderId = null);
                                    }
                                  },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _acceptingOrderId == id
                              ? const Color(0xFF81C784)
                              : const Color(0xFF2E7D32),
                          disabledBackgroundColor:
                              const Color(0xFF81C784),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _acceptingOrderId == id
                            ? const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Accepting…',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Accept Order',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

