class WuXing {
  late int xing;

  WuXing(this.xing);

  @override
  bool operator ==(Object other) {
    if (other is WuXing) {
      return xing == other.xing;
    } else {
      return false;
    }
  }

  bool operator +(WuXing other) => xing > other.xing;

  bool operator -(WuXing other) => xing < other.xing;

  bool operator *(WuXing other) => xing == other.xing;

  bool operator /(WuXing other) => xing != other.xing;
}

void dart1() {
  var list1 = [];
  list1.add(1);
  list1.add('2');
  list1.add(true);
  print(list1);

  var map1 = {};
  map1['MU'] = 1;
  map1['HUO'] = 2;
  print(map1);
}

int? test2() {
  int? i = 0;
  double d = 0.0;
  num? d2 = d;
  print(d2);
  return i;
}
