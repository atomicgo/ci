# {{ .Name }}

<a href="https://codecov.io/gh/atomicgo/{{ .Name }}">
<img src="https://img.shields.io/codecov/c/gh/atomicgo/{{ .Name }}?color=magenta&logo=codecov&style=flat-square" alt="Coverage">
</a>

{{ if not .IsCommand  }} 

---

<p align="center">
<strong><a href="#install">Get The Module</a></strong>
|
<strong><a href="https://godoc.org/github.com/atomicgo/{{ .Name }}">Documentation</a></strong>
|
<strong><a href="./CONTRIBUTING.md">Contributing</a></strong>
</p>

---

{{ .EmitSynopsis }}

## Install

```console
go get -u github.com/atomicgo/{{ .Name }}
```

## Import

```go
import "github.com/atomicgo/{{ .Name }}"
```

{{ .EmitUsage }}

{{ else }}

## Install

```console
go get -u github.com/atomicgo/{{ .Name }}
```

## Usage

```console
{{ .Name }} -help
```

{{ end }}