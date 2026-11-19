// Regression checks for invariants Prisma cannot generate.
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const here = dirname(fileURLToPath(import.meta.url));
const MIGRATION = readFileSync(
  resolve(here, "../prisma/migrations/0_mysql/migration.sql"),
  "utf8",
);
const SCHEMA = readFileSync(resolve(here, "../prisma/schema.prisma"), "utf8");

/** The migration with every `--` comment line removed. The comments deliberately
 *  discuss the objects that were REMOVED (PvpDailyFirstWin, the firstWinOfDay
 *  partial index) and why, because that history is the reason the current shape
 *  is what it is. Assertions about what the migration DOES must therefore look
 *  at the executable statements only. */
const SQL = MIGRATION.replaceAll("`", '"')
  .split(/\r?\n/)
  .filter((l) => !l.trimStart().startsWith("--"))
  .join("\n");

/** Every CHECK constraint the migration creates, and the exact text the
 *  RAW-SQL-ONLY block in schema.prisma must carry for each. */
const CHECKS: { name: string; predicate: string }[] = [
  { name: "PvpLadderEarn_nonneg", predicate: `"bp" >= 0 AND "milestoneBp" >= 0 AND "moneyAwarded" >= 0` },
  { name: "PvpLadderEarn_money_needs_bonus", predicate: `"moneyAwarded" = 0 OR "winBonusPaid"` },
  { name: "PvpWinBonusClaim_nonneg", predicate: `"money" >= 0` },
  { name: "PvpBadgeMilestone_nonneg", predicate: `"bp" >= 0` },
  { name: "PvpBadgeMilestone_crossed", predicate: `"ratingBefore" < "threshold"` },
];

it("enforces the non-self invariant for both inserts and updates despite cascading FKs", () => {
  for (const event of ["INSERT", "UPDATE"]) {
    expect(SQL).toContain(`BEFORE ${event} ON PvpLadderEarn`);
  }
  expect(SQL).toContain("IF NEW.userId = NEW.opponentUserId THEN");
  expect(SQL).toContain("SIGNAL SQLSTATE '45000'");
});

describe("schema.prisma documents what Prisma cannot see", () => {
  it("carries the RAW-SQL-ONLY block", () => {
    expect(SCHEMA).toContain("RAW-SQL-ONLY OBJECTS");
  });

  for (const c of CHECKS) {
    it(`declares ${c.name} in BOTH the migration and the schema note`, () => {
      expect(MIGRATION).toContain(c.name);
      expect(SQL).toContain(c.predicate);
      expect(SCHEMA).toContain(c.name);
      expect(SCHEMA).toContain(c.predicate);
    });
  }

  it("lists no CHECK in the schema note that the migration does not create", () => {
    const noteChecks = [...SCHEMA.matchAll(/^\/\/\s+CHECK\s+(\w+)/gm)].map((m) => m[1]);
    expect(noteChecks.sort()).toEqual(CHECKS.map((c) => c.name).sort());
  });

  it("explains WHY there is no partial index, so it is not re-added as an improvement", () => {
    expect(SCHEMA).toContain("There is deliberately NO partial unique index");
    expect(SCHEMA).toContain("prisma migrate dev` would generate a");
  });
});

describe("the schema models match the columns the settle actually writes", () => {
  // A column the code writes but the model lacks means Prisma's next generated
  // migration would try to remove it, which is how additive-only policies decay.
  const EARN_COLUMNS = [
    "matchId", "userId", "opponentUserId", "day", "provenance", "result", "endReason",
    "turns", "durationMs", "ratingBefore", "ratingAfter", "ratingDelta",
    "meetingIndex", "bpBeforeDecay", "tier", "bp", "milestoneBp", "moneyAwarded",
    "winBonusPaid", "grantId", "createdAt",
  ];

  it("has every PvpLadderEarn column in the migration and in the model", () => {
    const model = SCHEMA.slice(SCHEMA.indexOf("model PvpLadderEarn"));
    const body = model.slice(0, model.indexOf("\n}"));
    for (const col of EARN_COLUMNS) {
      expect(SQL, col).toContain(`"${col}"`);
      expect(body, col).toContain(col);
    }
  });

  it("has the win-bonus arbiter keyed on userId ALONE, not on a calendar day", () => {
    // The straddle fix, asserted at the schema level: a (userId, day) key is
    // satisfiable twice by two different day values.
    expect(SQL.split('CREATE TABLE "PvpWinBonusClaim"')[1].split("ENGINE=")[0]).toContain('PRIMARY KEY ("userId")');
    // No day-keyed arbiter table survives in either executable file.
    expect(SQL).not.toContain("PvpDailyFirstWin");
    expect(SCHEMA).not.toContain("model PvpDailyFirstWin");
    expect(SCHEMA).not.toContain("PvpDailyFirstWin[]");
    const model = SCHEMA.slice(SCHEMA.indexOf("model PvpWinBonusClaim"));
    expect(model.slice(0, model.indexOf("\n}"))).toContain("userId String @id");
  });

  it("keeps the milestone crossing evidence, both column and constraint", () => {
    expect(SQL).toContain('"ratingBefore"');
    expect(SQL).toContain('CONSTRAINT "PvpBadgeMilestone_crossed"');
    const model = SCHEMA.slice(SCHEMA.indexOf("model PvpBadgeMilestone"));
    expect(model.slice(0, model.indexOf("\n}"))).toContain("ratingBefore");
  });
});
