/// Domain entity representing a Load Recipe
/// This represents a complete reloading recipe/load data
class LoadRecipe {
  final String id;
  final String nickname; // Friendly name for quick identification
  final String cartridge; // e.g., ".308 Win"
  final double bulletWeight; // In grains
  final String bulletType; // e.g., "FMJ", "HPBT"
  final bool
  isFactoryAmmo; // True for factory/commercial ammo (skips powder/primer/brass fields)
  final String? powderType; // null for factory ammo
  final double? powderCharge; // In grains; null for factory ammo
  final String? primerType; // null for factory ammo
  final String? brassType; // Brand/type of brass; null for factory ammo
  final String? brassPrep; // Prep notes (annealed, resized, etc.) - optional
  final double?
  coalLength; // Cartridge Overall Length in inches; null for factory ammo
  final double? seatingDepth; // In inches - optional
  final String? crimp; // Text field for crimp info - optional
  final List<String> pressureSigns; // Multiple pressure sign indicators
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoadRecipe({
    required this.id,
    required this.nickname,
    required this.cartridge,
    required this.bulletWeight,
    required this.bulletType,
    this.isFactoryAmmo = false,
    this.powderType,
    this.powderCharge,
    this.primerType,
    this.brassType,
    this.brassPrep,
    this.coalLength,
    this.seatingDepth,
    this.crimp,
    this.pressureSigns = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this LoadRecipe with the given fields replaced.
  /// Use [clearPowderType], [clearPowderCharge], etc. sentinel booleans to
  /// explicitly set nullable fields to null.
  LoadRecipe copyWith({
    String? id,
    String? nickname,
    String? cartridge,
    double? bulletWeight,
    String? bulletType,
    bool? isFactoryAmmo,
    String? powderType,
    bool clearPowderType = false,
    double? powderCharge,
    bool clearPowderCharge = false,
    String? primerType,
    bool clearPrimerType = false,
    String? brassType,
    bool clearBrassType = false,
    String? brassPrep,
    bool clearBrassPrep = false,
    double? coalLength,
    bool clearCoalLength = false,
    double? seatingDepth,
    bool clearSeatingDepth = false,
    String? crimp,
    bool clearCrimp = false,
    List<String>? pressureSigns,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoadRecipe(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      cartridge: cartridge ?? this.cartridge,
      bulletWeight: bulletWeight ?? this.bulletWeight,
      bulletType: bulletType ?? this.bulletType,
      isFactoryAmmo: isFactoryAmmo ?? this.isFactoryAmmo,
      powderType: clearPowderType ? null : (powderType ?? this.powderType),
      powderCharge: clearPowderCharge
          ? null
          : (powderCharge ?? this.powderCharge),
      primerType: clearPrimerType ? null : (primerType ?? this.primerType),
      brassType: clearBrassType ? null : (brassType ?? this.brassType),
      brassPrep: clearBrassPrep ? null : (brassPrep ?? this.brassPrep),
      coalLength: clearCoalLength ? null : (coalLength ?? this.coalLength),
      seatingDepth: clearSeatingDepth
          ? null
          : (seatingDepth ?? this.seatingDepth),
      crimp: clearCrimp ? null : (crimp ?? this.crimp),
      pressureSigns: pressureSigns ?? this.pressureSigns,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LoadRecipe(id: $id, nickname: $nickname, cartridge: $cartridge, bulletWeight: $bulletWeight, isFactoryAmmo: $isFactoryAmmo, powderType: $powderType)';
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
