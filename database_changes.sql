---- create tables
-- parcel_lookup
CREATE TABLE parcel_lookup
(
  id serial NOT NULL,
  parcel_id character varying(20) NOT NULL,
  available boolean NOT NULL DEFAULT true,
  CONSTRAINT parcel_lookup_pkey PRIMARY KEY (id ),
  CONSTRAINT parcel_lookup_parcel_id_key UNIQUE (parcel_id )
)
WITH (
  OIDS=FALSE
);
---- create functions

--
CREATE OR REPLACE FUNCTION parcel_lookup_availability_trigger()
  RETURNS trigger AS
$BODY$
  BEGIN
    UPDATE parcel_lookup SET available = TRUE;
    UPDATE parcel_lookup SET available = FALSE WHERE parcel_id IN (SELECT DISTINCT parcel_id FROM parcel_def);
    RETURN NEW;
  END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
--
CREATE OR REPLACE FUNCTION parcel_lookup_define_parcel_trigger()
  RETURNS trigger AS
$BODY$
  BEGIN
    IF (SELECT COUNT(*)::integer FROM parcel_lookup  WHERE parcel_id = NEW.parcel_id) = 0 THEN
      INSERT INTO parcel_lookup (parcel_id) VALUES (NEW.parcel_id);
    END IF;
    RETURN NEW;
  END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
---- create triggers
--
DROP TRIGGER IF EXISTS insert_nodes_geom ON beacons;
CREATE TRIGGER insert_nodes_geom
  BEFORE INSERT OR UPDATE
  ON beacons
  FOR EACH ROW
  EXECUTE PROCEDURE calc_point();
--
DROP TRIGGER IF EXISTS parcel_lookup_availability ON parcel_def;
CREATE TRIGGER parcel_lookup_availability
  AFTER INSERT OR UPDATE OR DELETE
  ON parcel_def
  FOR EACH ROW
  EXECUTE PROCEDURE parcel_lookup_availability_trigger();
-- 
DROP TRIGGER IF EXISTS parcel_lookup_define_parcel ON parcel_def;
CREATE TRIGGER parcel_lookup_define_parcel
  BEFORE INSERT OR UPDATE
  ON parcel_def
  FOR EACH ROW
  EXECUTE PROCEDURE parcel_lookup_define_parcel_trigger();
---- create database constraints
ALTER TABLE parcel_def ADD CONSTRAINT parcel_def_beacon_fkey FOREIGN KEY (beacon)
      REFERENCES beacons (beacon) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE parcel_def ADD CONSTRAINT parcel_def_parcel_id_fkey FOREIGN KEY (parcel_id)
      REFERENCES parcel_lookup (parcel_id) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;

--insert into parcel_lookup  (parcel_id,available) VALUES (8,'f'),(9,'f'),(1,'f');


