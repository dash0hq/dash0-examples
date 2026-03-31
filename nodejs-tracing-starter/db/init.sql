CREATE TABLE IF NOT EXISTS urls (
  id SERIAL PRIMARY KEY,
  short_code VARCHAR(10) UNIQUE NOT NULL,
  original_url TEXT NOT NULL,
  title TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS visits (
  id SERIAL PRIMARY KEY,
  short_code VARCHAR(10) NOT NULL REFERENCES urls(short_code),
  ip_address TEXT,
  country VARCHAR(100),
  city VARCHAR(100),
  user_agent TEXT,
  visited_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_urls_short_code ON urls(short_code);
CREATE INDEX idx_visits_short_code ON visits(short_code);
