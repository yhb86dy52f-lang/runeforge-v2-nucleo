import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final api = ApiService();
  List<dynamic> unidades = [];
  Map<String, dynamic>? stats;
  String search = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final u = await api.listarUnidades(search: search);
      final s = await api.getStats();
      setState(() { unidades = u; stats = s; });
    } catch (e) {
      debugPrint("Error $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DASHBOARD - FlotaKW OS"), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Column(
        children: [
          if (stats != null) Container(color: Colors.black, padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [StatCard(title: "Unidades", value: stats!['total_unidades'].toString()), StatCard(title: "Beacons", value: stats!['total_beacons'].toString()), StatCard(title: "Hoy", value: stats!['instalaciones_hoy'].toString())])),
          Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v) { search = v; }, onSubmitted: (_) => load(), decoration: InputDecoration(hintText: "Buscar codigo, MAC, GPS...", prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(), suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: load)))),
          Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: unidades.length, itemBuilder: (ctx, i) {
            final u = unidades[i];
            final isR = u['codigo'].toString().endsWith("_R");
            return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: ListTile(leading: Container(width: 50, height: 50, decoration: BoxDecoration(border: Border.all(width: 2), color: isR ? Colors.orange.shade100 : Colors.green.shade100), child: Center(child: Text(u['tipo'][0], style: const TextStyle(fontWeight: FontWeight.bold)))), title: Text(u['codigo'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${u['mac']} | ${u['gps_marca_modelo']} | ${u['tecnico']}"), trailing: Text(u['fecha_instalacion'].toString().substring(0,10)), onTap: () {}));
          })),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  const StatCard({super.key, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12))]);
  }
}
