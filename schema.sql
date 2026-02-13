CREATE TABLE IF NOT EXISTS quiz_sessions (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  status TEXT NOT NULL DEFAULT 'waiting', -- waiting|live|finished
  current_question_index INT NOT NULL DEFAULT 0,

  -- Тайминг текущего вопроса main
  question_start_ns BIGINT,
  question_deadline_ns BIGINT,

  -- Длительность вопроса main (по умолчанию 60 секунд)
  question_duration_ns BIGINT NOT NULL DEFAULT 60000000000,

  -- Блиц (общий таймер на весь блиц)
  blitz_start_ns BIGINT,
  blitz_deadline_ns BIGINT,

  -- Куда слать результаты (админ, который запускал)
  admin_chat_id BIGINT,

  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS participants (
  id SERIAL PRIMARY KEY,
  session_id INT NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
  tg_user_id BIGINT NOT NULL,
  tg_username TEXT,
  display_name TEXT,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  blitz_index INT NOT NULL DEFAULT 0,

  UNIQUE(session_id, tg_user_id)
);



CREATE TABLE IF NOT EXISTS questions (
  id SERIAL PRIMARY KEY,
  session_code TEXT NOT NULL,
  set TEXT NOT NULL DEFAULT 'main' CHECK (set IN ('main','blitz')),
  order_index INT NOT NULL,
  text TEXT NOT NULL,
  opt_a TEXT NOT NULL,
  opt_b TEXT NOT NULL,
  opt_c TEXT NOT NULL,
  opt_d TEXT NOT NULL,
  correct CHAR(1) NOT NULL CHECK (correct IN ('A','B','C','D')),
  UNIQUE(session_code, set, order_index)
);

CREATE TABLE IF NOT EXISTS answers (
  id SERIAL PRIMARY KEY,
  session_id INT NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
  participant_id INT NOT NULL REFERENCES participants(id) ON DELETE CASCADE,
  set TEXT NOT NULL DEFAULT 'main' CHECK (set IN ('main','blitz')),
  question_index INT NOT NULL,
  chosen CHAR(1) NOT NULL CHECK (chosen IN ('A','B','C','D')),
  is_correct BOOLEAN NOT NULL,
  received_ns BIGINT NOT NULL,
  delta_ns BIGINT NOT NULL,
  answered_after_deadline BOOLEAN NOT NULL DEFAULT false,
  UNIQUE(participant_id, set, question_index)
);

CREATE INDEX IF NOT EXISTS idx_answers_session_set_question
ON answers(session_id, set, question_index);

CREATE INDEX IF NOT EXISTS idx_answers_participant_set_question
ON answers(participant_id, set, question_index);
