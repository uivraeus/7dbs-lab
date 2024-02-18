CREATE OR REPLACE FUNCTION recommendations(
  ref_title text default NULL,
  ref_actor text default NULL
) RETURNS TABLE (movie_title text) AS $$
DECLARE
BEGIN
  
  IF ref_actor IS NOT NULL THEN
    RETURN QUERY
      SELECT title as movie_title
      FROM movies NATURAL JOIN movies_actors NATURAL JOIN actors
      WHERE metaphone(name, 6) = metaphone(ref_actor, 6)
      LIMIT 5;
  ELSE
    RETURN QUERY
      SELECT m.title as movie_title
      FROM movies m, (
        SELECT genre, title
        FROM movies
        WHERE title = ref_title
      ) s
      WHERE ref_title <> m.title
      ORDER BY cube_distance(m.genre, s.genre)
      LIMIT 5;
  END IF;

END
$$ LANGUAGE plpgsql;