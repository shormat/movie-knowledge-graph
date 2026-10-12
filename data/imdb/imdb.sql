SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE `title` (
    title_id varchar(50) PRIMARY KEY,
    title_type varchar(50),
    primary_title varchar(50),
    original_title varchar(50),
    start_year SMALLINT,
    end_year SMALLINT,
    is_adult BOOLEAN,
    runtime_minutes SMALLINT UNSIGNED,
    avg_rating DECIMAL(3,2), /* 3 digits with 2 decimal places.*/
    num_votes int UNSIGNED
);

CREATE TABLE `genre` (
    title_id varchar(50),
    genre_name varchar(30),
    FOREIGN KEY (`title_id`) REFERENCES `title`(`title_id`) ON DELETE CASCADE
);

CREATE TABLE `localized_title` (
    title_id varchar(50),
    title varchar(50),
    region varchar(50),
    language varchar(50),
    PRIMARY KEY (`title_id`, `title`),
    FOREIGN KEY (`title_id`) REFERENCES `title`(`title_id`) ON DELETE CASCADE
);

CREATE TABLE `episode` (
    title_id varchar(50) PRIMARY KEY,
    series_title_id varchar(50),
    episode_number int,
    season_number int,
    FOREIGN KEY (`title_id`) REFERENCES `title`(`title_id`) ON DELETE CASCADE,
    FOREIGN KEY (`series_title_id`) REFERENCES `title`(`title_id`) ON DELETE CASCADE
);

CREATE TABLE `person`(
    n_const varchar(50) PRIMARY KEY,
    birthYear SMALLINT,
    deathYear SMALLINT,
    primaryName varchar(50)
);

CREATE TABLE `directed`(
    title_id varchar(50),
    n_const varchar(50),
    PRIMARY KEY (`title_id`, `n_const`),
    FOREIGN KEY (`title_id`) REFERENCES `title`(`title_id`) ON DELETE CASCADE,
    FOREIGN KEY (`n_const`) REFERENCES `person`(`n_const`) ON DELETE CASCADE
);

CREATE TABLE `wrote`(
    title_id varchar(50),
    n_const varchar(50),
    PRIMARY KEY (`title_id`, `n_const`),
    FOREIGN KEY (`title_id`) REFERENCES `title`(`title_id`) ON DELETE CASCADE,
    FOREIGN KEY (`n_const`) REFERENCES `person`(`n_const`) ON DELETE CASCADE
);

CREATE TABLE `known_for`(
    title_id varchar(50),
    n_const varchar(50),
    PRIMARY KEY (`title_id`, `n_const`),
    FOREIGN KEY (`title_id`) REFERENCES `title`(`title_id`) ON DELETE CASCADE,
    FOREIGN KEY (`n_const`) REFERENCES `person`(`n_const`) ON DELETE CASCADE
);


CREATE TABLE `worked`(
    n_const varchar(50),
    profession_name varchar(50),
    FOREIGN KEY (`n_const`) REFERENCES `person`(`n_const`) ON DELETE CASCADE
);

CREATE TABLE `principal`(
    title_id varchar(50),
    n_const varchar(50),
    category varchar(50),
    ordering int,
    character_name varchar(50),
    PRIMARY KEY (`title_id`, `ordering`),	
    FOREIGN KEY (`n_const`) REFERENCES `person`(`n_const`) ON DELETE CASCADE,
    FOREIGN KEY (`title_id`) REFERENCES `title`(`title_id`) ON DELETE CASCADE
);

CREATE table title_ratings_store (
    title_id VARCHAR(50),
    avg_rating DECIMAL(3,2),
    num_votes INT
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/title.ratings.tsv'
INTO TABLE title_ratings_store
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title_id, avg_rating, num_votes);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/title.basics.tsv' 
INTO TABLE `title` 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS 
(title_id, title_type, primary_title, original_title, is_adult, @start_year, @end_year, runtime_minutes, @genres)
SET start_year = NULLIF(@start_year, '\\N'), end_year = NULLIF(@end_year, '\\N');

