# Security policy

## Supported versions

Until a later release establishes a broader policy, security fixes are applied
to the latest published minor version.

| Version | Supported |
| --- | --- |
| 0.1.x | Yes |
| Earlier versions | No |

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability.

Use GitHub's private vulnerability reporting feature from the repository's
**Security** tab. Include:

- the affected version;
- a minimal reproduction;
- expected and observed behavior;
- potential impact;
- any suggested mitigation.

Avoid including secrets, private source code, or production report artifacts
unless the maintainer explicitly requests them through a secure channel.

You should receive an acknowledgement within seven days. The maintainer will
then assess severity, coordinate a fix, and disclose the issue after an
appropriate release is available.

## Sensitive report data

Atlas reports contain test names, step and check names, assertion messages,
and stacktraces. These may reveal source paths or business rules. Treat report
files as test artifacts and review them before making them public.
