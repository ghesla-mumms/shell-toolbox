#!/bin/bash
#####
# addPatientToIDGMeeting.#!/bin/sh
#
# This script add a patient to an existing IDG meeting. It is useful for adding
# a patient to an in-process meeting. Otherwise, the user could just push the
# refersh button to add missing patients.
#
# https://jira.mumms.com/browse/OP-28899
#####
LASTUPDATEUSER=$(whoami)
PATIENTNUMBER="1701"
TEAMNAME="North"
MEETINGID=

# Get the meeting id for the current meeting for the team
MEETINGID=$(psql -h hb-rootdb.mumms.com -d hb_demo1 -t -c "select id from idgteams.idgmeeting where teamname = '${TEAMNAME}' and stopdate is null;" | xargs)

# insert patient into idgpatientagenda
insert into idgteams.idgpatientagenda (issystemdefined, version, lastupdatetime, lastupdateuser, idgmeeting_id, agency_id, agency, patient_id, patientnumber, discussionstatus)
(select false, now(), now(), '${LASTUPDATEUSER}', ${MEETINGID}, h.id, h.bin, p.id, p.patientnumber, 'NOT_DISCUSSED'
  from patient p, hospice h
  where p.patientnumber = '${PATIENTNUMBER}'
  and not exists (select 1 from idgteams.idgpatientagenda where idgmeeting_id = ${MEETINGID} and patient_id = p.id));

# Get the id for the idgpatientagenda row we just inserted
PATIENTAGENDAID=$(psql -h hb-rootdb.mumms.com -d hb_demo1 -t -c "select id from idgteams.idgpatientagenda where idgmeeting_id = ${MEETINGID} and patientnumber = '${PATIENTNUMBER}';" | xargs)

# TODO: Add idgteams.idgpatientagendaitem records to store the "dots" indicating what changed
insert into idgteams.idgpatientagendaitem (issystemdefined, version, lastupdatetime, lastupdateuser, agenda_id, patientagenda_id)
(select false, now(), now(), '${LASTUPDATEUSER}', a.id, ${PATIENTAGENDAID}
  from idgteams.idgagenda a
  where a.abbreviation = 'DEC'
  and exists ({patient is Recently Deceased}))

insert into idgteams.idgpatientagendaitem (issystemdefined, version, lastupdatetime, lastupdateuser, agenda_id, patientagenda_id)
(select false, now(), now(), '${LASTUPDATEUSER}', a.id, ${PATIENTAGENDAID}
  from idgteams.idgagenda a
  where a.abbreviation = 'ADM'
  and exists (/patient is Recently Admitted/))

insert into idgteams.idgpatientagendaitem (issystemdefined, version, lastupdatetime, lastupdateuser, agenda_id, patientagenda_id)
(select false, now(), now(), '${LASTUPDATEUSER}', a.id, ${PATIENTAGENDAID}
  from idgteams.idgagenda a
  where a.abbreviation = 'RCT'
  and exists (/patient is Recently Certified/))

insert into idgteams.idgpatientagendaitem (issystemdefined, version, lastupdatetime, lastupdateuser, agenda_id, patientagenda_id)
(select false, now(), now(), '${LASTUPDATEUSER}', a.id, ${PATIENTAGENDAID}
  from idgteams.idgagenda a
  where a.abbreviation = 'NCT'
  and exists (/patient is Recertifies Next Week/))

insert into idgteams.idgpatientagendaitem (issystemdefined, version, lastupdatetime, lastupdateuser, agenda_id, patientagenda_id)
(select false, now(), now(), '${LASTUPDATEUSER}', a.id, ${PATIENTAGENDAID}
  from idgteams.idgagenda a
  where a.abbreviation = 'TMA'
  and exists (/patient is Team Arrival/))

insert into idgteams.idgpatientagendaitem (issystemdefined, version, lastupdatetime, lastupdateuser, agenda_id, patientagenda_id)
(select false, now(), now(), '${LASTUPDATEUSER}', a.id, ${PATIENTAGENDAID}
  from idgteams.idgagenda a
  where a.abbreviation = 'TMD'
  and exists (/patient is Team Departure/))

# insert the idgpatientreview records in order...
## Team Review and Acceptance (not an actual rolegroup)
insert into idgteams.idgpatientreview (issystemdefined, version, lastupdatetime, lastupdateuser, patientagenda_id, agency, rolegroup_id, rolegroupname)
(select false, now(), now(), '${LASTUPDATEUSER}', ${PATIENTAGENDAID}, h.bin, null, 'Team Review and Acceptance'
  from hospice h
  where not exists (select 1 from idgteams.idgpatientreview pr where pr.patientagenda_id = ${PATIENTAGENDAID} and rolegroupname = 'Team Review and Acceptance'));
