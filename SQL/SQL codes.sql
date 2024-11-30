create database if not exists IMDb;
USE IMDb;
CREATE TABLE name_basics (
    nconst VARCHAR(20) PRIMARY KEY,
    primaryName VARCHAR(255),
    birthYear INT,
    deathYear INT,
    primaryProfession VARCHAR(255),
    knownForTitles VARCHAR(255)
);
CREATE TABLE title_basics (
    tconst VARCHAR(20) PRIMARY KEY,
    titleType VARCHAR(50),
    primaryTitle VARCHAR(512),
    originalTitle VARCHAR(512),
    isAdult TINYINT,
    startYear INT,
    endYear INT,
    runtimeMinutes INT,
    genres VARCHAR(255)
);
CREATE TABLE title_ratings (
    tconst VARCHAR(20),
    averageRating DECIMAL(3, 1),
    numVotes INT,
    PRIMARY KEY (tconst),
    FOREIGN KEY (tconst) REFERENCES title_basics(tconst) ON DELETE CASCADE
);
CREATE TABLE title_episode (
    tconst VARCHAR(20),
    parentTconst VARCHAR(20),
    seasonNumber INT,
    episodeNumber INT,
    PRIMARY KEY (tconst),
    FOREIGN KEY (tconst) REFERENCES title_basics(tconst) ON DELETE CASCADE,
    FOREIGN KEY (parentTconst) REFERENCES title_basics(tconst) ON DELETE CASCADE
);
CREATE TABLE title_akas (
    titleId VARCHAR(20),
    ordering INT,
    title VARCHAR(512),
    region VARCHAR(255),
    language VARCHAR(255),
    types VARCHAR(255),
    attributes VARCHAR(255),
    isOriginalTitle TINYINT,
    PRIMARY KEY (titleId, ordering),
    FOREIGN KEY (titleId) REFERENCES title_basics(tconst) ON DELETE CASCADE
);
ALTER TABLE title_akas MODIFY title VARCHAR(1024);

CREATE TABLE title_directors (
    tconst VARCHAR(20),
    director_id VARCHAR(20),
    FOREIGN KEY (tconst) REFERENCES title_basics(tconst) ON DELETE CASCADE
);

CREATE TABLE title_writers (
    tconst VARCHAR(20),
    writer_id VARCHAR(20),
    FOREIGN KEY (tconst) REFERENCES title_basics(tconst) ON DELETE CASCADE
);

CREATE TABLE title_principals (
    tconst VARCHAR(20),
    ordering INT,
    nconst VARCHAR(20),
    category VARCHAR(255),
    job VARCHAR(255),
    characters VARCHAR(512),
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst) REFERENCES title_basics(tconst) ON DELETE CASCADE,
    FOREIGN KEY (nconst) REFERENCES name_basics(nconst) ON DELETE CASCADE
);

SHOW VARIABLES LIKE 'secure_file_priv';
SET GLOBAL local_infile = 1;
SET SESSION local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/name.basics.tsv'
INTO TABLE name_basics
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(nconst, primaryName, birthYear, deathYear, primaryProfession, knownForTitles);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/title.basics.tsv'
INTO TABLE title_basics
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/title.ratings.tsv'
INTO TABLE title_ratings
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, averageRating, numVotes);

SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/title.episode.tsv'
INTO TABLE title_episode
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, parentTconst, seasonNumber, episodeNumber);

SET FOREIGN_KEY_CHECKS = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/title.akas.tsv'
INTO TABLE title_akas
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(titleId, ordering, title, region, language, types, attributes, isOriginalTitle);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/title.crew.tsv'
INTO TABLE title_crew
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, directors, writers);

-- Load data into title_directors
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/title.directors.tsv'
INTO TABLE title_directors
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, director_id);

-- Load data into title_writers
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/title.writers.tsv'
INTO TABLE title_writers
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, writer_id);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/title.principals.tsv'
INTO TABLE title_principals
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(tconst, ordering, nconst, category, job, characters);

CREATE TABLE title_counts AS 
SELECT titleType, COUNT(*) AS total 
FROM title_basics 
GROUP BY titleType;

