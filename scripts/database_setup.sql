--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = ON;
SET check_function_bodies = FALSE;
SET client_min_messages = WARNING;
SET row_security = OFF;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--


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
-- Name: beardistinsert(character varying, double precision, double precision, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION beardistinsert(arg_plan_no   CHARACTER VARYING, arg_bearing DOUBLE PRECISION,
                               arg_distance  DOUBLE PRECISION, arg_beacon_from CHARACTER VARYING,
                               arg_beacon_to CHARACTER VARYING, arg_location CHARACTER VARYING,
                               arg_name      CHARACTER VARYING)
  RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  the_x    DOUBLE PRECISION;
  the_y    DOUBLE PRECISION;
  the_geom GEOMETRY(Point, :CRS);
BEGIN
  SELECT x
  INTO the_x
  FROM beacons
  WHERE beacon = arg_beacon_from;
  SELECT y
  INTO the_y
  FROM beacons
  WHERE beacon = arg_beacon_from;
  the_geom := pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, :CRS);
  INSERT INTO beacons (beacon, y, x, "location", "name")
  VALUES (arg_beacon_to, st_y(the_geom), st_x(the_geom), arg_location, arg_name);
  INSERT INTO beardist (plan_no, bearing, distance, beacon_from, beacon_to)
  VALUES (arg_plan_no, arg_bearing, arg_distance, arg_beacon_from, arg_beacon_to);
END
$$;

--
-- Name: beardistupdate(character varying, double precision, double precision, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION beardistupdate(arg_plan_no   CHARACTER VARYING, arg_bearing DOUBLE PRECISION,
                               arg_distance  DOUBLE PRECISION, arg_beacon_from CHARACTER VARYING,
                               arg_beacon_to CHARACTER VARYING, arg_location CHARACTER VARYING,
                               arg_name      CHARACTER VARYING, arg_index INTEGER)
  RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  the_id_beardist INTEGER;
  the_id_beacons  INTEGER;
  the_x           DOUBLE PRECISION;
  the_y           DOUBLE PRECISION;
  the_geom_       GEOMETRY(Point, :CRS);
BEGIN
  SELECT i.id
  INTO the_id_beardist
  FROM (
         SELECT
           bd.id,
           row_number()
           OVER (
             ORDER BY bd.id ) - 1 AS index
         FROM beardist bd
           INNER JOIN beacons b ON bd.beacon_to = b.beacon
         WHERE bd.plan_no = arg_plan_no
       ) AS i
  WHERE i.index = arg_index;
  SELECT gid
  INTO the_id_beacons
  FROM beacons b INNER JOIN beardist bd ON b.beacon = bd.beacon_to
  WHERE bd.id = the_id_beardist;
  SELECT x
  INTO the_x
  FROM beacons
  WHERE beacon = arg_beacon_from;
  SELECT y
  INTO the_y
  FROM beacons
  WHERE beacon = arg_beacon_from;
  SELECT pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, :CRS)
  INTO the_geom_;
  UPDATE beacons
  SET
    beacon     = arg_beacon_to,
    y          = st_y(the_geom_),
    x          = st_x(the_geom_),
    "location" = arg_location,
    "name"     = arg_name
  WHERE gid = the_id_beacons;
  UPDATE beardist
  SET
    plan_no     = arg_plan_no,
    bearing     = arg_bearing,
    distance    = arg_distance,
    beacon_from = arg_beacon_from,
    beacon_to   = arg_beacon_to
  WHERE id = the_id_beardist;
END
$$;

