create table user_oauth_accounts (
    id bigserial primary key,
    user_id bigint not null references users(id) on delete cascade,
    provider varchar(50) not null, -- 'google', 'github', etc.
    provider_user_id varchar(255) not null, -- the ID from OAuth provider
    email varchar(255), -- email from this provider (might differ)
    created_at datetime default current_timestamp,
    unique(provider, provider_user_id)
);

create index idx_oauth_user_id on user_oauth_accounts(user_id);
