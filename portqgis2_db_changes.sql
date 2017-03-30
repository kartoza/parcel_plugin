CREATE OR REPLACE FUNCTION beardistupdate(arg_plan_no character varying, arg_bearing double precision, arg_distance double precision, arg_beacon_from character varying, arg_beacon_to character varying, arg_location character varying, arg_name character varying, arg_index integer)
  RETURNS void AS
$BODY$
  DECLARE
    the_id_beardist integer;
    the_id_beacons  integer;
    the_x           double precision;
    the_y           double precision;
    the_geom_       geometry(Point, 26331);
  BEGIN
    SELECT i.id INTO the_id_beardist FROM (
      SELECT bd.id, row_number() over(ORDER BY bd.id) -1 as index 
      FROM beardist bd 
      INNER JOIN beacons b ON bd.beacon_to = b.beacon 
      WHERE bd.plan_no = arg_plan_no
    ) AS i
    WHERE i.index = arg_index;
    SELECT gid INTO the_id_beacons FROM beacons b INNER JOIN beardist bd ON b.beacon = bd.beacon_to WHERE bd.id = the_id_beardist;
    SELECT x INTO the_x FROM beacons WHERE beacon = arg_beacon_from;
    SELECT y INTO the_y FROM beacons WHERE beacon = arg_beacon_from;
    SELECT pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, 26331) INTO the_geom_;
    UPDATE beacons SET 
      beacon = arg_beacon_to, 
      y = st_y(the_geom_), 
      x = st_x(the_geom_), 
      "location" = arg_location, 
      "name" = arg_name
    WHERE gid = the_id_beacons;
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
ALTER FUNCTION beardistupdate(character varying, double precision, double precision, character varying, character varying, character varying, character varying, integer)
  OWNER TO robert;