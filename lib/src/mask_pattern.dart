class MaskPattern {
  bool optional = false;
  String pattern;
  String default_;
  Function transform;
  bool recursive = false;
  bool escape = false;
  MaskPattern(
      {this.pattern,
      this.default_,
      this.optional,
      this.transform,
      this.recursive,
      this.escape});
}

class MaskOptions {
  bool reverse = false;
  bool usedefaults = false;
  MaskOptions({this.reverse});
}

class MaskProcess {
  String result;
  bool valid = false;
  MaskProcess({this.result, this.valid});
}

class MaskStep {
  int start;
  int end;
  int inc;
}