INSERT IGNORE INTO title (title_id, avg_rating, num_votes)
SELECT title_id, avg_rating, num_votes
FROM title_ratings_store
ON DUPLICATE KEY UPDATE
    avg_rating = VALUES(avg_rating),
    num_votes = VALUES(num_votes);
DROP TABLE title_ratings_store;

CREATE TABLE title_genre_store (
    title_id VARCHAR(50),
    genres VARCHAR(255)
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/title.basics.tsv'
INTO TABLE title_genre_store
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@tconst, @titleType, @primaryTitle, @originalTitle, @isAdult, @startYear, @endYear, @runtimeMinutes, @genres)
SET title_id = @tconst, genres = @genres;

-- Create a temporary table for split genres
CREATE TEMPORARY TABLE temp_genre_split (
    title_id VARCHAR(50),
    genre_name VARCHAR(30)
);

-- Insert split genres into temporary table
INSERT INTO temp_genre_split (title_id, genre_name)
SELECT title_id, genre_name
FROM (
    WITH RECURSIVE genre_split AS (
        SELECT 
            title_id,
            SUBSTRING_INDEX(genres, ',', 1) AS genre_name,
            SUBSTRING(genres, LENGTH(SUBSTRING_INDEX(genres, ',', 1)) + 2) AS remaining_genres
        FROM title_genre_store
        WHERE genres IS NOT NULL AND genres != '\\N'

        UNION ALL

        SELECT 
            title_id,
            SUBSTRING_INDEX(remaining_genres, ',', 1),
            SUBSTRING(remaining_genres, LENGTH(SUBSTRING_INDEX(remaining_genres, ',', 1)) + 2)
        FROM genre_split
        WHERE remaining_genres <> '' 
    )
    SELECT title_id, genre_name FROM genre_split
) AS genre_split;

-- Insert only valid foreign keys into genre table
INSERT IGNORE INTO genre (title_id, genre_name)
SELECT tgs.title_id, tgs.genre_name
FROM temp_genre_split tgs
JOIN title t ON tgs.title_id = t.title_id;

DROP TABLE title_genre_store;
DROP TEMPORARY TABLE temp_genre_split;

-- Create temporary table for akas
CREATE TABLE temp_localized_title (
    title_id VARCHAR(50),
    title VARCHAR(50),
    region VARCHAR(50),
    language VARCHAR(50)
);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/title.akas.tsv'
INTO TABLE temp_localized_title
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title_id, title, region, language);

-- Insert only entries with valid title_id
INSERT IGNORE INTO localized_title (title_id, title, region, language)
SELECT tlt.title_id, tlt.title, tlt.region, tlt.language
FROM temp_localized_title tlt
JOIN title t ON tlt.title_id = t.title_id;

DROP TABLE temp_localized_title;

-- Create temporary table for episodes
CREATE TABLE temp_episode (
    title_id VARCHAR(50),
    series_title_id VARCHAR(50),
    season_number INT,
    episode_number INT
);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/title.episode.tsv'
INTO TABLE temp_episode
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title_id, series_title_id, season_number, episode_number);

-- Insert only episodes where both title_id and series_title_id exist
INSERT IGNORE INTO episode (title_id, series_title_id, season_number, episode_number)
SELECT te.title_id, te.series_title_id, te.season_number, te.episode_number
FROM temp_episode te
JOIN title t1 ON te.title_id = t1.title_id
JOIN title t2 ON te.series_title_id = t2.title_id;

DROP TABLE temp_episode;

-- Load person data
LOAD DATA INFILE '/docker-entrypoint-initdb.d/name.basics.tsv'
INTO TABLE person
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(n_const, primaryName, birthYear, deathYear)
SET birthYear = NULLIF(birthYear, '\\N'), deathYear = NULLIF(deathYear, '\\N');

