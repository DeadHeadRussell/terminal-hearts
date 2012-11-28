#!/usr/bin/perl

package DECK;
  sub new
  {
    my ($class) = shift;
    
    my (@d);
    my (@suits) = ("C", "D", "S", "H");
    my (@cards) = ("A", 2..10, "J", "Q", "K");
    
    foreach my $suit (@suits)
    {
      foreach my $card (@cards)
      {
        push @d, ($card.$suit);
      }
    }
    
    return bless [@d], $class;
  }
  
  sub getdeck
  {
    my (@d) = @{$_[0]};
    return @d;
  }
  
  sub shuffle
  {
    my @t = @{$_[0]};
    my ($t,$r,@d);    
    while (scalar(@t) > 0)
    {
        $r = int(rand scalar(@t));
        $t = $t[$r];
        splice @t, $r, 1;
        push (@d, $t);
    }
    $_[0] = bless [@d], DECK;
  }
## END DECK

package PLAYER;
  sub new
  {
    $class = shift;
    $ai = shift;
    return bless {"AI" => $ai, "SCORE" => 0}, $class;
  }

  sub addToScore
  {
    my $p = \shift;
    my $score = shift;
    $$p->{'SCORE'} += $score;
  }

  sub moveh
  {
    my $c = $_[0];
    my $suit = $_[1];
    my $first = $_[2];
    my $broken = $_[3];
    if($suit == -1)
    {
      if($first == 1)
      {
        return 1 if($c eq "2C");
      }
      else
      {
        return 1 if($broken == 1 or $c =~ /[^H]$/);
      } 
    }
    elsif($suit == 1)
    {
      if($first == 1)
      {
        return 1 if($c =~ /[^H]$/ and $c ne "QS");
      }
      else
      {
        return 1;
      }
    }
    else
    {
      return 1 if($c =~ /$suit/);
    }
    return 0;
  }

  sub move
  {
    my (%data) = %{$_[0]};
    my ($hand) = $data{"HAND"};
    my (@hand) = @{$hand};
    my ($card);
    my $pos = -1;
    my $suit = $_[1];
    my $first = $_[2];
    my $broken = $_[3];

    my $temp = 0;
    my $hearts = 1;
    for $h (@hand)
    {
      $hearts = 0 if($h !~ /H$/);
      if($h =~ /$suit/)
      {
        $temp = 1;
        last;
      }
    }
    if((!$temp and $suit != -1) or $hearts)
    {
      $suit = 1;
    }  
    
    if ($data{"AI"})
    {
      if(!($first == 1 && $suit == -1))
      {
        $pos = int(rand(scalar(@hand)));
        $card = $hand[$pos];
        until (PLAYER::moveh($card, $suit, $first, $broken))
        {
          $pos = int(rand(scalar(@hand)));
          $card = $hand[$pos];
        }
      }
      else
      {
        $pos = 0;
        $card = "2C";
      }
      print $card."\n";
    }
    else
    {
      my $valid = 0;
      until ($valid)
      {
        $pos = -1;
        $in = <STDIN>;
        chomp $in;
        if ($in =~ /^([qe]|quit|exit)$/i)
        {
          return -1;
        }
        foreach my $c (@hand)
        {
          $pos++;
          $valid = 1 if ($in eq $c and PLAYER::moveh($c, $suit, $first, $broken));
          last if $valid;
        }
        print "INVALID MOVE!: " if !$valid;
      }
      $card = $in;
    }

    splice (@hand, $pos, 1);
    $_[0]->{"HAND"} = [@hand];
    return $card;
  }
  
  sub addToHand
  {
    my ($p) = \$_[0];
    my ($c) = $_[1];
    my ($hand) = $$p->{"HAND"};
    my (@hand) = @{$hand};
    push (@hand, $c);
    $$p->{"HAND"} = [@hand];
  }

  sub addCards
  {
    my @cs = ($_[1], $_[2], $_[3]);
    foreach $c (@cs)
    {
      $_[0]->addToHand($c);
    }
    $_[0]->sortHand;
  }

  sub chsRndSelCards
  {
    $hand = $_[0]->{"HAND"};
    @hand = @{$hand};
    my @selCards = ();
    $pos = int(rand(scalar(@hand)));
    push (@selCards, $hand[$pos]);
    splice (@hand, $pos, 1);
    $pos = int(rand(scalar(@hand)));
    push (@selCards, $hand[$pos]);
    splice (@hand, $pos, 1);
    $pos = int(rand(scalar(@hand)));
    push (@selCards, $hand[$pos]);
    splice (@hand, $pos, 1);
    $_[0]->{"HAND"} = [@hand];
    return @selCards;
  }

  sub rmCards
  {
    my $p = \$_[0];
    my @cards = ($_[1], $_[2], $_[3]);
    my $hand = $$p->{"HAND"};
    my @hand = @{$hand};
    foreach $c (@cards)
    {
      $pos = 0;
      chomp($c);
      foreach $h (@hand)
      {
        if($c eq $h)
        {
          splice (@hand, $pos, 1);
          last;
        }
        else
        {
          $pos++;
        }
      }
      print "\n";
    }
    $$p->{"HAND"} = [@hand];
  }
 
  sub cardVal
  {
    my ($s1) = shift;
    my ($val);
    $val = 10 if $s1 =~ /J./;
    $val = 11 if $s1 =~ /Q./;
    $val = 12 if $s1 =~ /K./;
    $val = ($1-2) if $s1 =~ /([0-9]+)./;
    $val = 13 if $s1 =~ /A./;
    $val += 13 if $s1 =~ /.D/;
    $val += 26 if $s1 =~ /.S/;
    $val += 39 if $s1 =~ /.H/;
    return $val;
  }
  
  sub sortHand
  {
    my ($p) = \$_[0];
    my ($hand) = $$p->{"HAND"};
    my (@hand) = @{$hand};
    $hand = [sort {cardVal($a) <=> cardVal($b)} @hand];
    $$p->{"HAND"} = $hand;
  }

  sub containsCard
  {
    my $p = shift;
    my $c = shift;
    chomp $c;
    my $hand = $p->{"HAND"};
    my @hand = @{$hand};
    foreach $h (@hand)
    {
      return 1 if($h eq $c);
    }
    return 0;
  }
