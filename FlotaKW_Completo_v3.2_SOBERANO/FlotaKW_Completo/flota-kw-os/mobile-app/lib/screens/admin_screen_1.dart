import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final api = ApiService();
  List<dynamic> tecnicos = [];
  List<dynamic> auditoria = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final t = await api.getTecnicos();
      setState(() => tecnicos = t);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ADMIN - Ontologia"), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Panel de Administracion", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Cada accion queda registrada como evento inmutable. La confianza se construye con trazabilidad."),
          const SizedBox(height: 16),
          const Text("Tecnicos Activos:", style: TextStyle(fontWeight: FontWeight.bold)),
          ...tecnicos.map((t) => ListTile(leading: const Icon(Icons.person), title: Text(t['nombre']), trailing: Icon(t['activo'] ? Icons.check_circle : Icons.cancel, color: t['activo'] ? Colors.green : Colors.red))),
          const Divider(),
          const Text("Principios:", style: TextStyle(fontWeight: FontWeight.bold)),
          const ListTile(title: Text("1. Ontologia sobre tablas"), subtitle: Text("Unidades, Beacons, Instalaciones son objetos del mundo real")),
          const ListTile(title: Text("2. Decisiones en el borde"), subtitle: Text("El tecnico en campo decide correcto en momento correcto")),
          const ListTile(title: Text("3. Codigo como ventaja competitiva"), subtitle: Text("Cada funcionalidad es propiedad intelectual")),
          const ListTile(title: Text("4. Auditoria y linaje"), subtitle: Text("Trace_id en cada peticion, evento inmutable")),
        ],
      ),
    );
  }
}
