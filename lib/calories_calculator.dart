double userWeight = 90; // вес пользователя в килограммах

// Определяем MET по средней скорости
double getMET(double speed) {
  if (speed < 16) return 4.0;
  if (speed < 19) return 6.0;
  if (speed < 22) return 8.0;
  if (speed < 25) return 10.0;
  return 12.0;
}