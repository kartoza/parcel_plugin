

ALTER TABLE parcel_lookup ADD COLUMN scheme integer;
ALTER TABLE parcel_lookup ADD COLUMN  block character varying;
ALTER TABLE parcel_lookup ADD COLUMN local_govt integer;
--ALTER TABLE parcel_lookup DROP COLUMN prop_type; 
ALTER TABLE parcel_lookup ADD COLUMN prop_type character varying;
ALTER TABLE parcel_lookup ADD COLUMN file_number character varying;
ALTER TABLE parcel_lookup ADD COLUMN allocation integer;
ALTER TABLE parcel_lookup ADD COLUMN manual_no character varying;

--remove any non integer parcel_id's to temporary 'manual_no' field
--'convert' parcel_id from char var to int field

update parcel_lookup set manual_no = parcel_id;

ALTER TABLE parcel_lookup RENAME id  TO serial;

update parcel_lookup set parcel_id = serial;


ALTER TABLE parcel_lookup
   ADD COLUMN parcel_temp integer;

update parcel_lookup set parcel_temp = parcel_id::integer;

ALTER TABLE parcel_def drop constraint parcel_def_parcel_id_fkey;

ALTER TABLE parcel_lookup DROP COLUMN parcel_id;

ALTER TABLE parcel_lookup RENAME parcel_temp  TO parcel_id;

ALTER TABLE parcel_def
   ADD COLUMN parcel_temp integer;

update parcel_def set parcel_temp = parcel_id::integer;

DROP VIEW parcels;



ALTER TABLE parcel_def DROP COLUMN parcel_id;

ALTER TABLE parcel_def RENAME parcel_temp  TO parcel_id;

--drop view parcels;
CREATE OR REPLACE VIEW parcels AS
SELECT parcel.*, description.parcel_number, description.block, description.scheme, 
	description.file_number,description.allocation,description.owner FROM 
 (SELECT int4(row_number() OVER (ORDER BY vl.parcel_id)) AS id, vl.parcel_id, 
 st_makepolygon(st_addpoint(st_makeline(vl.geom),st_startpoint(st_makeline(vl.geom)))) AS the_geom
   FROM ( SELECT pd.id, pd.parcel_id, pd.beacon, pd.sequence, b.geom
           FROM beacons b
      JOIN parcel_def pd ON b.beacon::text = pd.beacon::text
     ORDER BY pd.parcel_id, pd.sequence) vl
  GROUP BY vl.parcel_id
 HAVING st_npoints(st_collect(vl.geom)) > 1) AS parcel
 INNER JOIN
(SELECT p.parcel_id,p.local_govt || p.prop_type || p.serial AS parcel_number, p.allocation,p.block,s.scheme_name AS scheme,p.file_number,d.grantee AS owner 
FROM parcel_lookup p, deeds d, schemes s WHERE p.file_number=d.file_no AND p.scheme = s.id) AS description
USING (parcel_id);

ALTER TABLE parcel_lookup ADD UNIQUE (parcel_id);


ALTER TABLE parcel_def ADD CONSTRAINT parcel_def_parcel_id_fkey FOREIGN KEY (parcel_id)
      REFERENCES parcel_lookup (parcel_id) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;


CREATE TABLE schemes 
(
  id serial NOT NULL,
  scheme_name character varying(50) NOT NULL,
  CONSTRAINT schemes_pkey PRIMARY KEY (id ),
  CONSTRAINT schemes_id_key UNIQUE (scheme_name)
)
WITH (
  OIDS=FALSE
);

CREATE TABLE local_govt
(
  id serial NOT NULL,
  local_govt_name character varying(50) NOT NULL,
  CONSTRAINT local_govt_pkey PRIMARY KEY (id ),
  CONSTRAINT local_govt_id_key UNIQUE (local_govt_name )
)
WITH (
  OIDS=FALSE
);


--DROP TABLE prop_types;
CREATE TABLE prop_types
(
  id serial NOT NULL,
  code character varying(2) NOT NULL,
  prop_type_name character varying(50) NOT NULL,
  CONSTRAINT prop_type_pkey PRIMARY KEY (id ),
  CONSTRAINT prop_type_id_key UNIQUE (prop_type_name ),
  CONSTRAINT prop_type_code_key UNIQUE (code )
)
WITH (
  OIDS=FALSE
);

CREATE TABLE allocation_cat
(
  allocation_cat integer NOT NULL,
  description character varying(50) NOT NULL,
  CONSTRAINT allocation_cat_pkey PRIMARY KEY (allocation_cat )
)
WITH (
  OIDS=FALSE
);


ALTER TABLE parcel_lookup ADD CONSTRAINT parcel_lookup_scheme_id_fkey FOREIGN KEY (scheme)
      REFERENCES schemes (id) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE parcel_lookup ADD CONSTRAINT parcel_lookup_local_govt_id_fkey FOREIGN KEY (local_govt)
      REFERENCES local_govt (id) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;

--ALTER TABLE parcel_lookup DROP CONSTRAINT parcel_lookup_prop_type_id_fkey
ALTER TABLE parcel_lookup ADD CONSTRAINT parcel_lookup_prop_type_id_fkey FOREIGN KEY (prop_type)
      REFERENCES prop_types (code) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE parcel_lookup ADD CONSTRAINT parcel_lookup_allocation_id_fkey FOREIGN KEY (allocation)
      REFERENCES allocation_cat (allocation_cat) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;


INSERT INTO allocation_cat (allocation_cat,description) VALUES
(0 ,'free and unallocated parcel'),
(1 ,'temporary allocation pending approval'),
(2 ,'parcel allocated and approved');

INSERT INTO schemes (scheme_name) VALUES
('Olusegun Obasanjo Hilltop GRA Layout');

INSERT INTO local_govt (local_govt_name) VALUES
('Abeokuta South');

INSERT INTO prop_types (code,prop_type_name) VALUES
('AL','Allocation');

--load deeds
--shp2pgsql -n -c deeds_sample.dbf deeds | psql -d sml