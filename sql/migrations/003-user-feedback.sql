-- User Feedback Table Migration
-- Stores user feedback with optional user association and email

create table user_feedback (
    id integer primary key autoincrement,
    user_id integer, -- nullable, as user may not be logged in
    email text, -- optional email address for non-logged-in users
    comments text not null, -- main feedback content
    user_agent text, -- browser/client information for debugging
    ip_address text, -- for spam prevention (if needed)
    status text not null default 'new', -- new, reviewed, resolved
    created_at datetime default current_timestamp,
    foreign key (user_id) references users(id)
);

-- Indices for performance
create index idx_user_feedback_user_id on user_feedback(user_id);
create index idx_user_feedback_status on user_feedback(status);
create index idx_user_feedback_created_at on user_feedback(created_at);