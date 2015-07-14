#!/usr/bin/perl -w

use strict;
use Socket;
use IO::Select;

$| = 1;#autoflush

my $protocol = getprotobyname("tcp");
my $port = 7200;
my $address = sockaddr_in ($port , INADDR_ANY);
my $socket;
my $logfile = "FileServer.log";

socket($socket , AF_INET , SOCK_STREAM , $protocol) or die "Impossible de creer le socket de connexion sur le serveur: $!";
bind($socket , $address) or die "Impossible de lier le port et l'adresse à la socket: $!";
listen($socket , SOMAXCONN) or die "Impossible d'ouvrir le port d'écoute sur le serveur local: $!";

print "Le serveur de transfert de fichier est demarre\n";

if (-e $logfile) {

    if (`rm -f $logfile`) {

        print "Ancien fichier de log $logfile supprime avec succes.\n";

    }

}

#fonctions principales

sub banner {

    my $banner_motd = "-" x 100 . "\n\t\t\t\tFileServer by s0bek\n" . "-" x 100 . "\n\n";
    return $banner_motd;

}


sub logg {

    my ($message) = @_;
    my $logdate = gmtime();
    my $fh;

    open ($fh , ">>" , $logfile) or die "Impossible d'ouvrir le fichier $logfile pour ecriture\n";
    print $fh  "$logdate:\t$message\n";
    close ($fh);

}

sub usage {

    my $copy = "Saisir 'upload [FILE]' pour deposer le fichier sur le repertoire distant du serveur.\n";
    my $logged_users = "Saisir 'logged bro?' pour connaitre la liste des utilisateurs actuellement connectes sur le serveur distant.\n";
    my $repository = "Saisir 'my repository' pour connaitre le nom de votre dossier de depot distant.\n";
    my $end = "Saisir 'bye amigo' pour se deconnecter du serveur comme un as!\n";
    my $repeatusage = "Saisir 'usage?' pour reafficher l'aide sur les commandes.\n";

    my $usage = "$copy$logged_users$repository$end$repeatusage\n";
    return $usage;

}

sub uniq {
    my ($ref) = @_;
    my @temp;
    my $length = @{$ref};
    my $temp_length = @temp;
    #my $first = @{$ref}[0];
    my $item;
    my $var;

    while ($length > 0) {

        my $value = splice (@{$ref} , 0 , 1);

        for ($var = 0 , $var < $temp_length , $var++) {

            if ($value ne 0) {

                if ($temp[$var] ne $value) {
                    $temp[$var] = $value;
                }

            }

        }
        $length = @{$ref};
    }

    print "Valeurs contenues dans temp: @temp\n";
    return @temp;
}

sub command {

    my ($cmd) = @_;
    my $status_cmd = "";

    if ($cmd ne "") {

        if ($cmd =~ m/usage\?/) {
            $status_cmd = "usage";
        }

        if ($cmd =~ m!logged\ bro!) {
            my @cmd_result = `w`;

            my $i = 1;
            my @users;
            my $item;
            foreach (@cmd_result) {

                unless ($i <= 2) {
                    my $user = (split(" "))[0];
                    #print "Utilisateur: $user\n";

                    push (@users , $user);
                }
                $i++

            }
            my @sorted_users;
            @sorted_users = uniq (\@users);
            print "Ensemble des utilisateurs connectes actuellement sur le systeme: @sorted_users\n";
            #print @cmd_result;
            $status_cmd = join ("" , @cmd_result);
        }

        if ($cmd =~ m/bye\ amigo/) {
            $status_cmd = "close";
        }

        #commande cachée pour cloturer la socket serveur
        if ($cmd =~ m/discloz/) {
            $status_cmd = "discloz";
        }

    }

    return $status_cmd;
}

logg ("Le serveur a bien ete demarre sur le port $port");

#corps principal du code
my $pipe = IO::Select->new();
$pipe->add ($socket);

while (1) {

    my @clients = $pipe->can_read(0);#on active le pipe pour y stocker les connexions clientes
    my $client_pipe;
    foreach $client_pipe (@clients) {

        if ($client_pipe == $socket) {

            my $client;
            my $client_address = accept ($client , $socket);

            my ($client_port , $iaddr) = sockaddr_in ($client_address);
            my $client_hostname = gethostbyaddr ($iaddr , AF_INET);

            my $message = "Nouvelle connexion cliente etablie";
            $message = "$message $client_hostname connecte depuis le port distant $client_port\n";

            print $message;
            logg ($message);

            #envoi d'un message au client
            my $header = banner ();
            send ($client , $header , 0);
            send ($client , "Bonjour maitre que puis-je faire pour vous aujourd'hui?\n\n" , 0);
            my $usage = usage ();
            send ($client , $usage , 0);

            $pipe->add ($client);

        } else {

            #reception des donnees clientes
            my $reception;
            my $cmd;
            while ($reception = <$client_pipe>) {

                chomp $reception;
                #print "\nMessage recu du client: $reception.\n";

                #traitement de la reponse ou commande client
                #repeter usage en tout premier lieu si l'utilisateur ne se souvient plus des commandes serveur
                $cmd = command ($reception);

                if ($cmd eq "usage") {
                    my $usage = usage ();
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
