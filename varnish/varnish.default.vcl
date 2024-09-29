vcl 4.0;

backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

acl purge {
    "localhost";
    "127.0.0.1";
    "::1";
}

sub vcl_recv {

    unset req.http.proxy;

    # Purge logic
    if(req.method == "PURGE") {
        if(!client.ip ~ purge) {
            return(synth(405,"PURGE not allowed for this IP address"));
        }
        if (req.http.X-Purge-Method == "regex") {
            ban("obj.http.x-url ~ " + req.url + " && obj.http.x-host == " + req.http.host);
            return(synth(200, "Purged"));
        }
        ban("obj.http.x-url == " + req.url + " && obj.http.x-host == " + req.http.host);
        return(synth(200, "Purged"));
    }

    # LetsEncrypt Certbot passthrough
    if (req.url ~ "^/\.well-known/acme-challenge/") {
        return (pass);
    }

    # Blocks
    if (req.http.user-agent ~ "(domaincrawler|dotbot|mj12bot|semrush)") {
        return (synth(204, "Bot blocked"));
    }

    # Forward client's IP to the backend
    if (req.restarts == 0) {
        if (req.http.X-Real-IP) {
            set req.http.X-Forwarded-For = req.http.X-Real-IP;
        } else if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # Normalize the query arguments (but exclude for WordPress' backend)
    if (req.url !~ "wp-admin") {
        set req.url = std.querysort(req.url);
    }

    # Non-RFC2616 or CONNECT which is weird.
    if (
        req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "DELETE"
    ) {
        return (pipe);
    }

    # Si la requête est HTTPS, nous le signalons à WordPress
    if (req.http.X-Forwarded-Proto == "https") {
        set req.http.X-Forwarded-Proto = "https";
        set req.http.X-Forwarded-Port = "443";
    }

    # Ne pas mettre en cache les requêtes des utilisateurs connectés à WordPress ou du tableau de bord
    if (req.http.Cookie ~ "(wp-postpass|wordpress_logged_in|comment_author|woocommerce_items_in_cart)") {
        return (pass);
    }

    # We only deal with GET and HEAD by default
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    if (req.url ~ "/wp-admin/") {
        return (pass);
    }

    if (req.url ~ "/bwa35-login/") {
        return (pass);
    }
    if (req.url ~ "/wp-login.php") {
        return (pass);
    }

    # Traiter les requêtes Ajax WordPress et WooCommerce
    if (req.http.X-Requested-With == "XMLHttpRequest") {
        return (pass);
    }

    # Remove tracking query string parameters associated with analytics/social services, useless for our backend
    if (req.url ~ "(\?|&)(_bta_[a-z]+|cof|cx|fbclid|gclid|ie|mc_[a-z]+|origin|siteurl|utm_[a-z]+|zanpid)=") {
        set req.url = regsuball(req.url, "(_bta_[a-z]+|cof|cx|fbclid|gclid|ie|mc_[a-z]+|origin|siteurl|utm_[a-z]+|zanpid)=[-_A-z0-9+()%.]+&?", "");
        set req.url = regsub(req.url, "[?|&]+$", "");
    }

    # Strip a trailing ? if it exists
    if (req.url ~ "\?$") {
        set req.url = regsub(req.url, "\?$", "");
    }

    # Strip hash, server doesn't need it.
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    if (req.http.X-Logged-In == "False" && req.method != "POST") {
        unset req.http.Cookie;
    }

    # Don't cache HTTP authorization/authentication pages and pages with certain headers or cookies
    if (
        req.http.Authorization ||
        req.http.Authenticate ||
        req.http.X-Logged-In == "True" ||
        req.http.Cookie ~ "userID" ||
        req.http.Cookie ~ "joomla_[a-zA-Z0-9_]+" ||
        req.http.Cookie ~ "(wordpress_[a-zA-Z0-9_]+|wp-postpass|comment_author_[a-zA-Z0-9_]+|woocommerce_cart_hash|woocommerce_items_in_cart|wp_woocommerce_session_[a-zA-Z0-9]+)"
    ) {
        #set req.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set req.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set req.http.Pragma = "no-cache";
        return (pass);
    }

    if (
        req.url ~ "^/addons" ||
        req.url ~ "^/administrator" ||
        req.url ~ "^/cart" ||
        req.url ~ "^/checkout" ||
        req.url ~ "^/component/banners" ||
        req.url ~ "^/component/socialconnect" ||
        req.url ~ "^/component/users" ||
        req.url ~ "^/connect" ||
        req.url ~ "^/contact" ||
        req.url ~ "^/login" ||
        req.url ~ "^/logout" ||
        req.url ~ "^/lost-password" ||
        req.url ~ "^/my-account" ||
        req.url ~ "^/register" ||
        req.url ~ "^/signin" ||
        req.url ~ "^/signup" ||
        req.url ~ "^/wc-api" ||
        req.url ~ "^/wp-admin" ||
        req.url ~ "^/wp-login.php" ||
        req.url ~ "^\?add-to-cart=" ||
        req.url ~ "^\?wc-api="
    ) {
        #set req.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set req.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set req.http.Pragma = "no-cache";
        return (pass);
    }

    # Don't cache ajax requests
    if (req.http.X-Requested-With == "XMLHttpRequest" || req.url ~ "nocache") {
        #set req.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set req.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set req.http.Pragma = "no-cache";
        return (pass);
    }

    # Properly handle different encoding types
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|jpeg|png|gif|gz|tgz|bz2|tbz|mp3|ogg|swf)$") {
            # No point in compressing these
            unset req.http.Accept-Encoding;
        } elseif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elseif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            # unknown algorithm (aka crappy browser)
            unset req.http.Accept-Encoding;
        }
    }

}

