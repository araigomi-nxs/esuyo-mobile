# ESUYO DATABASE SCHEMA DESIGN

## Core Entity Relationship Diagram (ERD)

```
┌─────────────────────┐         ┌──────────────────┐
│      USERS          │         │   PASSENGERS     │
├─────────────────────┤    1    ├──────────────────┤
│ id (PK)             ├─────────│ id (FK→users)    │
│ user_type (enum)    │    M    │ emergency_contact│
│ phone_number (U)    │         │ preferred_payment│
│ email (U)           │         │ rating           │
│ password_hash       │         │ trip_count       │
│ full_name           │         │ created_at       │
│ username (U)        │         └──────────────────┘
│ dob                 │                 │
│ address             │                 │ 1
│ profile_photo_url   │                 ├──────────────────┐
│ status              │                 │                  │ M
│ created_at          │         ┌───────▼─────────────┐   │
│ updated_at          │         │  WALLET_ACCOUNTS    │   │
└─────────────────────┘         ├─────────────────────┤   │
   │                      │ id (PK)             │   │
   │              ┌───────│ user_id (FK)        │   │
   │              │       │ balance             │   │
   │              │       │ currency            │   │
   │              │       │ last_transaction    │   │
   │              │       │ updated_at          │   │
   │              │       └─────────────────────┘   │
   │              │               │                  │
   │              │               │ 1                │
   │              │       ┌───────▼──────────────┐   │
   │              │       │ WALLET_TRANSACTIONS  │   │
   │              │       ├────────────────────┤   │
   │              │       │ id (PK)             │   │
   │              │       │ wallet_id (FK)      │   │
   │              │       │ type (top_up/spend) │   │
   │              │       │ amount              │   │
   │              │       │ description         │   │
   │              │       │ reference           │   │
   │              │       │ status              │   │
   │              │       │ created_at          │   │
   │              │       └────────────────────┘   │
   │              │                                  │
   │ 1            │                           ┌─────▼──────────┐
   ├─────────────────────────────────────────│  FAVORITE_ROUTES │
   │ M            │                           ├──────────────────┤
   │              │                           │ id (PK)          │
   │              │                           │ user_id (FK)     │
   │              │                           │ route_id (FK)    │
   │              │                           │ alias            │
   │              │                           │ added_at         │
   │              │                           └──────────────────┘
   │              │
   │ 1            │
    ┌────▼──────────┐   │
    │    DRIVERS    │   │
    ├───────────────┤   │
    │ id (FK→users) │   │
    │ license_no(U) │   │
    │ license_exp   │   │
    │ selfie_url    │   │
    │ status        │   │
    │ rating        │   │
    │ trip_count    │   │
    │ tier          │   │
    └───────┬───────┘   │
      │           │
      │ 1     ┌────▼─────────────┐
      │       │  TRIP_HISTORY    │
      │       ├──────────────────┤
      │       │ id (PK)          │
      │       │ passenger_id(FK) │
      │       │ driver_id (FK)   │
      │       │ route_id (FK)    │
      │       │ jeepney_id (FK)  │
      │       │ start_location   │
      │       │ end_location     │
      │       │ distance_km      │
      │       │ duration_minutes │
      │       │ fare             │
      │       │ payment_method   │
      │       │ status           │
      │       │ rating           │
      │       │ review           │
      │       │ created_at       │
      │       │ completed_at     │
      │       └──────────────────┘
      │
      │ M
    ┌───────▼────────────────┐
    │  DRIVER_JEEPNEYS       │
    ├────────────────────────┤
    │ id (PK)                │
    │ driver_id (FK)         │
    │ jeepney_id (FK)        │
    │ assigned_date          │
    │ is_primary             │
    │ status                 │
    │ assigned_routes        │
    └────────┬───────────────┘
       │
       │ M
    ┌────────▼──────────────┐
    │  ACTIVE_TRIPS         │
    ├───────────────────────┤
    │ id (PK)               │
    │ driver_id (FK)        │
    │ jeepney_id (FK)       │
    │ route_id (FK)         │
    │ current_passengers    │
    │ capacity_available    │
    │ current_location      │
    │ heading_to            │
    │ eta_minutes           │
    │ status                │
    │ started_at            │
    │ updated_at            │
    └───────────────────────┘
       │
       │ 1
    ┌────────▼──────────────┐
    │  JEEPNEYS (Vehicles)  │
    ├───────────────────────┤
    │ id (PK)               │
    │ plate_number (U)      │
    │ vehicle_type          │
    │ model                 │
    │ color                 │
    │ capacity              │
    │ status                │
    │ created_at            │
    └────────┬──────────────┘
       │
       │ 1
    ┌────────▼──────────────┐
    │  JEEPNEY_DOCUMENTS    │
    ├───────────────────────┤
    │ id (PK)               │
    │ jeepney_id (FK)       │
    │ file_url              │
    │ label                 │
    │ uploaded_at           │
    │ updated_at            │
    └───────────────────────┘
```

