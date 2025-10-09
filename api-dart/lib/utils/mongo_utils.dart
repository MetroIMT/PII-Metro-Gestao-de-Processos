import 'package:mongo_dart/mongo_dart.dart';

dynamic _encodeValue(dynamic value) {
  if (value is ObjectId) return value.oid;
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is Map<String, dynamic>) return encodeDocument(value);
  if (value is List) return value.map(_encodeValue).toList();
  return value;
}

Map<String, dynamic> encodeDocument(Map<String, dynamic> doc) {
  return doc.map((key, value) => MapEntry(key, _encodeValue(value)));
}
