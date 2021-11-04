#!/bin/bash

-- Sys Admin
INSERT INTO person (issystemdefined, lastupdatetime, lastupdateuser, version, deleted,
                    email, firstname, lastname, hasldapprofile, serialnumber, hospice_id)
            VALUES (false, '2020-01-01 11:05:00', NULL, '2020-01-01 11:05:00', false,
                    'g.hesla@mumms.com', 'Greg', 'Hesla', true, '8e61a68e-bd96-49e2-b7f3-40d6e90ae3b5', (select id from hospice where bin='mummsupport'));

INSERT into person_role(issystemdefined, deleted, lastupdatetime, lastupdateuser, version, rank, person_id, role_id)
  VALUES(false, false, '2020-01-01 11:05:00', NULL, '2020-01-01 11:05:00', 0, currval('person_id_seq'), (select id from hbrole where issystemdefined and name = 'Mumms Administrator'));

INSERT into smartformresponse(issystemdefined, deleted, lastupdatetime, lastupdateuser, version, answer_id, question_id) VALUES (true, false, now(),'g.hesla', now(), (select id from smartformanswer where issystemdefined and answertext = 'No' and question_id = (select id from smartformquestion where issystemdefined and questiontext = 'Hospice Employee')), (select id from smartformquestion where issystemdefined and questiontext = 'Hospice Employee'));

INSERT into person_smartformresponse(smartformresponses_id, person_id) VALUES (currval('smartformresponse_id_seq'), currval('person_id_seq'));

INSERT into smartformresponse(issystemdefined, deleted, lastupdatetime, lastupdateuser, version, answer_id, question_id) VALUES (true, false, now(),'g.hesla', now(), (select id from smartformanswer where issystemdefined and answertext = 'Yes' and question_id = (select id from smartformquestion where issystemdefined and questiontext = 'Hummingbird User')), (select id from smartformquestion where issystemdefined and questiontext = 'Hummingbird User'));

INSERT into person_smartformresponse(smartformresponses_id, person_id) VALUES (currval('smartformresponse_id_seq'), currval('person_id_seq'));

INSERT into smartformresponse(issystemdefined, deleted, lastupdatetime, lastupdateuser, version, answer_id, question_id) VALUES (true, false, now(),'g.hesla', now(), (select id from smartformanswer where issystemdefined and answertext = 'Mumms Administrator' and question_id = (select id from smartformquestion where issystemdefined and questiontext = 'User Type')), (select id from smartformquestion where issystemdefined and questiontext = 'User Type'));

INSERT into person_smartformresponse(smartformresponses_id, person_id) VALUES (currval('smartformresponse_id_seq'), currval('person_id_seq'));

update hospice set dbusername = 'hummingbird', dbpassword = 'hummingbird', dbhost = 'localhost', dbname = 'hummingbird', dbport = 5432 where bin = 'mummsupport';
