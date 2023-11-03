create or replace function public.test(
    sql text, -- SQL запросы для тестирования
    expected_sqlstate   text default '57014'/*query_canceled*/, -- код исключения, возвращаемый SQLSTATE
    expected_message    text default null, -- текст основного сообщения исключения
    expected_detail     text default null, -- текст детального сообщения исключения
    expected_hint       text default null, -- текст подсказки к исключению
    expected_constraint text default null, -- имя ограничения целостности, относящегося к исключению
    expected_table      text default null, -- имя таблицы, относящейся к исключению
    expected_schema     text default null, -- имя схемы, относящейся к исключению
    expected_column     text default null, -- имя столбца, относящегося к исключению
    expected_context    text default null, -- строки текста, описывающие стек вызовов в момент исключения
    expected_datatype   text default null, -- имя типа данных, относящегося к исключению

    --returns record:
    sqlstate     out text,
    message      out text,
    detail       out text,
    hint         out text,
    "constraint" out text,
    "table"      out text,
    schema       out text,
    "column"     out text,
    context      out text,
    datatype     out text
)
    returns record
    volatile --!!!
    --returns null on null input
    parallel unsafe --!!!
    language plpgsql
    set search_path = ''
as
$function$
    DECLARE
        exception_sqlstate   text;
        exception_message    text;
        exception_detail     text;
        exception_hint       text;
        exception_constraint text;
        exception_table      text;
        exception_schema     text;
        exception_column     text;
        exception_context    text;
        exception_datatype   text;
    BEGIN

        BEGIN
            execute sql;

            -- rollback all test queries in subtransaction
            raise exception using errcode = 'query_canceled';
        EXCEPTION
            --https://www.postgrespro.ru/docs/postgresql/14/errcodes-appendix
            WHEN query_canceled /*57014*/ THEN
                -- https://www.postgrespro.ru/docs/postgresql/14/plpgsql-errors-and-messages
                -- https://www.postgrespro.ru/docs/postgresql/14/plpgsql-control-structures
                GET STACKED DIAGNOSTICS
                    exception_sqlstate   := RETURNED_SQLSTATE,
                    exception_column     := COLUMN_NAME,
                    exception_constraint := CONSTRAINT_NAME,
                    exception_datatype   := PG_DATATYPE_NAME,
                    exception_message    := MESSAGE_TEXT,
                    exception_table      := TABLE_NAME,
                    exception_schema     := SCHEMA_NAME,
                    exception_detail     := PG_EXCEPTION_DETAIL,
                    exception_hint       := PG_EXCEPTION_HINT,
                    exception_context    := PG_EXCEPTION_CONTEXT;
                if expected_sqlstate != exception_sqlstate
                or expected_message != exception_message
                or expected_detail != exception_detail
                or expected_hint != exception_hint
                or expected_constraint != exception_constraint
                or expected_table != exception_table
                or expected_schema != exception_schema
                or expected_column != exception_column
                or expected_context != exception_context
                or expected_datatype != exception_datatype
                then
                    raise; -- raise the original exception
                end if;
            WHEN others /*все типы ошибок, кроме QUERY_CANCELED и ASSERT_FAILURE*/ THEN
                -- https://www.postgrespro.ru/docs/postgresql/14/plpgsql-errors-and-messages
                -- https://www.postgrespro.ru/docs/postgresql/14/plpgsql-control-structures
                GET STACKED DIAGNOSTICS
                    exception_sqlstate   := RETURNED_SQLSTATE,
                    exception_column     := COLUMN_NAME,
                    exception_constraint := CONSTRAINT_NAME,
                    exception_datatype   := PG_DATATYPE_NAME,
                    exception_message    := MESSAGE_TEXT,
                    exception_table      := TABLE_NAME,
                    exception_schema     := SCHEMA_NAME,
                    exception_detail     := PG_EXCEPTION_DETAIL,
                    exception_hint       := PG_EXCEPTION_HINT,
                    exception_context    := PG_EXCEPTION_CONTEXT;
                if expected_sqlstate != exception_sqlstate
                or expected_message != exception_message
                or expected_detail != exception_detail
                or expected_hint != exception_hint
                or expected_constraint != exception_constraint
                or expected_table != exception_table
                or expected_schema != exception_schema
                or expected_column != exception_column
                or expected_context != exception_context
                or expected_datatype != exception_datatype
                then
                    raise; -- raise the original exception
                end if;
        END;
        --returns record:
        sqlstate     := exception_sqlstate;
        message      := exception_message;
        detail       := exception_detail;
        hint         := exception_hint;
        "constraint" := exception_constraint;
        "table"      := exception_table;
        schema       := exception_schema;
        "column"     := exception_column;
        context      := exception_context;
        datatype     := exception_datatype;
    END
$function$;

comment on function public.test(
    sql text,
    expected_sqlstate   text,
    expected_message    text,
    expected_detail     text,
    expected_hint       text,
    expected_constraint text,
    expected_table      text,
    expected_schema     text,
    expected_column     text,
    expected_context    text,
    expected_datatype   text,

    --returns record:
    sqlstate     out text,
    message      out text,
    detail       out text,
    hint         out text,
    "constraint" out text,
    "table"      out text,
    schema       out text,
    "column"     out text,
    context      out text,
    datatype     out text
) is $$
    Функция используется для тестирования.
    Выполняет SQL запросы в подтранзакции, а затем откатывает (только подтранзакцию!).
    Если результат не соответствует ожидаемому, генерирует исключение (ошибку).
$$;

--TEST AND EXAMPLES
select * from public.test($sql$
    select 1 / 0;
$sql$, '22012', 'division by zero');

select * from public.test($sql$
    create table public.test123 (s text);
    insert into public.test123 values('test');
    select * from public.test123;
$sql$);
