class Readings {
  int containerLvl;
  int drainLvl;
  int temp;
  int status;
  Readings({
    required this.containerLvl,
    required this.drainLvl,
    required this.temp,
    required this.status,
  });

  @override
  String toString() {
    return 'Readings(containerLvl: $containerLvl, drainLvl: $drainLvl, temp: $temp, status: $status)';
  }
}
