import "package:parser/parser.dart";
import "package:test/test.dart";

void main() {
  group("stringIsBase64", () {
    test("String \"notBase64\"", () {
      expect(stringIsBase64("notBase64"), false);
    });

    test("Base64 encoded string \"test\" - \"dGVzdA==\"", () {
      expect(stringIsBase64("dGVzdA=="), true);
    });

    test("Invalid base64 encoded string \"dGVzdA=\"", () {
      expect(stringIsBase64("dGVzdA="), false);
    });
  });

  group("fileToBase64", () {
    test("\"example.script\" to base64", () {
      expect(stringIsBase64(fileToBase64("./example/example.script")), true);
    });
  });

  group("isAlphaOrUnderscore", () {
    test("String \"A\"", () {
      expect(isAlphaOrUnderscore("A"), true);
    });

    test("String \"ABC\"", () {
      expect(isAlphaOrUnderscore("ABC"), true);
    });

    test("String \"a\"", () {
      expect(isAlphaOrUnderscore("a"), true);
    });

    test("String \"abc\"", () {
      expect(isAlphaOrUnderscore("abc"), true);
    });

    test("String \"_A\"", () {
      expect(isAlphaOrUnderscore("_A"), true);
    });

    test("String \"_AbC_\"", () {
      expect(isAlphaOrUnderscore("_AbC"), true);
    });

    test("String \"_123\"", () {
      expect(isAlphaOrUnderscore("_123"), false);
    });

    test("String \"a1b2c3\"", () {
      expect(isAlphaOrUnderscore("a1b2c3"), false);
    });

    test("String \"_a1b2c3_\"", () {
      expect(isAlphaOrUnderscore("_a1b2c3_"), false);
    });

    test("String \"1\"", () {
      expect(isAlphaOrUnderscore("1"), false);
    });

    test("String \"123\"", () {
      expect(isAlphaOrUnderscore("123"), false);
    });
  });

  group("toBool", () {
    test("null", () {
      expect(toBool(null), false);
    });

    test("Empty string", () {
      expect(toBool(""), false);
    });

    test("String \"true\"", () {
      expect(toBool("true"), true);
    });

    test("String \"false\"", () {
      expect(toBool("false"), false);
    });

    test("String \"test\"", () {
      expect(toBool("test"), true);
    });

    test("Number 0", () {
      expect(toBool(0), false);
    });

    test("Number 0.5", () {
      expect(toBool(0.5), true);
    });

    test("Number 1", () {
      expect(toBool(1), true);
    });

    test("Empty List", () {
      expect(toBool([]), false);
    });

    test("List [1]", () {
      expect(toBool([1]), true);
    });

    test("List [1, 2]", () {
      expect(toBool([1, 2]), true);
    });

    test("Empty Map", () {
      expect(toBool({}), false);
    });

    test("Map { 1 : 1 }", () {
      expect(toBool({1: 1}), true);
    });

    test("Map { 1 : 1, 2 : 2 }", () {
      expect(toBool({1: 1, 2: 2}), true);
    });

    test("Map { \"1\" : \"1\" }", () {
      expect(toBool({"1": "1"}), true);
    });

    test("Map { \"1\" : \"1\", \"2\" : \"2\" }", () {
      expect(toBool({"1": "1", "2": "2"}), true);
    });
  });
}
