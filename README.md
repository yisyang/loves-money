# loves.money #

A domain / email forwarder built on a personal toy framework called CarCrashJS.

While the toy framework supports having multiple subdomains (UI, API) within the same project, the
approach is not recommended in production as it goes against the micro-services approach and makes
designing a self-scaling infrastructure more difficult.

Live site is located at http://loves.money

### Notes on installation

Should you wish to use the server on your domain, there are a couple of things that you should take
care of beyond mere cloning.

1. configure mail server to use mysql, or some other database

2. then configure this app to insert aliases into the database used by the mail server

3. add SSL as appropriate

4. (if using apache), add this line somewhere for the api config:

        Header merge Access-Control-Allow-Headers "Authorization"

5. npm install -g browserify pm2

6. npm install

7. npm run browserify

8. npm start

9. use "pm2 list" to check that everything is running, and "pm2 startup" to make server persistent through restarts