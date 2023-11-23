// Copyright (c) 2017, EmersonMoura. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:string_mask/src/mask_pattern.dart';

export "./mask_pattern.dart";

class StringMask {
  String pattern;
  MaskOptions? options;

  Map<String, MaskPattern> tokens = {
    '0': new MaskPattern(pattern: "\\d", default_: "0"),
    '9': new MaskPattern(pattern: "\\d", optional: true),
    '#': new MaskPattern(pattern: "\\d", optional: true, recursive: true),
    'A': new MaskPattern(pattern: "[a-zA-Z0-9 ]"),
    'S': new MaskPattern(pattern: "[a-zA-Z ]"),
    'U': new MaskPattern(
        pattern: "[a-zA-Z ]",
        transform: (String c) {
          return c.toUpperCase();
        }),
    'L': new MaskPattern(
        pattern: "[a-zA-Z ]",
        transform: (String c) {
          return c.toLowerCase();
        }),
    '\$': new MaskPattern(escape: true)
  };

  StringMask(this.pattern, {this.options}) {
    if (options == null) {
      this.options = new MaskOptions();
    }

    if (this.options?.reverse == null) {
      this.options?.reverse = false;
    }

    if (this.options?.usedefaults == null) {
      this.options?.usedefaults = this.options?.reverse;
    }

    this.pattern = pattern;
  }

  bool isEscaped(String pattern, int pos) {
    int count = 0;
    int i = pos - 1;
    MaskPattern? token = new MaskPattern(escape: true);

    while (i >= 0 && token != null && token.escape) {
      var key = pattern[i];
      token = tokens[key];
      count += (token != null && token.escape) ? 1 : 0;
      i--;
    }
    return count > 0 && count % 2 == 1;
  }

  int calcOptionalNumbersToUse(String pattern, String value) {
    int numbersInP = pattern
        .replaceAll(new RegExp("[^0]"), '')
        .length;
    int numbersInV = value
        .replaceAll(new RegExp("[^\\d]"), '')
        .length;
    return numbersInV - numbersInP;
  }

  String concatChar(String text, String character, MaskOptions? options,
      MaskPattern? token) {
    if (token != null && token.transform != null) {
      character = token.transform?.call(character);
    }
    if (options?.reverse == true) {
      return character + text;
    }
    return text + character;
  }

  bool hasMoreTokens(String pattern, int pos, int inc) {
    String? pc;

    if (pattern.length > pos && pos >= 0) {
      pc = pattern[pos];
    }

    MaskPattern? token = tokens[pc];

    if (pc == null) {
      return false;
    }

    return token != null && !token.escape
        ? true
        : hasMoreTokens(pattern, pos + inc, inc);
  }

  bool hasMoreRecursiveTokens(String pattern, int pos, int inc) {
    String? pc;

    if (pattern.length > pos && pos >= 0) {
      pc = pattern[pos];
    }

    MaskPattern? token = tokens[pc];

    if (pc == null) {
      return false;
    }

    return token != null && token.recursive
        ? true
        : hasMoreRecursiveTokens(pattern, pos + inc, inc);
  }

  String insertChar(String text, String char, int position) {
    List<String> t = [];
    t.addAll(text.split(''));

    t.insert(position, char);

    return t.join('');
  }