--
-- Name: calc_point(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION calc_point()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.the_geom:=ST_SetSRID(ST_MakePoint(new.x, new.y), :CRS);
  RETURN NEW;
END
$$;

--
-- Name: fn_beacons_after_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_beacons_after_insert()
  RETURNS TRIGGER
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
-- Name: fn_beacons_before_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_beacons_before_delete()
  RETURNS TRIGGER
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
-- Name: fn_beacons_before_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_beacons_before_update()
  RETURNS TRIGGER
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
-- Name: fn_updateprintjobs(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_updateprintjobs()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.created IS NOT NULL
  THEN
    NEW.created = NEW.created + INTERVAL '2 hours';
  END IF;
  IF NEW.done IS NOT NULL
  THEN
    NEW.done = NEW.done + INTERVAL '2 hours';
  END IF;
  RETURN NEW;
END;
$$;

--
-- Name: parcel_lookup_availability_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION parcel_lookup_availability_trigger()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE parcel_lookup
  SET available = TRUE;
  UPDATE parcel_lookup
  SET available = FALSE
  WHERE parcel_id IN (SELECT parcel_id
                      FROM parcel_def
                      GROUP BY parcel_id);
  RETURN NEW;
END
$$;

--
-- Name: parcel_lookup_define_parcel_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION parcel_lookup_define_parcel_trigger()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF (SELECT COUNT(*) :: INTEGER
      FROM parcel_lookup
      WHERE parcel_id = NEW.parcel_id) = 0
  THEN
    INSERT INTO parcel_lookup (parcel_id) VALUES (NEW.parcel_id);
  END IF;
  RETURN NEW;
END
$$;

--
-- Name: parcels_matview_refresh_row(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION parcels_matview_refresh_row(INTEGER)
  RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
AS $_$
BEGIN
  DELETE FROM parcels_matview
  WHERE parcel_id = $1;
  INSERT INTO parcels_matview SELECT *
                              FROM parcels
                              WHERE parcel_id = $1;
  RETURN;
END
$_$;

--
-- Name: pointfrombearinganddistance(double precision, double precision, double precision, double precision, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pointfrombearinganddistance(dstarte  DOUBLE PRECISION, dstartn DOUBLE PRECISION,
                                            dbearing DOUBLE PRECISION, ddistance DOUBLE PRECISION, "precision" INTEGER,
                                            srid     INTEGER)
  RETURNS GEOMETRY
LANGUAGE plpgsql
AS $$
DECLARE
  dangle1     DOUBLE PRECISION;
  dangle1rad  DOUBLE PRECISION;
  ddeltan     DOUBLE PRECISION;
  ddeltae     DOUBLE PRECISION;
  dende       DOUBLE PRECISION;
  dendn       DOUBLE PRECISION;
  "precision" INT;
  srid        INT;
BEGIN
  precision := CASE WHEN precision IS NULL
    THEN 3
               ELSE precision END;
  srid := CASE WHEN srid IS NULL
    THEN 4326
          ELSE srid END;
  BEGIN
    IF
    dstarte IS NULL OR
    dstartn IS NULL OR
    dbearing IS NULL OR
    ddistance IS NULL
    THEN RETURN NULL;
    END IF;
    IF dbearing < 90
    THEN
      dangle1    := 90 - dbearing;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance;
      ddeltan    := Sin(dangle1rad) * ddistance;
    END IF;
    IF dbearing < 180
    THEN
      dangle1    := dbearing - 90;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance;
      ddeltan    := Sin(dangle1rad) * ddistance * -1;
    END IF;
    IF dbearing < 270
    THEN
      dangle1    := 270 - dbearing;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance * -1;
      ddeltan    := Sin(dangle1rad) * ddistance * -1;
    END IF;
    IF dbearing <= 360
    THEN
      dangle1    := dbearing - 270;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance * -1;
      ddeltan    := Sin(dangle1rad) * ddistance;
    END IF;
    dende := ddeltae + dstarte;
    dendn := ddeltan + dstartn;
    RETURN ST_SetSRID(ST_MakePoint(round(dende :: NUMERIC, precision), round(dendn :: NUMERIC, precision)), :CRS);
  END;
END;
$$;

--
-- Name: refreshallmaterializedviews(text); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION refreshallmaterializedviews(schema_arg TEXT DEFAULT 'public' :: TEXT)
  RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  r RECORD;
BEGIN
  RAISE NOTICE 'Refreshing materialized view in schema %', schema_arg;
  FOR r IN SELECT matviewname
           FROM pg_matviews
           WHERE schemaname = schema_arg
  LOOP
    RAISE NOTICE 'Refreshing %.%', schema_arg, r.matviewname;
    EXECUTE 'REFRESH MATERIALIZED VIEW ' || schema_arg || '.' || r.matviewname;
  END LOOP;

  RETURN 1;
END
$$;

--
-- Name: refreshallmaterializedviewsconcurrently(text); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION refreshallmaterializedviewsconcurrently(schema_arg TEXT DEFAULT 'public' :: TEXT)
  RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  r RECORD;
BEGIN
  RAISE NOTICE 'Refreshing materialized view in schema %', schema_arg;
  FOR r IN SELECT matviewname
           FROM pg_matviews
           WHERE schemaname = schema_arg
  LOOP
    RAISE NOTICE 'Refreshing %.%', schema_arg, r.matviewname;
    EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY ' || schema_arg || '.' || r.matviewname;
  END LOOP;

  RETURN 1;
END
$$;


SET default_tablespace = '';

SET default_with_oids = FALSE;

--
-- Name: allocation_cat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE allocation_cat (
  description    CHARACTER VARYING(50) NOT NULL,
  allocation_cat INTEGER               NOT NULL
);

--
-- Name: allocation_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE allocation_cat_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: allocation_cat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE allocation_cat_id_seq OWNED BY allocation_cat.allocation_cat;

--
-- Name: beacons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE beacons (
  gid              INTEGER                NOT NULL,
  beacon           CHARACTER VARYING(80)  NOT NULL,
  y                DOUBLE PRECISION       NOT NULL,
  x                DOUBLE PRECISION       NOT NULL,
  the_geom         GEOMETRY(Point, :CRS) NOT NULL,
  location         CHARACTER VARYING(180),
  name             CHARACTER VARYING(100),
  last_modified_by CHARACTER VARYING
);

--
-- Name: beacons_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE beacons_gid_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: beacons_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE beacons_gid_seq OWNED BY beacons.gid;

--
-- Name: parcel_def; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE parcel_def (
  id        INTEGER               NOT NULL,
  beacon    CHARACTER VARYING(20) NOT NULL,
  sequence  INTEGER               NOT NULL,
  parcel_id INTEGER
);

--
-- Name: parcel_lookup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE parcel_lookup (
  plot_sn       CHARACTER VARYING,
  available     BOOLEAN DEFAULT TRUE NOT NULL,
  scheme        INTEGER,
  block         CHARACTER VARYING,
  local_govt    INTEGER,
  prop_type     INTEGER,
  file_number   CHARACTER VARYING,
  allocation    INTEGER,
  manual_no     CHARACTER VARYING,
  deeds_file    CHARACTER VARYING,
  parcel_id     INTEGER              NOT NULL,
  official_area DOUBLE PRECISION,
  private       BOOLEAN DEFAULT FALSE,
  status        INTEGER
);

--
-- Name: COLUMN parcel_lookup.plot_sn; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN parcel_lookup.plot_sn IS 'plot serial no within a block. Forms part of the parcel no';

--
-- Name: beacons_views; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW beacons_views AS
  SELECT DISTINCT ON (b.gid)
    b.gid,
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
-- Name: deeds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE deeds (
  fileno     CHARACTER VARYING(40),
  planno     CHARACTER VARYING(40),
  instrument TEXT,
  grantor    TEXT,
  grantee    TEXT,
  block      CHARACTER VARYING(80),
  plot       CHARACTER VARYING(80),
  location   TEXT,
  deed_sn    INTEGER NOT NULL
);

--
-- Name: schemes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE schemes (
  id          INTEGER               NOT NULL,
  scheme_name CHARACTER VARYING(50) NOT NULL,
  "Scheme"    SMALLINT
);

--
-- Name: COLUMN schemes."Scheme"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN schemes."Scheme" IS 'line';

--
-- Name: parcels; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW parcels AS
  SELECT
    parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom)) :: NUMERIC, 3)) :: DOUBLE PRECISION                    AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/' :: TEXT || (description.deeds_file) :: TEXT) ||
       '" target="blank_">' :: TEXT) || (description.deeds_file) :: TEXT) || '</a>' :: TEXT) AS deeds_file,
    description.private
  FROM ((SELECT
           vl.parcel_id,
           (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(
               st_makeline(vl.the_geom))))) :: GEOMETRY(Polygon, :CRS) AS the_geom
         FROM (SELECT
                 pd.id,
                 pd.parcel_id,
                 pd.beacon,
                 pd.sequence,
                 b.the_geom
               FROM (beacons b
                 JOIN parcel_def pd ON (((b.beacon) :: TEXT = (pd.beacon) :: TEXT)))
               ORDER BY pd.parcel_id, pd.sequence) vl
         GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
    JOIN (SELECT
            p.parcel_id,
            ((p.local_govt || (p.prop_type) :: TEXT) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn                                                AS serial_no,
            p.official_area,
            s.scheme_name                                            AS scheme,
            p.file_number,
            d.grantee                                                AS owner,
            p.deeds_file,
            p.private
          FROM ((parcel_lookup p
            LEFT JOIN deeds d ON (((p.file_number) :: TEXT = (d.fileno) :: TEXT)))
            LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block) :: TEXT <> ALL
                 (ARRAY [('perimeter' :: CHARACTER VARYING) :: TEXT, ('acquisition' :: CHARACTER VARYING) :: TEXT, ('agriculture' :: CHARACTER VARYING) :: TEXT, ('education' :: CHARACTER VARYING) :: TEXT]))) description
    USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom);

