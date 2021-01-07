-- Do not run the sql file as is. Replace :CRS with a custom crs before running
-- Create a database and run the following sql file
--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;
SET xmloption = document;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = public, pg_catalog;

--
-- Name: beardistinsert(character varying, double precision, double precision, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION beardistinsert(arg_plan_no character varying, arg_bearing double precision, arg_distance double precision, arg_beacon_from character varying, arg_beacon_to character varying, arg_location character varying, arg_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    the_x    double precision;
    the_y    double precision;
    the_geom geometry(Point,:CRS);
  BEGIN
    SELECT x INTO the_x FROM beacons WHERE beacon = arg_beacon_from;
    SELECT y INTO the_y FROM beacons WHERE beacon = arg_beacon_from;
    the_geom := pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, :CRS);
    INSERT INTO beacons(beacon, y, x, "location", "name")
    VALUES(arg_beacon_to, st_y(the_geom), st_x(the_geom), arg_location, arg_name);
    INSERT INTO beardist(plan_no, bearing, distance, beacon_from, beacon_to)
    VALUES(arg_plan_no, arg_bearing, arg_distance, arg_beacon_from, arg_beacon_to);
  END
$$;



--
-- Name: beardistupdate(character varying, double precision, double precision, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION beardistupdate(arg_plan_no character varying, arg_bearing double precision, arg_distance double precision, arg_beacon_from character varying, arg_beacon_to character varying, arg_location character varying, arg_name character varying, arg_index integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    the_id_beardist integer;
    the_id_beacons  integer;
    the_x           double precision;
    the_y           double precision;
    the_geom_       geometry(Point, :CRS);
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
    SELECT pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, :CRS) INTO the_geom_;
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
$$;



--
-- Name: calc_point(); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION calc_point() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    NEW.the_geom:=ST_SetSRID(ST_MakePoint(new.x, new.y), :CRS) ;
  RETURN NEW;
  END
  $$;



--
-- Name: fn_beacons_after_insert(); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION fn_beacons_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO hist_beacons (
    gid,
    beacon,
    y,
    x,
    the_geom,
    location,
    name,
    hist_user,
    hist_action,
    hist_time
  ) VALUES (
    NEW."gid",
    NEW."beacon",
    NEW."y",
    NEW."x",
    NEW."the_geom",
    NEW."location",
    NEW."name",
      NEW."last_modified_by",
    'INSERT',
    NOW()
    );
    RETURN NEW;
END;
$$;



--
-- Name: fn_beacons_before_delete(); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION fn_beacons_before_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO hist_beacons (
    gid,
    beacon,
    y,
    x,
    the_geom,
    location,
    name,
    hist_user,
    hist_action,
    hist_time
  ) VALUES (
    OLD."gid",
    OLD."beacon",
    OLD."y",
    OLD."x",
    OLD."the_geom",
    OLD."location",
    OLD."name",
      OLD."last_modified_by",
    'DELETE',
    NOW()
    );
    RETURN OLD;
END;
$$;



--
-- Name: fn_beacons_before_update(); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION fn_beacons_before_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO hist_beacons (
    gid,
    beacon,
    y,
    x,
    the_geom,
    location,
    name,
    hist_user,
    hist_action,
    hist_time
  ) VALUES (
    OLD."gid",
    OLD."beacon",
    OLD."y",
    OLD."x",
    OLD."the_geom",
    OLD."location",
    OLD."name",
      NEW."last_modified_by",
    'EDIT',
    NOW()
    );
    RETURN NEW;
END;
$$;



--
-- Name: fn_updateprintjobs(); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION fn_updateprintjobs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.created IS NOT NULL THEN
      NEW.created = NEW.created + interval '2 hours';
    END IF;
  IF NEW.done IS NOT NULL THEN
      NEW.done = NEW.done + interval '2 hours';
    END IF;
    RETURN NEW;
END;
$$;



--
-- Name: parcel_lookup_availability_trigger(); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION parcel_lookup_availability_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    UPDATE parcel_lookup SET available = TRUE;
    UPDATE parcel_lookup SET available = FALSE WHERE parcel_id IN (SELECT parcel_id FROM parcel_def GROUP BY parcel_id);
    RETURN NEW;
  END
$$;



--
-- Name: parcel_lookup_define_parcel_trigger(); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION parcel_lookup_define_parcel_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (SELECT COUNT(*)::integer FROM parcel_lookup  WHERE parcel_id = NEW.parcel_id) = 0 THEN
      INSERT INTO parcel_lookup (parcel_id) VALUES (NEW.parcel_id);
    END IF;
    RETURN NEW;
  END
$$;



--
-- Name: pointfrombearinganddistance(double precision, double precision, double precision, double precision, integer, integer); Type: FUNCTION; Schema: public; 
--

CREATE FUNCTION pointfrombearinganddistance(dstarte double precision, dstartn double precision, dbearing double precision, ddistance double precision, "precision" integer, srid integer) RETURNS geometry
    LANGUAGE plpgsql
    AS $$
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
    dende := ddeltae + dstarte;
    dendn := ddeltan + dstartn;
    RETURN ST_SetSRID(ST_MakePoint(round(dende::numeric, precision), round(dendn::numeric, precision)), :CRS);
  END;
END;
$$;



SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: allocation_cat; Type: TABLE; Schema: public; 
--

CREATE TABLE allocation_cat (
    description character varying(50) NOT NULL,
    allocation_cat integer NOT NULL
);



--
-- Name: allocation_cat_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE allocation_cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: allocation_cat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE allocation_cat_id_seq OWNED BY allocation_cat.allocation_cat;


--
-- Name: beacons; Type: TABLE; Schema: public; 
--

CREATE TABLE beacons (
    gid integer NOT NULL,
    beacon character varying(80) NOT NULL,
    y double precision NOT NULL,
    x double precision NOT NULL,
    the_geom geometry(Point,:CRS) NOT NULL,
    location character varying(180),
    name character varying(100),
    last_modified_by character varying
);



--
-- Name: beacons_gid_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE beacons_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: beacons_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE beacons_gid_seq OWNED BY beacons.gid;


--
-- Name: parcel_def; Type: TABLE; Schema: public; 
--

CREATE TABLE parcel_def (
    id integer NOT NULL,
    beacon character varying(20) NOT NULL,
    sequence integer NOT NULL,
    parcel_id integer
);



--
-- Name: parcel_lookup; Type: TABLE; Schema: public; 
--

CREATE TABLE parcel_lookup (
    plot_sn character varying,
    available boolean DEFAULT true NOT NULL,
    scheme integer,
    block character varying,
    local_govt integer,
    prop_type integer,
    file_number character varying,
    allocation integer,
    manual_no character varying,
    deeds_file character varying,
    parcel_id integer NOT NULL,
    official_area double precision,
    private boolean DEFAULT false,
    status integer
);



--
-- Name: COLUMN parcel_lookup.plot_sn; Type: COMMENT; Schema: public; 
--

COMMENT ON COLUMN parcel_lookup.plot_sn IS 'plot serial no within a block. Forms part of the parcel no';


--
-- Name: beacons_views; Type: MATERIALIZED VIEW; Schema: public; 
--

CREATE  VIEW beacons_views AS
 SELECT DISTINCT ON (b.gid) b.gid,
    b.beacon,
    b.y,
    b.x,
    b.the_geom,
    b.location,
    b.name,
    pl.private,
    pl.parcel_id
   FROM ((beacons b
     JOIN parcel_def pd USING (beacon))
     JOIN parcel_lookup pl USING (parcel_id))
  ;






--
-- Name: deeds; Type: TABLE; Schema: public; 
--

CREATE TABLE deeds (
    fileno character varying(40),
    planno character varying(40),
    instrument text,
    grantor text,
    grantee text,
    block character varying(80),
    plot character varying(80),
    location text,
    deed_sn integer NOT NULL
);



--
-- Name: schemes; Type: TABLE; Schema: public; 
--

CREATE TABLE schemes (
    id integer NOT NULL,
    scheme_name character varying(50) NOT NULL,
    "Scheme" smallint
);



--
-- Name: COLUMN schemes."Scheme"; Type: COMMENT; Schema: public; 
--

COMMENT ON COLUMN schemes."Scheme" IS 'line';


--
-- Name: parcels; Type: VIEW; Schema: public; 
--

CREATE VIEW parcels AS
 SELECT parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom))::numeric, 3))::double precision AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/'::text || (description.deeds_file)::text) || '" target="blank_">'::text) || (description.deeds_file)::text) || '</a>'::text) AS deeds_file,
    description.private
   FROM (( SELECT vl.parcel_id,
            (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(st_makeline(vl.the_geom)))))::geometry(Polygon,:CRS) AS the_geom
           FROM ( SELECT pd.id,
                    pd.parcel_id,
                    pd.beacon,
                    pd.sequence,
                    b.the_geom
                   FROM (beacons b
                     JOIN parcel_def pd ON (((b.beacon)::text = (pd.beacon)::text)))
                  ORDER BY pd.parcel_id, pd.sequence) vl
          GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
     JOIN ( SELECT p.parcel_id,
            ((p.local_govt || (p.prop_type)::text) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn AS serial_no,
            p.official_area,
            s.scheme_name AS scheme,
            p.file_number,
            d.grantee AS owner,
            p.deeds_file,
            p.private
           FROM ((parcel_lookup p
             LEFT JOIN deeds d ON (((p.file_number)::text = (d.fileno)::text)))
             LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block)::text <> ALL (ARRAY[('perimeter'::character varying)::text, ('acquisition'::character varying)::text, ('agriculture'::character varying)::text, ('education'::character varying)::text]))) description USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom);



