#!/usr/bin/env python3
"""
Patches assigned_orders_screen.dart:
  - Replaces the small orange ACCEPT button inside _buildOrderCard
    with a full-width green Accept Order button + spinner.
Run from the project root:
    python patch_accept_btn.py
"""
import re, sys, pathlib

TARGET = pathlib.Path(
    r"lib/screens/order/assigned_orders_screen.dart"
)

src = TARGET.read_text(encoding="utf-8")

# ── 1. Find the fuel-row + old button block ───────────────────────────────
# We look for the divider section up to the closing of _buildOrderCard
OLD_MARKER_START = "                  const SizedBox(height: 16),\n                  const Divider(height: 1, color: Color(0xFFF2F2F2)),"
OLD_MARKER_END   = "    );\n  }\n}"   # end of _buildOrderCard and class

if OLD_MARKER_START not in src:
    print("ERROR: Could not find start marker. File may have changed.")
    sys.exit(1)

start_idx = src.index(OLD_MARKER_START)
end_idx   = src.index(OLD_MARKER_END, start_idx) + len(OLD_MARKER_END)

NEW_BLOCK = '''                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF2F2F2)),
                  const SizedBox(height: 16),
                  // ── Fuel type row ──────────────────────────────────
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
                      // Inline button for non-available orders
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

                  // ── Green Accept Order button (available orders only) ─
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
                                    'Accepting\u2026',
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
'''

patched = src[:start_idx] + NEW_BLOCK
TARGET.write_text(patched, encoding="utf-8")
print(f"Done. Written {len(patched)} bytes to {TARGET}")
