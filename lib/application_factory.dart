/**
 * Bootstrapping for Angular applications via [dart:mirrors](https://api.dartlang
 * .org/apidocs/channels/stable/dartdoc-viewer/dart-mirrors) for development.
 *
 * Angular apps that use  [applicationFactory](#angular-app-factory@id_dynamicApplication) rely on
 * dynamic transformation at compile time to generate the getters, setters, annotations, and
 * factories needed for tree shaking during compilation with `dart2js`. See the [angular:app]
 * (#angular-app) library for a discussion of how this works.
 */
library angular.app.factory;

import 'package:di/dynamic_injector.dart';
import 'package:angular/angular.dart';
import 'package:angular/core/registry.dart';
import 'package:angular/core/parser/parser.dart' show ClosureMap;
import 'package:angular/change_detection/change_detection.dart';
import 'package:angular/change_detection/dirty_checking_change_detector_dynamic.dart';
import 'package:angular/core/registry_dynamic.dart';
import 'package:angular/core/parser/parser_dynamic.dart';
import 'dart:html';

/**
 * If you are writing code accessed from Angular expressions, you must include
 * your own @MirrorsUsed annotation or ensure that everything is tagged with
 * the Ng annotations.
 *
 * All programs should also include a @MirrorsUsed(override: '*') which
 * tells the compiler that only the explicitly listed libraries will
 * be reflected over.
 *
 * This is a short-term fix until we implement a transformer-based solution
 * which does not rely on mirrors.
 */
@MirrorsUsed(targets: const [
    'angular',
    'angular.core_internal',
    'angular.core.dom_internal',
    'angular.formatter',
    'angular.perf',
    'angular.directive',
    'angular.routing',
    'angular.core.parser.Parser',
    'angular.core.parser.dynamic_parser',
    'angular.core.parser.lexer',
    'perf_api',
    List,
    NodeTreeSanitizer,
],
metaTargets: const [
    Injectable,
    Decorator,
    Controller,
    Component,
    Formatter
])
import 'dart:mirrors' show MirrorsUsed;

class _DynamicApplication extends Application {
  _DynamicApplication() {
    ngModule
        ..type(MetadataExtractor, implementedBy: DynamicMetadataExtractor)
        ..type(FieldGetterFactory, implementedBy: DynamicFieldGetterFactory)
        ..type(ClosureMap, implementedBy: DynamicClosureMap);
  }

  Injector createInjector() => new DynamicInjector(modules: modules);
}

Application applicationFactory() => new _DynamicApplication();
