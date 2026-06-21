CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username   text UNIQUE NOT NULL,
  email      text UNIQUE NOT NULL,
  senha      text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cards (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scryfall_id        text NOT NULL,
  name               text NOT NULL,
  type_line          text,
  rarity             text,
  set_code           text,
  image_url          text,
  finish             text NOT NULL,
  treatment          text NOT NULL,
  available_finishes text[],
  price_usd          numeric,
  price_usd_foil     numeric,
  price_usd_etched   numeric,
  quantity           int NOT NULL DEFAULT 1,
  created_at         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, scryfall_id, finish, treatment)
);
