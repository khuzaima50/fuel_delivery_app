# Real-Time Live Tracking: Comprehensive Problem Catalog & Root Causes

This document details every real-world bug, edge case, and architectural failure mode encountered in real-time GPS tracking applications, along with their root causes and verified remedies.

---

## 1. The Native Stream Collision Bug (`getCurrentPosition` vs `getPositionStream`)

### Symptom
* Driver opens the tracking screen and begins moving.
* The map marker remains completely frozen at the starting point.
* Terminal logs report **0 raw GPS events** while moving.

### Root Cause
On Android devices, Google Play Services' `FusedLocationProviderClient` maintains an internal request queue. When a single-shot request like `Geolocator.getCurrentPosition()` or an un-synchronized route-fetching call executes while `Geolocator.getPositionStream()` is actively listening, the native Android provider resets its active listener and cancels the continuous stream without throwing a visible Dart exception.

### Permanent Fix
* Strictly ban `getCurrentPosition()` across the entire active navigation screen lifecycle.
* Fetch routes and initialize camera positions using `Geolocator.getLastKnownPosition()` or the first genuine event from the continuous stream.

---

## 2. Competing Stream Subscriptions on App Lifecycle Resume

### Symptom
* Driver minimizes the app to check an SMS or take a phone call, then returns to the app.
* The app either crashes, marker updates stutter, or battery consumption surges dramatically.

### Root Cause
`didChangeAppLifecycleState(AppLifecycleState.resumed)` repeatedly called `_gpsTracker.restart(...)` without verifying whether the previous native stream was still active or in the process of starting. This created multiple concurrent background subscriptions fighting for CPU cycles and receiving duplicate location events.

### Permanent Fix
1. Guard lifecycle triggers with `if (!_gpsTracker.isActive)`.
2. Encapsulate all `start()` and `restart()` methods within a mutual-exclusion lock (`_isStarting`).
3. Explicitly `await _positionSub?.cancel()` to ensure the old native stream is fully closed before opening a new channel.

---

## 3. The "Reopen Jump" Illusion

### Symptom
* Marker stays frozen while driving.
* Exiting the screen and reopening it causes the marker to suddenly "jump" to the driver's current real-world location.

### Root Cause
The active GPS stream was dead (receiving 0 events). When the screen was reopened, `initState()` executed `Geolocator.getLastKnownPosition()`. Because the Android OS continuously maintains a cached location from other system sensors (cell tower / Wi-Fi), `getLastKnownPosition()` returned the driver's current position upon screen load, creating the false illusion that GPS was working when in reality the live stream was dead.

### Permanent Fix
* Decouple `getLastKnownPosition()` from live streaming logic.
* Use raw stream telemetry (`LOCATION_EVENT_RAW`) to guarantee that continuous real-time events are driving the marker, not static cache lookups.

---

## 4. UI Thread Starvation via Synchronous Database Writes

### Symptom
* Map animations lag, drop frames, or stutter whenever a location update occurs.
* In areas with poor mobile reception (2G/3G), the entire app freezes.

### Root Cause
Awaiting network requests (such as Supabase database updates or REST API calls) inside the continuous GPS stream callback. A 2-second HTTP timeout or network stall blocks the Flutter main UI thread from rendering marker repositioning frames.

### Permanent Fix
* Decouple local UI updates (fast-path: 0 ms lag) from cloud telemetry (slow-path: throttled to 2–3 seconds).
* Run cloud writes in un-awaited background `Future` tasks (`_writeToSupabase(pos)`) so network latencies never impact UI rendering.

---

## 5. Marker Spinning & Erratic Heading at Low Speeds / Traffic Lights

### Symptom
* When the vehicle comes to a complete stop at a red light, the navigation arrow marker begins spinning wildly or points North (0°).

### Root Cause
GPS satellite Doppler calculations for heading become mathematically undefined or highly noisy when vehicle velocity drops below ~0.5 m/s. The GPS hardware either emits noise or defaults to `heading: 0.0`.

