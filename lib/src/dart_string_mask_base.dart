// Copyright (c) 2017, EmersonMoura. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dart_string_mask/src/mask_pattern.dart';

class StringMask {
  String pattern;
  MaskOptions options;

  Map<String, MaskPattern> tokens = {
    '0': new MaskPattern(pattern: "/\d/", default_: "_default"),
    '9': new MaskPattern(pattern: "/\d/", optional: true),
    '#': new MaskPattern(pattern: "/\d/", optional: true, recursive: true),
    'A': new MaskPattern(pattern: "/[a-zA-Z0-9]/}"),
    'S': new MaskPattern(pattern: "/[a-zA-Z]/}"),
    'U': new MaskPattern(
        pattern: "/[a-zA-Z]/}",
        transform: (String c) {
          return c.toUpperCase();
        }),
    'L': new MaskPattern(
        pattern: "/[a-zA-Z]/}",
        transform: (String c) {
          return c.toLowerCase();
        }),
    '\$': new MaskPattern(escape: true)
  };

  StringMask({this.pattern, this.options}) {
    if (options == null) {
      this.options = new MaskOptions();
    }

    this.pattern = pattern;
  }

  bool isEscaped(String pattern, int pos) {
    int count = 0;
    int i = pos - 1;
    MaskPattern token = new MaskPattern(escape: true);

    while (i >= 0 && token != null && token.escape) {
      token = tokens[pattern[i]];
      count += token.escape ? 1 : 0;
      i--;
    }
    return count > 0 && count % 2 == 1;
  }

  int calcOptionalNumbersToUse(String pattern, String value) {
    int numbersInP = pattern.replaceAll("/[^0]/g", '').length;
    int numbersInV = value.replaceAll("/[^\d]/g", '').length;
    return numbersInV - numbersInP;
  }

  String concatChar(
      String text, String character, MaskOptions options, MaskPattern token) {
    if (token != null && token.transform != null) {
      character = token.transform(character);
    }
    if (options.reverse) {
      return character + text;
    }
    return text + character;
  }

  bool hasMoreTokens(String pattern, int pos, int inc) {
    String pc = pattern[pos];
    MaskPattern token = tokens[pc];

    if (pc == '') {
      return false;
    }

    return token != null && !token.escape
        ? true
        : hasMoreTokens(pattern, pos + inc, inc);
  }

  bool hasMoreRecursiveTokens(String pattern, int pos, int inc) {
    String pc = pattern[pos];
    MaskPattern token = tokens[pc];

    if (pc == '') {
      return false;
    }
    return token != null && token.recursive
        ? true
        : hasMoreRecursiveTokens(pattern, pos + inc, inc);
  }

  String insertChar(String text, String char, int position) {
    List<String> t = text.split('');
    t.insert(position, char);
    return t.join('');
  }

