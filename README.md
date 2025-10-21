# Aurora

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/a940189170c8456c85a75ea36edb32c7)](https://app.codacy.com/gh/ublue-os/aurora/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Stable Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-stable.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-stable.yml) [![Latest Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-main.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-main.yml) [![Latest Images HWE](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-hwe.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-latest-hwe.yml) [![Beta Images](https://github.com/ublue-os/aurora/actions/workflows/build-image-beta.yml/badge.svg)](https://github.com/ublue-os/aurora/actions/workflows/build-image-beta.yml) [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ublue-os/aurora-docs) 

[![LFX Active Contributors](https://insights.linuxfoundation.org/api/badge/active-contributors?project=aurora&repos=https://github.com/ublue-os/aurora)](https://insights.linuxfoundation.org/project/aurora)

[<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/ublue-os/countme/main/badge-endpoints/aurora.json&label=Weekly%20Device%20Counts&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAdCAYAAADLnm6HAAAABGdBTUEAALGPC%2FxhBQAAAAFzUkdCAdnJLH8AAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAuIwAALiMBeKU%2FdgAAAAd0SU1FB%2BkHDxYYCm25gikAAAR4SURBVEjHvVVpbFRlFD33e8t0CUKAIcGUxbTW1CAhMVFE1BqQ2haQHwwlSNmCJQRUIIW2aGFskdpWQWhCrRYVAkpmgli6IFARUBJM%2FKESQY0kYDRQEC20bwbe8l1%2FtNPOlO7J9P67753ce%2B65y0cYoL31QtnCoBRFrVKZYLA4HrTEqkPnXr2GQZoYCLgsbft0Ah8A4WEi6ASawwJHAC8NCQEFeJuIlPBvBHoy42n3vKgTqEwvmgaiZ7sNwsLr8XhEVAkQlNww97RjmylgGABAhMnBmzPnR41AdZo3kcFzQz7DfnPP2bxfJaGy4xvT1sGooPYHpKu0wWZSwADA35c25p8DANtx3gPEGgCxRHg0%2BF9aFuD%2FvD8x5xaemSKIZvY5vb70gtH3ROxVg5U4Qwq0SiVr64lNvtD%2FrGcqdgWk%2BhprCkhTL8WMODbJ7%2FfLbpNuOjlWcbkWsSKWEDAZzL%2F1qYDQtDWQiAMDDL7y960%2FvoicDbMcrK4C4AKQEmzNiFAhPX23rk6Y%2BJLQ9eUgZRaIlFDVTLB6VaBqdk7saDH2akAqbkMqaHFow8bjm3d2xc2eVlkFXckhTQV0canFuPLYcHdSstRcK0nXsilGdZNLA2I0kEsDBLXPEn%2FXqwLjNPeSoIS73b3jOLf3dodzYJUqUFa0zRSlDBuedJGhJhMBuK9EvsXAEUD6mvHNqR4JeFNTFQLldk45qvMbS%2B90C76BvzgB5wmY3tYXSo7MyTYD9XC4Wrt0%2Fbjfv8DqcwtSRz417y5TUptUsO%2Bxtbsr5uUnvMMcfeTaVqmtBfDgfbUCl8HYC0t%2BerQq7dqA1lABNnQWwL51X3mvhvz1U9fHmLEJq4OsFgQc4SZC24Z24k%2BxlDtjzcMN%2FoPdb0SvBH5YnP9cMEjTOqJKuxwAch7PURNGJS0PSLHFliIBTOFJTTA%2Bk8zvN9Qs%2FgkAMhcdHAH4mwd8CYUicsMin1h6rPjHPS9um%2F%2BIe%2BJFAj4EkBAGNxlcaUknsa5xxfL4%2BPoLmXP3z5%2FjOXRWQLsw1eOLGZACP68vnGT9KzNDokpG7f7MosYA0wxICu%2Bvzcz7YNnFdefXdbTnbvOs8RQnDhKggwhj4tXVAHb2WwFdVfIobHkEYRcRZkQONZ%2BxpT3lkzOvrzwUlhwAak%2B%2BcoWAjzqwRPmpHl98vwhcLitOIsbCyGeQRFjm61JydunXxvMfnN74S09BHcsuZnBL26XEmAdGxS3rFwGd8Aaoh81gruN75qStjXkHAC%2F31teGhmVNxFTBzN%2BCeQXMpn09P%2FPt1vRxyUPmLef3wA1bNW5YMFoZhlRgOMIKOErB5Xq5w9tH4sFYR7UKoZC6DiWzKZk92fVbjiJKJgDgdk1JIoGyuwyaKYEFntqiqCXvIKCrWh6F9Z4BloQFGV9uq0GUTQRPvjOOiJZ2OeI7Ug%2BXRD05AAhd1T0E6GHVX2y6eWczhsgECaRH7DDLgoxjFeaQEZCO3APwn6Fb5H9X1GIIjQDg%2Bv7yOM2xc41%2FbHv8xsLtQ0ngf4pt0%2FfhCzpDAAAAAElFTkSuQmCC%0A">](https://github.com/ublue-os/aurora)

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