--
-- Name: beacons_intersect; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW beacons_intersect AS
  SELECT
    a.beacon,
    a.the_geom,
    a.x,
    a.y,
    b.parcel_id,
    a.private
  FROM (beacons_views a
    LEFT JOIN parcels b ON ((a.parcel_id = b.parcel_id)))
WITH NO DATA;

--
-- Name: beardist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE beardist (
  id          INTEGER               NOT NULL,
  plan_no     CHARACTER VARYING(20) NOT NULL,
  bearing     DOUBLE PRECISION      NOT NULL,
  distance    DOUBLE PRECISION      NOT NULL,
  beacon_from CHARACTER VARYING(20) NOT NULL,
  beacon_to   CHARACTER VARYING(20) NOT NULL
);

--
-- Name: beardist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE beardist_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: beardist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE beardist_id_seq OWNED BY beardist.id;

--
-- Name: bearing_labels; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW bearing_labels AS
  SELECT
    b.id,
    b.geom,
    c.plan_no,
    c.bearing,
    c.distance
  FROM ((SELECT
           a.id,
           st_makeline(a.the_geom) AS geom
         FROM (SELECT
                 bd.id,
                 bd.beacon,
                 bd.orderby,
                 b_1.the_geom
               FROM ((SELECT
                        beardist.id,
                        beardist.beacon_from AS beacon,
                        1                    AS orderby
                      FROM beardist
                      UNION
                      SELECT
                        beardist.id,
                        beardist.beacon_to AS beacon,
                        2                  AS orderby
                      FROM beardist) bd
                 JOIN beacons b_1 USING (beacon))
               ORDER BY bd.orderby) a
         GROUP BY a.id) b
    JOIN beardist c USING (id));

--
-- Name: boundaries; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW boundaries AS
  WITH boundaries AS (
      SELECT
        segments.parcel_id,
        st_makeline(segments.sp, segments.ep) AS geom
      FROM (SELECT
              linestrings.parcel_id,
              st_pointn(linestrings.geom, generate_series(1, (st_npoints(linestrings.geom) - 1))) AS sp,
              st_pointn(linestrings.geom, generate_series(2, st_npoints(linestrings.geom)))       AS ep
            FROM (SELECT
                    parcels.parcel_id,
                    (st_dump(st_boundary(parcels.the_geom))).geom AS geom
                  FROM parcels) linestrings) segments
  )
  SELECT
    row_number()
    OVER ()                                                                                                  AS id,
    boundaries.parcel_id,
    (boundaries.geom) :: GEOMETRY(LineString, :CRS)                                                         AS geom,
    round((st_length(boundaries.geom)) :: NUMERIC,
          2)                                                                                                 AS distance,
    round((degrees(st_azimuth(st_startpoint(boundaries.geom), st_endpoint(boundaries.geom)))) :: NUMERIC, 2) AS bearing
  FROM boundaries
  WHERE st_isvalid(boundaries.geom)
WITH NO DATA;

