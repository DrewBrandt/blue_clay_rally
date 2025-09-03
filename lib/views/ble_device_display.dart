import 'package:blue_clay_rally/providers/ble_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_ble/universal_ble.dart';

class BleDeviceDisplay extends ConsumerWidget {
  final int i;
  final BleDevice b;
  const BleDeviceDisplay({super.key, required this.i, required this.b});

  @override
  Widget build(BuildContext context, ref) {
    return Tooltip(
      message: 'Connect',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => ref.watch(bleProvider.notifier).connect(b),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.black.withAlpha(100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${b.name}'),
                        ),
                        Align(child: Text('${b.rssi ?? 0}')),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FutureBuilder<BleConnectionState>(
                            future: b.connectionState,
                            builder: (context, snapshot) {
                              if(snapshot.hasData){
                                return Text(
                                  switch(snapshot.data){
                                    BleConnectionState.connected => 'OK',
                                    _ => 'X'
                                  }
                                );
                              }
                              return const CircularProgressIndicator();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'Option 1',
                          child: Text('Option 23'),
                        ),
                      ],
                    ),
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
