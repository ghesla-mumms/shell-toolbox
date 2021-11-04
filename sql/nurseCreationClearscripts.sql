-- This is designed to create a repeatable demo nurse whose serial#
-- footprint will persist across database scramble/syncs. Do not use
-- more than once without changing the identifiers.
-- The first use and after any ldap sync requires a Reset Password action

DO $$
DECLARE
    phys_id BIGINT;
    addr_id BIGINT;
BEGIN
  -- address record
  insert into address(issystemdefined,lastupdatetime,version,lastupdateuser,city,county,state,street1,zip,zip4)
	values(FALSE,now(),now(),'script','New Orleans','Orleans','LA','822 Camp St.','70130','1234')
	returning id into addr_id;

  -- person record
  insert into person (id,issystemdefined,deleted,lastupdatetime,version,lastupdateuser,lastname,firstname,
 	    email,employmentstartdate,hasldapprofile,personnumber,serialnumber,address_id,active,sex,hospice_id)
 	values(-48,FALSE,FALSE,now(),now(),'script','ClearScripts','Nurse',
  	 'g.hesla+csnurse48@mumms.com','2019-01-01',TRUE,'48','48DemoPhysSerial',addr_id,TRUE,'Unknown',3)
	returning id into phys_id;

  -- Set the clearscriptlogin depending upon the phase
  update person
   -- set clearscriptslogin = 'jmarshall'       -- qa
   -- set clearscriptslogin = 'maagent9923'     -- stage
   -- qa: set clearscriptslogin = 'maagent5413' -- sales/preview
   -- qa: set clearscriptslogin = 'maagent6359' -- prod/sandbox
   where id = -48;

  --- person_role
  -- -1: Hospice Administrator
  INSERT INTO person_role (issystemdefined,lastupdateuser,lastupdatetime,VERSION,
      rank,person_id,role_id,deleted)
	SELECT FALSE AS issystemdefined, 'DataImport' AS lastupdateuser, now() AS lastupdatetime, now() AS VERSION,
      0 AS rank,phys_id,-1,FALSE AS deleted;
  -- -13: Registered Nurse
  INSERT INTO person_role (issystemdefined,lastupdateuser,lastupdatetime,VERSION,
      rank,person_id,role_id,deleted)
	SELECT FALSE AS issystemdefined, 'DataImport' AS lastupdateuser, now() AS lastupdatetime, now() AS VERSION,
      1 AS rank,phys_id,-13,FALSE AS deleted;
  -- -6: Intern
  INSERT INTO person_role(issystemdefined,lastupdateuser,lastupdatetime,VERSION,
      rank,person_id,role_id,deleted)
	SELECT FALSE AS issystemdefined, 'DataImport' AS lastupdateuser, now() AS lastupdatetime, now() AS VERSION,
      2 AS rank,phys_id,-6,FALSE AS deleted;

  -- smartformresponse records
  -- Hummingbird User
  INSERT INTO smartformresponse (answer_id,
      question_id,
      issystemdefined,lastupdatetime,VERSION,deleted,lastupdateuser)
	SELECT (SELECT id AS answer_id FROM smartformanswer WHERE answertext = 'Yes' AND question_id =
  		  (SELECT id FROM smartformquestion WHERE questiontext = 'Hummingbird User' AND hospice_id IS NULL)) as answer_id,
  		(SELECT id AS question_id FROM smartformquestion WHERE questiontext = 'Hummingbird User' AND hospice_id IS NULL) as question_id,
  		FALSE,now(),now(),FALSE,'DATAIMPORT';
  -- associate response with person
  insert into person_smartformresponse
  INSERT INTO person_smartformresponse (person_id,smartformresponses_id)
 	    SELECT phys_id,(select last_value from smartformresponse_id_seq);

  -- Hospice Employee
  INSERT INTO smartformresponse (answer_id,
      question_id,
      issystemdefined,lastupdatetime,VERSION,deleted,lastupdateuser)
	SELECT (SELECT id AS answer_id FROM smartformanswer WHERE answertext = 'Yes' AND question_id =
  		  (SELECT id FROM smartformquestion WHERE questiontext = 'Hospice Employee' AND hospice_id IS NULL)) as answer_id,
  		(SELECT id AS question_id FROM smartformquestion WHERE questiontext = 'Hospice Employee' AND hospice_id IS NULL) as question_id,
  		FALSE,now(),now(),FALSE,'DATAIMPORT';
  -- associate response with person
  INSERT INTO person_smartformresponse (person_id,smartformresponses_id)
  	 SELECT phys_id,(select last_value from smartformresponse_id_seq);

  -- Full-Time Employee
  INSERT INTO smartformresponse (answer_id,
      question_id,
      issystemdefined,lastupdatetime,VERSION,deleted,lastupdateuser)
	SELECT (SELECT id AS answer_id FROM smartformanswer WHERE answertext = 'Full-Time' AND question_id =
  		  (SELECT id FROM smartformquestion WHERE questiontext = 'Employee Type' AND hospice_id IS NULL)) as answer_id,
  		(SELECT id AS question_id FROM smartformquestion WHERE questiontext = 'Employee Type' AND hospice_id IS NULL) as question_id,
  		FALSE,now(),now(),FALSE,'DATAIMPORT';
  -- associate response with person
  INSERT INTO person_smartformresponse (person_id,smartformresponses_id)
  	 SELECT phys_id,(select last_value from smartformresponse_id_seq);

  -- Adding Site/Programsite
  insert into person_site
  (select -48,id,row_number() over (order by id) as row
    from office
    where officetype ='Site' and deleted = false);

  insert into person_programsite
  (select -48,id,row_number() over (order by id) as row
    from programsite
    where deleted = false);

END;
$$;