--
-- Name: boundary_labels; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW boundary_labels AS
  SELECT
    row_number()
    OVER ()                                 AS id,
    b.id                                    AS boundary_id,
    (b.geom) :: GEOMETRY(LineString, :CRS) AS geom,
    c.plan_no,
    c.bearing,
    c.distance,
    p.parcel_id
  FROM (((SELECT
            a.id,
            st_makeline(a.the_geom) AS geom
          FROM (SELECT
                  bd.id,
                  bd.beacon,
                  bd.orderby,
                  b_1.the_geom
                FROM ((SELECT
                         beardist.id,
                         beardist.beacon_from AS beacon,
                         1                    AS orderby
                       FROM beardist
                       UNION
                       SELECT
                         beardist.id,
                         beardist.beacon_to AS beacon,
                         2                  AS orderby
                       FROM beardist) bd
                  JOIN beacons b_1 USING (beacon))
                ORDER BY bd.orderby) a
          GROUP BY a.id) b
    JOIN beardist c USING (id))
    JOIN parcels p ON (st_coveredby(b.geom, p.the_geom)))
WITH NO DATA;

--
-- Name: deeds_deed_sn_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE deeds_deed_sn_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: deeds_deed_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE deeds_deed_sn_seq OWNED BY deeds.deed_sn;

--
-- Name: derived_boundaries; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW derived_boundaries AS
  SELECT
    b.id,
    b.parcel_id,
    b.geom,
    b.distance,
    b.bearing
  FROM boundaries b
  WHERE (NOT (b.id IN (SELECT b_1.id
                       FROM (boundaries b_1
                         JOIN boundary_labels bl ON (st_equals(b_1.geom, bl.geom))))))
WITH NO DATA;

--
-- Name: hist_beacons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE hist_beacons (
  hist_id     BIGINT                                                 NOT NULL,
  gid         INTEGER DEFAULT nextval('beacons_gid_seq' :: REGCLASS) NOT NULL,
  beacon      CHARACTER VARYING(80)                                  NOT NULL,
  y           DOUBLE PRECISION                                       NOT NULL,
  x           DOUBLE PRECISION                                       NOT NULL,
  the_geom    GEOMETRY(Point, :CRS)                                 NOT NULL,
  location    CHARACTER VARYING(180),
  name        CHARACTER VARYING(100),
  hist_user   CHARACTER VARYING,
  hist_action CHARACTER VARYING,
  hist_time   TIMESTAMP WITHOUT TIME ZONE
);

--
-- Name: hist_beacons_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hist_beacons_hist_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: hist_beacons_hist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE hist_beacons_hist_id_seq OWNED BY hist_beacons.hist_id;

--
-- Name: instrument_cat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE instrument_cat (
  instrument_cat INTEGER           NOT NULL,
  description    CHARACTER VARYING NOT NULL
);

--
-- Name: instrument_cat_instrument_cat_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE instrument_cat_instrument_cat_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: instrument_cat_instrument_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE instrument_cat_instrument_cat_seq OWNED BY instrument_cat.instrument_cat;

--
-- Name: local_govt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE local_govt (
  id              INTEGER               NOT NULL,
  local_govt_name CHARACTER VARYING(50) NOT NULL
);

--
-- Name: local_govt_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE local_govt_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: local_govt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE local_govt_id_seq OWNED BY local_govt.id;

--
-- Name: localmotclass_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE localmotclass_code_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: localrdclass_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE localrdclass_code_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: parcel_def_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE parcel_def_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: parcel_def_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE parcel_def_id_seq OWNED BY parcel_def.id;

--
-- Name: parcel_lookup_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE parcel_lookup_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: parcel_lookup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE parcel_lookup_id_seq OWNED BY parcel_lookup.plot_sn;

--
-- Name: parcel_lookup_parcel_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE parcel_lookup_parcel_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: parcel_lookup_parcel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE parcel_lookup_parcel_id_seq OWNED BY parcel_lookup.parcel_id;

--
-- Name: perimeters; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW perimeters AS
  SELECT
    parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom)) :: NUMERIC, 3)) :: DOUBLE PRECISION                    AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/' :: TEXT || (description.deeds_file) :: TEXT) ||
       '" target="blank_">' :: TEXT) || (description.deeds_file) :: TEXT) || '</a>' :: TEXT) AS deeds_file,
    description.private
  FROM ((SELECT
           vl.parcel_id,
           (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(
               st_makeline(vl.the_geom))))) :: GEOMETRY(Polygon, :CRS) AS the_geom
         FROM (SELECT
                 pd.id,
                 pd.parcel_id,
                 pd.beacon,
                 pd.sequence,
                 b.the_geom
               FROM (beacons b
                 JOIN parcel_def pd ON (((b.beacon) :: TEXT = (pd.beacon) :: TEXT)))
               ORDER BY pd.parcel_id, pd.sequence) vl
         GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
    JOIN (SELECT
            p.parcel_id,
            ((p.local_govt || (p.prop_type) :: TEXT) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn                                                AS serial_no,
            p.official_area,
            s.scheme_name                                            AS scheme,
            p.file_number,
            d.grantee                                                AS owner,
            p.deeds_file,
            p.private
          FROM ((parcel_lookup p
            LEFT JOIN deeds d ON (((p.file_number) :: TEXT = (d.fileno) :: TEXT)))
            LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block) :: TEXT = ANY
                 (ARRAY [('perimeter' :: CHARACTER VARYING) :: TEXT, ('acquisition' :: CHARACTER VARYING) :: TEXT, ('agriculture' :: CHARACTER VARYING) :: TEXT, ('education' :: CHARACTER VARYING) :: TEXT]))) description
    USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom);

--
-- Name: parcel_overlap_matviews; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW parcel_overlap_matviews AS
  SELECT DISTINCT ON (a.parcel_id)
    a.parcel_id,
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
  WHERE (st_overlaps(a.the_geom, b.the_geom) = TRUE)
WITH NO DATA;

