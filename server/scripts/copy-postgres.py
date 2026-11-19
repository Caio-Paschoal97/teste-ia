"""Offline PostgreSQL -> MySQL copy. See ../MYSQL.md; no DDL, upserts or deletes."""
import argparse
import os
from graphlib import TopologicalSorter
from urllib.parse import unquote, urlsplit

import psycopg
from psycopg import sql
import pymysql


def ident(name):
    return '`' + name.replace('`', '``') + '`'


def destination():
    url = urlsplit(os.environ['DATABASE_URL'])
    if url.scheme != 'mysql' or not url.path.strip('/') or url.query or url.fragment:
        raise ValueError('Use a mysql://user:pass@host:port/database URL without parameters for the copy')
    ca = os.getenv('MYSQL_CA_FILE')
    if url.hostname not in ('localhost', '127.0.0.1', '::1') and not ca:
        raise ValueError('For remote MySQL set MYSQL_CA_FILE or use a local SSH tunnel')
    return pymysql.connect(host=url.hostname, port=url.port or 3306,
                           user=unquote(url.username or ''), password=unquote(url.password or ''),
                           database=unquote(url.path[1:]), charset='utf8mb4', autocommit=False,
                           ssl_ca=ca, ssl_verify_cert=bool(ca), ssl_verify_identity=bool(ca))


def run(pg, my, apply):
    pg.execute('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY')
    pg.execute("SET LOCAL TIME ZONE 'UTC'")
    with my.cursor() as cur:
        cur.execute("SET SESSION time_zone = '+00:00'")
        cur.execute("SELECT @@SESSION.sql_mode, @@SESSION.foreign_key_checks")
        mode, checks = cur.fetchone()
        if 'STRICT_' not in mode or not checks:
            raise ValueError('Strict SQL mode and FK checks are required')
        cur.execute("SELECT migration_name FROM _prisma_migrations WHERE finished_at IS NOT NULL AND rolled_back_at IS NULL")
        if ('0_mysql',) not in cur.fetchall():
            raise ValueError('Run the MySQL baseline first')
        cur.execute("SELECT table_name, engine FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name <> '_prisma_migrations'")
        tables = dict(cur.fetchall())
        src = {t for t, in pg.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name <> '_prisma_migrations'")}
        if tables.keys() != src or not tables or set(tables.values()) != {'InnoDB'}:
            raise ValueError(f'Expected matching application tables (InnoDB only); difference: {src ^ tables.keys()}')
        deps = {t: set() for t in tables}
        cur.execute('SELECT table_name, referenced_table_name FROM information_schema.key_column_usage WHERE table_schema=DATABASE() AND referenced_table_name IS NOT NULL')
        for child, parent in cur.fetchall():
            deps[child].add(parent)
        for table in TopologicalSorter(deps).static_order():
            cur.execute(f'SELECT 1 FROM {ident(table)} LIMIT 1')
            if cur.fetchone():
                raise ValueError(f'{table}: target is not empty; refusing to merge')
            src_cols = dict(pg.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND table_name=%s ORDER BY ordinal_position", (table,)))
            cur.execute('SELECT column_name, column_key FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name=%s ORDER BY ordinal_position', (table,))
            cols = dict(cur.fetchall())
            pk = [c for c, key in cols.items() if key == 'PRI']
            if cols.keys() != src_cols.keys() or not pk:
                raise ValueError(f'{table}: column mismatch or missing primary key')
            names = ', '.join(map(ident, cols))
            pg_order = [sql.Identifier(c) + (sql.SQL(' COLLATE "C"') if src_cols[c] in ('text', 'character varying') else sql.SQL('')) for c in pk]
            select = sql.SQL('SELECT {} FROM {} ORDER BY {}').format(
                sql.SQL(', ').join(map(sql.Identifier, cols)), sql.Identifier('public', table), sql.SQL(', ').join(pg_order))
            if not apply:
                print(table, 'schema and empty target OK')
                continue
            # Named cursor: bounded memory, including large saves. One InnoDB
            # transaction for ALL tables, including the read-back verification.
            with pg.cursor(name='source_rows') as rows:
                rows.execute(select)
                count = 0
                while batch := rows.fetchmany(16):
                    cur.executemany(f'INSERT INTO {ident(table)} ({names}) VALUES ({", ".join(["%s"] * len(cols))})', batch)
                    count += len(batch)
            with pg.cursor(name='verify_rows') as rows, my.cursor(pymysql.cursors.SSCursor) as copied:
                rows.execute(select)
                copied.execute(f'SELECT {names} FROM {ident(table)} ORDER BY {", ".join(map(ident, pk))}')
                while True:
                    expected, actual = rows.fetchmany(16), copied.fetchmany(16)
                    if list(expected) != list(actual):
                        raise ValueError(f'{table}: read-back mismatch; rolling back')
                    if not expected:
                        break
            print(table, count, 'rows compared')
    if apply:
        my.commit()
        print('Copy verified and committed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true', help='copy into a new, offline, migrated database')
    args = parser.parse_args()
    # Exiting without commit (including on exception) rolls back the destination.
    with psycopg.connect(os.environ['SOURCE_DATABASE_URL']) as source, destination() as target:
        run(source, target, args.apply)
