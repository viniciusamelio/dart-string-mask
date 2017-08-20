// Copyright (c) 2017, EmersonMoura. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dart_string_mask/dart_string_mask.dart';
import 'package:dart_string_mask/src/mask_pattern.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {});

    test('Number', () {
      var dartStringMask = new StringMask("#0");
      expect(dartStringMask.apply("123"), "123");
    });

    test('Two decimal number with thousands separators', () {
      var maskOptions = new MaskOptions()
        ..reverse = true;

      var formatter =
      new StringMask('#.##0,00', options: maskOptions);
      var result = formatter.apply('100123456'); // 1.001.234,56
      expect(result, "1.001.234,56");
    });

    test('Phone number', () {
      var formatter = new StringMask('+00 (00) 0000-0000');
      var result = formatter.apply('553122222222');
      expect(result, "+55 (31) 2222-2222");
    });

    test('Percentage', () {
      var formatter = new StringMask('#0,00%');
      var result = formatter.apply('001'); // 0,01%
      expect(result, "0,01%");
    });

    test('Brazilian CPF number', () {
      var formatter = new StringMask('000.000.000-00');
      var result = formatter.apply('12965815620');
      expect(result, "129.658.156-20");
    });

    test('Date and time', () {
      var formatter = new StringMask('90/90/9900');
      var result = formatter.apply('1187');
      expect(result, "1/1/87");
    });

    test('Convert Case', () {
      var formatter = new StringMask('UUUUUUUUUUUUU');
      var result = formatter.apply('To Upper Case');
      expect(result, "TO UPPER CASE");
    });

    test('International Bank Number', () {
      var formatter = new StringMask('UUAA AAAA AAAA AAAA AAAA AAAA AAA');
      var result = formatter.apply('FR761111BBBB69410000AA33222');
      expect(result, "FR76 1111 BBBB 6941 0000 AA33 222");
    });

  });
}
