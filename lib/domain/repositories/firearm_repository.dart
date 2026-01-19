import '../entities/firearm.dart';

/// Repository interface for Firearm operations
/// This defines the contract that the data layer must implement
abstract class FirearmRepository {
  /// Get all firearms
  Future<List<Firearm>> getAllFirearms();

  /// Get a firearm by ID
  Future<Firearm?> getFirearmById(String id);

  /// Add a new firearm
  Future<void> addFirearm(Firearm firearm);

  /// Update an existing firearm
  Future<void> updateFirearm(Firearm firearm);

  /// Delete a firearm by ID
  Future<void> deleteFirearm(String id);

  /// Search firearms by name, make, model, or caliber
  Future<List<Firearm>> searchFirearms(String query);
}
