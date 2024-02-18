/* Additions to create_movies.sql */

CREATE TABLE comments (
  comment_id SERIAL PRIMARY KEY,
  created_at timestamp DEFAULT current_timestamp,
  created_by text NOT NULL, -- future improvement; user_id (when users exists)
  movie_id integer REFERENCES movies, -- NULL ok for general comments
  comment text NOT NULL
)

