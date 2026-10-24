import 'package:get/get.dart';

extension TrParams on String {
  /// Translates this key and replaces `{name}` tokens with [params].
  /// e.g. `'home.greeting'.trp({'name': displayName})`.
  String trp(Map<String, Object?> params) {
    var s = tr;
    params.forEach((k, v) => s = s.replaceAll('{$k}', '${v ?? ''}'));
    return s;
  }
}
