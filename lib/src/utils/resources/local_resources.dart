import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../../analytics/analytics.dart';
import '../../xwidget.dart';
import 'resources.dart';

final _log = Logger('LocalResources');

/// Loads resources from Flutter's asset bundle.
///
/// This is the default when no `resources` parameter is passed to
/// [XWidget.initialize].
///
/// Path parameters ([fragmentsPath], [valuesPath]) default to values
/// from [XWidget.config] when not provided explicitly. Constructor
/// arguments override config values when passed.
///
/// Use [LocalResources.withAnalytics] to enable XWidget Cloud
/// analytics without cloud-hosted resource delivery.
class LocalResources extends Resources {
  static bool _serviceExtensionRegistered = false;

  final String? _fragmentsPath;
  final String? _valuesPath;
  final AssetBundle? assetBundle;
  final String? projectKey;
  final String? version;
  final String? channel;

  String get fragmentsPath => _fragmentsPath ?? XWidget.config.fragmentsPath;
  String get valuesPath => _valuesPath ?? XWidget.config.valuesPath;

  LocalResources({String? fragmentsPath, String? valuesPath, this.assetBundle})
    : _fragmentsPath = fragmentsPath,
      _valuesPath = valuesPath,
      projectKey = null,
      version = null,
      channel = null;

  /// Creates a [LocalResources] with XWidget Cloud analytics enabled.
  LocalResources.withAnalytics({
    required String this.projectKey,
    required String this.version,
    String? fragmentsPath,
    String? valuesPath,
    this.assetBundle,
  }) : _fragmentsPath = fragmentsPath,
       _valuesPath = valuesPath,
       channel = 'local';

  @override
  Future<void> load() async {
    if (projectKey != null) {
      await Analytics.initialize(
        projectKey: projectKey!,
        channel: channel ?? 'local',
        version: version!,
      );
    }

    _log.info(
      'Loading local resources from fragmentsPath=$fragmentsPath, '
      'valuesPath=$valuesPath',
    );

    final activeAssetBundle = assetBundle ?? rootBundle;
    final manifestMap = await _loadManifest(activeAssetBundle);

    final fragments = FragmentResourceBundle(fragmentsPath);
    final values = ValueResourceBundle(valuesPath);

    var fragmentCount = 0;
    var valueFileCount = 0;

    for (final fileName in manifestMap.keys) {
      if (fileName.startsWith('$fragmentsPath/')) {
        final relativePath = fileName.substring(fragmentsPath.length + 1);
        final parts = splitFileName(relativePath);
        if (parts != null) {
          await fragments.loadFromAssetBundle(
            fileName,
            parts.path,
            parts.name,
            parts.ext,
            activeAssetBundle,
          );
          fragmentCount++;
        }
      } else if (fileName.startsWith('$valuesPath/')) {
        final relativePath = fileName.substring(valuesPath.length + 1);
        final parts = splitFileName(relativePath);
        if (parts != null) {
          await values.loadFromAssetBundle(
            fileName,
            parts.path,
            parts.name,
            parts.ext,
            activeAssetBundle,
          );
          valueFileCount++;
        }
      }
    }

    replaceResourceBundles([fragments, values]);
    _log.info(
      'Local resources loaded: $fragmentCount fragments, '
      '$valueFileCount value files',
    );

    _registerServiceExtensions();
  }

  void _registerServiceExtensions() {
    if (kDebugMode) {
      if (_serviceExtensionRegistered) return;
      _serviceExtensionRegistered = true;

      // register for fragment updates
      registerExtension('ext.xwidget.updateFragment', (method, params) async {
        final fqn = params['fqn'];
        final content = params['content'];
        if (fqn == null || content == null) {
          return ServiceExtensionResponse.error(
            ServiceExtensionResponse.invalidParams,
            'Missing required params: fqn, content',
          );
        }
        final bundle = Resources.of<FragmentResourceBundle>();
        bundle.updateFragment(fqn, content);
        Resources.instance.clearXmlCache();
        WidgetsBinding.instance.reassembleApplication();
        _log.fine('Fragment updated via service extension: $fqn');
        return ServiceExtensionResponse.result('{}');
      });

      // register for updated to resource values
      registerExtension('ext.xwidget.updateValues', (method, params) async {
        final content = params['content'];
        if (content == null) {
          return ServiceExtensionResponse.error(
            ServiceExtensionResponse.invalidParams,
            'Missing required param: content',
          );
        }
        final bundle = Resources.of<ValueResourceBundle>();
        bundle.updateValues(content);
        WidgetsBinding.instance.reassembleApplication();
        _log.fine('Values updated via service extension');
        return ServiceExtensionResponse.result('{}');
      });
    }
  }

  Future<dynamic> _loadManifest(AssetBundle assetBundle) async {
    try {
      final data = await assetBundle.load('AssetManifest.bin');
      return const StandardMessageCodec().decodeMessage(data);
    } catch (_) {
      final jsonStr = await assetBundle.loadString('AssetManifest.json');
      return json.decode(jsonStr);
    }
  }
}