### Permanent Fix
Implement **Sensor Fusion**:
* When `speed >= 0.5 m/s`: Use GPS satellite heading (`pos.heading`) or vector displacement.
* When `speed < 0.5 m/s`: Ignore GPS heading and read the device's hardware magnetometer via `flutter_compass` to accurately orient the vehicle arrow in the direction the phone is facing.

---

## 6. Zero-Coordinate and Out-of-Order Timestamp Corruptions

### Symptom
* Marker suddenly teleports to the Atlantic Ocean `(0.0, 0.0)` or flickers back and forth between previous locations.

### Root Cause
* Hardware GPS initialization often returns `(0.0, 0.0)` on the very first fix before satellite triangulation locks.
* In multi-threaded native bridges, buffered GPS fixes can occasionally be delivered out of chronological order.

### Permanent Fix
* Validate coordinates at the entry point of the stream:
  ```dart
  if (pos.latitude == 0.0 && pos.longitude == 0.0) {
    debugPrint('LOCATION_EVENT_REJECTED reason=zero_coordinates');
    return;
  }
  ```
* Reject stale or out-of-order timestamps:
  ```dart
  if (_lastFixTimestamp != null && pos.timestamp.isBefore(_lastFixTimestamp!)) {
    debugPrint('LOCATION_EVENT_REJECTED reason=out_of_order');
    return;
  }
  _lastFixTimestamp = pos.timestamp;
  ```

---

## 7. Android OS Doze Mode & Battery Management Termination

### Symptom
* Tracking works for the first 60 seconds, then stops updating completely after the phone screen dims or locks.

### Root Cause
Android 10+ (API 29+) and Android 14+ aggressively put background tasks and location listeners into Doze mode to conserve battery unless a dedicated Foreground Service with a persistent notification is registered.

### Permanent Fix
* Declare `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION` permissions in `AndroidManifest.xml`.
* Register `com.baseflow.geolocator.GeolocatorLocationService` with `android:foregroundServiceType="location"`.

---

## 8. Memory Leaks from Dangling Subscriptions and Controllers

### Symptom
* Navigating between orders causes app performance to progressively degrade, eventually leading to Out-Of-Memory (OOM) crashes.

### Root Cause
Failing to cancel `StreamSubscription<Position>`, `StreamSubscription<CompassEvent>`, `StreamSubscription<ServiceStatus>`, or `GoogleMapController` when the delivery screen is popped off the navigation stack.

### Permanent Fix
Consolidate teardown in `dispose()`:
```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _gpsTracker.dispose();
  _compassSub?.cancel();
  _serviceStatusSub?.cancel();
  _orderStatusChannel?.unsubscribe();
  _mapController?.dispose();
  super.dispose();
}
```

---

## Summary Problem Matrix

| # | Problem Encountered | Root Cause | Impact | Verified Solution |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **Frozen Live Marker** | `getCurrentPosition` cancelled `getPositionStream` | Stream killed at native level (0 events) | Ban `getCurrentPosition` during navigation |
| 2 | **App Crashes / Lag on Resume** | Unserialized `restart()` calls | Competing stream subscriptions | Async `_isStarting` lock guard |
| 3 | **False "Reopen Jump"** | `getLastKnownPosition` masking dead stream | Stream appeared functional only on reload | Observable raw telemetry logging |
| 4 | **UI Frame Stutter** | Awaiting Supabase writes inside GPS listener | UI thread starved on slow networks | Decouple UI updates from throttled background writes |
| 5 | **Spinning Marker at Red Lights** | GPS heading noise at 0 m/s speed | Arrow points wrong way when stopped | Sensor fusion with hardware magnetometer |
| 6 | **Teleporting to (0,0)** | GPS cold-start defaults | Marker moves to Null Island | Sanity check filter at stream entry |
| 7 | **Stream Dies When Screen Dims** | Android Doze Mode battery saver | OS terminates GPS stream | Android Foreground Service declaration |
| 8 | **Memory Leaks / OOM** | Dangling subscriptions on pop | Memory buildup over multiple deliveries | Complete teardown in `dispose()` |
