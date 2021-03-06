/*
  This file contains common functions that are useful writing reports
*/

-- You should uncomment this line to check syntax in IDE.  Liquibase handles this internally.
-- DELIMITER #

/*
How to use the fuctions
concept_from_mapping('source', 'code')
concept_name(concept_id, 'locale')
encounter_type(patient_id)
age_at_enc(person_id, encounter_id)
zlemr(patient_id)
unknown_patient(patient_id)
gender(patient_id)
person_address(patient_id)
loc_registered(patient)
provider(patient_id)
program(program_name)
relationship_type(name)
person_address_state_province(patient_id)
person_address_city_village(patient_id)
person_address_three(patient_id)
person_address_two(patient_id)
person_address_one(patient_id)

*/

/*
 get concept_id from report_mapping table
*/
#
DROP FUNCTION IF EXISTS concept_from_mapping;
#
CREATE FUNCTION concept_from_mapping(
	_source varchar(50),
    _code varchar(255)
)
    RETURNS INT
    DETERMINISTIC
BEGIN
    DECLARE mappedConcept INT;

	SELECT concept_id INTO mappedConcept FROM report_mapping WHERE source = _source and code = _code;

    RETURN mappedConcept;

END
#

/*
get names from the concept_name table
*/
#
DROP FUNCTION IF EXISTS concept_name;
#
CREATE FUNCTION concept_name(
    _conceptID INT,
    _locale varchar(50)
)
	RETURNS VARCHAR(255)
    DETERMINISTIC

BEGIN
    DECLARE conceptName varchar(255);

	SELECT name INTO conceptName
	FROM concept_name
	WHERE voided = 0
	  AND concept_id = _conceptID
	  AND locale = _locale
	  AND concept_name_type = 'FULLY_SPECIFIED';

    RETURN conceptName;
END
#

/*
    return encounter type id given name or uuid
*/
#
DROP FUNCTION IF EXISTS encounter_type;
#
CREATE FUNCTION encounter_type(
    _name_or_uuid varchar(255)
)
	RETURNS INT
    DETERMINISTIC

BEGIN
    DECLARE ret varchar(255);

	SELECT  encounter_type_id INTO ret
	FROM    encounter_type where name = _name_or_uuid or uuid = _name_or_uuid;

    RETURN ret;
END
#

/*
    return patient identifier type id
*/
#
DROP FUNCTION IF EXISTS patient_identifier;
#
CREATE FUNCTION patient_identifier(
    _patient_id int,
    _name_or_uuid varchar(255)
)
    RETURNS varchar(50)
    DETERMINISTIC

BEGIN
    DECLARE ret varchar(50);

    SELECT      i.identifier INTO ret
    FROM        patient_identifier i
    INNER JOIN  patient_identifier_type t on i.identifier_type = t.patient_identifier_type_id
    WHERE       (t.name = _name_or_uuid or t.uuid = _name_or_uuid)
    AND         i.voided = 0
    AND         i.patient_id = _patient_id
    ORDER BY    preferred desc, i.date_created desc limit 1;

    RETURN ret;
END
#

/*
 get patient age at encounter
*/
#
DROP FUNCTION IF EXISTS age_at_enc;
#
CREATE FUNCTION age_at_enc(
    _person_id int,
    _encounter_id int
)
	RETURNS DOUBLE
    DETERMINISTIC

BEGIN
    DECLARE ageAtEnc DOUBLE;

	select  TIMESTAMPDIFF(YEAR, birthdate, encounter_datetime) into ageAtENC
	from    encounter e
	join    person p on p.person_id = e.patient_id
	where   e.encounter_id = _encounter_id
	and     p.person_id = _person_id;

    RETURN ageAtEnc;
END
#

/*
get patient EMR ZL
*/
#
DROP FUNCTION IF EXISTS zlemr;
#
CREATE FUNCTION zlemr(
    _patient_id int
)
	RETURNS VARCHAR(255)
    DETERMINISTIC

