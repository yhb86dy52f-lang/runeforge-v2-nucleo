import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class EtiquetaScreen extends StatelessWidget {
  final String html;
  final String codigo;
  const EtiquetaScreen({super.key, required this.html, required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Etiqueta $codigo"), backgroundColor: Colors.black, foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.print), onPressed: () async { await Printing.layoutPdf(onLayout: (format) async => Uint8List(0)); })]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [Container(decoration: BoxDecoration(border: Border.all(width: 4)), child: Image.network("https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$codigo")), const SizedBox(height: 16), const Text("Etiqueta lista para impresion - Blanco / Marco Negro - Ontologia v3.0", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), SelectableText(html, style: const TextStyle(fontFamily: 'monospace', fontSize: 10))])),
    );
  }
}
