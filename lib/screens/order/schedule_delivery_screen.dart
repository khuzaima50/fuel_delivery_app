import 'package:flutter/material.dart';
import 'payment_details_screen.dart';

class ScheduleDeliveryScreen extends StatefulWidget {
  final String vehicleName;
  final String locationName;
  final String fuelType;
  final String quantity;

  const ScheduleDeliveryScreen({
    super.key,
    this.vehicleName = 'Tesla Model 3',
    this.locationName = 'Home (123 Main St)',
    this.fuelType = 'Petrol',
    this.quantity = '45.0',
  });

  @override
  State<ScheduleDeliveryScreen> createState() => _ScheduleDeliveryScreenState();
}

class _ScheduleDeliveryScreenState extends State<ScheduleDeliveryScreen> {
  int _selectedTimeIndex = -1;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '8:00 AM -\n10:00 AM', 'available': true},
    {'time': '10:00 AM -\n12:00 PM', 'available': true},
    {'time': '12:00 PM -\n2:00 PM', 'available': true},
    {'time': '2:00 PM -\n4:00 PM', 'available': false},
    {'time': '4:00 PM -\n6:00 PM', 'available': true},
    {'time': '6:00 PM -\n8:00 PM', 'available': true},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6600),
              onPrimary: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayName = days[date.weekday - 1];
    String monthName = months[date.month - 1];
    String day = date.day.toString().padLeft(2, '0');
    return '$dayName $monthName $day, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    bool isContinueEnabled = _selectedTimeIndex != -1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            ),
          ),
        ),
        title: const Text(
          'Schedule',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Schedule Delivery',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your preferred date and time',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              // Select Date Label
              Row(
                children: const [
                  Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF333333)),
                  SizedBox(width: 8),
                  Text(
                    'Select Date',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Date Button
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFFF6600), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Select Time Label
              Row(
                children: const [
                  Icon(Icons.access_time_outlined, size: 20, color: Color(0xFF333333)),
                  SizedBox(width: 8),
                  Text(
                    'Select Time Window',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Time Window Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timeSlots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];
                  bool isSelected = _selectedTimeIndex == index;
                  bool isAvailable = slot['available'];

                  return GestureDetector(
                    onTap: isAvailable ? () => setState(() => _selectedTimeIndex = index) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.white : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected && isAvailable ? const Color(0xFFFF6600) : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: isAvailable
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(isSelected ? 6 : 4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot['time'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                              color: isAvailable ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                            ),
                          ),
                          if (!isAvailable) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Unavailable',
                              style: TextStyle(fontSize: 10, color: Color(0xFFCCCCCC)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Delivery Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F4).withAlpha(100),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Vehicle', widget.vehicleName),
                    _buildDetailRow('Location', widget.locationName),
                    _buildDetailRow('Fuel Type', widget.fuelType),
                    _buildDetailRow('Quantity', '${widget.quantity} gallons'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Flexible Scheduling Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCE5FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.alarm, color: Color(0xFFFF5252), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Flexible Scheduling',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You can reschedule your delivery up to 2 hours before the scheduled time.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isContinueEnabled
                ? () {
                    final slot = _timeSlots[_selectedTimeIndex];
                    final timeStr = slot['time'].split(' - ')[0].replaceAll('\n', ' ');
                    // Simple parsing for "8:00 AM" etc
                    final parts = timeStr.split(' ');
                    final timeParts = parts[0].split(':');
                    int hour = int.parse(timeParts[0]);
                    final int minute = int.parse(timeParts[1]);
                    if (parts[1] == 'PM' && hour < 12) hour += 12;
                    if (parts[1] == 'AM' && hour == 12) hour = 0;

                    final scheduledDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      hour,
                      minute,
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PaymentDetailsScreen(
                          scheduledDateTime: scheduledDateTime,
                        ),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isContinueEnabled ? const Color(0xFFFF6600) : const Color(0xFFEBEBEB),
              foregroundColor: isContinueEnabled ? Colors.white : const Color(0xFFAAAAAA),
              disabledBackgroundColor: const Color(0xFFEBEBEB),
              disabledForegroundColor: const Color(0xFFAAAAAA),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Review Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18, color: isContinueEnabled ? Colors.white : const Color(0xFFAAAAAA)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }
}
