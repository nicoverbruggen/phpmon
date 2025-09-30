# Security Policy

## Supported versions

Generally speaking, only the latest version of **PHP Monitor** is supported, except during transition periods (for example, when particular system requirements go up).

| Version | Apple Silicon | Supported          | Supported macOS | Minimum Deployment | Detected PHP Versions | Recommended Valet Version |
| ------- | ------------- | ------------------ | ----- | ----- | ----- | ----
| 25      | ✅ Universal binary | ✅ Yes | Ventura (13.5+)<br/>Sonoma (14.0+)<br/>Sequoia (15.0+)<br/>Tahoe (26.0+) | macOS 13.5+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.4 (w/ Valet 3.x)<br/>PHP 7.1-PHP 8.5 (w/ Valet 4.x)| 3.0 or higher recommended<br/> 2.16.2 minimum |

## Legacy versions

These versions of PHP Monitor are no longer supported, but if you’re using an older computer with an older version of Homebrew, Valet or macOS, you might want to use one of these versions.

| Version | Apple Silicon | Supported          | Supported macOS | Minimum Deployment | Detected PHP Versions | Minimum Required Valet Version |
| ------- | ------------- | ------------------ | ----- | ----- | ----- | ----
| 7.1      | ✅ Universal binary | ❌ | Monterey (12.4+)<br/>Ventura (13.0+)<br/>Sonoma (14.0+)<br/>Sequoia (15.0+) | macOS 12.4+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.4 (w/ Valet 3.x)<br/>PHP 7.1-PHP 8.5 (w/ Valet 4.x)| 3.0 or higher recommended<br/> 2.16.2 minimum |
| 7.0      | ✅ Universal binary | ❌ | Monterey (12.4+)<br/>Ventura (13.0+)<br/>Sonoma (14.0) | macOS 12.4+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.4 (w/ Valet 3.x)<br/>PHP 7.1-PHP 8.4 (w/ Valet 4.x)| 3.0 or higher recommended<br/> 2.16.2 minimum |
| 6.2      | ✅ Universal binary | ❌ | Monterey (12.4+)<br/>Ventura (13.0+)<br/>Sonoma (14.0) | macOS 12.4+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.4 (w/ Valet 3.x)<br/>PHP 7.1-PHP 8.4 (w/ Valet 4.x)| 3.0 or higher recommended<br/> 2.16.2 minimum |
| 6.1      | ✅ Universal binary | ❌ | Monterey (12.4+)<br/>Ventura (13.0+)<br/>Sonoma (14.0) | macOS 12.4+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.4 (w/ Valet 3.x)<br/>PHP 7.1-PHP 8.4 (w/ Valet 4.x)| 3.0 or higher recommended<br/> 2.16.2 minimum |
| 6.0      | ✅ Universal binary | ❌ | Monterey (12.4+)<br/>Ventura (13.0+) | macOS 12.4+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.2 (w/ Valet 3.x)<br/>PHP 7.1-PHP 8.2 (w/ Valet 4.x) | 3.0 or higher recommended<br/> 2.16.2 minimum |
| 5.8       | ✅ Universal binary | ❌ | Monterey (12.4+)<br/>Ventura (13.0+) | macOS 12.4+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.2 (w/ Valet 3.x)<br/>PHP 7.1-PHP 8.2 (w/ Valet 4.x) | 3.0 or higher recommended<br/> 2.16.2 minimum |
| 5.7       | ✅ Universal binary | ❌ | Big Sur (11.0)<br/>Monterey (12.0)<br/>Ventura (13.0) | macOS 11+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.2 (w/ Valet 3.x)<br/>PHP 7.1-PHP 8.2 (w/ Valet 4.x) | 3.0 or higher recommended<br/> 2.16.2 minimum |
| 5.6       | ✅ Universal binary | ❌ | Big Sur (11.0)<br/>Monterey (12.0)<br/>Ventura (13.0) | macOS 11+ | PHP 5.6—PHP 8.2 (w/ Valet 2.x)<br/>PHP 7.0—PHP 8.2 (w/ Valet 3.x) | 3.0 recommended<br/> 2.16.2 minimum |
| 4.1       | ✅ Universal binary | ❌ | Big Sur (11.0)<br/>Monterey (12.0) | macOS 11+ | PHP 5.6—PHP 8.2 | 2.16.2 |
| 4.0       | ✅ Universal binary | ❌ | Big Sur (11.0)<br/>Monterey (12.0) | macOS 10.14+ | PHP 5.6—PHP 8.2 | 2.13 |
| 3.5       | ✅ Universal binary | ❌ | Big Sur (11.0)<br/>Monterey (12.0) | macOS 10.14+ | PHP 5.6—PHP 8.2 | 2.13 |
| 3.0—3.4   | ✅ Universal binary | ❌ | Big Sur (11.0) | macOS 10.14+ | PHP 5.6—PHP 8.1 | 2.13 |
| 2.6       | ✅ Universal binary | ❌ | Big Sur (11.0) | macOS 10.14+ | PHP 5.6—PHP 8.0 | 2.13 |
| 2.5       | ✴️ Universal binary<br/>`/usr/local/homebrew` installations only | ❌ | Big Sur (11.0)<br/>Catalina (10.15) | macOS 10.14+ | not applicable | not applicable |
| 2.4       | ✴️ Universal binary<br/>`/usr/local/homebrew` installations only | ❌ | Big Sur (11.0)<br/>Catalina (10.15) | macOS 10.14+ | not applicable | not applicable |
| < 2.4     | ❌ Intel binary<br/>`/usr/local/homebrew` installations only | ❌ | Catalina (10.15) | macOS 10.14+ | not applicable | not applicable | 

## Reporting a vulnerability

Contact me (Nico Verbruggen) at the email address used for the commits in the repository. Please include "PHP Monitor" in the subject.
