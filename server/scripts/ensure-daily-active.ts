#!/usr/bin/env tsx
// Historical entry point: Migrate owns the DDL now. Check without changing data.
import { prisma } from "../src/db.js";

try {
  console.log(`DailyActive: ${await prisma.dailyActive.count()} row(s).`);
} catch (error) {
  console.error("Cannot read DailyActive. Check the connection and run npm run db:deploy.", error);
  process.exitCode = 1;
} finally {
  await prisma.$disconnect();
}
