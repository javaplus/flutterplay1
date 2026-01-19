/// Domain entity representing a Range Session
/// This represents testing a specific Load Recipe with a specific Firearm
class RangeSession {
  final String id;
  final DateTime date;
  final String location;
  final String firearmId; // Foreign key to Firearm
  final String loadRecipeId; // Foreign key to LoadRecipe
  final int roundsFired;
  final String weather; // Single text field for weather notes
  final double? avgVelocity; // Average velocity in fps (nullable)
  final double? standardDeviation; // SD in fps (nullable)
  final double? extremeSpread; // ES in fps (nullable)
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RangeSession({
    required this.id,
    required this.date,
    required this.location,
    required this.firearmId,
    required this.loadRecipeId,
    required this.roundsFired,
    required this.weather,
    this.avgVelocity,
    this.standardDeviation,
    this.extremeSpread,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this RangeSession with the given fields replaced
  RangeSession copyWith({
    String? id,
    DateTime? date,
    String? location,
    String? firearmId,
    String? loadRecipeId,
    int? roundsFired,
    String? weather,
    double? avgVelocity,
    double? standardDeviation,
    double? extremeSpread,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RangeSession(
      id: id ?? this.id,
      date: date ?? this.date,
      location: location ?? this.location,
      firearmId: firearmId ?? this.firearmId,
      loadRecipeId: loadRecipeId ?? this.loadRecipeId,
      roundsFired: roundsFired ?? this.roundsFired,
      weather: weather ?? this.weather,
      avgVelocity: avgVelocity ?? this.avgVelocity,
      standardDeviation: standardDeviation ?? this.standardDeviation,
      extremeSpread: extremeSpread ?? this.extremeSpread,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RangeSession(id: $id, date: $date, location: $location, firearmId: $firearmId, loadRecipeId: $loadRecipeId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RangeSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
