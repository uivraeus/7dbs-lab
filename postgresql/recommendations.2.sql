CREATE OR REPLACE FUNCTION recommendations(
  ref_title text default NULL,
  ref_actor text default NULL
) RETURNS TABLE (movie_title text) AS $$
DECLARE
BEGIN
  
  IF ref_actor IS NOT NULL THEN 
    CREATE TEMP TABLE candidate_movies ON COMMIT DROP AS (
      SELECT title, genre
      FROM movies NATURAL JOIN movies_actors NATURAL JOIN actors
      WHERE metaphone(name, 6) = metaphone(ref_actor, 6)
    );
  ELSE
    CREATE TEMP TABLE candidate_movies ON COMMIT DROP AS (
      SELECT title, genre from movies
    );
  END IF;

  IF ref_title IS NOT NULL THEN
    RETURN QUERY
      SELECT m.title as movie_title
      FROM candidate_movies m, (
        SELECT genre, title
        FROM movies -- not candidate_movies here (possible to use ref_title where ref_actor doesn't appear)
        WHERE title = ref_title
      ) s
      WHERE ref_title <> m.title
      ORDER BY cube_distance(m.genre, s.genre)
      LIMIT 5;
  ELSE
    RETURN QUERY
      SELECT title as movie_title
      FROM candidate_movies
      ORDER BY random() -- no obvious "top" picks 
      LIMIT 5;
  END IF;

END
$$ LANGUAGE plpgsql;