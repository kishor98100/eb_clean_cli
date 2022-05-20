/*
 * Copyright (c) 2022.
 * Author: Kishor Mainali
 * Company: EB Pearls
 */
import 'package:args/command_runner.dart';
import 'package:eb_clean_cli/src/cli/cli.dart';
import 'package:eb_clean_cli/src/commands/generate/templates/clean/source/source_template.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:universal_io/io.dart';

class SourceCommand extends Command<int> {
  SourceCommand(this.logger) {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'feature name to create page',
        mandatory: true,
      )
      ..addOption(
        'client',
        abbr: 'c',
        help: 'client to use as api client',
        allowed: ['dio', 'graphql'],
        defaultsTo: 'graphql',
      );
  }

  final Logger logger;

  @override
  String get description => 'generates source class in specific feature';

  @override
  String get name => 'source';

  @override
  String get invocation => 'eb_clean generate source --client <dio,graphql> <name>';

  @override
  String get summary => '$invocation\n$description';

  @override
  Future<int> run() async {
    if (argResults!['feature'] == null) {
      throw UsageException('feature is required', usage);
    }
    final packageName = Directory.current.path.split('/').last;
    if (!FlutterCli.isVeryGoodProject()) {
      final args = argResults?.rest;
      if (args != null && args.isNotEmpty) {
        final client = argResults!['client'] as String? ?? 'graphql';
        final featureName = argResults!['feature'] as String;
        final sourceName = args.first;
        final sourceTemplate = SourceTemplate();
        final sourceDone = logger.progress('Generating ${sourceName.pascalCase}RemoteSource');
        final sourceGenerator = await MasonGenerator.fromBundle(sourceTemplate.bundle);
        var vars = <String, dynamic>{
          'name': sourceName,
          'useDio': client == 'dio',
          'package_name': packageName,
        };
        final cwd = Directory(p.join(Directory.current.path, sourceTemplate.path, '$featureName/data/source'));
        await sourceGenerator.generate(DirectoryGeneratorTarget(cwd),
            fileConflictResolution: FileConflictResolution.overwrite, vars: vars);
        sourceDone('Generated ${sourceName.pascalCase}RemoteSource source in ${sourceTemplate.path}');
        await sourceTemplate.onGenerateComplete(logger, Directory.current);
      } else {
        throw UsageException('please provide source name', usage);
      }
      return ExitCode.success.code;
    } else {
      throw UsageException('source is not generated on non clean project', usage);
      return ExitCode.success.code;
    }
  }
}
