# Use latest alpine image as base
FROM alpine:latest

# Copy needed stuff into container
COPY LICENSE README.md /
COPY entrypoint.sh /entrypoint.sh
COPY template.md /template.md
COPY .chglog /.chglog
COPY main.go /main.go

# Install some packages
RUN apk add jq bash git go sudo
RUN apk add --no-cache --upgrade grep
RUN apk --no-cache add findutils

# Start action
ENTRYPOINT ["/entrypoint.sh"]
