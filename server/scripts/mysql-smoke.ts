// Integration gate, intentionally NOT part of the DB-less vitest suite.
// CI creates this disposable DB. Never allow the smoke fixture in another DB.
import assert from "node:assert/strict";
import { prisma } from "../src/db.js";
import { recordDailyActive } from "../src/lib/presence.js";
import { errorFingerprint, fetchErrorGroups } from "../src/lib/errorFingerprint.js";
import { readLadderHistory, readLadderStatus, settleLadderEarn } from "../src/lib/pvpLadder.js";

const url = new URL(process.env.DATABASE_URL!);
assert(url.hostname === "127.0.0.1" && url.pathname === "/pokeidle_ci");
process.env.PVP_LADDER_REWARDS = "1";
try {
  const saveData = JSON.stringify({ note: "🐉".repeat(40000) });
  for (const id of ["Alice", "Bob"]) {
    await prisma.user.create({ data: { id, email: `${id}@example.test`, username: id, isAdmin: id === "Alice", saveData, saveVersion: 1 } });
  }
  assert.equal((await prisma.user.findUniqueOrThrow({ where: { id: "Alice" } })).saveData, saveData);
  assert.equal(await prisma.user.count({ where: { id: "alice" } }), 0);
  await recordDailyActive("Alice");
  await recordDailyActive("Alice");
  assert.equal(await prisma.dailyActive.count({ where: { userId: "Alice" } }), 1);
  await prisma.errorLog.create({ data: { kind: "server", message: "save 409 user@example.com" } });
  const [log] = await prisma.$queryRaw<{ fp: string }[]>`SELECT ${errorFingerprint} AS fp FROM ErrorLog`;
  assert.equal(log.fp, "save <num> <email>");
  const [group] = await fetchErrorGroups(new Date(0), "server", 10);
  assert.equal(group.fingerprint, log.fp);
  assert.equal(Number(group.count), 1);
  const match = {
    matchId: "m1", provenance: "queue", winnerId: "Alice", loserId: "Bob", endReason: "ko",
    durationMs: 300000, ratingDelta: { aDelta: 16, bDelta: -16, aRating: 1016, bRating: 984 },
    logLines: ["|start", "|turn|1", "|turn|2", "|turn|3", "|turn|4", "|win|Alice"],
  } as const;
  const input = { ...match, logLines: [...match.logLines] };
  assert.equal((await settleLadderEarn(input)).paid, true);
  assert.equal((await settleLadderEarn(input)).reason, "already_settled");
  assert.equal(await prisma.pendingGrant.count(), 2);
  assert.equal((await readLadderStatus("Alice")).winBonusOnCooldown, true);
  assert.equal((await readLadderHistory("Alice"))[0].winBonusPaid, true);
  const later = new Date(Date.now() + 72 * 3600000);
  const next = await settleLadderEarn({ ...input, matchId: "m2", now: later });
  assert.equal(next.sides.find(s => s.userId === "Alice")?.winBonus, true);
} finally {
  await prisma.$disconnect();
}
