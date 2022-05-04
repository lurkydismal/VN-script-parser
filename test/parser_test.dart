import 'package:parser/parser.dart';
import 'package:test/test.dart';

void main() {
  test("calculate", () {
    expect(stringIsBase64("notBase64"), false);
  });
}
