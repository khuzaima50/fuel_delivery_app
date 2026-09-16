# Real-Time Live Tracking Implementation Guide

This document details the concrete strategies, coding patterns, lifecycle rules, and platform configurations required to implement a zero-defect live tracking pipeline in Flutter.

---

## Strategy 1: Mutually Exclusive & Serialized Stream Lifecycle

### Problem Addressed
In mobile applications, rapid screen navigation, backgrounding/resuming, and repeated service-status events often invoke multiple concurrent `start()` or `restart()` calls. On Android, starting a new location subscription before the old one is completely torn down causes race conditions, leaving subscriptions dangling or unassigned.

### Implementation Pattern
All lifecycle methods (`start()`, `restart()`, and `dispose()`) must be protected by an asynchronous lock (`_isStarting`) and explicitly `await` previous subscription cancellations:

```dart
class DriverLocationStream {
  StreamSubscription<Position>? _positionSub;
  bool _isStarting = false;

  bool get isActive => _positionSub != null;

  Future<bool> start({
    required void Function(Position position) onPosition,
    int dbThrottleSeconds = 2,
  }) async {
    if (_isStarting) {
      debugPrint('[Location Start] start() already in progress — skipping');
      return _positionSub != null;
    }
    if (_positionSub != null) {
      debugPrint('[Location Start] Stream already active — skipping duplicate');
      return true;
    }
    _isStarting = true;
    try {
      return await _doStart(onPosition: onPosition, dbThrottleSeconds: dbThrottleSeconds);
    } finally {
      _isStarting = false;
    }
  }

  Future<bool> restart({
    required void Function(Position position) onPosition,
    int dbThrottleSeconds = 2,
  }) async {
    if (_isStarting) {
      debugPrint('[Location Restart] In progress — skipping');
      return _positionSub != null;
    }
    _isStarting = true;
    try {
      await _disposeInternal();
      return await _doStart(onPosition: onPosition, dbThrottleSeconds: dbThrottleSeconds);
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _disposeInternal() async {
    if (_positionSub != null) {
      await _positionSub?.cancel();
      _positionSub = null;
    }
    _lastFixTimestamp = null;
  }
}
```

---

## Strategy 2: Strict Prohibition of Single-Shot GPS Calls During Active Tracking

### Problem Addressed
Calling `Geolocator.getCurrentPosition()` while `Geolocator.getPositionStream()` is actively listening forces the Android `FusedLocationProviderClient` to reconfigure its internal request queue, which silently cancels the continuous stream at the native OS layer.

### Implementation Pattern
1. **Never** call `getCurrentPosition()` on active navigation screens.
2. Initial map presentation uses cached `Geolocator.getLastKnownPosition()`.
3. Route calculation begins upon receiving the first genuine GPS fix from `onPosition(pos)` or from the destination resolver.

```dart
// CORRECT: Safe initial presentation without killing the stream
Geolocator.getLastKnownPosition().then((pos) {
  if (pos != null && mounted && _currentMarkerPos == null) {
    setState(() {
      _currentMarkerPos = LatLng(pos.latitude, pos.longitude);
      _updateDriverMarker(_currentMarkerPos!, _currentBearing);
    });
  }
});
```

---

## Strategy 3: Fast-Path Local UI Updates & Sensor Fusion

### Problem Addressed
When a vehicle stops at a traffic light or moves at low speeds (< 2 m/s), GPS heading becomes erratic or defaults to `0.0` (North), causing the map marker to spin erratically.

### Implementation Pattern
Blend hardware GPS vector heading at driving speeds with device magnetometer/compass readings when stationary:

```dart
void _onNewPosition(Position pos) {
  if (!mounted) return;
  if (pos.latitude == 0.0 && pos.longitude == 0.0) return;

  final newLatLng = LatLng(pos.latitude, pos.longitude);
  double targetBearing = _currentBearing;

  // 1. Driving Speed (> 0.5 m/s): Use hardware GPS heading
  if (pos.speed >= 0.5 && pos.heading >= 0.0 && pos.heading <= 360.0) {
    targetBearing = pos.heading;
  } else if (_lastGpsFix != null) {
    // Fallback: Compute vector bearing between two consecutive points
    final distanceMoved = Geolocator.distanceBetween(
      _lastGpsFix!.latitude, _lastGpsFix!.longitude,
      pos.latitude, pos.longitude,
    );
    if (distanceMoved >= 3.0) {
      targetBearing = _calculateBearing(
        LatLng(_lastGpsFix!.latitude, _lastGpsFix!.longitude),
        newLatLng,
      );
    }
  }

  _currentMarkerPos = newLatLng;
  _currentBearing = targetBearing;
  _lastGpsFix = pos;

  // 2. Direct 0ms Local Marker Update
  _updateDriverMarker(newLatLng, targetBearing);

  // 3. Smooth Camera Follow
  if (_isCameraFollowing && _mapController != null) {
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: newLatLng,
          zoom: 16.5,
          tilt: 45,
          bearing: targetBearing,
        ),
      ),
    );
  }
}
```

### Stationary Magnetometer Listener:
```dart
void _initCompass() {
  _compassSub = FlutterCompass.events?.listen((event) {
    final heading = event.heading;
    if (heading == null || !mounted) return;

    // Only rotate marker via compass if vehicle is stationary or crawling
    final speed = _lastGpsFix?.speed ?? 0.0;
    if (speed < 1.5 && _currentMarkerPos != null) {
      _currentBearing = (heading + 360) % 360;
      _updateDriverMarker(_currentMarkerPos!, _currentBearing);
    }
  });
}
```

---

## Strategy 4: Throttled, Decoupled Cloud Telemetry

### Problem Addressed
Writing every 1-second GPS coordinate directly to the backend database exhausts client network bandwidth, causes database lock contention, drains mobile battery, and risks dropping UI frames if network latency spikes.

### Implementation Pattern
Separate the high-frequency UI callback from the low-frequency database writer:

```dart
// Inside stream event handler:
// Fast-Path (Always executes immediately)
onPosition(pos);

// Slow-Path (Throttled to once every 2-3 seconds in un-awaited background Future)
final now = DateTime.now();
if (_lastDbWrite == null || now.difference(_lastDbWrite!).inSeconds >= dbThrottleSeconds) {
  _lastDbWrite = now;
  _writeToSupabase(pos); // Non-blocking background call
}
```

---

## Strategy 5: Platform Native Android Configuration

### AndroidManifest.xml Requirements
Ensure all permissions and the foreground location service are explicitly declared:

```xml
<!-- Hardware & Location Permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<application ...>
    <!-- Geolocator Android Foreground Service declaration -->
    <service
        android:name="com.baseflow.geolocator.GeolocatorLocationService"
        android:enabled="true"
        android:exported="false"
        android:foregroundServiceType="location" />
</application>
```

### Android Location Settings Setup:
```dart
locationSettings = AndroidSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 0,
  intervalDuration: const Duration(seconds: 1),
);
```

---

## Strategy 6: Complete Diagnostic Observability Suite

### Standardized Diagnostic Tags
Always trace the GPS pipeline using unambiguous, standardized log tags:

| Tag | Purpose | Expected Frequency |
| :--- | :--- | :--- |
| `LOCATION_STREAM_CREATED` | Confirms native GPS stream initialized | Once per session |
| `LOCATION_EVENT_RAW` | First line of stream listener; proves native OS emitted fix | 1 per second |
| `LOCATION_EVENT_REJECTED` | Logs when a coordinate fix fails sanity checks | Only on GPS glitches |
| `LOCATION_CALLBACK_DELIVERING` | Fired immediately prior to UI callback execution | 1 per second |
| `LOCATION_CALLBACK_DELIVERED` | Fired immediately after UI marker is updated | 1 per second |
| `LOCATION_STREAM_ERROR` | Fired if native stream encounters an exception | On hardware/permission fault |
| `LOCATION_STREAM_DONE` | Fired if native stream completes or is closed | On screen disposal |
