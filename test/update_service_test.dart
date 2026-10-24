import 'package:flutter_test/flutter_test.dart';
import 'package:we_monitor/shared/services/update_service.dart';

void main() {
  test('compareVersions', () {
    expect(UpdateService.compareVersions('1.0.0', '1.1.0'), -1);
    expect(UpdateService.compareVersions('1.10.0', '1.9.9'), 1);
    expect(UpdateService.compareVersions('1.1', '1.1.0'), 0);
    expect(UpdateService.compareVersions('1.1.0+10', '1.1.0'), 0);
    expect(UpdateService.compareVersions('2.0.0', '1.99.99'), 1);
  });
}
