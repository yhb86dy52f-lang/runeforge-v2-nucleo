import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'scanner_screen.dart';
import 'etiqueta_screen.dart';

class AltaScreen extends StatefulWidget {
  const AltaScreen({super.key});
  @override
  State<AltaScreen> createState() => _AltaScreenState();
}

class _AltaScreenState extends State<AltaScreen> {
  final _codigoCtrl = TextEditingController();
  final _macCtrl = TextEditingController();
  final _gpsCtrl = TextEditingController();
  final _tecnicoCtrl = TextEditingController();
  bool isR = false;
  bool loading = false;
  final api = ApiService();

  void checkIsR() {
    setState(() {
      isR = _codigoCtrl.text.toUpperCase().endsWith("_R");
    });
  }

  Future<void> scanMac() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (result != null) {
      setState(() => _macCtrl.text = result.toString().toUpperCase());
    }
  }

  Future<void> submit() async {
    if (_codigoCtrl.text.isEmpty || _macCtrl.text.isEmpty || _tecnicoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos obligatorios")));
      return;
    }
    if (isR && _gpsCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Codigo _R requiere GPS Marca Modelo")));
      return;
    }
    setState(() => loading = true);
    try {
      final res = await api.altaUnidad(codigo: _codigoCtrl.text, mac: _macCtrl.text, tecnico: _tecnicoCtrl.text, gpsMarcaModelo: isR ? _gpsCtrl.text : null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alta exitosa: ${res['unidad']['codigo']} | TRACE ${res['trace_id']}")));
      Navigator.push(context, MaterialPageRoute(builder: (_) => EtiquetaScreen(html: res['etiqueta_html'], codigo: res['unidad']['codigo'])));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ALTA ATOMICA - FlotaKW OS"), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Cada linea de codigo es una decision que protege tu ventaja competitiva.", style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            TextField(controller: _codigoCtrl, onChanged: (_) => checkIsR(), decoration: InputDecoration(labelText: "Codigo Unidad (ej KW-1234 o KW-1234_R)", border: const OutlineInputBorder(), suffixIcon: Icon(isR ? Icons.warning : Icons.check, color: isR ? Colors.orange : Colors.green))),
            if (isR) Container(margin: const EdgeInsets.only(top:8), padding: const EdgeInsets.all(8), color: Colors.orange.shade100, child: const Text("Detectado _R: GPS Variable obligatorio. Sin _R = CALAMP automatico.", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            TextField(controller: _macCtrl, decoration: InputDecoration(labelText: "MAC Beacon (AA:BB:CC:DD:EE:FF)", border: const OutlineInputBorder(), suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: scanMac))),
            const SizedBox(height: 16),
            if (isR) TextField(controller: _gpsCtrl, decoration: const InputDecoration(labelText: "GPS Marca Modelo (obligatorio _R)", hintText: "Ej: TELTONIKA FMB920, QUECLINK GV300", border: OutlineInputBorder())),
            if (isR) const SizedBox(height: 16),
            TextField(controller: _tecnicoCtrl, decoration: const InputDecoration(labelText: "Tecnico", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: loading ? null : submit, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("EJECUTAR ALTA ATOMICA")),
            const SizedBox(height: 12),
            const Text("Validacion en backend, nunca en frontend. Transaccion atomica. Si falla un INSERT, todo se revierte.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
