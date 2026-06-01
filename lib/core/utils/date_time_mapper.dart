DateTime? parseDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? dateToJson(DateTime? value) => value?.toIso8601String();
