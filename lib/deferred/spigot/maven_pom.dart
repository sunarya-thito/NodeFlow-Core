import 'package:nodeflow/objects.dart';
import 'package:xml/xml.dart';

class Repository {
  final String id;
  final String? name;
  final String url;
  final String layout;

  const Repository({
    required this.id,
    this.name,
    required this.url,
    this.layout = 'default',
  });
}

class Exclusion {
  final String groupId;
  final String artifactId;

  const Exclusion({
    required this.groupId,
    required this.artifactId,
  });
}

class Dependency {
  final String groupId;
  final String artifactId;
  final String version;
  final String scope;
  final String? classifier;
  final String type;
  final String? systemPath;
  final String optional;
  final List<Exclusion>? exclusions;

  const Dependency({
    required this.groupId,
    required this.artifactId,
    required this.version,
    this.scope = 'compile',
    this.classifier,
    this.type = 'jar',
    this.systemPath,
    this.optional = 'false',
    this.exclusions,
  });
}

class Organization {
  final String name;
  final String? url;

  const Organization({
    required this.name,
    this.url,
  });
}

class License {
  final String name;
  final String? url;
  final String? distribution;
  final String? comments;

  const License({
    required this.name,
    this.url,
    this.distribution,
    this.comments,
  });
}

class Contributor {
  final String? name;
  final String? email;
  final String? url;
  final String? organization;
  final String? organizationUrl;
  final String? roles;
  final String? timezone;
  final Map<String, String>? properties;

  const Contributor({
    this.name,
    this.email,
    this.url,
    this.organization,
    this.organizationUrl,
    this.roles,
    this.timezone,
    this.properties,
  });
}

class Developer extends Contributor {
  final String id;

  const Developer({
    required this.id,
    super.name,
    super.email,
    super.url,
    super.organization,
    super.organizationUrl,
    super.roles,
    super.timezone,
    super.properties,
  });
}