CREATE TABLE genre_counts AS
WITH RECURSIVE genre_split AS (
    SELECT
        tconst,
        SUBSTRING_INDEX(genres, ',', 1) AS genre,
        SUBSTRING_INDEX(genres, ',', -1) AS remaining_genres
    FROM title_basics
    WHERE genres IS NOT NULL
    
    UNION ALL
    
    SELECT
        tconst,
        SUBSTRING_INDEX(remaining_genres, ',', 1),
        IF(remaining_genres = genre, NULL, SUBSTRING_INDEX(remaining_genres, ',', -1))
    FROM genre_split
    WHERE remaining_genres IS NOT NULL
)
SELECT genre, COUNT(*) AS total
FROM genre_split
GROUP BY genre;

CREATE TABLE titles_per_year AS 
SELECT startYear, titleType, COUNT(*) AS total_titles
FROM title_basics
WHERE startYear IS NOT NULL
GROUP BY startYear, titleType
ORDER BY startYear;

-- weightingaverage 2
CREATE TEMPORARY TABLE genre_movies
SELECT *
FROM genre_titletype
WHERE titleType = "movie";

-- join 3 tables
-- you can mix it with above code
CREATE TABLE genre_movie_ratings AS
SELECT 
    gm.tconst,
    tb.primaryTitle,
    tb.startYear,
    tb.runtimeMinutes,
    gm.genre,
    tr.averageRating,
    tr.numVotes
FROM 
    genre_movies gm
JOIN 
    title_basics tb ON gm.tconst = tb.tconst
JOIN 
    title_ratings tr ON gm.tconst = tr.tconst;

-- Minimum number of votes required to be considered (e.g., the 90th percentile of the number of votes across all movies which is 2714)
-- The mean average rating across all movies (C)
CREATE TABLE genre_movie_weighted_rating
WITH avg_rating AS (
    SELECT AVG(averageRating) AS C
    FROM genre_movie_ratings
)

-- Weighted Rating
SELECT 
    gmr.tconst,
    gmr.primaryTitle,
    gmr.startYear,
    gmr.runtimeMinutes,
    gmr.genre,
    gmr.averageRating AS R,
    gmr.numVotes AS v,
    avg_rating.C,
    2714 AS m,
    ((gmr.numVotes / (gmr.numVotes + 2714)) * gmr.averageRating) + 
    ((2714 / (gmr.numVotes + 2714)) * avg_rating.C) AS weighted_rating
FROM 
    genre_movie_ratings gmr,
    avg_rating
ORDER BY 
    weighted_rating DESC;
    
    -- Top Directors
drop table genre_director_movies;
CREATE TEMPORARY TABLE genre_director_movies AS
SELECT 
    gmw.tconst,
    gmw.primaryTitle,
    gmw.startYear,
    gmw.runtimeMinutes,
    gmw.genre,
    gmw.weighted_rating,
    REPLACE(REPLACE(TRIM(td.director_id), '\n', ''), '\r', '') AS director_id
FROM 
    genre_movie_weighted_rating AS gmw
JOIN 
    title_directors AS td
ON 
    gmw.tconst = td.tconst;

-- join to name_basics
CREATE temporary TABLE genre_director_movies_with_names AS
SELECT 
    gdm.tconst,
    gdm.primaryTitle,
    gdm.startYear,
    gdm.runtimeMinutes,
    gdm.genre,
    gdm.weighted_rating,
    gdm.director_id,
    nb.primaryName AS director_name,
    nb.birthYear,
    nb.deathYear
FROM 
    genre_director_movies AS gdm
JOIN 
    name_basics AS nb
ON 
    gdm.director_id = nb.nconst;

-- removing duplicates
CREATE TABLE unique_director_movies AS
SELECT DISTINCT 
    tconst,
    primaryTitle,
    startYear,
    runtimeMinutes,
    weighted_rating,
    director_id,
    director_name,
    birthYear,
    deathYear
FROM 
    genre_director_movies_with_names;
    
    -- bayesian average
create table top_directors
WITH director_stats AS (
    SELECT
        director_id,
        director_name,
        COUNT(tconst) AS total_movies,
        AVG(weighted_rating) AS avg_rating
    FROM unique_director_movies
    GROUP BY director_id, director_name
),
global_stats AS (
    SELECT AVG(weighted_rating) AS global_mean
    FROM unique_director_movies
)
SELECT
    ds.director_id,
    ds.director_name,
    ds.total_movies,
    ds.avg_rating,
    gs.global_mean,
    ((ds.avg_rating * ds.total_movies) + (gs.global_mean * 5)) / (ds.total_movies + 5) AS bayesian_average
FROM director_stats ds
CROSS JOIN global_stats gs
ORDER BY bayesian_average DESC;
    