---

## REGISTERED JEEPNEYS TABLE (Driver Foreign Key Relationship)

### Database Schema

```sql
CREATE TABLE drivers (
  id UUID PRIMARY KEY,
  phone_number VARCHAR(20) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  dob DATE,
  address TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE jeepneys (
  id UUID PRIMARY KEY,
  plate_number VARCHAR(20) UNIQUE NOT NULL,
  vehicle_type VARCHAR(50) NOT NULL, -- 'Jeepney', 'Tricycle', 'Van', 'Motorcycle'
  model VARCHAR(100),
  color VARCHAR(50),
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'maintenance', 'inactive'
  next_inspection DATE,
  insurance_expiry DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE driver_jeepneys (
  id UUID PRIMARY KEY,
  driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  jeepney_id UUID NOT NULL REFERENCES jeepneys(id) ON DELETE RESTRICT,
  assigned_date TIMESTAMP DEFAULT NOW(),
  is_primary BOOLEAN DEFAULT FALSE, -- Primary vehicle for daily assignments
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'archived', 'transferred'
  UNIQUE(driver_id, jeepney_id),
  FOREIGN KEY (driver_id) REFERENCES drivers(id),
  FOREIGN KEY (jeepney_id) REFERENCES jeepneys(id)
);

CREATE TABLE jeepney_documents (
  id UUID PRIMARY KEY,
  jeepney_id UUID NOT NULL REFERENCES jeepneys(id) ON DELETE CASCADE,
  document_type VARCHAR(50), -- 'OR', 'CR', 'Insurance', 'Inspection', 'Registration'
  file_url TEXT,
  expiry_date DATE,
  uploaded_at TIMESTAMP DEFAULT NOW()
);
```

## 1. USERS TABLE (Core User Information)

