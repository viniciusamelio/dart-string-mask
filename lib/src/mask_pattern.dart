class MaskPattern {
  bool optional = false;
  String pattern;
  String default_;
  Function transform;
  bool recursive = false;
  bool escape = false;

  MaskPattern({this.pattern,
    this.default_,
    this.optional = false,
    this.transform,
    this.recursive = false,
    this.escape = false});
}

class MaskOptions {
  bool reverse = false;
  bool usedefaults = false;

  MaskOptions({this.reverse, this.usedefaults});
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
