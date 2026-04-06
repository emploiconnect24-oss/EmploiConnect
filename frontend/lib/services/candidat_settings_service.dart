import 'dart:convert';
import 'api_service.dart';

class CandidatSettingsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getSettings() async {
    final res = await _api.get('/candidat/parametres', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur chargement paramètres',
      );
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<void> updateConfidentialite({
    bool? profilVisible,
    bool? recevoirPropositions,
    bool? visibleRechercheTalents,
    bool? candidaturesConfidentielles,
  }) async {
    final res = await _api.patch(
      '/candidat/parametres/confidentialite',
      useAuth: true,
      body: {
        if (profilVisible != null) 'profil_visible': profilVisible,
        if (recevoirPropositions != null)
          'recevoir_propositions': recevoirPropositions,
        if (visibleRechercheTalents != null)
          'visible_recherche_talents': visibleRechercheTalents,
        if (candidaturesConfidentielles != null)
          'candidatures_confidentielles': candidaturesConfidentielles,
      },
    );
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur mise à jour confidentialité',
      );
    }
  }

  Future<void> updateProfil({
    String? nom,
    String? telephone,
    String? adresse,
    String? langueInterface,
    String? fuseauHoraire,
    String? disponibilite,
  }) async {
    final body = <String, dynamic>{
      if (nom != null) 'nom': nom,
      if (telephone != null) 'telephone': telephone,
      if (adresse != null) 'adresse': adresse,
      if (langueInterface != null) 'langue_interface': langueInterface,
      if (fuseauHoraire != null) 'fuseau_horaire': fuseauHoraire,
      if (disponibilite != null) 'disponibilite': disponibilite,
    };
    if (body.isEmpty) return;
    final res = await _api.patch(
      '/candidat/parametres/profil',
      useAuth: true,
      body: body,
    );
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur mise à jour profil',
      );
    }
  }

  Future<void> updateRechercheEmploi({
    required List<String> typesContrat,
    required List<String> villes,
    required List<String> secteurs,
    String? salaireSouhaite,
  }) async {
    final res = await _api.patch(
      '/candidat/parametres/recherche-emploi',
      useAuth: true,
      body: {
        'types_contrat': typesContrat,
        'villes': villes,
        'secteurs': secteurs,
        'salaire_souhaite': salaireSouhaite,
      },
    );
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur préférences de recherche',
      );
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final res = await _api.patch(
      '/candidat/parametres/mot-de-passe',
      useAuth: true,
      body: {
        'ancien_mot_de_passe': oldPassword,
        'nouveau_mot_de_passe': newPassword,
      },
    );
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur mise à jour mot de passe',
      );
    }
  }
}
