# Database Design

## Overview

This document records the **initial database design** of the Booking System.

At this stage, the goal is to establish a simple and clean relational foundation that can be extended as the project grows.

The database is being designed using **PostgreSQL**.

---

## Current Database Scope

The initial system is based on four core entities:

- **Users**
- **Hotels**
- **Rooms**
- **Bookings**

These entities represent the basic flow of the system:

```text
User
  ↓
Booking
  ↓
Room
  ↓
Hotel
```

---

## Initial Schema

### 1. Users

Stores information about users of the booking system.

Main attributes:

```text
id
name
email
password_hash
phone_number
created_at
updated_at
```

The `id` is the primary key, and `email` is unique.

---

### 2. Hotels

Stores information about hotels available in the system.

Main attributes:

```text
id
name
address
city
state
country
postal_code
phone_number
created_at
updated_at
```

The `id` is the primary key.

---

### 3. Rooms

Stores individual rooms belonging to hotels.

Main attributes:

```text
id
hotel_id
room_number
room_type
max_occupancy
price_per_night
description
status
created_at
updated_at
```

The `id` is the primary key.

`hotel_id` is a foreign key referencing the hotel to which the room belongs.

---

### 4. Bookings

Stores room reservation information.

Main attributes:

```text
id
user_id
room_id
check_in
check_out
booking_price
booking_time
status
created_at
updated_at
```

The `id` is the primary key.

`user_id` references the user who created the booking.

`room_id` references the room being booked.

---

## Relationships

The current database relationships are:

```text
User  1 ───────── N  Booking

Hotel 1 ───────── N  Room

Room  1 ───────── N  Booking
```

### Meaning

- One user can have multiple bookings.
- One hotel can contain multiple rooms.
- One room can have multiple bookings over its lifetime.

---

## Database Integrity

The initial design uses relational database concepts such as:

- Primary Keys
- Foreign Keys
- Unique Constraints
- NOT NULL Constraints
- CHECK Constraints
- Referential Integrity

These constraints are intended to keep invalid data out of the database.

---

## Why This Is Only Version 1

This schema is intentionally simple.

It provides the foundation for the actual Booking System, but it is **not considered the final database design**.

As more database concepts are learned, the schema will be reviewed and improved based on real requirements.

Future improvements may involve:

```text
Normalization
Indexes
Query Optimization
Transactions
ACID
Concurrency
Isolation Levels
Locks
MVCC
Double-Booking Prevention
Performance
Scaling
Replication
Partitioning
```

Not every concept will necessarily require a schema change. Each change will be made only when there is a real requirement or engineering reason.

---

## Development Philosophy

The database will evolve through practical experimentation:

```text
Learn a Concept
      ↓
Understand the Problem
      ↓
Apply it to the Booking System
      ↓
Design
      ↓
Implement
      ↓
Test
      ↓
Find Edge Cases
      ↓
Improve
      ↓
Document
```

This allows the project to demonstrate not only the final database, but also the reasoning and engineering decisions behind its evolution.

---

## Current Status

**Database:** PostgreSQL

**Current milestone:**

> Initial relational schema designed and implemented for Users, Hotels, Rooms, and Bookings.

This schema will serve as the foundation for future versions of the Booking System.
