/*
 * This script will correct the patient name and demographic information for the patients that are
 * linked to DrFirst patients with Medication history in their staging environment. The patients
 * effected are:
 *      102571 - Bruce Wayne
 *      102876 - Chenin Blanc Aubaine
 *      102206 - Kyle, Selena
 *
 * This script will attempt to...
 *  - Ensure the patient's name, date of birth, sex on the 'patient' table is in sync with DrFirst values
 *  - Ensure that the patient's currentstatus is "Admitted"
 *  - *Ensure the patient's address in the 'address' table is in sync with the DrFirst values
 *  - *Ensure that the patient's phone number is in sync with the DrFirst values
 *
 *  *these are optional but will result in a more complete representation of the DrFirst patient in PIM/M2.
 */

begin;

SELECT id, patientnumber, firstname, lastname, dateofbirth, sex, currentstatus, lastupdatetime, lastupdateuser
FROM patient
WHERE patientnumber = any(array['102571','102876','102206']);

-- Wayne, Bruce (102571)...
UPDATE  patient
SET     firstname       =   'Bruce',
        lastname        =   'Wayne',
        dateofbirth     =   '1946-02-06',
        sex             =   'Male',
        lastupdatetime  =   now(),
        lastupdateuser  =   'DrFirstSync'
WHERE   patientnumber   =   '102571';

-- Aubaine, Chenin Blanc (102876)...
UPDATE  patient
SET     firstname       =   'Chenin Blanc',
        lastname        =   'Aubaine',
        dateofbirth     =   '1954-09-01',
        sex             =   'Female',
        lastupdatetime  =   now(),
        lastupdateuser  =   'DrFirstSync'
WHERE   patientnumber   =   '102876';

-- Kyle, Selena (102206)...
UPDATE  patient
SET     firstname       =   'Selena',
        lastname        =   'Kyle',
        dateofbirth     =   '1966-10-11',
        sex             =   'Female',
        lastupdatetime  =   now(),
        lastupdateuser  =   'DrFirstSync'
WHERE   patientnumber   =   '102206';


-- Fix up the patient's status
SELECT  p.id            AS  patient_id,
        p.patientnumber AS  patientnummber,
        p.firstname     AS  firstname,
        p.lastname      AS  lastname,
        p.currentstatus AS  currentstatus,
        (CASE p.currentstatus
            WHEN 'Admitted' THEN 'No action needed'
            ELSE 'Please fix the status for this patient.'
         END)               AS action_needed
FROM    patient         p
WHERE   p.patientnumber = ANY(ARRAY['102571','102876','102206']);

/*
 * Finish flushing this out so that we actually change the patient's current status
select  (case ps.)
from    patientstatus   ps  join
        patientinteraction  pi  on  pi.id   =   ps.interaction_id   join
        patient             p   on  p.id    =   pi.patient_id
where   p.patientnumber     =   '102571';
*/

rollback;
-- commit;
