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
-- Name: beardistinsert(character varying, double precision, double precision, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: beardistupdate(character varying, double precision, double precision, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: calc_point(); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: fn_beacons_after_insert(); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: fn_beacons_before_delete(); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: fn_beacons_before_update(); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: fn_updateprintjobs(); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: parcel_lookup_availability_trigger(); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: parcel_lookup_define_parcel_trigger(); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: parcels_matview_refresh_row(integer); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION parcels_matview_refresh_row(integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
BEGIN
  DELETE FROM parcels_matview WHERE parcel_id = $1;
  INSERT INTO parcels_matview SELECT * FROM parcels WHERE parcel_id = $1;
  RETURN;
END
$_$;



--
-- Name: pointfrombearinganddistance(double precision, double precision, double precision, double precision, integer, integer); Type: FUNCTION; Schema: public; Owner: docker
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
-- Name: allocation_cat; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE allocation_cat (
    description character varying(50) NOT NULL,
    allocation_cat integer NOT NULL
);



--
-- Name: allocation_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE allocation_cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: allocation_cat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE allocation_cat_id_seq OWNED BY allocation_cat.allocation_cat;


--
-- Name: beacons; Type: TABLE; Schema: public; Owner: docker
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
-- Name: beacons_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE beacons_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: beacons_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE beacons_gid_seq OWNED BY beacons.gid;


--
-- Name: parcel_def; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE parcel_def (
    id integer NOT NULL,
    beacon character varying(20) NOT NULL,
    sequence integer NOT NULL,
    parcel_id integer
);



--
-- Name: parcel_lookup; Type: TABLE; Schema: public; Owner: docker
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
-- Name: COLUMN parcel_lookup.plot_sn; Type: COMMENT; Schema: public; Owner: docker
--

COMMENT ON COLUMN parcel_lookup.plot_sn IS 'plot serial no within a block. Forms part of the parcel no';


--
-- Name: beacons_views; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW beacons_views AS
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
  WITH NO DATA;



--
-- Name: deeds; Type: TABLE; Schema: public; Owner: docker
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
-- Name: schemes; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE schemes (
    id integer NOT NULL,
    scheme_name character varying(50) NOT NULL,
    "Scheme" smallint
);



--
-- Name: COLUMN schemes."Scheme"; Type: COMMENT; Schema: public; Owner: docker
--

COMMENT ON COLUMN schemes."Scheme" IS 'line';


--
-- Name: parcels; Type: VIEW; Schema: public; Owner: docker
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
-- Name: beacons_intersect; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW beacons_intersect AS
 SELECT a.beacon,
    a.the_geom,
    a.x,
    a.y,
    b.parcel_id,
    a.private
   FROM (beacons_views a
     LEFT JOIN parcels b ON ((a.parcel_id = b.parcel_id)))
  WITH NO DATA;



--
-- Name: beardist; Type: TABLE; Schema: public; Owner: docker
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
-- Name: beardist_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE beardist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: beardist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE beardist_id_seq OWNED BY beardist.id;


--
-- Name: bearing_labels; Type: VIEW; Schema: public; Owner: docker
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
-- Name: boundaries; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW boundaries AS
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
  WITH NO DATA;



--
-- Name: boundary_labels; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW boundary_labels AS
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
  WITH NO DATA;



--
-- Name: deeds_deed_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE deeds_deed_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: deeds_deed_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE deeds_deed_sn_seq OWNED BY deeds.deed_sn;


--
-- Name: derived_boundaries; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW derived_boundaries AS
 SELECT b.id,
    b.parcel_id,
    b.geom,
    b.distance,
    b.bearing
   FROM boundaries b
  WHERE (NOT (b.id IN ( SELECT b_1.id
           FROM (boundaries b_1
             JOIN boundary_labels bl ON (st_equals(b_1.geom, bl.geom))))))
  WITH NO DATA;



--
-- Name: hist_beacons; Type: TABLE; Schema: public; Owner: docker
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
-- Name: hist_beacons_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE hist_beacons_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: hist_beacons_hist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE hist_beacons_hist_id_seq OWNED BY hist_beacons.hist_id;


--
-- Name: instrument_cat; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE instrument_cat (
    instrument_cat integer NOT NULL,
    description character varying NOT NULL
);



--
-- Name: instrument_cat_instrument_cat_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE instrument_cat_instrument_cat_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: instrument_cat_instrument_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE instrument_cat_instrument_cat_seq OWNED BY instrument_cat.instrument_cat;


--
-- Name: local_govt; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE local_govt (
    id integer NOT NULL,
    local_govt_name character varying(50) NOT NULL
);



--
-- Name: local_govt_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE local_govt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: local_govt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE local_govt_id_seq OWNED BY local_govt.id;


--
-- Name: localmotclass_code_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE localmotclass_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: localrdclass_code_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE localrdclass_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: parcel_def_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE parcel_def_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: parcel_def_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE parcel_def_id_seq OWNED BY parcel_def.id;


--
-- Name: parcel_lookup_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE parcel_lookup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: parcel_lookup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE parcel_lookup_id_seq OWNED BY parcel_lookup.plot_sn;


--
-- Name: parcel_lookup_parcel_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE parcel_lookup_parcel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: parcel_lookup_parcel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE parcel_lookup_parcel_id_seq OWNED BY parcel_lookup.parcel_id;


--
-- Name: perimeters; Type: VIEW; Schema: public; Owner: docker
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
-- Name: parcel_overlap_matviews; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW parcel_overlap_matviews AS
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
  WITH NO DATA;



--
-- Name: parcels_intersect; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW parcels_intersect AS
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
  WITH NO DATA;



--
-- Name: parcels_lines; Type: VIEW; Schema: public; Owner: docker
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
-- Name: parcels_line_length; Type: VIEW; Schema: public; Owner: docker
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
-- Name: perimeters_original; Type: VIEW; Schema: public; Owner: docker
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
-- Name: print_survey_details; Type: TABLE; Schema: public; Owner: docker
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
-- Name: print_survey_details_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE print_survey_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: print_survey_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE print_survey_details_id_seq OWNED BY print_survey_details.id;


--
-- Name: prop_types; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE prop_types (
    id integer NOT NULL,
    code character varying(2) NOT NULL,
    prop_type_name character varying(50) NOT NULL
);



--
-- Name: prop_types_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE prop_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: prop_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE prop_types_id_seq OWNED BY prop_types.id;


--
-- Name: reference_view; Type: TABLE; Schema: public; Owner: docker
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
-- Name: schemes_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE schemes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: schemes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE schemes_id_seq OWNED BY schemes.id;


--
-- Name: speed_code_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE speed_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: status_cat; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE status_cat (
    status_cat integer NOT NULL,
    description character varying NOT NULL
);



--
-- Name: status_cat_status_cat_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE status_cat_status_cat_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: status_cat_status_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE status_cat_status_cat_seq OWNED BY status_cat.status_cat;


--
-- Name: str_type_strid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE str_type_strid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: survey; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE survey (
    id integer NOT NULL,
    plan_no character varying(20) NOT NULL,
    ref_beacon character varying(20) NOT NULL,
    scheme integer,
    description character varying(255)
);



--
-- Name: survey_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE survey_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: survey_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE survey_id_seq OWNED BY survey.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: docker
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



--
-- Name: allocation_cat allocation_cat; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY allocation_cat ALTER COLUMN allocation_cat SET DEFAULT nextval('allocation_cat_id_seq'::regclass);


--
-- Name: beacons gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beacons ALTER COLUMN gid SET DEFAULT nextval('beacons_gid_seq'::regclass);


--
-- Name: beardist id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist ALTER COLUMN id SET DEFAULT nextval('beardist_id_seq'::regclass);


--
-- Name: deeds deed_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY deeds ALTER COLUMN deed_sn SET DEFAULT nextval('deeds_deed_sn_seq'::regclass);


--
-- Name: hist_beacons hist_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY hist_beacons ALTER COLUMN hist_id SET DEFAULT nextval('hist_beacons_hist_id_seq'::regclass);


--
-- Name: instrument_cat instrument_cat; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY instrument_cat ALTER COLUMN instrument_cat SET DEFAULT nextval('instrument_cat_instrument_cat_seq'::regclass);


--
-- Name: local_govt id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY local_govt ALTER COLUMN id SET DEFAULT nextval('local_govt_id_seq'::regclass);


--
-- Name: parcel_def id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_def ALTER COLUMN id SET DEFAULT nextval('parcel_def_id_seq'::regclass);


--
-- Name: parcel_lookup parcel_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup ALTER COLUMN parcel_id SET DEFAULT nextval('parcel_lookup_parcel_id_seq'::regclass);


--
-- Name: print_survey_details id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY print_survey_details ALTER COLUMN id SET DEFAULT nextval('print_survey_details_id_seq'::regclass);


--
-- Name: prop_types id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY prop_types ALTER COLUMN id SET DEFAULT nextval('prop_types_id_seq'::regclass);


--
-- Name: schemes id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY schemes ALTER COLUMN id SET DEFAULT nextval('schemes_id_seq'::regclass);


--
-- Name: status_cat status_cat; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY status_cat ALTER COLUMN status_cat SET DEFAULT nextval('status_cat_status_cat_seq'::regclass);


--
-- Name: survey id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey ALTER COLUMN id SET DEFAULT nextval('survey_id_seq'::regclass);


--
-- Name: allocation_cat allocation_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY allocation_cat
    ADD CONSTRAINT allocation_cat_pkey PRIMARY KEY (allocation_cat);


--
-- Name: beacons beacons_beacon_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beacons
    ADD CONSTRAINT beacons_beacon_key UNIQUE (beacon);


--
-- Name: beacons beacons_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beacons
    ADD CONSTRAINT beacons_pkey PRIMARY KEY (gid);


--
-- Name: beardist beardist_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_pkey PRIMARY KEY (id);


--
-- Name: deeds dkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY deeds
    ADD CONSTRAINT dkey PRIMARY KEY (deed_sn);


--
-- Name: hist_beacons hist_beacons_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY hist_beacons
    ADD CONSTRAINT hist_beacons_pkey PRIMARY KEY (hist_id);


--
-- Name: instrument_cat instrument_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY instrument_cat
    ADD CONSTRAINT instrument_cat_pkey PRIMARY KEY (instrument_cat);


--
-- Name: local_govt local_govt_id_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY local_govt
    ADD CONSTRAINT local_govt_id_key UNIQUE (local_govt_name);


--
-- Name: local_govt local_govt_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY local_govt
    ADD CONSTRAINT local_govt_pkey PRIMARY KEY (id);


--
-- Name: parcel_def parcel_def_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_pkey PRIMARY KEY (id);


--
-- Name: parcel_lookup parcel_lookup_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_pkey PRIMARY KEY (parcel_id);


--
-- Name: print_survey_details print_survey_details_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY print_survey_details
    ADD CONSTRAINT print_survey_details_pkey PRIMARY KEY (id);


--
-- Name: prop_types prop_type_code_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_code_key UNIQUE (code);


--
-- Name: prop_types prop_type_id_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_id_key UNIQUE (prop_type_name);


--
-- Name: prop_types prop_type_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_pkey PRIMARY KEY (id);


--
-- Name: schemes schemes_id_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY schemes
    ADD CONSTRAINT schemes_id_key UNIQUE (scheme_name);


--
-- Name: schemes schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY schemes
    ADD CONSTRAINT schemes_pkey PRIMARY KEY (id);


--
-- Name: status_cat status_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY status_cat
    ADD CONSTRAINT status_cat_pkey PRIMARY KEY (status_cat);


--
-- Name: survey survey_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_pkey PRIMARY KEY (id);


--
-- Name: survey survey_plan_no_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_plan_no_key UNIQUE (plan_no);


--
-- Name: survey survey_plan_no_key1; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_plan_no_key1 UNIQUE (plan_no);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: beacons_beacon_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beacons_beacon_idx ON beacons USING btree (beacon);


--
-- Name: beardist_beacon_from_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beardist_beacon_from_idx ON beardist USING btree (beacon_from);


--
-- Name: beardist_beacon_to_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beardist_beacon_to_idx ON beardist USING btree (beacon_to);


--
-- Name: beardist_ndx1; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beardist_ndx1 ON beardist USING btree (beacon_from);


--
-- Name: beardist_plan_no_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beardist_plan_no_idx ON beardist USING btree (plan_no);


--
-- Name: fki_parcel_lookup_status_cat_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_parcel_lookup_status_cat_fkey ON parcel_lookup USING btree (status);


--
-- Name: fki_transactions_instrument_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_transactions_instrument_fkey ON transactions USING btree (instrument);


--
-- Name: fki_transactions_parcel_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_transactions_parcel_fkey ON transactions USING btree (parcel_id);


--
-- Name: fki_transactions_survey_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_transactions_survey_fkey ON transactions USING btree (survey);


--
-- Name: hist_beacons_idx1; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX hist_beacons_idx1 ON hist_beacons USING btree (gid);


--
-- Name: hist_beacons_idx2; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX hist_beacons_idx2 ON hist_beacons USING btree (hist_time);


--
-- Name: idp_beacons_intersect; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_beacons_intersect ON beacons_intersect USING btree (beacon);


--
-- Name: idp_beacons_mtview; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_beacons_mtview ON beacons_views USING btree (gid);


--
-- Name: idp_parcel_overlap_matviews; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_parcel_overlap_matviews ON parcel_overlap_matviews USING btree (parcel_id);


--
-- Name: idp_parcels_intersect; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_parcels_intersect ON parcels_intersect USING btree (parcel_id);


--
-- Name: idx_beacons_intersect_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_beacons_intersect_geom ON beacons_intersect USING gist (the_geom);


--
-- Name: idx_beacons_matviews_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_beacons_matviews_geom ON beacons_views USING gist (the_geom);


--
-- Name: idx_boundaries_labels_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_boundaries_labels_geom ON boundaries USING gist (geom);


--
-- Name: idx_boundary_labels_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_boundary_labels_geom ON boundary_labels USING gist (geom);


--
-- Name: idx_derived_boundaries_labels_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_derived_boundaries_labels_geom ON derived_boundaries USING gist (geom);


--
-- Name: idx_parcels_intersects_new_matviews_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_parcels_intersects_new_matviews_geom ON parcels_intersect USING gist (the_geom);


--
-- Name: ndx_schemes1; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX ndx_schemes1 ON schemes USING gin (to_tsvector('english'::regconfig, (COALESCE(scheme_name, ''::character varying))::text));


--
-- Name: parcel_over_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX parcel_over_idx ON parcel_overlap_matviews USING gist (the_geom);


--
-- Name: sidx_beacons_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX sidx_beacons_geom ON beacons USING gist (the_geom);


--
-- Name: beacons insert_nodes_geom; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER insert_nodes_geom BEFORE INSERT OR UPDATE ON beacons FOR EACH ROW EXECUTE PROCEDURE calc_point();


--
-- Name: parcel_def parcel_lookup_define_parcel; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER parcel_lookup_define_parcel BEFORE INSERT OR UPDATE ON parcel_def FOR EACH ROW EXECUTE PROCEDURE parcel_lookup_define_parcel_trigger();


--
-- Name: beacons trg_beacons_after_insert; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER trg_beacons_after_insert AFTER INSERT ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_after_insert();


--
-- Name: beacons trg_beacons_before_delete; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER trg_beacons_before_delete BEFORE DELETE ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_before_delete();


--
-- Name: beacons trg_beacons_before_update; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER trg_beacons_before_update BEFORE UPDATE ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_before_update();


--
-- Name: beardist beardist_beacon_from_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_from_fkey FOREIGN KEY (beacon_from) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_from_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_from_fkey1 FOREIGN KEY (beacon_from) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_to_fkey FOREIGN KEY (beacon_to) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_to_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_to_fkey1 FOREIGN KEY (beacon_to) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_plan_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_plan_no_fkey FOREIGN KEY (plan_no) REFERENCES survey(plan_no) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_plan_no_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_plan_no_fkey1 FOREIGN KEY (plan_no) REFERENCES survey(plan_no) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_def parcel_def_beacon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_beacon_fkey FOREIGN KEY (beacon) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_def parcel_def_parcel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_parcel_id_fkey FOREIGN KEY (parcel_id) REFERENCES parcel_lookup(parcel_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_allocation_id_fkey FOREIGN KEY (allocation) REFERENCES allocation_cat(allocation_cat) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_local_govt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_local_govt_id_fkey FOREIGN KEY (local_govt) REFERENCES local_govt(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_prop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_prop_type_id_fkey FOREIGN KEY (prop_type) REFERENCES prop_types(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_scheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_scheme_id_fkey FOREIGN KEY (scheme) REFERENCES schemes(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_status_cat_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_status_cat_fkey FOREIGN KEY (status) REFERENCES status_cat(status_cat);


--
-- Name: survey survey_ref_beacon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_ref_beacon_fkey FOREIGN KEY (ref_beacon) REFERENCES beacons(beacon);


--
-- Name: survey survey_scheme_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_scheme_fkey FOREIGN KEY (scheme) REFERENCES schemes(id);


--
-- Name: transactions transactions_instrument_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_instrument_fkey FOREIGN KEY (instrument) REFERENCES instrument_cat(instrument_cat);


--
-- Name: transactions transactions_parcel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_parcel_fkey FOREIGN KEY (parcel_id) REFERENCES parcel_lookup(parcel_id);


--
-- Name: transactions transactions_survey_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_survey_fkey FOREIGN KEY (survey) REFERENCES survey(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--




--
-- PostgreSQL database dump complete
--

