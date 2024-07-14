FROM alpine:3.15

# Copy needed stuff into container
COPY LICENSE README.md /
COPY entrypoint.sh /entrypoint.sh
COPY template.md /template.md
COPY template /template
COPY .chglog /.chglog
COPY main.go /main.go

RUN apk update && \
    apk add --no-cache jq bash git sudo grep findutils go

RUN go install github.com/robertkrimen/godocdown/godocdown@latest && \
    go install github.com/princjef/gomarkdoc/cmd/gomarkdoc@latest

# Start action
ENTRYPOINT ["/entrypoint.sh"]

