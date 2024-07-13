# Use latest alpine image as base
FROM alpine:latest

# Copy needed stuff into container
COPY LICENSE README.md /
COPY entrypoint.sh /entrypoint.sh
COPY template.md /template.md
COPY template /template
COPY .chglog /.chglog
COPY main.go /main.go

# Update packages
RUN apk update

# Install some packages
RUN apk add jq bash git sudo
RUN apk add --no-cache --upgrade grep
RUN apk --no-cache add findutils
RUN apk add go --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

RUN go install github.com/robertkrimen/godocdown/godocdown@latest
RUN go install github.com/princjef/gomarkdoc/cmd/gomarkdoc@latest

# Start action
ENTRYPOINT ["/entrypoint.sh"]
