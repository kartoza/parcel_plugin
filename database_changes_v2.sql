

ALTER TABLE parcel_lookup ADD COLUMN scheme integer;
ALTER TABLE parcel_lookup ADD COLUMN  block character varying;
ALTER TABLE parcel_lookup ADD COLUMN local_govt integer;
--ALTER TABLE parcel_lookup DROP COLUMN prop_type; 
ALTER TABLE parcel_lookup ADD COLUMN prop_type character varying;
ALTER TABLE parcel_lookup ADD COLUMN file_number character varying;
ALTER TABLE parcel_lookup ADD COLUMN allocation integer;
ALTER TABLE parcel_lookup ADD COLUMN manual_no character varying;
ALTER TABLE parcel_lookup ADD COLUMN deeds_file character varying;

--remove any non integer parcel_id's to temporary 'manual_no' field
--'convert' parcel_id from char var to int field

update parcel_lookup set manual_no = parcel_id;

--update parcel_def p set parcel_id = pl.parcel_id from parcel_lookup pl where pl.manual_no = p.parcel_id

ALTER TABLE parcel_lookup RENAME id  TO serial;
ALTER TABLE parcel_lookup RENAME serial  TO plot_sn;
ALTER TABLE parcel_lookup
   ALTER COLUMN plot_sn DROP DEFAULT;
COMMENT ON COLUMN parcel_lookup.plot_sn IS 'plot serial no within a block. Forms part of the parcel no';


ALTER TABLE parcel_lookup DROP CONSTRAINT parcel_lookup_pkey;
ALTER TABLE parcel_lookup ADD PRIMARY KEY (parcel_id);
--ALTER TABLE parcel_lookup DROP CONSTRAINT parcel_lookup_parcel_id_key;


update parcel_lookup set parcel_id = serial;

---------------------
ALTER TABLE parcel_lookup
   ADD COLUMN parcel_temp integer;

update parcel_lookup set parcel_temp = parcel_id::integer;

ALTER TABLE parcel_def drop constraint parcel_def_parcel_id_fkey;

ALTER TABLE parcel_lookup DROP COLUMN parcel_id;

ALTER TABLE parcel_lookup RENAME parcel_temp  TO parcel_id;

ALTER TABLE parcel_def
   ADD COLUMN parcel_temp integer;

    DROP TRIGGER parcel_lookup_define_parcel ON public.parcel_def;
DROP TRIGGER parcel_lookup_availability_trigger  ON public.parcel_def;

update parcel_def set parcel_temp = parcel_id::integer;

DROP VIEW parcels;



ALTER TABLE parcel_def DROP COLUMN parcel_id;

ALTER TABLE parcel_def RENAME parcel_temp  TO parcel_id;

--create vew parcels...
--add constraint parcel_def_parcel_id_fkey
--set parcel_id as pk of parcel_lookup
--set permissions
--reinstate triggers
--refresh parcels on geoserver and 1Map
CREATE SEQUENCE parcel_lookup_parcel_id_seq;
ALTER TABLE parcel_lookup
   ALTER COLUMN parcel_id SET DEFAULT nextval('parcel_lookup_parcel_id_seq');

ALTER SEQUENCE parcel_lookup_parcel_id_seq OWNED BY parcel_lookup.parcel_id;
--then set sequence to start in right place.

-------------------------------

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

