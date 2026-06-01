# ClassRent Complete ERD

```mermaid
erDiagram
    auth_users ||--|| users : "auth profile"
    users ||--o{ facilities : owns
    facilities ||--o{ rooms : contains
    users ||--o{ rooms : administers
    rooms ||--o{ room_facilities : has
    rooms ||--o{ room_images : has
    facilities ||--o{ pricing_rules : scopes
    rooms ||--o{ pricing_rules : overrides
    facilities ||--o{ coupons : offers
    users ||--o{ coupons : creates
    users ||--o{ bookings : makes
    rooms ||--o{ bookings : reserved_for
    facilities ||--o{ bookings : scoped_to
    coupons ||--o{ bookings : applied_to
    bookings ||--o{ payments : paid_by
    payments ||--o{ payment_logs : audited_by
    payments ||--o{ payment_refunds : refunded_by
    coupons ||--o{ coupon_redemptions : redeemed_as
    users ||--o{ coupon_redemptions : redeems
    bookings ||--o{ coupon_redemptions : uses
    rooms ||--o{ room_schedules : has
    facilities ||--o{ blackout_dates : may_define
    rooms ||--o{ maintenance_schedules : blocks
    rooms ||--o{ reviews : receives
    bookings ||--|| reviews : reviewed_once
    users ||--o{ reviews : writes
    users ||--o{ notifications : receives
    users ||--o{ audit_logs : acts
    users ||--o{ user_favorites : favorites
    rooms ||--o{ user_favorites : favorited
    rooms ||--o{ waitlist : waited_for
    users ||--o{ waitlist : joins
    users ||--o{ user_sessions : has
    users ||--o{ user_consents : accepts
    users ||--o{ support_tickets : opens
    facilities ||--o{ support_tickets : assigned_to
    bookings ||--o{ support_tickets : related_to
    support_tickets ||--o{ ticket_messages : contains
    users ||--o{ ticket_messages : sends

    users {
      uuid id PK
      text email UK
      text full_name
      text role
      boolean is_verified
      text fcm_token
      timestamptz deleted_at
      timestamptz anonymized_at
    }
    facilities {
      uuid id PK
      uuid admin_id FK
      text name
      text slug UK
      text city
      boolean is_active
    }
    rooms {
      uuid id PK
      uuid facility_id FK
      uuid admin_id FK
      text name
      text room_type
      int capacity
      numeric hourly_rate
      int dp_percentage
      boolean requires_approval
      tsvector search_vector
      timestamptz deleted_at
    }
    bookings {
      uuid id PK
      uuid user_id FK
      uuid room_id FK
      uuid facility_id FK
      date booking_date
      time start_time
      time end_time
      numeric final_price
      text status
      text qr_token UK
      timestamptz expires_at
    }
    payments {
      uuid id PK
      uuid booking_id FK
      uuid user_id FK
      numeric amount
      text midtrans_order_id UK
      text status
      boolean is_dp
    }
    coupons {
      uuid id PK
      uuid facility_id FK
      text code UK
      text discount_type
      numeric discount_value
      int usage_limit
      int usage_count
    }
    support_tickets {
      uuid id PK
      uuid user_id FK
      uuid facility_id FK
      uuid booking_id FK
      text category
      text status
      text priority
    }
```

## Notes
- `facilities` are the top-level multi-tenant boundary; admins own facilities, staff access is scoped through `staff_room_assignments`.
- `bookings` uses a PostgreSQL `EXCLUDE` constraint to prevent overlapping active bookings for the same room.
- `room_analytics` is a materialized view refreshed by cron in production.
- All app tables have RLS enabled; service-role Edge Functions perform privileged payment, QR, image, and role-management flows.