**Purpose**: Central user management for all Esuyo platform users (passengers and drivers)

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_type VARCHAR(20) NOT NULL, -- 'passenger', 'driver', 'admin'
  phone_number VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  dob DATE,
  address TEXT,
  profile_photo_url TEXT,
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive', 'suspended', 'banned'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP,

  -- Constraints
  CONSTRAINT users_phone_format CHECK (phone_number ~ '^\+63[0-9]{10}$'),
  CONSTRAINT users_email_format CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
  INDEX idx_phone (phone_number),
  INDEX idx_email (email),
  INDEX idx_user_type (user_type)
);
```

**Fields**:
| Field | Type | Constraint | Notes |
|-------|------|-----------|-------|
| id | UUID | PK, default | Auto-generated unique identifier |
| user_type | VARCHAR(20) | NOT NULL | passenger \| driver \| admin |
| phone_number | VARCHAR(20) | UNIQUE, NOT NULL | +63XXXXXXXXXX format |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Valid email format |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt hash (never plain) |
| full_name | VARCHAR(255) | NOT NULL | User's full name |
| username | VARCHAR(50) | UNIQUE, NOT NULL | Unique login identifier |
| dob | DATE | nullable | Date of birth (18+ for drivers) |
| address | TEXT | nullable | Full residential address |
| profile_photo_url | TEXT | nullable | URL to profile picture |
| status | VARCHAR(20) | default 'active' | active \| inactive \| suspended \| banned |
| created_at | TIMESTAMP | default NOW() | Account creation timestamp |
| updated_at | TIMESTAMP | default NOW() | Last update timestamp |
| last_login | TIMESTAMP | nullable | Last login timestamp |

---

## 2. PASSENGERS TABLE (Passenger-Specific Information)

**Purpose**: Extend USER table with passenger-specific data

```sql
CREATE TABLE passengers (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  emergency_contact_name VARCHAR(255),
  emergency_contact_phone VARCHAR(20),
  preferred_payment_method VARCHAR(50), -- 'wallet', 'card', 'cash', 'gcash'
  wallet_id UUID UNIQUE REFERENCES wallet_accounts(id),
  rating DECIMAL(3,2) DEFAULT 0.00, -- 0-5 stars
  total_trips INT DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0.00,
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive', 'banned'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  INDEX idx_user_id (user_id),
  INDEX idx_rating (rating)
);
```

**Fields**:
| Field | Type | Constraint | Notes |
|-------|------|-----------|-------|
| id | UUID | PK | Same as user_id for 1:1 relationship |
| user_id | UUID | FK, UNIQUE | Reference to users table |
| emergency_contact_name | VARCHAR(255) | nullable | In case of emergency |
| emergency_contact_phone | VARCHAR(20) | nullable | Emergency contact number |
| preferred_payment_method | VARCHAR(50) | nullable | wallet, card, cash, gcash |
| wallet_id | UUID | FK, UNIQUE | Reference to wallet_accounts |
| rating | DECIMAL(3,2) | default 0.00 | Average rating (0-5) |
| total_trips | INT | default 0 | Lifetime trip count |
| total_spent | DECIMAL(10,2) | default 0.00 | Total money spent |
| status | VARCHAR(20) | default 'active' | active \| inactive \| banned |
| created_at | TIMESTAMP | default NOW() | Record creation |
| updated_at | TIMESTAMP | default NOW() | Last update |

---

## 3. DRIVERS TABLE (Driver-Specific Information)

**Purpose**: Extend USER table with driver/Tsuper verification and credentials

```sql
CREATE TABLE drivers (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  license_number VARCHAR(50) UNIQUE NOT NULL,
  license_expiry DATE NOT NULL,
  license_front_url TEXT,
  license_back_url TEXT,
  selfie_url TEXT,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'verified', 'suspended', 'rejected'
  verification_date TIMESTAMP,
  rejection_reason TEXT,
  rating DECIMAL(3,2) DEFAULT 0.00,
  total_trips INT DEFAULT 0,
  total_earnings DECIMAL(12,2) DEFAULT 0.00,
  tier VARCHAR(20) DEFAULT 'bronze', -- 'bronze', 'silver', 'gold', 'business'
  tier_updated_at TIMESTAMP,
  bank_account_name VARCHAR(255),
  bank_name VARCHAR(100),
  bank_account_number VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  CONSTRAINT drivers_license_expiry CHECK (license_expiry > NOW()),
  INDEX idx_status (status),
  INDEX idx_tier (tier),
  INDEX idx_rating (rating)
);
```

**Fields**:
| Field | Type | Constraint | Notes |
|-------|------|-----------|-------|
| id | UUID | PK | Same as user_id for 1:1 relationship |
| user_id | UUID | FK, UNIQUE | Reference to users table |
| license_number | VARCHAR(50) | UNIQUE, NOT NULL | PRC/Professional license |
| license_expiry | DATE | NOT NULL | Must be > current date |
| license_front_url | TEXT | nullable | URL to license front photo |
| license_back_url | TEXT | nullable | URL to license back photo |
| selfie_url | TEXT | nullable | URL to driver selfie |
| status | VARCHAR(20) | default 'pending' | pending \| verified \| suspended \| rejected |
| verification_date | TIMESTAMP | nullable | When verified |
| rejection_reason | TEXT | nullable | Why rejected (if applicable) |
| rating | DECIMAL(3,2) | default 0.00 | Average rating (0-5) |
| total_trips | INT | default 0 | Lifetime trips completed |
| total_earnings | DECIMAL(12,2) | default 0.00 | Total commission earned |
| tier | VARCHAR(20) | default 'bronze' | bronze \| silver \| gold \| business |
| tier_updated_at | TIMESTAMP | nullable | When tier last changed |
| bank_account_name | VARCHAR(255) | nullable | Account holder name |
| bank_name | VARCHAR(100) | nullable | Bank name (BDO, BPI, etc) |
| bank_account_number | VARCHAR(50) | nullable | Account number for payouts |
| created_at | TIMESTAMP | default NOW() | Record creation |
| updated_at | TIMESTAMP | default NOW() | Last update |

**Driver Tier System**:

```
Bronze (0-500 trips)      → 1 jeepney max, 2% commission
Silver (500-2000 trips)   → 2 jeepneys max, 1.8% commission
Gold (2000+ trips)        → 5 jeepneys max, 1.5% commission
Business (Commercial)     → 10+ jeepneys, 1.2% commission
```

---

## 4. JEEPNEYS TABLE (Vehicle Registry)

**Purpose**: Master record of all jeepneys/vehicles on the platform

```sql
CREATE TABLE jeepneys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plate_number VARCHAR(20) UNIQUE NOT NULL,
  vehicle_type VARCHAR(50) NOT NULL, -- 'jeepney', 'tricycle', 'van', 'motorcycle'
  brand VARCHAR(100),
  model VARCHAR(100),
  year INT,
  color VARCHAR(50),
  capacity INT NOT NULL, -- passenger capacity
  mileage INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'maintenance', 'inspection', 'inactive'
  -- Next inspection and insurance expiry handled via document screenshots
  registration_number VARCHAR(50),
  or_number VARCHAR(50), -- Official Receipt
  cr_number VARCHAR(50), -- Certificate of Registration
  engine_number VARCHAR(50),
  chassis_number VARCHAR(50),
  last_maintenance DATE,
  maintenance_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  CONSTRAINT jeepneys_capacity_positive CHECK (capacity > 0),
  INDEX idx_plate (plate_number),
  INDEX idx_status (status),
  INDEX idx_vehicle_type (vehicle_type)
);
```

**Fields**:
| Field | Type | Constraint | Notes |
|-------|------|-----------|-------|
| id | UUID | PK | Auto-generated |
| plate_number | VARCHAR(20) | UNIQUE, NOT NULL | License plate (e.g., JUL-001) |
| vehicle_type | VARCHAR(50) | NOT NULL | jeepney \| tricycle \| van \| motorcycle |
| brand | VARCHAR(100) | nullable | Vehicle manufacturer |
| model | VARCHAR(100) | nullable | Model name |
| year | INT | nullable | Year of manufacture |
| color | VARCHAR(50) | nullable | Vehicle color |
| capacity | INT | NOT NULL | Passenger capacity (>0) |
| mileage | INT | default 0 | Current mileage in km |
| status | VARCHAR(20) | default 'active' | active \| maintenance \| inspection \| inactive |
| next_inspection | DATE | nullable | Scheduled inspection date |
| insurance_expiry | DATE | NOT NULL | Insurance expiry must be valid |
| registration_number | VARCHAR(50) | nullable | LTO registration |
| or_number | VARCHAR(50) | nullable | Official Receipt number |
| cr_number | VARCHAR(50) | nullable | Certificate of Registration |
| engine_number | VARCHAR(50) | nullable | Engine serial |
| chassis_number | VARCHAR(50) | nullable | Chassis serial |
| last_maintenance | DATE | nullable | Last maintenance date |
| maintenance_notes | TEXT | nullable | Notes on maintenance history |
| created_at | TIMESTAMP | default NOW() | Record creation |
| updated_at | TIMESTAMP | default NOW() | Last update |

---

## 5. DRIVER_JEEPNEYS TABLE (One-to-Many Relationship)

**Purpose**: Link drivers to their assigned vehicles

```sql
CREATE TABLE driver_jeepneys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  jeepney_id UUID NOT NULL REFERENCES jeepneys(id) ON DELETE RESTRICT,
  assigned_date TIMESTAMP DEFAULT NOW(),
  is_primary BOOLEAN DEFAULT FALSE,
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'archived', 'transferred'
  assigned_routes TEXT, -- JSON array of route IDs
  removal_date TIMESTAMP,
  removal_reason VARCHAR(255),

  UNIQUE(driver_id, jeepney_id),
  INDEX idx_driver_id (driver_id),
  INDEX idx_jeepney_id (jeepney_id),
  INDEX idx_is_primary (is_primary)
);
```

**Fields**:
| Field | Type | Constraint | Notes |
|-------|------|-----------|-------|
| id | UUID | PK | Auto-generated |
| driver_id | UUID | FK, NOT NULL | Reference to drivers |
| jeepney_id | UUID | FK, NOT NULL | Reference to jeepneys |
| assigned_date | TIMESTAMP | default NOW() | When assigned |
| is_primary | BOOLEAN | default FALSE | Only ONE per driver |
| status | VARCHAR(20) | default 'active' | active \| archived \| transferred |
| assigned_routes | TEXT | nullable | JSON: ["route_id1", "route_id2"] |
| removal_date | TIMESTAMP | nullable | When removed |
| removal_reason | VARCHAR(255) | nullable | Why removed |

**Capacity Rules**:

```
Max Jeepneys per Driver = TIER_CAPACITY
Bronze:  1
Silver:  2
Gold:    5
Business: 10+
```

---

## 6. JEEPNEY_DOCUMENTS TABLE

**Purpose**: Track document verification and expiry for vehicles

```sql
CREATE TABLE jeepney_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  jeepney_id UUID NOT NULL REFERENCES jeepneys(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL, -- screenshot image URL (single attachment per record)
  label VARCHAR(100), -- optional label: 'license_front', 'license_back', 'or', 'cr', 'generic'
  uploaded_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  INDEX idx_jeepney_id (jeepney_id)
);
```

**Fields**:
| Field | Type | Constraint | Notes |
|-------|------|-----------|-------|
| id | UUID | PK | Auto-generated |
| jeepney_id | UUID | FK, NOT NULL | Reference to jeepneys |
| document_type | VARCHAR(50) | NOT NULL | or \| cr \| insurance \| inspection \| registration |
| file_url | TEXT | NOT NULL | URL to document file |
| expiry_date | DATE | nullable | When document expires |
| verification_status | VARCHAR(20) | default 'pending' | pending \| verified \| rejected \| expired |
| verified_by | UUID | FK, nullable | Admin who verified |
| verification_date | TIMESTAMP | nullable | When verified |
| rejection_reason | TEXT | nullable | Why rejected |
| uploaded_at | TIMESTAMP | default NOW() | Upload date |
| updated_at | TIMESTAMP | default NOW() | Last update |

---

## 7. WALLET_ACCOUNTS TABLE

**Purpose**: Passenger wallet management for in-app payments

```sql
CREATE TABLE wallet_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES passengers(id) ON DELETE CASCADE,
  balance DECIMAL(12,2) DEFAULT 0.00,
  currency VARCHAR(3) DEFAULT 'PHP',
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'frozen', 'closed'
  last_transaction_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  CONSTRAINT wallet_balance_positive CHECK (balance >= 0),
  INDEX idx_user_id (user_id),
  INDEX idx_status (status)
);
```

**Fields**:
| Field | Type | Constraint | Notes |
|-------|------|-----------|-------|
| id | UUID | PK | Auto-generated |
| user_id | UUID | FK, UNIQUE, NOT NULL | Link to passenger |
| balance | DECIMAL(12,2) | default 0, >=0 | Current balance in PHP |
| currency | VARCHAR(3) | default 'PHP' | Currency code |
| status | VARCHAR(20) | default 'active' | active \| frozen \| closed |
| last_transaction_date | TIMESTAMP | nullable | Last transaction time |
| created_at | TIMESTAMP | default NOW() | Account creation |
| updated_at | TIMESTAMP | default NOW() | Last update |

---

## 8. WALLET_TRANSACTIONS TABLE

**Purpose**: Transaction audit log for wallet activities

```sql
CREATE TABLE wallet_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wallet_id UUID NOT NULL REFERENCES wallet_accounts(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- 'top_up', 'trip_payment', 'refund', 'promo', 'adjustment'
  amount DECIMAL(12,2) NOT NULL,
  balance_before DECIMAL(12,2),
  balance_after DECIMAL(12,2),
  description TEXT,
  reference_id VARCHAR(255), -- trip_id, order_id, etc.
  payment_method VARCHAR(50), -- 'card', 'gcash', 'transfer', 'in_app'
  status VARCHAR(20) DEFAULT 'completed', -- 'pending', 'completed', 'failed', 'refunded'
  created_at TIMESTAMP DEFAULT NOW(),

  INDEX idx_wallet_id (wallet_id),
  INDEX idx_type (type),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
);
```

**Fields**:
| Field | Type | Constraint | Notes |
|-------|------|-----------|-------|
| id | UUID | PK | Auto-generated |
| wallet_id | UUID | FK, NOT NULL | Reference to wallet |
| type | VARCHAR(50) | NOT NULL | top_up \| trip_payment \| refund \| promo \| adjustment |
| amount | DECIMAL(12,2) | NOT NULL | Transaction amount |
| balance_before | DECIMAL(12,2) | nullable | Balance before transaction |
| balance_after | DECIMAL(12,2) | nullable | Balance after transaction |
| description | TEXT | nullable | Human-readable description |
| reference_id | VARCHAR(255) | nullable | trip_id, order_id, etc. |
| payment_method | VARCHAR(50) | nullable | card, gcash, transfer, in_app |
| status | VARCHAR(20) | default 'completed' | pending \| completed \| failed \| refunded |
| created_at | TIMESTAMP | default NOW() | Transaction timestamp |

---

## 9. ROUTES TABLE

**Purpose**: Master route definitions for jeepney service

```sql
CREATE TABLE routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  short_code VARCHAR(20) UNIQUE NOT NULL, -- 'LEG-KAL', 'JAM-REC', etc.
  start_point VARCHAR(255) NOT NULL,
  end_point VARCHAR(255) NOT NULL,
  distance_km DECIMAL(5,2),
  estimated_duration_minutes INT,
  waypoints JSONB, -- GeoJSON coordinates
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive', 'maintenance'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  INDEX idx_short_code (short_code),
  INDEX idx_status (status)
);
```

---

## 10. ACTIVE_TRIPS TABLE

**Purpose**: Real-time tracking of active jeepney trips

```sql
CREATE TABLE active_trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID NOT NULL REFERENCES drivers(id),
  jeepney_id UUID NOT NULL REFERENCES jeepneys(id),
  route_id UUID REFERENCES routes(id),
  current_location POINT, -- (lat, lng)
  heading_to VARCHAR(255),
  current_passengers INT DEFAULT 0,
  capacity_available INT,
  eta_minutes INT,
  status VARCHAR(20) DEFAULT 'in_progress', -- 'in_progress', 'completed', 'cancelled'
  started_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW(),

  INDEX idx_driver_id (driver_id),
  INDEX idx_status (status),
  INDEX idx_started_at (started_at)
);
```

---

## 11. TRIP_HISTORY TABLE

**Purpose**: Complete record of all passenger trips

```sql
CREATE TABLE trip_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  passenger_id UUID NOT NULL REFERENCES passengers(id),
  driver_id UUID NOT NULL REFERENCES drivers(id),
  jeepney_id UUID NOT NULL REFERENCES jeepneys(id),
  route_id UUID REFERENCES routes(id),
  start_location TEXT NOT NULL,
  end_location TEXT NOT NULL,
  distance_km DECIMAL(5,2),
  duration_minutes INT,
  base_fare DECIMAL(8,2),
  surcharge DECIMAL(8,2) DEFAULT 0,
  promo_discount DECIMAL(8,2) DEFAULT 0,
  total_fare DECIMAL(8,2),
  payment_method VARCHAR(50), -- 'wallet', 'cash', 'card'
  status VARCHAR(20) DEFAULT 'completed', -- 'in_progress', 'completed', 'cancelled', 'no_show'
  passenger_rating INT, -- 1-5 stars
  driver_rating INT, -- 1-5 stars
  passenger_review TEXT,
  driver_review TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,

  INDEX idx_passenger_id (passenger_id),
  INDEX idx_driver_id (driver_id),
  INDEX idx_created_at (created_at),
  INDEX idx_status (status)
);
```

---

## INDEXES & PERFORMANCE OPTIMIZATION

```sql
-- Composite indexes for common queries
CREATE INDEX idx_user_type_status ON users(user_type, status);
CREATE INDEX idx_driver_status_rating ON drivers(status, rating DESC);
CREATE INDEX idx_trip_date_passenger ON trip_history(created_at DESC, passenger_id);
CREATE INDEX idx_wallet_transaction_date ON wallet_transactions(created_at DESC, wallet_id);