## END PLAYER

package GAME;
  sub new
  {
    my ($class) = shift;
    $deck = DECK->new;
    $P1 = PLAYER->new (0);
    $P2 = PLAYER->new (1);
    $P3 = PLAYER->new (1);
    $P4 = PLAYER->new (1);
    return bless {"DECK" => $deck, "P1" => $P1, "P2" => $P2, "P3" => $P3, "P4" => $P4, "dealt" => 0, "round" => -1, "current" => 1}, $class;
  }
  
  sub get
  {
    my ($g) = $_[0];
    if($_[1] == "DECK")
    {
      my ($d) = $g->{"DECK"};
      if($d == 0)
      {
        return 0;
      }
      else
      { 
        my (@d) = $d->getdeck;
        return @d;
      }
    }
    elsif($_[1] == "P1HAND")
    {
      my ($p) = $g->{"P1"};
      my $h = $p->{"HAND"};
      return $h;
    }
    else
    {
      return "";
    }
  }
  
  sub shuffleDeck
  {
    my ($g) = \$_[0];
    if ($$g->{"DECK"} == 0)
    {
       my ($dtemp) = DECK->new;
       $$g->{"DECK"} = $dtemp;
    }
    my ($d) = \$$g->{"DECK"};
    $$d->shuffle;
  }

  sub deal
  {
    my ($g) = \$_[0];
    my (@d) = $$g->get("DECK");
    my ($P1) = \$$g->{"P1"};
    my ($P2) = \$$g->{"P2"};
    my ($P3) = \$$g->{"P3"};
    my ($P4) = \$$g->{"P4"}; 
    while  (scalar @d > 0)
    {
      $$P1->addToHand (shift (@d));
      $$P2->addToHand (shift (@d));
      $$P3->addToHand (shift (@d));
      $$P4->addToHand (shift (@d));
    }
    $$P1->sortHand;
    $$P2->sortHand;
    $$P3->sortHand;
    $$P4->sortHand;
    $$g->{"DECK"} = 0;
  }
  
  sub winnerRound
  {
    my $g = \shift;
    shift;
    @cards = ($_[0], $_[1], $_[2], $_[3]);
    $_[$$g->{"current"} - 1] =~ /([CDHS])$/;
    my $c = $1;
    my $high = -1;
    my $p = -1;
    for(my $i = 0; $i < 4; $i++)
    {
      $_[$i] =~ /^([0-9AJQK]+([CDSH]))$/;
      if($2 eq $c)
      {
        if(PLAYER::cardVal($1) > PLAYER::cardVal($high))
        {
          $high = $1;
          $p = $i;
        }
      }
    }
    return $p;
  }

  sub findTwoOfClubs
  {
    my $g = shift;
    return 1 if($g->{"P1"}->containsCard("2C"));
    return 2 if($g->{"P2"}->containsCard("2C"));
    return 3 if($g->{"P3"}->containsCard("2C"));
    return 4 if($g->{"P4"}->containsCard("2C"));
  }
## END GAME

package main;

sub playNum
{
  my $num = $_[0];
  $num -= 4 while($num > 4);
  return $num;
}

$game = GAME->new();

my @pass = ("left", "right", "across");

my $name;
my $in = 0;

