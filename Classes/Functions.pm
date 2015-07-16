package Functions;
use strict;

#fonctions principales, définies à partir du constructeur du même nom
sub Functions {
  my ($class) = @_;

  my $this = {};#pas d'attribut pour la classe en question

  bless ($this , $class);
  return $this;

}

#bannière du serveur FileServer
sub banner {

    my ($class) = @_;

    my $banner_motd = "-" x 100 . "\n\t\t\t\tFileServer by s0bek\n" . "-" x 100 . "\n\n";
    return $banner_motd;

}

#fonction qui trie les données d'un tableau donnée en entrée en sortant un tableau ne contenant les données qu'en un seul exemplaire
sub uniq {

    my ($class , $ref) = @_;

    my @temp = ("" , "user");
    my $length = @{$ref};
    my $temp_length = @temp;
    my $item;
    my $var;

    while ($length > 0) {

        my $value = shift (@{$ref}); #ou splice (@{$ref} , 0 , 1)

        for ($var = 0 , $var < $temp_length , $var++) {

          if ($temp[$var] ne $value ) {
              $temp[$var] = $value;
          }

        }
        $length = @{$ref};
    }

    shift (@temp);
    return @temp;
}

#fonction de suppression de l'ancien fichier de log
sub logdelete {

  my ($class , $logfile) = @_;

  if (-e $logfile) {
      if (`rm -f $logfile`) {
          print "Ancien fichier de log $logfile supprime avec succes.\n\n";
      }
  }

}

#fonction contenant les informations d'utilisation du serveur FileServer pour assister l'utilisateur
sub usage {

    my ($class) = @_;

    my $copy = "Saisir 'upload [FILE]' pour deposer le fichier sur le repertoire distant du serveur.\n";
    my $logged_users = "Saisir 'logged bro?' pour connaitre la liste des utilisateurs actuellement connectes sur le serveur distant.\n";
    my $repository = "Saisir 'my repository' pour connaitre le nom de votre dossier de depot distant.\n";
    my $end = "Saisir 'bye amigo' pour se deconnecter du serveur comme un as!\n";
    my $repeatusage = "Saisir 'usage?' pour reafficher l'aide sur les commandes.\n";

    my $usage = "$copy$logged_users$repository$end$repeatusage\n";
    return $usage;

}

#fonction permettant de tracer dans le fichier de log FileServer.log l'ensemble de l'activité client-serveur
sub logg {

    my ($class , $message) = @_;

    my $logfile = "FileServer.log";
    my $logdate = gmtime();
    my $fh;

    open ($fh , ">>" , $logfile) or die "Impossible d'ouvrir le fichier $logfile pour ecriture\n";
    print $fh  "$logdate:\t$message\n";
    close ($fh);

}

#fonction d'interraction client-serveur
sub command {

    my ($class , $cmd) = @_;
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
                    push (@users , $user);
                }
                $i++

            }
            my @sorted_users = $class -> uniq (\@users);
            $status_cmd = "Utilisateurs actuellement connectes sur le serveur: @sorted_users\n\n";
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

1;