---- bearing and distance stuff
--
ALTER TABLE survey ADD UNIQUE (plan_no);
ALTER TABLE beardist ADD FOREIGN KEY (beacon_from) REFERENCES beacons (beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE beardist ADD FOREIGN KEY (beacon_to) REFERENCES beacons (beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE beardist ADD FOREIGN KEY (plan_no) REFERENCES survey (plan_no) ON UPDATE CASCADE ON DELETE CASCADE;
--
CREATE OR REPLACE FUNCTION pointfrombearinganddistance(dstarte double precision, dstartn double precision, dbearing double precision, ddistance double precision, "precision" integer, srid integer)
  RETURNS geometry AS
$BODY$
  DECLARE
      dangle1    double precision;
      dangle1rad double precision;
      ddeltan    double precision;
      ddeltae    double precision;
      dende      double precision;
      dendn      double precision;
      "precision" int;
      srid int;
BEGIN
    precision := CASE WHEN precision IS NULL THEN 3 ELSE precision END;
    srid := CASE WHEN srid IS NULL THEN 4326 ELSE srid END;
  BEGIN
    IF 
      dstarte   IS NULL OR
      dstartn   IS NULL OR
      dbearing  IS NULL OR
      ddistance IS NULL 
    THEN RETURN NULL;
    END IF;
    -- First calculate ddeltae and ddeltan
    IF dbearing < 90 
    THEN 
      dangle1    := 90 - dbearing;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance;
      ddeltan    := Sin(dangle1rad) * ddistance;
    END if;
    IF dbearing < 180 
    THEN 
      dangle1    := dbearing - 90;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance;
      ddeltan    := Sin(dangle1rad) * ddistance * -1;
    END if;
    IF dbearing < 270 
    THEN 
      dangle1    := 270 - dbearing;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance * -1;
      ddeltan    := Sin(dangle1rad) * ddistance * -1;
    END if;
    IF dbearing <= 360 
    THEN 
      dangle1    := dbearing - 270;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance * -1;
      ddeltan    := Sin(dangle1rad) * ddistance;
    END IF;
    -- Calculate the easting and northing of the end point
    dende := ddeltae + dstarte;
    dendn := ddeltan + dstartn;
    RETURN ST_SetSRID(ST_MakePoint(round(dende::numeric, precision), round(dendn::numeric, precision)), 26331);
  END;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
--
CREATE OR REPLACE FUNCTION public.BearDistInsert(
  arg_plan_no     character varying(20),
  arg_bearing     double precision,
  arg_distance    double precision,
  arg_beacon_from character varying(20),
  arg_beacon_to   character varying(20),
  arg_location    character varying(50),
  arg_name        character varying(20)
)
  RETURNS void AS
$BODY$
  DECLARE
    the_x    double precision;
    the_y    double precision;
    the_geom geometry(Point,26331);
  BEGIN
    -- calculate geometry from bearing and distance
    SELECT x INTO the_x FROM beacons WHERE beacon = arg_beacon_from;
    SELECT y INTO the_y FROM beacons WHERE beacon = arg_beacon_from;
    the_geom := pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, 26331);
    -- insert record into beacons table
    INSERT INTO beacons(beacon, y, x, "location", "name")
    VALUES(arg_beacon_to, st_y(the_geom), st_x(the_geom), arg_location, arg_name);
    -- insert record into beardist table
    INSERT INTO beardist(plan_no, bearing, distance, beacon_from, beacon_to) 
    VALUES(arg_plan_no, arg_bearing, arg_distance, arg_beacon_from, arg_beacon_to);
  END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
--
CREATE OR REPLACE FUNCTION beardistupdate(arg_plan_no character varying, arg_bearing double precision, 
arg_distance double precision, arg_beacon_from character varying, arg_beacon_to character varying, 
arg_location character varying, arg_name character varying, arg_index integer)
  RETURNS void AS
$BODY$
  DECLARE
    the_id_beardist integer;
    the_id_beacons  integer;
    the_x           double precision;
    the_y           double precision;
    the_geom        geometry(Point, 26331);
  BEGIN
    -- get id of old record in beardist table
    SELECT i.id INTO the_id_beardist FROM (
      SELECT bd.id, row_number() over(ORDER BY bd.id) -1 as index 
      FROM beardist bd 
      INNER JOIN beacons b ON bd.beacon_to = b.beacon 
      WHERE bd.plan_no = arg_plan_no
    ) AS i
    WHERE i.index = arg_index;
    -- get id of old record in beacon table
    SELECT gid INTO the_id_beacons FROM beacons b INNER JOIN beardist bd ON b.beacon = bd.beacon_to WHERE bd.id = the_id_beardist;
    -- calculate geometry from bearing and distance
    SELECT x INTO the_x FROM beacons WHERE beacon = arg_beacon_from;
    SELECT y INTO the_y FROM beacons WHERE beacon = arg_beacon_from;
    SELECT pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, 26331) INTO the_geom;
    -- update beacons table record
    UPDATE beacons SET 
      beacon = arg_beacon_to, 
      y = st_y(the_geom), 
      x = st_x(the_geom), 
      "location" = arg_location, 
      "name" = arg_name
    WHERE gid = the_id_beacons;
    -- update beardist table record
    UPDATE beardist SET 
      plan_no = arg_plan_no,
      bearing = arg_bearing, 
      distance = arg_distance, 
      beacon_from = arg_beacon_from, 
      beacon_to = arg_beacon_to
    WHERE id = the_id_beardist; 
  END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

