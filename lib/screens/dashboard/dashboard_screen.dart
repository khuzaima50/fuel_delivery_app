import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../order/notifications_screen.dart';
import '../order/assigned_orders_screen.dart';
import '../order/delivery_navigation_screen.dart';
import '../order/order_details_screen.dart';
import '../profile/settings_screen.dart';
import '../../services/driver_database_service.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../../services/service_area_service.dart';


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
  bool _isFetching = false;
  double _currentFuel = 0;
  final double _maxFuelCapacity = 100;
  bool _isFuelLoading = true;
  String? _profileImageUrl;

  // ── Nearby orders (shown on dashboard) ────────────────────────────
  // _serviceAreas is loaded once on init and used for order proximity filtering.
  // When empty, ServiceAreaService falls back to 25 km driver-relative radius.
  List<ServiceArea> _serviceAreas = [];
  List<Map<String, dynamic>> _nearbyOrders = [];
  String? _acceptingOrderId;          // order ID currently being accepted
  Position? _driverPosition;
  RealtimeChannel? _nearbyChannel;
  StreamSubscription<Position>? _dashLocationStream;

  // ── Debounce / cancellation ────────────────────────────────────────
  int _fetchToken = 0;
  Timer? _debounceTimer;
  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();
    _loadServiceAreas();
    _scheduleFetch();
    _startLocationWatch();
    _subscribeNearbyOrders();
  }

  /// Fetches active service areas once on screen load.
  /// A refresh can be triggered by calling this again (e.g., on pull-to-refresh).
  Future<void> _loadServiceAreas() async {
    final areas = await ServiceAreaService.fetchActiveAreas();
    if (mounted) setState(() => _serviceAreas = areas);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _watchdogTimer?.cancel();
    _nearbyChannel?.unsubscribe();
    _dashLocationStream?.cancel();
    super.dispose();
  }

  // ── Track driver location for proximity filter ─────────────────────
  Future<void> _startLocationWatch() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      if (mounted) {
        setState(() => _driverPosition = pos);
        _fetchNearbyOrders(); // Re-fetch orders with the actual location
      }
      _dashLocationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, distanceFilter: 300),
      ).listen((p) { 
        if (mounted) {
          setState(() => _driverPosition = p);
          _fetchNearbyOrders(); // Re-fetch if driver moves significantly
        }
      });
    } catch (_) {}
  }

  // ── Whether an order falls within a configured service area ──────────────────
  // Delegates to ServiceAreaService which handles both the service-area check
  // and the 25 km fallback when no service areas are configured.
  bool _isNearby(Map<String, dynamic> order) {
    // Try all known coordinate field names used in this app's DB schema
    final latRaw = order['customer_lat']
        ?? order['delivery_lat']
        ?? order['latitude']
        ?? order['delivery_latitude']
        ?? order['lat'];
    final lngRaw = order['customer_lng']
        ?? order['delivery_lng']
        ?? order['longitude']
        ?? order['delivery_longitude']
        ?? order['lng'];

    final orderLat = double.tryParse(latRaw?.toString() ?? '');
    final orderLng = double.tryParse(lngRaw?.toString() ?? '');

    return ServiceAreaService.isOrderInServiceAreas(
      areas: _serviceAreas,
      driverLat: _driverPosition?.latitude,
      driverLng: _driverPosition?.longitude,
      orderLat: orderLat,
      orderLng: orderLng,
      orderId: order['id']?.toString(),
    );
  }

  // ── Realtime subscription for available/pending orders ────────────
  void _subscribeNearbyOrders() {
    _nearbyChannel?.unsubscribe();
    _nearbyChannel = Supabase.instance.client
        .channel('dashboard:nearby_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final order = Map<String, dynamic>.from(payload.newRecord);
            final status = order['status']?.toString().toLowerCase() ?? '';
            final dId = order['driver_id'];
            final hasDriver = dId != null && dId.toString().trim().isNotEmpty && dId.toString().trim() != 'null';
            if (!mounted) return;
            if ((status == 'available' || status == 'pending') && !hasDriver && _isNearby(order)) {
              setState(() {
                if (!_nearbyOrders.any((o) => o['id'] == order['id'])) {
                  _nearbyOrders.insert(0, order);
                }
              });
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final order = Map<String, dynamic>.from(payload.newRecord);
            final status = order['status']?.toString().toLowerCase() ?? '';
            final dId = order['driver_id'];
            final hasDriver = dId != null && dId.toString().trim().isNotEmpty && dId.toString().trim() != 'null';
            if (!mounted) return;
            setState(() {
              // Remove if no longer available (assigned by someone else)
              if (hasDriver || (status != 'available' && status != 'pending')) {
                _nearbyOrders.removeWhere((o) => o['id'] == order['id']);
              }
            });
          },
        )
        .subscribe();

    // Also do an initial DB fetch of current nearby available orders
    _fetchNearbyOrders();
  }

  Future<void> _fetchNearbyOrders() async {
    try {
      // Fetch recent orders WITHOUT SQL status/driver_id filters.
      // Reason 1: DB stores 'PENDING' (uppercase) but inFilter only matches exact case.
      // Reason 2: driver_id IS NULL misses empty-string driver_ids.
      // We mirror assigned_orders_screen exactly — filter everything in Dart.
      final data = await Supabase.instance.client
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(300);
      if (!mounted) return;

      final fetched = (data as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((o) {
            // Status check — case-insensitive, same as assigned_orders_screen
            final status = o['status']?.toString().toLowerCase().trim() ?? '';
            if (status != 'available' && status != 'pending') return false;

            // driver_id check — null, empty string, or literal "null" = unclaimed
            final dId = o['driver_id'];
            final isUnclaimed = dId == null ||
                dId.toString().trim().isEmpty ||
                dId.toString().trim() == 'null';
            if (!isUnclaimed) return false;

            // Proximity check — conservative, shows when no coords available
            return _isNearby(o);
          })
          .toList();

      debugPrint('[Dashboard] _fetchNearbyOrders: ${data.length} total fetched → '
          '${fetched.length} unclaimed+nearby orders');

      setState(() {
        _nearbyOrders = fetched;
      });
    } catch (e) {
      debugPrint('[Dashboard] _fetchNearbyOrders error: $e');
    }

  }

  // ── Race-safe accept ───────────────────────────────────────────────
  Future<void> _acceptNearbyOrder(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString() ?? '';
    if (orderId.isEmpty || _acceptingOrderId != null) return;
    if (mounted) setState(() => _acceptingOrderId = orderId);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // ── PREFLIGHT CHECK: Live DB se confirm karo ke order abhi bhi available hai ──
      final liveCheck = await Supabase.instance.client
          .from('orders')
          .select('id, status, driver_id')
          .eq('id', orderId)
          .maybeSingle();

      if (liveCheck == null) {
        // Order DB mein mil hi nahi raha
        if (mounted) setState(() => _nearbyOrders.removeWhere((o) => o['id'] == orderId));
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.dashboardOrderNoLongerAvailable),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      final liveStatus = liveCheck['status']?.toString().toLowerCase() ?? '';

      // Safely extract driver_id — treat null, empty string, and literal "null" as unclaimed
      final rawDriverId = liveCheck['driver_id'];
      final bool hasRealDriver = rawDriverId != null &&
          rawDriverId.toString().trim().isNotEmpty &&
          rawDriverId.toString().trim() != 'null';
      final String liveDriverId = hasRealDriver ? rawDriverId.toString().trim() : '';

      debugPrint('[Dashboard] Preflight: status=$liveStatus driverId=$liveDriverId hasDriver=$hasRealDriver');

      // Agar yeh order pehle se current driver ka hai — seedha navigate karo
      if (hasRealDriver && liveDriverId == user.id) {
        if (mounted) setState(() => _nearbyOrders.removeWhere((o) => o['id'] == orderId));
        final fullOrder = await Supabase.instance.client
            .from('orders').select().eq('id', orderId).maybeSingle();
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DeliveryNavigationScreen(order: fullOrder ?? {'id': orderId}),
        ));
        return;
      }

      // Agar kisi AUR (real) driver ne le liya
      if (hasRealDriver || (liveStatus != 'available' && liveStatus != 'pending')) {
        if (mounted) setState(() => _nearbyOrders.removeWhere((o) => o['id'] == orderId));
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.dashboardOrderTakenByAnother),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      // ── END PREFLIGHT ──────────────────────────────────────────────


      final profile = await Supabase.instance.client
          .from('drivers')
          .select('full_name, avatar_url, vehicle_type, phone')
          .eq('id', user.id)
          .maybeSingle();

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 5)));
      } catch (_) {}

      final nowTs = DateTime.now().toUtc().toIso8601String();
      final payload = <String, dynamic>{
        'status': 'assigned',
        'driver_id': user.id,
        'assigned_at': nowTs,
        'driver_name': profile?['full_name'] ?? 'Driver',
        'driver_photo': profile?['avatar_url'] ?? '',
        'driver_vehicle': profile?['vehicle_type'] ?? 'Fuel Truck',
        'driver_phone': profile?['phone'] ?? '',
        if (pos != null) 'driver_latitude': pos.latitude,
        if (pos != null) 'driver_longitude': pos.longitude,
      };

      // ── UPDATE: Simple eq-only update (no SQL status/driver_id guards) ──────
      // Race safety is ensured by reading the row AFTER the update and verifying
      // that driver_id is now set to OUR user ID.
      await Supabase.instance.client
          .from('orders')
          .update(payload)
          .eq('id', orderId);

      // Verify the update won the race — read back the current row
      final verifyRow = await Supabase.instance.client
          .from('orders')
          .select('id, driver_id, status')
          .eq('id', orderId)
          .maybeSingle();

      final actualDriverId = verifyRow?['driver_id']?.toString() ?? '';
      final actualStatus   = verifyRow?['status']?.toString().toLowerCase() ?? '';

      debugPrint('[Dashboard] Post-update verify: driver_id=$actualDriverId status=$actualStatus');

      if (actualDriverId != user.id) {
        // Another driver won the race between preflight and update
        if (mounted) setState(() => _nearbyOrders.removeWhere((o) => o['id'] == orderId));
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.dashboardOrderTakenByAnother),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }


      // Log
      try {
        await DriverDatabaseService.instance.logDriverAction(
          action: 'ORDER_ACCEPTED',
          details: {'order_id': orderId, 'assigned_at': nowTs},
        );
      } catch (_) {}

      // Remove from nearby list and refresh dashboard
      if (mounted) setState(() => _nearbyOrders.removeWhere((o) => o['id'] == orderId));
      _scheduleFetch();

      // Fetch full order row to show OrderDetailsScreen
      Map<String, dynamic>? fullOrder;
      try {
        fullOrder = await Supabase.instance.client
            .from('orders').select().eq('id', orderId).maybeSingle();
      } catch (_) {}

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      // Navigate to OrderDetailsScreen first
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(order: fullOrder ?? {'id': orderId}),
      ));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.dashboardOrderAccepted),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ));

    } catch (e) {
      debugPrint('[Dashboard] _acceptNearbyOrder error: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.dashboardFailedAction}$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _acceptingOrderId = null);
      }
    }
  }

  // ── Debounced fetch entry-point ────────────────────────────────────
  /// Call this instead of `_fetchDashboardData` directly.
  /// Collapses rapid consecutive calls into a single fetch after 300 ms.
  void _scheduleFetch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _fetchDashboardData();
    });
  }

  Future<void> _fetchDashboardData() async {
    // ── Prevent concurrent requests ────────────────────────────────────
    if (_isFetching) {
      debugPrint('[Dashboard] Fetch already in-flight — skipping duplicate request');
      return;
    }

    // Grab a token that identifies THIS request.  If a newer request starts
    // before this one finishes the token will have changed and we bail early.
    final int myToken = ++_fetchToken;
    _isFetching = true;

    // ── Watchdog: auto-recover if stuck loading for > 15 s ────────────
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        debugPrint('[Dashboard] ⚠ Watchdog fired — clearing stuck loading state');
        setState(() {
          _isLoading = false;
          _isFetching = false;
          _isFuelLoading = false;
        });
      }
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() { _isLoading = false; _isFetching = false; });
        return;
      }

      // ── Profile ────────────────────────────────────────────────────
      final profile = await Supabase.instance.client
          .from('drivers')
          .select('*, current_fuel_capacity')
          .eq('id', user.id)
          .maybeSingle();

      // Bail if this request has been superseded
      if (myToken != _fetchToken || !mounted) return;

      if (profile != null) {
        setState(() {
          _driverName = profile['full_name'] ?? 'Driver';
          final vType = (profile['vehicle_type'] ?? '').toString().trim();
          _truckId = vType.isEmpty ? 'Fuel Tanker - 01' : vType;
          _isOnline = profile['status'] == 'online';
          _profileImageUrl = profile['avatar_url'];
        });

        // ── Dynamic Fuel Calculation ──────────────────────────────────
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

        try {
          final completedOrders = await Supabase.instance.client
              .from('orders')
              .select('id')
              .eq('driver_id', user.id)
              .inFilter('status', ['completed', 'delivered', 'COMPLETED', 'DELIVERED'])
              .gte('completed_at', startOfDay);

          if (myToken != _fetchToken || !mounted) return;

          final int completedToday = (completedOrders as List).length;
          final double calculatedFuel = _maxFuelCapacity - (completedToday * 10.0);
          setState(() {
            _currentFuel = calculatedFuel < 0 ? 0 : calculatedFuel;
            _isFuelLoading = false;
          });
        } catch (e) {
          debugPrint('[Dashboard] Error calculating fuel: $e');
          if (myToken == _fetchToken && mounted) {
            setState(() {
              _currentFuel = _maxFuelCapacity;
              _isFuelLoading = false;
            });
          }
        }

        // Welcome notification — once per session
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

      // ── Active Order ───────────────────────────────────────────────
      if (_isOnline) {
        Map<String, dynamic>? order = await Supabase.instance.client
            .from('orders')
            .select()
            .eq('driver_id', user.id)
            .eq('status', 'assigned')
            .limit(1)
            .maybeSingle();

        if (myToken != _fetchToken || !mounted) return;

        // Enrich with customer info if missing
        if (order != null) {
          final hasName = (order['customer_name'] ?? '').toString().trim().isNotEmpty;
          if (!hasName) {
            final userId = order['user_id']?.toString();
            if (userId != null && userId.isNotEmpty) {
              try {
                final profileData = await Supabase.instance.client
                    .from('profiles')
                    .select('full_name, phone_number, avatar_url')
                    .eq('id', userId)
                    .maybeSingle();
                if (myToken != _fetchToken || !mounted) return;
                if (profileData != null) {
                  order = {
                    ...order,
                    'customer_name': profileData['full_name'] ?? order['customer_name'],
                    'customer_phone': profileData['phone_number'] ?? order['customer_phone'],
                    'customer_avatar': profileData['avatar_url'],
                  };
                }
              } catch (e) {
                debugPrint('[Dashboard] Error fetching customer profile: $e');
              }
            }
          }
        }

        if (myToken == _fetchToken && mounted) {
          setState(() {
            _activeOrder = order;
            _isLoading = false;
          });
        }
      } else {
        if (myToken == _fetchToken && mounted) {
          setState(() {
            _activeOrder = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[Dashboard] Error fetching dashboard data: $e');
      if (myToken == _fetchToken && mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      // Only clear the guard if this is still the active request
      if (myToken == _fetchToken) {
        _isFetching = false;
        _watchdogTimer?.cancel();
      }
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
        final l10n = AppLocalizations.of(context)!;
        setState(() => _activeOrder = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dashboardEmergencyAlert),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      // Debounced re-fetch — won't overlap with itself
      _scheduleFetch();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.dashboardFailedEmergency}$e')),
        );
      }
    }
  }

  Future<void> _toggleStatus(bool value) async {
    // Optimistic update so the switch feels instant
    setState(() => _isOnline = value);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('drivers')
            .update({'status': value ? 'online' : 'offline'})
            .eq('id', user.id);
      }
      // Use debounced fetch — prevents double-fire when toggle causes rapid state changes
      _scheduleFetch();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isOnline = !value); // Revert optimistic update
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dashboardFailedUpdateStatus)),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dashboardCannotDialer)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                              l10n.dashboardDelivers,
                              _isOnline ? l10n.dashboardActive : l10n.dashboardOffline,
                              _isOnline ? l10n.dashboardReceivingOrders : l10n.dashboardGoOnline,
                              Icons.directions_car,
                              _isOnline ? 1.0 : 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _isFuelLoading 
                              ? _buildStatCard(
                                  l10n.dashboardFuelCapacity,
                                  '--', // Loading placeholder
                                  l10n.dashboardLoading,
                                  Icons.local_gas_station,
                                  0.0,
                                )
                              : _buildStatCard(
                                  l10n.dashboardFuelCapacity,
                                  _currentFuel > 0 ? '${_currentFuel.toStringAsFixed(0)} Gal' : '0 Gal',
                                  _currentFuel > 0 ? '${((_currentFuel / _maxFuelCapacity) * 100).toStringAsFixed(0)}%' : l10n.dashboardEmpty,
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
                          _activeOrder != null ? l10n.dashboardActiveDelivery : l10n.dashboardAvailableStatus,
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
                        Text(
                          l10n.dashboardAvailableStatus,
                          style: const TextStyle(
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
                              title: Text(l10n.dashboardEmergencyTitle),
                              content: Text(l10n.dashboardEmergencyPrompt),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(l10n.common_cancel),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _triggerEmergency();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  child: Text(l10n.dashboardEmergencyConfirm, style: const TextStyle(color: Colors.white)),
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
                                  children: [
                                    Text(
                                      l10n.dashboardEmergencyTitle,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.dashboardEmergencySubtitle,
                                      style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    // Try multiple field names — different parts of the app store phone differently
    final customerPhone = [
      _activeOrder!['customer_phone'],
      _activeOrder!['phone'],
      _activeOrder!['customer_mobile'],
      _activeOrder!['user_phone'],
    ].firstWhere(
      (v) => v != null && v.toString().trim().isNotEmpty,
      orElse: () => null,
    )?.toString().trim() ?? '';

    // ── Scheduled time-lock ───────────────────────────────────────────
    final rawScheduledTime = _activeOrder!['scheduled_time'];
    DateTime? scheduledDt;
    if (rawScheduledTime != null &&
        rawScheduledTime.toString().trim().isNotEmpty) {
      try {
        scheduledDt = DateTime.parse(rawScheduledTime.toString()).toLocal();
      } catch (_) {}
    }
    final bool isTimeLocked = scheduledDt != null &&
        scheduledDt.difference(DateTime.now()).inMinutes > 60;
    final String scheduledLabel = scheduledDt != null
        ? '${scheduledDt.hour > 12 ? scheduledDt.hour - 12 : (scheduledDt.hour == 0 ? 12 : scheduledDt.hour)}:${scheduledDt.minute.toString().padLeft(2, '0')} ${scheduledDt.hour >= 12 ? 'PM' : 'AM'}'
        : '';

    void showTimeLockWarning() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.dashboardScheduledWarning(scheduledLabel),
          ),
          backgroundColor: const Color(0xFFFF8C00),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // Prefer customer_lat/lng (actual GPS location) over delivery_lat/lng
    double? extractDouble(String key1, String key2) {
      final v = _activeOrder![key1] ?? _activeOrder![key2];
      if (v == null) return null;
      final d = double.tryParse(v.toString());
      return (d == 0.0) ? null : d;
    }

    final deliveryLat = extractDouble('customer_lat', 'delivery_lat');
    final deliveryLng = extractDouble('customer_lng', 'delivery_lng');

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
                      'STATUS • ${l10n.dashboardStatusAssigned}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF4D00),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _activeOrder!['delivery_address'] ?? 'Unknown Address',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_activeOrder!['fuel_quantity'] ?? _activeOrder!['fuel_quantity_gallons'] ?? 'N/A'} Gallons of ${_activeOrder!['fuel_type'] ?? 'Fuel'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                              final distText = distMeters > 0
                                  ? l10n.dashboardMilesAway((distMeters / 1609.34).toStringAsFixed(1))
                                  : l10n.dashboardMilesAway('0.0');
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isTimeLocked
                      ? showTimeLockWarning
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DeliveryNavigationScreen(
                                order: _activeOrder,
                              ),
                            ),
                          );
                        },
                  icon: Icon(
                    Icons.explore_outlined,
                    size: 20,
                    color: isTimeLocked ? Colors.grey : Colors.white,
                  ),
                  label: Text(l10n.dashboardNavigate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTimeLocked
                        ? const Color(0xFFDDDDDD)
                        : const Color(0xFFFF4D00),
                    foregroundColor:
                        isTimeLocked ? Colors.grey : Colors.white,
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
                  onPressed: isTimeLocked
                      ? showTimeLockWarning
                      : () async {
                          if (customerPhone.isNotEmpty) {
                            await _makePhoneCall(customerPhone);
                          } else {
                            // Try to fetch phone from profiles table
                            final userId = _activeOrder!['user_id']?.toString();
                            if (userId != null && userId.isNotEmpty) {
                              try {
                                final profile = await Supabase.instance.client
                                    .from('profiles')
                                    .select('phone_number, phone')
                                    .eq('id', userId)
                                    .maybeSingle();
                                final phone = (profile?['phone_number'] ?? profile?['phone'])?.toString().trim() ?? '';
                                if (phone.isNotEmpty && mounted) {
                                  await _makePhoneCall(phone);
                                  return;
                                }
                              } catch (_) {}
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.dashboardNoPhone),
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              );
                            }
                          }
                        },
                  icon: Icon(
                    Icons.phone_outlined,
                    size: 20,
                    color: isTimeLocked ? Colors.grey : Colors.white,
                  ),
                  label: Text(l10n.dashboardContact),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTimeLocked
                        ? const Color(0xFFDDDDDD)
                        : const Color(0xFFFF4D00),
                    foregroundColor:
                        isTimeLocked ? Colors.grey : Colors.white,
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
              onPressed: isTimeLocked
                  ? showTimeLockWarning
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (deliveryLat != null && deliveryLng != null) {
                        final url = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=$deliveryLat,$deliveryLng',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                                content:
                                    Text(l10n.dashboardOpenMapsError)),
                          );
                        }
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(
                                  l10n.dashboardNoGps)),
                        );
                      }
                    },
              icon: Icon(
                Icons.map_outlined,
                color: isTimeLocked
                    ? Colors.grey
                    : const Color(0xFFFF4D00),
                size: 18,
              ),
              label: Text(
                l10n.dashboardOpenMaps,
                style: TextStyle(
                    color: isTimeLocked
                        ? Colors.grey
                        : const Color(0xFFFF4D00),
                    fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: isTimeLocked
                        ? Colors.grey
                        : const Color(0xFFFF4D00)),
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
    final l10n = AppLocalizations.of(context)!;
    if (_nearbyOrders.isEmpty) {
      // No nearby orders yet — show radar pulse
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
            const Icon(Icons.radar, size: 48, color: Color(0xFFFF4D00)),
            const SizedBox(height: 16),
            Text(
              l10n.dashboardSearchingNearby,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F1F1F)),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboardSearchingNearbyDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AssignedOrdersScreen()),
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 18, color: Color(0xFFFF4D00)),
                label: Text(l10n.dashboardViewAllOrders,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFF4D00))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4D00)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Nearby orders list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFFF4D00), size: 16),
            const SizedBox(width: 6),
            Text(
              l10n.dashboardOrdersCount(_nearbyOrders.length),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFF4D00)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AssignedOrdersScreen()),
              ),
              child: Text(l10n.dashboardViewAllText, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._nearbyOrders.map((order) => _buildNearbyOrderCard(order)),
      ],
    );
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * 3.1415926535897932 / 180;
    final dLng = (lng2 - lng1) * 3.1415926535897932 / 180;
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(lat1 * 3.1415926535897932 / 180) *
            math.cos(lat2 * 3.1415926535897932 / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Widget _buildNearbyOrderCard(Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context)!;
    final orderId = order['id']?.toString() ?? '';
    final shortId = '#ORD-${orderId.length >= 4 ? orderId.substring(0, 4).toUpperCase() : orderId.toUpperCase()}';
    final address = order['delivery_address']?.toString() ?? 'Unknown Location';
    final fuelType = '${order['fuel_quantity'] ?? order['fuel_quantity_gallons'] ?? '?'} Gal ${order['fuel_type'] ?? 'Fuel'}';
    final isAccepting = _acceptingOrderId == orderId;

    // Distance label
    String distLabel = '';
    final pos = _driverPosition;
    if (pos != null) {
      final lat = double.tryParse(order['latitude']?.toString() ?? '');
      final lng = double.tryParse(order['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        final km = _haversineKm(pos.latitude, pos.longitude, lat, lng);
        distLabel = km < 1 ? l10n.dashboardMetersAway((km * 1000).round()) : l10n.dashboardKmAway(km.toStringAsFixed(1));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Positioned(left: 0, top: 14, bottom: 14,
              child: Container(width: 3, decoration: BoxDecoration(color: const Color(0xFFFF4D00), borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(shortId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFF4D00))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                      child: Text(l10n.dashboardStatusAvailable, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                    ),
                    const Spacer(),
                    if (distLabel.isNotEmpty)
                      Flexible(
                        child: Text(
                          distLabel,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(address,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_gas_station, size: 13, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        fuelType,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (_acceptingOrderId != null)
                        ? null
                        : () => _acceptNearbyOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAccepting ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                      disabledBackgroundColor: const Color(0xFF81C784),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isAccepting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              const SizedBox(width: 10),
                              Text(l10n.dashboardAccepting, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.dashboardAcceptOrder, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCard() {
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.dashboardOfflineCardTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dashboardOfflineCardDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFFF4D00), size: 22),
              if (subtitle.isNotEmpty)
                Flexible(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
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