-- Full-text search indexes
CREATE INDEX idx_users_search ON users USING GIN(to_tsvector('english', full_name || ' ' || username));

-- Geo-spatial index for location queries
CREATE INDEX idx_active_trips_location ON active_trips USING GIST(current_location);
```

---

## DATA INTEGRITY & CONSTRAINTS

```sql
-- Foreign key cascade rules
ALTER TABLE passengers ADD CONSTRAINT fk_passenger_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE drivers ADD CONSTRAINT fk_driver_user
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Unique constraints
ALTER TABLE users ADD CONSTRAINT unique_phone UNIQUE(phone_number);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE(email);
ALTER TABLE drivers ADD CONSTRAINT unique_license UNIQUE(license_number);
ALTER TABLE jeepneys ADD CONSTRAINT unique_plate UNIQUE(plate_number);

-- Check constraints
ALTER TABLE wallet_accounts ADD CONSTRAINT check_balance CHECK(balance >= 0);
ALTER TABLE jeepneys ADD CONSTRAINT check_capacity CHECK(capacity > 0);
ALTER TABLE drivers ADD CONSTRAINT check_license_expiry CHECK(license_expiry > NOW());
```

---

## BACKUP & RECOVERY STRATEGY

```sql
-- Enable Row-Level Security (RLS) for data protection
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_history ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only view their own data
CREATE POLICY user_isolation ON users
  USING (auth.uid()::uuid = id);
