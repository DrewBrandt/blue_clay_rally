import 'package:blue_clay_rally/providers/ble_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_ble/universal_ble.dart';

class BleDeviceDisplay extends ConsumerWidget {
  final int i;
  final BleDevice b;
  const BleDeviceDisplay({super.key, required this.i, required this.b});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // <-- WidgetRef
    final ble = ref.read(bleProvider.notifier); 
    print('build');      // grab once
    return Tooltip(
      message: 'Connect',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => ble.connect(b),               // <-- use read in callbacks
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color: Colors.black.withAlpha(100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        const Align(alignment: Alignment.centerLeft),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(b.name ?? '(unnamed)'),
                        ),
                        const Align(),
                        Align(
                          alignment: Alignment.center,
                          child: Text('${b.rssi ?? 0}'),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FutureBuilder<BleConnectionState>(
                            future: b.connectionState,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              }
                              if (snap.hasError) {
                                return const Text('X');
                              }
                              final st = snap.data;
                              return Text(
                                st == BleConnectionState.connected ? 'OK' : 'X',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'Option 1',
                        child: Text('Option 23'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
