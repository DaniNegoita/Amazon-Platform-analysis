
-- BEGINNING

-- INSIGHTS: 

-- Movies vs TV shows distributions 
-- Run time analysis
-- IMDB scores & TMBD popularity
-- Genres trends over time and geographical regions
-- Top 5 titles & inner join


-- Explore titles table
select *
from projects..titles;

-- Step 1: Polish and Transform the dataset

-- Add a new column named CleanedGenres to the titles table
alter table projects..titles
add CleanedGenres nvarchar(max);

-- Update the CleanedGenres column using data transformation subquery
update t
set t.CleanedGenres = sub.Genre
from projects..titles as t
cross apply (
    select trim(value) as Genre -- remove leading/trailing spaces
   from string_split            -- split string into multiple rows based on comma delimiter
   (replace(replace(replace(t.genres, '[', ''), ']', ''), '''', ''), ',') -- remove square brackets and single quotes
) as sub;

-- Same operation for production countries
alter table projects..titles
add CleanedCountries nvarchar(max);

update t
set t.CleanedCountries=sub1.Countries
from projects..titles as t
cross apply (
select trim(value) as Countries
from string_split(replace(replace(replace(t.production_countries, '[', ''), ']', ''), '''', ''), ',')
) as sub1;

/*************************************************************************************/

-- Step 2: Analysis


-- Distribution by Type: Movie vs. TV Show
-- Count the number of titles for each type (Movie vs. TV Show)
select type, count(*) as countType
from projects..titles
group by type;

/*
The results indicate a notable disparity between the number of movies (9322) and TV shows (1551), which
underscores the prevalence and popularity of movies as a dominant form of entertainment.
*/

-- Runtime analysis : assess the most common duration for movies and TV shows

-- Calculate the average time
select type, round(avg(runtime),1) as avgDuration
from projects..titles
group by type

/*
The findings highlight a substantial difference in average runtime between movies and TV shows
where the movies exhibit a notably longer average duration (circa 94 minutes) when compared
to the TV shows ( circa 36.4 minutes).
*/


-- Analyse imbd scores and TMBD popularity 
select *
from projects..titles;

select title, type, imdb_score, round((tmdb_popularity),1) as tmdbPopularity, release_year
from projects..titles
where imdb_score is not null
and tmdb_popularity is not null
group by  title, type, imdb_score, tmdb_popularity, release_year
order by imdb_score desc, tmdbPopularity desc

/* Among the highest-ranking based on IMDb scores and TMDB popularity the top 5 are all mvoies, 
with "Pawankhind" on the top, a movie released in the year 2022. */


-- Genre trends over the years and geographical distribution

select min(release_year), max(release_year) -- the dataset contains year info from 1912 to 2023
from projects..titles

select release_year, CleanedCountries, CleanedGenres, count(*) as gen
from projects..titles
group by release_year, CleanedCountries, CleanedGenres
order by gen desc

/*
The analysis reveals that the genre "drama" stands out as the most popular choice among viewers, 
reflecting a significant preference for emotionally engaging content.
Furthermore, it is noteworthy that the United States emerges as the predominant production country, 
showcasing its pivotal role in the creation and distribution of these compelling dramatic titles. 
*/


-- Top 5 titles between 2018 and 2021
-- and countries of production and type
select top(5) id,  title, CleanedCountries, type
from projects..titles
where CleanedGenres='drama'
and release_year between '2018'and '2021'

/* The list of the top 5 drama titles comprises films produced in India, Ireland, Japan, and Korea. 
Notably, India takes the lead in this selection, contributing 2 out of the 5 films.*/

select name
from projects..credits

-- Next perform an inner join where I retrieve the leading actors' names
select distinct title, CleanedCountries, type, stuff((   -- concatenate names into a comma-separated list within each title
        select ', ' + c.name
        from projects..credits as c
        where c.id = t.id
        for xml path(''), type).value('.', 'nvarchar(max)'), 1, 2, '') as Actors -- extract names into xml format and store them in a nvarchar string
from projects..titles as t
inner join projects..credits as c
on t.id=c.id
where CleanedGenres='drama'
and release_year between '2018'and '2021'
and t.id in ('tm853251', 'tm448269', 'tm430081', 'tm461807', 'tm454307')

-- END