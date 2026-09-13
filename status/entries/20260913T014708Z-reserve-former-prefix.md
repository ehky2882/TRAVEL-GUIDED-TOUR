# Reserved the former. username prefix for deleted accounts (owner pasted, verified)

_2026-09-13 01:47 UTC · branch `reserve-former-prefix`_

Requested by the account-deletion session (`claude/account-self-delete`), which keeps a sold-tour maker row as "Former creator" with the handle `former.<12 hex>`. **`backend/reserve_former_prefix.sql`** patches the live `handle_problem()` by content, adding `or h like 'former.%'` beside the `user.%` check with an exactly-once guard. Owner pasted it 2026-09-13. Receipt: a person picking `former.abc` or a placeholder is `reserved`; the system assigning a placeholder is allowed (NULL); `formerly` is allowed (NULL).

That session's guard path (user_id NULL) never calls `handle_problem`, so the reservation cannot block deletion. Its PATCH/DELETE filter on `id=eq.<maker_id>&user_id=is.null` (confirmed by that session). App side: #849 hides `former.*` handles under "Former creator".