# Gérer les réponses
sub vcl_backend_response {

    if (
        beresp.status == 500 ||
        beresp.status == 502 ||
        beresp.status == 503 ||
        beresp.status == 504
    ) {
        return (abandon);
    }

    if (
        bereq.url ~ "^/addons" ||
        bereq.url ~ "^/administrator" ||
        bereq.url ~ "^/cart" ||
        bereq.url ~ "^/checkout" ||
        bereq.url ~ "^/component/banners" ||
        bereq.url ~ "^/component/socialconnect" ||
        bereq.url ~ "^/component/users" ||
        bereq.url ~ "^/connect" ||
        bereq.url ~ "^/contact" ||
        bereq.url ~ "^/login" ||
        bereq.url ~ "^/logout" ||
        bereq.url ~ "^/lost-password" ||
        bereq.url ~ "^/my-account" ||
        bereq.url ~ "^/register" ||
        bereq.url ~ "^/signin" ||
        bereq.url ~ "^/signup" ||
        bereq.url ~ "^/wc-api" ||
        bereq.url ~ "^/wp-admin" ||
        bereq.url ~ "^/wp-login.php" ||
        bereq.url ~ "^\?add-to-cart=" ||
        bereq.url ~ "^\?wc-api="
    ) {
        #set beresp.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set beresp.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set beresp.http.Pragma = "no-cache";
        set beresp.uncacheable = true;
        return (deliver);
    }

    if (
        bereq.http.Authorization ||
        bereq.http.Authenticate ||
        bereq.http.X-Logged-In == "True" ||
        bereq.http.Cookie ~ "userID" ||
        bereq.http.Cookie ~ "joomla_[a-zA-Z0-9_]+" ||
        bereq.http.Cookie ~ "(wordpress_[a-zA-Z0-9_]+|wp-postpass|comment_author_[a-zA-Z0-9_]+|woocommerce_cart_hash|woocommerce_items_in_cart|wp_woocommerce_session_[a-zA-Z0-9]+)"
    ) {
        #set beresp.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set beresp.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set beresp.http.Pragma = "no-cache";
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Unset the "pragma" header (suggested)
    unset beresp.http.Pragma;

    # Unset the "vary" header (suggested)
    unset beresp.http.Vary;

    # Allow stale content, in case the backend goes down
    set beresp.grace = 24h;

    # Ne pas mettre en cache les réponses contenant des cookies d'administration
    if (beresp.http.Set-Cookie ~ "(wp-postpass|wordpress_logged_in|comment_author|woocommerce_items_in_cart)") {
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Définir le TTL par défaut pour les réponses publiques
    set beresp.ttl = 4h;
}

# Gérer la livraison des réponses
sub vcl_deliver {
    # Supprimer les en-têtes pour éviter de montrer les informations internes
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    unset resp.http.Age;
}