BEGIN
    DECLARE  zlEMR VARCHAR(255);
    SELECT patient_identifier(_patient_id, 'ZL EMR ID') into zlEMR;
    RETURN zlEMR;
END
#

DROP FUNCTION IF EXISTS dosId;
#

CREATE FUNCTION dosId (patient_id_in int(11))
RETURNS varchar(50)

DETERMINISTIC

BEGIN

DECLARE dosId_out varchar(50);

select identifier into dosId_out
from patient_identifier pid
where pid.patient_id = patient_id_in
and pid.voided = 0
and pid.identifier_type = 
  (select patient_identifier_type_id from patient_identifier_type where uuid = 'e66645eb-03a8-4991-b4ce-e87318e37566')
order by pid.preferred desc, pid.date_created asc limit 1   
;

RETURN dosId_out;

END;
#
/*
unknown patient
*/
#
DROP FUNCTION IF EXISTS unknown_patient;
#
CREATE FUNCTION unknown_patient(
    _patient_id int
)
	RETURNS VARCHAR(50)
    DETERMINISTIC

BEGIN
    DECLARE  unknownPatient VARCHAR(50);

	select person_id into unknownPatient from person_attribute where person_attribute_type_id = (select person_attribute_type_id from
person_attribute_type where name = 'Unknown patient') and voided = 0 and person_id = _patient_id;

    RETURN unknownPatient;

END
#
/*
person_attribute_value
*/
#
DROP FUNCTION IF EXISTS person_attribute_value;
#
CREATE FUNCTION person_attribute_value(
    _patient_id int,
    _att_type_name varchar(50)
)
    RETURNS VARCHAR(50)
    DETERMINISTIC

BEGIN
    DECLARE  attVal VARCHAR(50);

    select      a.value into attVal
    from        person_attribute a
    inner join  person_attribute_type pat on a.person_attribute_type_id = pat.person_attribute_type_id
    where       pat.name = _att_type_name
    and         a.voided = 0
    and         a.person_id = _patient_id
    order by    a.date_created desc
    limit       1;

    RETURN attVal;

END
#

/*
gender
*/
#
DROP FUNCTION IF EXISTS gender;
#
CREATE FUNCTION gender(
    _patient_id int
)
	RETURNS VARCHAR(50)
    DETERMINISTIC

BEGIN
    DECLARE  patientGender VARCHAR(50);

	select gender into patientGender from person where person_id = _patient_id and voided =0;

    RETURN patientGender;

END
#

