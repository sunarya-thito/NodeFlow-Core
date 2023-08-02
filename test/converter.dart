import 'dart:convert';
import 'dart:io';

main() {
  File file = File('lib/l10n/data.json');
  String content = file.readAsStringSync();
  Map<String, dynamic> json = jsonDecode(content);
  // we need to replace keys because we cannot accept key with dot "."
  // we need to replace it with capital letter of the next word
  // for example: "nodeflow.settings.key" -> "nodeflowSettingsKey"
  Map<String, dynamic> newJson = {};
  json.forEach((key, value) {
    String newKey = key.replaceAll('.', ' ').split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join();
    // replace the first letter to lowercase
    newKey = newKey[0].toLowerCase() + newKey.substring(1);
    newJson[newKey] = value;
  });
  // with prettier
  String newContent = JsonEncoder.withIndent('  ').convert(newJson);
  file = File('lib/l10n/app_en.arb');
  file.writeAsStringSync(newContent);
}
