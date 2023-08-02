import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart';

import 'maven_metadata.dart';
import 'maven_pom.dart';

void main() async {
  Repository spigotRepository = const Repository(id: 'spigot', url: 'https://hub.spigotmc.org/nexus/content/repositories/snapshots/');

  var mavenLookup = MavenLookup(repositories: [spigotRepository], groupId: 'org.spigotmc', artifactId: 'spigot-api', version: '1.20.1-R0.1-SNAPSHOT');
  // ProjectObjectModel? model = await MavenExtractor.downloadPOM(mavenLookup);

  // print(model?.name);

  MavenExtractor.downloadJAR(mavenLookup);
}

class MavenLookup {
  final List<Repository> repositories;
  final String groupId;
  final String artifactId;
  final String version;

  const MavenLookup({
    required this.repositories,
    required this.groupId,
    required this.artifactId,
    required this.version,
  });
}

class MavenLookupResult {
  final MavenLookup lookup;
  final Repository repository;
  final File jarFile;
  final File sourceJarFile;
  final List<MavenLookupResult> dependencies; // only "compile" scope

  MavenLookupResult(this.lookup, this.repository, this.jarFile, this.sourceJarFile, this.dependencies);
}

class MavenExtractor {
  static const String mavenCentral = 'https://repo1.maven.org/maven2/';
  static const List<Repository> defaultRepositories = [
    Repository(id: '', url: mavenCentral),
  ];

  static Future<String?> downloadXMLOrNull(String url) async {
    var response = await get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return null;
    }
  }

  static Future<VersionMetadata?> downloadVersionMetadata(MavenLookup lookup, [bool lookUpAtDefaultRepositories = true]) async {
    for (Repository repository in (lookUpAtDefaultRepositories ? defaultRepositories + lookup.repositories : lookup.repositories)) {
      String url = '${repository.url}${lookup.groupId.replaceAll('.', '/')}/${lookup.artifactId}/${lookup.version}/maven-metadata.xml';
      String? xml = await downloadXMLOrNull(url);
      if (xml != null) {
        return VersionMetadata.fromXml(repository, xml);
      }
    }
    return null;
  }

  static Future<ArtifactMetadata?> downloadArtifactMetadata(MavenLookup lookup, [bool lookUpAtDefaultRepositories = true]) async {
    for (Repository repository in (lookUpAtDefaultRepositories ? defaultRepositories + lookup.repositories : lookup.repositories)) {
      String url = '${repository.url}${lookup.groupId.replaceAll('.', '/')}/${lookup.artifactId}/maven-metadata.xml';
      String? xml = await downloadXMLOrNull(url);
      if (xml != null) {
        return ArtifactMetadata.fromXml(repository, xml);
      }
    }
    return null;
  }

  static Future<ProjectObjectModel?> downloadPOM(MavenLookup lookup) async {
    VersionMetadata? versionMetadata = await downloadVersionMetadata(lookup);
    if (versionMetadata != null) {
      Repository repository = versionMetadata.repository;
      String url = '${repository.url}${lookup.groupId.replaceAll('.', '/')}/${lookup.artifactId}/${lookup.version}/${lookup.artifactId}-${lookup.version}.pom';
      String? xml = await downloadXMLOrNull(url);
      if (xml == null) {
        // the pom must have different versioning
        SnapshotVersion? targetVersion = versionMetadata.versioning.snapshotVersions.firstWhereOrNull((element) => element.extension == 'pom');
        if (targetVersion != null) {
          url =
              '${repository.url}${lookup.groupId.replaceAll('.', '/')}/${lookup.artifactId}/${lookup.version}/${lookup.artifactId}-${targetVersion.value}.pom';
          xml = await downloadXMLOrNull(url);
        }
      }
      if (xml != null) {
        return ProjectObjectModel.fromXml(repository, xml);
      }
    }
    return null;
  }

  static Future<void> _checkIntegrity(String url, List<int> bytes) async {
    String md5Url = '$url.md5';
    String? md5Response = await downloadXMLOrNull(md5Url);
    if (md5Response != null) {
      String jarMd5 = md5.convert(bytes).toString();
      if (md5Response != jarMd5) {
        throw Exception('MD5 checksums do not match');
      }
    } else {
      String sha1Url = '$url.sha1';
      String? sha1Response = await downloadXMLOrNull(sha1Url);
      if (sha1Response != null) {
        String jarSha1 = sha1.convert(bytes).toString();
        if (sha1Response != jarSha1) {
          throw Exception('SHA1 checksums do not match');
        }
      }
    }
  }

  static Future<MavenLookupResult?> downloadJAR(MavenLookup lookup, [bool checkIntegrity = false, bool shadeDependencies = false]) async {
    VersionMetadata? versionMetadata = await downloadVersionMetadata(lookup);
    if (versionMetadata != null) {
      Repository repository = versionMetadata.repository;
      String url = '${repository.url}${lookup.groupId.replaceAll('.', '/')}/${lookup.artifactId}/${lookup.version}/${lookup.artifactId}-${lookup.version}.jar';
      var response = await get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<int> bytes = response.bodyBytes;
        if (checkIntegrity) {
          await _checkIntegrity(url, bytes);
        }
        return null;
      } else {
        SnapshotVersion? targetVersion = versionMetadata.versioning.snapshotVersions.firstWhereOrNull((element) => element.extension == 'jar');
        if (targetVersion != null) {
          url =
              '${repository.url}${lookup.groupId.replaceAll('.', '/')}/${lookup.artifactId}/${lookup.version}/${lookup.artifactId}-${targetVersion.value}.jar';
          response = await get(Uri.parse(url));
          List<int> bytes = response.bodyBytes;
          if (response.statusCode == 200) {
            if (checkIntegrity) {
              await _checkIntegrity(url, bytes);
            }
            return null;
          }
        }
      }
    }
    return null;
  }
}
