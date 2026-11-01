import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Privacy Policy',
      sections: [
        _LegalSection(
          'Privacy by design',
          'CareerSpeak does not require an account and does not ask for your name, email address, phone number, contacts, precise location, advertising identifier, or social-login profile to use the learning experience.',
        ),
        _LegalSection(
          'Installation identity',
          'The app may create a random installation identifier and an installation credential. They are used for app security, synchronization, recovery, and other core app functionality. The credential is stored using platform secure storage. The identifier is pseudonymous and is not intended to reveal your real-world identity.',
        ),
        _LegalSection(
          'Learning data',
          'The app may process learning state such as favorites, listened and completed status, playback position, practice-test attempts, selected country or language, preferred accent, theme, synchronization state, and locally downloaded content. This data is used only to provide and restore learning functionality.',
        ),
        _LegalSection(
          'Data minimization',
          'CareerSpeak is designed to avoid collecting information that is not required for the learning service. We do not use the installation identity or learning state for cross-app advertising or behavioral advertising.',
        ),
        _LegalSection(
          'Sharing',
          'Data is not sold. Service providers may process limited technical data only when required to operate infrastructure, deliver content, provide security, or diagnose failures. Any production provider must be reviewed against this policy before release.',
        ),
        _LegalSection(
          'Retention and deletion',
          'Local learning data remains on the device until it is removed by app functionality, application storage is cleared, or the app is uninstalled, subject to platform behavior. Server-side installation and learning state must be retained only for the documented service purpose and deleted when no longer required or when a valid deletion request applies, subject to legal obligations.',
        ),
        _LegalSection(
          'Security',
          'Release builds require HTTPS for API communication. Installation credentials are stored using platform secure storage. The app is designed to expose learner-safe errors instead of backend secrets, filesystem details, or credentials.',
        ),
        _LegalSection(
          'Your choices',
          'You can stop using the service, clear local application data through your platform, and use the privacy contact published with the application to request information about or deletion of server-side data associated with the current installation where applicable.',
        ),
        _LegalSection(
          'Children',
          'The initial public release is not designed as a child-directed service. Store age-rating and audience declarations must match the released product and applicable regional requirements.',
        ),
        _LegalSection(
          'Controller and contact',
          'The legally responsible publisher name, privacy contact, public policy URL, effective date, and applicable regional disclosures are maintained in the public Privacy Policy published with each production release. The release process must not be approved until those fields are complete and publicly reachable.',
        ),
      ],
    );
  }
}

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Terms of Use',
      sections: [
        _LegalSection(
          'Service',
          'CareerSpeak provides educational content and practice tools. The service is provided for learning and informational purposes and is not a guarantee of employment, examination results, professional certification, or any specific outcome.',
        ),
        _LegalSection(
          'No account required',
          'The current service uses an installation-based identity rather than a personal account. You are responsible for maintaining access to your device. Reinstalling the application or clearing application data may remove locally stored state.',
        ),
        _LegalSection(
          'Acceptable use',
          'You may not interfere with service security, attempt unauthorized access, abuse infrastructure, distribute malicious content through the service, or use the service in violation of applicable law.',
        ),
        _LegalSection(
          'Content and intellectual property',
          'Application software, original educational content, branding, and other protected materials remain owned by or licensed to the publisher. Third-party materials may be used only under their applicable licenses.',
        ),
        _LegalSection(
          'Availability',
          'Offline functionality may remain available for previously downloaded content, but synchronization, new content, and some recovery operations require network access and available backend services.',
        ),
        _LegalSection(
          'Changes',
          'The service, content catalog, and these terms may change. Material policy changes should be published with an updated effective date and, where required, presented to users before the changed processing applies.',
        ),
        _LegalSection(
          'Applicable terms',
          'The final public Terms of Use must identify the legal publisher, governing-law provisions appropriate to the distribution model, support contact, effective date, and any store-specific commercial terms before production approval.',
        ),
      ],
    );
  }
}

class DataAndPrivacyScreen extends StatelessWidget {
  const DataAndPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScreen(
      title: 'Data & Privacy',
      sections: [
        _LegalSection(
          'We do not ask for direct identity data',
          'No name, email address, phone number, social-login profile, contacts, precise location, or advertising identifier is required by the current product design.',
        ),
        _LegalSection(
          'What can exist on this device',
          'Application preferences, offline content metadata and files, learner markers, playback position, practice-test state, synchronization metadata, and a pseudonymous installation credential may be stored locally.',
        ),
        _LegalSection(
          'What can be synchronized',
          'When backend synchronization is enabled, the service may associate a pseudonymous installation identifier with the minimum learner and synchronization state required to provide continuity and recovery.',
        ),
        _LegalSection(
          'What we deliberately avoid',
          'The product design does not require advertising IDs, contact lists, precise location, microphone recordings, photos, social graphs, or a real-world identity for normal learning functionality.',
        ),
        _LegalSection(
          'Deletion',
          'Clearing application data or uninstalling the app affects local data but does not by itself prove deletion of server-side records. The production backend and public policy must provide a documented mechanism for deletion requests associated with an installation where such server-side records exist.',
        ),
      ],
    );
  }
}

class _LegalDocumentScreen extends StatelessWidget {
  const _LegalDocumentScreen({required this.title, required this.sections});

  final String title;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final section in sections) ...[
            Text(section.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(section.body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}
