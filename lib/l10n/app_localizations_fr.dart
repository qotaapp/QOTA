// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Qota';

  @override
  String get navHome => 'Accueil';

  @override
  String get navEvaluer => 'Évaluer';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profil';

  @override
  String get navMenu => 'Menu';

  @override
  String get searchHint => 'Rechercher un service, un lieu...';

  @override
  String get loginEmailOrAddress => 'E-mail ou Adresse';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginButton => 'Connexion';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccountYet => 'Pas encore de compte';

  @override
  String get socialLogin => 'Connexion avec Facebook/Gmail';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get accountCreatedSuccess => 'Compte créé avec succès';

  @override
  String get stateLabel => 'État';

  @override
  String get cityZoneLabel => 'Ville / Zone';

  @override
  String get categoryLabel => 'Catégorie';

  @override
  String get serviceAlreadyExists => 'Cette service semble déjà exister.';

  @override
  String get viewService => 'Voir la service';

  @override
  String get requestOwnership => 'Demander la propriété';

  @override
  String get rateAction => 'Évaluer';

  @override
  String get commentHint => 'Votre avis...';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get publish => 'Publier';
}
