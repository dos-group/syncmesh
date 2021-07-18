FROM golang:1.16-alpine

WORKDIR /app

# copy mod files
COPY go.mod .
COPY go.sum .

# download mod files
RUN go mod download

# copy go files
COPY *.go .

# compile listener
RUN go build -o /listener
# run the script
CMD ["/listener"]


