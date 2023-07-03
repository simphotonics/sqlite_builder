import 'package:analyzer/dart/element/type.dart'
    show DartType, ParameterizedType;
import 'package:sqlite_builder/src/generator_exception.dart';

/// Returns a [List] of type arguments (of a parametrized type)
List<DartType> typeArgumentsOf(DartType type) {
  return type is ParameterizedType ? type.typeArguments : const [];
}

/// Converts a valid static type to an SQLITE type
String sqliteType(DartType type) {
  if (type.isDartCoreInt) return 'INTEGER';
  if (type.isDartCoreString) return 'TEXT';
  if (type.isDartCoreBool) return 'INTEGER';
  if (type.isDartCoreDouble) return 'REAL';
  throw GeneratorException(
      'Type could not be converted to a valid Sqlite type. Found: $type.');
}
