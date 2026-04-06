import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/data/quizzes.json');
  final jsonString = await file.readAsString();
  final List<dynamic> jsonList = json.decode(jsonString);

  final diff1 = jsonList.where((j) => j['difficulty'] == '1').take(5).toList();
  final diff2 = jsonList.where((j) => j['difficulty'] == '2').take(5).toList();
  final diff3 = jsonList.where((j) => j['difficulty'] == '3').take(5).toList();
  
  print('--- Difficulty 1 ---');
  for (var q in diff1) print(q['options'][0] + ' : ' + (q['englishMeanings'] as List).isNotEmpty ? q['englishMeanings'][0] : '');

  print('--- Difficulty 2 ---');
  for (var q in diff2) print(q['options'][0] + ' : ' + (q['englishMeanings'] as List).isNotEmpty ? q['englishMeanings'][0] : '');

  print('--- Difficulty 3 ---');
  for (var q in diff3) print(q['options'][0] + ' : ' + (q['englishMeanings'] as List).isNotEmpty ? q['englishMeanings'][0] : '');
}
