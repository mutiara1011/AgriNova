import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commodity.dart';

class CommodityService {
  static const String baseUrl = 'https://agrinova.devlabfortirta.cloud/api/v1';

  Future<List<Commodity>> getAllCommodities() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/commodities'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['data'] ?? []) as List;
        return list.map((e) => Commodity.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getAllCommodities: $e');
    }
    return [];
  }

  Future<Commodity?> createCommodity(Commodity commodity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/commodities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(commodity.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return Commodity.fromJson(json['data']);
      }
    } catch (e) {
      print('Error createCommodity: $e');
    }
    return null;
  }
}
