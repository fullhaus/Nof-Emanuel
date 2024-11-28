# Nof-Emanuel project benchmark tools(TODO)

## Install Apache Bench tool for MAC and run

```shell
$ brew install httpd
```

```shell
ab -n 1000 -c 100 https://web.nof-emanuel.dev/
```

## Install hey tool for MAC and run

```shell
$ brew install hey
```

```shell
hey -z 30s -c 100 https://web.nof-emanuel.dev/
```