# Database Review Guidelines

This page is specific to database reviews. Please refer to our
[code review guide](code_review.md) for broader advice and best
practices for code review in general.

## General process

A database review is required for:

- Changes that touch the database schema or perform data migrations,
  including files in:
  - `db/`
  - `lib/gitlab/background_migration/`
- Changes to the database tooling, e.g.:
  - migration or ActiveRecord helpers in `lib/gitlab/database/`
  - load balancing
- Changes that produce SQL queries that are beyond the obvious. It is
  generally up to the author of a merge request to decide whether or
  not complex queries are being introduced and if they require a
  database review.

A database reviewer is expected to look out for obviously complex
queries in the change and review those closer. If the author does not
point out specific queries for review and there are no obviously
complex queries, it is enough to concentrate on reviewing the
migration only.

It is preferable to review queries in SQL form and generally accepted
to ask the author to translate any ActiveRecord queries in SQL form
for review.

### Roles and process

A Merge Request author's role is to:

- Decide whether a database review is needed.
- If database review is needed, add the ~database label.
- Use the [database changes](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab/merge_request_templates/Database%20changes.md)
  merge request template, or include the appropriate items in the MR description.

A database **reviewer**'s role is to:

- Perform a first-pass review on the MR and suggest improvements to the author.
- Once satisfied, relabel the MR with ~"database::reviewed", approve it, and
  reassign MR to the database **maintainer** suggested by Reviewer
  Roulette.

A database **maintainer**'s role is to:

- Perform the final database review on the MR.
- Discuss further improvements or other relevant changes with the
  database reviewer and the MR author.
- Finally approve the MR and relabel the MR with ~"database::approved"
- Merge the MR if no other approvals are pending or pass it on to
  other maintainers as required (frontend, backend, docs).

### Distributing review workload

Review workload is distributed using [reviewer roulette](code_review.md#reviewer-roulette)
([example](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/25181#note_147551725)).
The MR author should then co-assign the suggested database
**reviewer**. When they give their sign-off, they will hand over to
the suggested database **maintainer**.

If reviewer roulette didn't suggest a database reviewer & maintainer,
make sure you have applied the ~database label and rerun the
`danger-review` CI job, or pick someone from the
[`@gl-database` team](https://gitlab.com/groups/gl-database/-/group_members).

### How to review for database

- Check migrations
  - Review relational modeling and design choices
  - Review migrations follow [database migration style guide](migration_style_guide.md),
    for example
    - [Check ordering of columns](ordering_table_columns.md)
    - [Check indexes are present for foreign keys](migration_style_guide.md#adding-foreign-key-constraints)
  - Ensure that migrations execute in a transaction or only contain
    concurrent index/foreign key helpers (with transactions disabled)
  - Check consistency with `db/schema.rb` and that migrations are [reversible](migration_style_guide.md#reversibility)
  - For data migrations, establish a time estimate for execution
- Check post deploy migration
  - Make sure we can expect post deploy migrations to finish within 1 hour max.
- Check background migrations
  - Review queries (for example, make sure batch sizes are fine)
  - Establish a time estimate for execution
- Query performance
  - Check for any obviously complex queries and queries the author specifically
    points out for review (if any)
  - If not present yet, ask the author to provide SQL queries and query plans
    (e.g. by using [chatops](understanding_explain_plans.md#chatops) or direct
    database access)
  - For given queries, review parameters regarding data distribution
  - [Check query plans](understanding_explain_plans.md) and suggest improvements
    to queries (changing the query, schema or adding indexes and similar)
  - General guideline is for queries to come in below 100ms execution time
  - If queries rely on prior migrations that are not present yet on production
    (eg indexes, columns), you can use a [one-off instance from the restore
    pipeline](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd)
    in order to establish a proper testing environment.
