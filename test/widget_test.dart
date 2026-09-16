import 'package:flutter_test/flutter_test.dart';
import 'package:fueldirect_app/services/service_area_service.dart';

void main() {
  test('ServiceArea model deserialization test', () {
    final map = {
      'id': 'sa-101',
      'name': 'Test Zone',
      'center_lat': 32.42,
      'center_lng': -104.22,
      'radius_km': 25.0,
      'is_active': true,
    };
    final area = ServiceArea.fromMap(map);
    expect(area.id, 'sa-101');
    expect(area.name, 'Test Zone');
    expect(area.centerLat, 32.42);
    expect(area.centerLng, -104.22);
    expect(area.radiusKm, 25.0);
    expect(area.isActive, isTrue);
  });

  test('Haversine distance calculation test', () {
    // Carlsbad to Carlsbad distance should be 0
    final d = ServiceAreaService.haversineKm(32.4203, -104.2289, 32.4203, -104.2289);
    expect(d, closeTo(0.0, 0.001));
  });

  test('ServiceAreaService isOrderInServiceAreas returns true', () {
    final inArea = ServiceAreaService.isOrderInServiceAreas(
      areas: [],
      driverLat: 32.42,
      driverLng: -104.22,
      orderLat: 32.45,
      orderLng: -104.25,
      orderId: 'ord-1',
    );
    expect(inArea, isTrue);
  });
}
