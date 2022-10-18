class Readings {
  double? tempTL;
  double? tempTR;
  double? tempBL;
  double? tempBR;
  double? tempBaby;
  double? humidity;
  double? humidityRef;
  double? tempRef;
  int? mode;
  Readings({
    this.tempTL = 0,
    this.tempTR = 0,
    this.tempBL = 0,
    this.tempBR = 0,
    this.tempBaby = 0,
    this.humidity = 0,
    this.humidityRef = 50,
    this.tempRef = 37,
    this.mode = 3,
  });

  @override
  String toString() {
    return 'Readings(tempTL: $tempTL, tempTR: $tempTR, tempBL: $tempBL, tempBR: $tempBR, tempBaby: $tempBaby, humidity: $humidity, humidityRef: $humidityRef, tempRef: $tempRef, mode: $mode)';
  }
}