--
-- Name: parcels_intersect; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW parcels_intersect AS
  SELECT DISTINCT ON (a.parcel_id)
    a.parcel_id,
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
-- Name: parcels_lines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW parcels_lines AS
  WITH toast AS (
      SELECT
        parcels.parcel_id,
        (st_dump(parcels.the_geom)).geom AS the_geom
      FROM parcels
      GROUP BY parcels.parcel_id, parcels.the_geom
  )
  SELECT
    a.parcel_id,
    st_collect(st_exteriorring(a.the_geom)) AS geom
  FROM toast a
  GROUP BY a.parcel_id;

--
-- Name: parcels_line_length; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW parcels_line_length AS
  WITH segments AS (
      SELECT
        dumps.parcel_id,
        row_number()
        OVER ()                                                                     AS id,
        st_makeline(lag((dumps.pt).geom, 1, NULL :: GEOMETRY)
                    OVER (
                      PARTITION BY dumps.parcel_id
                      ORDER BY dumps.parcel_id, (dumps.pt).path ), (dumps.pt).geom) AS geom
      FROM (SELECT
              parcels_lines.parcel_id,
              st_dumppoints(parcels_lines.geom) AS pt
            FROM parcels_lines) dumps
  )
  SELECT
    segments.parcel_id,
    segments.id,
    segments.geom,
    st_length(segments.geom) AS st_length
  FROM segments
  WHERE (segments.geom IS NOT NULL);

--
-- Name: perimeters_original; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW perimeters_original AS
  SELECT
    parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom)) :: NUMERIC, 3)) :: DOUBLE PRECISION                    AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/' :: TEXT || (description.deeds_file) :: TEXT) ||
       '" target="blank_">' :: TEXT) || (description.deeds_file) :: TEXT) || '</a>' :: TEXT) AS deeds_file
  FROM ((SELECT
           vl.parcel_id,
           (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(
               st_makeline(vl.the_geom))))) :: GEOMETRY(Polygon, :CRS) AS the_geom
         FROM (SELECT
                 pd.id,
                 pd.parcel_id,
                 pd.beacon,
                 pd.sequence,
                 b.the_geom
               FROM (beacons b
                 JOIN parcel_def pd ON (((b.beacon) :: TEXT = (pd.beacon) :: TEXT)))
               ORDER BY pd.parcel_id, pd.sequence) vl
         GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
    JOIN (SELECT
            p.parcel_id,
            ((p.local_govt || (p.prop_type) :: TEXT) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn                                                AS serial_no,
            p.official_area,
            s.scheme_name                                            AS scheme,
            p.file_number,
            d.grantee                                                AS owner,
            p.deeds_file
          FROM ((parcel_lookup p
            LEFT JOIN deeds d ON (((p.file_number) :: TEXT = (d.fileno) :: TEXT)))
            LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block) :: TEXT = ANY
                 (ARRAY [('perimeter' :: CHARACTER VARYING) :: TEXT, ('acquisition' :: CHARACTER VARYING) :: TEXT, ('agriculture' :: CHARACTER VARYING) :: TEXT, ('education' :: CHARACTER VARYING) :: TEXT]))) description
    USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom)
  LIMIT 1;

--
-- Name: print_survey_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE print_survey_details (
  id                   INTEGER NOT NULL,
  plan_no              CHARACTER VARYING,
  survey_owner         CHARACTER VARYING,
  area_name            CHARACTER VARYING,
  sheet_no             CHARACTER VARYING,
  survey_type          CHARACTER VARYING,
  survey_authorisation CHARACTER VARYING,
  property_id          INTEGER
);

--
-- Name: print_survey_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE print_survey_details_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: print_survey_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE print_survey_details_id_seq OWNED BY print_survey_details.id;

--
-- Name: prop_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE prop_types (
  id             INTEGER               NOT NULL,
  code           CHARACTER VARYING(2)  NOT NULL,
  prop_type_name CHARACTER VARYING(50) NOT NULL
);

--
-- Name: prop_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE prop_types_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: prop_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE prop_types_id_seq OWNED BY prop_types.id;

--
-- Name: reference_view; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE reference_view (
  id         INTEGER,
  plan_no    CHARACTER VARYING(20),
  ref_beacon CHARACTER VARYING(20),
  scheme     INTEGER,
  parcel_id  INTEGER,
  the_geom   GEOMETRY(Point, :CRS),
  x          DOUBLE PRECISION,
  y          DOUBLE PRECISION
);

--
-- Name: schemes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE schemes_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: schemes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE schemes_id_seq OWNED BY schemes.id;

--
-- Name: speed_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE speed_code_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: status_cat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE status_cat (
  status_cat  INTEGER           NOT NULL,
  description CHARACTER VARYING NOT NULL
);

--
-- Name: status_cat_status_cat_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE status_cat_status_cat_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: status_cat_status_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE status_cat_status_cat_seq OWNED BY status_cat.status_cat;

--
-- Name: str_type_strid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE str_type_strid_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: survey; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE survey (
  id          INTEGER               NOT NULL,
  plan_no     CHARACTER VARYING(20) NOT NULL,
  ref_beacon  CHARACTER VARYING(20) NOT NULL,
  scheme      INTEGER,
  description CHARACTER VARYING(255)
);

--
-- Name: survey_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE survey_id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

--
-- Name: survey_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE survey_id_seq OWNED BY survey.id;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE transactions (
  id               CHARACTER VARYING(10)                     NOT NULL,
  parcel_id        INTEGER                                   NOT NULL,
  capture_officer  INTEGER                                   NOT NULL,
  approval_officer INTEGER,
  date             TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  instrument       INTEGER                                   NOT NULL,
  survey           INTEGER                                   NOT NULL
);

--
-- Name: allocation_cat allocation_cat; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY allocation_cat
  ALTER COLUMN allocation_cat SET DEFAULT nextval('allocation_cat_id_seq' :: REGCLASS);

