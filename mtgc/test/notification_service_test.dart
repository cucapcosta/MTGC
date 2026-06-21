import 'package:flutter_test/flutter_test.dart';
import 'package:mtgc/services/notification_service.dart';

void main() {
  test('reminderPlan has two reminders at 5 and 10 minutes', () {
    final plan = reminderPlan();
    expect(plan.length, 2);

    expect(plan[0].id, 0);
    expect(plan[0].delay, const Duration(minutes: 5));
    expect(plan[0].title, 'MTG Collector');
    expect(plan[0].body, 'Seus boosters esperam! 🎴');

    expect(plan[1].id, 1);
    expect(plan[1].delay, const Duration(minutes: 10));
    expect(plan[1].title, 'MTG Collector');
    expect(plan[1].body, 'Hora de abrir mais um pacote!');
  });
}