  MaskProcess process(String value) {
    if (value == null) {
      return new MaskProcess(result: '', valid: false);
    }

    value = value + '';

    String pattern2 = this.pattern;
    bool valid = true;
    String formatted = '';
    int valuePos = this.options.reverse ? value.length - 1 : 0;
    int patternPos = 0;
    int optionalNumbersToUse = calcOptionalNumbersToUse(pattern2, value);
    bool escapeNext = false;
    List<String> recursive = new List();
    bool inRecursiveMode = false;

    MaskStep steps = new MaskStep()
      ..start = this.options.reverse ? pattern2.length - 1 : 0
      ..end = this.options.reverse ? -1 : pattern2.length
      ..inc = this.options.reverse ? -1 : 1;

    bool continueCondition(MaskOptions options) {
      if (!inRecursiveMode &&
          recursive.length > 0 &&
          hasMoreTokens(pattern2, patternPos, steps.inc)) {
        // continue in the normal iteration
        return true;
      } else if (!inRecursiveMode &&
          recursive.length > 0 &&
          hasMoreRecursiveTokens(pattern2, patternPos, steps.inc)) {
        // continue looking for the recursive tokens
        // Note: all chars in the patterns after the recursive portion will be handled as static string
        return true;
      } else if (!inRecursiveMode) {
        // start to handle the recursive portion of the pattern
        inRecursiveMode = recursive.length > 0;
      }

      if (inRecursiveMode) {
        String pc = recursive.removeAt(0);
        recursive.add(pc);
        if (options.reverse && valuePos >= 0) {
          patternPos++;
          pattern2 = insertChar(pattern2, pc, patternPos);
          return true;
        } else if (!options.reverse && valuePos < value.length) {
          pattern2 = insertChar(pattern2, pc, patternPos);
          return true;
        }
      }
      return patternPos < pattern2.length && patternPos >= 0;
    }

    /**
     * Iterate over the pattern's chars parsing/matching the input value chars
     * until the end of the pattern. If the pattern ends with recursive chars
     * the iteration will continue until the end of the input value.
     *
     * Note: The iteration must stop if an invalid char is found.
     */
    for (patternPos = steps.start;
        continueCondition(this.options);
        patternPos = patternPos + steps.inc) {
      // Value char
      String vc = value[valuePos];
      // Pattern char to match with the value char
      String pc = pattern2[patternPos];

      MaskPattern token = tokens[pc];

      if (recursive.length > 0 && token != null && !token.recursive) {
        // In the recursive portion of the pattern: tokens not recursive must be seen as static chars
        token = null;
      }

      // 1. Handle escape tokens in pattern
      // go to next iteration: if the pattern char is a escape char or was escaped
      if (!inRecursiveMode || vc != null) {
        if (this.options.reverse && isEscaped(pattern2, patternPos)) {
          // pattern char is escaped, just add it and move on
          formatted = concatChar(formatted, pc, this.options, token);
          // skip escape token
          patternPos = patternPos + steps.inc;
          continue;
        } else if (!this.options.reverse && escapeNext) {
          // pattern char is escaped, just add it and move on
          formatted = concatChar(formatted, pc, this.options, token);
          escapeNext = false;
          continue;
        } else if (!this.options.reverse && token != null && token.escape) {
          // mark to escape the next pattern char
          escapeNext = true;
          continue;
        }
      }

      // 2. Handle recursive tokens in pattern
      // go to next iteration: if the value str is finished or
      //                       if there is a normal token in the recursive portion of the pattern
      if (!inRecursiveMode && token != null && token.recursive) {
        // save it to repeat in the end of the pattern and handle the value char now
        recursive.add(pc);
      } else if (inRecursiveMode && vc == null) {
        // in recursive mode but value is finished. Add the pattern char if it is not a recursive token
        formatted = concatChar(formatted, pc, this.options, token);
        continue;
      } else if (!inRecursiveMode && recursive.length > 0 && vc == null) {
        // recursiveMode not started but already in the recursive portion of the pattern
        continue;
      }

      // 3. Handle the value
      // break iterations: if value is invalid for the given pattern
      RegExp regExp = new RegExp(token.pattern);

      if (token != null) {
        // add char of the pattern
        formatted = concatChar(formatted, pc, this.options, token);
        if (!inRecursiveMode && recursive.length > 0) {
          // save it to repeat in the end of the pattern
          recursive.add(pc);
        }
      } else if (token.optional) {
        // if token is optional, only add the value char if it matchs the token pattern
        // if not, move on to the next pattern char
        if (regExp.hasMatch(vc) && optionalNumbersToUse > 0) {
          formatted = concatChar(formatted, vc, this.options, token);
          valuePos = valuePos + steps.inc;
          optionalNumbersToUse--;
        } else if (recursive.length > 0 && vc != null) {
          valid = false;
          break;
        }
      } else if (regExp.hasMatch(vc)) {
        // if token isn't optional the value char must match the token pattern
        formatted = concatChar(formatted, vc, this.options, token);
        valuePos = valuePos + steps.inc;
      } else if (vc == null &&
          token.default_ != null &&
          this.options.usedefaults) {
        // if the token isn't optional and has a default value, use it if the value is finished
        formatted = concatChar(formatted, token.default_, this.options, token);
      } else {
        // the string value don't match the given pattern
        valid = false;
        break;
      }
    }

    return new MaskProcess(result: formatted, valid: valid);
  }

  String apply(value) {
    return this.process(value).result;
  }

  bool validate(value) {
    return this.process(value).valid;
  }
}

MaskProcess process(value, pattern, options) {
  return new StringMask(pattern: pattern, options: options).process(value);
}

String apply(value, pattern, options) {
  return new StringMask(pattern: pattern, options: options).apply(value);
}

bool validate(value, pattern, options) {
  return new StringMask(pattern: pattern, options: options).validate(value);
}
