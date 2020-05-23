-module(raw_sqlite3).

-export([open/1, open/2, open/3,
         close/1,
         prepare/2,
         bind/2,
         step/1,
         fetchall/1,
         q/2, q/3,
         exec/2, exec/3]).

-include_lib("raw_sqlite3/include/raw_sqlite3.hrl").

open(DbFile) ->
    open(DbFile, ?SQLITE_OPEN_READWRITE bor ?SQLITE_OPEN_CREATE).

open(DbFile, Flags) ->
    open(DbFile, Flags, "").

open(DbFile, Flags, Vfs) ->
    sqlite3_nif:sqlite3_open_v2(DbFile, Flags, Vfs).

close(Conn) ->
    sqlite3_nif:sqlite3_close_v2(Conn).

prepare(Conn, Sql) ->
    sqlite3_nif:sqlite3_prepare_v2(Conn, Sql).

bind(Stmt, Params) ->
    sqlite3_nif:sqlite3_bind(Stmt, Params).

step(Stmt) ->
    sqlite3_nif:sqlite3_step(Stmt).

fetchall(Stmt) ->
    fetchall(Stmt, []).

fetchall(Stmt, Acc) ->
    case step(Stmt) of
        ok ->
            lists:reverse(Acc);
        {error, _} = Err ->
            Err;
        Row ->
            fetchall(Stmt, [Row | Acc])
    end.

q(Conn, Sql) ->
    q(Conn, Sql, []).

q(Conn, Sql, Params) ->
    case prepare(Conn, Sql) of
        {ok, Stmt, _} ->
            case sqlite3_nif:sqlite3_bind(Stmt, Params) of
                ok ->
                    fetchall(Stmt);
                {error, _} = Err ->
                    Err
            end;
        {error, _} = Err ->
            Err
    end.

exec(Conn, Sql) ->
    exec(Conn, Sql, []).

exec(_Conn, <<>>, _Params) ->
    ok;
exec(Conn, Sql, Params) ->
    case prepare(Conn, Sql) of
        {ok, Stmt, Leftover} ->
            case do_exec(Stmt, Params) of
                ok ->
                    exec(Conn, Leftover, Params);
                {error, _} = Err ->
                    Err
            end;
        {error, _} = Err ->
            Err
    end.

do_exec(Stmt, Params) ->
    case sqlite3_nif:sqlite3_bind(Stmt, Params) of
        ok ->
            case fetchall(Stmt) of
                {error, _} = Err ->
                    Err;
                _ ->
                    ok
            end;
        {error, _} = Err ->
            Err
    end.