/*
 patient address
*/
#
DROP FUNCTION IF EXISTS person_address;
#
CREATE FUNCTION person_address(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddress TEXT;

	select concat(IFNULL(state_province,''), ',' ,IFNULL(city_village,''), ',', IFNULL(address3,''), ',', IFNULL(address1,''), ',',IFNULL(address2,'')) into patientAddress
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddress;

END
#
/*
 patient name
*/
#
DROP FUNCTION IF EXISTS person_name;
#
CREATE FUNCTION person_name(
    _person_id int
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE personName TEXT;

    select      concat(given_name, ' ', family_name) into personName
    from        person_name
    where       voided = 0
    and         person_id = _person_id
    order by    preferred desc, date_created desc
    limit       1;

    RETURN personName;

END
#

/*
  ZL EMR ID location
*/
#
DROP FUNCTION IF EXISTS loc_registered;
#
CREATE FUNCTION loc_registered(
    _patient_id int
)
	RETURNS VARCHAR(255)
    DETERMINISTIC

BEGIN
    DECLARE locRegistered varchar(255);

select name into locRegistered from location l join patient_identifier pi on pi.location_id = l.location_id and pi.voided = 0 and pi.patient_id = _patient_id
and identifier_type = (select pid2.patient_identifier_type_id from patient_identifier_type pid2 where
 pid2.name = 'ZL EMR ID');

    RETURN locRegistered;

END
#
/*
Provider
*/
#
DROP FUNCTION IF EXISTS provider;
#
CREATE FUNCTION provider (
    _encounter_id int
) 
	RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE providerName varchar(255);

select CONCAT(given_name, ' ', family_name) into providerName
from person_name pn join provider pv on pn.person_id = pv.person_id AND pn.voided = 0 
join encounter_provider ep on pv.provider_id = ep.provider_id and ep.voided = 0 and ep.encounter_id = _encounter_id;
    
    RETURN providerName;
    
END
#
/*
Encounter Location
*/
#
DROP FUNCTION IF EXISTS encounter_location_name;
#
CREATE FUNCTION encounter_location_name (
    _encounter_id int
)
    RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE locName varchar(255);

    select      l.name into locName
    from        encounter e
    inner join  location l on l.location_id = e.location_id
    where       e.encounter_id = _encounter_id;

    RETURN locName;
END
#
/*
Encounter Date
*/
#
DROP FUNCTION IF EXISTS encounter_date;
#
CREATE FUNCTION encounter_date (
    _encounter_id int
)
    RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE encDate datetime;

    select      e.encounter_datetime into encDate
    from        encounter e
    where       e.encounter_id = _encounter_id;

    RETURN encDate;
END
#
/*
Visit date
*/
#
DROP FUNCTION IF EXISTS visit_date;
#
CREATE FUNCTION visit_date(
    _patient_id int
)
	RETURNS DATE
    DETERMINISTIC

BEGIN
    DECLARE visitDate date;

    select date(date_started) into visitDate from visit where voided = 0 and visit_id = (select visit_id from encounter where encounter_type = @encounter_type)
and patient_id = _patient_id;

    RETURN visitDate;

END
#
/*
Program
*/
#
DROP FUNCTION IF EXISTS program;
#
CREATE FUNCTION program(_name varchar (255))
	RETURNS INT
    DETERMINISTIC

BEGIN
    DECLARE programId int;

    select program_id into programId from program where retired = 0 and name = _name;

    RETURN programId;

END
#
/*
Relationship
*/
#
DROP FUNCTION IF EXISTS relation_type;
#
CREATE FUNCTION relation_type(
    _name VARCHAR(255)
)
	RETURNS INT
    DETERMINISTIC

BEGIN
    DECLARE relationshipID INT;

	SELECT relationship_type_id INTO relationshipID FROM relationship_type WHERE retired = 0 AND a_is_to_b = _name;

    RETURN relationshipID;
END
#

#

/*
 patient address
*/

#
DROP FUNCTION IF EXISTS person_address_state_province;
#
CREATE FUNCTION person_address_state_province(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressStateProvince TEXT;

	select state_province into patientAddressStateProvince
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressStateProvince;

END
#

#
DROP FUNCTION IF EXISTS person_address_city_village;
#
CREATE FUNCTION person_address_city_village(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressCityVillage TEXT;

	select city_village into patientAddressCityVillage
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressCityVillage;

END
#

#
DROP FUNCTION IF EXISTS person_address_three;
#
CREATE FUNCTION person_address_three(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressThree TEXT;

	select address3 into patientAddressThree
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressThree;

END
#

#
DROP FUNCTION IF EXISTS person_address_one;
#
CREATE FUNCTION person_address_one(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressOne TEXT;

	select address1 into patientAddressOne
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressOne;

END
#

#
DROP FUNCTION IF EXISTS person_address_two;
#
CREATE FUNCTION person_address_two(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressTwo TEXT;

	select address2 into patientAddressTwo
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressTwo;

END
#

-- This function accepts a patient_id, concept_id and beginDate
-- It will return the obs_id of the most recent observation for that patient and concept_id SINCE the beginDate
-- if null is passed in as the beginDate, it will be disregarded
-- example: select latestObs(311450, 357, '2020-01-01') or select latestObs(311450, 357, '2020-02-12 08:59:59');

#
DROP FUNCTION IF EXISTS latestObs;
#
CREATE FUNCTION latestObs (patient_id_in int(11), concept_id_in int (11), beginDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE obs_id_out int(11);

    select obs_id into obs_id_out
    from obs o
    where o.voided = 0
      and o.person_id = patient_id_in
      and o.concept_id = concept_id_in
      and (beginDate is null or o.obs_datetime >= beginDate)
    order by o.obs_datetime desc
    limit 1;

    RETURN obs_id_out;

END
#

-- This function accepts patient_id, encounter_type and beginDate
-- It will return the latest encounter id if the patient
-- if null is passed in as the beginDate, it will be disregarded

#
DROP FUNCTION IF EXISTS latestEnc;
#
CREATE FUNCTION latestEnc(_patientId int(11), _encounterTypes varchar(255), _beginDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      encounter_id into enc_id_out
    from        encounter enc inner join encounter_type et on enc.encounter_type = et.encounter_type_id
    where       enc.voided = 0
    and         enc.patient_id = _patientId
    and         find_in_set(et.name, _encounterTypes)
    and         (_beginDate is null or enc.encounter_datetime >= _beginDate)
    order by    enc.encounter_datetime desc
    limit       1;

    RETURN enc_id_out;

END
#

-- This function accepts patient_id, encounter_type, beginDate, endDate
-- It will return the latest encounter of the specified type that it finds for the patient between the dates
-- Null date values can be used to indicate no constraint

#
DROP FUNCTION IF EXISTS latestEncBetweenDates;
#
CREATE FUNCTION latestEncBetweenDates(_patientId int(11), _encounterTypes varchar(255), _beginDate datetime, _endDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      encounter_id into enc_id_out
    from        encounter enc inner join encounter_type et on enc.encounter_type = et.encounter_type_id
    where       enc.voided = 0
      and       enc.patient_id = _patientId
      and       find_in_set(et.name, _encounterTypes)
      and       (_beginDate is null or enc.encounter_datetime >= _beginDate)
      and       (_endDate is null or enc.encounter_datetime <= _endDate)
    order by    enc.encounter_datetime desc
    limit       1;

    RETURN enc_id_out;

END
#

-- This function accepts patient_id, encounter_type and beginDate
-- It will return the first encounter of the specified type that it finds for the patient after the passed beginDate
-- if null is passed in as the beginDate, it will be disregarded

#
DROP FUNCTION IF EXISTS firstEnc;
#
CREATE FUNCTION firstEnc(_patientId int(11), _encounterTypes varchar(255), _beginDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      encounter_id into enc_id_out
    from        encounter enc inner join encounter_type et on enc.encounter_type = et.encounter_type_id
    where       enc.voided = 0
      and       enc.patient_id = _patientId
      and       find_in_set(et.name, _encounterTypes)
      and       (_beginDate is null or enc.encounter_datetime >= _beginDate)
    order by    enc.encounter_datetime asc
    limit       1;

    RETURN enc_id_out;

END
#

/**
  FUNCTIONS TO RETRIEVE OBSERVATION VALUES FROM A GIVEN ENCOUNTER
*/

-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_text
#
DROP FUNCTION IF EXISTS obs_value_text;
#
CREATE FUNCTION obs_value_text(_encounterId int(11), _source varchar(50), _term varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      o.value_text into ret
    from        obs o
    where       o.voided = 0
    and         o.encounter_id = _encounterId
    and         o.concept_id = concept_from_mapping(_source, _term)
    order by    o.date_created desc, o.obs_id desc
    limit 1;

    RETURN ret;

END

#

-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_text
#
DROP FUNCTION IF EXISTS obs_value_coded_list;
#
CREATE FUNCTION obs_value_coded_list(_encounterId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        obs o
    where       o.voided = 0
      and       o.encounter_id = _encounterId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#

-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_numeric
#
DROP FUNCTION IF EXISTS obs_value_numeric;
#
CREATE FUNCTION obs_value_numeric(_encounterId int(11), _source varchar(50), _term varchar(255))
RETURNS double
DETERMINISTIC

BEGIN

DECLARE ret double;

select      o.value_numeric into ret
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1;

RETURN ret;

END

#
-- This function accepts visit_id, mapping source, mapping code
-- It will find the value_coded entries that match this, separated by | 
#
DROP FUNCTION IF EXISTS obs_from_visit_value_coded_list;
#
CREATE FUNCTION obs_from_visit_value_coded_list(_visitId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        obs o
    inner join encounter e on o.encounter_id = e.encounter_id and e.voided = 0
    where       o.voided = 0
      and       e.visit_id = _visitId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#

-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the value_coded entries that match this, separated by | 

#

DROP FUNCTION IF EXISTS obs_from_group_id_value_coded_list;
#
CREATE FUNCTION obs_from_group_id_value_coded_list(_obsGroupId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#
-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the value_text entry that matches this
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_text;
#
CREATE FUNCTION obs_from_group_id_value_text(_obsGroupId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      value_text into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#
   
-- This function accepts encounter_id, mapping source, mapping code
-- It will find the obs_id of the matching observation    
    
#
DROP FUNCTION IF EXISTS obs_id;
#
CREATE FUNCTION obs_id(_encounterId int(11), _source varchar(50), _term varchar(255), _offset_value int)
RETURNS int
DETERMINISTIC

BEGIN

DECLARE ret int;

select      o.obs_id into ret
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1
offset _offset_value
;

RETURN ret;

END
#
/*
 get global property value
*/
#
DROP FUNCTION IF EXISTS global_property_value;
#
CREATE FUNCTION global_property_value(
    _property varchar(255),
    _defaultValue text
)
    RETURNS text
    DETERMINISTIC
BEGIN
    DECLARE val text;

    SELECT property_value into val FROM global_property where property = _property;
    SELECT if(val is null || val = '', _defaultValue, val) into val;

    return val;

END
#

/*
 get global property value
*/
#
DROP FUNCTION IF EXISTS user_property_value;
#
CREATE FUNCTION user_property_value(
    _userId int,
    _property varchar(1000),
    _defaultValue text
)
    RETURNS text
    DETERMINISTIC
BEGIN
    DECLARE val text;

    SELECT property_value into val FROM user_property where user_id = _userId and property = _property;
    SELECT if(val is null || val = '', _defaultValue, val) into val;

    return val;

END
#

/*
 get metadata mapping uuid
*/
#
DROP FUNCTION IF EXISTS metadata_uuid;
#
CREATE FUNCTION metadata_uuid(
    _sourceName varchar(255),
    _codeName varchar(255)
)
    RETURNS varchar(38)
    DETERMINISTIC
BEGIN
    DECLARE ret varchar(38);

    select      m.metadata_uuid into ret
    from        metadatamapping_metadata_term_mapping m
    inner join  metadatamapping_metadata_source s on s.metadata_source_id = m.metadata_source_id
    where       s.name = _sourceName
    and         m.code = _codeName;

    return ret;
END
#

-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_datetime
#
DROP FUNCTION IF EXISTS obs_value_datetime;
#
CREATE FUNCTION obs_value_datetime(_encounterId int(11), _source varchar(50), _term varchar(255))
RETURNS datetime
DETERMINISTIC

BEGIN

DECLARE ret datetime;

select      o.value_datetime into ret
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1;

RETURN ret;

END

#

-- This function accepts encounter_id, mapping source, mapping code (for both the concept_id and value_coded) and returns
-- true if the obs_id exists and
-- null if the obs_id does not exisit
-- This function is used on questions that also act as answers (i.e you either check it as true or your don't)
#
DROP FUNCTION IF EXISTS obs_single_value_coded;
#
CREATE FUNCTION obs_single_value_coded(_encounterId int(11), _source varchar(50), _term varchar(255), _source1 varchar(50), _term1 varchar(255))
RETURNS varchar(11)
DETERMINISTIC

BEGIN

DECLARE ret varchar(11);

select      IFNULL(NULL, "Yes") into ret FROM
(
select      obs_id
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
and         o.value_coded = concept_from_mapping(_source1, _term1)
order by    o.date_created desc, o.obs_id desc
limit 1
) obs_single_question_answer;

RETURN ret;

END

#
