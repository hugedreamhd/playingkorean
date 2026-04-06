import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class ApiService {
  static const String _serviceKey = '983de768-8ed1-4dc0-8ce1-ad650ebe76b0';
  static const String _baseUrl = 'https://api.kcisa.kr/openapi/API_SOP_027/request';

  /// 문화데이터광장 한국어기초사전 API에서 데이터를 가져옴
  Future<List<Map<String, dynamic>>> fetchRawDictionaryData({int pageNo = 1, int numOfRows = 100}) async {
    final Uri url = Uri.parse('$_baseUrl?serviceKey=$_serviceKey&numOfRows=$numOfRows&pageNo=$pageNo');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(decodedBody);
        final items = document.findAllElements('item');

        return items.map((node) {
          return {
            'title': node.findElements('title').firstOrNull?.innerText ?? '',
            'description': node.findElements('description').firstOrNull?.innerText ?? '',
            'alternativeTitle': node.findElements('alternativeTitle').firstOrNull?.innerText ?? '',
            'uci': node.findElements('uci').firstOrNull?.innerText ?? '',
            'url': node.findElements('url').firstOrNull?.innerText ?? '',
          };
        }).toList();
      } else {
        throw Exception('Failed to load data from KCISA API: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService Error: $e');
      return [];
    }
  }
}
