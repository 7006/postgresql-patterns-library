# Тестирование потери установленного соединения к PostgreSQL

Как протестировать?

1. Запустить команду в терминале 1
1. Разорвать соединение к СУБД в терминале 2
1. Посмотреть результат в терминале 1. В случае потери соединения вывод уведомлений (ping) приостановится (в этом случае `psql` "зависает") или явно возвратится ошибка

**Запустить в терминале 1**
```bash
# устанавливаем psql, при необходимости
sudo dnf -y install postgresql-14-14.5 postgresql-14-libs-14.5
  
# создаём файл .pgpass, при необходимости
nano ~/.pgpass && chmod 600 ~/.pgpass
 
# передаём в application_name основной IP текущего сервера, т.к. запрос может проходить через прокси
psql -q -X -U postgres -d "application_name='psql $(hostname -I | cut -f1 -d' ')'" \
  -c "\echo 'Press CTRL+C to stop'" -c "\conninfo" -f connection_ping.sql -c "call connection_ping(1000, 1.0)" \
  -h <host> -p <port>
```
Файл [connection_ping.sql](connection_ping.sql)

**TODO** в случае "зависания" `psql` можно ещё попробовать заглянуть в `pg_stat_activity` и терминировать процесс (самоуничтожение), если он долго ожидает клиента.

# Тестирование длительности отсутствия соединения к PostgreSQL

Как протестировать?

1. Запустить скрипт в терминале 1
1. Остановить и запустить СУБД в терминале 2
1. Посмотреть результат в терминале 1

## Скрипт 1

Принцип работы:
1. В цикле psql пытается подключиться к СУБД. Между попытками 0.1 секунда.
1. Преимущества: не «зависает».
1. Недостатки: может не отловить очень кратковременную недоступность подключения к СУБД.

Файл [psql_connection_lost_duration_v1.sh](psql_connection_lost_duration_v1.sh)

## Скрипт 2
1. Принцип работы:
   1. Psql подключается к СУБД и выполняет хранимую процедуру. Внутри неё цикл, из которого клиенту отсылаются уведомления каждые 0.5 секунд.
   1. Как только соединение к СУБД теряется, в скрипте запускается цикл, в котором psql пытается подключиться к СУБД. Между попытками 0.1 секунда.
1. Преимущества: отлавливает очень кратковременную недоступность подключения к СУБД.
1. Недостатки: может «зависнуть»

Файлы [psql_connection_lost_duration_v2.sh](psql_connection_lost_duration_v2.sh), [connection_ping.sql](connection_ping.sql)
