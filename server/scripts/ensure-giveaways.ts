#!/usr/bin/env tsx
// Historical entry point: Migrate owns the DDL now. Check without changing data.
import { prisma } from "../src/db.js";

try {
  console.log(`Giveaway: ${await prisma.giveaway.count()}, GiveawayEntry: ${await prisma.giveawayEntry.count()} row(s).`);
} catch (error) {
  console.error("Cannot read giveaways. Check the connection and run npm run db:deploy.", error);
  process.exitCode = 1;
} finally {
  await prisma.$disconnect();
}
