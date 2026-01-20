/// Domain entity representing a Range Session
/// This represents testing a specific Load Recipe with a specific Firearm
class RangeSession {
  final String id;
  final DateTime date;
  final String firearmId; // Foreign key to Firearm
  final String loadRecipeId; // Foreign key to LoadRecipe
  final String? weather; // Single text field for weather notes (optional)
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RangeSession({
    required this.id,
    required this.date,
    required this.firearmId,
    required this.loadRecipeId,
    this.weather,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this RangeSession with the given fields replaced
  RangeSession copyWith({
    String? id,
    DateTime? date,
    String? firearmId,
    String? loadRecipeId,
    String? weather,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RangeSession(
      id: id ?? this.id,
      date: date ?? this.date,
      firearmId: firearmId ?? this.firearmId,
      loadRecipeId: loadRecipeId ?? this.loadRecipeId,
      weather: weather ?? this.weather,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RangeSession(id: $id, date: $date, firearmId: $firearmId, loadRecipeId: $loadRecipeId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RangeSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
