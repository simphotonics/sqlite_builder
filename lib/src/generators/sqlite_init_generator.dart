import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqlite_entity/sqlite_entity.dart';
import 'package:sqlite_builder/src/table_visitor.dart';

String classNameToLibraryName(String className) {
  final pattern = RegExp(r"(?<=[a-z])[A-Z]");
  String libraryName = className.replaceAllMapped(
    pattern,
    (Match m) => '_${m[0]}',
  );
  return libraryName.toLowerCase();
}

class SqliteInitGenerator extends GeneratorForAnnotation<GenerateSqliteInit> {
  TableVisitor _v;

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    // Create a new table visitor for each annotated element
    // (Otherwise previously detected columns, foreign keys, etc are included again!)
    _v = TableVisitor();
    element.visitChildren(_v);

    return DartFormatter().format(
      'part of \'${classNameToLibraryName(_v.modelClassName)}.dart\';${_init().accept(DartEmitter())}',
    );
  }

  Field _init() {
    var source = QuoteBuffer();
    // Specify table name
    source.writelnQ('CREATE TABLE ${_v.modelClassName} (');
    // Specify columns
    List<String> columns = [];
    for (var column in _v.columns) {
      var constraints = column.constraints.join(' ');
      columns.add('${column.name} ${column.sqliteType} $constraints');
    }
    source.writelnAllQ(columns, ',');
    if (_v.foreignKeys.isNotEmpty) {
      source.writeQ(',');
      // Specify foreign keys
      for (var key in _v.foreignKeys) {
        source.writelnQ('FOREIGN KEY(${key.childColumns.join(",")}) REFERENCES ');
        source.writelnQ(key.parentColumns.join(","));
        // print(key.childColumns.toString());
        // print(key.parentColumns.toString());
      }
    }

    source.writeQ(');');

    return Field((b) => b
      ..name = '_init'
      ..assignment = Code(source.toString())
      ..type = refer('String')
      ..modifier = FieldModifier.constant
      ..docs.add('/// Statement used to initialize the '
          'Sqlite table ${_v.modelClassName}.'));
  }
}