--
-- Name: beacons gid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beacons
  ALTER COLUMN gid SET DEFAULT nextval('beacons_gid_seq' :: REGCLASS);

--
-- Name: beardist id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beardist
  ALTER COLUMN id SET DEFAULT nextval('beardist_id_seq' :: REGCLASS);

--
-- Name: deeds deed_sn; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deeds
  ALTER COLUMN deed_sn SET DEFAULT nextval('deeds_deed_sn_seq' :: REGCLASS);

--
-- Name: hist_beacons hist_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hist_beacons
  ALTER COLUMN hist_id SET DEFAULT nextval('hist_beacons_hist_id_seq' :: REGCLASS);

--
-- Name: instrument_cat instrument_cat; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instrument_cat
  ALTER COLUMN instrument_cat SET DEFAULT nextval('instrument_cat_instrument_cat_seq' :: REGCLASS);

--
-- Name: local_govt id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY local_govt
  ALTER COLUMN id SET DEFAULT nextval('local_govt_id_seq' :: REGCLASS);

--
-- Name: parcel_def id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_def
  ALTER COLUMN id SET DEFAULT nextval('parcel_def_id_seq' :: REGCLASS);

--
-- Name: parcel_lookup parcel_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_lookup
  ALTER COLUMN parcel_id SET DEFAULT nextval('parcel_lookup_parcel_id_seq' :: REGCLASS);

--
-- Name: print_survey_details id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY print_survey_details
  ALTER COLUMN id SET DEFAULT nextval('print_survey_details_id_seq' :: REGCLASS);

--
-- Name: prop_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prop_types
  ALTER COLUMN id SET DEFAULT nextval('prop_types_id_seq' :: REGCLASS);

--
-- Name: schemes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY schemes
  ALTER COLUMN id SET DEFAULT nextval('schemes_id_seq' :: REGCLASS);

--
-- Name: status_cat status_cat; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY status_cat
  ALTER COLUMN status_cat SET DEFAULT nextval('status_cat_status_cat_seq' :: REGCLASS);

--
-- Name: survey id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY survey
  ALTER COLUMN id SET DEFAULT nextval('survey_id_seq' :: REGCLASS);

--
-- Name: allocation_cat allocation_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY allocation_cat
  ADD CONSTRAINT allocation_cat_pkey PRIMARY KEY (allocation_cat);

--
-- Name: beacons beacons_beacon_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beacons
  ADD CONSTRAINT beacons_beacon_key UNIQUE (beacon);

--
-- Name: beacons beacons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beacons
  ADD CONSTRAINT beacons_pkey PRIMARY KEY (gid);

--
-- Name: beardist beardist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beardist
  ADD CONSTRAINT beardist_pkey PRIMARY KEY (id);

--
-- Name: deeds dkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deeds
  ADD CONSTRAINT dkey PRIMARY KEY (deed_sn);

--
-- Name: hist_beacons hist_beacons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hist_beacons
  ADD CONSTRAINT hist_beacons_pkey PRIMARY KEY (hist_id);

--
-- Name: instrument_cat instrument_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instrument_cat
  ADD CONSTRAINT instrument_cat_pkey PRIMARY KEY (instrument_cat);

--
-- Name: local_govt local_govt_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY local_govt
  ADD CONSTRAINT local_govt_id_key UNIQUE (local_govt_name);

--
-- Name: local_govt local_govt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY local_govt
  ADD CONSTRAINT local_govt_pkey PRIMARY KEY (id);

--
-- Name: parcel_def parcel_def_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_def
  ADD CONSTRAINT parcel_def_pkey PRIMARY KEY (id);

--
-- Name: parcel_lookup parcel_lookup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_lookup
  ADD CONSTRAINT parcel_lookup_pkey PRIMARY KEY (parcel_id);

--
-- Name: print_survey_details print_survey_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY print_survey_details
  ADD CONSTRAINT print_survey_details_pkey PRIMARY KEY (id);

--
-- Name: prop_types prop_type_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prop_types
  ADD CONSTRAINT prop_type_code_key UNIQUE (code);

--
-- Name: prop_types prop_type_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prop_types
  ADD CONSTRAINT prop_type_id_key UNIQUE (prop_type_name);

--
-- Name: prop_types prop_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prop_types
  ADD CONSTRAINT prop_type_pkey PRIMARY KEY (id);

--
-- Name: schemes schemes_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY schemes
  ADD CONSTRAINT schemes_id_key UNIQUE (scheme_name);

--
-- Name: schemes schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY schemes
  ADD CONSTRAINT schemes_pkey PRIMARY KEY (id);

--
-- Name: status_cat status_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY status_cat
  ADD CONSTRAINT status_cat_pkey PRIMARY KEY (status_cat);

--
-- Name: survey survey_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY survey
  ADD CONSTRAINT survey_pkey PRIMARY KEY (id);

--
-- Name: survey survey_plan_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY survey
  ADD CONSTRAINT survey_plan_no_key UNIQUE (plan_no);

--
-- Name: survey survey_plan_no_key1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY survey
  ADD CONSTRAINT survey_plan_no_key1 UNIQUE (plan_no);

--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
  ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);

--
-- Name: beacons_beacon_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX beacons_beacon_idx
  ON beacons USING BTREE (beacon);

--
-- Name: beardist_beacon_from_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX beardist_beacon_from_idx
  ON beardist USING BTREE (beacon_from);

--
-- Name: beardist_beacon_to_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX beardist_beacon_to_idx
  ON beardist USING BTREE (beacon_to);

--
-- Name: beardist_ndx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX beardist_ndx1
  ON beardist USING BTREE (beacon_from);