CREATE TABLE title_director_store (
    title_id VARCHAR(50),
    directors VARCHAR(255)
);
CREATE TABLE title_writer_store (
    title_id VARCHAR(50),
    writers VARCHAR(255)
);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/title.crew.tsv'
INTO TABLE title_director_store
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title_id, directors)
SET directors = NULLIF(directors, '\\N');

LOAD DATA INFILE '/docker-entrypoint-initdb.d/title.crew.tsv'
INTO TABLE title_writer_store
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title_id, @dummy, writers)
SET writers = NULLIF(writers, '\\N');

-- Create temporary table for split directors
CREATE TEMPORARY TABLE temp_director_split (
    title_id VARCHAR(50),
    n_const VARCHAR(50)
);

-- Split directors into temporary table
INSERT INTO temp_director_split (title_id, n_const)
SELECT title_id, n_const
FROM (
    WITH RECURSIVE director_split AS (
        SELECT 
            title_id,
            SUBSTRING_INDEX(directors, ',', 1) AS n_const,
            SUBSTRING(directors, LENGTH(SUBSTRING_INDEX(directors, ',', 1)) + 2) AS remaining_directors
        FROM title_director_store
        WHERE directors IS NOT NULL

        UNION ALL

        SELECT 
            title_id,
            SUBSTRING_INDEX(remaining_directors, ',', 1),
            SUBSTRING(remaining_directors, LENGTH(SUBSTRING_INDEX(remaining_directors, ',', 1)) + 2)
        FROM director_split
        WHERE remaining_directors <> '' 
    )
    SELECT title_id, n_const FROM director_split
    WHERE n_const IS NOT NULL
) AS director_split;

-- Insert only valid foreign keys into directed
INSERT IGNORE INTO directed (title_id, n_const)
SELECT tds.title_id, tds.n_const
FROM temp_director_split tds
JOIN title t ON tds.title_id = t.title_id
JOIN person p ON tds.n_const = p.n_const;

DROP TEMPORARY TABLE temp_director_split;

-- Create temporary table for split writers
CREATE TEMPORARY TABLE temp_writer_split (
    title_id VARCHAR(50),
    n_const VARCHAR(50)
);

-- Split writers into temporary table
INSERT INTO temp_writer_split (title_id, n_const)
SELECT title_id, n_const
FROM (
    WITH RECURSIVE writer_split AS (
        SELECT 
            title_id,
            SUBSTRING_INDEX(writers, ',', 1) AS n_const,
            SUBSTRING(writers, LENGTH(SUBSTRING_INDEX(writers, ',', 1)) + 2) AS remaining_writers
        FROM title_writer_store
        WHERE writers IS NOT NULL

        UNION ALL

        SELECT 
            title_id,
            SUBSTRING_INDEX(remaining_writers, ',', 1),
            SUBSTRING(remaining_writers, LENGTH(SUBSTRING_INDEX(remaining_writers, ',', 1)) + 2)
        FROM writer_split
        WHERE remaining_writers <> '' 
    )
    SELECT title_id, n_const FROM writer_split
    WHERE n_const IS NOT NULL
) AS writer_split;

-- Insert only valid foreign keys into wrote
INSERT IGNORE INTO wrote (title_id, n_const)
SELECT tws.title_id, tws.n_const
FROM temp_writer_split tws
JOIN title t ON tws.title_id = t.title_id
JOIN person p ON tws.n_const = p.n_const;

DROP TABLE title_director_store;
DROP TABLE title_writer_store;
DROP TEMPORARY TABLE temp_writer_split;

