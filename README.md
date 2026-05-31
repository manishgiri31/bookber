# BookBer

Real-time barber appointment, queue and chair management platform.

## Features

- Customer booking
- Reserved chair system
- Walk-in handling
- Real-time queue updates
- Socket.io synchronization
- Push notifications
- Nearby barber search
- Ratings & reviews

## Tech Stack

### Frontend
- Flutter
- Riverpod
- GoRouter
- FlutterMap

### Backend
- Node.js
- Fastify
- Prisma
- PostgreSQL + PostGIS
- Redis
- Socket.io

## Local Setup

### Backend

cd backend
npm install

### Database

docker compose up -d

### Prisma

npx prisma generate
npx prisma db push

### Run

npm run dev