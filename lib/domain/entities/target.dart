/// Domain entity representing a Target
/// This represents an individual target shot during a Range Session
class Target {
  final String id;
  final String rangeSessionId; // Foreign key to RangeSession
  final String? photoPath; // Path to target photo
  final double distance; // Distance to target (yards or meters)
  final int numberOfShots; // Number of shots in the group
  final double? groupSizeInches; // Manual entry - group size in inches
  final double? groupSizeMoa; // Manual entry or calculated - group size in MOA
  final double?
  avgVelocity; // Average velocity in fps (calculated from shot velocities)
  final double?
  standardDeviation; // SD in fps (calculated from shot velocities)
  final double? extremeSpread; // ES in fps (calculated from shot velocities)
  final String? notes; // Shooter notes (e.g., "pulled shot #3")
  final DateTime createdAt;
  final DateTime updatedAt;

  Target({
    required this.id,
    required this.rangeSessionId,
    this.photoPath,
    required this.distance,
    required this.numberOfShots,
    this.groupSizeInches,
    this.groupSizeMoa,
    this.avgVelocity,
    this.standardDeviation,
    this.extremeSpread,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this Target with the given fields replaced
  Target copyWith({
    String? id,
    String? rangeSessionId,
    String? photoPath,
    double? distance,
    int? numberOfShots,
    double? groupSizeInches,
    double? groupSizeMoa,
    double? avgVelocity,
    double? standardDeviation,
    double? extremeSpread,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Target(
      id: id ?? this.id,
      rangeSessionId: rangeSessionId ?? this.rangeSessionId,
      photoPath: photoPath ?? this.photoPath,
      distance: distance ?? this.distance,
      numberOfShots: numberOfShots ?? this.numberOfShots,
      groupSizeInches: groupSizeInches ?? this.groupSizeInches,
      groupSizeMoa: groupSizeMoa ?? this.groupSizeMoa,
      avgVelocity: avgVelocity ?? this.avgVelocity,
      standardDeviation: standardDeviation ?? this.standardDeviation,
      extremeSpread: extremeSpread ?? this.extremeSpread,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate MOA from inches and distance
  /// MOA = (group size in inches / distance in yards) * 100 / 1.047
  static double calculateMoa(double groupSizeInches, double distanceYards) {
    if (distanceYards <= 0) return 0;
    return (groupSizeInches / distanceYards) * 100 / 1.047;
  }

  /// Calculate MOA for this target if group size and distance are available
  double? get calculatedMoa {
    if (groupSizeInches == null) return null;
    return calculateMoa(groupSizeInches!, distance);
  }

  @override
  String toString() {
    return 'Target(id: $id, rangeSessionId: $rangeSessionId, distance: $distance, shots: $numberOfShots)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Target && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