CREATE TABLE known_for_store (
    n_const VARCHAR(50),
    known_for VARCHAR(255)
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/name.basics.tsv'
INTO TABLE known_for_store
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(n_const, @dummy, @dummy, @dummy, @dummy, known_for);

-- Create temporary table for known_for split
CREATE TEMPORARY TABLE temp_known_for_split (
    title_id VARCHAR(50),
    n_const VARCHAR(50)
);

-- Split known_for into temporary table
INSERT INTO temp_known_for_split (title_id, n_const)
SELECT title_id, n_const
FROM (
    WITH RECURSIVE known_for_split AS (
        SELECT 
            n_const,
            SUBSTRING_INDEX(known_for, ',', 1) AS title_id,
            SUBSTRING(known_for, LENGTH(SUBSTRING_INDEX(known_for, ',', 1)) + 2) AS remaining_titles
        FROM known_for_store
        WHERE known_for IS NOT NULL AND known_for != '\\N'

        UNION ALL

        SELECT 
            n_const,
            SUBSTRING_INDEX(remaining_titles, ',', 1),
            SUBSTRING(remaining_titles, LENGTH(SUBSTRING_INDEX(remaining_titles, ',', 1)) + 2)
        FROM known_for_split
        WHERE remaining_titles <> '' 
    )
    SELECT title_id, n_const FROM known_for_split
    WHERE title_id IS NOT NULL
) AS known_for_split;

-- Insert only valid foreign keys into known_for
INSERT IGNORE INTO known_for (title_id, n_const)
SELECT kfs.title_id, kfs.n_const
FROM temp_known_for_split kfs
JOIN title t ON kfs.title_id = t.title_id
JOIN person p ON kfs.n_const = p.n_const;

DROP TABLE known_for_store;
DROP TEMPORARY TABLE temp_known_for_split;

CREATE TABLE profession_store (
    n_const VARCHAR(50),
    professions VARCHAR(255)
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/name.basics.tsv'
INTO TABLE profession_store
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(n_const, @dummy, @dummy, @dummy, professions);

-- Create temporary table for profession split
CREATE TEMPORARY TABLE temp_profession_split (
    n_const VARCHAR(50),
    profession_name VARCHAR(50)
);

-- Split professions into temporary table
INSERT INTO temp_profession_split (n_const, profession_name)
SELECT n_const, profession_name
FROM (
    WITH RECURSIVE profession_split AS (
        SELECT 
            n_const,
            SUBSTRING_INDEX(professions, ',', 1) AS profession_name,
            SUBSTRING(professions, LENGTH(SUBSTRING_INDEX(professions, ',', 1)) + 2) AS remaining_professions
        FROM profession_store
        WHERE professions IS NOT NULL AND professions != '\\N'

        UNION ALL

        SELECT 
            n_const,
            SUBSTRING_INDEX(remaining_professions, ',', 1),
            SUBSTRING(remaining_professions, LENGTH(SUBSTRING_INDEX(remaining_professions, ',', 1)) + 2)
        FROM profession_split
        WHERE remaining_professions <> '' 
    )
    SELECT n_const, profession_name FROM profession_split
) AS profession_split;

-- Insert only valid foreign keys into worked
INSERT IGNORE INTO worked (n_const, profession_name)
SELECT tps.n_const, tps.profession_name
FROM temp_profession_split tps
JOIN person p ON tps.n_const = p.n_const;

DROP TABLE profession_store;
DROP TEMPORARY TABLE temp_profession_split;

-- Create temporary table for principal data
CREATE TABLE temp_principal (
    title_id VARCHAR(50),
    ordering INT,
    n_const VARCHAR(50),
    category VARCHAR(50),
    character_name VARCHAR(50)
);

-- Load principal data into temporary table
LOAD DATA INFILE '/docker-entrypoint-initdb.d/title.principals.tsv'
INTO TABLE temp_principal
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(title_id, ordering, n_const, category, @dummy, character_name)
SET character_name = NULLIF(character_name, '\\N');

-- Insert only valid foreign keys into principal
INSERT IGNORE INTO principal (title_id, n_const, category, ordering, character_name)
SELECT tp.title_id, tp.n_const, tp.category, tp.ordering, tp.character_name
FROM temp_principal tp
JOIN title t ON tp.title_id = t.title_id
JOIN person p ON tp.n_const = p.n_const;

DROP TABLE temp_principal;

COMMIT;