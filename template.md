# {{ .Name }}
{{ if not .IsCommand  }} 

[![GoDoc](https://godoc.org/github.com/atomicgo/{{ .Name }}?status.svg)](https://godoc.org/github.com/atomicgo/{{ .Name }})

> {{ .EmitSynopsis }}

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