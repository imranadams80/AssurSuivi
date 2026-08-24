import 'package:flutter_test/flutter_test.dart';
import 'package:assursuivi/services/notification_service.dart';

void main() {
  test('NotificationService instantiates without error', () {
    final service = NotificationService();
    expect(service, isNotNull);
  });
}

