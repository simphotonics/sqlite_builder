import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:lazy_evaluation/lazy_evaluation.dart';
import 'package:sqlite_entity/sqlite_entity.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader, TypeChecker;
import 'package:sqlite_builder/src/generator_exception.dart';
import 'package:sqlite_builder/src/type_utils.dart';

/// Class representing a processed [Column].
class ProcessedColumn {
  ProcessedColumn(this.fieldElement) {
    /// Validate
    _isValidColumn = isValidInput(fieldElement);
    if (!_isValidColumn) return;

    /// Initialize lazy fields
    _constValue = Lazy<DartObject>(
      fieldElement.computeConstantValue,
    );
    _constReader = Lazy<ConstantReader>(() => ConstantReader(
          _constValue.value,
        ));
    _constraints = Lazy<Set<Constraint>>(_initConstraints);
    _defaultValue = Lazy<dynamic>(_initDefaultValue);
    _sqliteType = Lazy<SqliteType>(_initSqliteType);
  }

  /// Field element that is processed.
  final FieldElement fieldElement;
  bool _isValidColumn;

  /// Lazy class fields
  Lazy<DartObject> _constValue;
  Lazy<ConstantReader> _constReader;

  Lazy<Set<Constraint>> _constraints;
  Lazy<dynamic> _defaultValue;
  Lazy<SqliteType> _sqliteType;

  DartType get type => typeArgumentsOf(fieldElement.type).first;
  String get name => fieldElement.name;

  /// Getters
  Set<Constraint> get constraints => _constraints.value;
  dynamic get defaultValue => _defaultValue.value;
  SqliteType get sqliteType => _sqliteType.value;
  bool get isValidColumn => _isValidColumn;

  /// Initializes the lazy variable [sqliteType].
  SqliteType _initSqliteType() {
    if (type.isDartCoreInt) return SqliteType.INTEGER;
    if (type.isDartCoreString) return SqliteType.TEXT;
    if (type.isDartCoreBool) return SqliteType.BOOL;
    if (type.isDartCoreDouble) return SqliteType.REAL;
    throw GeneratorException('Type $type not supported by Sqlite.');
  }

  /// Initializes the lazy variable [constraints].
  Set<Constraint> _initConstraints() {
    Set<Constraint> out = {};
    // Get field constraints
    var constraints = _constValue.value.getField('constraints').toSetValue();
    for (var constraint in constraints) {
      String value = ConstantReader(constraint).read('value').stringValue;
      var constraintObject = Constraint.valueMap[value];
      if (constraintObject != null) {
        out.add(constraintObject);
      }
    }
    return out;
  }

  /// Initializes the lazy variable [defaultValue].
  dynamic _initDefaultValue() {
    var defaultValue = _constValue.value.getField('defaultValue');
    if (type.isDartCoreInt) {
      return defaultValue.toIntValue();
    } else if (type.isDartCoreBool) {
      return defaultValue.toBoolValue();
    } else if (type.isDartCoreString) {
      return defaultValue.toStringValue();
    } else if (type.isDartCoreDouble) {
      return defaultValue.toDoubleValue();
    } else {
      return null;
    }
  }

  static final _columnChecker = TypeChecker.fromRuntime(Column);
  static final _sqlTypeChecker = TypeChecker.any([
    TypeChecker.fromRuntime(int),
    TypeChecker.fromRuntime(bool),
    TypeChecker.fromRuntime(String),
    TypeChecker.fromRuntime(double)
  ]);

  /// Returns true if [element] is of type [Column].
  static isColumn(FieldElement element) {
    return _columnChecker.isAssignableFromType(element.type);
  }

  /// Returns true if the type argument of [element] is a valid
  /// Sqlite type.
  static hasValidType(FieldElement element) {
    var typeArg = typeArgumentsOf(element.type).first;
    return _sqlTypeChecker.isExactlyType(typeArg);
  }

  /// Returns true if [element] is [Column] and has valid Sqlite type
  /// parameter.
  /// Throws if [element] is [Column] and has invalid Sqlite type.
  static bool isValidInput(FieldElement element) {
    if (!isColumn(element)) return false;
    if (!hasValidType(element)) {
      // Invalid type argument of generic class Column<Type>.
      var columnType = typeArgumentsOf(element.type).first;
      throw GeneratorException('''
        Variable ${element.name} has unsupported type: Column<$columnType>.
        Valid types are: Column<int>, Column<String>,
                         Column<bool>, Column<double>
        ''');
    } else {
      return true;
    }
  }
}
