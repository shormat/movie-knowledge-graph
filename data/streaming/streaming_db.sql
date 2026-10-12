SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

CREATE TABLE `person` (
  `id` int AUTO_INCREMENT PRIMARY KEY,
  `name` varchar(50) NOT NULL
);
CREATE TABLE `title` (
  `show_id` varchar(15) NOT NULL,
  `description` TEXT,
  `type` varchar(10),
  `director_id` int,
  `country` varchar(50),
  `date_added` date,
  `release_year` YEAR,
  `tv_rating` varchar(20),
  `title` varchar(50),
  `streaming_service` varchar(20),
  `duration` varchar(20),
  `nb_seasons` int,
  PRIMARY KEY (`show_id`, `streaming_service`),
  FOREIGN KEY (`director_id`) REFERENCES `person`(`id`) ON DELETE SET NULL
);
CREATE TABLE `played_in` (
  `show_id` varchar(15) NOT NULL,
  `person_id` int NOT NULL,
  PRIMARY KEY (`show_id`, `person_id`),
  FOREIGN KEY (`show_id`) REFERENCES `title`(`show_id`) ON DELETE CASCADE,
  FOREIGN KEY (`person_id`) REFERENCES `person`(`id`) ON DELETE CASCADE
);

CREATE TABLE `tmp_cast` (
  `show_id` varchar(15) NOT NULL PRIMARY KEY,
  `cast_name` varchar(255) NOT NULL
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/amazon_prime_titles.csv'
INTO TABLE tmp_cast
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id, @dummy, @dummy, @dummy, cast_name);

INSERT INTO person (name)
SELECT DISTINCT cast_name
FROM (
  WITH RECURSIVE cast_split AS(
    SELECT 
      SUBSTRING_INDEX(cast_name, ',', 1) AS cast_name,
      SUBSTRING(cast_name, LENGTH(SUBSTRING_INDEX(cast_name, ',', 1)) + 2) AS remaining_cast
    FROM tmp_cast
    WHERE cast_name IS NOT NULL

    UNION ALL

    SELECT 
      SUBSTRING_INDEX(remaining_cast, ',', 1) AS cast_name,
      SUBSTRING(remaining_cast, LENGTH(SUBSTRING_INDEX(remaining_cast, ',', 1)) + 2) AS remaining_cast
    FROM cast_split
    WHERE remaining_cast <> ''
  )
  SELECT cast_name FROM cast_split
) AS tmp
WHERE cast_name IS NOT NULL;

LOAD DATA INFILE '/docker-entrypoint-initdb.d/amazon_prime_titles.csv' 
INTO TABLE title 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(show_id, type, title, @director, @dummy, country, date_added, release_year, tv_rating, @duration, @dummy, description)
SET 
  duration = CASE 
    WHEN @duration LIKE '% min' THEN @duration 
    ELSE NULL 
  END,
  nb_seasons = CASE 
    WHEN @duration NOT LIKE '% min' THEN CAST(@duration AS UNSIGNED) 
    ELSE NULL 
  END,
  streaming_service = 'Amazon Prime',
  director_id = (SELECT id FROM person WHERE name = @director LIMIT 1);

INSERT IGNORE INTO played_in (show_id, person_id)
SELECT DISTINCT show_id, person.id
FROM (
  WITH RECURSIVE cast_split AS(
    SELECT 
      show_id,
      SUBSTRING_INDEX(cast_name, ',', 1) AS cast_name,
      SUBSTRING(cast_name, LENGTH(SUBSTRING_INDEX(cast_name, ',', 1)) + 2) AS remaining_cast
    FROM tmp_cast
    WHERE cast_name IS NOT NULL

    UNION ALL

    SELECT 
      show_id,
      SUBSTRING_INDEX(remaining_cast, ',', 1) AS cast_name,
      SUBSTRING(remaining_cast, LENGTH(SUBSTRING_INDEX(remaining_cast, ',', 1)) + 2) AS remaining_cast
    FROM cast_split
    WHERE remaining_cast <> ''
  )
  SELECT show_id, cast_name FROM cast_split
) AS tmp
JOIN person ON tmp.cast_name = person.name;

DROP TABLE tmp_cast;

CREATE TABLE `tmp_cast_netflix` (
  `show_id` varchar(15) NOT NULL PRIMARY KEY,
  `cast_name` varchar(255) NOT NULL
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/netflix_titles.csv'
INTO TABLE tmp_cast_netflix
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id, @dummy, @dummy, @dummy, cast_name);

INSERT INTO person (name)
SELECT DISTINCT cast_name
FROM (
  WITH RECURSIVE cast_split AS(
    SELECT 
      SUBSTRING_INDEX(cast_name, ',', 1) AS cast_name,
      SUBSTRING(cast_name, LENGTH(SUBSTRING_INDEX(cast_name, ',', 1)) + 2) AS remaining_cast
    FROM tmp_cast_netflix
    WHERE cast_name IS NOT NULL

    UNION ALL

    SELECT 
      SUBSTRING_INDEX(remaining_cast, ',', 1) AS cast_name,
      SUBSTRING(remaining_cast, LENGTH(SUBSTRING_INDEX(remaining_cast, ',', 1)) + 2) AS remaining_cast
    FROM cast_split
    WHERE remaining_cast <> ''
  )
  SELECT cast_name FROM cast_split
) AS tmp
WHERE cast_name IS NOT NULL;

