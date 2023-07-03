import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';

/// Visits ClassElements and collects static type information.
/// The static type of class, superclass, and type parameters
/// (for parametrized types) can be accessed via getters.
///
/// Usage:
/// ```
/// var vis = ClassElementVisitor();
/// element.accept(vis);
///
/// print(${vis.classType});
/// print(${vis.superType});
/// ```
class ClassElementVisitor extends SimpleElementVisitor<void> {
  late DartType _thisType;
  late DartType _thisTypeArg;
  late DartType _superType;
  late DartType _superTypeArg;
  late List<DartType> _thisTypeArgs;
  late List<DartType> _superTypeArgs;

  @override
  void visitClassElement(ClassElement element) {
    _thisType = element.thisType;
    _thisTypeArgs = typeArgumentsOf(_thisType);
    _thisTypeArg = (_thisTypeArgs.isNotEmpty) ? _thisTypeArgs.first : null;
    _superType = element.supertype;
    _superTypeArgs = typeArgumentsOf(_superType);
    _superTypeArg = (_superTypeArgs.isNotEmpty) ? _superTypeArgs.first : null;
  }

  /// Static type of class, if element is ClassElement otherwise null.
  DartType get thisType => _thisType;

  /// First entry of static class type parameter list. Null if list is empty.
  DartType get thisTypeArg => _thisTypeArg;

  /// Class static type parameter list.
  List<DartType> get thisTypeArgs => _thisTypeArgs;

  /// Static type of superclass, if element is ClassElement otherwise null.
  DartType get superType => _superType;

  /// First entry of superclass static type parameter list. Null if list is empty.
  DartType get superTypeArg => _superTypeArg;

  /// Superclass static type parameter list.
  List<DartType> get superTypeArgs => _superTypeArgs;
}

/// Returns a [List] of type arguments (of a parametrized type).
List<DartType> typeArgumentsOf(DartType type) {
  return type is ParameterizedType ? type.typeArguments : const [];
}
