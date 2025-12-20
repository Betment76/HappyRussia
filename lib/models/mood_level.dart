/// Уровень настроения (1-5)
enum MoodLevel {
  verySad(1, '😢', 'Очень грустно'),
  sad(2, '😔', 'Грустно'),
  neutral(3, '😐', 'Нейтрально'),
  happy(4, '😊', 'Хорошо'),
  veryHappy(5, '😄', 'Прекрасно');

  final int value;
  final String emoji;
  final String label;

  const MoodLevel(this.value, this.emoji, this.label);
}