--
-- Name: beardist_plan_no_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX beardist_plan_no_idx
  ON beardist USING BTREE (plan_no);

--
-- Name: fki_parcel_lookup_status_cat_fkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_parcel_lookup_status_cat_fkey
  ON parcel_lookup USING BTREE (status);

--
-- Name: fki_transactions_instrument_fkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_transactions_instrument_fkey
  ON transactions USING BTREE (instrument);

--
-- Name: fki_transactions_parcel_fkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_transactions_parcel_fkey
  ON transactions USING BTREE (parcel_id);

--
-- Name: fki_transactions_survey_fkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_transactions_survey_fkey
  ON transactions USING BTREE (survey);

--
-- Name: hist_beacons_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hist_beacons_idx1
  ON hist_beacons USING BTREE (gid);

--
-- Name: hist_beacons_idx2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hist_beacons_idx2
  ON hist_beacons USING BTREE (hist_time);

--
-- Name: idp_beacons_intersect; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idp_beacons_intersect
  ON beacons_intersect USING BTREE (beacon);

--
-- Name: idp_beacons_mtview; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idp_beacons_mtview
  ON beacons_views USING BTREE (gid);

--
-- Name: idp_parcel_overlap_matviews; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idp_parcel_overlap_matviews
  ON parcel_overlap_matviews USING BTREE (parcel_id);

--
-- Name: idp_parcels_intersect; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idp_parcels_intersect
  ON parcels_intersect USING BTREE (parcel_id);

--
-- Name: idx_beacons_intersect_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_beacons_intersect_geom
  ON beacons_intersect USING GIST (the_geom);

--
-- Name: idx_beacons_matviews_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_beacons_matviews_geom
  ON beacons_views USING GIST (the_geom);

--
-- Name: idx_boundaries_labels_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_boundaries_labels_geom
  ON boundaries USING BTREE (id);
CREATE INDEX idy_boundaries_labels_mtview
  ON public.boundary_labels USING GIST (geom);
CREATE INDEX idy_derived_boundaries_labels_geom
  ON public.derived_boundaries USING GIST (geom);

CREATE INDEX idy_boundaries_labels_geom
  ON public.boundaries USING GIST (geom);

--
-- Name: idx_boundary_labels_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_boundary_labels_geom
  ON boundary_labels USING BTREE (id);

--
-- Name: idx_derived_boundaries_labels_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_derived_boundaries_labels_geom
  ON derived_boundaries USING BTREE (id);

--
-- Name: idx_parcels_intersects_new_matviews_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parcels_intersects_new_matviews_geom
  ON parcels_intersect USING GIST (the_geom);

--
-- Name: ndx_schemes1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ndx_schemes1
  ON schemes USING GIN (to_tsvector('english' :: REGCONFIG, (COALESCE(scheme_name, '' :: CHARACTER VARYING)) :: TEXT));

--
-- Name: parcel_over_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX parcel_over_idx
  ON parcel_overlap_matviews USING GIST (the_geom);

--
-- Name: sidx_beacons_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sidx_beacons_geom
  ON beacons USING GIST (the_geom);

--
-- Name: beacons insert_nodes_geom; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER insert_nodes_geom
BEFORE INSERT OR UPDATE ON beacons
FOR EACH ROW EXECUTE PROCEDURE calc_point();

--
-- Name: parcel_def parcel_lookup_define_parcel; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER parcel_lookup_define_parcel
BEFORE INSERT OR UPDATE ON parcel_def
FOR EACH ROW EXECUTE PROCEDURE parcel_lookup_define_parcel_trigger();

--
-- Name: beacons trg_beacons_after_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_beacons_after_insert
AFTER INSERT ON beacons
FOR EACH ROW EXECUTE PROCEDURE fn_beacons_after_insert();

--
-- Name: beacons trg_beacons_before_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_beacons_before_delete
BEFORE DELETE ON beacons
FOR EACH ROW EXECUTE PROCEDURE fn_beacons_before_delete();

--
-- Name: beacons trg_beacons_before_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_beacons_before_update
BEFORE UPDATE ON beacons
FOR EACH ROW EXECUTE PROCEDURE fn_beacons_before_update();

