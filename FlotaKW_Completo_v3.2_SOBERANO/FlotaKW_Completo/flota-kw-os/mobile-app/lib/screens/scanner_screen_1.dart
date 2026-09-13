import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESCANER QR - FlotaKW OS"), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (scanned) return;
                final barcode = capture.barcodes.first;
                final value = barcode.rawValue;
                if (value != null) {
                  scanned = true;
                  // Regla: extrae MAC del QR (formato AA:BB:CC:DD:EE:FF)
                  Navigator.pop(context, value);
                }
              },
            ),
          ),
          Container(color: Colors.black, padding: const EdgeInsets.all(16), child: const Text("Apunta al QR del Beacon. El sistema extrae MAC automaticamente. Tu base de datos es tu unica fuente de verdad.", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
