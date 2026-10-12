SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

CREATE TABLE `person`(
    name varchar(50) PRIMARY KEY
);

CREATE TABLE `movie`(
    name varchar(50),
    runtime_minutes SMALLINT UNSIGNED,
    censor_rating varchar(20),
    company varchar(50),
    country varchar(50),
    gross int,
    budget int,
    released_year YEAR,
    released_date VARCHAR(50),
    nb_votes int,
    director varchar(50),
    star varchar(50),
    writer varchar(50),
    PRIMARY KEY (`name`, `released_date`),
    INDEX (`released_date`),
    FOREIGN KEY (`writer`) REFERENCES `person`(`name`) ON DELETE SET NULL,
    FOREIGN KEY (`director`) REFERENCES `person`(`name`) ON DELETE SET NULL,
    FOREIGN KEY (`star`) REFERENCES `person`(`name`) ON DELETE SET NULL
);

CREATE TABLE `genre`(
    movie_name varchar(50),
    movie_date varchar(50),
    genre_name varchar(30),
    PRIMARY KEY (`movie_name`, `genre_name`, `movie_date`),
    FOREIGN KEY (`movie_name`) REFERENCES `movie`(`name`) ON DELETE CASCADE
);

CREATE TABLE `video`(
    video_id varchar(50) PRIMARY KEY
);

CREATE TABLE `trailer_of`(
    video_id varchar(50),
    movie_name varchar(50),
    released_date varchar(50),
    PRIMARY KEY (`video_id`, `movie_name`, `released_date`),
    FOREIGN KEY (`video_id`) REFERENCES `video`(`video_id`) ON DELETE CASCADE,
    FOREIGN KEY (`movie_name`) REFERENCES `movie`(`name`) ON DELETE CASCADE,
    FOREIGN KEY (`released_date`) REFERENCES `movie`(`released_date`) ON DELETE CASCADE
);
CREATE TABLE `sentiments`(
    video_id varchar(50) PRIMARY KEY,
    nb_positive int,
    nb_neutral int,
    nb_negative int,
    FOREIGN KEY (`video_id`) REFERENCES `video`(`video_id`) ON DELETE CASCADE
);
CREATE TABLE `temp_person`(
    name varchar(50),
    id int PRIMARY KEY AUTO_INCREMENT
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/movies_youtube_sentiments.csv' 
INTO TABLE `temp_person`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(@dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, name);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/movies_youtube_sentiments.csv'
INTO TABLE `temp_person`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(@dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, name);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/movies_youtube_sentiments.csv'
INTO TABLE `temp_person`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(@dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, @dummy, name);

INSERT INTO `person` (name)
SELECT DISTINCT name FROM `temp_person`;


DROP TABLE `temp_person`;
LOAD DATA INFILE '/docker-entrypoint-initdb.d/movies_youtube_sentiments.csv'
INTO TABLE `movie`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(name, @dummy, @dummy, @dummy, @dummy, censor_rating, @dummy, released_year, released_date, nb_votes, director, writer, star, country, budget, gross, company, runtime_minutes);

LOAD DATA INFILE '/docker-entrypoint-initdb.d/movies_youtube_sentiments.csv'
INTO TABLE `genre`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(movie_name, @dummy, @dummy, @dummy, @dummy, @dummy, genre_name, @dummy, movie_date);
CREATE TEMPORARY TABLE `tmp_video`(
    video_id varchar(50),
    ID int PRIMARY KEY AUTO_INCREMENT
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/movies_youtube_sentiments.csv'
INTO TABLE `tmp_video`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(@dummy, @dummy, video_id);

INSERT INTO `video` (video_id)
SELECT DISTINCT video_id FROM `tmp_video`;

DROP TABLE `tmp_video`;
LOAD DATA INFILE '/docker-entrypoint-initdb.d/movies_youtube_sentiments.csv'
INTO TABLE `trailer_of`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(movie_name, @dummy, video_id, @dummy, @dummy, @dummy, @dummy, @dummy, released_date); 
CREATE TABLE `tmp_sentiments`(
    video_id varchar(50),
    json_data TEXT,
    ID int PRIMARY KEY AUTO_INCREMENT 
);
LOAD DATA INFILE '/docker-entrypoint-initdb.d/movies_youtube_sentiments.csv'
INTO TABLE `tmp_sentiments`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(@dummy, @dummy, video_id, @json_data)
SET json_data = IF(@json_data LIKE '{%}', @json_data, NULL);

INSERT INTO `sentiments` (video_id, nb_positive, nb_neutral, nb_negative)
SELECT video_id, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(json_data, 'positive\': ', -1), ',', 1) + 0,
    SUBSTRING_INDEX(SUBSTRING_INDEX(json_data, 'neutral\': ', -1), ',', 1) + 0,
    SUBSTRING_INDEX(SUBSTRING_INDEX(json_data, 'negative\': ', -1), '}', 1) + 0
FROM `tmp_sentiments`
ON DUPLICATE KEY UPDATE 
    nb_positive = VALUES(nb_positive), 
    nb_neutral = VALUES(nb_neutral), 
    nb_negative = VALUES(nb_negative);

DROP TABLE `tmp_sentiments`;
COMMIT;
