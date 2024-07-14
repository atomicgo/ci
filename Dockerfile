FROM golang:alpine

# Copy needed stuff into container
COPY LICENSE README.md /
COPY entrypoint.sh /entrypoint.sh
COPY template /template
COPY main.go /main.go

RUN apk update && \
  apk add jq bash git sudo grep findutils

RUN go install github.com/robertkrimen/godocdown/godocdown@latest && \
  go install github.com/princjef/gomarkdoc/cmd/gomarkdoc@latest

# Start action
ENTRYPOINT ["/entrypoint.sh"]