if ($#ARGV < 0)
{
  print "Please enter your name: ";
  $name = <STDIN>;
  $name =~ /^(.*)\n/;
  $name = $1;
}
else
{
  $name = $ARGV[0];
}

print "Welcome $name.\n";

while (true)
{
  print "Hit `Enter` to start a new game, or enter 'q' to exit.\n";
  $in = <STDIN>;
  if ($in =~ /^([qe]|quit|exit)$/i)
  {
    last;
  }
  else
  {
    my @scores = (0,0,0,0);
    my @go = (0, -1);
    my $handnum = 1;
    while (true)
    {
      if ($game->{"dealt"})
      {
        #During a round
        my (@cards,$win);
        my $suit = -1;
        system "clear";
        print "Hand: ".$handnum."\n";
        print $name."'s hand:\n";
        $P1HAND = $game->{"P1"}->{"HAND"};
        @P1HAND = @{$P1HAND};
        print join(" ", @P1HAND)."\n\n";
        
        for($i = 1; $i < 5; $i++)
        {
          my ($p,$pn);
          $pn = ($i + ($game->{"current"} - 1)) % 4;
          $pn = 4 if $pn == 0;
          $p = \$game->{"P".$pn};
          print "P".$pn."'s Card: " if $pn != 1;
          print $name."'s Card: " if $pn == 1;
          $cards[$pn] = $$p->move($suit, $game->{"first"}, $game->{"broken"});
          $hand = $$p->{"HAND"};
          @hand = @{$hand};
          exit 0 if($cards[$pn] == -1);
          $suit = $1 if $suit == -1 and $cards[$pn] =~ /^[0-9AJQK]+([CDSH])$/;
          $game->{"broken"} = 1 if($cards[$pn] =~ /H$/);
        }
        print "\n";
        $win = $game->winnerRound(@cards);
        $game->{"current"} = $win + 1;
        foreach $c (@cards)
        {
          $scores[$win]++ if($c =~ /H$/);
          $scores[$win] += 13 if($c eq 'QS');
        }
        $t = 0;
        $t += $_ for @scores;
        $game->{"dealt"} = 0 if($t == 26);
        $game->{"first"} = 0;
        $handnum++;
        print "P".($win+1)." Takes the round!" if $win != 0;
        print $name." Takes the round!" if $win == 0;
        <STDIN>;
      }
      else
      {
        system "clear";
        print "Round: ".($game->{"round"}+1)."\n\n";
        my $p = 100;
        for($i = 1; $i < 5; $i++)
        {
          my $s;
          if($scores[$i-1] == 26)
          {
            $s = $game->{"P".$i}->addToScore(0);
          }
          else
          {
            my $sm = 0;
            for($j = 1; $j < 5; $j++)
            {
              $sm = 1 if($scores[$j-1] == 26);
            }
            $s = $game->{"P".$i}->addToScore(26) if($sm);
            $s = $game->{"P".$i}->addToScore($scores[$i-1]) if(!$sm);
          }
          $go[0] = 1 if($s >= 100);
          if($s < $p)
          {
            $go[1] = $i;
            $p = $s;
          }
        }
        print "SCORE:\nP1: ", $game->{"P1"}->{"SCORE"}, "  P2: ", $game->{"P2"}->{"SCORE"}, "  P3: ", $game->{"P3"}->{"SCORE"}, "  P4: ", $game->{"P4"}->{"SCORE"}, "\n\n";
        if(!$go[0])
        {
          $game->shuffleDeck;
          $game->deal;
          $game->{"round"}++;
          if ($game->{"round"} % 4 != 3)
          {
            print "Please select three cards to pass $pass[($game->{'round'}%4)]:\n";
            while (true)
            {
              $h = $game->{"P1"}->{"HAND"};
              @h = @{$h};
              print join(" ", @h), "\n\n";
              $in = <STDIN>;
              exit (0) if ($in =~ /^([qe]|quit|exit)$/i);
              @selCards = split(/ /, $in);
              foreach $sel (@selCards)
              {
                $bad = 1 if !$game->{"P1"}->containsCard($sel);
              }
              last if !$bad;
              print "\nINVALID INPUT!\n\n";
            }
            #PASS CARDS HERE!! GUD INPOOT;
            $game->{"P1"}->rmCards(@selCards);
            @selCards2 = $game->{"P2"}->chsRndSelCards;
            @selCards3 = $game->{"P3"}->chsRndSelCards;
            @selCards4 = $game->{"P4"}->chsRndSelCards;
            $game->{"P".playNum(2+($game->{'round'}%4))}->addCards(@selCards);
            $game->{"P".playNum(3+($game->{'round'}%4))}->addCards(@selCards2);
            $game->{"P".playNum(4+($game->{'round'}%4))}->addCards(@selCards3);
            $game->{"P".playNum(5+($game->{'round'}%4))}->addCards(@selCards4);
          }
    else
          {
            <STDIN>;
          }
          $game->{"broken"} = 0; 
          $game->{"first"} = 1;
          $game->{"current"} = $game->findTwoOfClubs;
          @scores = (0,0,0,0);
          $game->{"dealt"} = 1;
          $handnum = 1;
        }
        else
        {
          print "Player ".$go[1]." Wins!!!\n\n";
          $game = GAME->new();
          last;
        }
      }
    }
  }
}