```

### Tablet UI Design: Registered Jeepneys List

#### **View 1: Jeepneys Overview (Dashboard Card)**

```
┌─────────────────────────────────────────────────┐
│ YOUR JEEPNEYS                                   │
├─────────────────────────────────────────────────┤
│                                                 │
│ ┌──────────────────┬──────────────────────────┐ │
│ │[🚙]              │ MZF-8845 (Primary)      │ │
│ │Jeepney           │ Sarao Motors 2022       │ │
│ │Green · Active    │ Status: 🟢 Active       │ │
│ │ [Manage]         │ Next inspection: Jun 15 │ │
│ └──────────────────┴──────────────────────────┘ │
│                                                 │
│ ┌──────────────────┬──────────────────────────┐ │
│ │[🚙]              │ JQX-2203                │ │
│ │Tricycle          │ Bajaj 2020              │ │
│ │Blue · Maintenance│ Status: ⚠️  Maintenance │ │
│ │ [Manage]         │ Next inspection: Aug 2  │ │
│ └──────────────────┴──────────────────────────┘ │
│                                                 │
│ [+ Add New Jeepney]                             │
└─────────────────────────────────────────────────┘
```

#### **View 2: Registered Jeepneys Table (Tablet)**

**Visible Columns** (6 total):
| Column | Type | Width | Content | Notes |
|--------|------|-------|---------|-------|
| Vehicle | Icon/Text | 10% | [🚙] Icon | Vehicle emoji |
| Plate # | ID | 14% | MZF-8845 | Clickable to details |
| Type | Badge | 12% | Jeepney/Tricycle | Color coded |
| Model | Text | 16% | Sarao 2022 | Make + Year |
| Status | Badge | 12% | 🟢 Active / ⚠️ Maintenance | Visual indicator |
| Primary | Toggle | 10% | ⭐ / ☆ | Star for primary vehicle |
| Documents | Count | 10% | 5/5 ✓ | Docs uploaded / required |
| Action | Menu | 8% | ⋮ | Edit, Assign Route, Remove |

**Design Example**:

```
╔════════════════════════════════════════════════════════════╗
║ YOUR REGISTERED JEEPNEYS (2/5 slots filled)                ║
├────────────────────────────────────────────────────────────┤
│ [🚙] MZF-8845  Jeepney      Sarao 2022    🟢 Active  ⭐ 5/5 ⋮ │
│      Green, 2022 model      Primary vehicle                 │
│      Insurance: Valid (Exp: Dec 2026)                       │
├────────────────────────────────────────────────────────────┤
│ [🚙] JQX-2203  Tricycle     Bajaj 2020    ⚠️ Maint.  ☆  3/5 ⋮ │
│      Blue, 2020 model       In maintenance, available soon  │
│      Insurance: Expiring (Exp: Jul 2026)                    │
├────────────────────────────────────────────────────────────┤
│ [+] Add New Jeepney                    Max Capacity: 5      │
╚════════════════════════════════════════════════════════════╝
```

---

### **Expanded Detail View (On Row Tap)**

When user taps a jeepney row, a side panel or drawer expands showing:

```
╔════════════════════════════════════════════════════════════╗
║ JEEPNEY DETAILS: MZF-8845                           [×]     ║
├────────────────────────────────────────────────────────────┤
║ VEHICLE INFORMATION                                         ║
├────────────────────────────────────────────────────────────┤
│ Plate Number:      MZF-8845                                │
│ Type:              Jeepney                                 │
│ Model:             Sarao Motors 2022                       │
│ Color:             Green                                   │
│ Status:            🟢 Active                               │
│ Primary Vehicle:   ⭐ Yes (Set as Primary)                 │
│ Assigned Date:     May 1, 2026                             │
│                                                             ║
║ DOCUMENTS (5/5)                                             ║
├────────────────────────────────────────────────────────────┤
│ ✓ OR (Owner's Duplicate)         Expires: Dec 15, 2027    │
│ ✓ CR (Certificate of Registration) Expires: Dec 15, 2026  │
│ ✓ Insurance (MAPFRE)             Expires: Dec 31, 2026    │
│ ✓ Inspection (Safety Check)      Expires: Jun 15, 2026    │
│ ✓ Registration (LTO)             Expires: Mar 20, 2027    │
│                                                             ║
║ QUICK ACTIONS                                               ║
├────────────────────────────────────────────────────────────┤
│ [📝 Edit Details]  [🛠️ Maintenance]  [🗑️ Remove]          │
│                                                             ║
║ ASSIGN TO ROUTE                                             ║
├────────────────────────────────────────────────────────────┤
│ Currently assigned to: Legazpi ↔ Kalilihan                 │
│ [Change Route Assignment]                                  │
╚════════════════════════════════════════════════════════════╝
```

---

### **Tablet Interactions**

#### **Tap Row**

- Expands side panel (width: 300-320px) sliding in from right
- Shows full jeepney details, documents, and quick actions
- Close with back button or tap outside

#### **Set as Primary (⭐)**

- Tap star icon to toggle primary vehicle
- Only one jeepney can be primary per driver
- Primary vehicle used for daily route assignments
- Visual confirmation: star fills in, older primary unfills

#### **Swipe Left**

- Reveals 2-3 quick actions:
  - 📝 Edit Jeepney Details
  - 🛠️ Schedule Maintenance
  - 🗑️ Remove from Fleet

#### **Dropdown Menu (⋮)**

- Full action menu:
  - View Details
  - Edit Information
  - Set as Primary
  - View Documents
  - Assign to Route
  - Schedule Maintenance
  - Archive / Remove

#### **Add New Jeepney**

- Tap [+] button at bottom
- Launches modal/sheet with:
  1. **Vehicle Info**: Plate, Type (dropdown), Model, Color
  2. **Documents Upload**: OR, CR, Insurance, Inspection
  3. **Route Assignment**: Select which route(s) jeepney serves
  4. **Confirmation**: Set as primary or secondary

---

### **Status & Color Coding**

**Vehicle Status**:

- 🟢 **Active** (Green): Ready for daily operations
- ⚠️ **Maintenance** (Amber): In service, unavailable for trips
- 🔴 **Inactive** (Red): Not in use (archived, sold, etc.)

**Document Status**:

- ✓ **Valid** (Green): Document current and valid
- ⚠️ **Expiring Soon** (<30 days): Show warning color
- 🔴 **Expired**: Red background, urgent action needed

**Primary Indicator**:

- ⭐ **Primary**: Primary jeepney (vehicle of choice)
- ☆ **Secondary**: Backup/alternative vehicles

---

### **Capacity & Limits**

```
Driver Jeepney Capacity Matrix:
┌─────────────────────────┬──────────────────────────────────┐
│ Driver Tier             │ Max Jeepneys Allowed             │
├─────────────────────────┼──────────────────────────────────┤
│ Bronze (0-500 trips)    │ 1 jeepney (single operator)      │
│ Silver (500-2000 trips) │ 2 jeepneys (small fleet)         │
│ Gold (2000+ trips)      │ 5 jeepneys (full fleet)          │
│ Business (Commercial)   │ 10+ jeepneys (unlimited)         │
└─────────────────────────┴──────────────────────────────────┘
```

Visual slot indicator:

```
┌─────────────────────────────────────────────────┐
│ YOUR JEEPNEYS: 2/5 SLOTS FILLED                 │
│ [🚙] [🚙] [ ] [ ] [ ]  [+ Add]                  │
└─────────────────────────────────────────────────┘
```

---

### **Mobile Adaptation (< 768px)**

**Card-Based Layout**:

```
┌────────────────────────────┐
│ MZF-8845 (Primary) ⭐       │
├────────────────────────────┤
│ Jeepney · Green · Active  │
│ Sarao 2022 · Assigned: May1│
│ Docs: 5/5 ✓ · Inspection:  │
│ Valid (Exp: Jun 15)        │
├────────────────────────────┤
│ [Details] [Edit] [More]    │
└────────────────────────────┘

┌────────────────────────────┐
│ JQX-2203 ☆                 │
├────────────────────────────┤
│ Tricycle · Blue · Maint.   │
│ Bajaj 2020 · Assigned: Apr │
│ Docs: 3/5 ⚠️ Insurance:    │
│ Expiring (Exp: Jul 2026)   │
├────────────────────────────┤
│ [Details] [Edit] [More]    │
└────────────────────────────┘

[+ Add New Jeepney]
```

---

### **Real-Time Updates**

- **Status Changes**: If jeepney maintenance status changes → badge updates with 300ms animation
- **Document Expiry**: 7 days before expiry → badge turns amber, notification sent
- **Insurance Expiry**: 15 days before → badge turns red, urgent alert
- **Primary Switch**: If primary jeepney goes offline → system auto-switches to secondary, driver notified

---

### **Permissions & Data Access**

```
┌──────────────────────┬──────────┬──────────┬──────────┐
│ Action               │ Owner    │ Manager  │ Operator │
├──────────────────────┼──────────┼──────────┼──────────┤
│ View Jeepneys        │ ✓        │ ✓        │ ✓ (own)  │
│ Add Jeepney          │ ✓        │ ✓        │          │
│ Edit Details         │ ✓        │ ✓        │          │
│ Set as Primary       │ ✓        │ ✓        │          │
│ Upload Documents     │ ✓        │ ✓        │          │
│ Remove Jeepney       │ ✓        │          │          │
│ Assign Routes        │ ✓        │ ✓        │          │
└──────────────────────┴──────────┴──────────┴──────────┘
```

---

### **API Endpoints for Jeepney Management**

```
GET    /drivers/:driverId/jeepneys              → List all jeepneys
GET    /drivers/:driverId/jeepneys/:jeepneyId  → Jeepney details
POST   /drivers/:driverId/jeepneys              → Add new jeepney
PUT    /drivers/:driverId/jeepneys/:jeepneyId  → Update jeepney
DELETE /drivers/:driverId/jeepneys/:jeepneyId  → Remove jeepney
PATCH  /drivers/:driverId/jeepneys/:jeepneyId/primary → Set as primary
GET    /jeepneys/:jeepneyId/documents          → Get all documents
POST   /jeepneys/:jeepneyId/documents          → Upload document
DELETE /jeepneys/:jeepneyId/documents/:docId   → Delete document
```

---

### **Validation Rules**

**Adding a Jeepney**:

- ✓ Plate number unique (not already registered to another driver)
- ✓ All required documents must be uploaded (OR, CR, Insurance, Inspection)
- ✓ Vehicle type must be selected
- ✓ Documents not expired
- ✓ Driver hasn't exceeded tier capacity

**Editing a Jeepney**:

- ✓ Can update model, color, status
- ✓ Cannot change plate number (immutable)
- ✓ Documents can be replaced/updated

**Removing a Jeepney**:

- ✓ Cannot remove if active trips exist
- ✓ If primary, must assign another as primary first
- ✓ Confirmation required: "Are you sure? This cannot be undone."