## Doctor
insert into idgteams.idgpatientreview (issystemdefined, version, lastupdatetime, lastupdateuser, patientagenda_id, agency, rolegroup_id, rolegroupname)
(select false, now(), now(), '${LASTUPDATEUSER}', ${PATIENTAGENDAID}, h.bin, rg.id, rg.name
  from hospice h cross join rolegroup rg
  where rg.name = 'Doctor'
  and not exists (select 1 from idgteams.idgpatientreview pr where pr.patientagenda_id = ${PATIENTAGENDAID} and rolegroup_id = rg.id));
## Nurse
insert into idgteams.idgpatientreview (issystemdefined, version, lastupdatetime, lastupdateuser, patientagenda_id, agency, rolegroup_id, rolegroupname)
(select false, now(), now(), '${LASTUPDATEUSER}', ${PATIENTAGENDAID}, h.bin, rg.id, rg.name
  from hospice h cross join rolegroup rg
  where rg.name = 'Nurse'
  and not exists (select 1 from idgteams.idgpatientreview pr where pr.patientagenda_id = ${PATIENTAGENDAID} and rolegroup_id = rg.id));
## Social Worker
insert into idgteams.idgpatientreview (issystemdefined, version, lastupdatetime, lastupdateuser, patientagenda_id, agency, rolegroup_id, rolegroupname)
(select false, now(), now(), '${LASTUPDATEUSER}', ${PATIENTAGENDAID}, h.bin, rg.id, rg.name
  from hospice h cross join rolegroup rg
  where rg.name = 'Social Worker'
  and not exists (select 1 from idgteams.idgpatientreview pr where pr.patientagenda_id = ${PATIENTAGENDAID} and rolegroup_id = rg.id));
## Spiritual
insert into idgteams.idgpatientreview (issystemdefined, version, lastupdatetime, lastupdateuser, patientagenda_id, agency, rolegroup_id, rolegroupname)
(select false, now(), now(), '${LASTUPDATEUSER}', ${PATIENTAGENDAID}, h.bin, rg.id, rg.name
  from hospice h cross join rolegroup rg
  where rg.name = 'Spiritual'
  and not exists (select 1 from idgteams.idgpatientreview pr where pr.patientagenda_id = ${PATIENTAGENDAID} and rolegroup_id = rg.id));
## Volunteer Coordinator
insert into idgteams.idgpatientreview (issystemdefined, version, lastupdatetime, lastupdateuser, patientagenda_id, agency, rolegroup_id, rolegroupname)
(select false, now(), now(), '${LASTUPDATEUSER}', ${PATIENTAGENDAID}, h.bin, rg.id, rg.name
  from hospice h cross join rolegroup rg
  where rg.name = 'Volunteer Coordinator'
  and not exists (select 1 from idgteams.idgpatientreview pr where pr.patientagenda_id = ${PATIENTAGENDAID} and rolegroup_id = rg.id));

TEAMREVIEWID=$(psql -h hb-rootdb.mumms.com -d hb_demo1 -t -c "select id from idgteams.idgpatientreview where patientagenda_id = ${PATIENTAGENDAID} and rolegroupname = 'Team Review and Acceptance';" | xargs)

# Insert reviewtopics for the Team Review and Acceptance - This adds the "IDG has reviewed...", "Imminence of Death", and "Expected Discharge Date" fields for this review
## Add "IDG has reviewed..."
insert into idgteams.idgpatientreviewtopic (issystemdefined, version, lastupdatetime, lastupdateuser, patientreview_id, fieldtype, reviewtopicverbiage_id)
values (false, now(), now(), '${LASTUPDATEUSER}', ${TEAMREVIEWID}, 'RADIOBUTTON', -1);

## Add "Imminence of Death?"
insert into idgteams.idgpatientreviewtopic (issystemdefined, version, lastupdatetime, lastupdateuser, patientreview_id, fieldtype, reviewtopicverbiage_id)
values (false, now(), now(), '${LASTUPDATEUSER}', ${TEAMREVIEWID}, 'DROPDOWN', -4);

## Add "Expected Discharge Date"
insert into idgteams.idgpatientreviewtopic (issystemdefined, version, lastupdatetime, lastupdateuser, patientreview_id, fieldtype, reviewtopicverbiage_id)
values (false, now(), now(), '${LASTUPDATEUSER}', ${TEAMREVIEWID}, 'DATEBOX', -9);
