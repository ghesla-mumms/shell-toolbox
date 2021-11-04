select  sc.table_schema
        ,sc.table_name
        ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'main') as main
--        ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'fsm') as fsm
--        ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'vm') as vm
--        ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'init') as init
        ,pg_table_size('"' || table_schema || '"."' || table_name || '"')
        ,pg_indexes_size('"' || table_schema || '"."' || table_name || '"') as indexes
        ,pg_total_relation_size('"' || table_schema || '"."' || table_name || '"') as total
  from  information_schema.tables sc
  order by indexes desc;

select  q.modified::date
        ,count(distinct q.id)       as  num_questionnaires
from    questionnaires  q   inner join
        patients        p   on  p.id    =   q.patient_id    inner join
        location        l   on  l.id    =   p.location_id
where   l.firm          =   'capital'
and     q.modified      >=  '2019-06-01'
group by q.modified::date
order by q.modified::date desc
limit 15;

  modified  | num_questionnaires
------------+--------------------
 2019-07-02 |              27745
 2019-07-01 |             167673
 2019-06-30 |              18846
 2019-06-29 |               6767
 2019-06-28 |              27435
 2019-06-27 |              26055
 2019-06-26 |              29157
 2019-06-25 |              11935
 2019-06-24 |               8182
 2019-06-23 |               1101
 2019-06-22 |               1144
 2019-06-21 |               8533
 2019-06-20 |               8726
 2019-06-19 |               8268
 2019-06-18 |              10732
(15 rows)

select  v.modified::date
        ,count(distinct v.id)       as  num_visits
from    visits          v   inner join
        patients        p   on  p.id    =   v.patient_id    inner join
        location        l   on  l.id    =   p.location_id
where   l.firm          =   'capital'
and     v.modified      >=  '2019-01-01'
group by v.modified::date
order by num_visits desc
limit 15;

  modified  | num_visits
------------+------------
 2019-07-02 |      26819
 2019-07-01 |     167408
 2019-06-30 |      19233
 2019-06-29 |       6253
 2019-06-28 |      26418
 2019-06-27 |      24102
 2019-06-26 |      27413
 2019-06-25 |      10518
 2019-06-24 |       7354
 2019-06-23 |       1014
 2019-06-22 |        975
 2019-06-21 |       8143
 2019-06-20 |       8042
 2019-06-19 |       7414
 2019-06-18 |       9191
(15 rows)

Crash Chat:
04/29: https://teams.microsoft.com/l/message/19:20e76a47f45142e1892668db90a665a4@thread.skype/1556568834475?tenantId=8cf78974-4371-4d3a-a0f9-474f2459bb4e&groupId=1575746d-f648-4580-958a-b79c904fe24e&parentMessageId=1556568834475&teamName=Hummingbird%20Project&channelName=Crash%20Chat&createdTime=1556568834475
05/02: https://teams.microsoft.com/l/message/19:20e76a47f45142e1892668db90a665a4@thread.skype/1556826070780?tenantId=8cf78974-4371-4d3a-a0f9-474f2459bb4e&groupId=1575746d-f648-4580-958a-b79c904fe24e&parentMessageId=1556826070780&teamName=Hummingbird%20Project&channelName=Crash%20Chat&createdTime=1556826070780




select  sc.table_schema
       ,sc.table_name
       ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'main') as main
       ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'fsm') as fsm
       ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'vm') as vm
       ,pg_relation_size('"' || table_schema || '"."' || table_name || '"', 'init') as init
       ,pg_table_size('"' || table_schema || '"."' || table_name || '"')
       ,pg_indexes_size('"' || table_schema || '"."' || table_name || '"') as indexes
       ,pg_total_relation_size('"' || table_schema || '"."' || table_name || '"') as total
from  information_schema.tables sc
order by indexes desc
limit 5;


    table_schema    |                      table_name                      |    main    | pg_table_size |  indexes   |    total
--------------------+------------------------------------------------------+------------+---------------+------------+-------------
 bi                 | questionnaire_dfact                                  | 1601282048 |    1601732608 | 3338682368 |  4940414976
 bi                 | patientvisit_dfact                                   | 1517699072 |    1518125056 | 2004025344 |  3522150400
 bi                 | response_fact                                        | 1590165504 |    1593778176 | 1920057344 |  3513835520
 public             | patientinteraction                                   |  717971456 |     718192640 | 1893064704 |  2611257344
 bi                 | claimdetail_fact                                     | 1384980480 |    1385373696 | 1605255168 |  2990628864
 public             | patientvisit                                         |  879976448 |     880238592 |  988872704 |  1869111296
 public             | revinfo                                              |  933036032 |     933298176 |  473292800 |  1406590976
 public             | patient_aud                                          | 3285565440 |    3303751680 |  418881536 |  3722633216
 public             | patientvisit_aud                                     | 1784045568 |    1784545280 |  347586560 |  2132131840

Crash Chat - fyi we just got an alert that /home/cpc is filling up on prod-gce-hbc-1
  https://teams.microsoft.com/l/message/19:20e76a47f45142e1892668db90a665a4@thread.skype/1561582585563?tenantId=8cf78974-4371-4d3a-a0f9-474f2459bb4e&groupId=1575746d-f648-4580-958a-b79c904fe24e&parentMessageId=1561582585563&teamName=Hummingbird%20Project&channelName=Crash%20Chat&createdTime=1561582585563

Crash Chat We are not able to see the history record for any patients in PIM currently for any site.  example patient is 108853 from treasureco/hmsl.  Just shows blank field with
View changes to patient across status, LOC/Fac, coverage, physician, and diagnosis.
  https://teams.microsoft.com/l/message/19:20e76a47f45142e1892668db90a665a4@thread.skype/1561644257117?tenantId=8cf78974-4371-4d3a-a0f9-474f2459bb4e&groupId=1575746d-f648-4580-958a-b79c904fe24e&parentMessageId=1561644257117&teamName=Hummingbird%20Project&channelName=Crash%20Chat&createdTime=1561644257117
