import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/author.dart';
import 'article_service.dart';

class AuthorService {
  // GET /authors
  Future<List<Author>> getAuthors() async {
    final response = await http.get(Uri.parse('${ArticleService.baseUrl}/authors'));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) throw Exception(body['message']);

    final List data = body['data'];
    return data.map((json) => Author.fromJson(json)).toList();
  }
}
