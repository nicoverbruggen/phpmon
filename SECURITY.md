# Security Policy

## Supported versions

Generally speaking, only the latest version of **PHP Monitor** is supported, except during transition periods (for example, when particular system requirements go up):

| Version | Apple silicon | Supported          | Supported macOS | Deployment Target | Detected PHP Versions | Minimum Required Valet Version |
| ------- | ------------- | ------------------ | ----- | ----- | ----- | ----
| 4.1       | ✅ Universal binary | ✅ Yes | Big Sur (11.0) and Monterey (12.0) | macOS 11+ | PHP 5.6—PHP 8.2 | 2.16.2 |

## Legacy versions

These versions of PHP Monitor are no longer supported, but if you’re using an older computer with an older version of Homebrew, Valet or macOS, you might want to use one of these versions.

| Version | Apple silicon | Supported          | Supported macOS | Deployment Target | Detected PHP Versions | Minimum Required Valet Version |
| ------- | ------------- | ------------------ | ----- | ----- | ----- | ----
| 4.0       | ✅ Universal binary | ❌ | Big Sur (11.0) and Monterey (12.0) | macOS 10.14+ | PHP 5.6—PHP 8.2 | 2.13 |
| 3.5       | ✅ Universal binary | ❌ | Big Sur (11.0) and Monterey (12.0) | macOS 10.14+ | PHP 5.6—PHP 8.2 | 2.13 |
| 3.0—3.4   | ✅ Universal binary | ❌ | Big Sur (11.0) | macOS 10.14+ | PHP 5.6—PHP 8.1 | 2.13 |
| 2.6       | ✅ Universal binary | ❌ | Big Sur (11.0) | macOS 10.14+ | PHP 5.6—PHP 8.0 | 2.13 |
| 2.5       | ✴️ Universal binary<br/>`/usr/local/homebrew` installations only | ❌ | Big Sur (11.0)<br/>Catalina (10.15) | macOS 10.14+ | not applicable | not applicable |
| 2.4       | ✴️ Universal binary<br/>`/usr/local/homebrew` installations only | ❌ | Big Sur (11.0)<br/>Catalina (10.15) | macOS 10.14+ | not applicable | not applicable |
| < 2.4     | ❌ Intel binary<br/>`/usr/local/homebrew` installations only | ❌ | Catalina (10.15) | macOS 10.14+ | not applicable | not applicable | 

## Reporting a vulnerability

Contact me (Nico Verbruggen) at the email address used for the commits in the repository. Please include "PHP Monitor" in the subject.
