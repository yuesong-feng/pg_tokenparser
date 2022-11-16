/* contrib/pg_tokenparser/pg_tokenparser--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_tokenparser" to load this file. \quit

CREATE OR REPLACE FUNCTION parse_start(internal,int4)
RETURNS internal
AS 'MODULE_PATHNAME', 'parse_start'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION parse_gettoken(internal,internal,internal)
RETURNS internal 
AS 'MODULE_PATHNAME', 'parse_gettoken'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION parse_end(internal)
RETURNS void
AS 'MODULE_PATHNAME', 'parse_end'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION parse_tokentype(internal)
RETURNS internal
AS 'MODULE_PATHNAME', 'parse_tokentype'
LANGUAGE C STRICT;

CREATE TEXT SEARCH PARSER tokenparser(
    START = parse_start,
    GETTOKEN = parse_gettoken,
    END = parse_end,
    LEXTYPES = parse_tokentype
);

CREATE TEXT SEARCH CONFIGURATION my_parser (
    PARSER = tokenparser
);

ALTER TEXT SEARCH CONFIGURATION my_parser ADD MAPPING FOR word WITH english_stem; 
