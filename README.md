# Aurora

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/a940189170c8456c85a75ea36edb32c7)](https://app.codacy.com/gh/ublue-os/aurora/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Stable Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-stable.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-stable.yml) [![Latest Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-main.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-main.yml) [![Beta Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-beta.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-beta.yml) [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ublue-os/aurora-docs)

[![LFX Active Contributors](https://insights.linuxfoundation.org/api/badge/active-contributors?project=aurora&repos=https://github.com/ublue-os/aurora)](https://insights.linuxfoundation.org/project/aurora)

[<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/ublue-os/countme/main/badge-endpoints/aurora.json&label=Weekly%20Device%20Counts&logo=data:image/jpg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBAUEBAYFBQUGBgYHCQ4JCQgICRINDQoOFRIWFhUSFBQXGIocHBweHBodHh0gHR4jIyQrIiAnJSgpNDQ5NDVWXV7/2wBDAQYHBwYIChgQDBwVFh0gHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR7/wgARCAAeACADASIAAhEBAxEB/8QAGwABAQACAwEAAAAAAAAAAAAAAAYDBwECBAX/xAAZAQEAAwEBAAAAAAAAAAAAAAAAAgQFAwH/2gAMAwEAAhADEAAAAeBZwL6c+i84yLq105xYFkLzO9u0k1bJjGqEwP/EACMQAAICAQQCAgMAAAAAAAAAAAQFAwYBAgcACBIQExQxUXH/2gAIAQEAAQUC+z+YfKqX7eN1q+4zC6T6hI12a02Q2d1b7i6Jq6hO1l5nK72jH2Ua3PzZq2l8yFqu1YQv2//8QAIREAAgEBCQAAAAAAAAAAAAAAAQIAAxIEERATITFAUWH/2gAIAQMBAT8BUlHhQ5jN7n2ZcWLzP//EAB4RAQABBAIDAQAAAAAAAAAAAAECAAMQERITICFB/9oACAECAQE/AbfTqZ2D4P1m3kch28R4rO+4T//EACgQAAEDAgUCBwAAAAAAAAAAAAECAwQAEQUSEyAhMQYgMEFRYXGBkf/aAAgBAQAGPwLWl5IU2oKSeYqG+pBKVq93qL6VpWlCgVJ8p51hSVuBxYUpwEEgmpDSk/wBieKjSGFK9Ie1U11x5oKeQG1flHSuU6tSkNoUonwBUfGUPJbfaS2FEAKScxSuK6XUuulTf5SeVf/xAAlEAADAAECBQUBAAAAAAAAAAAAAREhMRBBUWFxIIGRocHR8OH/2gAIAQEAAT8h4gqJ297L3E2EaTf0cWfgV2tU3hPjY8zU0Q2n+pSl/wDJjQkQyFkPItRk2Yg5H8g0Mmmt37ZqVwH6G9bIS2Q1fH2FjC3P3P/2gAMAwEAAgADAAAAEADvMP8A/8QAHxEAAwEAAgICAwAAAAAAAAAAAAERITFBUWGhEHGB/9oACAEDAQE/EGKxHyh9B4m9LzwhR5vB8hJJrP4f/8QAHhEBAQEAAgIDAQEAAAAAAAAAAQARITFBUWFxECBh/9oACAECAQE/EDg+Sg39gv1/eL5X3B331Ljw2d832QxXfRz//xAAkEAEAAgEEAQQDAQAAAAAAAAABESEAMUFRYXEggaGxMJHB0f/aAAgBAQABPxAuJ16V8uA+YqA5x0f695TKEp8wY3R6c/D9YhQO0P4MAQOQkH09Zc5Hh2cK7kM7+MAjN66MBSfJ6d/GCJ7kE/f5jYwKAAoADwYy2EwHkM84Qo1gE+Q/M/9k=">](https://github.com/ublue-os/aurora)

![aurora](https://github.com/user-attachments/assets/269bda65-665a-4232-96e5-b165ab846e9a)

Aurora is a delightful KDE desktop experience for end-users that are looking for reliability and developers for the most-hassle free setup. Zero maintenance included.

- [Download Aurora](https://getaurora.dev)

## Documentation

1. [Discussions and Announcements](https://universal-blue.discourse.group/c/aurora/11) - strongly recommended!
2. [Documentation](https://docs.getaurora.dev/)
3. [Contributing Guide](https://universal-blue.org/contributing.html)
4. [Local Building Guide](https://docs.getaurora.dev/guides/building)

### Secure Boot

Secure Boot is supported by default on our systems, providing an additional layer of security. After the first installation, you will be prompted to enroll the secure boot key in the BIOS.

Enter the password `universalblue`
when prompted to enroll our key.

If this step is not completed during the initial setup, you can manually enroll the key by running the following command in the terminal:

`
ujust enroll-secure-boot-key
`

Secure boot is supported with our custom key. The pub key can be found in the root of the akmods repository [here](https://github.com/ublue-os/akmods/raw/main/certs/public_key.der).
If you'd like to enroll this key prior to installation or rebase, download the key and run the following:

```bash
sudo mokutil --timeout -1
sudo mokutil --import public_key.der
```

## Repobeats

![Alt](https://repobeats.axiom.co/api/embed/c86e98a6654e55f789375ff210dd4eb95f757906.svg "Repobeats analytics image")

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=ublue-os/aurora&type=Date)](https://www.star-history.com/#ublue-os/aurora&Date)
