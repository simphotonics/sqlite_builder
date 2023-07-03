import 'package:build/build.dart';
import 'package:merging_builder/merging_builder.dart';


/// Defines a merging builder.
/// Honours the options: `input_files`, `output_file`, `header`, `footer`,
/// and `sort_assets` that can be set in `build.yaml`.
Builder modelBuilder(BuilderOptions options) {
  final defaultOptions = BuilderOptions({
    'input_files': 'lib/*.dart',
    'output_file': 'lib/output.dart',
    'header': modelGenerator.header,
    'footer': modelGenerator.footer,
    'sort_assets': true,
  });

  // Apply user set options.
  options = defaultOptions.overrideWith(options);
  return StandaloneBuilder<LibDir>(
    generator: ModelGenerator(),
    inputFiles: options.config['input_files'],
    outputFile: options.config['output_file'],
    header: options.config['header'],
    footer: options.config['footer'],
    sortAssets: options.config['sort_assets'],
  );
}

/// Defines a standalone builder.
Builder sqliteInitBuilder(BuilderOptions options) {
  final defaultOptions = BuilderOptions({
    'input_files': 'lib/*.dart',
    'output_files': 'lib/output/assistant_(*).dart',
    'header': SqliteInitGenerator.header,
    'footer': SqliteInitGenerator.footer,5
    'root': ''
  });
  options = defaultOptions.overrideWith(options);
  return MergingBuilder<LibDir>(
      generator: SqliteInitGenerator(),
      inputFiles: options.config['input_files'],
      outputFiles: options.config['output_files'],
      root: options.config['root']);
}
