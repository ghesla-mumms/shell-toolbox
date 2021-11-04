select  sc.table_schema
        ,sc.table_name
        ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'main') as relation_main
        -- ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'fsm') as relation_fsm
        -- ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'vm') as relation_vm
        -- ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'init') as relation_init
        ,pg_size_pretty(pg_table_size('"' || table_schema || '"."' || table_name || '"')) as table_size
        ,pg_size_pretty(pg_indexes_size('"' || table_schema || '"."' || table_name || '"')) as indexes_size
        ,pg_size_pretty(pg_total_relation_size('"' || table_schema || '"."' || table_name || '"')) as total_size
        ,st.n_live_tup
        ,st.n_dead_tup
        ,st.last_vacuum
        ,st.last_autovacuum
from    information_schema.tables sc  join
        pg_stat_all_tables        st  on  st.schemaname = sc.table_schema
                                      and st.relname    = sc.table_name
-- order by pg_total_relation_size('"' || table_schema || '"."' || table_name || '"') desc
order by st.n_dead_tup desc
limit 5;