--
-- Name: beacons_intersect; Type: MATERIALIZED VIEW; Schema: public; 
--

CREATE  VIEW beacons_intersect AS
 SELECT a.beacon,
    a.the_geom,
    a.x,
    a.y,
    b.parcel_id,
    a.private
   FROM (beacons_views a
     LEFT JOIN parcels b ON ((a.parcel_id = b.parcel_id)))
  ;



--
-- Name: beardist; Type: TABLE; Schema: public; 
--

CREATE TABLE beardist (
    id integer NOT NULL,
    plan_no character varying(20) NOT NULL,
    bearing double precision NOT NULL,
    distance double precision NOT NULL,
    beacon_from character varying(20) NOT NULL,
    beacon_to character varying(20) NOT NULL
);



--
-- Name: beardist_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE beardist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: beardist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE beardist_id_seq OWNED BY beardist.id;


--
-- Name: bearing_labels; Type: VIEW; Schema: public; 
--

CREATE VIEW bearing_labels AS
 SELECT b.id,
    b.geom,
    c.plan_no,
    c.bearing,
    c.distance
   FROM (( SELECT a.id,
            st_makeline(a.the_geom) AS geom
           FROM ( SELECT bd.id,
                    bd.beacon,
                    bd.orderby,
                    b_1.the_geom
                   FROM (( SELECT beardist.id,
                            beardist.beacon_from AS beacon,
                            1 AS orderby
                           FROM beardist
                        UNION
                         SELECT beardist.id,
                            beardist.beacon_to AS beacon,
                            2 AS orderby
                           FROM beardist) bd
                     JOIN beacons b_1 USING (beacon))
                  ORDER BY bd.orderby) a
          GROUP BY a.id) b
     JOIN beardist c USING (id));



--
-- Name: boundaries; Type: MATERIALIZED VIEW; Schema: public; 
--

CREATE  VIEW boundaries AS
 WITH boundaries AS (
         SELECT segments.parcel_id,
            st_makeline(segments.sp, segments.ep) AS geom
           FROM ( SELECT linestrings.parcel_id,
                    st_pointn(linestrings.geom, generate_series(1, (st_npoints(linestrings.geom) - 1))) AS sp,
                    st_pointn(linestrings.geom, generate_series(2, st_npoints(linestrings.geom))) AS ep
                   FROM ( SELECT parcels.parcel_id,
                            (st_dump(st_boundary(parcels.the_geom))).geom AS geom
                           FROM parcels) linestrings) segments
        )
 SELECT row_number() OVER () AS id,
    boundaries.parcel_id,
    (boundaries.geom)::geometry(LineString,:CRS) AS geom,
    round((st_length(boundaries.geom))::numeric, 2) AS distance,
    round((degrees(st_azimuth(st_startpoint(boundaries.geom), st_endpoint(boundaries.geom))))::numeric, 2) AS bearing
   FROM boundaries
  WHERE st_isvalid(boundaries.geom)
  ;



--
-- Name: boundary_labels; Type: MATERIALIZED VIEW; Schema: public; 
--

CREATE  VIEW boundary_labels AS
 SELECT row_number() OVER () AS id,
    b.id AS boundary_id,
    (b.geom)::geometry(LineString,:CRS) AS geom,
    c.plan_no,
    c.bearing,
    c.distance,
    p.parcel_id
   FROM ((( SELECT a.id,
            st_makeline(a.the_geom) AS geom
           FROM ( SELECT bd.id,
                    bd.beacon,
                    bd.orderby,
                    b_1.the_geom
                   FROM (( SELECT beardist.id,
                            beardist.beacon_from AS beacon,
                            1 AS orderby
                           FROM beardist
                        UNION
                         SELECT beardist.id,
                            beardist.beacon_to AS beacon,
                            2 AS orderby
                           FROM beardist) bd
                     JOIN beacons b_1 USING (beacon))
                  ORDER BY bd.orderby) a
          GROUP BY a.id) b
     JOIN beardist c USING (id))
     JOIN parcels p ON (st_coveredby(b.geom, p.the_geom)))
  ;



--
-- Name: deeds_deed_sn_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE deeds_deed_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: deeds_deed_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE deeds_deed_sn_seq OWNED BY deeds.deed_sn;


--
-- Name: derived_boundaries; Type: MATERIALIZED VIEW; Schema: public; 
--

CREATE  VIEW derived_boundaries AS
 SELECT b.id,
    b.parcel_id,
    b.geom,
    b.distance,
    b.bearing
   FROM boundaries b
  WHERE (NOT (b.id IN ( SELECT b_1.id
           FROM (boundaries b_1
             JOIN boundary_labels bl ON (st_equals(b_1.geom, bl.geom))))))
  ;



--
-- Name: hist_beacons; Type: TABLE; Schema: public; 
--

CREATE TABLE hist_beacons (
    hist_id bigint NOT NULL,
    gid integer DEFAULT nextval('beacons_gid_seq'::regclass) NOT NULL,
    beacon character varying(80) NOT NULL,
    y double precision NOT NULL,
    x double precision NOT NULL,
    the_geom geometry(Point,:CRS) NOT NULL,
    location character varying(180),
    name character varying(100),
    hist_user character varying,
    hist_action character varying,
    hist_time timestamp without time zone
);



--
-- Name: hist_beacons_hist_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE hist_beacons_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: hist_beacons_hist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE hist_beacons_hist_id_seq OWNED BY hist_beacons.hist_id;


--
-- Name: instrument_cat; Type: TABLE; Schema: public; 
--

CREATE TABLE instrument_cat (
    instrument_cat integer NOT NULL,
    description character varying NOT NULL
);



--
-- Name: instrument_cat_instrument_cat_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE instrument_cat_instrument_cat_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: instrument_cat_instrument_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE instrument_cat_instrument_cat_seq OWNED BY instrument_cat.instrument_cat;


--
-- Name: local_govt; Type: TABLE; Schema: public; 
--

CREATE TABLE local_govt (
    id integer NOT NULL,
    local_govt_name character varying(50) NOT NULL
);



--
-- Name: local_govt_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE local_govt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: local_govt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE local_govt_id_seq OWNED BY local_govt.id;


--
-- Name: localmotclass_code_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE localmotclass_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: localrdclass_code_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE localrdclass_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: parcel_def_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE parcel_def_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: parcel_def_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE parcel_def_id_seq OWNED BY parcel_def.id;


--
-- Name: parcel_lookup_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE parcel_lookup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: parcel_lookup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE parcel_lookup_id_seq OWNED BY parcel_lookup.plot_sn;


--
-- Name: parcel_lookup_parcel_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE parcel_lookup_parcel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: parcel_lookup_parcel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE parcel_lookup_parcel_id_seq OWNED BY parcel_lookup.parcel_id;


--
-- Name: perimeters; Type: VIEW; Schema: public; 
--

CREATE VIEW perimeters AS
 SELECT parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom))::numeric, 3))::double precision AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/'::text || (description.deeds_file)::text) || '" target="blank_">'::text) || (description.deeds_file)::text) || '</a>'::text) AS deeds_file,
    description.private
   FROM (( SELECT vl.parcel_id,
            (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(st_makeline(vl.the_geom)))))::geometry(Polygon,:CRS) AS the_geom
           FROM ( SELECT pd.id,
                    pd.parcel_id,
                    pd.beacon,
                    pd.sequence,
                    b.the_geom
                   FROM (beacons b
                     JOIN parcel_def pd ON (((b.beacon)::text = (pd.beacon)::text)))
                  ORDER BY pd.parcel_id, pd.sequence) vl
          GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
     JOIN ( SELECT p.parcel_id,
            ((p.local_govt || (p.prop_type)::text) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn AS serial_no,
            p.official_area,
            s.scheme_name AS scheme,
            p.file_number,
            d.grantee AS owner,
            p.deeds_file,
            p.private
           FROM ((parcel_lookup p
             LEFT JOIN deeds d ON (((p.file_number)::text = (d.fileno)::text)))
             LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block)::text = ANY (ARRAY[('perimeter'::character varying)::text, ('acquisition'::character varying)::text, ('agriculture'::character varying)::text, ('education'::character varying)::text]))) description USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom);



--
-- Name: parcel_overlap_matviews; Type: MATERIALIZED VIEW; Schema: public; 
--

CREATE  VIEW parcel_overlap_matviews AS
 SELECT DISTINCT ON (a.parcel_id) a.parcel_id,
    a.the_geom,
    a.comp_area,
    a.official_area,
    a.parcel_number,
    a.block,
    a.serial_no,
    a.scheme,
    a.file_number,
    a.allocation,
    a.owner,
    a.deeds_file,
    a.private
   FROM parcels a,
    perimeters b
  WHERE (st_overlaps(a.the_geom, b.the_geom) = true)
  ;



--
-- Name: parcels_intersect; Type: MATERIALIZED VIEW; Schema: public; 
--

CREATE  VIEW parcels_intersect AS
 SELECT DISTINCT ON (a.parcel_id) a.parcel_id,
    a.the_geom,
    a.comp_area,
    a.official_area,
    a.parcel_number,
    a.block,
    a.serial_no,
    a.scheme,
    a.file_number,
    a.allocation,
    a.owner,
    a.deeds_file,
    a.private
   FROM (parcels a
     LEFT JOIN parcels b ON (st_intersects(a.the_geom, b.the_geom)))
  WHERE ((a.parcel_id <> b.parcel_id) AND (b.parcel_id IS NOT NULL) AND (NOT st_touches(a.the_geom, b.the_geom)))
  ;



