// Seed data — shape and values, you decide how to wrap/export it

const shows = [
  { id: 1, title: 'Pathaan', venue: 'PVR Cinemas', startTime: '2026-08-25T18:30:00.000Z', totalSeats: 6 },
  { id: 2, title: 'Jawan', venue: 'INOX', startTime: '2026-08-25T21:00:00.000Z', totalSeats: 4 },
  { id: 3, title: 'Animal', venue: 'PVR Cinemas', startTime: '2026-08-26T19:00:00.000Z', totalSeats: 4 },
];

const seats = [
  { id: 1, showId: 1, seatNumber: 'A1', category: 'Gold', status: 'available' },
  { id: 2, showId: 1, seatNumber: 'A2', category: 'Gold', status: 'available' },
  { id: 3, showId: 1, seatNumber: 'A3', category: 'Gold', status: 'booked' },
  { id: 4, showId: 1, seatNumber: 'B1', category: 'Silver', status: 'available' },
  { id: 5, showId: 1, seatNumber: 'B2', category: 'Silver', status: 'available' },
  { id: 6, showId: 1, seatNumber: 'B3', category: 'Silver', status: 'available' },
  { id: 7, showId: 2, seatNumber: 'A1', category: 'Gold', status: 'available' },
  { id: 8, showId: 2, seatNumber: 'A2', category: 'Gold', status: 'booked' },
  { id: 9, showId: 2, seatNumber: 'B1', category: 'Silver', status: 'available' },
  { id: 10, showId: 2, seatNumber: 'B2', category: 'Silver', status: 'available' },
  { id: 11, showId: 3, seatNumber: 'A1', category: 'Gold', status: 'available' },
  { id: 12, showId: 3, seatNumber: 'A2', category: 'Gold', status: 'available' },
  { id: 13, showId: 3, seatNumber: 'B1', category: 'Silver', status: 'available' },
  { id: 14, showId: 3, seatNumber: 'B2', category: 'Silver', status: 'available' },
];

const bookings = [
  {
    id: 1, userId: 101, showId: 1, seatId: 3, status: 'confirmed',
    createdAt: new Date('2026-08-20T09:00:00.000Z'),
    _adminNotes: 'Booked via promo code SUMMER26 — do not expose to client',
  },
  {
    id: 2, userId: 102, showId: 2, seatId: 8, status: 'confirmed',
    createdAt: new Date('2026-08-20T10:15:00.000Z'),
    _adminNotes: 'Flagged for manual review — payment gateway delay',
  },
];

let nextSeatId = 15;
let nextBookingId = 3;


// Just the shape — you write the actual seed values from what I gave you
export default {
  shows,
  seats,
  bookings,
  nextSeatId,
  nextBookingId,
};