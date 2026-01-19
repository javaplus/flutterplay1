/// Domain entity representing a Shot Velocity
/// This represents the velocity of an individual shot captured from a chronograph
class ShotVelocity {
  final String id;
  final String targetId; // Foreign key to Target
  final double velocity; // Velocity in fps
  final DateTime timestamp; // When the shot was recorded
  final DateTime createdAt;
  final DateTime updatedAt;

  ShotVelocity({
    required this.id,
    required this.targetId,
    required this.velocity,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this ShotVelocity with the given fields replaced
  ShotVelocity copyWith({
    String? id,
    String? targetId,
    double? velocity,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShotVelocity(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      velocity: velocity ?? this.velocity,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ShotVelocity(id: $id, targetId: $targetId, velocity: $velocity fps)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShotVelocity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