--int4(row_number() OVER (ORDER BY vl.parcel_id)) AS gid, 
--drop view parcels;
CREATE OR REPLACE VIEW parcels AS
	SELECT parcel.*, round(st_area(parcel.the_geom)::numeric,3)::double precision AS comp_area,description.official_area,description.parcel_number, description.block, description.scheme, 
		description.file_number,description.allocation,description.owner,
		'<a href="http://192.168.10.12/geoserver/'||description.deeds_file
		||'" target="blank_">'||description.deeds_file||'</a>' AS deeds_file FROM 
	 (SELECT int4(vl.parcel_id) as parcel_id, 
	 st_makepolygon(st_addpoint(st_makeline(vl.the_geom),st_startpoint(st_makeline(vl.the_geom))))::geometry(Polygon,26331)  AS the_geom
	   FROM ( SELECT pd.id, pd.parcel_id, pd.beacon, pd.sequence, b.the_geom
	           FROM beacons b
	      JOIN parcel_def pd ON b.beacon::text = pd.beacon::text
	     ORDER BY pd.parcel_id, pd.sequence) vl
	  GROUP BY vl.parcel_id
	 HAVING st_npoints(st_collect(vl.the_geom)) > 1) AS parcel
	 INNER JOIN
	(SELECT p.parcel_id,p.local_govt || p.prop_type || p.plot_sn AS parcel_number, p.allocation,p.block,p.official_area,
	s.scheme_name AS scheme,p.file_number,d.grantee AS owner,p.deeds_file 
	FROM parcel_lookup p LEFT JOIN deeds d ON p.file_number=d.fileno LEFT JOIN schemes s ON p.scheme = s.id) AS description
	USING (parcel_id);

GRANT SELECT ON TABLE public.parcels TO GROUP web_read;


--ALTER TABLE parcel_lookup ADD UNIQUE (parcel_id);
--instead make parcel_id the PK

ALTER TABLE parcel_def ADD CONSTRAINT parcel_def_parcel_id_fkey FOREIGN KEY (parcel_id)
      REFERENCES parcel_lookup (parcel_id) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;




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


ALTER TABLE parcel_lookup
   ALTER COLUMN local_govt SET NOT NULL;
ALTER TABLE parcel_lookup
   ALTER COLUMN prop_type SET NOT NULL;



--change parcel_id to integer field!

--fix 26331 transformation

create table temp_proj as select * from spatial_ref_sys where srid = 26331;
--select * from temp_proj;
--select proj4text from temp_proj;
update temp_proj set srid = 263310;
--delete from spatial_ref_sys where srid = 263310
insert into spatial_ref_sys (select * from temp_proj);

update spatial_ref_sys set 
proj4text = '+proj=utm +zone=31 +ellps=clrk80 +towgs84=-111.92, -87.85, 114.5, 1.875, 0.202, 0.219, 0.032 +units=m +no_defs',
srtext = 'PROJCS["Minna / UTM zone 31N", GEOGCS["Minna", DATUM["Minna", SPHEROID["Clarke 1880 (RGS)", 6378249.145, 293.465, AUTHORITY["EPSG","7012"]], TOWGS84[-111.92, -87.85, 114.5, 1.875, 0.202, 0.219, 0.032], AUTHORITY["EPSG","6263"]], PRIMEM["Greenwich", 0.0, AUTHORITY["EPSG","8901"]], UNIT["degree", 0.017453292519943295], AXIS["Geodetic longitude", EAST], AXIS["Geodetic latitude", NORTH], AUTHORITY["EPSG","4263"]], PROJECTION["Transverse_Mercator", AUTHORITY["EPSG","9807"]], PARAMETER["central_meridian", 3.0], PARAMETER["latitude_of_origin", 0.0], PARAMETER["scale_factor", 0.9996], PARAMETER["false_easting", 500000.0], PARAMETER["false_northing", 0.0], UNIT["m", 1.0], AXIS["Easting", EAST], AXIS["Northing", NORTH], AUTHORITY["EPSG","26331"]]'
WHERE srid = 26331;

drop table temp_proj;

--revert the above, back to original transformation:
update spatial_ref_sys set
proj4text = (select proj4text from spatial_ref_sys where srid = 263310),
srtext = (select proj4text from spatial_ref_sys where srid = 263310)
WHERE srid = 26331; 
DELETE from spatial_ref_sys where srid = 263310;

ALTER TABLE parcel_def
   ALTER COLUMN parcel_id SET NOT NULL;

--add area to parcels and scheme to survey

ALTER TABLE survey ADD COLUMN scheme integer;
ALTER TABLE beacons RENAME geom  TO the_geom;

 ALTER TABLE survey ADD FOREIGN KEY (scheme) REFERENCES schemes (id) ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE parcel_lookup ADD COLUMN official_area double precision;

ALTER TABLE survey ADD FOREIGN KEY (ref_beacon) REFERENCES beacons (beacon) ON UPDATE NO ACTION ON DELETE NO ACTION;

