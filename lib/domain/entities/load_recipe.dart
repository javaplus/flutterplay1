/// Domain entity representing a Load Recipe
/// This represents a complete reloading recipe/load data
class LoadRecipe {
  final String id;
  final String cartridge; // e.g., ".308 Win"
  final double bulletWeight; // In grains
  final String bulletType; // e.g., "FMJ", "HPBT"
  final String powderType;
  final double powderCharge; // In grains
  final String primerType;
  final String brassType; // Brand/type of brass
  final String? brassPrep; // Prep notes (annealed, resized, etc.) - optional
  final double coalLength; // Cartridge Overall Length in inches
  final double? seatingDepth; // In inches - optional
  final String? crimp; // Text field for crimp info - optional
  final List<String> pressureSigns; // Multiple pressure sign indicators
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoadRecipe({
    required this.id,
    required this.cartridge,
    required this.bulletWeight,
    required this.bulletType,
    required this.powderType,
    required this.powderCharge,
    required this.primerType,
    required this.brassType,
    this.brassPrep,
    required this.coalLength,
    this.seatingDepth,
    this.crimp,
    this.pressureSigns = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this LoadRecipe with the given fields replaced
  LoadRecipe copyWith({
    String? id,
    String? cartridge,
    double? bulletWeight,
    String? bulletType,
    String? powderType,
    double? powderCharge,
    String? primerType,
    String? brassType,
    String? brassPrep,
    double? coalLength,
    double? seatingDepth,
    String? crimp,
    List<String>? pressureSigns,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoadRecipe(
      id: id ?? this.id,
      cartridge: cartridge ?? this.cartridge,
      bulletWeight: bulletWeight ?? this.bulletWeight,
      bulletType: bulletType ?? this.bulletType,
      powderType: powderType ?? this.powderType,
      powderCharge: powderCharge ?? this.powderCharge,
      primerType: primerType ?? this.primerType,
      brassType: brassType ?? this.brassType,
      brassPrep: brassPrep ?? this.brassPrep,
      coalLength: coalLength ?? this.coalLength,
      seatingDepth: seatingDepth ?? this.seatingDepth,
      crimp: crimp ?? this.crimp,
      pressureSigns: pressureSigns ?? this.pressureSigns,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LoadRecipe(id: $id, cartridge: $cartridge, bulletWeight: $bulletWeight, powderType: $powderType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoadRecipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Common pressure sign indicators
class PressureSignTypes {
  static const String flattenedPrimers = 'Flattened Primers';
  static const String crateredPrimers = 'Cratered Primers';
  static const String ejectorMarks = 'Ejector Marks';
  static const String extractorMarks = 'Extractor Marks';
  static const String heavyBoltLift = 'Heavy Bolt Lift';
  static const String stickyExtraction = 'Sticky Extraction';
  static const String caseHeadSeparation = 'Case Head Separation';

  static const List<String> all = [
    flattenedPrimers,
    crateredPrimers,
    ejectorMarks,
    extractorMarks,
    heavyBoltLift,
    stickyExtraction,
    caseHeadSeparation,
  ];
}
