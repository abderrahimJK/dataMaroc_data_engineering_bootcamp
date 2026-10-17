FROM alpine:3.14
RUN apk add --no-cache bash gawk coreutils
WORKDIR /app
COPY process_sales.sh /app
RUN chmod +x process_sales.sh
CMD ["sh", "-c", "while true; do ./process_sales.sh; sleep 10; done"]
