import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:lazy_evaluation/lazy_evaluation.dart';
import 'package:sqlite_entity/sqlite_entity.dart';
import 'package:source_gen/source_gen.dart' show ConstantReader, TypeChecker;

import 'generator_exception.dart';

class ProcessedForeignKey {
  ProcessedForeignKey(this.element) {
    if (!isValidInput(element)) {
      throw GeneratorException('''ForeignKeyProcessor can only process elements
          of type ForeingKey. Found: ${element.type}.''');
    }
    _reader = Lazy<ConstantReader>(
      () => ConstantReader(
        element.computeConstantValue(),
      ),
    );
    _parentColumns = Lazy<List<String>>(() => initColumnNames('parentColumns'));
    _childColumns = Lazy<List<String>>(() => initColumnNames('childColumns'));
  }

  final FieldElement element;
  DartObject value;
  Lazy<ConstantReader> _reader;
  Lazy<List<String>> _parentColumns;
  Lazy<List<String>> _childColumns;

  static final _foreignKeyChecker = TypeChecker.fromRuntime(ForeignKey);

  static isValidInput(FieldElement element) {
    if (_foreignKeyChecker.isAssignableFromType(
      element.type,
    )) {
      return true;
    } else {
      return false;
    }
  }

  List<String> get parentColumns => _parentColumns.value;
  List<String> get childColumns => _childColumns.value;

  String get name => element.name;

  /// Reads child and parent column names.
  /// Note: In the most general case both the foreign key and
  /// the parent reference are composite keys.
  List<String> initColumnNames(String fieldName) {
    List<String> names = [];
    //Get bound columns
    var columns = _reader.value.read(fieldName).listValue;
    for (var column in columns) {
      names.add(
        ConstantReader(column).read('name').stringValue,
      );
    }
    return names;
  }
}
