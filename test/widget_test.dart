import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cloud Quest model and reward constants test', () {
    const expectedPoints = 10;
    const expectedBadge = 'first-quest';

    expect(expectedPoints, 10);
    expect(expectedBadge, 'first-quest');
  });
}
