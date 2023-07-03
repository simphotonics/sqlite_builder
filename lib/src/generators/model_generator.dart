
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' show BuildStep;
import 'package:source_gen/source_gen.dart'
    show ConstantReader, GeneratorForAnnotation;
import 'package:sqlite_entity/sqlite_entity.dart';

class ModelGenerator extends GeneratorForAnnotation<GenerateModel> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    // TODO: implement generateForAnnotatedElement
    throw UnimplementedError();
  }
}
