CREATE TABLE genres (
  name text UNIQUE,
  position integer
);

CREATE TABLE movies (
  movie_id SERIAL PRIMARY KEY,
  title text,
  genre cube
);

CREATE TABLE actors (
  actor_id SERIAL PRIMARY KEY,
  name text
);

/* speed up reverse lookups via index on foreign keys
 * - unique to avoid duplicates
 */
CREATE TABLE movies_actors (
  movie_id integer REFERENCES movies NOT NULL,
  actor_id integer REFERENCES actors NOT NULL,
  UNIQUE (movie_id, actor_id)
);

CREATE INDEX movies_actors_movie_id ON movies_actors (movie_id);
CREATE INDEX movies_actors_actor_id ON movies_actors (actor_id);

/* https://www.postgresql.org/docs/16/gist.html */
CREATE INDEX movies_genres_cube ON movies USING gist (genre);
