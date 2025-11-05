import 'package:flutter_test/flutter_test.dart';
import '../lib/services/fongbe_translation_service.dart';

void main() {
  group('Test des commandes vocales d\'appel', () {
    final translationService = FongbeTranslationService();
    
    test('Devrait reconnaître "yolo jean"', () {
      final result = translationService.parseVoiceCommand('yolo jean');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('Jean'));
    });
    
    test('Devrait reconnaître "ylɔ paul"', () {
      final result = translationService.parseVoiceCommand('ylɔ paul');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('Paul'));
    });
    
    test('Devrait reconnaître "ɔlɔ marie"', () {
      final result = translationService.parseVoiceCommand('ɔlɔ marie');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('Marie'));
    });
    
    test('Devrait reconnaître "yɔlɔ kofí"', () {
      final result = translationService.parseVoiceCommand('yɔlɔ kofí');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('Kofi'));
    });
    
    test('Devrait reconnaître "alɔ pierre"', () {
      final result = translationService.parseVoiceCommand('alɔ pierre');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('pierre'));
    });
    
    test('Devrait reconnaître "elo antoine"', () {
      final result = translationService.parseVoiceCommand('elo antoine');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('antoine'));
    });
    
    test('Devrait reconnaître "yololuc" (sans espace)', () {
      final result = translationService.parseVoiceCommand('yololuc');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('luc'));
    });
    
    test('Devrait reconnaître "ylɔjean" (sans espace)', () {
      final result = translationService.parseVoiceCommand('ylɔjean');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('jean'));
    });
    
    test('Ne devrait pas reconnaître des commandes invalides', () {
      final result1 = translationService.parseVoiceCommand('bonjour');
      expect(result1['command'], isNull);
      
      final result2 = translationService.parseVoiceCommand('appeler jean');
      expect(result2['command'], isNull);
      
      final result3 = translationService.parseVoiceCommand('jean');
      expect(result3['command'], isNull);
    });
    
    test('Devrait gérer les majuscules', () {
      final result = translationService.parseVoiceCommand('YOLO JEAN');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('Jean'));
    });
    
    test('Devrait traduire les noms fongbé', () {
      final result = translationService.parseVoiceCommand('yolo kɔku');
      expect(result['command'], equals('call'));
      expect(result['parameter'], equals('Koku'));
    });
  });
}
