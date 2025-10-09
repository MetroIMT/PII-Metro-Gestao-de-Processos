import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(int statusCode, Object? data) {
  return Response(
    statusCode,
    body: jsonEncode(
      data,
      toEncodable: (value) {
        if (value is DateTime) return value.toUtc().toIso8601String();
        return value;
      },
    ),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}