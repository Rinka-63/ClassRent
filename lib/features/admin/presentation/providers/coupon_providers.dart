import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/entities/coupon.dart';

final agencyCouponsProvider = FutureProvider<List<Coupon>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  if (supabase == null) throw Exception('Supabase not initialized');
  final session = supabase.auth.currentSession;
  if (session == null) throw Exception('Not authenticated');

  final userId = session.user.id;

  // Cek apakah user adalah SUPER_ADMIN
  final userDoc = await supabase.from('users').select('role').eq('id', userId).single();
  final isSuperAdmin = userDoc['role'] == 'SUPER_ADMIN';

  final response = await supabase
      .from('coupons')
      .select()
      .or(isSuperAdmin ? 'created_by.is.null,created_by.not.is.null' : 'created_by.eq.$userId')
      .order('created_at', ascending: false);

  return (response as List).map((json) => Coupon.fromJson(json)).toList();
});

class CouponRepository {
  final dynamic _supabase;
  CouponRepository(this._supabase);

  Future<void> createCoupon(Map<String, dynamic> data) async {
    final client = _supabase;
    if (client == null) throw Exception('Supabase not initialized');
    final session = client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final userId = session.user.id;
    final userDoc = await client.from('users').select('role').eq('id', userId).single();
    final isSuperAdmin = userDoc['role'] == 'SUPER_ADMIN';

    // If not super admin, force created_by to be their own id
    if (!isSuperAdmin) {
      data['created_by'] = userId;
    }

    await client.from('coupons').insert(data);
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> data) async {
    if (_supabase == null) throw Exception('Supabase not initialized');
    await _supabase.from('coupons').update(data).eq('id', id);
  }

  Future<void> deleteCoupon(String id) async {
    if (_supabase == null) throw Exception('Supabase not initialized');
    await _supabase.from('coupons').delete().eq('id', id);
  }

  Future<Either<Exception, List<Coupon>>> getAllCoupons() async {
    try {
      final client = _supabase;
      if (client == null) return Left(Exception('Supabase not initialized'));
      final session = client.auth.currentSession;
      if (session == null) return Left(Exception('Not authenticated'));
      
      final userId = session.user.id;

      // 1. Dapatkan kupon yang diklaim oleh user ini (user_coupons)
      final userCouponsRes = await client
          .from('user_coupons')
          .select('coupon_id')
          .eq('user_id', userId)
          .eq('is_used', false);
          
      final List<dynamic> claimedIds = userCouponsRes;
      final uuids = claimedIds.map((c) => c['coupon_id']).toList();
      
      // 2. Dapatkan kupon aktif
      final response = await client.from('coupons').select().eq('is_active', true);
      final allCoupons = (response as List).map((json) => Coupon.fromJson(json)).toList();
      
      // Filter valid kupon: validUntil == null atau > now
      final now = DateTime.now();
      final validCoupons = allCoupons.where((c) {
        if (c.validUntil != null && c.validUntil!.isBefore(now)) return false;
        // Tampilkan jika global (createdBy null) atau jika user telah mengklaimnya
        if (c.createdBy == null) return true;
        if (uuids.contains(c.id)) return true;
        return true; 
      }).toList();

      return Right(validCoupons);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepository(ref.watch(supabaseClientProvider));
});