LOAD DATA INFILE '/docker-entrypoint-initdb.d/netflix_titles.csv' 
INTO TABLE title 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(show_id, type, title, @director, @dummy, country, date_added, release_year, tv_rating, @duration, @dummy, description)
SET 
  duration = CASE 
    WHEN @duration LIKE '% min' THEN @duration 
    ELSE NULL 
  END,
  nb_seasons = CASE 
    WHEN @duration NOT LIKE '% min' THEN CAST(@duration AS UNSIGNED) 
    ELSE NULL 
  END,
  streaming_service = 'Netflix',
  director_id = (SELECT id FROM person WHERE name = @director LIMIT 1);

INSERT  IGNORE INTO played_in (show_id, person_id)
SELECT DISTINCT show_id, person.id
FROM (
  WITH RECURSIVE cast_split AS(
    SELECT 
      show_id,
      SUBSTRING_INDEX(cast_name, ',', 1) AS cast_name,
      SUBSTRING(cast_name, LENGTH(SUBSTRING_INDEX(cast_name, ',', 1)) + 2) AS remaining_cast
    FROM tmp_cast_netflix
    WHERE cast_name IS NOT NULL

    UNION ALL

    SELECT 
      show_id,
      SUBSTRING_INDEX(remaining_cast, ',', 1) AS cast_name,
      SUBSTRING(remaining_cast, LENGTH(SUBSTRING_INDEX(remaining_cast, ',', 1)) + 2) AS remaining_cast
    FROM cast_split
    WHERE remaining_cast <> ''
  )
  SELECT show_id, cast_name FROM cast_split
) AS tmp
JOIN person ON tmp.cast_name = person.name;

DROP TABLE tmp_cast_netflix;

CREATE TABLE `tmp_cast_disney` (
  `show_id` varchar(15) NOT NULL PRIMARY KEY,
  `cast_name` varchar(255) NOT NULL
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/disney_plus_titles.csv'
INTO TABLE tmp_cast_disney
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id, @dummy, @dummy, @dummy, cast_name);

INSERT INTO person (name)
SELECT DISTINCT cast_name
FROM (
  WITH RECURSIVE cast_split AS(
    SELECT 
      SUBSTRING_INDEX(cast_name, ',', 1) AS cast_name,
      SUBSTRING(cast_name, LENGTH(SUBSTRING_INDEX(cast_name, ',', 1)) + 2) AS remaining_cast
    FROM tmp_cast_disney
    WHERE cast_name IS NOT NULL

    UNION ALL

    SELECT 
      SUBSTRING_INDEX(remaining_cast, ',', 1) AS cast_name,
      SUBSTRING(remaining_cast, LENGTH(SUBSTRING_INDEX(remaining_cast, ',', 1)) + 2) AS remaining_cast
    FROM cast_split
    WHERE remaining_cast <> ''
  )
  SELECT cast_name FROM cast_split
) AS tmp
WHERE cast_name IS NOT NULL;

LOAD DATA INFILE '/docker-entrypoint-initdb.d/disney_plus_titles.csv' 
INTO TABLE title 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(show_id, type, title, @director, @dummy, country, date_added, release_year, tv_rating, @duration, @dummy, description)
SET 
  duration = CASE 
    WHEN @duration LIKE '% min' THEN @duration 
    ELSE NULL 
  END,
  nb_seasons = CASE 
    WHEN @duration NOT LIKE '% min' THEN CAST(@duration AS UNSIGNED) 
    ELSE NULL 
  END,
  streaming_service = 'Disney Plus',
  director_id = (SELECT id FROM person WHERE name = @director LIMIT 1);

INSERT IGNORE INTO played_in (show_id, person_id)
SELECT DISTINCT show_id, person.id
FROM (
  WITH RECURSIVE cast_split AS(
    SELECT 
      show_id,
      SUBSTRING_INDEX(cast_name, ',', 1) AS cast_name,
      SUBSTRING(cast_name, LENGTH(SUBSTRING_INDEX(cast_name, ',', 1)) + 2) AS remaining_cast
    FROM tmp_cast_disney
    WHERE cast_name IS NOT NULL

    UNION ALL

    SELECT 
      show_id,
      SUBSTRING_INDEX(remaining_cast, ',', 1) AS cast_name,
      SUBSTRING(remaining_cast, LENGTH(SUBSTRING_INDEX(remaining_cast, ',', 1)) + 2) AS remaining_cast
    FROM cast_split
    WHERE remaining_cast <> ''
  )
  SELECT show_id, cast_name FROM cast_split
) AS tmp
JOIN person ON tmp.cast_name = person.name;

DROP TABLE tmp_cast_disney;

COMMIT;
