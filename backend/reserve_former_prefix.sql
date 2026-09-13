-- ✅ APPLIED by the owner, 2026-09-13. Receipt: person_picks_former = reserved ·
-- person_picks_a_placeholder = reserved · system_assigns_placeholder = NULL ·
-- a_normal_word_starting_former = NULL — exactly as expected. Kept as the record.
--
-- reserve_former_prefix.sql
--
-- Reserve usernames starting with `former.` so a signed-in person cannot pick
-- one and look like a deleted account.
--
-- Why: account deletion (branch claude/account-self-delete) keeps a sold-tour
-- maker row as "Former creator" with the handle `former.<12 hex>`. That handle
-- is assigned only after the login is gone (user_id NULL), and the guard's
-- user_id-NULL branch never calls handle_problem, so this reservation can
-- never block it. It only stops a PERSON choosing `former.anything`.
--
-- 🔴 Patches the LIVE handle_problem() by content, the same way
-- usernames.sql patched the catalogue: find the `user.%` check, add one
-- condition beside it, refuse if the anchor is not there exactly once, prove
-- it took. Safe to re-run: skipped when already present.

do $patch$
declare
    src     text;
    patched text;
    anchor  constant text := '(or h like ''user\.%'')';
    hits    int;
begin
    src := pg_get_functiondef('public.handle_problem(text, boolean)'::regprocedure);

    if src like '%former.%' then
        raise notice 'handle_problem already reserves former. - nothing to do.';
        return;
    end if;

    select count(*) into hits from regexp_matches(src, anchor, 'g');
    if hits <> 1 then
        raise exception 'expected the user.%% check exactly once in handle_problem, found % - refusing to guess.', hits;
    end if;

    patched := regexp_replace(src, anchor, E'\\1 or h like ''former.%''');
    execute patched;

    if pg_get_functiondef('public.handle_problem(text, boolean)'::regprocedure) not like '%former.%' then
        raise exception 'handle_problem still does not reserve former. after patching.';
    end if;
end
$patch$;

-- The proof. Expect: reserved · reserved · NULL · NULL
-- (NULL means "allowed": the system may still assign former.…, and an
--  ordinary word like `formerly` — no dot — is untouched.)
select
    public.handle_problem('former.abc', false)          as person_picks_former,
    public.handle_problem('former.1a2b3c4d5e6f', false) as person_picks_a_placeholder,
    public.handle_problem('former.1a2b3c4d5e6f', true)  as system_assigns_placeholder,
    public.handle_problem('formerly', false)            as a_normal_word_starting_former;
