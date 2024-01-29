enum Command {

  turnOn([1, 1, 3, 3]),
  turnOff([1, 2, 49, 152]),
  windOff([2, 0, 56, 226]),
  wind_1([2, 1, 41, 107]),
  wind_2([2, 2, 27, 240]),
  wind_3([2, 3, 10, 121]),
  windNatural([2, 4, 126, 198]),
  lightOff([3, 0, 33, 58]),
  light_1([3, 1, 48, 179]),
  light_2([3, 2, 2, 40]),
  light_3([3, 3, 19, 161]),
  ;

  const Command(this.value);

  final List<int> value;

  List<int> get() {
    return value;
  }
}