--
-- Name: parcels_lines; Type: VIEW; Schema: public; 
--

CREATE VIEW parcels_lines AS
 WITH toast AS (
         SELECT parcels.parcel_id,
            (st_dump(parcels.the_geom)).geom AS the_geom
           FROM parcels
          GROUP BY parcels.parcel_id, parcels.the_geom
        )
 SELECT a.parcel_id,
    st_collect(st_exteriorring(a.the_geom)) AS geom
   FROM toast a
  GROUP BY a.parcel_id;



--
-- Name: parcels_line_length; Type: VIEW; Schema: public; 
--

CREATE VIEW parcels_line_length AS
 WITH segments AS (
         SELECT dumps.parcel_id,
            row_number() OVER () AS id,
            st_makeline(lag((dumps.pt).geom, 1, NULL::geometry) OVER (PARTITION BY dumps.parcel_id ORDER BY dumps.parcel_id, (dumps.pt).path), (dumps.pt).geom) AS geom
           FROM ( SELECT parcels_lines.parcel_id,
                    st_dumppoints(parcels_lines.geom) AS pt
                   FROM parcels_lines) dumps
        )
 SELECT segments.parcel_id,
    segments.id,
    segments.geom,
    st_length(segments.geom) AS st_length
   FROM segments
  WHERE (segments.geom IS NOT NULL);



--
-- Name: perimeters_original; Type: VIEW; Schema: public; 
--

CREATE VIEW perimeters_original AS
 SELECT parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom))::numeric, 3))::double precision AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/'::text || (description.deeds_file)::text) || '" target="blank_">'::text) || (description.deeds_file)::text) || '</a>'::text) AS deeds_file
   FROM (( SELECT vl.parcel_id,
            (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(st_makeline(vl.the_geom)))))::geometry(Polygon,:CRS) AS the_geom
           FROM ( SELECT pd.id,
                    pd.parcel_id,
                    pd.beacon,
                    pd.sequence,
                    b.the_geom
                   FROM (beacons b
                     JOIN parcel_def pd ON (((b.beacon)::text = (pd.beacon)::text)))
                  ORDER BY pd.parcel_id, pd.sequence) vl
          GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
     JOIN ( SELECT p.parcel_id,
            ((p.local_govt || (p.prop_type)::text) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn AS serial_no,
            p.official_area,
            s.scheme_name AS scheme,
            p.file_number,
            d.grantee AS owner,
            p.deeds_file
           FROM ((parcel_lookup p
             LEFT JOIN deeds d ON (((p.file_number)::text = (d.fileno)::text)))
             LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block)::text = ANY (ARRAY[('perimeter'::character varying)::text, ('acquisition'::character varying)::text, ('agriculture'::character varying)::text, ('education'::character varying)::text]))) description USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom)
 LIMIT 1;



--
-- Name: print_survey_details; Type: TABLE; Schema: public; 
--

CREATE TABLE print_survey_details (
    id integer NOT NULL,
    plan_no character varying,
    survey_owner character varying,
    area_name character varying,
    sheet_no character varying,
    survey_type character varying,
    survey_authorisation character varying,
    property_id integer
);



--
-- Name: print_survey_details_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE print_survey_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: print_survey_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE print_survey_details_id_seq OWNED BY print_survey_details.id;


--
-- Name: prop_types; Type: TABLE; Schema: public; 
--

CREATE TABLE prop_types (
    id integer NOT NULL,
    code character varying(2) NOT NULL,
    prop_type_name character varying(50) NOT NULL
);



--
-- Name: prop_types_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE prop_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: prop_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE prop_types_id_seq OWNED BY prop_types.id;


--
-- Name: reference_view; Type: TABLE; Schema: public; 
--

CREATE TABLE reference_view (
    id integer,
    plan_no character varying(20),
    ref_beacon character varying(20),
    scheme integer,
    parcel_id integer,
    the_geom geometry(Point,:CRS),
    x double precision,
    y double precision
);



--
-- Name: schemes_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE schemes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: schemes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE schemes_id_seq OWNED BY schemes.id;


--
-- Name: speed_code_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE speed_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: status_cat; Type: TABLE; Schema: public; 
--

CREATE TABLE status_cat (
    status_cat integer NOT NULL,
    description character varying NOT NULL
);



--
-- Name: status_cat_status_cat_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE status_cat_status_cat_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: status_cat_status_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE status_cat_status_cat_seq OWNED BY status_cat.status_cat;


--
-- Name: str_type_strid_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE str_type_strid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: survey; Type: TABLE; Schema: public; 
--

CREATE TABLE survey (
    id integer NOT NULL,
    plan_no character varying(20) NOT NULL,
    ref_beacon character varying(20) NOT NULL,
    scheme integer,
    description character varying(255)
);



--
-- Name: survey_id_seq; Type: SEQUENCE; Schema: public; 
--

CREATE SEQUENCE survey_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: survey_id_seq; Type: SEQUENCE OWNED BY; Schema: public; 
--

ALTER SEQUENCE survey_id_seq OWNED BY survey.id;


--
-- Name: transactions; Type: TABLE; Schema: public; 
--

CREATE TABLE transactions (
    id character varying(10) NOT NULL,
    parcel_id integer NOT NULL,
    capture_officer integer NOT NULL,
    approval_officer integer,
    date timestamp without time zone DEFAULT now() NOT NULL,
    instrument integer NOT NULL,
    survey integer NOT NULL
);

