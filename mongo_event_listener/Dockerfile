FROM golang:1.16-alpine

WORKDIR /app

# change mongodb url to mongodb instead of localhost TODO: this does not work yet, find correct namespace/url in deployment
ENV mongo_url="openfaas-db-mongodb/?directConnection=true"

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


