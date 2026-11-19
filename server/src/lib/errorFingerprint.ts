import { prisma } from "../db.js";
import { Prisma } from "@prisma/client";

// MySQL 8 ICU patterns, bound as parameters (no SQL string/backslash escaping).
// Reuse exactly the same expression for grouping, drill-down and deletion.
const rules = [
  ["[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", "<uuid>"],
  ["[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}", "<email>"],
  [String.raw`\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}([.]\d+)?(Z|[+-]\d{2}:?\d{2})?`, "<timestamp>"],
  [String.raw`\b[0-9A-Za-z]{20,}\b`, "<id>"],
  [String.raw`\b0x[0-9a-fA-F]+\b`, "<hex>"],
  ["[0-9]+", "<num>"],
];
export const errorFingerprint = rules.reduce(
  (expr, [pattern, replacement]) => Prisma.sql`REGEXP_REPLACE(${expr}, ${pattern}, ${replacement})`,
  Prisma.sql`message`,
);

interface GroupRow {
  kind: string;
  fingerprint: string;
  sampleMessage: string;
  count: bigint;
  latestAt: Date;
  sampleId: string;
  sampleLevel: string;
  sampleSource: string | null;
  sampleStack: string | null;
  sampleUserId: string | null;
  sampleUsername: string | null;
  sampleUserAgent: string | null;
}

// A fixed-size window key also avoids MySQL's max_sort_length prefix for LONGTEXT.
export function fetchErrorGroups(since: Date, kind: string | undefined, limit: number) {
  return prisma.$queryRaw<GroupRow[]>`
    WITH normalized AS (
      SELECT id, kind, level, message, stack, source, userId, username, userAgent, createdAt,
             ${errorFingerprint} AS fingerprint
        FROM ErrorLog WHERE createdAt >= ${since} ${kind ? Prisma.sql`AND kind = ${kind}` : Prisma.empty}
    ), scored AS (
      SELECT normalized.*, COUNT(*) OVER grp AS groupCount,
             ROW_NUMBER() OVER (grp ORDER BY createdAt DESC, id DESC) AS rn
        FROM normalized WINDOW grp AS (PARTITION BY kind, SHA2(fingerprint, 256))
    )
    SELECT kind, fingerprint, message AS sampleMessage, groupCount AS count, createdAt AS latestAt,
           id AS sampleId, level AS sampleLevel, source AS sampleSource, stack AS sampleStack,
           userId AS sampleUserId, username AS sampleUsername, userAgent AS sampleUserAgent
      FROM scored WHERE rn = 1 ORDER BY groupCount DESC LIMIT ${limit}`;
}
