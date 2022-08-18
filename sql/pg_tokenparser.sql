CREATE EXTENSION pg_tokenparser;

SELECT alias, description, token FROM ts_debug('my_cfg', 'token_01 tagset-02 tagset03 token:04');

SELECT to_tsvector('my_cfg', 'token_01 tagset-02 tagset03 token:04');

DROP EXTENSION pg_tokenparser;