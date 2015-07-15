#!/usr/bin/perl -w

use strict;
use Socket;
use IO::Select;
use Classes::Functions;

$| = 1;#autoflush

my $protocol = getprotobyname ("tcp");
my $port = 7200;
my $address = sockaddr_in ($port , INADDR_ANY);
my $socket;
my $logfile = "FileServer.log";

socket($socket , AF_INET , SOCK_STREAM , $protocol) or die "Impossible de creer le socket de connexion sur le serveur: $!";
bind($socket , $address) or die "Impossible de lier le port et l'adresse à la socket: $!";
listen($socket , SOMAXCONN) or die "Impossible d'ouvrir le port d'écoute sur le serveur local: $!";

print "Le serveur de transfert de fichier est demarre\n";

#utilisation des fonctions de la classe appropriée
my $Functions = Functions -> Functions();

#suppression de l'ancien fichier de log au démarrage du serveur
$Functions -> logdelete ($logfile);

# logg ("Le serveur a bien ete demarre sur le port $port");
$Functions -> logg ("Le serveur a bien ete demarre sur le port $port");

#corps principal du code
my $pipe = IO::Select -> new();
$pipe-> add ($socket);

while (1) {

    my @clients = $pipe -> can_read(0);#on active le pipe pour y stocker les connexions clientes
    my $client_pipe;
    foreach $client_pipe (@clients) {

        if ($client_pipe == $socket) {

            my $client;
            my $client_address = accept ($client , $socket);

            my ($client_port , $iaddr) = sockaddr_in ($client_address);
            my $client_hostname = gethostbyaddr ($iaddr , AF_INET);

            my $message = "Nouvelle connexion cliente etablie";
            $message = "$message $client_hostname connecte depuis le port distant $client_port\n";

            # print $message;

            $Functions -> logg ($message);
            my $header = $Functions -> banner();
            send ($client , $header , 0);
            send ($client , "Bonjour maitre que puis-je faire pour vous aujourd'hui?\n\n" , 0);
            # my $usage = usage ();
            my $usage = $Functions -> usage();
            send ($client , $usage , 0);

            $pipe -> add ($client);

        } else {

            #reception des donnees clientes
            my $reception;
            # my $cmd;

            while ($reception = <$client_pipe>) {

                chomp $reception;

                #traitement de la reponse ou commande client

                # $cmd = command ($reception);
                my $cmd = $Functions -> command ($reception);

                if ($cmd eq "usage") {
                    # my $usage = usage ();
                    my $usage = $Functions -> usage();
                    send ($client_pipe , $usage , 0);
                }

                if ($cmd eq "close") {
                    send ($client_pipe , "Ravi d'avoir pu servir maitre!\n" , 0);
                    send ($client_pipe , "quit" , 0);
                    #$pipe->delete ($client);
                }

                if ($cmd eq "discloz") {
                    #close ($client_pipe);
                    close ($socket);
                    exit (0);
                }

            }

        }

    }

}

close ($socket);
exit (0);