--
-- Name: beardist beardist_beacon_from_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beardist
  ADD CONSTRAINT beardist_beacon_from_fkey FOREIGN KEY (beacon_from) REFERENCES beacons (beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: beardist beardist_beacon_from_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beardist
  ADD CONSTRAINT beardist_beacon_from_fkey1 FOREIGN KEY (beacon_from) REFERENCES beacons (beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: beardist beardist_beacon_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beardist
  ADD CONSTRAINT beardist_beacon_to_fkey FOREIGN KEY (beacon_to) REFERENCES beacons (beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: beardist beardist_beacon_to_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beardist
  ADD CONSTRAINT beardist_beacon_to_fkey1 FOREIGN KEY (beacon_to) REFERENCES beacons (beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: beardist beardist_plan_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beardist
  ADD CONSTRAINT beardist_plan_no_fkey FOREIGN KEY (plan_no) REFERENCES survey (plan_no) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: beardist beardist_plan_no_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY beardist
  ADD CONSTRAINT beardist_plan_no_fkey1 FOREIGN KEY (plan_no) REFERENCES survey (plan_no) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: parcel_def parcel_def_beacon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_def
  ADD CONSTRAINT parcel_def_beacon_fkey FOREIGN KEY (beacon) REFERENCES beacons (beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: parcel_def parcel_def_parcel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_def
  ADD CONSTRAINT parcel_def_parcel_id_fkey FOREIGN KEY (parcel_id) REFERENCES parcel_lookup (parcel_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: parcel_lookup parcel_lookup_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_lookup
  ADD CONSTRAINT parcel_lookup_allocation_id_fkey FOREIGN KEY (allocation) REFERENCES allocation_cat (allocation_cat) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: parcel_lookup parcel_lookup_local_govt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_lookup
  ADD CONSTRAINT parcel_lookup_local_govt_id_fkey FOREIGN KEY (local_govt) REFERENCES local_govt (id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: parcel_lookup parcel_lookup_prop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_lookup
  ADD CONSTRAINT parcel_lookup_prop_type_id_fkey FOREIGN KEY (prop_type) REFERENCES prop_types (id) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: parcel_lookup parcel_lookup_scheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_lookup
  ADD CONSTRAINT parcel_lookup_scheme_id_fkey FOREIGN KEY (scheme) REFERENCES schemes (id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: parcel_lookup parcel_lookup_status_cat_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parcel_lookup
  ADD CONSTRAINT parcel_lookup_status_cat_fkey FOREIGN KEY (status) REFERENCES status_cat (status_cat);

--
-- Name: survey survey_ref_beacon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY survey
  ADD CONSTRAINT survey_ref_beacon_fkey FOREIGN KEY (ref_beacon) REFERENCES beacons (beacon);

--
-- Name: survey survey_scheme_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY survey
  ADD CONSTRAINT survey_scheme_fkey FOREIGN KEY (scheme) REFERENCES schemes (id);

--
-- Name: transactions transactions_instrument_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
  ADD CONSTRAINT transactions_instrument_fkey FOREIGN KEY (instrument) REFERENCES instrument_cat (instrument_cat);

--
-- Name: transactions transactions_parcel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
  ADD CONSTRAINT transactions_parcel_fkey FOREIGN KEY (parcel_id) REFERENCES parcel_lookup (parcel_id);

--
-- Name: transactions transactions_survey_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
  ADD CONSTRAINT transactions_survey_fkey FOREIGN KEY (survey) REFERENCES survey (id);

CREATE VIEW boundary_labels_degrees as 
select a.id,a.parcel_id,a.boundary_id,a.bearing,a.distance,st_line_interpolate_point(a.geom,0.9) as geom 
from boundary_labels as a;

CREATE VIEW boundary_labels_minutes as 
select a.id,a.parcel_id,a.boundary_id,a.bearing,a.distance,st_line_interpolate_point(a.geom,0.1) as geom 
from boundary_labels as a;


CREATE VIEW derived_boundaries_degrees as
select a.parcel_id,a.id,a.distance,a.bearing,st_line_interpolate_point(a.geom,0.9) as geom from derived_boundaries as a;


CREATE VIEW derived_boundaries_minutes as
select a.parcel_id,a.id,a.distance,a.bearing,st_line_interpolate_point(a.geom,0.1) as geom from derived_boundaries as a;

--
-- Name: Refresh all materialized views
--

SELECT refreshallmaterializedviews();


CREATE OR REPLACE FUNCTION beacons_views_mat_view()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY beacons_views;
  RETURN NULL;
END $$;

CREATE TRIGGER beacons_views_ref_row
  AFTER INSERT OR UPDATE OR DELETE
  ON public.parcel_def
  FOR EACH STATEMENT
  EXECUTE PROCEDURE public.beacons_views_mat_view();

-- second trigger
CREATE OR REPLACE FUNCTION intersect_beacons_views()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY beacons_intersect;
  RETURN NULL;
END $$;

CREATE TRIGGER intersect_beacons_ref_row
  AFTER INSERT OR UPDATE OR DELETE
  ON public.parcel_def
  FOR EACH STATEMENT
  EXECUTE PROCEDURE public.intersect_beacons_views();

-- third trigger

CREATE OR REPLACE FUNCTION boundaries_views()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY boundaries;
  RETURN NULL;
END $$;

CREATE TRIGGER boundaries_ref_row
  AFTER INSERT OR UPDATE OR DELETE
  ON public.parcel_def
  FOR EACH STATEMENT
  EXECUTE PROCEDURE public.boundaries_views();

-- fourth
CREATE OR REPLACE FUNCTION labels_boundaries_views()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY boundary_labels;
  RETURN NULL;
END $$;

CREATE TRIGGER labels_boundaries_ref_row
  AFTER INSERT OR UPDATE OR DELETE
  ON public.parcel_def
  FOR EACH STATEMENT
  EXECUTE PROCEDURE public.labels_boundaries_views();

-- fifth
CREATE OR REPLACE FUNCTION modified_derived_boundaries()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY derived_boundaries;
  RETURN NULL;
END $$;

CREATE TRIGGER modified_derived_boundaries_ref_row
  AFTER INSERT OR UPDATE OR DELETE
  ON public.parcel_def
  FOR EACH STATEMENT
  EXECUTE PROCEDURE public.modified_derived_boundaries();


-- fifth
CREATE OR REPLACE FUNCTION parcels_intersect_views()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY parcels_intersect;
  RETURN NULL;
END $$;

CREATE TRIGGER parcels_intersect_views_ref_row
  AFTER INSERT OR UPDATE OR DELETE
  ON public.parcel_def
  FOR EACH STATEMENT
  EXECUTE PROCEDURE public.parcels_intersect_views();

--last one
CREATE OR REPLACE FUNCTION result_parcels_intersect_views()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY parcel_overlap_matviews;
  RETURN NULL;
END $$;

CREATE TRIGGER result_parcels_intersect_views_ref_row
  AFTER INSERT OR UPDATE OR DELETE
  ON public.parcel_def
  FOR EACH STATEMENT
  EXECUTE PROCEDURE public.result_parcels_intersect_views();
--
-- PostgreSQL database dump complete
--
