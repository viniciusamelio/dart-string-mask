// Copyright (c) 2017, EmersonMoura. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dart_string_mask/dart_string_mask.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    DartStringMask stringMask;

    setUp(() {
      stringMask = new DartStringMask();
    });

    test('First Test', () {
      expect(stringMask.apply("123"), isTrue);
    });
  });
}