  MaskProcess process(String? value) {
    if (value == null) {
      return new MaskProcess(result: '', valid: false);
    }

    value = value + '';

    String pattern2 = this.pattern;
    bool valid = true;
    String formatted = '';
    int valuePos = this.options?.reverse == true ? value.length - 1 : 0;
    int patternPos = 0;
    int optionalNumbersToUse = calcOptionalNumbersToUse(pattern2, value);
    bool escapeNext = false;
    List<String> recursive = [];
    bool inRecursiveMode = false;

    MaskStep steps = new MaskStep()
      ..start = this.options?.reverse == true ? pattern2.length - 1 : 0
      ..end = this.options?.reverse == true ? -1 : pattern2.length
      ..inc = this.options?.reverse == true ? -1 : 1;

    bool continueCondition(MaskOptions? options) {
      if (!inRecursiveMode &&
          recursive.length == 0 &&
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
        if (options?.reverse == true && valuePos >= 0) {
          patternPos++;
          pattern2 = insertChar(pattern2, pc, patternPos);
          return true;
        } else if (!(options?.reverse == true) && value != null && valuePos < value.length) {
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
      String? vc;

      if (value.length > valuePos && valuePos >= 0) {
        vc = value[valuePos];
      }
      // Pattern char to match with the value char
      String? pc;

      if (pattern2.length > patternPos && patternPos >= 0) {
        pc = pattern2[patternPos];
      }

      MaskPattern? token = tokens[pc];

      if (recursive.length > 0 && token != null && !token.recursive) {
        // In the recursive portion of the pattern: tokens not recursive must be seen as static chars
        token = null;
      }

      // 1. Handle escape tokens in pattern
      // go to next iteration: if the pattern char is a escape char or was escaped
      if (!inRecursiveMode || vc != null) {
        if (this.options?.reverse == true && isEscaped(pattern2, patternPos) && pc != null) {
          // pattern char is escaped, just add it and move on
          formatted = concatChar(formatted, pc, this.options, token);
          // skip escape token
          patternPos = patternPos + steps.inc;
          continue;
        } else if (this.options?.reverse == false && escapeNext && pc != null) {
          // pattern char is escaped, just add it and move on
          formatted = concatChar(formatted, pc, this.options, token);
          escapeNext = false;
          continue;
        } else if (this.options?.reverse == true && token != null && token.escape) {
          // mark to escape the next pattern char
          escapeNext = true;
          continue;
        }
      }

      // 2. Handle recursive tokens in pattern
      // go to next iteration: if the value str is finished or
      //                       if there is a normal token in the recursive portion of the pattern
      if (!inRecursiveMode && token != null && token.recursive && pc != null) {
        // save it to repeat in the end of the pattern and handle the value char now
        recursive.add(pc);
      } else if (inRecursiveMode && vc == null && pc != null) {
        // in recursive mode but value is finished. Add the pattern char if it is not a recursive token
        formatted = concatChar(formatted, pc, this.options, token);
        continue;
      } else if (!inRecursiveMode && recursive.length > 0 && vc == null) {
        // recursiveMode not started but already in the recursive portion of the pattern
        continue;
      }

      final pattern = token?.pattern;
      final tokenDefault = token?.default_;

      // 3. Handle the value
      // break iterations: if value is invalid for the given pattern
      if (token == null && pc != null) {
        // add char of the pattern
        formatted = concatChar(formatted, pc, this.options, token);
        if (!inRecursiveMode && recursive.length > 0) {
          // save it to repeat in the end of the pattern
          recursive.add(pc);
        }
      } else if (token?.optional == true) {
        // if token is optional, only add the value char if it matchs the token pattern
        // if not, move on to the next pattern char

        if (vc != null && pattern != null && new RegExp(pattern).hasMatch(vc) &&
            optionalNumbersToUse > 0) {
          formatted = concatChar(formatted, vc, this.options, token);
          valuePos = valuePos + steps.inc;
          optionalNumbersToUse--;
        } else if (recursive.length > 0 && vc != null) {
          valid = false;
          break;
        }
      } else if (vc != null && pattern != null && new RegExp(pattern).hasMatch(vc)) {
        // if token isn't optional the value char must match the token pattern
        formatted = concatChar(formatted, vc, this.options, token);
        valuePos = valuePos + steps.inc;
      } else if (vc == null &&
          tokenDefault != null &&
          this.options?.usedefaults == true) {
        
        // if the token isn't optional and has a default value, use it if the value is finished
        formatted = concatChar(formatted, tokenDefault, this.options, token);
      } else {
        // the string value don't match the given pattern
        valid = false;
        break;
      }
    }

    return new MaskProcess(result: formatted, valid: valid);
  }

  String apply(value) {
    return this
        .process(value)
        .result;
  }

  bool validate(value) {
    return this
        .process(value)
        .valid;
  }

  static MaskProcess process_(value, pattern, options) {
    return new StringMask(pattern, options: options).process(value);
  }

  static String apply_(value, pattern, options) {
    return new StringMask(pattern, options: options).apply(value);
  }

  static bool validate_(value, pattern, options) {
    return new StringMask(pattern, options: options).validate(value);
  }
}