class ProjectObjectModel {
  factory ProjectObjectModel.fromXml(Repository repository, String xml) {
    XmlDocument document = XmlDocument.parse(xml);
    XmlElement project = document.rootElement;

    String groupId = Objects.nonNull(project.findElements('groupId').firstOrNull?.innerText, 'groupId');
    String artifactId = Objects.nonNull(project.findElements('artifactId').firstOrNull?.innerText, 'artifactId');
    String version = Objects.nonNull(project.findElements('version').firstOrNull?.innerText, 'version');
    String packaging = Objects.nonNull(project.findElements('packaging').firstOrNull?.innerText, 'packaging');

    String? name = project.findElements('name').firstOrNull?.innerText;
    String? description = project.findElements('description').firstOrNull?.innerText;
    String? url = project.findElements('url').firstOrNull?.innerText;
    String? inceptionYear = project.findElements('inceptionYear').firstOrNull?.innerText;

    XmlElement? organizationElement = project.findElements('organization').firstOrNull;
    Organization? organization;
    if (organizationElement != null) {
      String organizationName = Objects.nonNull(organizationElement.findElements('name').firstOrNull?.innerText, 'organization.name');
      String? organizationUrl = organizationElement.findElements('url').firstOrNull?.innerText;
      organization = Organization(
        name: organizationName,
        url: organizationUrl,
      );
    }

    List<License>? licenses;
    List<XmlElement> licenseElements = project.findElements('licenses').firstOrNull?.findElements('license').toList() ?? [];
    if (licenseElements.isNotEmpty) {
      licenses = [];
      for (XmlElement licenseElement in licenseElements) {
        String licenseName = Objects.nonNull(licenseElement.findElements('name').firstOrNull?.innerText, 'license.name');
        String? licenseUrl = licenseElement.findElements('url').firstOrNull?.innerText;
        String? licenseDistribution = licenseElement.findElements('distribution').firstOrNull?.innerText;
        String? licenseComments = licenseElement.findElements('comments').firstOrNull?.innerText;
        licenses.add(License(
          name: licenseName,
          url: licenseUrl,
          distribution: licenseDistribution,
          comments: licenseComments,
        ));
      }
    }

    List<Developer>? developers;
    List<XmlElement> developerElements = project.findElements('developers').firstOrNull?.findElements('developer').toList() ?? [];
    if (developerElements.isNotEmpty) {
      developers = [];
      for (XmlElement developerElement in developerElements) {
        String developerId = Objects.nonNull(developerElement.findElements('id').firstOrNull?.innerText, 'developer.id');
        String? developerName = developerElement.findElements('name').firstOrNull?.innerText;
        String? developerEmail = developerElement.findElements('email').firstOrNull?.innerText;
        String? developerUrl = developerElement.findElements('url').firstOrNull?.innerText;
        String? developerOrganization = developerElement.findElements('organization').firstOrNull?.innerText;
        String? developerOrganizationUrl = developerElement.findElements('organizationUrl').firstOrNull?.innerText;
        String? developerRoles = developerElement.findElements('roles').firstOrNull?.innerText;
        String? developerTimezone = developerElement.findElements('timezone').firstOrNull?.innerText;
        Map<String, String>? developerProperties;
        List<XmlElement> developerPropertyElements = developerElement.findElements('properties').firstOrNull?.findElements('property').toList() ?? [];
        if (developerPropertyElements.isNotEmpty) {
          developerProperties = {};
          for (XmlElement developerPropertyElement in developerPropertyElements) {
            String developerPropertyName = Objects.nonNull(developerPropertyElement.findElements('name').firstOrNull?.innerText, 'developer.property.name');
            String developerPropertyValue =
                Objects.nonNull(developerPropertyElement.findElements('value').firstOrNull?.innerText, 'developer.property.innerText');
            developerProperties[developerPropertyName] = developerPropertyValue;
          }
        }
        developers.add(Developer(
          id: developerId,
          name: developerName,
          email: developerEmail,
          url: developerUrl,
          organization: developerOrganization,
          organizationUrl: developerOrganizationUrl,
          roles: developerRoles,
          timezone: developerTimezone,
          properties: developerProperties,
        ));
      }
    }

    List<Contributor>? contributors;
    List<XmlElement> contributorElements = project.findElements('contributors').firstOrNull?.findElements('contributor').toList() ?? [];
    if (contributorElements.isNotEmpty) {
      contributors = [];
      for (XmlElement contributorElement in contributorElements) {
        String? contributorName = contributorElement.findElements('name').firstOrNull?.innerText;
        String? contributorEmail = contributorElement.findElements('email').firstOrNull?.innerText;
        String? contributorUrl = contributorElement.findElements('url').firstOrNull?.innerText;
        String? contributorOrganization = contributorElement.findElements('organization').firstOrNull?.innerText;
        String? contributorOrganizationUrl = contributorElement.findElements('organizationUrl').firstOrNull?.innerText;
        String? contributorRoles = contributorElement.findElements('roles').firstOrNull?.innerText;
        String? contributorTimezone = contributorElement.findElements('timezone').firstOrNull?.innerText;
        Map<String, String>? contributorProperties;
        List<XmlElement> contributorPropertyElements = contributorElement.findElements('properties').firstOrNull?.findElements('property').toList() ?? [];
        if (contributorPropertyElements.isNotEmpty) {
          contributorProperties = {};
          for (XmlElement contributorPropertyElement in contributorPropertyElements) {
            String contributorPropertyName =
                Objects.nonNull(contributorPropertyElement.findElements('name').firstOrNull?.innerText, 'contributor.property.name');
            String contributorPropertyValue =
                Objects.nonNull(contributorPropertyElement.findElements('value').firstOrNull?.innerText, 'contributor.property.innerText');
            contributorProperties[contributorPropertyName] = contributorPropertyValue;
          }
        }
        contributors.add(Contributor(
          name: contributorName,
          email: contributorEmail,
          url: contributorUrl,
          organization: contributorOrganization,
          organizationUrl: contributorOrganizationUrl,
          roles: contributorRoles,
          timezone: contributorTimezone,
          properties: contributorProperties,
        ));
      }
    }

    Map<String, String> properties = {};
    List<XmlElement> propertyElements = project.findElements('properties').firstOrNull?.findElements('property').toList() ?? [];
    if (propertyElements.isNotEmpty) {
      for (XmlElement propertyElement in propertyElements) {
        String propertyName = Objects.nonNull(propertyElement.findElements('name').firstOrNull?.innerText, 'property.name');
        String propertyValue = Objects.nonNull(propertyElement.findElements('value').firstOrNull?.innerText, 'property.innerText');
        properties[propertyName] = propertyValue;
      }
    }

    List<Dependency> dependencies = [];
    List<XmlElement> dependencyElements = project.findElements('dependencies').firstOrNull?.findElements('dependency').toList() ?? [];
    if (dependencyElements.isNotEmpty) {
      for (XmlElement dependencyElement in dependencyElements) {
        String groupId = Objects.nonNull(dependencyElement.findElements('groupId').firstOrNull?.innerText, 'dependency.groupId');
        String artifactId = Objects.nonNull(dependencyElement.findElements('artifactId').firstOrNull?.innerText, 'dependency.artifactId');
        String version = Objects.nonNull(dependencyElement.findElements('version').firstOrNull?.innerText, 'dependency.version');
        String? type = dependencyElement.findElements('type').firstOrNull?.innerText;
        String? classifier = dependencyElement.findElements('classifier').firstOrNull?.innerText;
        String? scope = dependencyElement.findElements('scope').firstOrNull?.innerText;
        String? systemPath = dependencyElement.findElements('systemPath').firstOrNull?.innerText;
        String? optional = dependencyElement.findElements('optional').firstOrNull?.innerText;
        List<XmlElement> exclusionElements = dependencyElement.findElements('exclusions').firstOrNull?.findElements('exclusion').toList() ?? [];
        List<Exclusion>? exclusions;
        if (exclusionElements.isNotEmpty) {
          exclusions = [];
          for (XmlElement exclusionElement in exclusionElements) {
            String exclusionGroupId = Objects.nonNull(exclusionElement.findElements('groupId').firstOrNull?.innerText, 'exclusion.groupId');
            String exclusionArtifactId = Objects.nonNull(exclusionElement.findElements('artifactId').firstOrNull?.innerText, 'exclusion.artifactId');
            exclusions.add(Exclusion(
              groupId: exclusionGroupId,
              artifactId: exclusionArtifactId,
            ));
          }
        }
        dependencies.add(Dependency(
          groupId: groupId,
          artifactId: artifactId,
          version: version,
          type: type ?? 'jar',
          classifier: classifier,
          scope: scope ?? 'compile',
          systemPath: systemPath,
          optional: optional ?? 'false',
          exclusions: exclusions,
        ));
      }
    }

    List<Repository> repositories = [];
    List<XmlElement> repositoryElements = project.findElements('repositories').firstOrNull?.findElements('repository').toList() ?? [];
    if (repositoryElements.isNotEmpty) {
      for (XmlElement repositoryElement in repositoryElements) {
        String repositoryId = Objects.nonNull(repositoryElement.findElements('id').firstOrNull?.innerText, 'repository.id');
        String repositoryName = Objects.nonNull(repositoryElement.findElements('name').firstOrNull?.innerText, 'repository.name');
        String repositoryUrl = Objects.nonNull(repositoryElement.findElements('url').firstOrNull?.innerText, 'repository.url');
        String? repositoryLayout = repositoryElement.findElements('layout').firstOrNull?.innerText;
        repositories.add(Repository(
          id: repositoryId,
          name: repositoryName,
          url: repositoryUrl,
          layout: repositoryLayout ?? 'default',
        ));
      }
    }

    return ProjectObjectModel(
      repository: repository,
      groupId: groupId,
      artifactId: artifactId,
      version: version,
      packaging: packaging,
      name: name,
      description: description,
      url: url,
      inceptionYear: inceptionYear,
      organization: organization,
      licenses: licenses,
      developers: developers,
      contributors: contributors,
      properties: properties,
      dependencies: dependencies,
      repositories: repositories,
    );
  }

  final Repository repository;

  final String groupId;
  final String artifactId;
  final String version;
  final String packaging;

  final String? name;
  final String? description;
  final String? url;
  final String? inceptionYear;
  final Organization? organization;
  final List<License>? licenses;
  final List<Developer>? developers;
  final List<Contributor>? contributors;

  final Map<String, String> properties;
  final List<Dependency> dependencies;
  final List<Repository> repositories;

  const ProjectObjectModel({
    required this.repository,
    required this.groupId,
    required this.artifactId,
    required this.version,
    required this.packaging,
    this.name,
    this.description,
    this.url,
    this.inceptionYear,
    this.organization,
    this.licenses,
    this.developers,
    this.contributors,
    this.properties = const {},
    this.dependencies = const [],
    this.repositories = const [],
  });
}
