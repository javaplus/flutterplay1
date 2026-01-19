/// Domain entity representing a Firearm
/// This is the core business object, independent of any framework or database
class Firearm {
  final String id;
  final String name; // Nickname or friendly name for display
  final String make;
  final String model;
  final String caliber;
  final double barrelLength; // In inches
  final String barrelTwistRate; // Free text, e.g., "1:10"
  final int roundCount;
  final String? opticInfo; // Single text field for optic details
  final String? notes;
  final String? photoPath; // Path to local photo file
  final DateTime createdAt;
  final DateTime updatedAt;

  Firearm({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.caliber,
    required this.barrelLength,
    required this.barrelTwistRate,
    this.roundCount = 0,
    this.opticInfo,
    this.notes,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this Firearm with the given fields replaced
  Firearm copyWith({
    String? id,
    String? name,
    String? make,
    String? model,
    String? caliber,
    double? barrelLength,
    String? barrelTwistRate,
    int? roundCount,
    String? opticInfo,
    String? notes,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Firearm(
      id: id ?? this.id,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      caliber: caliber ?? this.caliber,
      barrelLength: barrelLength ?? this.barrelLength,
      barrelTwistRate: barrelTwistRate ?? this.barrelTwistRate,
      roundCount: roundCount ?? this.roundCount,
      opticInfo: opticInfo ?? this.opticInfo,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Firearm(id: $id, name: $name, make: $make, model: $model, caliber: $caliber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Firearm && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
