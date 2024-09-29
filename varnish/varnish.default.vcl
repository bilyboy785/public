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

    # Si la requête est HTTPS, nous le signalons à WordPress
    if (req.http.X-Forwarded-Proto == "https") {
        set req.http.X-Forwarded-Proto = "https";
        set req.http.X-Forwarded-Port = "443";
    }

    # Ne pas mettre en cache les requêtes des utilisateurs connectés à WordPress ou du tableau de bord
    if (req.http.Cookie ~ "(wp-postpass|wordpress_logged_in|comment_author|woocommerce_items_in_cart)") {
        return (pass);
    }

    # Ne pas mettre en cache les requêtes POST
    if (req.method == "POST") {
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

    # Pour tout le reste, utiliser le cache
}

# Gérer les réponses
sub vcl_backend_response {
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