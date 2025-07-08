# Aurora

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/a940189170c8456c85a75ea36edb32c7)](https://app.codacy.com/gh/ublue-os/aurora/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
![Aurora Users](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/ublue-os/countme/main/badge-endpoints/aurora.json&color=9b59b6)
[![Stable Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-stable.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-stable.yml) [![Latest Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-main.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-main.yml) [![Latest Images HWE](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-hwe.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-hwe.yml) <!--[![Beta Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-beta.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-beta.yml)--> [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ublue-os/aurora) 


![aurora](https://github.com/user-attachments/assets/2b36fa23-0122-4cba-bc8f-87026c84b909)


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
