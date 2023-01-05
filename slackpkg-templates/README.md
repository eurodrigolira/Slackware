## Templates para o Slackpkg

Para poder usar esses templates é necessário fazer a instalação do slackpkg+,
você pode obter mais informações no post abaixo:

- https://alien.slackbook.org/blog/introducing-slackpkg-an-extension-to-slackpkg-for-3rd-party-repositories/

Configure os seguintes repositórios no /etc/slackpkg/slackpkgplus.conf

```sh
MIRRORPLUS['alienbob']=https://slackware.nl/people/alien/sbrepos/current/x86_64
MIRRORPLUS['slackers']=https://slack.conraid.net/repository/slackware64-current/
```

- https://slackpkg.org/
- https://docs.slackware.com/slackware:slackpkg
