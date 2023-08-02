import 'package:nodeflow/objects.dart';
import 'package:xml/xml.dart';

import 'maven_pom.dart';

class ArtifactMetadata {
  final Repository repository;
  final String groupId;
  final String artifactId;
  final ArtifactVersioning versioning;

  ArtifactMetadata(this.repository, this.groupId, this.artifactId, this.versioning);

  factory ArtifactMetadata.fromXml(Repository repository, String xml) {
    XmlDocument document = XmlDocument.parse(xml);
    XmlElement metadata = document.rootElement;
    String groupId = Objects.nonNull(metadata.findElements('groupId').firstOrNull?.innerText, 'groupId');
    String artifactId = Objects.nonNull(metadata.findElements('artifactId').firstOrNull?.innerText, 'artifactId');
    XmlElement versioning = Objects.nonNull(metadata.findElements('versioning').firstOrNull, 'versioning');
    String latest = Objects.nonNull(versioning.findElements('latest').firstOrNull?.innerText, 'latest');
    String release = Objects.nonNull(versioning.findElements('release').firstOrNull?.innerText, 'release');
    String lastUpdated = Objects.nonNull(versioning.findElements('lastUpdated').firstOrNull?.innerText, 'lastUpdated');
    List<String> versions = versioning.findElements('versions').map((e) => Objects.nonNull(e.innerText, 'version')).toList();
    return ArtifactMetadata(repository, groupId, artifactId, ArtifactVersioning(latest, release, versions, lastUpdated));
  }
}

class ArtifactVersioning {
  final String latest;
  final String release;
  final List<String> versions;
  final String lastUpdated;

  ArtifactVersioning(this.latest, this.release, this.versions, this.lastUpdated);
}

class VersionMetadata {
  final Repository repository;
  final String groupId;
  final String artifactId;
  final VersionVersioning versioning;

  VersionMetadata(this.repository, this.groupId, this.artifactId, this.versioning);

  factory VersionMetadata.fromXml(Repository repository, String xml) {
    XmlDocument document = XmlDocument.parse(xml);
    XmlElement metadata = document.rootElement;
    String groupId = Objects.nonNull(metadata.findElements('groupId').firstOrNull?.innerText, 'groupId');
    String artifactId = Objects.nonNull(metadata.findElements('artifactId').firstOrNull?.innerText, 'artifactId');
    XmlElement versioning = Objects.nonNull(metadata.findElements('versioning').firstOrNull, 'versioning');
    XmlElement snapshot = Objects.nonNull(versioning.findElements('snapshot').firstOrNull, 'snapshot');
    String timestamp = Objects.nonNull(snapshot.findElements('timestamp').firstOrNull?.innerText, 'timestamp');
    String buildNumber = Objects.nonNull(snapshot.findElements('buildNumber').firstOrNull?.innerText, 'buildNumber');
    String lastUpdated = Objects.nonNull(versioning.findElements('lastUpdated').firstOrNull?.innerText, 'lastUpdated');
    List<SnapshotVersion> snapshotVersions = versioning.findElements('snapshotVersions').firstOrNull?.findElements('snapshotVersion').map((e) {
          String extension = Objects.nonNull(e.findElements('extension').firstOrNull?.innerText, 'extension');
          String value = Objects.nonNull(e.findElements('value').firstOrNull?.innerText, 'value');
          String updated = Objects.nonNull(e.findElements('updated').firstOrNull?.innerText, 'updated');
          return SnapshotVersion(extension, value, updated);
        }).toList() ??
        [];
    return VersionMetadata(repository, groupId, artifactId, VersionVersioning(Snapshot(timestamp, buildNumber), snapshotVersions, lastUpdated));
  }
}

class VersionVersioning {
  final Snapshot snapshot;
  final List<SnapshotVersion> snapshotVersions;
  final String lastUpdated;

  VersionVersioning(this.snapshot, this.snapshotVersions, this.lastUpdated);
}

class Snapshot {
  final String timestamp;
  final String buildNumber;

  Snapshot(this.timestamp, this.buildNumber);
}

class SnapshotVersion {
  final String extension;
  final String value;
  final String updated;

  SnapshotVersion(this.extension, this.value, this.updated);
}
