# ClassRent Flutter Foundation

This project foundation follows the ClassRent Final Blueprint v2.0 and the existing Supabase migrations.

## Structure

```text
lib/
  core/
    config/
    constants/
    error/
    network/
    router/
    supabase/
    theme/
    utils/
    widgets/
  shared/
    data/dto/
    domain/entities/
    presentation/widgets/
  features/
    admin/
    auth/
    booking/
    favorites/
    home/
    notifications/
    payments/
    profile/
    reviews/
    rooms/
    search/
    support_tickets/
```

## Notes

- The app uses Riverpod providers, GoRouter routing, Supabase service/repository boundaries, and feature-first Clean Architecture.
- Domain entities use the existing table names and column shapes from `supabase/migrations`.
- Presentation screens are intentionally starter screens. They reuse the Stitch design tokens and navigation language, but full business logic is deferred.
- Supabase credentials are loaded via `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
