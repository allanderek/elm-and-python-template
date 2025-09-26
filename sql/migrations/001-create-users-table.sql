create table users (
    id integer primary key autoincrement,
    username text not null unique,
    email text not null unique,
    fullname text,
    -- No 'not null' constraint on password to allow for OAuth users
    password text,
    admin boolean not null default false,
    created_at datetime default current_timestamp
);

create index idx_users_email on users(email)
;
