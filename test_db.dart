import 'dart:convert';
import 'dart:io';

void main() async {
  final url = 'https://itxcfeebqcwxdigvuqkx.supabase.co/rest/v1/rooms?select=*,facilities!facility_id(name)&limit=1';
  
  final request = await HttpClient().getUrl(Uri.parse(url));
  request.headers.add('apikey', 'sb_publishable_ykbUlibkYJN_RNQYKpeA9Q_H6XvG0Nb');
  request.headers.add('Authorization', 'Bearer sb_publishable_ykbUlibkYJN_RNQYKpeA9Q_H6XvG0Nb');
  
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print('Response body: $responseBody');
}
