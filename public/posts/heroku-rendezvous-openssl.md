In this post we are looking into how to run a command on a heroku one-off dyno with curl and consume the rendezvous url over tcp.

## Running a command

If you are familiar with the heroku API, you know that you can easily query it from the shell with curl.

For example, in order to run a rake task, you can do something like this:

```bash
# $1 is your heroku app name, $2 is the command
curl -H "Authorization: Bearer ${HEROKU_OAUTH_TOKEN}" \
         -H "Accept: application/vnd.heroku+json; version=3"  \
         -H "Content-Type: application/json" \
         -d "{\"attach\": true, \"command\" : \"$2\", \"type\" : \"run\"}" \
        "https://api.heroku.com/apps/$1/dynos
```

Heroku API will return you a json object that contains a rendezvous URL.

`{ "attach_url":"rendezvous://rendezvous.runtime.heroku.com:5000/<secret>" ... }`

## Connecting to the rendezvous url

One nice little trick, is to get your command output stream by connecting to the rendezvous url. Since it's a tcp connection with ssl, you can use openssl for that.

```bash
openssl s_client -connect rendezvous.runtime.heroku.com:5000
# Once the connection is established, you can past the <secret> in order to finish the handshake.

# here is a one-liner to do that
(echo "<secret>"; sleep 1) | openssl s_client -connect rendezvous.runtime.heroku.com:5000
```

## Try it out

If you want to try it out, I made a small script that allows for running a command on heroku and meeting at the rendezvous with openssl.

```bash
#!/bin/bash

# args: $1 is the app name, $2 is the command you want to run.

heroku_run() {
  curl -H "Authorization: Bearer ${HEROKU_OAUTH_TOKEN}" \
       -H "Accept: application/vnd.heroku+json; version=3"  \
       -H "Content-Type: application/json" \
       -d "{\"attach\": true, \"command\" : \"$2\", \"type\" : \"run\"}" \
       "https://api.heroku.com/apps/$1/dynos"
}

parse_secret() {
  echo $1 | grep -oe '/heroku\.com\:5000\/([a-z0-9]+)/'
}

rendez_vous() {
  (echo "$1"; sleep 2) | openssl s_client -connect rendezvous.runtime.heroku.com:5000
}

echo "$1> Running $2"
output=$(heroku_run $1 $2)
echo "$1> $output"
secret=$(parse_secret "$output")
echo "$1> Rendez vous... $secret"
rendez_vous $secret
```
