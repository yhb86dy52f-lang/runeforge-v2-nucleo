import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://localhost:8000/api/v1";

  Future<Map<String, dynamic>> altaUnidad({required String codigo, required String mac, required String tecnico, String? gpsMarcaModelo}) async {
    final url = Uri.parse("$baseUrl/alta");
    final body = {"codigo": codigo, "mac": mac, "tecnico": tecnico, if (gpsMarcaModelo != null) "gps_marca_modelo": gpsMarcaModelo};
    final res = await http.post(url, headers: {"Content-Type": "application/json", "X-Trace-Id": DateTime.now().millisecondsSinceEpoch.toString()}, body: jsonEncode(body));
    if (res.statusCode == 200 || res.statusCode == 201) return jsonDecode(res.body);
    throw Exception("Error ${res.statusCode}: ${res.body}");
  }

  Future<List<dynamic>> listarUnidades({String? search, int page=1, int limit=20}) async {
    final url = Uri.parse("$baseUrl/unidades?search=${search ?? ''}&page=$page&limit=$limit");
    final res = await http.get(url);
    if (res.statusCode == 200) return jsonDecode(res.body)['items'];
    throw Exception("Error listando");
  }

  Future<String> getEtiquetaHtml(String codigo) async {
    final url = Uri.parse("$baseUrl/etiqueta/$codigo");
    final res = await http.get(url);
    if (res.statusCode == 200) return res.body;
    throw Exception("No encontrada");
  }

  Future<List<dynamic>> getTecnicos() async {
    final url = Uri.parse("$baseUrl/tecnicos");
    final res = await http.get(url);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Error tecnicos");
  }

  Future<Map<String, dynamic>> getStats() async {
    final url = Uri.parse("$baseUrl/stats");
    final res = await http.get(url);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Error stats");
  }
}
