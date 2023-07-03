import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:sqlite_builder/src/processed_column.dart';
import 'package:sqlite_builder/src/processed_foreign_key.dart';
import 'generator_exception.dart';

/// Visitor
class TableVisitor extends SimpleElementVisitor {
  /// Name of generated model class.
  String modelClassName;

  /// Name of private table class.
  String tableClassName;

  List<FieldElement> fields = [];
  List<ProcessedColumn> columns = [];
  List<ProcessedForeignKey> foreignKeys = [];
  List<MethodElement> methods = [];

  final String baseClassName = 'TableInfo';

  /// Construct model class name.
  /// Note: If no constructor is defined, the default
  /// constructor is visited.
  @override
  visitConstructorElement(ConstructorElement element) {
    var className = element.type.returnType.toString();
    // Check if className ends with Table.
    var nameException = GeneratorException(
      '''Classes extending TableInfo should be named
      <ModelClassName>TableInfo.
      Try renaming $className to ${className}TableInfo''',
    );
    if (className.length < baseClassName.length) throw nameException;
    if (className.replaceRange(
            0, className.length - baseClassName.length, '') !=
        baseClassName) throw nameException;

    modelClassName = className.replaceRange(
      className.length - baseClassName.length,
      className.length,
      '',
    );
    tableClassName = '${modelClassName}Table';
  }

  @override
  visitFieldElement(FieldElement element) {
    fields.add(element);
    _addColumn(element);
    _addForeignKey(element);
  }

  @override
  visitMethodElement(MethodElement element) {
    methods.add(element);
  }

  /// Adds elements of type ProcessedColumn to [columns].
  _addColumn(FieldElement element) {
    // Add ProcessedColumn is element is of type [Column] and has a type
    // parameter that is supported by Sqlite.
    if (ProcessedColumn.isValidInput(element)) {
      columns.add(ProcessedColumn(element));
    }
  }

   _addForeignKey(FieldElement element) {
    // Check if element is [ForeignKey].
    if (ProcessedForeignKey.isValidInput(element)) {
      foreignKeys.add(ProcessedForeignKey(element));
    }
  }
}
