import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/season.dart';
import 'package:mobile_app/models/harvest.dart';

void main() {
  group('Season Model & Target Realization Tests', () {
    test('Season.fromJson parses harvests_sum_weight_kg correctly', () {
      final json = {
        'id': 1,
        'name': 'Musim Hujan',
        'start_date': '2026-06-01',
        'end_date': '2026-09-20',
        'status': 'active',
        'target_kg': '200.00',
        'harvests_sum_weight_kg': '2000.00',
        'computed_status': 'active',
      };

      final season = Season.fromJson(json);

      expect(season.id, 1);
      expect(season.targetKg, 200.0);
      expect(season.totalPanen, 2000.0);
    });

    test('Season.fromJson supports fallback total_harvest_kg if present', () {
      final json = {
        'id': 2,
        'name': 'Musim Kemarau',
        'start_date': '2026-01-01',
        'end_date': '2026-05-31',
        'status': 'completed',
        'target_kg': '500.00',
        'total_harvest_kg': '750.50',
      };

      final season = Season.fromJson(json);

      expect(season.totalPanen, 750.5);
    });

    test('Multiple harvests for season are summed by weightKg', () {
      final harvestA = Harvest(
        id: 1,
        seasonId: 10,
        seasonName: 'Musim Hujan',
        quantity: 1,
        weightKg: 2000.0,
        harvestDate: '2026-08-29',
        notes: '',
        photo: '',
        status: 'recorded',
      );

      final harvestB = Harvest(
        id: 2,
        seasonId: 10,
        seasonName: 'Musim Hujan',
        quantity: 1,
        weightKg: 500.0,
        harvestDate: '2026-09-01',
        notes: '',
        photo: '',
        status: 'recorded',
      );

      final harvestOtherSeason = Harvest(
        id: 3,
        seasonId: 99,
        seasonName: 'Musim Lain',
        quantity: 1,
        weightKg: 300.0,
        harvestDate: '2026-07-01',
        notes: '',
        photo: '',
        status: 'recorded',
      );

      final harvests = [harvestA, harvestB, harvestOtherSeason];

      // Replicating _getActualForSeason logic
      double getActualForSeason(int targetSeasonId) {
        double total = 0;
        for (var h in harvests) {
          if (h.seasonId == targetSeasonId) {
            total += h.weightKg;
          }
        }
        return total;
      }

      final actualSeason10 = getActualForSeason(10);
      expect(actualSeason10, 2500.0);

      // Verify distinct visual progress vs true numerical achievement
      const double target = 200.0;
      final progress = (actualSeason10 / target).clamp(0.0, 1.0);
      final achievementPct = (actualSeason10 / target) * 100;

      expect(progress, 1.0); // Visual progress bar is capped at 100%
      expect(achievementPct, 1250.0); // True numerical achievement is 1250.0%
    });
  });
}
