# Use Alpine base image
FROM alpine:3.7

# Install dependencies
RUN apk add --no-cache perl bash gawk sed grep bc coreutils alpine-sdk xorriso syslinux

# Set workdir
WORKDIR /app