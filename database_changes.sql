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
CREATE OR REPLACE FUNCTION calc_point()
  RETURNS trigger AS
$BODY$
  BEGIN
    NEW.geom:=ST_SetSRID(ST_MakePoint(new.x, new.y), 26331) ;
    RETURN NEW;
  END
$BODY$
  LANGUAGE plpgsql VOLATILE COST 100;
--
CREATE OR REPLACE FUNCTION parcel_lookup_availability_trigger()
  RETURNS trigger AS
$BODY$
  BEGIN
    UPDATE parcel_lookup SET available = TRUE;
    UPDATE parcel_lookup SET available = FALSE WHERE parcel_id IN (SELECT parcel_id FROM parcel_def GROUP BY parcel_id);
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



