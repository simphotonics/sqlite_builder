import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' show BuildStep;
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqlite_entity/sqlite_entity.dart';
import 'package:sqlite_builder/src/table_visitor.dart';

class ModelGenerator1 extends GeneratorForAnnotation<GenerateModel> {
  TableVisitor _v;

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    // Create a new table visitor for each annotated element
    // (Otherwise previously detected columns, foreign keys, etc are included
    // again!)
    _v = TableVisitor();
    element.visitChildren(_v);

    return DartFormatter().format(_library().accept(DartEmitter()).toString());
  }

  /// Adds import statement
  Library _library() {
    return Library((b) => b
      //..directives.add(Directive.import('package:meta/meta.dart'))
      ..body.addAll([
        _modelClass(),
      ]));
  }

  /// Builds model class.
  Class _modelClass() {
    return Class((b) => b
      ..name = _v.modelClassName
      ..fields.addAll(_modelFields())
      ..constructors.addAll([
        _modelConstructor(),
        _fromMapConstructor(),
      ])
      ..methods.addAll([
        _toMapMethod(),
        _initMapMethod(),
      ])
      ..docs.add('/// Data model [_v.modelClassName].${DateTime.now()}'));
  }

  /// Builds model fields.
  List<Field> _modelFields() {
    List<Field> fields = [];
    for (var column in _v.columns) {
      fields.add(Field((b) => b
        ..name = column.name
        ..type = refer(column.type.toString())
        ..modifier = FieldModifier.final$));
    }
    // // Initialize static const table.
    // fields.add(Field((b) => b
    //   ..name = 'table'
    //   //..type = refer(_v.tableClassName)
    //   ..modifier = FieldModifier.constant
    //   ..static = true
    //   ..assignment = _tableInitializer()
    //   ..docs.add('/// Table associated to data model: ${_v.modelClassName}')));
    return fields;
  }

  // /// Builds table field initializer.
  // Code _tableInitializer() {
  //   var b = QuoteBuffer();
  //   b.writeln('${_v.tableClassName}(');
  //   for (var column in _v.columns) {
  //     b.write('${column.name}:');
  //     b.write(BoundColumn.source(
  //       name: column.name,
  //       type: column.sqliteType.type,
  //       constraints: column.constraints,
  //       defaultValue: column.defaultValue,
  //     ));
  //     b.write(',');
  //   }
  //   b.writeln(')');
  //   return Code(b.toString());
  // }

  /// Builds model constructor.
  Constructor _modelConstructor() {
    List<Parameter> parameters = [];
    for (var column in _v.columns) {
      parameters.add(Parameter((b) => b
        ..named = true
        ..annotations.add(refer('required'))
        ..toThis = true
        ..name = column.name));
    }
    return Constructor((b) => b
      ..optionalParameters.addAll(parameters)
      ..constant = true);
  }

  /// Builds model constructor.
  Constructor _fromMapConstructor() {
    final parameter = Parameter((b) => b
      ..name = 'map'
      ..type = refer('Map<String,dynamic>'));
    List<Code> initializers = [];
    for (var column in _v.columns) {
      initializers.add(Code('${column.name} = map[\'${column.name}\']'));
    }
    return Constructor((b) => b
      ..docs
          .add('/// Converts a Map<String,dynamic> to a ${_v.modelClassName}.')
      ..name = 'fromMap'
      ..requiredParameters.add(parameter)
      ..initializers.addAll(initializers));
  }

  /// Builds toMap() model method
  Method _toMapMethod() {
    var source = StringBuffer();
    source.writeln('return {');
    for (var column in _v.columns) {
      source.writeln('\'${column.name}\': ${column.name},');
    }
    source.writeln('};');

    return Method((b) => b
      ..docs.add('/// Converts a ${_v.modelClassName} to Map<String,dynamic>')
      ..returns = refer('Map<String,dynamic>')
      ..body = Code(source.toString())
      ..name = 'toMap');
  }

  /// Builds initMap() model method
  Method _initMapMethod() {
    // List of parameters
    List<Parameter> parameters = [];
    // Function body
    var source = StringBuffer();
    source.writeln('return {');
    for (var column in _v.columns) {
      //Skip column declared as primary key
      if (column.constraints.contains(Constraint.PRIMARY_KEY)) continue;
      source.writeln('\'${column.name}\': ${column.name},');
      // Add parameter
      parameters.add(Parameter((b) => b
        ..type = refer(column.type.toString())
        ..annotations.add(refer('required'))
        ..named = true
        ..name = column.name));
    }
    source.writeln('};');

    return Method((b) => b
      ..docs.add(
          '''/// Creates a Map<String,dynamic> representing a ${_v.modelClassName}
      /// object without a primary key. The primary key is assigned by the
      /// database during insertion.''')
      ..static = true
      ..returns = refer('Map<String,dynamic>')
      ..optionalParameters.addAll(parameters)
      ..body = Code(source.toString())
      ..name = 'initMap');
  }
}
