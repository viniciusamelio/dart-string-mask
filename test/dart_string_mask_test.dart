// Copyright (c) 2017, EmersonMoura. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dart_string_mask/dart_string_mask.dart';
import 'package:dart_string_mask/src/mask_pattern.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {});

    test('Number', () {
      var dartStringMask = new StringMask(pattern: "#0");
      expect(dartStringMask.apply("123"), "123");
    });

    test('Two decimal number with thousands separators', () {
      var maskOptions = new MaskOptions()..reverse = true;

      var formatter =
          new StringMask(pattern: '#.##0,00', options: maskOptions);
      var result = formatter.apply('100123456'); // 1.001.234,56
      expect(result, "1.001.234,56");
    });
  });
}
