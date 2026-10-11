import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/author.dart';
import 'article_service.dart';

class AuthorService {
  // GET /authors
  Future<List<Author>> getAuthors() async {
    // TODO: GET ke '${ArticleService.baseUrl}/authors'
    // Hint: daftar penulis ada di body['data'] (List) -> ubah tiap item dengan Author.fromJson
    throw UnimplementedError('getAuthors belum dibuat');
  }
}
