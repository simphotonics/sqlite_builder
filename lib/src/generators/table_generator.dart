import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqlite_entity/sqlite_entity.dart';
import 'package:sqlite_builder/src/processed_column.dart';
import 'package:sqlite_builder/src/table_visitor.dart';

String classNameToLibraryName(String className) {
  final pattern = RegExp(r"(?<=[a-z])[A-Z]");
  String libraryName = className.replaceAllMapped(
    pattern,
    (Match m) => '_${m[0]}',
  );
  return libraryName.toLowerCase();
}

class TableGenerator extends GeneratorForAnnotation<GenerateTable> {
  TableVisitor _v;

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    // Create a new table visitor for each annotated element
    // (Otherwise previously detected columns, foreign keys, etc are included again!)
    _v = TableVisitor();
    element.visitChildren(_v);
    return DartFormatter().format(_library().accept(DartEmitter()).toString());
  }

  /// Adds import statement
  Library _library() {
    return Library((b) => b
      // ..directives.addAll([
      //   Directive.import(
      //     'package:sqlite_entity/sqlite_entity.dart',
      //     // show: [
      //     //   'BoundColumn',
      //     //   'Constraint',
      //     //   'Table',
      //     // ],
      //   ),
      //   Directive.import(
      //       '${classNameToLibraryName(_v.modelClassName)}.model.dart'),
      // ])
      ..body.addAll([
        // refer(
        //     'part \'${classNameToLibraryName(_v.modelClassName)}.table.g.dart\';'),
        _tableClass(),
      ]));
  }

  /// Generates the [Table] class
  Class _tableClass() {
    return Class((b) => b
          ..name = _v.tableClassName
          ..constructors.add(_tableConstructor())
          ..extend = refer('Table<${_v.modelClassName}>')
          //..annotations.add(refer('GenerateSqliteInit').call([]))
          ..fields.addAll(
            _tableFields(),
          )
        //..fields.add(_init())
        );
  }

  /// Builds table constructor.
  Constructor _tableConstructor() {
    // List<Parameter> parameters = [];
    // for (var column in _v.columns) {
    //   parameters.add(Parameter((b) => b
    //     ..named = true
    //     ..annotations.add(refer('required'))
    //     ..toThis = true
    //     ..name = column.name));
    // }
    return Constructor((b) => b
      //..optionalParameters.addAll(parameters)
      ..constant = true
      ..name = '_');
  }

  /// Generates table fields.
  List<Field> _tableFields() {
    List<Field> fields = [];
    for (var column in _v.columns) {
      fields.add(Field((b) => b
        ..name = column.name
        ..assignment = Code(_columnInitializer(column))
        //..type = refer('BoundColumn<${column.type}>')
        ..static = true
        ..docs.add('/// Column ${column.name}')
        ..modifier = FieldModifier.constant));
    }
    fields.add(Field((b) => b
     ..name = 'init'
     ..type = refer('String')
     ..assignment = Code('_init')
     ..static = true
     ..modifier = FieldModifier.constant
     ..docs.add('/// Sqlite command: Initialize table ${_v.tableClassName}')));
    return fields;
  }

  /// Builds column initializer.
  String _columnInitializer(ProcessedColumn column) {
    return BoundColumn.source(
      name: column.name,
      type: column.sqliteType.type,
      constraints: column.constraints,
      defaultValue: column.defaultValue,
    );
  }
}
