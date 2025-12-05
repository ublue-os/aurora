# Aurora

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/a940189170c8456c85a75ea36edb32c7)](https://app.codacy.com/gh/ublue-os/aurora/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Stable Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-stable.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-stable.yml) [![Latest Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-main.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-main.yml) [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ublue-os/aurora-docs)

[![LFX Active Contributors](https://insights.linuxfoundation.org/api/badge/active-contributors?project=aurora&repos=https://github.com/ublue-os/aurora)](https://insights.linuxfoundation.org/project/aurora)

[<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/ublue-os/countme/main/badge-endpoints/aurora.json&label=Weekly%20Device%20Counts&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUEAYAAADdGcFOAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAAAAAAAAPlDu38AAAAJcEhZcwAAAGAAAABgAPBrQs8AAAAHdElNRQfpChkXJy/yQ9qXAAAIXElEQVRIx7XV+X+NVx4H8M85z3Ofu2UTERFJhSBCaJkRSQUT2lcIJtbWGhISNXTTKUWattaIoEpriz2UDqKpIRFDooitsUVQWzZpNEaT3OTe+9znOef0h1n6AzM6M+b7B3xf7+95fc/nS/Ccq5NjRtgNE+DXzxJdUwgJFAZwMFggwQ5Agw4DAAINgBEUIWBQ4YFGNABwwQYFQC+E4BxAnzewdYhie3ALlNwV+SIYzBVsSlLuEjexiawhSS3MIooEkFOGHWDIB4UKikZwaTNcUKFYRqMOLeFlqIVFxMAOSM8LFrNghkfuhwDbKY2TJkJQPz5Q1ACSByvjDSPDyO9hEjlbZZwQ1YhWf8JeomBM2Vio8IKxx/sQ0EH6fQ0P1MD22mlUkW8Q6B7zPwMH50ytOjQUkBQ9j7lgRDRpiwIwtMVQlEWMIdUiW/hv/IlkiyKM6HidnuDdRP9qHy7L5RLLnkauog26Vf9WuOgKYrySR4NYpiiX36T5vLt4dXmS/N/Chg2Jr8jOAfhOvZw54cYuGoZJPdFIF+uj+Pygh+QG3S9CV10Us4iNrAyKxT5swSgARWQEXhaZklGfzpiuabrxE4OMs8a7dpMaDAgnqSMmKUskEh+yxfft/xg4fv5rw7KWAJpTK3X5wORyUxKUYjTyD5g7HehZJqXz9uzj9BwxmfiTbRFTsYTswDx7J+TjDF613BRncY5EgNLV/B5/DzDmNN1RRwBMk2dJJDhT7KePych5ScKfxpHqc5m/Gji1Y5zPpjJAr9Re16MgsQyiSTfhlHfpRH/ZALqU/8i3ze/E55LLNGW0Q3iSWvLo2nDsIh1I4skeaIPNonwGxDm0Jr1FveWqM9CRCthNpkiztZdJ2sMcbNLqmaKBLyUent1FKdVJ5xnDfzVQmetK1kJB2HjjAWkmmKVUveW4DrjSuVUpmPIpKyJXaMXbhaKI2EnyI18+gfpKm2dtID4IFeyFWBGDlfgJwFuIJuc89vDzJJ7EzixVQrXlWuFcH1ZAq+hFG+cbqIWOSj4rcmkxGfqdN3kWLOXwwPfSUoCKCZS2FIBnezrbrgLO7dAM0YPa8RNSJ2nsDlncJoK08+jOt5FyOuituYYeLF0L2/CSa4Bcq8QnBWAFJuHdjZViMPmUHLSv4itIKJkql/AM6qSTjkcxnSZLP8w56hqu9FG2Xt2D5fgdBv2bmPm0OnbpvNuAQhCpL4DV0F1U62XQRCprgYRukVKtyOORmw7IL/FiprT5iAZwb16QvstUoIWqe9c3GfbrXfWtUdmSzL9jYvpZaQQbw863HStF8VPsek0SbS76CdcyF70orKL3vHmsm9RZCi+fzDpLNdJwgL7Ek8QckCeCOusPQ1JnngHcBMlzFMJKJ+IVYUaTWxW541jaKsbjMfGzm1dO8bwP2uQZ2t7zKxHRZC8Y2yKIT6nTK+I8s3CsKXGXr2UdSVKVQ4GWQL7Dee83zUxDdTf14435Ri8tw5UxctKDNO86/yPpBYjFVfGXupYm4Vri7A2LlTiG2IuB/ZG7+o46CfHPHcyrHu6YfAFwDNZuOUKgsOPwp0vRZP2caI4dluvKAgRrbotMejsyRPpiQDuxEhXkjMgXCaIeczunMG9coGPWxrPF+LO0zHlTi4ddCj/oz/zETRqx5w3D9zSGzQ++xIrEYToi8vFV/xtDtDYX/DoM9Mqo/Bo19/ca41rdhn1bUHZcwr5fHoy8+UXvV3q/AozObV/X5QBoQ+v6QzwNXJ1a61Y/gYa4JK/TPufnJeiVqJG6fbJdrIKLBNFS3gp36ERA34kjdFrNh3qM2CaPP+xwzcYyqWHHZ1iHRyT12/7UH3143OvX9URkS2t2V/J3RDEt2XjUaCExmjYtxumNY4bdwHu7D2NR2JOrJicP6hfRKxGou1Y9u+ksuPvqZnZDT0DJlZe5+46drh/SJ6uD5wzmJWItidZkvQu/TNRz27TRIlpSjhzX8sVlqcWhGnMnmm7bXPp55XBe12IhX+E2lrg5eiFPWgvKTe7p7COEUhvAO5IwWsu/NFciQP0SsP+IvkY/AMDJp/0Fucu6/kEBVsglrY8lVdZAVyvsB/Wv+hxWchQfkpVm5Uf1Oj7Bslh3qWvYZx9mOw111xyNq4tsPVDa7HZTAuVw8DVA/RvigLUrOnp9Rjo0DoJsDSJBzgropATuWCAms8vQaDHA3oaNtoFsjSDfOV8E6Ae8TIQDOAaPpwIfdCvt+zgSujXRC8ad7b9Xisz1cujq42yQfpGHB0xjW1yBfOeGRVqs2p/dW5kLnZwk452dzfNrWEMcYAo0TSaTQLRF4rbcFcLb1/sFeh+644btit4DIPeRhnH0EDvObYhCAnvIw0kmTbMGGS7pf0SmWOTSnEf+rmnzFKA7fALMy1q1VoOaTmu+GX21VHUcC299SX/R9Q5P3eRibtp5di11mtqp6aye4oxkJzSVl8DSqloZSRtg752yma1fCPGPhoX58UgGoOQY10jbAeSSm5hwvaM0UjfwnplTWK2WzEcX/mBY755lygMMgXU9tTUA+jw97mSl2GyQb74aRMLpEaQWZkneynnqNv80zZXK6cJbtschVd0bZ+kJ8hAlnfaCu8XpNUKZAFtY42K2Ngz/sh6+e9dWnwAJIYjEt6ei+G3+gmh2CnytALEA5sqGng9dIE2x3raAR78M+CSwyhIsl/9pYMPs2ouOZEdbOVEZRqMA1dGYrDUH3C/4LDeXQNbiHQXaMtg6rkwZkG5+9mlstSIkxouBwYP8SPYDfJSWw+8DeqFm4H8F3Pc1f7+FA6JhXO14R+DfbsNTG2n3c5My7gHOJTnV6UsA1e+bovQHII2r9h1JS3w25P9dPwNP7+Z3Ffvw8wAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0xMC0yNVQxMDo0MjoxNCswMDowMJ3RgeEAAAAldEVYdGRhdGU6bW9kaWZ5ADE5NzAtMDEtMDFUMDA6MDA6MDArMDA6MDD5oWsKAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI1LTEwLTI1VDIzOjM5OjQ3KzAwOjAw0uGrGgAAAABJRU5ErkJggg==">](https://github.com/ublue-os/aurora)

![aurora](https://github.com/user-attachments/assets/269bda65-665a-4232-96e5-b165ab846e9a)

Aurora is a delightful KDE desktop experience for end-users that are looking for reliability and developers for the most-hassle free setup. Zero maintenance included.

- [Download Aurora](https://getaurora.dev)

## Documentation

1. [Discussions and Announcements](https://universal-blue.discourse.group/c/aurora/11) - strongly recommended!
2. [Documentation](https://docs.getaurora.dev/)
3. [Contributing Guide](https://universal-blue.org/contributing.html)
4. [Local Building Guide](https://docs.getaurora.dev/guides/building)

The `system_files`, `flatpak` and `logos` directory have been moved to https://github.com/get-aurora-dev/common.

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
