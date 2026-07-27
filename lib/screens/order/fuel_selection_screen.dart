import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import 'schedule_delivery_screen.dart';

class FuelSelectionScreen extends StatefulWidget {
  const FuelSelectionScreen({super.key});

  @override
  State<FuelSelectionScreen> createState() => _FuelSelectionScreenState();
}

class _FuelSelectionScreenState extends State<FuelSelectionScreen> {
  int _selectedFuelIndex = 0;
  double _quantity = 45.0;
  bool _isFullTank = false;

  final List<double> _quickSelectOptions = [15.0, 45.0, 25.0];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.fuelTitle,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Fuel Types
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF5F5F5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.fuelTypes,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          '0',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFuelCard(
                            index: 0,
                            title: l10n.fuelPetrol,
                            price: '\$1.85/Gal',
                            subtitle: l10n.fuelOctanePremium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFuelCard(
                            index: 1,
                            title: l10n.fuelDiesel,
                            price: '\$1.32/ Gal',
                            subtitle: l10n.fuelUltraLowSulfur,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Quantity
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF5F5F5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.fuelQuantity,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_quantity.toStringAsFixed(1)}gal',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.fuelApproxRange,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 8,
                        activeTrackColor: const Color(0xFFF0F0F0),
                        inactiveTrackColor: const Color(0xFFF0F0F0),
                        thumbColor: const Color(0xFFFF6600),
                        overlayColor: const Color(0xFFFF6600).withAlpha(50),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
                      ),
                      child: Slider(
                        value: _quantity,
                        min: 5.0,
                        max: 100.0,
                        onChanged: (value) {
                          setState(() => _quantity = value);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.orderDetailsGallons('5'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(l10n.orderDetailsGallons('25'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(l10n.orderDetailsGallons('50'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(l10n.orderDetailsGallons('75'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(l10n.orderDetailsGallons('100'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Quick Select Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _quickSelectOptions.map((q) => _buildQuickSelectChip(q)).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Full Tank Button
                    GestureDetector(
                      onTap: () => setState(() => _isFullTank = !_isFullTank),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_gas_station,
                              size: 20,
                              color: _isFullTank ? const Color(0xFFFF6600) : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.fuelFullTank,
                              style: TextStyle(
                                color: _isFullTank ? const Color(0xFFFF6600) : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScheduleDeliveryScreen(
                    fuelType: _selectedFuelIndex == 0 ? 'Petrol' : 'Diesel',
                    quantity: _quantity.toStringAsFixed(1),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.selectLocationConfirmOrder,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuelCard({
    required int index,
    required String title,
    required String price,
    required String subtitle,
  }) {
    bool isSelected = _selectedFuelIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFuelIndex = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFFFF6600),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectChip(double val) {
    bool isCurrent = _quantity == val;
    return GestureDetector(
      onTap: () => setState(() => _quantity = val),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFF0F0F0) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${val.toInt()}Gal',
          style: TextStyle(
            color: isCurrent ? const Color(0xFF333333) : Colors.grey,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
