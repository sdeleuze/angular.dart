library angular.test.tools.transformer.expression_extractor_spec;

import 'dart:async';

import 'package:angular/tools/transformer/expression_generator.dart';
import 'package:angular/tools/transformer/html_dart_references_generator.dart';
import 'package:angular/tools/transformer/options.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:code_transformers/tests.dart' as tests;

import '../../jasmine_syntax.dart';

main() {
  describe('ExpressionGenerator', () {
    var htmlFiles = [];
    var templateUriRewrites = {};
    var options = new TransformOptions(
        htmlFiles: htmlFiles,
        templateUriRewrites: templateUriRewrites,
        sdkDirectory: dartSdkDirectory);
    var resolvers = new Resolvers(dartSdkDirectory);

    var phases = [
      [new HtmlDartReferencesGenerator(options)],
      [new ExpressionGenerator(options, resolvers)]
    ];

    it('should extract expressions', () {
      return generates(phases,
          inputs: {
            'a|web/main.dart': '''
                import 'package:angular/angular.dart';

                main() {} ''',
            'a|web/index.html': '''
                <div>{{some.getter}}</div>
                <script src='main.dart' type='application/dart'></script>''',
            'angular|lib/angular.dart': libAngular,
          },
          getters: ['some', 'getter'],
          setters: ['some', 'getter'],
          symbols: []);
    });

    it('should extract functions as getters', () {
      return generates(phases,
          inputs: {
            'a|web/main.dart': '''
                import 'package:angular/angular.dart';

                main() {} ''',
            'a|web/index.html': '''
                <div>{{some.method()}}</div>
                <script src='main.dart' type='application/dart'></script>''',
            'angular|lib/angular.dart': libAngular,
          },
          getters: ['some', 'method'],
          setters: ['some'],
          symbols: []);
    });

    it('should follow templateUris', () {
      return generates(phases,
          inputs: {
            'a|web/main.dart': '''
                import 'package:angular/angular.dart';

                @NgComponent(
                    templateUrl: 'lib/foo.html',
                    selector: 'my-component')
                class FooComponent {}

                @NgComponent(
                    templateUrl: 'packages/b/bar.html',
                    selector: 'my-component')
                class BarComponent {}

                main() {}
                ''',
            'a|lib/foo.html': '''
                <div>{{template.contents}}</div>''',
            'b|lib/bar.html': '''
                <div>{{bar}}</div>''',
            'a|web/index.html': '''
                <script src='main.dart' type='application/dart'></script>''',
            'angular|lib/angular.dart': libAngular,
          },
          getters: ['template', 'contents', 'bar'],
          setters: ['template', 'contents', 'bar'],
          symbols: []);
    });

    it('should apply additional HTML files', () {
      htmlFiles.add('web/dummy.html');
      htmlFiles.add('/packages/b/bar.html');
      return generates(phases,
          inputs: {
            'a|web/main.dart': '''
                import 'package:angular/angular.dart';

                main() {}
                ''',
            'a|web/dummy.html': '''
                <div>{{contents}}</div>''',
            'b|lib/bar.html': '''
                <div>{{bar}}</div>''',
            'a|web/index.html': '''
                <script src='main.dart' type='application/dart'></script>''',
            'angular|lib/angular.dart': libAngular,
          },
          getters: ['contents', 'bar'],
          setters: ['contents', 'bar'],
          symbols: []).whenComplete(() {
            htmlFiles.clear();
          });
    });

    it('should warn on not-found HTML files', () {
      htmlFiles.add('web/not-found.html');
      return generates(phases,
          inputs: {
            'a|web/main.dart': '''
                import 'package:angular/angular.dart';

                main() {}

                @NgComponent(
                    templateUrl: 'packages/b/not-found.html',
                    selector: 'my-component')
                class BarComponent {}
                ''',
            'a|web/index.html': '''
                <script src='main.dart' type='application/dart'></script>''',
            'angular|lib/angular.dart': libAngular,
          },
          messages: [
            'warning: Unable to find /packages/b/not-found.html at '
                'b|lib/not-found.html (web/main.dart 4 16)',
            'warning: Unable to find a|web/main.dart from html_files in '
                'pubspec.yaml.',
          ]).whenComplete(() {
            htmlFiles.clear();
          });
    });
  });
}

Future generates(List<List<Transformer>> phases,
    { Map<String, String> inputs,
      List<String> getters: const [],
      List<String> setters: const [],
      List<String> symbols: const [],
      Iterable<String> messages: const []}) {

  var buffer = new StringBuffer();
  buffer.write(header);
  buffer.write('final Map<String, FieldGetter> getters = {\n');
  buffer.write(getters.map((g) => '  r"$g": (o) => o.$g').join(',\n'));
  buffer.write('\n};\n');
  buffer.write('final Map<String, FieldSetter> setters = {\n');
  buffer.write(setters.map((s) => '  r"$s": (o, v) => o.$s = v').join(',\n'));
  buffer.write('\n};\n');
  buffer.write('final Map<String, Symbol> symbols = {\n');
  buffer.write(symbols.map((s) => '  r"$s": #$s').join(',\n'));
  buffer.write('\n};\n');

  return tests.applyTransformers(phases,
      inputs: inputs,
      results: {
        'a|web/main_static_expressions.dart': buffer.toString()
      },
      messages: messages);
}

const String header = '''
library a.web.main.generated_expressions;

import 'package:angular/change_detection/change_detection.dart';

''';

const String libAngular = '''
library angular.core.annotation_src;

class NgComponent {
  const NgComponent({String templateUrl, String selector});
}
''';
