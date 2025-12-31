# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_19_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "accounts", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "append_url"
    t.boolean "append_url_if_truncated"
    t.string "append_url_label"
    t.string "append_url_spacer"
    t.boolean "attach_link"
    t.datetime "created_at", null: false
    t.jsonb "credentials", default: {}, null: false
    t.datetime "credentials_renewed_at"
    t.integer "crosspost_cooldown", default: 0, null: false
    t.integer "crosspost_min_age", default: 0, null: false
    t.integer "disabled_feed_ids", default: [], null: false, array: true
    t.string "format_string"
    t.string "label", null: false
    t.boolean "manually_create_crossposts", default: false, null: false
    t.boolean "manually_publish_crossposts", default: false, null: false
    t.string "og_image"
    t.string "platform_tag", null: false
    t.boolean "truncate"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "crossposts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "attempts", default: 0, null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.jsonb "failures", default: []
    t.datetime "last_attempted_at"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "post_id", null: false
    t.datetime "published_at"
    t.string "remote_id"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["account_id"], name: "index_crossposts_on_account_id"
    t.index ["metadata"], name: "index_crossposts_on_metadata", using: :gin
    t.index ["post_id", "account_id"], name: "index_crossposts_on_post_id_and_account_id", unique: true
    t.index ["post_id"], name: "index_crossposts_on_post_id"
  end

  create_table "feeds", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "automatically_create_crossposts", default: true, null: false
    t.datetime "created_at", null: false
    t.string "etag_header"
    t.string "label", null: false
    t.datetime "last_checked_at"
    t.string "last_modified_header"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "url"], name: "index_feeds_on_user_id_and_url", unique: true
    t.index ["user_id"], name: "index_feeds_on_user_id"
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "invited_by_id", null: false
    t.bigint "received_by_id"
    t.string "status", default: "open", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invites_on_email_open", unique: true, where: "((status)::text = 'open'::text)"
    t.index ["invited_by_id"], name: "index_invites_on_invited_by_id"
    t.index ["received_by_id"], name: "index_invites_on_received_by_id"
    t.index ["status"], name: "index_invites_on_status"
    t.index ["token"], name: "index_invites_on_token", unique: true
    t.check_constraint "received_by_id IS NULL OR status::text = 'accepted'::text", name: "received_by_only_for_accepted"
    t.check_constraint "status::text <> 'accepted'::text OR email IS NULL OR email::text = ''::text", name: "accepted_invites_require_blank_email"
    t.check_constraint "status::text <> 'accepted'::text OR received_by_id IS NOT NULL", name: "accepted_invites_require_recipient"
    t.check_constraint "status::text <> 'open'::text OR email IS NOT NULL AND email::text <> ''::text", name: "open_invites_require_email"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying, 'accepted'::character varying]::text[])", name: "invites_status_valid"
  end

  create_table "notifications", force: :cascade do |t|
    t.boolean "badge", default: false, null: false
    t.datetime "created_at", null: false
    t.jsonb "refs", default: [], null: false, array: true
    t.virtual "search", type: :tsvector, as: "to_tsvector('simple'::regconfig, (((COALESCE(title, ''::character varying))::text || ' '::text) || COALESCE(text, ''::text)))", stored: true
    t.datetime "seen_at"
    t.string "severity", null: false
    t.text "text", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["refs"], name: "index_notifications_on_refs", using: :gin
    t.index ["search"], name: "index_notifications_on_search", using: :gin
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_created_at", order: { created_at: :desc }
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "alternate_url"
    t.boolean "append_url"
    t.boolean "append_url_if_truncated"
    t.string "append_url_label"
    t.string "append_url_spacer"
    t.boolean "attach_link"
    t.string "author_email"
    t.string "author_name"
    t.string "channel"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "crossposts_created_at"
    t.bigint "feed_id", null: false
    t.string "format_string"
    t.jsonb "media", default: [], null: false, array: true
    t.string "og_description"
    t.string "og_image"
    t.string "og_title"
    t.jsonb "platform_overrides", default: {}, null: false
    t.string "related_url"
    t.string "remote_id", null: false
    t.datetime "remote_published_at"
    t.datetime "remote_updated_at"
    t.string "short_url"
    t.string "subtitle"
    t.text "summary"
    t.boolean "syndicate"
    t.string "title"
    t.boolean "truncate"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index "((((((COALESCE(title, ''::character varying))::text || ' '::text) || (COALESCE(url, ''::character varying))::text) || ' '::text) || COALESCE(content, ''::text))) gin_trgm_ops", name: "idx_posts_search_trgm", using: :gin
    t.index ["feed_id", "remote_id"], name: "index_posts_on_feed_id_and_remote_id", unique: true
    t.index ["feed_id"], name: "index_posts_on_feed_id"
    t.index ["media"], name: "index_posts_on_media", using: :gin
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "system_configurations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "fake_now"
    t.datetime "updated_at", null: false
  end

  create_table "temporary_assets", force: :cascade do |t|
    t.binary "bytes", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.bigint "crosspost_id", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["crosspost_id"], name: "index_temporary_assets_on_crosspost_id", unique: true
    t.index ["key"], name: "index_temporary_assets_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.boolean "allow_automatic_syndication", default: true, null: false
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "email_verified_at"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["allow_automatic_syndication"], name: "index_users_on_allow_automatic_syndication"
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verified_at"], name: "index_users_on_email_verified_at"
  end

  add_foreign_key "accounts", "users", on_delete: :cascade
  add_foreign_key "crossposts", "accounts", on_delete: :cascade
  add_foreign_key "crossposts", "posts", on_delete: :cascade
  add_foreign_key "feeds", "users", on_delete: :cascade
  add_foreign_key "invites", "users", column: "invited_by_id"
  add_foreign_key "invites", "users", column: "received_by_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "posts", "feeds", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "temporary_assets", "crossposts", on_delete: :cascade
end
