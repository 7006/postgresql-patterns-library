create or replace procedure execute_attempt(
    --обязательные параметры:
    query text,
    --необязательные параметры:
    lock_timeout text default '100ms',
    max_attempts smallint default '100'
)
    language plpgsql
as
$procedure$
    declare
        is_completed boolean := false;
        delay numeric;
        total_time_start timestamp not null default clock_timestamp();
        total_time_elapsed numeric not null default 0; -- длительность выполнения всех запросов, в секундах
    begin
        perform set_config('lock_timeout', lock_timeout, false);

        for i in 1..max_attempts loop
            begin
                execute query;
                is_completed := true;
                exit;
            exception when lock_not_available then
                total_time_elapsed := round(extract('epoch' from clock_timestamp() - total_time_start)::numeric, 2);
                delay := round(greatest(sqrt(total_time_elapsed * 1), 1), 2);
                raise warning 'Attempt % of % to execute query failed due lock timeout %, next replay after % second', i, max_attempts, lock_timeout, delay;
                perform pg_sleep(delay);
            end;
        end loop;

        if is_completed then
            raise info 'Execute success';
        else
            raise exception 'Execute failed';
        end if;
    end
$procedure$;

comment on procedure execute_attempt(
    --обязательные параметры:
    query text,
    --необязательные параметры:
    lock_timeout interval default '100ms',
    max_attempts smallint default '100'
) is $$
    Процедура предназначена для безопасного выполнения DDL запроосов в БД.
    Пытается выполнить запрос с учётом ограничения lock_timeout.
    В случае неудачи делает задержку выполнения и повторяет попытку N раз.
$$;

--TEST
--call depers.execute_attempt('alter table person alter column email type varchar(320)');