CREATE TABLE public.layer_styles (
    id integer NOT NULL,
    f_table_catalog character varying,
    f_table_schema character varying,
    f_table_name character varying,
    f_geometry_column character varying,
    stylename text,
    styleqml xml,
    stylesld xml,
    useasdefault boolean,
    description text,
    owner character varying(63),
    ui xml,
    update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

--
-- Name: layer_styles_id_seq; Type: SEQUENCE; Schema: public;
--

CREATE SEQUENCE public.layer_styles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: layer_styles_id_seq; Type: SEQUENCE OWNED BY; Schema: public;
--

ALTER SEQUENCE public.layer_styles_id_seq OWNED BY public.layer_styles.id;


--
-- Name: layer_styles id; Type: DEFAULT; Schema: public;
--

ALTER TABLE ONLY public.layer_styles ALTER COLUMN id SET DEFAULT nextval('public.layer_styles_id_seq'::regclass);



INSERT INTO public.layer_styles VALUES (1, ':DATABASE', 'public', 'beacons', 'the_geom', 'beacons', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.8.0-Zanzibar" labelsEnabled="1" simplifyAlgorithm="0" maxScale="0" simplifyDrawingTol="1" simplifyLocal="1" hasScaleBasedVisibilityFlag="1" simplifyDrawingHints="0" readOnly="0" styleCategories="AllStyleCategories" minScale="10000" simplifyMaxScale="1">
 <flags>
  <Identifiable>1</Identifiable>
  <Removable>1</Removable>
  <Searchable>1</Searchable>
 </flags>
 <renderer-v2 type="singleSymbol" forceraster="0" enableorderby="0" symbollevels="0">
  <symbols>
   <symbol type="marker" alpha="1" name="0" clip_to_extent="1" force_rhr="0">
    <layer enabled="1" class="SvgMarker" locked="0" pass="0">
     <prop k="angle" v="0"/>
     <prop k="color" v="0,0,0,255"/>
     <prop k="fixedAspectRatio" v="0"/>
     <prop k="horizontal_anchor_point" v="1"/>
     <prop k="name" v="gpsicons/point.svg"/>
     <prop k="offset" v="0,0"/>
     <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="offset_unit" v="MM"/>
     <prop k="outline_color" v="0,0,0,255"/>
     <prop k="outline_width" v="1"/>
     <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="outline_width_unit" v="MM"/>
     <prop k="scale_method" v="diameter"/>
     <prop k="size" v="3"/>
     <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="size_unit" v="MM"/>
     <prop k="vertical_anchor_point" v="1"/>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" name="name" value=""/>
       <Option name="properties"/>
       <Option type="QString" name="type" value="collection"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </symbols>
  <rotation/>
  <sizescale/>
 </renderer-v2>
 <labeling type="simple">
  <settings>
   <text-style textOpacity="1" fontLetterSpacing="0" fontSizeUnit="Point" blendMode="0" namedStyle="Regular" fontUnderline="0" multilineHeight="1" fontSizeMapUnitScale="3x:0,0,0,0,0,0" textColor="85,0,0,255" fieldName="beacon" useSubstitutions="0" fontWordSpacing="0" fontStrikeout="0" fontCapitals="0" fontFamily="Ubuntu" previewBkgrdColor="#ffffff" isExpression="0" fontSize="7" fontWeight="50" fontItalic="0">
    <text-buffer bufferColor="255,255,255,255" bufferOpacity="1" bufferNoFill="0" bufferDraw="0" bufferSize="1" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferJoinStyle="64" bufferSizeUnits="MM" bufferBlendMode="0"/>
    <background shapeOffsetY="0" shapeSizeType="0" shapeOffsetUnit="Point" shapeBorderWidthUnit="Point" shapeJoinStyle="64" shapeOffsetX="0" shapeRadiiX="0" shapeRadiiY="0" shapeSizeUnit="Point" shapeRotation="0" shapeSizeX="0" shapeRadiiUnit="Point" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidth="0" shapeOpacity="1" shapeSizeY="0" shapeRotationType="0" shapeFillColor="255,255,255,255" shapeDraw="0" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeBlendMode="0" shapeBorderColor="128,128,128,255" shapeType="0" shapeSVGFile="" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0"/>
    <shadow shadowDraw="0" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowBlendMode="6" shadowRadius="1.5" shadowRadiusUnit="Point" shadowOffsetUnit="Point" shadowOpacity="1" shadowColor="0,0,0,255" shadowRadiusAlphaOnly="0" shadowOffsetDist="1" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowUnder="0" shadowOffsetAngle="135" shadowScale="100" shadowOffsetGlobal="1"/>
    <substitutions/>
   </text-style>
   <text-format reverseDirectionSymbol="0" decimals="0" placeDirectionSymbol="0" formatNumbers="0" rightDirectionSymbol=">" addDirectionSymbol="0" leftDirectionSymbol="&lt;" useMaxLineLengthForAutoWrap="1" autoWrapLength="0" multilineAlign="0" plussign="1" wrapChar=""/>
   <placement offsetUnits="MapUnit" geometryGenerator="" distUnits="MM" fitInPolygonOnly="0" centroidWhole="0" xOffset="1" maxCurvedCharAngleOut="-20" maxCurvedCharAngleIn="20" placement="0" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" offsetType="0" geometryGeneratorType="PointGeometry" dist="0" repeatDistance="0" repeatDistanceUnits="MM" distMapUnitScale="3x:0,0,0,0,0,0" placementFlags="0" centroidInside="0" quadOffset="2" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" rotationAngle="0" geometryGeneratorEnabled="0" preserveRotation="1" yOffset="0" priority="5" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0"/>
   <rendering obstacleFactor="1" obstacle="1" labelPerPart="0" fontLimitPixelSize="0" scaleVisibility="1" obstacleType="0" mergeLines="0" scaleMin="1" minFeatureSize="0" zIndex="0" limitNumLabels="0" scaleMax="10000" fontMaxPixelSize="200" fontMinPixelSize="3" maxNumLabels="2000" displayAll="0" upsidedownLabels="0" drawLabels="1"/>
   <dd_properties>
    <Option type="Map">
     <Option type="QString" name="name" value=""/>
     <Option name="properties"/>
     <Option type="QString" name="type" value="collection"/>
    </Option>
   </dd_properties>
  </settings>
 </labeling>
 <customproperties>
  <property key="embeddedWidgets/count" value="0"/>
  <property key="variableNames"/>
  <property key="variableValues"/>
 </customproperties>
 <blendMode>0</blendMode>
 <featureBlendMode>0</featureBlendMode>
 <layerOpacity>1</layerOpacity>
 <SingleCategoryDiagramRenderer attributeLegend="1" diagramType="Histogram">
  <DiagramCategory sizeType="MM" barWidth="5" penAlpha="255" scaleBasedVisibility="0" scaleDependency="Area" minScaleDenominator="0" labelPlacementMethod="XHeight" height="15" backgroundColor="#ffffff" minimumSize="0" width="15" lineSizeType="MM" rotationOffset="270" penWidth="0" opacity="1" diagramOrientation="Up" penColor="#000000" maxScaleDenominator="1e+08" lineSizeScale="3x:0,0,0,0,0,0" backgroundAlpha="255" enabled="0" sizeScale="3x:0,0,0,0,0,0">
   <fontProperties description="Ubuntu,11,-1,5,50,0,0,0,0,0" style=""/>
  </DiagramCategory>
 </SingleCategoryDiagramRenderer>
 <DiagramLayerSettings priority="0" linePlacementFlags="18" zIndex="0" dist="0" showAll="1" placement="0" obstacle="0">
  <properties>
   <Option type="Map">
    <Option type="QString" name="name" value=""/>
    <Option name="properties"/>
    <Option type="QString" name="type" value="collection"/>
   </Option>
  </properties>
 </DiagramLayerSettings>
 <geometryOptions geometryPrecision="0" removeDuplicateNodes="0">
  <activeChecks/>
  <checkConfiguration/>
 </geometryOptions>
 <fieldConfiguration>
  <field name="gid">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="beacon">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="y">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="x">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="location">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="name">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="last_modified_by">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
 </fieldConfiguration>
 <aliases>
  <alias field="gid" name="" index="0"/>
  <alias field="beacon" name="" index="1"/>
  <alias field="y" name="" index="2"/>
  <alias field="x" name="" index="3"/>
  <alias field="location" name="" index="4"/>
  <alias field="name" name="" index="5"/>
  <alias field="last_modified_by" name="" index="6"/>
 </aliases>
 <excludeAttributesWMS/>
 <excludeAttributesWFS/>
 <defaults>
  <default field="gid" expression="" applyOnUpdate="0"/>
  <default field="beacon" expression="" applyOnUpdate="0"/>
  <default field="y" expression="" applyOnUpdate="0"/>
  <default field="x" expression="" applyOnUpdate="0"/>
  <default field="location" expression="" applyOnUpdate="0"/>
  <default field="name" expression="" applyOnUpdate="0"/>
  <default field="last_modified_by" expression="" applyOnUpdate="0"/>
 </defaults>
 <constraints>
  <constraint field="gid" constraints="3" unique_strength="1" notnull_strength="1" exp_strength="0"/>
  <constraint field="beacon" constraints="3" unique_strength="1" notnull_strength="1" exp_strength="0"/>
  <constraint field="y" constraints="1" unique_strength="0" notnull_strength="1" exp_strength="0"/>
  <constraint field="x" constraints="1" unique_strength="0" notnull_strength="1" exp_strength="0"/>
  <constraint field="location" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="name" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="last_modified_by" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
 </constraints>
 <constraintExpressions>
  <constraint field="gid" desc="" exp=""/>
  <constraint field="beacon" desc="" exp=""/>
  <constraint field="y" desc="" exp=""/>
  <constraint field="x" desc="" exp=""/>
  <constraint field="location" desc="" exp=""/>
  <constraint field="name" desc="" exp=""/>
  <constraint field="last_modified_by" desc="" exp=""/>
 </constraintExpressions>
 <expressionfields/>
 <attributeactions>
  <defaultAction key="Canvas" value="{{00000000-0000-0000-0000-000000000000}}"/>
 </attributeactions>
 <attributetableconfig sortOrder="0" sortExpression="" actionWidgetStyle="dropDown">
  <columns>
   <column type="field" hidden="0" width="-1" name="gid"/>
   <column type="field" hidden="0" width="-1" name="beacon"/>
   <column type="field" hidden="0" width="-1" name="y"/>
   <column type="field" hidden="0" width="-1" name="x"/>
   <column type="field" hidden="0" width="-1" name="location"/>
   <column type="field" hidden="0" width="-1" name="name"/>
   <column type="field" hidden="0" width="-1" name="last_modified_by"/>
   <column type="actions" hidden="1" width="-1"/>
  </columns>
 </attributetableconfig>
 <conditionalstyles>
  <rowstyles/>
  <fieldstyles/>
 </conditionalstyles>
 <editform tolerant="1">.</editform>
 <editforminit/>
 <editforminitcodesource>0</editforminitcodesource>
 <editforminitfilepath></editforminitfilepath>
 <editforminitcode><![CDATA[# -*- coding: utf-8 -*-
"""
QGIS forms can have a Python function that is called when the form is
opened.

Use this function to add extra logic to your forms.

Enter the name of the function in the "Python Init function"
field.
An example follows:
"""
from qgis.PyQt.QtWidgets import QWidget

def my_form_open(dialog, layer, feature):
  geom = feature.geometry()
  control = dialog.findChild(QWidget, "MyLineEdit")
]]></editforminitcode>
 <featformsuppress>0</featformsuppress>
 <editorlayout>generatedlayout</editorlayout>
 <editable>
  <field name="beacon" editable="1"/>
  <field name="gid" editable="1"/>
  <field name="last_modified_by" editable="1"/>
  <field name="location" editable="1"/>
  <field name="name" editable="1"/>
  <field name="x" editable="1"/>
  <field name="y" editable="1"/>
 </editable>
 <labelOnTop>
  <field labelOnTop="0" name="beacon"/>
  <field labelOnTop="0" name="gid"/>
  <field labelOnTop="0" name="last_modified_by"/>
  <field labelOnTop="0" name="location"/>
  <field labelOnTop="0" name="name"/>
  <field labelOnTop="0" name="x"/>
  <field labelOnTop="0" name="y"/>
 </labelOnTop>
 <widgets/>
 <previewExpression>name</previewExpression>
 <mapTip></mapTip>
 <layerGeometryType>0</layerGeometryType>
</qgis>
', '<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" version="1.1.0" xmlns:se="http://www.opengis.net/se" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ogc="http://www.opengis.net/ogc">
 <NamedLayer>
  <se:Name>Beacons</se:Name>
  <UserStyle>
   <se:Name>Beacons</se:Name>
   <se:FeatureTypeStyle>
    <se:Rule>
     <se:Name>Single symbol</se:Name>
     <se:MinScaleDenominator>0</se:MinScaleDenominator>
     <se:MaxScaleDenominator>10000</se:MaxScaleDenominator>
     <se:PointSymbolizer>
      <se:Graphic>
       <!--Parametric SVG-->
       <se:ExternalGraphic>
        <se:OnlineResource xlink:type="simple" xlink:href="/usr/share/qgis/svg/gpsicons/point.svg?fill=%23000000&amp;fill-opacity=1&amp;outline=%23000000&amp;outline-opacity=1&amp;outline-width=4"/>
        <se:Format>image/svg+xml</se:Format>
       </se:ExternalGraphic>
       <!--Plain SVG fallback, no parameters-->
       <se:ExternalGraphic>
        <se:OnlineResource xlink:type="simple" xlink:href="gpsicons/point.svg"/>
        <se:Format>image/svg+xml</se:Format>
       </se:ExternalGraphic>
       <!--Well known marker fallback-->
       <se:Mark>
        <se:WellKnownName>square</se:WellKnownName>
        <se:Fill>
         <se:SvgParameter name="fill">#000000</se:SvgParameter>
        </se:Fill>
        <se:Stroke>
         <se:SvgParameter name="stroke">#000000</se:SvgParameter>
         <se:SvgParameter name="stroke-width">4</se:SvgParameter>
        </se:Stroke>
       </se:Mark>
       <se:Size>11</se:Size>
      </se:Graphic>
     </se:PointSymbolizer>
    </se:Rule>
    <se:Rule>
     <se:MinScaleDenominator>1</se:MinScaleDenominator>
     <se:MaxScaleDenominator>10000</se:MaxScaleDenominator>
     <se:TextSymbolizer>
      <se:Label>
       <ogc:PropertyName>beacon</ogc:PropertyName>
      </se:Label>
      <se:Font>
       <se:SvgParameter name="font-family">Ubuntu</se:SvgParameter>
       <se:SvgParameter name="font-size">9</se:SvgParameter>
      </se:Font>
      <se:LabelPlacement>
       <se:PointPlacement>
        <se:AnchorPoint>
         <se:AnchorPointX>0</se:AnchorPointX>
         <se:AnchorPointY>0.5</se:AnchorPointY>
        </se:AnchorPoint>
       </se:PointPlacement>
      </se:LabelPlacement>
      <se:Fill>
       <se:SvgParameter name="fill">#550000</se:SvgParameter>
      </se:Fill>
      <se:VendorOption name="maxDisplacement">1</se:VendorOption>
     </se:TextSymbolizer>
    </se:Rule>
   </se:FeatureTypeStyle>
  </UserStyle>
 </NamedLayer>
</StyledLayerDescriptor>
', true, 'Mon Jul 8 11:24:51 2019', ':DBOWNER', NULL, '2019-07-08 09:24:51.081314');
INSERT INTO public.layer_styles VALUES (2, ':DATABASE', 'public', 'parcels', 'the_geom', 'parcels', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.8.0-Zanzibar" labelsEnabled="1" simplifyAlgorithm="0" maxScale="-4.65661e-10" simplifyDrawingTol="1" simplifyLocal="1" hasScaleBasedVisibilityFlag="0" simplifyDrawingHints="1" readOnly="0" styleCategories="AllStyleCategories" minScale="1e+08" simplifyMaxScale="1">
 <flags>
  <Identifiable>1</Identifiable>
  <Removable>1</Removable>
  <Searchable>1</Searchable>
 </flags>
 <renderer-v2 type="RuleRenderer" forceraster="0" enableorderby="0" symbollevels="0">
  <rules key="{{ef477c4b-828a-4aa4-b5b5-e35bd14cdbba}}">
   <rule label="parcels" key="{{2acd78d1-46b5-4c4e-bb2f-366f29335ebb}}" scalemindenom="1" scalemaxdenom="20000" description="Parcel boundaries" symbol="0" filter=" &quot;block&quot; &lt;> ''perimeter'' or &quot;block&quot; is null"/>
   <rule label="parcels" key="{{6ae6949f-9f98-4328-a90c-86d1b98f1d42}}" scalemindenom="20000" symbol="1" filter=" &quot;block&quot; &lt;> ''perimeter'' or &quot;block&quot; is null"/>
   <rule label="acquisitions" key="{{8bca7cec-fb7b-4dd0-9eba-523b253233a9}}" scalemindenom="20000" symbol="2" filter=" &quot;block&quot; &lt;> ''acquisitionr'' or &quot;block&quot; is null"/>
   <rule label="perimeter" key="{{acd42f56-dd9e-4675-bf2a-568e389a9c43}}" description="Scheme perimeters" symbol="3" filter=" &quot;block&quot; = ''perimeter''"/>
  </rules>
  <symbols>
   <symbol type="fill" alpha="0.498039" name="0" clip_to_extent="1" force_rhr="0">
    <layer enabled="1" class="SimpleFill" locked="0" pass="2">
     <prop k="border_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="color" v="255,0,0,255"/>
     <prop k="joinstyle" v="bevel"/>
     <prop k="offset" v="0,0"/>
     <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="offset_unit" v="MM"/>
     <prop k="outline_color" v="0,0,0,255"/>
     <prop k="outline_style" v="solid"/>
     <prop k="outline_width" v="0.3"/>
     <prop k="outline_width_unit" v="MM"/>
     <prop k="style" v="diagonal_x"/>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" name="name" value=""/>
       <Option name="properties"/>
       <Option type="QString" name="type" value="collection"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol type="fill" alpha="1" name="1" clip_to_extent="1" force_rhr="0">
    <layer enabled="1" class="CentroidFill" locked="0" pass="3">
     <prop k="point_on_all_parts" v="1"/>
     <prop k="point_on_surface" v="0"/>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" name="name" value=""/>
       <Option name="properties"/>
       <Option type="QString" name="type" value="collection"/>
      </Option>
     </data_defined_properties>
     <symbol type="marker" alpha="1" name="@1@0" clip_to_extent="1" force_rhr="0">
      <layer enabled="1" class="SimpleMarker" locked="0" pass="0">
       <prop k="angle" v="0"/>
       <prop k="color" v="170,85,0,255"/>
       <prop k="horizontal_anchor_point" v="1"/>
       <prop k="joinstyle" v="bevel"/>
       <prop k="name" v="square"/>
       <prop k="offset" v="0,0"/>
       <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
       <prop k="offset_unit" v="MM"/>
       <prop k="outline_color" v="170,85,0,255"/>
       <prop k="outline_style" v="solid"/>
       <prop k="outline_width" v="0"/>
       <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
       <prop k="outline_width_unit" v="MM"/>
       <prop k="scale_method" v="area"/>
       <prop k="size" v="0.1"/>
       <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
       <prop k="size_unit" v="MM"/>
       <prop k="vertical_anchor_point" v="1"/>
       <data_defined_properties>
        <Option type="Map">
         <Option type="QString" name="name" value=""/>
         <Option name="properties"/>
         <Option type="QString" name="type" value="collection"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol type="fill" alpha="1" name="2" clip_to_extent="1" force_rhr="0">
    <layer enabled="1" class="SimpleFill" locked="0" pass="0">
     <prop k="border_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="color" v="86,35,135,255"/>
     <prop k="joinstyle" v="bevel"/>
     <prop k="offset" v="0,0"/>
     <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="offset_unit" v="MM"/>
     <prop k="outline_color" v="170,0,127,255"/>
     <prop k="outline_style" v="dot"/>
     <prop k="outline_width" v="0.26"/>
     <prop k="outline_width_unit" v="MM"/>
     <prop k="style" v="no"/>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" name="name" value=""/>
       <Option name="properties"/>
       <Option type="QString" name="type" value="collection"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol type="fill" alpha="1" name="3" clip_to_extent="1" force_rhr="0">
    <layer enabled="1" class="SimpleFill" locked="0" pass="1">
     <prop k="border_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="color" v="170,0,0,255"/>
     <prop k="joinstyle" v="bevel"/>
     <prop k="offset" v="0,0"/>
     <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
     <prop k="offset_unit" v="MM"/>
     <prop k="outline_color" v="170,0,0,255"/>
     <prop k="outline_style" v="dash"/>
     <prop k="outline_width" v="0.26"/>
     <prop k="outline_width_unit" v="MM"/>
     <prop k="style" v="no"/>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" name="name" value=""/>
       <Option name="properties"/>
       <Option type="QString" name="type" value="collection"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </symbols>
 </renderer-v2>
 <labeling type="simple">
  <settings>
   <text-style textOpacity="1" fontLetterSpacing="0" fontSizeUnit="Point" blendMode="0" namedStyle="Regular" fontUnderline="0" multilineHeight="1" fontSizeMapUnitScale="3x:0,0,0,0,0,0" textColor="0,0,0,255" fieldName="case when &quot;block&quot; &lt;> ''perimeter'' or &quot;block&quot; is null then (&quot;parcel_number&quot; || ''\n'' || ''block ''||&#xa;case when &quot;block&quot; is not null then &quot;block&quot; else ''?'' end ||'', plot ''||&#xa;case when&quot;serial_no&quot; is not null then&quot;serial_no&quot; else ''?'' end ||''\n''|| &#xa;case when &quot;official_area&quot; is not null then &quot;official_area&quot; else ''?'' end||''m² (o)''||''\n''||&#xa;&quot;comp_area&quot;||''m² (c)'')  else &quot;scheme&quot; end" useSubstitutions="0" fontWordSpacing="0" fontStrikeout="0" fontCapitals="0" fontFamily="Ubuntu" previewBkgrdColor="#ffffff" isExpression="1" fontSize="8" fontWeight="50" fontItalic="0">
    <text-buffer bufferColor="255,255,255,255" bufferOpacity="1" bufferNoFill="0" bufferDraw="1" bufferSize="0.1" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferJoinStyle="64" bufferSizeUnits="MapUnit" bufferBlendMode="0"/>
    <background shapeOffsetY="0" shapeSizeType="0" shapeOffsetUnit="Point" shapeBorderWidthUnit="Point" shapeJoinStyle="64" shapeOffsetX="0" shapeRadiiX="0" shapeRadiiY="0" shapeSizeUnit="Point" shapeRotation="0" shapeSizeX="0" shapeRadiiUnit="Point" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidth="0" shapeOpacity="1" shapeSizeY="0" shapeRotationType="0" shapeFillColor="255,255,255,255" shapeDraw="0" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeBlendMode="0" shapeBorderColor="128,128,128,255" shapeType="0" shapeSVGFile="" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0"/>
    <shadow shadowDraw="0" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowBlendMode="6" shadowRadius="1.5" shadowRadiusUnit="Point" shadowOffsetUnit="Point" shadowOpacity="1" shadowColor="0,0,0,255" shadowRadiusAlphaOnly="0" shadowOffsetDist="1" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowUnder="0" shadowOffsetAngle="135" shadowScale="100" shadowOffsetGlobal="1"/>
    <substitutions/>
   </text-style>
   <text-format reverseDirectionSymbol="0" decimals="0" placeDirectionSymbol="0" formatNumbers="0" rightDirectionSymbol=">" addDirectionSymbol="0" leftDirectionSymbol="&lt;" useMaxLineLengthForAutoWrap="1" autoWrapLength="0" multilineAlign="0" plussign="1" wrapChar=""/>
   <placement offsetUnits="MapUnit" geometryGenerator="" distUnits="MM" fitInPolygonOnly="0" centroidWhole="0" xOffset="0" maxCurvedCharAngleOut="-20" maxCurvedCharAngleIn="20" placement="5" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" offsetType="0" geometryGeneratorType="PointGeometry" dist="0" repeatDistance="0" repeatDistanceUnits="MM" distMapUnitScale="3x:0,0,0,0,0,0" placementFlags="0" centroidInside="0" quadOffset="4" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" rotationAngle="0" geometryGeneratorEnabled="0" preserveRotation="1" yOffset="0" priority="10" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0"/>
   <rendering obstacleFactor="1" obstacle="1" labelPerPart="0" fontLimitPixelSize="0" scaleVisibility="1" obstacleType="0" mergeLines="0" scaleMin="1" minFeatureSize="0" zIndex="0" limitNumLabels="0" scaleMax="1500" fontMaxPixelSize="10000" fontMinPixelSize="3" maxNumLabels="2000" displayAll="0" upsidedownLabels="0" drawLabels="1"/>
   <dd_properties>
    <Option type="Map">
     <Option type="QString" name="name" value=""/>
     <Option name="properties"/>
     <Option type="QString" name="type" value="collection"/>
    </Option>
   </dd_properties>
  </settings>
 </labeling>
 <customproperties>
  <property key="dualview/previewExpressions">
   <value>parcel_id</value>
  </property>
  <property key="embeddedWidgets/count" value="0"/>
  <property key="variableNames"/>
  <property key="variableValues"/>
 </customproperties>
 <blendMode>0</blendMode>
 <featureBlendMode>0</featureBlendMode>
 <layerOpacity>1</layerOpacity>
 <SingleCategoryDiagramRenderer attributeLegend="1" diagramType="Histogram">
  <DiagramCategory sizeType="MM" barWidth="5" penAlpha="255" scaleBasedVisibility="0" scaleDependency="Area" minScaleDenominator="-4.65661e-10" labelPlacementMethod="XHeight" height="15" backgroundColor="#ffffff" minimumSize="0" width="15" lineSizeType="MM" rotationOffset="270" penWidth="0" opacity="1" diagramOrientation="Up" penColor="#000000" maxScaleDenominator="1e+08" lineSizeScale="3x:0,0,0,0,0,0" backgroundAlpha="255" enabled="0" sizeScale="3x:0,0,0,0,0,0">
   <fontProperties description="Ubuntu,11,-1,5,50,0,0,0,0,0" style=""/>
  </DiagramCategory>
 </SingleCategoryDiagramRenderer>
 <DiagramLayerSettings priority="0" linePlacementFlags="18" zIndex="0" dist="0" showAll="1" placement="1" obstacle="0">
  <properties>
   <Option type="Map">
    <Option type="QString" name="name" value=""/>
    <Option name="properties"/>
    <Option type="QString" name="type" value="collection"/>
   </Option>
  </properties>
 </DiagramLayerSettings>
 <geometryOptions geometryPrecision="0" removeDuplicateNodes="0">
  <activeChecks/>
  <checkConfiguration/>
 </geometryOptions>
 <fieldConfiguration>
  <field name="parcel_id">
   <editWidget type="Range">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="comp_area">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="official_area">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="parcel_number">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="block">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="serial_no">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="scheme">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="file_number">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="allocation">
   <editWidget type="Range">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="owner">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="deeds_file">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="private">
   <editWidget type="CheckBox">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
 </fieldConfiguration>
 <aliases>
  <alias field="parcel_id" name="" index="0"/>
  <alias field="comp_area" name="" index="1"/>
  <alias field="official_area" name="" index="2"/>
  <alias field="parcel_number" name="" index="3"/>
  <alias field="block" name="" index="4"/>
  <alias field="serial_no" name="" index="5"/>
  <alias field="scheme" name="" index="6"/>
  <alias field="file_number" name="" index="7"/>
  <alias field="allocation" name="" index="8"/>
  <alias field="owner" name="" index="9"/>
  <alias field="deeds_file" name="" index="10"/>
  <alias field="private" name="" index="11"/>
 </aliases>
 <excludeAttributesWMS/>
 <excludeAttributesWFS/>
 <defaults>
  <default field="parcel_id" expression="" applyOnUpdate="0"/>
  <default field="comp_area" expression="" applyOnUpdate="0"/>
  <default field="official_area" expression="" applyOnUpdate="0"/>
  <default field="parcel_number" expression="" applyOnUpdate="0"/>
  <default field="block" expression="" applyOnUpdate="0"/>
  <default field="serial_no" expression="" applyOnUpdate="0"/>
  <default field="scheme" expression="" applyOnUpdate="0"/>
  <default field="file_number" expression="" applyOnUpdate="0"/>
  <default field="allocation" expression="" applyOnUpdate="0"/>
  <default field="owner" expression="" applyOnUpdate="0"/>
  <default field="deeds_file" expression="" applyOnUpdate="0"/>
  <default field="private" expression="" applyOnUpdate="0"/>
 </defaults>
 <constraints>
  <constraint field="parcel_id" constraints="3" unique_strength="1" notnull_strength="1" exp_strength="0"/>
  <constraint field="comp_area" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="official_area" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="parcel_number" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="block" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="serial_no" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="scheme" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="file_number" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="allocation" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="owner" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="deeds_file" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
  <constraint field="private" constraints="0" unique_strength="0" notnull_strength="0" exp_strength="0"/>
 </constraints>
 <constraintExpressions>
  <constraint field="parcel_id" desc="" exp=""/>
  <constraint field="comp_area" desc="" exp=""/>
  <constraint field="official_area" desc="" exp=""/>
  <constraint field="parcel_number" desc="" exp=""/>
  <constraint field="block" desc="" exp=""/>
  <constraint field="serial_no" desc="" exp=""/>
  <constraint field="scheme" desc="" exp=""/>
  <constraint field="file_number" desc="" exp=""/>
  <constraint field="allocation" desc="" exp=""/>
  <constraint field="owner" desc="" exp=""/>
  <constraint field="deeds_file" desc="" exp=""/>
  <constraint field="private" desc="" exp=""/>
 </constraintExpressions>
 <expressionfields/>
 <attributeactions>
  <defaultAction key="Canvas" value="{{00000000-0000-0000-0000-000000000000}}"/>
 </attributeactions>
 <attributetableconfig sortOrder="0" sortExpression="" actionWidgetStyle="dropDown">
  <columns>
   <column type="field" hidden="0" width="-1" name="parcel_id"/>
   <column type="field" hidden="0" width="-1" name="comp_area"/>
   <column type="field" hidden="0" width="-1" name="official_area"/>
   <column type="field" hidden="0" width="-1" name="parcel_number"/>
   <column type="field" hidden="0" width="172" name="block"/>
   <column type="field" hidden="0" width="-1" name="serial_no"/>
   <column type="field" hidden="0" width="-1" name="scheme"/>
   <column type="field" hidden="0" width="-1" name="file_number"/>
   <column type="field" hidden="0" width="-1" name="allocation"/>
   <column type="field" hidden="0" width="-1" name="owner"/>
   <column type="field" hidden="0" width="-1" name="deeds_file"/>
   <column type="field" hidden="0" width="-1" name="private"/>
   <column type="actions" hidden="1" width="-1"/>
  </columns>
 </attributetableconfig>
 <conditionalstyles>
  <rowstyles/>
  <fieldstyles/>
 </conditionalstyles>
 <editform tolerant="1">.</editform>
 <editforminit/>
 <editforminitcodesource>0</editforminitcodesource>
 <editforminitfilepath></editforminitfilepath>
 <editforminitcode><![CDATA[# -*- coding: utf-8 -*-
"""
QGIS forms can have a Python function that is called when the form is
opened.

Use this function to add extra logic to your forms.

Enter the name of the function in the "Python Init function"
field.
An example follows:
"""
from qgis.PyQt.QtWidgets import QWidget

def my_form_open(dialog, layer, feature):
  geom = feature.geometry()
  control = dialog.findChild(QWidget, "MyLineEdit")
]]></editforminitcode>
 <featformsuppress>0</featformsuppress>
 <editorlayout>generatedlayout</editorlayout>
 <editable>
  <field name="allocation" editable="1"/>
  <field name="block" editable="1"/>
  <field name="comp_area" editable="1"/>
  <field name="deeds_file" editable="1"/>
  <field name="file_number" editable="1"/>
  <field name="official_area" editable="1"/>
  <field name="owner" editable="1"/>
  <field name="parcel_id" editable="1"/>
  <field name="parcel_number" editable="1"/>
  <field name="private" editable="1"/>
  <field name="scheme" editable="1"/>
  <field name="serial_no" editable="1"/>
 </editable>
 <labelOnTop>
  <field labelOnTop="0" name="allocation"/>
  <field labelOnTop="0" name="block"/>
  <field labelOnTop="0" name="comp_area"/>
  <field labelOnTop="0" name="deeds_file"/>
  <field labelOnTop="0" name="file_number"/>
  <field labelOnTop="0" name="official_area"/>
  <field labelOnTop="0" name="owner"/>
  <field labelOnTop="0" name="parcel_id"/>
  <field labelOnTop="0" name="parcel_number"/>
  <field labelOnTop="0" name="private"/>
  <field labelOnTop="0" name="scheme"/>
  <field labelOnTop="0" name="serial_no"/>
 </labelOnTop>
 <widgets/>
 <previewExpression>parcel_id</previewExpression>
 <mapTip></mapTip>
 <layerGeometryType>2</layerGeometryType>
</qgis>
', '<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" version="1.1.0" xmlns:se="http://www.opengis.net/se" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ogc="http://www.opengis.net/ogc">
 <NamedLayer>
  <se:Name>Parcels</se:Name>
  <UserStyle>
   <se:Name>Parcels</se:Name>
   <se:FeatureTypeStyle>
    <se:Rule>
     <se:Name>parcels</se:Name>
     <se:Description>
      <se:Title>parcels</se:Title>
      <se:Abstract>Parcel boundaries</se:Abstract>
     </se:Description>
     <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
      <ogc:Or>
       <ogc:PropertyIsNotEqualTo>
        <ogc:PropertyName>block</ogc:PropertyName>
        <ogc:Literal>perimeter</ogc:Literal>
       </ogc:PropertyIsNotEqualTo>
       <ogc:PropertyIsNull>
        <ogc:PropertyName>block</ogc:PropertyName>
       </ogc:PropertyIsNull>
      </ogc:Or>
     </ogc:Filter>
     <se:MinScaleDenominator>1</se:MinScaleDenominator>
     <se:MaxScaleDenominator>20000</se:MaxScaleDenominator>
     <se:PolygonSymbolizer>
      <se:Fill>
       <se:GraphicFill>
        <se:Graphic>
         <se:Mark>
          <se:WellKnownName>x</se:WellKnownName>
          <se:Stroke>
           <se:SvgParameter name="stroke">#ff0000</se:SvgParameter>
          </se:Stroke>
         </se:Mark>
        </se:Graphic>
       </se:GraphicFill>
      </se:Fill>
      <se:Stroke>
       <se:SvgParameter name="stroke">#000000</se:SvgParameter>
       <se:SvgParameter name="stroke-width">1</se:SvgParameter>
       <se:SvgParameter name="stroke-linejoin">bevel</se:SvgParameter>
      </se:Stroke>
     </se:PolygonSymbolizer>
    </se:Rule>
    <se:Rule>
     <se:Name>parcels</se:Name>
     <se:Description>
      <se:Title>parcels</se:Title>
     </se:Description>
     <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
      <ogc:Or>
       <ogc:PropertyIsNotEqualTo>
        <ogc:PropertyName>block</ogc:PropertyName>
        <ogc:Literal>perimeter</ogc:Literal>
       </ogc:PropertyIsNotEqualTo>
       <ogc:PropertyIsNull>
        <ogc:PropertyName>block</ogc:PropertyName>
       </ogc:PropertyIsNull>
      </ogc:Or>
     </ogc:Filter>
     <se:MinScaleDenominator>20000</se:MinScaleDenominator>
     <se:PointSymbolizer>
      <se:Graphic>
       <se:Mark>
        <se:WellKnownName>square</se:WellKnownName>
        <se:Fill>
         <se:SvgParameter name="fill">#aa5500</se:SvgParameter>
        </se:Fill>
        <se:Stroke>
         <se:SvgParameter name="stroke">#aa5500</se:SvgParameter>
         <se:SvgParameter name="stroke-width">0.5</se:SvgParameter>
        </se:Stroke>
       </se:Mark>
      </se:Graphic>
     </se:PointSymbolizer>
    </se:Rule>
    <se:Rule>
     <se:Name>acquisitions</se:Name>
     <se:Description>
      <se:Title>acquisitions</se:Title>
     </se:Description>
     <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
      <ogc:Or>
       <ogc:PropertyIsNotEqualTo>
        <ogc:PropertyName>block</ogc:PropertyName>
        <ogc:Literal>acquisitionr</ogc:Literal>
       </ogc:PropertyIsNotEqualTo>
       <ogc:PropertyIsNull>
        <ogc:PropertyName>block</ogc:PropertyName>
       </ogc:PropertyIsNull>
      </ogc:Or>
     </ogc:Filter>
     <se:MinScaleDenominator>20000</se:MinScaleDenominator>
     <se:PolygonSymbolizer>
      <se:Stroke>
       <se:SvgParameter name="stroke">#aa007f</se:SvgParameter>
       <se:SvgParameter name="stroke-width">1</se:SvgParameter>
       <se:SvgParameter name="stroke-linejoin">bevel</se:SvgParameter>
       <se:SvgParameter name="stroke-dasharray">1 2</se:SvgParameter>
      </se:Stroke>
     </se:PolygonSymbolizer>
    </se:Rule>
    <se:Rule>
     <se:Name>perimeter</se:Name>
     <se:Description>
      <se:Title>perimeter</se:Title>
      <se:Abstract>Scheme perimeters</se:Abstract>
     </se:Description>
     <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
      <ogc:PropertyIsEqualTo>
       <ogc:PropertyName>block</ogc:PropertyName>
       <ogc:Literal>perimeter</ogc:Literal>
      </ogc:PropertyIsEqualTo>
     </ogc:Filter>
     <se:PolygonSymbolizer>
      <se:Stroke>
       <se:SvgParameter name="stroke">#aa0000</se:SvgParameter>
       <se:SvgParameter name="stroke-width">1</se:SvgParameter>
       <se:SvgParameter name="stroke-linejoin">bevel</se:SvgParameter>
       <se:SvgParameter name="stroke-dasharray">4 2</se:SvgParameter>
      </se:Stroke>
     </se:PolygonSymbolizer>
    </se:Rule>
    <se:Rule>
     <se:MinScaleDenominator>1</se:MinScaleDenominator>
     <se:MaxScaleDenominator>1500</se:MaxScaleDenominator>
     <se:TextSymbolizer>
      <se:Label>
       <!--SE Export for CASE WHEN block <> ''perimeter'' OR block IS NULL THEN parcel_number || ''\n'' || ''block '' || CASE WHEN block IS NOT NULL THEN block ELSE ''?'' END || '', plot '' || CASE WHEN serial_no IS NOT NULL THEN serial_no ELSE ''?'' END || ''\n'' || CASE WHEN official_area IS NOT NULL THEN official_area ELSE ''?'' END || ''m² (o)'' || ''\n'' || comp_area || ''m² (c)'' ELSE scheme END not implemented yet-->Placeholder</se:Label>
      <se:Font>
       <se:SvgParameter name="font-family">Ubuntu</se:SvgParameter>
       <se:SvgParameter name="font-size">10</se:SvgParameter>
      </se:Font>
      <se:LabelPlacement>
       <se:PointPlacement>
        <se:AnchorPoint>
         <se:AnchorPointX>0.5</se:AnchorPointX>
         <se:AnchorPointY>0.5</se:AnchorPointY>
        </se:AnchorPoint>
       </se:PointPlacement>
      </se:LabelPlacement>
      <se:Halo>
       <se:Radius>0.05</se:Radius>
       <se:Fill>
        <se:SvgParameter name="fill">#ffffff</se:SvgParameter>
       </se:Fill>
      </se:Halo>
      <se:Fill>
       <se:SvgParameter name="fill">#000000</se:SvgParameter>
      </se:Fill>
      <se:Priority>1000</se:Priority>
     </se:TextSymbolizer>
    </se:Rule>
   </se:FeatureTypeStyle>
  </UserStyle>
 </NamedLayer>
</StyledLayerDescriptor>
', true, 'Mon Jul 8 11:25:02 2019', ':DBOWNER', NULL, '2019-07-08 09:25:02.645003');




--
-- Name: layer_styles layer_styles_pkey; Type: CONSTRAINT; Schema: public;
--

ALTER TABLE ONLY public.layer_styles
    ADD CONSTRAINT layer_styles_pkey PRIMARY KEY (id);



--
-- Name: beacons gid; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY beacons ALTER COLUMN gid SET DEFAULT nextval('beacons_gid_seq'::regclass);


--
-- Name: beardist id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY beardist ALTER COLUMN id SET DEFAULT nextval('beardist_id_seq'::regclass);


--
-- Name: deeds deed_sn; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY deeds ALTER COLUMN deed_sn SET DEFAULT nextval('deeds_deed_sn_seq'::regclass);


--
-- Name: hist_beacons hist_id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY hist_beacons ALTER COLUMN hist_id SET DEFAULT nextval('hist_beacons_hist_id_seq'::regclass);


--
-- Name: instrument_cat instrument_cat; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY instrument_cat ALTER COLUMN instrument_cat SET DEFAULT nextval('instrument_cat_instrument_cat_seq'::regclass);


--
-- Name: local_govt id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY local_govt ALTER COLUMN id SET DEFAULT nextval('local_govt_id_seq'::regclass);


--
-- Name: parcel_def id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY parcel_def ALTER COLUMN id SET DEFAULT nextval('parcel_def_id_seq'::regclass);


--
-- Name: parcel_lookup parcel_id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY parcel_lookup ALTER COLUMN parcel_id SET DEFAULT nextval('parcel_lookup_parcel_id_seq'::regclass);


--
-- Name: print_survey_details id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY print_survey_details ALTER COLUMN id SET DEFAULT nextval('print_survey_details_id_seq'::regclass);


--
-- Name: prop_types id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY prop_types ALTER COLUMN id SET DEFAULT nextval('prop_types_id_seq'::regclass);


--
-- Name: schemes id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY schemes ALTER COLUMN id SET DEFAULT nextval('schemes_id_seq'::regclass);


--
-- Name: status_cat status_cat; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY status_cat ALTER COLUMN status_cat SET DEFAULT nextval('status_cat_status_cat_seq'::regclass);


--
-- Name: survey id; Type: DEFAULT; Schema: public; 
--

ALTER TABLE ONLY survey ALTER COLUMN id SET DEFAULT nextval('survey_id_seq'::regclass);


--
-- Name: allocation_cat allocation_cat_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY allocation_cat
    ADD CONSTRAINT allocation_cat_pkey PRIMARY KEY (allocation_cat);


--
-- Name: beacons beacons_beacon_key; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beacons
    ADD CONSTRAINT beacons_beacon_key UNIQUE (beacon);


--
-- Name: beacons beacons_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beacons
    ADD CONSTRAINT beacons_pkey PRIMARY KEY (gid);


--
-- Name: beardist beardist_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_pkey PRIMARY KEY (id);


--
-- Name: deeds dkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY deeds
    ADD CONSTRAINT dkey PRIMARY KEY (deed_sn);


--
-- Name: hist_beacons hist_beacons_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY hist_beacons
    ADD CONSTRAINT hist_beacons_pkey PRIMARY KEY (hist_id);


--
-- Name: instrument_cat instrument_cat_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY instrument_cat
    ADD CONSTRAINT instrument_cat_pkey PRIMARY KEY (instrument_cat);


--
-- Name: local_govt local_govt_id_key; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY local_govt
    ADD CONSTRAINT local_govt_id_key UNIQUE (local_govt_name);


--
-- Name: local_govt local_govt_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY local_govt
    ADD CONSTRAINT local_govt_pkey PRIMARY KEY (id);


--
-- Name: parcel_def parcel_def_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_pkey PRIMARY KEY (id);


--
-- Name: parcel_lookup parcel_lookup_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_pkey PRIMARY KEY (parcel_id);


--
-- Name: print_survey_details print_survey_details_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY print_survey_details
    ADD CONSTRAINT print_survey_details_pkey PRIMARY KEY (id);


--
-- Name: prop_types prop_type_code_key; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_code_key UNIQUE (code);


--
-- Name: prop_types prop_type_id_key; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_id_key UNIQUE (prop_type_name);


--
-- Name: prop_types prop_type_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_pkey PRIMARY KEY (id);


--
-- Name: schemes schemes_id_key; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY schemes
    ADD CONSTRAINT schemes_id_key UNIQUE (scheme_name);


--
-- Name: schemes schemes_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY schemes
    ADD CONSTRAINT schemes_pkey PRIMARY KEY (id);


--
-- Name: status_cat status_cat_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY status_cat
    ADD CONSTRAINT status_cat_pkey PRIMARY KEY (status_cat);


--
-- Name: survey survey_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_pkey PRIMARY KEY (id);


--
-- Name: survey survey_plan_no_key; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_plan_no_key UNIQUE (plan_no);


--
-- Name: survey survey_plan_no_key1; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_plan_no_key1 UNIQUE (plan_no);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: beacons_beacon_idx; Type: INDEX; Schema: public; 
--

CREATE INDEX beacons_beacon_idx ON beacons USING btree (beacon);


--
-- Name: beardist_beacon_from_idx; Type: INDEX; Schema: public; 
--

CREATE INDEX beardist_beacon_from_idx ON beardist USING btree (beacon_from);


--
-- Name: beardist_beacon_to_idx; Type: INDEX; Schema: public; 
--

CREATE INDEX beardist_beacon_to_idx ON beardist USING btree (beacon_to);


--
-- Name: beardist_ndx1; Type: INDEX; Schema: public; 
--

CREATE INDEX beardist_ndx1 ON beardist USING btree (beacon_from);


--
-- Name: beardist_plan_no_idx; Type: INDEX; Schema: public; 
--

CREATE INDEX beardist_plan_no_idx ON beardist USING btree (plan_no);


--
-- Name: fki_parcel_lookup_status_cat_fkey; Type: INDEX; Schema: public; 
--

CREATE INDEX fki_parcel_lookup_status_cat_fkey ON parcel_lookup USING btree (status);


--
-- Name: fki_transactions_instrument_fkey; Type: INDEX; Schema: public; 
--

CREATE INDEX fki_transactions_instrument_fkey ON transactions USING btree (instrument);


--
-- Name: fki_transactions_parcel_fkey; Type: INDEX; Schema: public; 
--

CREATE INDEX fki_transactions_parcel_fkey ON transactions USING btree (parcel_id);


--
-- Name: fki_transactions_survey_fkey; Type: INDEX; Schema: public; 
--

CREATE INDEX fki_transactions_survey_fkey ON transactions USING btree (survey);


--
-- Name: hist_beacons_idx1; Type: INDEX; Schema: public; 
--

CREATE INDEX hist_beacons_idx1 ON hist_beacons USING btree (gid);


--
-- Name: hist_beacons_idx2; Type: INDEX; Schema: public; 
--

CREATE INDEX hist_beacons_idx2 ON hist_beacons USING btree (hist_time);






--
-- Name: ndx_schemes1; Type: INDEX; Schema: public; 
--

CREATE INDEX ndx_schemes1 ON schemes USING gin (to_tsvector('english'::regconfig, (COALESCE(scheme_name, ''::character varying))::text));




--
-- Name: sidx_beacons_geom; Type: INDEX; Schema: public; 
--

CREATE INDEX sidx_beacons_geom ON beacons USING gist (the_geom);







--
-- Name: beacons insert_nodes_geom; Type: TRIGGER; Schema: public; 
--

CREATE TRIGGER insert_nodes_geom BEFORE INSERT OR UPDATE ON beacons FOR EACH ROW EXECUTE PROCEDURE calc_point();


--
-- Name: parcel_def parcel_lookup_define_parcel; Type: TRIGGER; Schema: public; 
--

CREATE TRIGGER parcel_lookup_define_parcel BEFORE INSERT OR UPDATE ON parcel_def FOR EACH ROW EXECUTE PROCEDURE parcel_lookup_define_parcel_trigger();


--
-- Name: beacons trg_beacons_after_insert; Type: TRIGGER; Schema: public; 
--

CREATE TRIGGER trg_beacons_after_insert AFTER INSERT ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_after_insert();


--
-- Name: beacons trg_beacons_before_delete; Type: TRIGGER; Schema: public; 
--

CREATE TRIGGER trg_beacons_before_delete BEFORE DELETE ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_before_delete();


--
-- Name: beacons trg_beacons_before_update; Type: TRIGGER; Schema: public; 
--

CREATE TRIGGER trg_beacons_before_update BEFORE UPDATE ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_before_update();


--
-- Name: beardist beardist_beacon_from_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_from_fkey FOREIGN KEY (beacon_from) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_from_fkey1; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_from_fkey1 FOREIGN KEY (beacon_from) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_to_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_to_fkey FOREIGN KEY (beacon_to) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_to_fkey1; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_to_fkey1 FOREIGN KEY (beacon_to) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_plan_no_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_plan_no_fkey FOREIGN KEY (plan_no) REFERENCES survey(plan_no) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_plan_no_fkey1; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_plan_no_fkey1 FOREIGN KEY (plan_no) REFERENCES survey(plan_no) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_def parcel_def_beacon_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_beacon_fkey FOREIGN KEY (beacon) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_def parcel_def_parcel_id_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_parcel_id_fkey FOREIGN KEY (parcel_id) REFERENCES parcel_lookup(parcel_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_allocation_id_fkey FOREIGN KEY (allocation) REFERENCES allocation_cat(allocation_cat) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_local_govt_id_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_local_govt_id_fkey FOREIGN KEY (local_govt) REFERENCES local_govt(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_prop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_prop_type_id_fkey FOREIGN KEY (prop_type) REFERENCES prop_types(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_scheme_id_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_scheme_id_fkey FOREIGN KEY (scheme) REFERENCES schemes(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_status_cat_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_status_cat_fkey FOREIGN KEY (status) REFERENCES status_cat(status_cat);


--
-- Name: survey survey_ref_beacon_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_ref_beacon_fkey FOREIGN KEY (ref_beacon) REFERENCES beacons(beacon);


--
-- Name: survey survey_scheme_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_scheme_fkey FOREIGN KEY (scheme) REFERENCES schemes(id);


--
-- Name: transactions transactions_instrument_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_instrument_fkey FOREIGN KEY (instrument) REFERENCES instrument_cat(instrument_cat);


--
-- Name: transactions transactions_parcel_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_parcel_fkey FOREIGN KEY (parcel_id) REFERENCES parcel_lookup(parcel_id);


--
-- Name: transactions transactions_survey_fkey; Type: FK CONSTRAINT; Schema: public; 
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_survey_fkey FOREIGN KEY (survey) REFERENCES survey(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--




--
-- PostgreSQL database dump complete
--

